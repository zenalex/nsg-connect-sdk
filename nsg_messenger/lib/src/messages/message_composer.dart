import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart' show Uint8List, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart'
    show RoomParticipant;
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
// ignore: unnecessary_import
import 'package:uuid/uuid.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../theme/nsg_messenger_theme.dart';
import '../theme/overlay_surface.dart';
import '../widgets/nsg_avatar_image.dart';
import 'attachments/attachment_picker.dart';
import 'attachments/clipboard_image.dart';
import 'attachments/mxc_image_provider.dart';
import 'chat_message.dart';
import 'composer_album_edit.dart';

/// True на mobile-платформах (iOS/Android). На desktop / web Enter
/// обрабатываем через `HardwareKeyboard.addHandler` + Shortcuts, и
/// `onSubmitted` (callback от soft-keyboard Send-кнопки) не нужен —
/// больше того, на macOS он триггерится и для Shift+Enter, что
/// ломает desktop UX «Shift+Enter = newline». Detection один раз
/// при загрузке файла.
final bool _kIsMobile = !kIsWeb && (Platform.isIOS || Platform.isAndroid);

/// Telegram-style лимит длины тела одного сообщения. Совпадает с
/// серверным `MessengerEndpoint.kMessageBodyMaxChars`. Composer
/// прокидывает в `TextField.maxLength` — counter «N/4096» под полем
/// показывает оставшийся объём, paste выше лимита truncated.
///
/// Сервер тоже валидирует и кидает `MessageBodyTooLargeException`
/// (anti-abuse + защита от malformed клиентов).
const int kMessageBodyMaxChars = 4096;

/// Ключ подложки попапа @-подсказок (issue #43).
///
/// Попап живёт в `Overlay`, а не в поддереве композера, поэтому добраться
/// до него в тесте «через родителя» нельзя — нужен якорь. Держим его
/// рядом с виджетом, чтобы регрессия «фон снова прозрачный» ловилась
/// тестом, а не глазами на скриншоте.
const Key kMentionTypeaheadPopupKey = ValueKey('mention-typeahead-popup');

/// Bottom-bar композер для ChatScreen (TASK15 Chunk 2).
///
/// Контракт:
///   * `onSend(body, mentionedMessengerUserIds)` зовётся при нажатии
///     send-button или enter-key в TextField; field очищается **до**
///     await-а на send (UX: композер свободен для следующего сообщения
///     сразу же).
///   * `enabled = false` отключает send-button + TextField.
///     ChatScreen передаёт `false` пока [MessagesController] state
///     ≠ Ready (см. контракт sendMessage в controller doc).
///
/// **TASK19 Chunk 3**: paperclip attach button → bottom-sheet с camera/
/// gallery (image_picker). file_picker (arbitrary файлы) — Phase2.
/// `onSendAttachment(picked)` зовётся после успешного pick — host-app
/// (через MessagesController) делает upload + sendMessage. Composer
/// показывает upload-spinner пока future не resolve-ится; cancellation
/// — через убирание spinner-а после dispose.
///
/// **TASK16-A**: replies + mentions.
///   * `replyTarget` — ChatMessage, на который отвечаем; non-null
///     рендерит quote chip над TextField с close-X. Когда onSend
///     вызывается — composer резолвит chip-target в caller-side state
///     для clearing (через ChatScreen).
///   * `participants` — список из `RoomDetails.participants` (TASK13
///     30-cap). `@`-typeahead overlay фильтрует через displayName
///     prefix-match; tap по item-у вставляет `@<displayName> ` в
///     TextField + добавляет messengerUserId в `_pendingMentions`,
///     отправляется при send.
class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.initialText,
    this.onSendAttachment,
    this.onSendAlbum,
    this.replyTarget,
    this.onCancelReply,
    this.participants,
    this.totalParticipants,
    this.replyTargetSenderName,
    this.editTarget,
    this.onEdit,
    this.onCancelEdit,
    this.onRequestEditLast,
    this.onTyping,
    this.albumEdit,
    this.onEditAlbum,
    this.onCancelAlbumEdit,
    this.albumThumbnailRpc,
    this.albumFullSizeRpc,
    this.mentionInsertRequests,
  });

  /// **TASK16-A**: signature расширена `mentionedMessengerUserIds`.
  /// `null`/`[]` — no mentions; non-empty — server передаст по mention
  /// flow (см. server-side `MentionResolver.resolveOutgoing`).
  final Future<void> Function(
    String body, {
    List<int>? mentionedMessengerUserIds,
    String? albumId,
  })
  onSend;
  final bool enabled;

  /// **TASK57 фаза 0**: начальный текст (шаблон обращения в поддержку).
  /// Сидируется в поле ввода ОДНОКРАТНО в `initState`; далее это обычный
  /// редактируемый draft. `null`/пусто → поле стартует пустым (дефолт).
  final String? initialText;

  /// **TASK19 Chunk 3**: attachment send. Если null — paperclip скрыт
  /// (host-app не интегрировал media flow). Future должен complete
  /// после server-confirm-а; spinner крутится до тех пор. Errors
  /// внутрь composer не пробрасываются — host-app показывает snackbar
  /// на свой стороне.
  final Future<void> Function(PickedAttachment picked, {String? albumId})?
  onSendAttachment;

  /// **Оптимистичный альбом**: отправить пачку картинок (+опц. подпись)
  /// одним альбомом с мгновенной мозаикой и фоновым аплоадом. В отличие
  /// от [onSendAttachment] — НЕ awaited и НЕ морозит поле: композер
  /// освобождается сразу, аплоад идёт фоном в контроллере. Если null —
  /// fallback на последовательный [onSendAttachment] (старое поведение).
  /// Голос/одиночное/вставка по-прежнему идут через [onSendAttachment].
  final void Function(
    List<PickedAttachment> images, {
    String caption,
    List<int>? mentions,
  })?
  onSendAlbum;

  /// **TASK16-A**: reply target — non-null рендерит quote chip над
  /// TextField. ChatScreen passes `MessagesController.replyTarget`
  /// через ValueListenableBuilder.
  final ChatMessage? replyTarget;

  /// **TASK16-A**: tap close-X → controller.clearReplyTarget. Если
  /// null (и replyTarget non-null), close-X скрыт (display-only).
  final VoidCallback? onCancelReply;

  /// **TASK16-A**: список участников комнаты (TASK13 30-cap). Используется
  /// `@`-typeahead для filter+select. Empty/null → typeahead disabled.
  final List<RoomParticipant>? participants;

  /// **TASK16-A**: total room members — для header «Showing 30 of N»
  /// когда `totalParticipants > participants.length`. Per Q2 sign-off.
  final int? totalParticipants;

  /// **TASK16-A**: displayName sender-а replyTarget — резолвится в
  /// ChatScreen через participants map (composer не должен делать
  /// O(N) lookup на каждый build). Fallback на matrixUserId если
  /// participant отсутствует.
  final String? replyTargetSenderName;

  /// **B12 (BACKLOG)**: ChatMessage в режиме редактирования. Non-null
  /// переключает composer в edit-mode:
  ///   * вместо reply-chip — желтый indicator «Редактирование» с
  ///     close-X (= onCancelEdit);
  ///   * tap по send-button (Icons.check вместо .send) → onEdit(...)
  ///     вместо onSend(...);
  ///   * Esc отменяет edit (и reply, если приоритет reply выше — но
  ///     edit и reply не могут быть активны одновременно);
  ///   * pre-populate `_ctl.text` происходит автоматически в
  ///     didUpdateWidget при transition `null → ChatMessage`.
  final ChatMessage? editTarget;

  /// **B12**: callback для commit-а edit-а. Если null И editTarget
  /// non-null — composer rendering edit-режим, но send-button no-op
  /// (контракт нарушен — host-app забыл прокинуть).
  final Future<void> Function(
    String matrixEventId,
    String newBody, {
    List<int>? mentionedMessengerUserIds,
  })?
  onEdit;

  /// **B12**: tap close-X в edit-indicator. Также Esc.
  final VoidCallback? onCancelEdit;

  /// **B12**: пользователь нажал ↑-arrow в **пустом** composer-е.
  /// Host-app должен через MessagesController.lastOwnSentMessage
  /// найти last own sent message и передать его обратно через
  /// `editTarget`. Если null — shortcut disabled.
  final VoidCallback? onRequestEditLast;

  /// **B9 typing indicator**: вызывается composer-ом с debounce:
  ///   * первый keystroke → `onTyping(true)`;
  ///   * renew каждые ~15с пока юзер печатает (Matrix server-side
  ///     timeout 30s, держим safety margin);
  ///   * 5 сек без новых keystrokes → `onTyping(false)`;
  ///   * успешный send → immediate `onTyping(false)`.
  ///
  /// Composer сам делает throttle/debounce — host-app просто passes
  /// callback в `controller.sendTyping`. Если null — typing-нотификации
  /// disabled (например, embedded read-only режим).
  final Future<void> Function(bool typing)? onTyping;

  /// **Редактирование альбома**: non-null переключает composer в album-edit-
  /// mode. Композер показывает существующие картинки альбома (миниатюрами
  /// из mxc), даёт удалить/добавить картинки и правит подпись; на сохранении
  /// собирает дифф и вызывает [onEditAlbum]. Взаимоисключающе с [editTarget]
  /// (host-app не активирует оба одновременно).
  final ComposerAlbumEdit? albumEdit;

  /// **Редактирование альбома**: commit диффа альбома. Если null И
  /// [albumEdit] non-null — save-кнопка no-op (host-app не прокинул).
  final Future<void> Function(ComposerAlbumEditResult result)? onEditAlbum;

  /// **Редактирование альбома**: tap close-X в album-edit-indicator. Также Esc.
  final VoidCallback? onCancelAlbumEdit;

  /// **Редактирование альбома**: RPC для рендера миниатюр существующих
  /// картинок из `mxc://` (см. [MxcImageProvider]). Обязателен при
  /// [albumEdit] != null (иначе миниатюры не отрисуются).
  final DownloadAttachmentThumbnailRpc? albumThumbnailRpc;

  /// **Редактирование альбома**: RPC для full-size (fallback у
  /// [MxcImageProvider], если thumbnail недоступен).
  final DownloadAttachmentRpc? albumFullSizeRpc;

  /// **TASK69 2C**: внешний источник «упоминаний из контекста». Каждое
  /// событие — участник, которого надо упомянуть: композер вставляет
  /// `@имя ` в позицию курсора и добавляет его messengerUserId в
  /// mention-flow. ChatScreen эмитит сюда на «Ответить с упоминанием»
  /// (action-sheet) и на тап по аватару собеседника. `null` → фича off.
  final Stream<RoomParticipant>? mentionInsertRequests;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final TextEditingController _ctl = TextEditingController();
  final FocusNode _focus = FocusNode();
  final LayerLink _typeaheadAnchor = LayerLink();
  final _hasTextVN = ValueNotifier<bool>(false);
  Timer? _typeaheadDebounce;
  bool _uploading = false;
  OverlayEntry? _typeaheadOverlay;

  /// **Issue #54 п.3**: идёт чтение картинки из системного буфера (Ctrl+V).
  /// Чтение и декод крупного скриншота заметно долгие, а до появления
  /// миниатюры в ленте не рисовалось НИЧЕГО — выглядело как зависание.
  /// Показываем ту же индикацию, что и у `_uploading` (спиннер вместо
  /// скрепки), чтобы не изобретать второй вид «идёт работа».
  bool _pasting = false;

  /// Таймер отложенного показа [_pasting]. ПОЧЕМУ отложенно: если в буфере
  /// текст (или буфер пуст), `Pasteboard.image` возвращает null почти
  /// мгновенно — мгновенный показ-скрытие спиннера дал бы мигание на
  /// каждом Ctrl+V. Индикацию зажигаем, только если чтение реально
  /// затянулось дольше [_pasteIndicatorDelay].
  Timer? _pasteIndicatorTimer;

  /// Порог «пользователь заметил задержку». 150 мс — обычная граница,
  /// ниже которой отклик воспринимается как мгновенный.
  static const Duration _pasteIndicatorDelay = Duration(milliseconds: 150);

  /// **TASK69 2C**: подписка на внешние «упоминания из контекста»
  /// ([MessageComposer.mentionInsertRequests]).
  StreamSubscription<RoomParticipant>? _mentionInsertSub;

  /// **Отложенная отправка вложений**: pick/paste складывает картинки сюда
  /// (миниатюры над полем ввода), а не отправляет сразу. Пользователь может
  /// добавить ещё и/или написать текст; всё уходит по кнопке «Отправить».
  /// Голос (long-press mic) в этот буфер НЕ попадает — он отправляется сразу.
  final List<PickedAttachment> _pending = <PickedAttachment>[];

  /// **Редактирование альбома**: оставшиеся существующие картинки альбома
  /// (изначально = `albumEdit.images`, минус помеченные на удаление). Рисуются
  /// миниатюрами из mxc ПЕРЕД `_pending`. Пусто вне album-edit-mode.
  final List<ComposerAlbumImage> _existingImages = <ComposerAlbumImage>[];

  /// **Редактирование альбома**: `matrixEventId` существующих картинок,
  /// помеченных на удаление (крестик на миниатюре). Уходит в дифф.
  final List<String> _removedExistingIds = <String>[];

  /// Мягкий потолок числа вложений в одном черновике (anti-abuse / UI).
  static const int _maxPending = 10;

  /// Web: вставка картинки из буфера (Ctrl+V). На не-web — no-op заглушка.
  final ClipboardImageListener _clipboardPaste = ClipboardImageListener();

  /// **B12**: текущий отфильтрованный список mention-typeahead. Хранится на
  /// уровне state, чтобы `_globalKeyHandler` (Tab-autocomplete) мог выбрать
  /// первый вариант — у него нет доступа к локальному `filtered` из
  /// `_showTypeahead`. Сбрасывается в `_hideTypeahead`.
  List<RoomParticipant> _typeaheadFiltered = const [];

  /// **TASK16-A**: накопленные mentions в текущем drafte. Каждый раз когда
  /// user выбирает item из typeahead — добавляем messengerUserId сюда.
  /// На submit — отправляем серверу. На clear/submit — обнуляем.
  /// **Note**: если user удалил `@<name>` token из текста, mention
  /// остаётся в array — server игнорирует mismatch (renders плоским
  /// если в body нет matching token). Phase2 — sync через body parse.
  final Set<int> _pendingMentions = <int>{};

  // **B-voice**: voice-recording state.
  //
  // Press-and-hold mic button → `_startRecording` (запрашивает permission +
  // создаёт tmp file + record.start). Release → `_stopRecording` (полная
  // запись + send как m.audio attachment если duration >= 1s, иначе
  // cancel со snackbar).
  //
  // `_recording` true → composer показывает overlay вместо text-field
  // (animation + mm:ss timer). На повторных rebuild-ах состояние
  // персистент через State.
  AudioRecorder? _recorder;
  bool _recording = false;
  DateTime? _recordStartedAt;
  Timer? _recordTickTimer;
  String? _recordPath;
  // Минимальная длина записи. Press мгновенный (UX «жмётся-сразу-
  // отпустил») считается accidental tap — cancel со snackbar.
  static const Duration _kMinRecordDuration = Duration(seconds: 1);
  // #11: mention-query regex — статические, чтобы не пересоздавать (компилить)
  // на КАЖДЫЙ keystroke в _currentMentionQuery (давало лаг на длинном тексте
  // при быстром вводе).
  static final RegExp _kWhitespaceRe = RegExp(r'\s');
  static final RegExp _kMentionQueryRe = RegExp(
    r'^[\p{L}\p{N}_.\-]+$',
    unicode: true,
  );

  @override
  void initState() {
    super.initState();
    // **TASK57**: сидируем draft-шаблоном однократно. Notifier выставляем
    // напрямую (НЕ через _syncHasText — тот дёрнул бы typing-нотификацию до
    // ввода пользователя).
    final seed = widget.initialText;
    if (seed != null && seed.isNotEmpty) {
      _ctl.text = seed;
      _hasTextVN.value = true;
    }
    // **Редактирование альбома**: если композер смонтирован сразу в album-
    // edit-mode (без транзиции null→value через didUpdateWidget) — сидируем
    // существующие картинки + подпись здесь же.
    final album = widget.albumEdit;
    if (album != null) {
      _existingImages.addAll(album.images);
      if (album.captionBody.isNotEmpty) {
        _ctl.text = album.captionBody;
        _hasTextVN.value = true;
      }
    }
    _ctl.addListener(_syncHasText);
    _ctl.addListener(_syncTypeahead);
    _focus.addListener(_syncTypeahead);
    // Global hardware-keyboard handler — единственный надёжный способ
    // перехватить Enter ДО того как EditableText вставит \n. Shortcuts
    // widget (выше по дереву) и FocusNode.onKeyEvent оба проигрывают
    // встроенным Shortcuts-ам EditableText-а, который находится ближе
    // к primaryFocus. См. doc у `_globalKeyHandler`.
    HardwareKeyboard.instance.addHandler(_globalKeyHandler);
    // Web: paste картинки из буфера прямо в чат (на mobile/desktop no-op).
    _clipboardPaste.start(_onPastedImage);
    // **TASK69 2C**: слушаем «упоминания из контекста» от ChatScreen.
    _mentionInsertSub = widget.mentionInsertRequests?.listen(
      _insertContextMention,
    );
  }

  @override
  void didUpdateWidget(covariant MessageComposer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // **TASK69 2C**: источник упоминаний мог смениться (host пересоздал
    // Stream) — переподписываемся.
    if (!identical(
      widget.mentionInsertRequests,
      oldWidget.mentionInsertRequests,
    )) {
      _mentionInsertSub?.cancel();
      _mentionInsertSub = widget.mentionInsertRequests?.listen(
        _insertContextMention,
      );
    }

    // **Редактирование альбома**: transition в album-edit-mode.
    final newAlbum = widget.albumEdit;
    final oldAlbum = oldWidget.albumEdit;
    if (newAlbum != null && newAlbum.albumId != oldAlbum?.albumId) {
      // Entering album-edit OR switching to another album — загружаем
      // существующие картинки, чистим накопленные удаления/черновик,
      // префилим подпись, фокус.
      _existingImages
        ..clear()
        ..addAll(newAlbum.images);
      _removedExistingIds.clear();
      setState(() => _pending.clear());
      _ctl.text = newAlbum.captionBody;
      _ctl.selection = TextSelection.collapsed(offset: _ctl.text.length);
      _hasTextVN.value = _ctl.text.trim().isNotEmpty;
      if (!_focus.hasFocus) {
        _focus.requestFocus();
      }
    } else if (oldAlbum != null && newAlbum == null) {
      // Exiting album-edit — очистка (double-clear безопасен, save тоже
      // чистит).
      _existingImages.clear();
      _removedExistingIds.clear();
      setState(() => _pending.clear());
      _ctl.clear();
      _hasTextVN.value = false;
    }

    // **B12**: transition в edit-mode — pre-populate body и focus поля.
    final newTarget = widget.editTarget;
    final oldTarget = oldWidget.editTarget;
    if (newTarget != null &&
        newTarget.matrixEventId != oldTarget?.matrixEventId) {
      // Entering edit-mode OR switching to different message.
      _ctl.text = newTarget.body;
      _ctl.selection = TextSelection.collapsed(offset: _ctl.text.length);
      // Mentions переносим из target — иначе при send-back edit потеряет
      // существующие @mentions.
      _pendingMentions
        ..clear()
        ..addAll(newTarget.mentionedMessengerUserIds ?? const <int>[]);
      if (!_focus.hasFocus) {
        _focus.requestFocus();
      }
    } else if (oldTarget != null && newTarget == null) {
      // Exiting edit-mode — очищаем поле (если не вышли через успешный
      // commit, который тоже очищает; double-clear безопасен).
      _ctl.clear();
      _pendingMentions.clear();
    }

    // **Issue #21**: вход в reply-режим — сразу фокус в поле ввода, чтобы
    // пользователь печатал ответ без дополнительного тапа (в т.ч. на
    // desktop). Раньше фокус ставился только для album-edit/edit (блоки
    // выше) и для «Ответить с упоминанием» (_insertContextMention), а
    // обычное «Ответить» лишь выставляло replyTarget — фокус не запрашивался.
    // Album-edit/edit/reply взаимоисключающи, поэтому блоки не конфликтуют;
    // повторный requestFocus защищён проверкой hasFocus (идемпотентно с
    // mention-путём).
    final newReply = widget.replyTarget;
    final oldReply = oldWidget.replyTarget;
    // Идентичность цели — matrixEventId (sent) / clientTxnId (optimistic);
    // по инварианту ChatMessage хотя бы один заполнен.
    final newReplyId = newReply?.matrixEventId ?? newReply?.clientTxnId;
    final oldReplyId = oldReply?.matrixEventId ?? oldReply?.clientTxnId;
    if (newReply != null && newReplyId != oldReplyId) {
      if (!_focus.hasFocus) _focus.requestFocus();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_globalKeyHandler);
    _mentionInsertSub?.cancel();
    _clipboardPaste.stop();
    // Issue #54 п.3: отложенный показ индикации вставки мог не успеть
    // сработать — иначе setState после dispose.
    _pasteIndicatorTimer?.cancel();
    _pasteIndicatorTimer = null;
    // B-voice: abort любую активную запись (без upload) + cleanup.
    _recordTickTimer?.cancel();
    _recordTickTimer = null;
    final rec = _recorder;
    if (rec != null) {
      // Best-effort: stop + dispose. Ignore errors на shutdown path.
      unawaited(
        rec.stop().catchError((_) => null).whenComplete(() => rec.dispose()),
      );
      _recorder = null;
    }
    final path = _recordPath;
    if (path != null) {
      File(path).delete().catchError((_) => File(path));
      _recordPath = null;
    }
    _typingIdleTimer?.cancel();
    _typingIdleTimer = null;
    // Best-effort fire typing=false на закрытии composer-а — peer
    // увидит «перестал печатать» сразу, не ждёт 30s Matrix timeout.
    // Если onTyping null — no-op.
    if (_typingActive) {
      _typingActive = false;
      final cb = widget.onTyping;
      if (cb != null) unawaited(cb(false));
    }
    _typeaheadDebounce?.cancel();
    _typeaheadOverlay?.remove();
    _typeaheadOverlay = null;
    _ctl.removeListener(_syncHasText);
    _ctl.removeListener(_syncTypeahead);
    _focus.removeListener(_syncTypeahead);
    _ctl.dispose();
    _focus.dispose();
    _hasTextVN.dispose();
    super.dispose();
  }

  void _syncHasText() {
    final has = _ctl.text.trim().isNotEmpty;
    if (has != _hasTextVN.value) _hasTextVN.value = has;
    _maybeTriggerTyping(has);
  }

  // **B9 typing debounce**.
  //
  // Strategy (Telegram/Slack-style):
  //   * При first keystroke (`hasText` стал true ИЛИ просто новый
  //     keystroke в уже-непустом поле) → ensure typing=true sent
  //     не чаще раза в `_typingRenewInterval`.
  //   * Через `_typingIdleTimeout` после последнего keystroke без
  //     активности → typing=false.
  //   * После send (`_submit`) → typing=false мгновенно.
  //   * При editTarget = null (выход из edit-mode) → typing=false.
  //   * Composer disposed → cancel timers, last typing=false fire-and-
  //     forget.
  static const Duration _typingRenewInterval = Duration(seconds: 15);
  static const Duration _typingIdleTimeout = Duration(seconds: 5);

  Timer? _typingIdleTimer;
  DateTime? _lastTypingTrueAt;
  bool _typingActive = false;

  void _maybeTriggerTyping(bool hasText) {
    final cb = widget.onTyping;
    if (cb == null) {
      if (kDebugMode) {
        debugPrint(
          // Штатный случай — комната «Избранное» (ChatScreen намеренно не
          // передаёт onTyping: показывать «печатает…» самому себе некому).
          // Прежняя формулировка «host-app не прокинул» обвиняла хост и
          // читалась как дефект интеграции — мак-агент так и завёл её в
          // отчёт как баг (2026-07-22).
          '[MessageComposer] _maybeTriggerTyping(hasText=$hasText) '
          '→ onTyping не задан (комната без индикатора «печатает», '
          'напр. «Избранное») — пропускаем',
        );
      }
      return;
    }
    if (hasText) {
      // First keystroke OR renew если прошло >= renew interval.
      final now = DateTime.now();
      final shouldRenew =
          !_typingActive ||
          _lastTypingTrueAt == null ||
          now.difference(_lastTypingTrueAt!) >= _typingRenewInterval;
      if (shouldRenew) {
        final wasActive = _typingActive;
        _typingActive = true;
        _lastTypingTrueAt = now;
        // Fire-and-forget — каждая typing call best-effort на сервере.
        if (kDebugMode) {
          debugPrint(
            '[MessageComposer] typing=true '
            '(wasActive=$wasActive renew=true)',
          );
        }
        unawaited(cb(true));
      }
      // Restart idle timer.
      _typingIdleTimer?.cancel();
      _typingIdleTimer = Timer(_typingIdleTimeout, () {
        if (!mounted) return;
        _stopTyping();
      });
    } else {
      // Поле очищено — стопаем typing immediately.
      _stopTyping();
    }
  }

  void _stopTyping() {
    _typingIdleTimer?.cancel();
    _typingIdleTimer = null;
    if (!_typingActive) return;
    _typingActive = false;
    _lastTypingTrueAt = null;
    final cb = widget.onTyping;
    if (cb != null) unawaited(cb(false));
  }

  /// Извлекает текущий `@<query>` token immediately перед caret-ом.
  /// Returns query (без `@`) ИЛИ `null` если caret не в mention-context-е.
  String? _currentMentionQuery() {
    final selection = _ctl.selection;
    if (!selection.isValid || !selection.isCollapsed) return null;
    final caret = selection.start;
    if (caret <= 0) return null;
    final text = _ctl.text;
    // #11: ищем последний `@` ДО каретки без копии всего префикса —
    // substring(0, caret) был O(n) на каждый символ и тормозил длинный текст.
    // lastIndexOf с offset ищет от каретки назад (эквивалент поиска в
    // upToCaret, но без аллокации). Между `@` и caret — query (только
    // letters/digits/_-., без whitespace).
    final atIdx = text.lastIndexOf('@', caret - 1);
    if (atIdx < 0) return null;
    final query = text.substring(atIdx + 1, caret);
    if (_kWhitespaceRe.hasMatch(query)) return null;
    if (query.contains('@')) return null;
    // Permitted chars only — иначе exit (пользователь typed `@` в email
    // и пошло по тексту дальше, e.g. `foo@bar.com`). Unicode property
    // classes для non-ASCII displaynames (cyrillic + other scripts).
    if (query.isNotEmpty && !_kMentionQueryRe.hasMatch(query)) {
      return null;
    }
    // Boundary: `@` должен быть либо в начале, либо после whitespace —
    // защита от false-trigger в email.
    if (atIdx > 0) {
      final before = text[atIdx - 1];
      if (!_kWhitespaceRe.hasMatch(before)) return null;
    }
    return query;
  }

  void _syncTypeahead() {
    _typeaheadDebounce?.cancel();
    _typeaheadDebounce = Timer(const Duration(milliseconds: 100), () {
      final query = _currentMentionQuery();
      final participants = widget.participants;
      if (query == null ||
          participants == null ||
          participants.isEmpty ||
          !_focus.hasFocus) {
        _hideTypeahead();
        return;
      }
      _showTypeahead(query, participants);
    });
  }

  void _showTypeahead(String query, List<RoomParticipant> participants) {
    final ql = query.toLowerCase();
    final filtered = participants.where((p) {
      final dn = (p.displayName ?? '').toLowerCase();
      final lp = _matrixLocalpart(p.matrixUserId)?.toLowerCase() ?? '';
      // **TASK69 2A**: фильтруем и по публичному @username — раз мы его
      // показываем, набор `@handle` должен находить участника.
      final un = (p.username ?? '').toLowerCase();
      return ql.isEmpty ||
          dn.contains(ql) ||
          lp.contains(ql) ||
          un.contains(ql);
    }).toList();
    _typeaheadFiltered = filtered;

    _typeaheadOverlay?.remove();
    _typeaheadOverlay = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 0,
        right: 0,
        child: CompositedTransformFollower(
          link: _typeaheadAnchor,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          // **issue #43**: фон задаём ЯВНО. Без `color` Material берёт
          // `colorScheme.surface`, а в Glass-темах он прозрачный — попап
          // всплывал над лентой, и сквозь список подсказок читались
          // сообщения. Скругление + тень довершают отрыв от фона: попап
          // должен выглядеть как всплывшая карточка, а не как текст,
          // напечатанный поверх чата.
          child: Material(
            key: kMentionTypeaheadPopupKey,
            color: kOverlaySurface,
            elevation: 8,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: _TypeaheadList(
                filtered: filtered,
                totalShown: participants.length,
                totalAll: widget.totalParticipants ?? participants.length,
                onPick: _onPickMention,
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_typeaheadOverlay!);
  }

  void _hideTypeahead() {
    _typeaheadOverlay?.remove();
    _typeaheadOverlay = null;
    _typeaheadFiltered = const [];
  }

  void _onPickMention(RoomParticipant p) {
    final selection = _ctl.selection;
    if (!selection.isValid || !selection.isCollapsed) return;
    final caret = selection.start;
    final upToCaret = _ctl.text.substring(0, caret);
    final atIdx = upToCaret.lastIndexOf('@');
    if (atIdx < 0) return;
    final after = _ctl.text.substring(caret);
    final dn =
        p.displayName ?? _matrixLocalpart(p.matrixUserId) ?? p.matrixUserId;
    // Replace `@<query>` на `@<displayName> ` (trailing space — UX).
    final replaced = '${_ctl.text.substring(0, atIdx)}@$dn $after';
    final newCaret = atIdx + dn.length + 2; // `@` + displayName + space
    _ctl.value = TextEditingValue(
      text: replaced,
      selection: TextSelection.collapsed(offset: newCaret),
    );
    _pendingMentions.add(p.messengerUserId);
    _hideTypeahead();
    // Вернуть фокус в поле — пользователь продолжает ввод сразу после выбора
    // упоминания (на web тап по оверлею мог его кратко увести).
    if (!_focus.hasFocus) _focus.requestFocus();
  }

  /// **TASK69 2C**: вставить упоминание участника «из контекста» (не через
  /// набор `@`): по «Ответить с упоминанием» или тапу по аватару. В отличие
  /// от [_onPickMention] здесь НЕТ `@<query>`-токена для замены — вставляем
  /// `@имя ` в позицию курсора (или в конец), добавляя ведущий пробел, если
  /// перед курсором уже есть непробельный символ.
  void _insertContextMention(RoomParticipant p) {
    if (!mounted) return;
    final name =
        p.displayName ?? _matrixLocalpart(p.matrixUserId) ?? p.matrixUserId;
    final text = _ctl.text;
    final sel = _ctl.selection;
    final caret = (sel.isValid && sel.isCollapsed) ? sel.start : text.length;
    final before = text.substring(0, caret);
    final after = text.substring(caret);
    // Ведущий пробел — только если слева есть непробельный символ.
    final needsLeadingSpace = before.isNotEmpty && !before.endsWith(' ');
    final insert = '${needsLeadingSpace ? ' ' : ''}@$name ';
    final newText = '$before$insert$after';
    final newCaret = caret + insert.length;
    _ctl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCaret),
    );
    _pendingMentions.add(p.messengerUserId);
    _hasTextVN.value = newText.trim().isNotEmpty;
    if (!_focus.hasFocus) _focus.requestFocus();
  }

  /// **Desktop hardware-keyboard shortcuts**.
  ///
  /// Зачем глобальный handler через `HardwareKeyboard.addHandler`, а не
  /// `Shortcuts` widget / `Focus(onKeyEvent:)`:
  ///
  /// * `Shortcuts` ищет совпадения от primaryFocus вверх; у EditableText
  ///   внутри TextField есть **свой** Shortcuts widget которое ближе к
  ///   primaryFocus и срабатывает первым (мапит Enter в `InsertNewline`
  ///   intent для multi-line поля).
  /// * `Focus.onKeyEvent` / `FocusNode.onKeyEvent` точно так же
  ///   проигрывают встроенному dispatch-у EditableText-а.
  /// * `HardwareKeyboard.addHandler` — глобальный callback, который
  ///   Flutter вызывает ПЕРЕД любой widget-tree dispatch. Возврат `true`
  ///   останавливает event-propagation. Это единственный способ
  ///   гарантированно перехватить Enter до того как EditableText
  ///   вставит `\n`.
  ///
  /// Filter:
  /// * Срабатываем только если composer focused (`_focus.hasFocus`),
  ///   иначе пропускаем event дальше (другой TextField на экране должен
  ///   работать как обычно).
  /// * Только `KeyDownEvent` (не Up/Repeat — submit на repeat бы спамил).
  ///
  /// Bindings:
  /// * Enter / NumpadEnter (без Shift/Ctrl/Cmd/Alt) → submit.
  /// * Shift+Enter / Ctrl+Enter и т.п. → пропускаем (вернёт false),
  ///   EditableText сам вставит `\n`.
  /// * Esc + replyTarget → cancel reply.
  bool _globalKeyHandler(KeyEvent event) {
    if (!_focus.hasFocus) return false;
    if (event is! KeyDownEvent) return false;
    final keyboard = HardwareKeyboard.instance;
    final isShift = keyboard.isShiftPressed;
    final isCtrl = keyboard.isControlPressed;
    final isMeta = keyboard.isMetaPressed;
    final isAlt = keyboard.isAltPressed;
    final key = event.logicalKey;

    // **B12 Tab-autocomplete**: при открытом mention-typeahead Tab выбирает
    // первый отфильтрованный вариант (без перемещения фокуса). Закрытый
    // typeahead — Tab работает как обычная focus-навигация (пропускаем).
    if (key == LogicalKeyboardKey.tab &&
        !isShift &&
        !isCtrl &&
        !isMeta &&
        !isAlt &&
        _typeaheadOverlay != null &&
        _typeaheadFiltered.isNotEmpty) {
      _onPickMention(_typeaheadFiltered.first);
      return true; // intercept — НЕ дать Tab увести фокус
    }

    // **B12 markdown-wrapping**: Ctrl/Cmd+B → `**bold**`, Ctrl/Cmd+I →
    // `_italic_` вокруг выделения (пустое выделение → вставка пары маркеров
    // с кареткой между). Совместимо с server markdown→HTML (B19 phase2) и
    // SDK inline-render (`parseMarkdownToSpans`).
    if ((isCtrl || isMeta) && !isAlt) {
      if (key == LogicalKeyboardKey.keyB) {
        _wrapSelection('**');
        return true;
      }
      if (key == LogicalKeyboardKey.keyI) {
        _wrapSelection('_');
        return true;
      }
      // **Desktop paste картинки (2026-07-13)**: Ctrl/Cmd+V — если в
      // системном буфере картинка (скриншот/копия из проводника), кладём
      // её во вложения. НЕ перехватываем событие (return false ниже):
      // текстовую вставку делает сам EditableText — когда в буфере
      // картинка, текст-вставка обычно no-op, конфликтов нет. Web
      // покрыт отдельным listener-ом (`ClipboardImageListener`).
      if (key == LogicalKeyboardKey.keyV && !isShift) {
        unawaited(_tryPasteImageDesktop());
      }
    }

    final isEnter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    // **Enter = отправка — только на DESKTOP** (issue #27). На мобильном
    // Enter обязан давать ПЕРЕВОД СТРОКИ: многострочное сообщение иначе не
    // набрать (поле `maxLines: 5`, но вставить \n было нечем). Отправка там
    // — кнопкой (`Icons.send` рядом с полем), как в Telegram/WhatsApp.
    // Гард нужен именно здесь: часть Android-IME шлёт hardware-Enter, и без
    // него этот handler съедал бы \n даже при `TextInputAction.newline`.
    if (isEnter && !_kIsMobile && !isShift && !isCtrl && !isMeta && !isAlt) {
      // Submit нужно отложить на следующий frame — текущий handler
      // выполняется в Flutter's keyboard-pipeline microtask, и
      // setState/text-controller операции в нём могут конфликтовать
      // с in-flight key dispatch.
      if (_ctl.text.trim().isNotEmpty && widget.enabled && !_uploading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _submit();
        });
      }
      return true; // intercept — НЕ дать TextField вставить \n
    }

    if (key == LogicalKeyboardKey.escape) {
      // Album-edit имеет приоритет (тоже edit-режим). Затем edit-mode,
      // затем reply (все взаимоисключающи, но защищаемся порядком).
      if (widget.albumEdit != null && widget.onCancelAlbumEdit != null) {
        widget.onCancelAlbumEdit!();
        return true;
      }
      if (widget.editTarget != null && widget.onCancelEdit != null) {
        widget.onCancelEdit!();
        return true;
      }
      if (widget.replyTarget != null && widget.onCancelReply != null) {
        widget.onCancelReply!();
        return true;
      }
    }

    // **B12 ↑-arrow**: в пустом composer-е перебрасывает в edit-mode
    // для last own sent message. Если поле не пустое — пропускаем
    // (юзер навигирует курсор по строкам multi-line ввода).
    if (key == LogicalKeyboardKey.arrowUp &&
        !isShift &&
        !isCtrl &&
        !isMeta &&
        !isAlt &&
        _ctl.text.isEmpty &&
        widget.editTarget == null &&
        widget.onRequestEditLast != null) {
      widget.onRequestEditLast!();
      return true;
    }

    return false; // пропускаем дальше всё остальное
  }

  /// **B12**: обернуть текущее выделение в composer-е markdown-маркером
  /// (`**` bold / `_` italic). Пустое (collapsed) выделение → вставка пары
  /// маркеров с кареткой между ними. Каретка/выделение сохраняются на
  /// обёрнутом тексте, чтобы повторное нажатие/ввод продолжались логично.
  void _wrapSelection(String marker) {
    final value = _ctl.value;
    final sel = value.selection;
    if (!sel.isValid) return;
    final text = value.text;
    final start = sel.start;
    final end = sel.end;
    final selected = text.substring(start, end);
    final newText = text.replaceRange(start, end, '$marker$selected$marker');
    _ctl.value = value.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: start + marker.length,
        extentOffset: end + marker.length,
      ),
      composing: TextRange.empty,
    );
  }

  void _submit() {
    if (!widget.enabled || _uploading) return;

    // **Редактирование альбома**: save диффа — приоритет над обычным edit/send.
    final albumEdit = widget.albumEdit;
    if (albumEdit != null) {
      _submitAlbumEdit(albumEdit);
      return;
    }

    final trimmed = _ctl.text.trim();
    // Отправлять нечего только если и текст пуст, и вложений нет.
    if (trimmed.isEmpty && _pending.isEmpty) return;
    // Defensive clamp: TextField.maxLength=enforced уже не даёт превысить
    // лимит, но платформенные edge-case-ы (web IME, программная вставка
    // мимо formatter-а) теоретически могут просочиться. Гарантируем, что
    // server никогда не увидит > kMessageBodyMaxChars и не вернёт
    // MessageBodyTooLargeException (→ silent failed-send). Counter под
    // полем уже визуально предупреждал пользователя о пределе.
    final body = trimmed.length > kMessageBodyMaxChars
        ? trimmed.substring(0, kMessageBodyMaxChars)
        : trimmed;
    // Snapshot mentions ПЕРЕД clear-ом (clear сбрасывает state).
    final mentions = _pendingMentions.isEmpty
        ? null
        : List<int>.unmodifiable(_pendingMentions);
    // **B12**: edit-mode path. Submit идёт в onEdit, поле очищается,
    // edit-target сбрасывается через host-app (onEdit completion).
    final editing = widget.editTarget;
    final onEdit = widget.onEdit;
    if (editing != null && onEdit != null) {
      final eventId = editing.matrixEventId;
      if (eventId == null) return; // sanity — non-sent в edit не попадёт
      _ctl.clear();
      _pendingMentions.clear();
      _hideTypeahead();
      _hasTextVN.value = false;
      onEdit(eventId, body, mentionedMessengerUserIds: mentions);
      return;
    }
    // Есть отложенные вложения → отправляем альбомом. Снимаем снапшот
    // pending+text+mentions, синхронно чистим черновик, и:
    //   * если host подключил onSendAlbum (оптимистичный путь) — зовём его
    //     БЕЗ await и БЕЗ `_uploading=true`: мозаика появляется мгновенно,
    //     поле свободно сразу, аплоад идёт фоном в контроллере;
    //   * иначе fallback на старый последовательный _sendPendingThenText
    //     (со спиннером).
    if (_pending.isNotEmpty) {
      final pending = List<PickedAttachment>.of(_pending);
      _ctl.clear();
      _pendingMentions.clear();
      _hideTypeahead();
      _hasTextVN.value = false;
      setState(() => _pending.clear());
      final onSendAlbum = widget.onSendAlbum;
      if (onSendAlbum != null) {
        onSendAlbum(pending, caption: body, mentions: mentions);
      } else {
        unawaited(_sendPendingThenText(pending, body, mentions));
      }
      return;
    }
    _ctl.clear();
    _pendingMentions.clear();
    _hideTypeahead();
    _hasTextVN.value = false;
    widget.onSend(body, mentionedMessengerUserIds: mentions);
  }

  /// **Редактирование альбома**: собрать дифф и отдать хосту через
  /// [MessageComposer.onEditAlbum]. Guard: если ничего не изменилось
  /// (нет удалённых/добавленных картинок И подпись та же) — просто выходим
  /// из режима без RPC. Deletion всех картинок альбома блокируется в UI
  /// (нельзя убрать последнюю картинку крестиком).
  void _submitAlbumEdit(ComposerAlbumEdit albumEdit) {
    final onEditAlbum = widget.onEditAlbum;
    final newCaption = _ctl.text.trim();
    final captionChanged = newCaption != albumEdit.captionBody.trim();
    final nothingChanged =
        _removedExistingIds.isEmpty && _pending.isEmpty && !captionChanged;

    // Ничего не поменяли ИЛИ host не прокинул callback → тихо выходим из
    // режима (composer сброс — через host-app обнуление albumEdit).
    if (nothingChanged || onEditAlbum == null) {
      widget.onCancelAlbumEdit?.call();
      return;
    }

    final result = ComposerAlbumEditResult(
      albumId: albumEdit.albumId,
      removedImageEventIds: List<String>.of(_removedExistingIds),
      newAttachments: List<PickedAttachment>.of(_pending),
      newCaption: newCaption,
      captionEventId: albumEdit.captionEventId,
    );

    // Оптимистично чистим локальное состояние (host обнулит albumEdit →
    // didUpdateWidget тоже подчистит; double-clear безопасен).
    _hideTypeahead();
    setState(() {
      _pending.clear();
      _existingImages.clear();
      _removedExistingIds.clear();
    });
    _ctl.clear();
    _hasTextVN.value = false;

    unawaited(onEditAlbum(result));
  }

  /// **Редактирование альбома**: убрать существующую картинку (крестик на
  /// миниатюре) — из ленты уходит, её eventId копится в `_removedExistingIds`
  /// для redact на сохранении. Нельзя убрать последнюю картинку — альбом без
  /// картинок не имеет смысла (осталась бы одна подпись); крестик у последней
  /// не показывается, но защищаемся и здесь.
  void _removeExistingImage(int index) {
    if (!mounted || index < 0 || index >= _existingImages.length) return;
    if (_existingImages.length + _pending.length <= 1) return;
    final removed = _existingImages[index];
    setState(() {
      _existingImages.removeAt(index);
      _removedExistingIds.add(removed.matrixEventId);
    });
  }

  Future<void> _attach() async {
    if (!widget.enabled || _uploading) return;
    if (widget.onSendAttachment == null) return;
    // Ограничиваем мультивыбор оставшимся местом в черновике (кап
    // _maxPending). limit<=0 (буфер уже полон) — не открываем пикер.
    final remaining = _maxPending - _pending.length;
    if (remaining <= 0) return;
    final picked = await showAttachmentPicker(
      context: context,
      galleryLimit: remaining,
    );
    if (picked.isEmpty) return;
    // Добавляем все выбранные (с учётом кап-а в _addPending).
    for (final p in picked) {
      _addPending(p);
    }
  }

  /// **Desktop (2026-07-13)**: прочитать картинку из системного буфера
  /// (pasteboard: Windows/macOS/Linux) и добавить во вложения. Web — не
  /// здесь (там paste-событие браузера, см. [ClipboardImageListener]);
  /// mobile — физического Ctrl+V нет. Пустой буфер/не картинка — no-op.
  Future<void> _tryPasteImageDesktop() async {
    if (kIsWeb) return;
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return;
    }
    if (!widget.enabled || _uploading || _pasting) return;
    if (widget.onSendAttachment == null) return;
    Uint8List? bytes;
    // Индикация (issue #54 п.3) — с задержкой, чтобы не мигать, когда
    // в буфере не картинка и чтение возвращается сразу.
    _pasteIndicatorTimer?.cancel();
    _pasteIndicatorTimer = Timer(_pasteIndicatorDelay, () {
      if (mounted) setState(() => _pasting = true);
    });
    try {
      bytes = await Pasteboard.image;
    } catch (_) {
      return; // нет нативной реализации/ошибка платформы — молчим
    } finally {
      // Снимаем индикацию на ЛЮБОМ исходе, в т.ч. когда картинки не было:
      // тогда таймер ещё не сработал и спиннер не покажется вовсе.
      _pasteIndicatorTimer?.cancel();
      _pasteIndicatorTimer = null;
      if (mounted && _pasting) setState(() => _pasting = false);
    }
    if (bytes == null || bytes.isEmpty || !mounted) return;
    _onPastedImage(
      PickedAttachment(
        bytes: bytes,
        mimeType: 'image/png',
        originalFilename:
            'clipboard-${DateTime.now().millisecondsSinceEpoch}.png',
      ),
    );
  }

  /// Картинка вставлена из буфера (Ctrl+V, web). Игнорируем, если composer
  /// выключен/занят загрузкой или host-app не подключил media-flow.
  void _onPastedImage(PickedAttachment picked) {
    if (!mounted || !widget.enabled || _uploading) return;
    if (widget.onSendAttachment == null) return;
    _addPending(picked);
  }

  /// Добавить вложение в буфер черновика (миниатюра над полем). Отправка —
  /// отложенная, по кнопке «Отправить» (см. [_submit]).
  void _addPending(PickedAttachment picked) {
    if (!mounted) return;
    // Мягкий потолок — сверх лимита просто не добавляем (edge-case, без
    // отдельного l10n-текста).
    if (_pending.length >= _maxPending) return;
    setState(() => _pending.add(picked));
  }

  void _removePending(int index) {
    if (!mounted || index < 0 || index >= _pending.length) return;
    setState(() => _pending.removeAt(index));
  }

  /// Отправка черновика с вложениями: сперва каждое вложение отдельным
  /// сообщением (в порядке добавления), затем текст (если есть) — отдельным
  /// сообщением с mentions. Ошибки глотаем (host сам покажет snackbar).
  Future<void> _sendPendingThenText(
    List<PickedAttachment> pending,
    String text,
    List<int>? mentions,
  ) async {
    final onSendAttachment = widget.onSendAttachment;
    if (onSendAttachment == null) return;
    // Альбом: несколько картинок (или картинки + подпись) уходят одним
    // логическим сообщением-мозаикой — общий albumId на всю пачку. Одна
    // картинка без подписи — обычное сообщение (albumId=null).
    final albumId = (pending.length > 1 || text.isNotEmpty)
        ? const Uuid().v4()
        : null;
    if (mounted) setState(() => _uploading = true);
    try {
      for (final p in pending) {
        await onSendAttachment(p, albumId: albumId);
      }
      if (text.isNotEmpty) {
        await widget.onSend(
          text,
          mentionedMessengerUserIds: mentions,
          albumId: albumId,
        );
      }
    } catch (_) {
      // Host-app показывает snackbar; composer просто un-spinner.
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ============== B-voice: voice recording ==============

  /// Long-press start на mic-button. Запрашиваем permission, открываем
  /// recorder и сохраняем в tmp file. UI переключается в recording-mode
  /// через `setState(_recording = true)`.
  Future<void> _startRecording() async {
    if (_recording || _uploading || !widget.enabled) return;
    if (widget.onSendAttachment == null) return;
    final l = NsgL10n.of(context);
    final recorder = AudioRecorder();
    _recorder = recorder;
    try {
      final granted = await recorder.hasPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.voiceRecordPermissionDenied)),
          );
        }
        await recorder.dispose();
        _recorder = null;
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/nsg_voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await recorder.start(const RecordConfig(), path: path);
      _recordPath = path;
      _recordStartedAt = DateTime.now();
      if (!mounted) {
        // Composer unmounted между start permission и start recording —
        // best-effort cleanup.
        await recorder.stop().catchError((_) => null);
        await recorder.dispose();
        _recorder = null;
        File(path).delete().catchError((_) => File(path));
        _recordPath = null;
        return;
      }
      setState(() => _recording = true);
      // Tick timer для UI mm:ss обновления (раз в 200ms — достаточно
      // плавно, не дёргает CPU).
      _recordTickTimer?.cancel();
      _recordTickTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted) return;
        setState(() {}); // trigger rebuild для timer display
      });
    } catch (e, st) {
      // debugPrint ниже в release не выводится — до сих пор здесь не
      // оставалось вообще никаких следов (та же дыра, что стоила нам
      // несоединяющихся звонков в 805d0a1). Снек voiceRecordError общий с
      // отправкой (_stopRecording), поэтому тег разделяет «не начали
      // запись» и «не отправили записанное».
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'voice.action': 'startRecording'},
      );
      if (kDebugMode) {
        debugPrint('[MessageComposer] _startRecording failed: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.voiceRecordError)));
      }
      await recorder.dispose();
      _recorder = null;
      _recordPath = null;
      _recordStartedAt = null;
    }
  }

  /// Long-press end / pointer up. Stop recorder, проверяем длительность,
  /// если ≥ 1s — отправляем как m.audio attachment через onSendAttachment;
  /// иначе drop + snackbar «too short».
  Future<void> _stopRecording({bool cancel = false}) async {
    final recorder = _recorder;
    if (recorder == null) return;
    final l = NsgL10n.of(context);
    _recordTickTimer?.cancel();
    _recordTickTimer = null;
    String? path;
    try {
      path = await recorder.stop();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MessageComposer] _stopRecording: $e');
      }
    } finally {
      await recorder.dispose();
      _recorder = null;
    }
    final startedAt = _recordStartedAt;
    _recordStartedAt = null;
    final recordedPath = path ?? _recordPath;
    _recordPath = null;
    if (mounted) setState(() => _recording = false);

    if (cancel || recordedPath == null) {
      if (recordedPath != null) {
        File(recordedPath).delete().catchError((_) => File(recordedPath));
      }
      return;
    }

    final duration = startedAt != null
        ? DateTime.now().difference(startedAt)
        : Duration.zero;
    if (duration < _kMinRecordDuration) {
      File(recordedPath).delete().catchError((_) => File(recordedPath));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.voiceRecordTooShort)));
      }
      return;
    }

    // Reads bytes → send как attachment. Cleanup tmp file после.
    final onSendAttachment = widget.onSendAttachment;
    if (onSendAttachment == null) {
      File(recordedPath).delete().catchError((_) => File(recordedPath));
      return;
    }
    try {
      final f = File(recordedPath);
      final bytes = await f.readAsBytes();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final picked = PickedAttachment(
        bytes: bytes,
        mimeType: 'audio/mp4',
        originalFilename: 'voice-$ts.m4a',
      );
      if (!mounted) return;
      setState(() => _uploading = true);
      try {
        await onSendAttachment(picked);
      } catch (_) {
        // Host-app сам показывает snackbar.
      } finally {
        if (mounted) setState(() => _uploading = false);
        await f.delete().catchError((_) => f);
      }
    } catch (e, st) {
      // Голосовое не ушло, а в release-сборке следов не оставалось вообще:
      // debugPrint молчит, снек пользователь закрыл — и всё. Ошибки самой
      // отправки сюда не долетают (их глотает inner-catch выше, снек делает
      // host-app), так что это локальный сбой: чтение файла/tmp-каталог.
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'voice.action': 'send'},
      );
      if (kDebugMode) {
        debugPrint('[MessageComposer] voice send failed: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.voiceRecordError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = NsgL10n.of(context);
    // TASK22 Phase2 Chunk 1: composer outer-padding из bubble tokens —
    // host-app override-ит через `NsgMessengerTheme.bubbleTokens`.
    final bubbleTokens =
        theme.extension<NsgMessageBubbleTokens>() ??
        NsgMessageBubbleTokens.fallback;
    final canAttach =
        widget.enabled &&
        !_uploading &&
        !_pasting &&
        widget.onSendAttachment != null;
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Индикатор-чип над полем. Приоритет: album-edit > edit > reply
            // (все взаимоисключающи; defensive порядок в UI).
            if (widget.albumEdit != null)
              _AlbumEditDraftChip(onCancel: widget.onCancelAlbumEdit)
            else if (widget.editTarget != null)
              _EditDraftChip(
                target: widget.editTarget!,
                onCancel: widget.onCancelEdit,
              )
            else if (widget.replyTarget != null)
              _ReplyDraftChip(
                target: widget.replyTarget!,
                senderName:
                    widget.replyTargetSenderName ??
                    widget.replyTarget!.senderMatrixUserId,
                onCancel: widget.onCancelReply,
              ),
            // Миниатюры над полем ввода (Telegram-style).
            //   * album-edit: СНАЧАЛА существующие картинки (из mxc), потом
            //     добавленные (bytes); у каждой крестик удаления;
            //   * обычный черновик: только отложенные `_pending`.
            if (widget.albumEdit != null)
              _AlbumEditAttachmentsStrip(
                existing: _existingImages,
                pending: _pending,
                thumbnailRpc: widget.albumThumbnailRpc,
                fullSizeRpc: widget.albumFullSizeRpc,
                // Крестик на существующей картинке блокируется, если она
                // последняя оставшаяся (нельзя удалить все картинки альбома).
                canRemove: (_existingImages.length + _pending.length) > 1,
                onRemoveExisting: _uploading ? null : _removeExistingImage,
                onRemovePending: _uploading ? null : _removePending,
              )
            else if (_pending.isNotEmpty)
              _PendingAttachmentsStrip(
                pending: _pending,
                onRemove: _uploading ? null : _removePending,
              ),
            Padding(
              padding: bubbleTokens.composerPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.onSendAttachment != null)
                    IconButton(
                      // Спиннер и на upload-е, и на чтении буфера
                      // (issue #54 п.3) — один язык индикации «занято».
                      icon: (_uploading || _pasting)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.attach_file),
                      tooltip: l.attachTooltip,
                      onPressed: canAttach ? _attach : null,
                    ),
                  Expanded(
                    child: _recording
                        ? _RecordingIndicator(
                            startedAt: _recordStartedAt,
                            textColor: theme.colorScheme.error,
                          )
                        : CompositedTransformTarget(
                            link: _typeaheadAnchor,
                            // Desktop shortcuts (Enter/Shift+Enter/Esc)
                            // обрабатываются в `_globalKeyHandler` через
                            // `HardwareKeyboard.addHandler` — это первый
                            // уровень dispatch, до того как event попадёт
                            // в EditableText.
                            child: RepaintBoundary(
                              child: TextField(
                                controller: _ctl,
                                focusNode: _focus,
                                enabled: widget.enabled && !_uploading,
                                minLines: 1,
                                maxLines: 5,
                                // Telegram-style лимит. `maxLengthEnforcement`
                                // truncated → typing/paste выше лимита просто
                                // обрезается (без error-dialog-а). Визуальный
                                // «0/4096» counter скрыт (см. decoration ниже,
                                // counterText: '') — он ел строку и ломал
                                // выравнивание строки composer-а. Сервер тоже
                                // валидирует (MessageBodyTooLargeException) —
                                // anti-abuse.
                                //
                                // `enforced` (не `truncateAfterCompositionEnds`):
                                // последний обрезал только ПОСЛЕ завершения IME-
                                // композиции, поэтому paste-then-immediate-send
                                // (особенно desktop, где paste не даёт
                                // composition-end) проскакивал > лимита и ловил
                                // server-side MessageBodyTooLargeException →
                                // silent failed-send (наблюдали в проде: 5760
                                // chars). `enforced` режет немедленно на любом
                                // вводе/paste. Mid-IME-обрезка для лимита 4096
                                // практически невозможна (никто не композит
                                // 4096 символов за один IME-сеанс).
                                maxLength: kMessageBodyMaxChars,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                // **newline ВЕЗДЕ** (issue #27). Раньше на
                                // mobile стоял `TextInputAction.send`:
                                // soft-клавиатура показывала «Отправить»
                                // вместо Enter, и перевод строки было НЕЧЕМ
                                // поставить — многострочное сообщение не
                                // набрать. Отправка на mobile — кнопкой
                                // (`Icons.send`), как в Telegram/WhatsApp.
                                // На desktop `send` нельзя и по другой
                                // причине: macOS вызывает performAction(send)
                                // на Enter ЛЮБОГО типа (включая Shift+Enter),
                                // минуя HardwareKeyboard handler → ломает
                                // «Shift+Enter = newline». Enter=отправка на
                                // desktop живёт в _globalKeyHandler.
                                textInputAction: TextInputAction.newline,
                                // onSubmitted не нужен ни на одной платформе:
                                // mobile отправляет кнопкой, desktop — через
                                // _globalKeyHandler. На desktop этот callback
                                // ещё и триггерился на Shift+Enter (см. выше).
                                onSubmitted: null,
                                // #12: пока открыт typeahead упоминаний, тап (в
                                // т.ч. по самому оверлею) не должен уводить фокус
                                // из поля — иначе focus-listener убирает оверлей
                                // раньше, чем срабатывает onTap выбора, и клик по
                                // подсказке «теряется» (баг на web). По смене
                                // каретки/запроса оверлей всё равно скрывается
                                // через _ctl-listener (_syncTypeahead).
                                onTapOutside: (event) {
                                  if (_typeaheadOverlay != null) return;
                                  _focus.unfocus();
                                },
                                // **B19 (phase2)**: format-кнопки в context-menu
                                // выделения (Bold/Italic) — мобильный/тач-аналог
                                // Ctrl/Cmd+B/I (B12). Добавляются только когда
                                // есть выделение (collapsed → нечего оборачивать).
                                contextMenuBuilder: (ctx, editableState) {
                                  final items = List<ContextMenuButtonItem>.of(
                                    editableState.contextMenuButtonItems,
                                  );
                                  final sel =
                                      editableState.textEditingValue.selection;
                                  if (sel.isValid && !sel.isCollapsed) {
                                    items.addAll([
                                      ContextMenuButtonItem(
                                        label: l.composerFormatBold,
                                        onPressed: () {
                                          editableState.hideToolbar();
                                          _wrapSelection('**');
                                        },
                                      ),
                                      ContextMenuButtonItem(
                                        label: l.composerFormatItalic,
                                        onPressed: () {
                                          editableState.hideToolbar();
                                          _wrapSelection('_');
                                        },
                                      ),
                                    ]);
                                  }
                                  return AdaptiveTextSelectionToolbar.buttonItems(
                                    anchors: editableState.contextMenuAnchors,
                                    buttonItems: items,
                                  );
                                },
                                decoration: InputDecoration(
                                  hintText: l.chatScreenSendHint,
                                  border: InputBorder.none,
                                  // `maxLength` включён (обрезка на 4096
                                  // сохраняется), но встроенный «0/4096»
                                  // counter скрыт: он занимал строку под
                                  // полем и ломал вертикальное выравнивание
                                  // скрепки/микрофона в однострочном режиме.
                                  counterText: '',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                  // **B-voice**: показываем mic IconButton с GestureDetector
                  // для long-press вместо обычного send когда composer
                  // empty. Long-press start → запись; release → stop+send;
                  // короткий tap (< 1s) → snackbar "too short".
                  ValueListenableBuilder<bool>(
                    valueListenable: _hasTextVN,
                    builder: (_, hasText, _) {
                      final albumEditing = widget.albumEdit != null;
                      // Есть вложения в черновике / album-edit → показываем
                      // «Отправить»/«Сохранить», не mic (даже при пустом тексте).
                      final showMic =
                          !hasText &&
                          _pending.isEmpty &&
                          widget.editTarget == null &&
                          !albumEditing &&
                          widget.onSendAttachment != null &&
                          widget.enabled &&
                          !_uploading;
                      if (showMic && !_recording) {
                        return GestureDetector(
                          onLongPressStart: (_) => _startRecording(),
                          onLongPressEnd: (_) => _stopRecording(),
                          child: IconButton(
                            icon: const Icon(Icons.mic_none),
                            tooltip: l.voiceRecordTooltip,
                            onPressed: () {},
                          ),
                        );
                      } else if (_recording) {
                        return IconButton(
                          icon: Icon(
                            Icons.stop_circle,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: l.voiceRecordingHint,
                          onPressed: () => _stopRecording(),
                        );
                      } else {
                        final isEditMode =
                            widget.editTarget != null || albumEditing;
                        // Album-edit: сохранение доступно всегда (пустой дифф →
                        // просто выход из режима). Обычный edit/send — нужен
                        // текст либо вложения.
                        final canSend =
                            widget.enabled &&
                            !_uploading &&
                            (albumEditing || hasText || _pending.isNotEmpty);
                        return IconButton(
                          icon: Icon(isEditMode ? Icons.check : Icons.send),
                          tooltip: isEditMode
                              ? l.messageComposerSaveTooltip
                              : l.chatScreenSendTooltip,
                          onPressed: canSend ? _submit : null,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Горизонтальная лента миниатюр отложенных вложений над полем ввода.
/// Каждая — с крестиком удаления (пока не идёт отправка).
class _PendingAttachmentsStrip extends StatelessWidget {
  const _PendingAttachmentsStrip({required this.pending, this.onRemove});

  final List<PickedAttachment> pending;
  final void Function(int index)? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
        itemCount: pending.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final p = pending[i];
          final isImage = p.mimeType.startsWith('image/');
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: isImage
                      ? Image.memory(
                          p.bytes,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _fallback(theme),
                        )
                      : _fallback(theme),
                ),
              ),
              if (onRemove != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => onRemove!(i),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(
                        Icons.close,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _fallback(ThemeData theme) => Container(
    color: theme.colorScheme.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Icon(
      Icons.insert_drive_file_outlined,
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );
}

/// **Редактирование альбома**: лента миниатюр в album-edit-mode — сначала
/// существующие картинки альбома (рендер из `mxc://` через [MxcImageProvider]),
/// потом добавленные картинки-черновики (`bytes`). У каждой крестик удаления;
/// у существующих удаление копит eventId для redact, у новых — убирает из
/// черновика. Последнюю картинку удалить нельзя ([canRemove] == false).
class _AlbumEditAttachmentsStrip extends StatelessWidget {
  const _AlbumEditAttachmentsStrip({
    required this.existing,
    required this.pending,
    required this.thumbnailRpc,
    required this.fullSizeRpc,
    required this.canRemove,
    required this.onRemoveExisting,
    required this.onRemovePending,
  });

  final List<ComposerAlbumImage> existing;
  final List<PickedAttachment> pending;
  final DownloadAttachmentThumbnailRpc? thumbnailRpc;
  final DownloadAttachmentRpc? fullSizeRpc;
  final bool canRemove;
  final void Function(int index)? onRemoveExisting;
  final void Function(int index)? onRemovePending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
        itemCount: existing.length + pending.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isExisting = i < existing.length;
          final Widget thumb;
          final void Function()? onRemove;
          if (isExisting) {
            final img = existing[i];
            final tRpc = thumbnailRpc;
            final fRpc = fullSizeRpc;
            // RPC обязательны для рендера mxc; без них — file-иконка fallback.
            if (tRpc != null && fRpc != null) {
              thumb = Image(
                image: MxcImageProvider(
                  mxcUrl:
                      img.attachment.thumbnailMxcUrl ?? img.attachment.mxcUrl,
                  thumbnailRpc: tRpc,
                  fullSizeRpc: fRpc,
                ),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(theme),
              );
            } else {
              thumb = _fallback(theme);
            }
            final cb = onRemoveExisting;
            onRemove = (canRemove && cb != null) ? () => cb(i) : null;
          } else {
            final p = pending[i - existing.length];
            final pendingIdx = i - existing.length;
            thumb = p.mimeType.startsWith('image/')
                ? Image.memory(
                    p.bytes,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallback(theme),
                  )
                : _fallback(theme);
            final cb = onRemovePending;
            onRemove = (canRemove && cb != null) ? () => cb(pendingIdx) : null;
          }
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(width: 64, height: 64, child: thumb),
              ),
              if (onRemove != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(
                        Icons.close,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _fallback(ThemeData theme) => Container(
    color: theme.colorScheme.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Icon(
      Icons.insert_drive_file_outlined,
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );
}

/// **Редактирование альбома**: индикатор-чип над полем (аналог
/// [_EditDraftChip], но с иконкой мозаики и текстом «Редактирование альбома»).
class _AlbumEditDraftChip extends StatelessWidget {
  const _AlbumEditDraftChip({required this.onCancel});

  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = NsgL10n.of(context);
    final accent = Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.photo_library_outlined, size: 16, color: accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l.composerEditingAlbum,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          if (onCancel != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: l.composerCancelEdit,
              onPressed: onCancel,
            ),
        ],
      ),
    );
  }
}

class _ReplyDraftChip extends StatelessWidget {
  const _ReplyDraftChip({
    required this.target,
    required this.senderName,
    required this.onCancel,
  });

  final ChatMessage target;
  final String senderName;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = NsgL10n.of(context);
    final preview = target.body.isNotEmpty
        ? target.body
        : (target.attachment?.originalFilename ?? '');
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.composerReplyingTo(senderName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (preview.isNotEmpty)
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (onCancel != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: l.composerCancelReply,
              onPressed: onCancel,
            ),
        ],
      ),
    );
  }
}

/// **B12**: edit-mode indicator над TextField. Похож по стилю на
/// `_ReplyDraftChip`, но с pencil-иконкой и оранжевой акцентной
/// чертой (отличается визуально от reply-сценария).
class _EditDraftChip extends StatelessWidget {
  const _EditDraftChip({required this.target, required this.onCancel});

  final ChatMessage target;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = NsgL10n.of(context);
    final accent = Colors.orange.shade700;
    final preview = target.body.isNotEmpty
        ? target.body
        : (target.attachment?.originalFilename ?? '');
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_outlined, size: 16, color: accent),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.composerEditing,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (preview.isNotEmpty)
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (onCancel != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: l.composerCancelEdit,
              onPressed: onCancel,
            ),
        ],
      ),
    );
  }
}

class _TypeaheadList extends StatelessWidget {
  const _TypeaheadList({
    required this.filtered,
    required this.totalShown,
    required this.totalAll,
    required this.onPick,
  });

  final List<RoomParticipant> filtered;
  final int totalShown;
  final int totalAll;
  final void Function(RoomParticipant) onPick;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          l.mentionTypeaheadEmpty,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    final showHeader = totalAll > totalShown;
    return ListView(
      shrinkWrap: true,
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              l.mentionTypeaheadShowingHeader(totalShown, totalAll),
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        for (final p in filtered)
          ListTile(
            dense: true,
            // **TASK69 2A**: аватар вместо обезличенной иконки — участник
            // узнаётся визуально мгновенно (как в Telegram/Slack).
            leading: NsgAvatarImage(
              mxcUrl: p.avatarUrl,
              fallbackName: _participantName(p),
              size: 32,
            ),
            title: Text(
              _participantName(p),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // **TASK69 2A**: `@username` (публичный handle) вместо полного
            // matrix-id — короче и совпадает с тем, что подставится в текст.
            subtitle: Text(
              _participantHandle(p),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
            onTap: () => onPick(p),
          ),
      ],
    );
  }

  /// Отображаемое имя участника: displayName → matrix-localpart → matrixId.
  static String _participantName(RoomParticipant p) =>
      p.displayName ?? _matrixLocalpart(p.matrixUserId) ?? p.matrixUserId;

  /// Второй ряд: публичный `@username` (Вариант B); при отсутствии —
  /// matrix-localpart с `@`; иначе полный matrixId.
  static String _participantHandle(RoomParticipant p) {
    final u = p.username;
    if (u != null && u.isNotEmpty) return '@$u';
    final lp = _matrixLocalpart(p.matrixUserId);
    if (lp != null && lp.isNotEmpty) return '@$lp';
    return p.matrixUserId;
  }
}

String? _matrixLocalpart(String matrixUserId) {
  if (!matrixUserId.startsWith('@')) return null;
  final colonIdx = matrixUserId.indexOf(':');
  if (colonIdx <= 1) return null;
  return matrixUserId.substring(1, colonIdx);
}

/// **B-voice**: in-composer recording overlay (заменяет text-field).
/// Содержит pulse-индикатор + текст «Запись…» + mm:ss таймер.
/// Real waveform analysis — Phase2 (backlog).
class _RecordingIndicator extends StatefulWidget {
  const _RecordingIndicator({required this.startedAt, required this.textColor});

  final DateTime? startedAt;
  final Color textColor;

  @override
  State<_RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<_RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final started = widget.startedAt;
    final elapsed = started != null
        ? DateTime.now().difference(started)
        : Duration.zero;
    final mm = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          FadeTransition(
            opacity: _pulse,
            child: Icon(
              Icons.fiber_manual_record,
              color: widget.textColor,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(l.voiceRecordingHint, style: TextStyle(color: widget.textColor)),
          const SizedBox(width: 12),
          Text(
            '$mm:$ss',
            style: TextStyle(
              color: widget.textColor.withValues(alpha: 0.8),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
