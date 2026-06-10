import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart'
    show RoomParticipant;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../theme/nsg_messenger_theme.dart';
import 'attachments/attachment_picker.dart';
import 'chat_message.dart';

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
    this.onSendAttachment,
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
  });

  /// **TASK16-A**: signature расширена `mentionedMessengerUserIds`.
  /// `null`/`[]` — no mentions; non-empty — server передаст по mention
  /// flow (см. server-side `MentionResolver.resolveOutgoing`).
  final Future<void> Function(
    String body, {
    List<int>? mentionedMessengerUserIds,
  })
  onSend;
  final bool enabled;

  /// **TASK19 Chunk 3**: attachment send. Если null — paperclip скрыт
  /// (host-app не интегрировал media flow). Future должен complete
  /// после server-confirm-а; spinner крутится до тех пор. Errors
  /// внутрь composer не пробрасываются — host-app показывает snackbar
  /// на свой стороне.
  final Future<void> Function(PickedAttachment picked)? onSendAttachment;

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

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final TextEditingController _ctl = TextEditingController();
  final FocusNode _focus = FocusNode();
  final LayerLink _typeaheadAnchor = LayerLink();
  bool _hasText = false;
  bool _uploading = false;
  OverlayEntry? _typeaheadOverlay;

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
    _ctl.addListener(_syncHasText);
    _ctl.addListener(_syncTypeahead);
    _focus.addListener(_syncTypeahead);
    // Global hardware-keyboard handler — единственный надёжный способ
    // перехватить Enter ДО того как EditableText вставит \n. Shortcuts
    // widget (выше по дереву) и FocusNode.onKeyEvent оба проигрывают
    // встроенным Shortcuts-ам EditableText-а, который находится ближе
    // к primaryFocus. См. doc у `_globalKeyHandler`.
    HardwareKeyboard.instance.addHandler(_globalKeyHandler);
  }

  @override
  void didUpdateWidget(covariant MessageComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
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
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_globalKeyHandler);
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
    _typeaheadOverlay?.remove();
    _typeaheadOverlay = null;
    _ctl.removeListener(_syncHasText);
    _ctl.removeListener(_syncTypeahead);
    _focus.removeListener(_syncTypeahead);
    _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _syncHasText() {
    final has = _ctl.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
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
          '[MessageComposer] _maybeTriggerTyping(hasText=$hasText) '
          '→ onTyping callback is NULL (host-app не прокинул)',
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
  }

  void _showTypeahead(String query, List<RoomParticipant> participants) {
    final ql = query.toLowerCase();
    final filtered = participants.where((p) {
      final dn = (p.displayName ?? '').toLowerCase();
      final lp = _matrixLocalpart(p.matrixUserId)?.toLowerCase() ?? '';
      return ql.isEmpty || dn.contains(ql) || lp.contains(ql);
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
          child: Material(
            elevation: 8,
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
    // Unconditional debug, чтобы видеть что handler вообще вызывается
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
    }

    final isEnter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    if (isEnter && !isShift && !isCtrl && !isMeta && !isAlt) {
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
      // Edit-mode имеет приоритет над reply (они не должны быть
      // одновременно активны, но защищаемся).
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
    if (!widget.enabled) return;
    final trimmed = _ctl.text.trim();
    if (trimmed.isEmpty) return;
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
      setState(() => _hasText = false);
      onEdit(eventId, body, mentionedMessengerUserIds: mentions);
      return;
    }
    _ctl.clear();
    _pendingMentions.clear();
    _hideTypeahead();
    setState(() => _hasText = false);
    widget.onSend(body, mentionedMessengerUserIds: mentions);
  }

  Future<void> _attach() async {
    if (!widget.enabled || _uploading) return;
    final onSendAttachment = widget.onSendAttachment;
    if (onSendAttachment == null) return;
    final picked = await showAttachmentPicker(context: context);
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _uploading = true);
    try {
      await onSendAttachment(picked);
    } catch (_) {
      // Host-app сам показывает snackbar; composer просто un-spinner.
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
    } catch (e) {
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
    } catch (e) {
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
    final canSend = widget.enabled && _hasText && !_uploading;
    final canAttach =
        widget.enabled && !_uploading && widget.onSendAttachment != null;
    // **B-voice**: mic-button показывается когда composer empty (нет
    // текста) + есть attachment-flow + не редактируем. Иначе — обычная
    // send-кнопка.
    final showMic =
        !_hasText &&
        widget.editTarget == null &&
        widget.onSendAttachment != null &&
        widget.enabled &&
        !_uploading;
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // **B12**: edit-indicator имеет приоритет над reply-chip.
            // В UI они не сосуществуют — если editTarget non-null,
            // reply chip не рендерится (host-app должен убедиться что
            // оба не активны одновременно; defensive хвост в UI).
            if (widget.editTarget != null)
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
            Padding(
              padding: bubbleTokens.composerPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.onSendAttachment != null)
                    IconButton(
                      icon: _uploading
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
                            child: TextField(
                              controller: _ctl,
                              focusNode: _focus,
                              enabled: widget.enabled && !_uploading,
                              minLines: 1,
                              maxLines: 5,
                              // Telegram-style лимит. `maxLengthEnforcement`
                              // truncated → typing/paste выше лимита просто
                              // обрезается (без error-dialog-а; counter под
                              // полем визуально подсказывает оставшийся
                              // объём). Сервер тоже валидирует
                              // (MessageBodyTooLargeException) — anti-abuse.
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
                              // textInputAction.send только на mobile —
                              // на desktop macOS этот input action заставляет
                              // платформу вызывать performAction(send) на
                              // Enter ЛЮБОГО типа (включая Shift+Enter),
                              // минуя HardwareKeyboard handler и Shortcuts;
                              // ломает desktop UX «Shift+Enter = newline».
                              textInputAction: _kIsMobile
                                  ? TextInputAction.send
                                  : TextInputAction.newline,
                              // onSubmitted — только на mobile (кнопка Send
                              // на soft-keyboard). На desktop callback
                              // триггерится и на Shift+Enter (см. выше),
                              // что вызывает преждевременный submit.
                              onSubmitted: _kIsMobile ? (_) => _submit() : null,
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                  ),
                  // **B-voice**: показываем mic IconButton с GestureDetector
                  // для long-press вместо обычного send когда composer
                  // empty. Long-press start → запись; release → stop+send;
                  // короткий tap (< 1s) → snackbar "too short".
                  if (showMic && !_recording)
                    GestureDetector(
                      onLongPressStart: (_) => _startRecording(),
                      onLongPressEnd: (_) => _stopRecording(),
                      child: IconButton(
                        icon: const Icon(Icons.mic_none),
                        tooltip: l.voiceRecordTooltip,
                        // Tap (short) ничего не делает — snackbar/feedback
                        // на отмена показывается через _stopRecording если
                        // запись была короткой.
                        onPressed: () {},
                      ),
                    )
                  else if (_recording)
                    IconButton(
                      icon: Icon(
                        Icons.stop_circle,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: l.voiceRecordingHint,
                      onPressed: () => _stopRecording(),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        widget.editTarget != null ? Icons.check : Icons.send,
                      ),
                      tooltip: widget.editTarget != null
                          ? l.messageComposerSaveTooltip
                          : l.chatScreenSendTooltip,
                      onPressed: canSend ? _submit : null,
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
            leading: const Icon(Icons.person_outline, size: 20),
            title: Text(
              p.displayName ??
                  _matrixLocalpart(p.matrixUserId) ??
                  p.matrixUserId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              p.matrixUserId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
            onTap: () => onPick(p),
          ),
      ],
    );
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
