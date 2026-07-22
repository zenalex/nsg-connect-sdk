import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'nsg_l10n_en.dart';
import 'nsg_l10n_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of NsgL10n
/// returned by `NsgL10n.of(context)`.
///
/// Applications need to include `NsgL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/nsg_l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: NsgL10n.localizationsDelegates,
///   supportedLocales: NsgL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the NsgL10n.supportedLocales
/// property.
abstract class NsgL10n {
  NsgL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static NsgL10n of(BuildContext context) {
    return Localizations.of<NsgL10n>(context, NsgL10n)!;
  }

  static const LocalizationsDelegate<NsgL10n> delegate = _NsgL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// Кнопка/tooltip для повторной попытки в error states (chats list, message bubble после failed send).
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Title `CreateChatScreen` + tooltip add-button в `ChatsListScreen` AppBar. Use case: открыть UI создания нового чата (direct по messengerUserId / в будущем поиск по имени).
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get commonNewChat;

  /// Banner показывается когда `state == Error` но есть `lastKnown` cache; UI рендерит кэш + это сообщение наверху. См. `ConnectionLostBanner`.
  ///
  /// In en, this message translates to:
  /// **'Connection lost — showing cache'**
  String get commonConnectionLost;

  /// AppBar title для `ChatsListScreen` — главного экрана со списком всех чатов пользователя.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsListTitle;

  /// Empty-state в `ChatsListScreen` когда listRooms() вернул пустой массив (новый юзер без single чата).
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get chatsListEmpty;

  /// Заголовок error-empty экрана в `ChatsListScreen` когда listRooms() упал И нет lastKnown cache. Сопровождается raw error text + Retry button.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chats'**
  String get chatsListLoadFailed;

  /// Валидация формы в `CreateChatScreen` когда юзер ввёл не-числовой messengerUserId. Локально показывается под полем ввода.
  ///
  /// In en, this message translates to:
  /// **'Enter numeric messengerUserId'**
  String get createChatInvalidId;

  /// Anti-enumeration error из `RoomService.createDirect` (TASK13): peer не существует / в другом tenant / == caller. Показывается без uid-leak.
  ///
  /// In en, this message translates to:
  /// **'User unavailable'**
  String get createChatPeerUnavailable;

  /// Help-text в `CreateChatScreen` объясняющий MVP scope (только direct по числовому id; имя/handle search в TASK42).
  ///
  /// In en, this message translates to:
  /// **'Direct chat by messengerUserId. Name search — TASK42.'**
  String get createChatHelp;

  /// Submit-button в `CreateChatScreen` форме.
  ///
  /// In en, this message translates to:
  /// **'Create direct chat'**
  String get createChatSubmit;

  /// Empty-state в `ChatScreen` когда room новая, history-pagination вернула 0 messages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet — write the first one'**
  String get chatScreenEmpty;

  /// Заголовок error-empty в `ChatScreen` когда listMessages() упал на init без lastKnown.
  ///
  /// In en, this message translates to:
  /// **'Failed to load messages'**
  String get chatScreenLoadFailed;

  /// Placeholder в `MessageComposer` TextField — подсказка пользователю что писать.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get chatScreenSendHint;

  /// Tooltip send-button (paper-plane icon) в `MessageComposer`. Активен только при non-empty composer + state==Ready.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatScreenSendTooltip;

  /// Fallback name в `RoomSummaryTile` когда `RoomSummary.name == null` (group без явного имени, direct без participants info).
  ///
  /// In en, this message translates to:
  /// **'(no name)'**
  String get roomSummaryNoName;

  /// Fallback subtitle в `RoomSummaryTile` когда `lastMessagePreview == null` (комната создана но никто не написал).
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get roomSummaryNoMessages;

  /// Cancel-button в confirm-диалогах. TASK42: leave-confirm + future destructive actions.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// TASK42 Chunk 2: header в bottom-sheet который открывается на long-press `RoomSummaryTile`. Показывает available actions (mute/archive/leave).
  ///
  /// In en, this message translates to:
  /// **'Chat actions'**
  String get roomActionSheetTitle;

  /// TASK42: action в room-action-sheet. Открывает submenu с durations (1h/8h/1d/1w/forever).
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get roomActionMute;

  /// TASK42: action в room-action-sheet, видна когда `room.muted == true`. Сразу делает unmute (без submenu).
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get roomActionUnmute;

  /// TASK42: mute-duration option (1 час).
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get roomActionMuteFor1Hour;

  /// TASK42: mute-duration option (8 часов, типичная workday/sleep).
  ///
  /// In en, this message translates to:
  /// **'8 hours'**
  String get roomActionMuteFor8Hours;

  /// TASK42: mute-duration option (24 часа).
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get roomActionMuteFor1Day;

  /// TASK42: mute-duration option (7 дней, типичный отпуск short).
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get roomActionMuteFor1Week;

  /// TASK42: mute-duration option, использует `kMuteForever` sentinel (`DateTime.utc(9999, 1, 1)`). Без timer-а unmute, юзер должен явно нажать Unmute.
  ///
  /// In en, this message translates to:
  /// **'Forever'**
  String get roomActionMuteForever;

  /// TASK42: title secondary bottom-sheet с mute-durations (когда юзер выбрал Mute из главного sheet-а).
  ///
  /// In en, this message translates to:
  /// **'Mute until'**
  String get roomActionMuteUntilTitle;

  /// TASK42: action в room-action-sheet. Скрывает чат с active-tab. Restore через unarchive в archived-tab.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get roomActionArchive;

  /// TASK42: action в room-action-sheet, видна когда `room.archived == true`. Restore back to active list.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get roomActionUnarchive;

  /// TASK75: action в room-action-sheet для support-комнат. Оператор скрывает чат у себя до следующего сообщения заявителя (тикет не закрывается).
  ///
  /// In en, this message translates to:
  /// **'Close (until reply)'**
  String get roomActionDismissSupport;

  /// TASK42: destructive action в room-action-sheet. Покидает Matrix room + удаляет local membership. Открывает confirm-dialog.
  ///
  /// In en, this message translates to:
  /// **'Leave chat'**
  String get roomActionLeave;

  /// TASK42: title confirm-dialog для leaveRoom. Destructive action, требует явного OK.
  ///
  /// In en, this message translates to:
  /// **'Leave chat?'**
  String get roomActionLeaveConfirmTitle;

  /// TASK42: body leave-confirm-dialog. Объясняет что other participants получат membershipLeft event.
  ///
  /// In en, this message translates to:
  /// **'You will be removed from the conversation. Other participants will see that you left.'**
  String get roomActionLeaveConfirmBody;

  /// TASK42: snackbar когда mute/archive/leave RPC упал. Optimistic-update reverted, юзеру предлагается retry.
  ///
  /// In en, this message translates to:
  /// **'Action failed — try again'**
  String get roomActionFailedSnack;

  /// TASK42: tooltip overflow-menu button в `ChatsListScreen` AppBar (3 dots → Active/Archived/All).
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get chatsListFilterMenuTooltip;

  /// TASK42: PopupMenuItem `ChatsListFilter.active` (default — server-side filter `includeArchived=false`).
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get chatsListFilterActive;

  /// TASK42: PopupMenuItem `ChatsListFilter.archived` (server возвращает все, SDK post-filter `r.archived`).
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get chatsListFilterArchived;

  /// TASK42: PopupMenuItem `ChatsListFilter.all` (debug / power-user — без post-filter, видны и active и archived вместе).
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get chatsListFilterAll;

  /// TASK42 Chunk 3: tooltip search-icon в `ChatsListScreen` AppBar. На tap activates inline TextField mode.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get chatsListSearchTooltip;

  /// TASK42 Chunk 3: placeholder в search TextField. ILIKE на Room.name, server-side; 300ms debounce.
  ///
  /// In en, this message translates to:
  /// **'Search chats…'**
  String get chatsListSearchHint;

  /// TASK42 Chunk 3: tooltip clear-button (X icon) в search TextField. На tap reset query → refresh без search-параметра.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get chatsListSearchClearTooltip;

  /// TASK42 Chunk 3: empty-state в `ChatsListScreen` когда search вернул 0 results (отдельно от `chatsListEmpty` который для no-search empty).
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get chatsListSearchEmpty;

  /// TASK42 Chunk 3: tooltip product-filter dropdown в `ChatsListScreen` AppBar. Виден только в standalone-mode когда `availableProducts.length > 1`.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get chatsListProductFilterTooltip;

  /// TASK42 Chunk 3: PopupMenuItem `productFilter == null` — снимает product filter, показывает rooms из всех products.
  ///
  /// In en, this message translates to:
  /// **'All products'**
  String get chatsListProductFilterAll;

  /// TASK44 фаза 1: подпись папки-таба «Все» (плоский список) в полосе авто-папок над списком чатов (Telegram-style).
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get chatsListFolderAll;

  /// TASK44 фаза 1: подпись папки-таба «Личные» — комнаты без привязки к продукту (direct / обычные группы).
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get chatsListFolderPersonal;

  /// TASK44 фаза 1: fallback-подпись продуктовой папки, когда `Product.displayName`/`externalKey` недоступны (getAvailableProducts ещё не загружен или продукт не вернулся). Подставляется `productId`.
  ///
  /// In en, this message translates to:
  /// **'Product {productId}'**
  String chatsListFolderProductFallback(int productId);

  /// TASK44 фаза 1.5: subtitle строки-папки, когда у самого свежего чата папки нет превью — показываем число чатов в папке.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} chat} other{{count} chats}}'**
  String chatsListFolderRoomCount(int count);

  /// TASK44 фаза 1: заголовок секции support-комнат (`RoomType.support`) внутри продуктовой папки. Support-чаты выносятся вверх отдельной секцией.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get chatsListFolderSupportSection;

  /// TASK44 фаза 1: заголовок секции остальных (не-support) комнат внутри продуктовой папки, когда над ними есть секция Support.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsListFolderOtherSection;

  /// TASK75: имя агрегатной папки-строки «Поддержка» в корне списка чатов (операторский инбокс). Раньше FolderRow рисовал её как «Product 0» — у агрегатной папки нет productId.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get chatsListFolderSupport;

  /// TASK62: fallback-имя пользовательской папки, если `customName` почему-то пуст.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get chatsListFolderCustom;

  /// TASK68: название раздела «Избранное» — набор self-чатов (комнат с единственным участником, аналог Telegram Saved Messages). Заголовок папки-строки и drill-in экрана.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedChatsTitle;

  /// TASK68: кнопка создания нового именованного раздела «Избранного» («заметки», «файлообмен», ...).
  ///
  /// In en, this message translates to:
  /// **'New section'**
  String get savedChatsCreateAction;

  /// TASK68: подсказка в поле ввода имени нового раздела «Избранного».
  ///
  /// In en, this message translates to:
  /// **'Section name'**
  String get savedChatsCreateHint;

  /// TASK68: пустое состояние раздела «Избранное» — объясняет главный сценарий (передать что-то на другое устройство).
  ///
  /// In en, this message translates to:
  /// **'Send yourself notes, files and links — they sync across all your devices.'**
  String get savedChatsEmpty;

  /// TASK68: сервер отказал по потолку числа self-чатов (код saved_chat_limit).
  ///
  /// In en, this message translates to:
  /// **'Section limit reached ({limit}). Delete an unused one first.'**
  String savedChatsLimitReached(int limit);

  /// TASK68: сервер отказал из-за дубля имени раздела (код saved_chat_name_taken).
  ///
  /// In en, this message translates to:
  /// **'A section with this name already exists.'**
  String get savedChatsNameTaken;

  /// TASK68: строка настроек комнаты — TTL автоочистки сообщений раздела «Избранного».
  ///
  /// In en, this message translates to:
  /// **'Auto-delete messages'**
  String get autoCleanupTitle;

  /// TASK68: подпись под настройкой автоочистки. Ключевая гарантия §5 ТЗ: закреплённое переживает свип, это и есть способ защитить важное.
  ///
  /// In en, this message translates to:
  /// **'Pinned messages are never deleted'**
  String get autoCleanupHint;

  /// TASK68: вариант «не удалять» в выборе TTL автоочистки (autoCleanupTtlSeconds == null).
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get autoCleanupOff;

  /// TASK68: пресет TTL автоочистки в днях (1 / 7 / 30).
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{After {days} day} other{After {days} days}}'**
  String autoCleanupAfterDays(int days);

  /// TASK19 Chunk 3: header в bottom-sheet который открывается на tap-on-paperclip-icon в `MessageComposer`. Показывает доступные source-ы attachment (camera/gallery). file_picker — Phase2.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get attachActionSheetTitle;

  /// TASK19 Chunk 3: action в attach bottom-sheet — открывает camera через image_picker.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get attachActionCamera;

  /// TASK19 Chunk 3: action в attach bottom-sheet — открывает photo gallery через image_picker.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get attachActionGallery;

  /// Issue #54 п.2: тот же action что attachActionGallery, но на desktop/web — там нет «галереи», есть обычный диалог выбора файла с фильтром по картинкам.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get attachActionImage;

  /// Issue #54 п.2: action в attach bottom-sheet — выбор ПРОИЗВОЛЬНОГО файла (документ/архив/видео) через file_picker.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get attachActionFile;

  /// Issue #54 п.2: snackbar о файлах, отвергнутых клиентским лимитом kMaxAttachmentBytes. Показывается вместо молчаливого отброса — иначе пользователю кажется, что файл потерялся.
  ///
  /// In en, this message translates to:
  /// **'Too large (limit 50 MB), not attached: {names}'**
  String attachFileTooLarge(String names);

  /// TASK19 Chunk 3: snackbar когда upload через `messenger.uploadAttachment` упал (network / server reject mime). UI revert composer state.
  ///
  /// In en, this message translates to:
  /// **'Upload failed — try again'**
  String get attachUploadFailed;

  /// Issue #54: server rejected the attachment (AttachmentRejectReason.unsupportedType). Раньше такой реджект был НЕВИДИМ — сообщение просто получало красный «!» без объяснения.
  ///
  /// In en, this message translates to:
  /// **'Can\'t send “{filename}” — this file type isn\'t supported'**
  String attachRejectedType(String filename);

  /// Issue #54: реджект по extension-blacklist (AttachmentRejectReason.blockedExtension) — .exe/.apk/.msi и т.п.
  ///
  /// In en, this message translates to:
  /// **'Can\'t send “{filename}” — executable files aren\'t allowed'**
  String attachRejectedExecutable(String filename);

  /// Issue #54: реджект по size cap (AttachmentRejectReason.tooLarge). `maxMb` — лимит, который нарушен (50 для image/file, 100 для video).
  ///
  /// In en, this message translates to:
  /// **'Can\'t send “{filename}” — the file is larger than {maxMb} MB'**
  String attachRejectedTooLarge(String filename, int maxMb);

  /// TASK19 Chunk 3: fallback в `_FileRow` когда `AttachmentRef.originalFilename == ''` (defensive — server обычно non-empty).
  ///
  /// In en, this message translates to:
  /// **'Unnamed file'**
  String get attachUnnamedFallback;

  /// TASK19 Chunk 3: tooltip paperclip-icon в `MessageComposer`. Tap открывает `showAttachmentPicker` bottom-sheet.
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get attachTooltip;

  /// B-voice: tooltip microphone-кнопки в `MessageComposer`. Showed когда text field empty + onSendAttachment != null.
  ///
  /// In en, this message translates to:
  /// **'Hold to record'**
  String get voiceRecordTooltip;

  /// B-voice: indicator в composer-е во время записи (заменяет text field). Сопровождается mm:ss таймером.
  ///
  /// In en, this message translates to:
  /// **'Recording…'**
  String get voiceRecordingHint;

  /// B-voice: snackbar text когда юзер отпустил mic-button раньше 1 секунды. Запись отменяется.
  ///
  /// In en, this message translates to:
  /// **'Recording too short'**
  String get voiceRecordTooShort;

  /// B-voice: snackbar text когда AudioRecorder.hasPermission() вернул false. Юзер должен дать доступ через OS settings.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied'**
  String get voiceRecordPermissionDenied;

  /// B-voice: generic snackbar text при ошибке start/stop record (нет mic, codec не поддержан, etc.).
  ///
  /// In en, this message translates to:
  /// **'Recording failed'**
  String get voiceRecordError;

  /// TASK37 Chunk 2: header bottom-sheet который открывается на long-press `MessageBubble`. Items: Edit / Delete / Copy.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageActionSheetTitle;

  /// TASK37: edit action в message bottom-sheet. Visible только для own + non-deleted messages.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get messageActionEdit;

  /// TASK37: delete action. Visible только для own + non-deleted messages. Destructive — confirm dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get messageActionDelete;

  /// TASK37: copy text action. Always-enabled (Q4 sign-off). Использует Clipboard.setData.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get messageActionCopy;

  /// TASK37: title input dialog для edit. Open после Edit action в bottom-sheet.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get messageActionEditDialogTitle;

  /// TASK37: save-button в edit dialog. Disabled когда `body.trim().isEmpty` (Q5 client-side validation).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get messageActionEditSave;

  /// TASK37: title destructive confirm dialog для delete.
  ///
  /// In en, this message translates to:
  /// **'Delete message?'**
  String get messageActionDeleteConfirmTitle;

  /// TASK37: body confirm dialog. Объясняет что delete = visible to all participants (Telegram «delete for everyone» semantics).
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. The message will be removed for everyone in the chat.'**
  String get messageActionDeleteConfirmBody;

  /// TASK37: snackbar когда editMessage RPC упал (network / server reject). Optimistic-update reverted.
  ///
  /// In en, this message translates to:
  /// **'Edit failed — try again'**
  String get messageEditFailed;

  /// TASK37: snackbar когда deleteMessage RPC упал. Optimistic-tombstone reverted.
  ///
  /// In en, this message translates to:
  /// **'Delete failed — try again'**
  String get messageDeleteFailed;

  /// TASK37: italic tombstone placeholder в bubble когда `deletedAt != null`. Telegram-style soft-delete UX.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeletedPlaceholder;

  /// TASK37: small label рядом с timestamp в bubble когда `editedAt != null`. Не показывает diff/history (Phase2).
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get messageEditedBadge;

  /// Кнопка под обрезанным длинным сообщением — раскрывает полный текст inline.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get messageShowMore;

  /// TASK37: snackbar после Copy action — feedback что text put в clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get messageCopiedSnack;

  /// TASK16-A: action sheet item для reply на сообщение. Hidden для tombstone.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get messageActionReply;

  /// TASK69 2C: action sheet item — reply на сообщение + @упоминание автора в композере. Visible только в группах для чужих сообщений.
  ///
  /// In en, this message translates to:
  /// **'Reply with mention'**
  String get messageActionReplyWithMention;

  /// TASK69 2C: пункт «Упомянуть» в шите по тапу на аватар участника (group peer-bubble). Вставляет @имя в композер.
  ///
  /// In en, this message translates to:
  /// **'Mention'**
  String get mentionParticipantAction;

  /// F2 ч.1: заголовок шита полного emoji-picker-а для реакций.
  ///
  /// In en, this message translates to:
  /// **'Choose a reaction'**
  String get emojiPickerTitle;

  /// F2 ч.1: категория эмодзи — смайлы.
  ///
  /// In en, this message translates to:
  /// **'Smileys & emotion'**
  String get emojiCategorySmileys;

  /// F2 ч.1: категория эмодзи — жесты.
  ///
  /// In en, this message translates to:
  /// **'Gestures & people'**
  String get emojiCategoryGestures;

  /// F2 ч.1: категория эмодзи — сердца.
  ///
  /// In en, this message translates to:
  /// **'Hearts & symbols'**
  String get emojiCategoryHearts;

  /// F2 ч.1: категория эмодзи — животные.
  ///
  /// In en, this message translates to:
  /// **'Animals & nature'**
  String get emojiCategoryAnimals;

  /// F2 ч.1: категория эмодзи — еда.
  ///
  /// In en, this message translates to:
  /// **'Food & drink'**
  String get emojiCategoryFood;

  /// F2 ч.1: категория эмодзи — активности.
  ///
  /// In en, this message translates to:
  /// **'Activity & objects'**
  String get emojiCategoryActivity;

  /// F2 ч.1: категория эмодзи — символы.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get emojiCategorySymbols;

  /// TASK38: action sheet item — создать задачу во внешнем трекере из сообщения. Visible только если taskIntegrationEnabled.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get messageActionCreateTask;

  /// TASK38: snackbar после успешного createTaskFromMessage. taskKey = externalTaskKey ?? externalTaskId.
  ///
  /// In en, this message translates to:
  /// **'Task {taskKey} created'**
  String taskCreatedSnack(String taskKey);

  /// TASK38: snackbar когда createTaskFromMessage RPC упал (network / server reject).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create task'**
  String get taskCreateFailed;

  /// TASK38: snackbar при TaskIntegrationNotConfiguredException — интеграция выключена для tenant-а.
  ///
  /// In en, this message translates to:
  /// **'Task integration is not configured'**
  String get taskIntegrationDisabled;

  /// TASK16-A: header reply quote chip над composer-ом. {name} — displayName того, кому отвечаем (либо matrixUserId fallback).
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String composerReplyingTo(String name);

  /// TASK16-A: tooltip close-X кнопки в reply quote chip composer-а.
  ///
  /// In en, this message translates to:
  /// **'Cancel reply'**
  String get composerCancelReply;

  /// B12: header edit-mode indicator chip над composer-ом (вместо reply-chip когда композер в edit-mode).
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get composerEditing;

  /// Album-edit indicator chip над composer-ом: редактируется весь альбом (картинки + подпись), а не одиночное сообщение.
  ///
  /// In en, this message translates to:
  /// **'Editing album'**
  String get composerEditingAlbum;

  /// B19: text-selection context-menu action — wrap selection in **bold** markdown.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get composerFormatBold;

  /// B19: text-selection context-menu action — wrap selection in _italic_ markdown.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get composerFormatItalic;

  /// B12: tooltip close-X кнопки в edit-indicator chip композер-а.
  ///
  /// In en, this message translates to:
  /// **'Cancel edit'**
  String get composerCancelEdit;

  /// B12: tooltip send-button когда композер в edit-mode (иконка Icons.check вместо Icons.send).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get messageComposerSaveTooltip;

  /// B9 typing indicator footer над composer-ом: 1 peer печатает. {name} — displayName.
  ///
  /// In en, this message translates to:
  /// **'{name} is typing…'**
  String typingSingle(String name);

  /// B9: 2 peers печатают.
  ///
  /// In en, this message translates to:
  /// **'{name1} and {name2} are typing…'**
  String typingPair(String name1, String name2);

  /// B15: dialog title for room rename.
  ///
  /// In en, this message translates to:
  /// **'Rename chat'**
  String get roomRenameTitle;

  /// B15: TextField hint inside rename dialog.
  ///
  /// In en, this message translates to:
  /// **'New chat name'**
  String get roomRenameHint;

  /// B15: confirm button in rename dialog.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get roomRenameSave;

  /// B15: cancel button in rename dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get roomRenameCancel;

  /// B15: snackbar после server reject (InsufficientPowerException / network).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t rename the chat — try again or check your role'**
  String get roomRenameFailed;

  /// Group read-receipts bottom-sheet title.
  ///
  /// In en, this message translates to:
  /// **'Seen by'**
  String get readReceiptsSheetTitle;

  /// Section header listing peers who have read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get readReceiptsSectionRead;

  /// Section header listing peers who haven't read yet.
  ///
  /// In en, this message translates to:
  /// **'Not read'**
  String get readReceiptsSectionUnread;

  /// Shown in the sheet for groups > 25 participants — only count, no per-user breakdown.
  ///
  /// In en, this message translates to:
  /// **'Detailed read list is only available for groups of up to 25 members. {count} of {total} have read.'**
  String readReceiptsLargeGroupHint(int count, int total);

  /// Sheet placeholder when peer read count is zero.
  ///
  /// In en, this message translates to:
  /// **'No one has read yet'**
  String get readReceiptsNobodyRead;

  /// Compact label on bubble for group read count next to eye icon.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String readReceiptsCountLabel(int count);

  /// Destructive button label in GroupSettingsScreen — owner kicks everyone and leaves.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get groupDissolveAction;

  /// Confirm dialog title for group dissolve.
  ///
  /// In en, this message translates to:
  /// **'Delete group «{name}»?'**
  String groupDissolveConfirmTitle(String name);

  /// Confirm dialog body for group dissolve.
  ///
  /// In en, this message translates to:
  /// **'All members will be removed and the chat will close. This cannot be undone.'**
  String get groupDissolveConfirmBody;

  /// Progress snackbar while loop of kickUser+leaveRoom is running.
  ///
  /// In en, this message translates to:
  /// **'Deleting group…'**
  String get groupDissolveProgress;

  /// Snackbar when one or more kick calls failed; some members may remain.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t fully delete — try again. Members removed: {kicked} of {total}.'**
  String groupDissolveFailed(int kicked, int total);

  /// Snackbar after successful dissolve.
  ///
  /// In en, this message translates to:
  /// **'Group deleted'**
  String get groupDissolveSuccess;

  /// B9: 3+ peers печатают — заменяем именами на счётчик чтобы не растягивать footer.
  ///
  /// In en, this message translates to:
  /// **'{count} people are typing…'**
  String typingManyCount(int count);

  /// TASK16-A: placeholder в bubble reply chip когда target lookup в state.messages дал cache miss (pre-paginated либо not-yet-loaded).
  ///
  /// In en, this message translates to:
  /// **'Original message unavailable'**
  String get replyChipUnavailable;

  /// TASK16-A: empty-state в @-typeahead overlay когда query фильтрует все participants.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get mentionTypeaheadEmpty;

  /// TASK16-A: header в @-typeahead когда total participants > 30 (TASK13 cap). Сейчас участников много, видно top 30; Phase2 RPC search.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total}'**
  String mentionTypeaheadShowingHeader(int shown, int total);

  /// TASK29 Chunk 2: tooltip для crown-badge у owner-роли в participant tile.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleBadgeOwner;

  /// TASK29 Chunk 2: tooltip для shield-badge у admin-роли.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleBadgeAdmin;

  /// TASK29 Chunk 2: action sheet item для kick — admin/owner caller, target = member of room.
  ///
  /// In en, this message translates to:
  /// **'Kick from room'**
  String get roomAdminKickAction;

  /// TASK29 Chunk 2: action sheet item для ban — destructive (red), blocks rejoin.
  ///
  /// In en, this message translates to:
  /// **'Ban from room'**
  String get roomAdminBanAction;

  /// TASK29 Chunk 2: action sheet item для promote member → admin (owner-only caller).
  ///
  /// In en, this message translates to:
  /// **'Promote to admin'**
  String get roomAdminPromoteAction;

  /// TASK29 Chunk 2: action sheet item для promote admin → owner.
  ///
  /// In en, this message translates to:
  /// **'Promote to owner'**
  String get roomAdminPromoteOwnerAction;

  /// TASK29 Chunk 2: action sheet item для demote admin/owner → member.
  ///
  /// In en, this message translates to:
  /// **'Demote to member'**
  String get roomAdminDemoteAction;

  /// TASK29 Chunk 2: confirm-dialog title для kick.
  ///
  /// In en, this message translates to:
  /// **'Kick {name}?'**
  String roomAdminKickConfirmTitle(String name);

  /// TASK29 Chunk 2: confirm-dialog body для kick — explains revocability.
  ///
  /// In en, this message translates to:
  /// **'{name} can be re-invited later.'**
  String roomAdminKickConfirmBody(String name);

  /// TASK29 Chunk 2: confirm-dialog title для ban.
  ///
  /// In en, this message translates to:
  /// **'Ban {name}?'**
  String roomAdminBanConfirmTitle(String name);

  /// TASK29 Chunk 2: confirm-dialog body для ban.
  ///
  /// In en, this message translates to:
  /// **'{name} cannot rejoin until unbanned.'**
  String roomAdminBanConfirmBody(String name);

  /// TASK29 Chunk 2: snackbar mapping для LastOwnerCannotDemoteException.
  ///
  /// In en, this message translates to:
  /// **'Cannot demote the last owner. Promote another member first.'**
  String get roomAdminLastOwnerError;

  /// TASK29 Chunk 2: snackbar mapping для InsufficientPowerException.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action.'**
  String get roomAdminInsufficientPowerError;

  /// TASK29 Chunk 2: snackbar fallback для network / generic errors.
  ///
  /// In en, this message translates to:
  /// **'Action failed — try again.'**
  String get roomAdminGenericError;

  /// TASK29 Chunk 2: AppBar title для BannedUsersScreen.
  ///
  /// In en, this message translates to:
  /// **'Banned users'**
  String get bannedUsersTitle;

  /// TASK29 Chunk 2: empty-state widget при нулевом списке banned.
  ///
  /// In en, this message translates to:
  /// **'No banned users'**
  String get bannedUsersEmpty;

  /// TASK29 Chunk 2: button text per banned-user tile.
  ///
  /// In en, this message translates to:
  /// **'Unban'**
  String get bannedUsersUnbanAction;

  /// #23: success toast after unban — clarifies unban != re-invite (Matrix ban->leave).
  ///
  /// In en, this message translates to:
  /// **'Unbanned — invite them again if needed'**
  String get bannedUsersUnbanSuccess;

  /// B25: snackbar action after unban — re-invite the user back to the room via inviteToRoom.
  ///
  /// In en, this message translates to:
  /// **'Re-invite'**
  String get bannedUsersReinviteAction;

  /// B25: toast after a successful re-invite from the banned-users screen.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent'**
  String get bannedUsersReinviteSuccess;

  /// TASK29 Chunk 2: AppBar title для ParticipantsScreen.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participantsTitle;

  /// TASK29 Chunk 2: AppBar overflow menu item navigating to BannedUsersScreen (admin-only).
  ///
  /// In en, this message translates to:
  /// **'Banned users'**
  String get participantsBannedMenuItem;

  /// TASK20-Phase2 Chunk 4: AppBar title для NotificationSettingsScreen.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationSettingsTitle;

  /// TASK20-Phase2 Chunk 4: SwitchListTile title — toggle для message preview в push-notifications.
  ///
  /// In en, this message translates to:
  /// **'Show message preview'**
  String get notificationSettingsPreviewTitle;

  /// TASK20-Phase2 Chunk 4: SwitchListTile subtitle — описывает privacy trade-off.
  ///
  /// In en, this message translates to:
  /// **'Display sender and message text on the lock screen. Turn off to hide content.'**
  String get notificationSettingsPreviewSubtitle;

  /// B11: SwitchListTile title — toggle whether others see your read receipts.
  ///
  /// In en, this message translates to:
  /// **'Send read receipts'**
  String get notificationSettingsReadReceiptsTitle;

  /// B11: SwitchListTile subtitle — explains the incognito-read trade-off.
  ///
  /// In en, this message translates to:
  /// **'Others see when you\'ve read their messages. Turn off to read privately.'**
  String get notificationSettingsReadReceiptsSubtitle;

  /// TASK20-Phase2 Chunk 4: snackbar при RPC fail в setNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save settings — try again'**
  String get notificationSettingsSaveFailed;

  /// Settings: subheader above privacy toggles on the notification settings screen.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacySectionTitle;

  /// Settings: SwitchListTile title — toggle whether other users can find you by name or email in search.
  ///
  /// In en, this message translates to:
  /// **'Findable in search'**
  String get notificationSettingsDiscoverableTitle;

  /// Settings: SwitchListTile subtitle — explains the discoverable privacy trade-off.
  ///
  /// In en, this message translates to:
  /// **'Others can find you by name or email. Turn off to hide from search.'**
  String get notificationSettingsDiscoverableSubtitle;

  /// TASK20 followup (a): tooltip над ConnectionStateIndicator widget-ом когда transport WS живой.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectionStateHealthy;

  /// TASK20 followup (a): tooltip когда bus в reconnecting state (1-2 failed attempts, retrying).
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get connectionStateReconnecting;

  /// TASK20 followup (a): tooltip когда bus в disconnected state (3+ failed reconnects, still retrying).
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get connectionStateDisconnected;

  /// TASK43: AppBar title for the support team management screen.
  ///
  /// In en, this message translates to:
  /// **'Support team'**
  String get supportTeamTitle;

  /// TASK43: empty state when the support team has no members.
  ///
  /// In en, this message translates to:
  /// **'No team members yet'**
  String get supportTeamEmpty;

  /// TASK43: hint text of the add-member email input.
  ///
  /// In en, this message translates to:
  /// **'Add operator by email'**
  String get supportTeamAddHint;

  /// TASK43: label of the add-member button.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get supportTeamAddAction;

  /// TASK43: label of the remove-member action.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get supportTeamRemoveAction;

  /// TASK48: subtitle badge for a tier-2 (senior/escalation) support operator.
  ///
  /// In en, this message translates to:
  /// **'Escalation'**
  String get supportTeamTierEscalation;

  /// TASK48: owner action promoting a member to tier 2 (escalation).
  ///
  /// In en, this message translates to:
  /// **'Make senior (escalation)'**
  String get supportTeamMakeEscalation;

  /// TASK48: owner action demoting a member to tier 1 (front line).
  ///
  /// In en, this message translates to:
  /// **'Move back to front line'**
  String get supportTeamMakeFrontline;

  /// TASK76: owner action promoting a member to owner (может управлять составом команды).
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get supportTeamMakeOwner;

  /// TASK76: owner action demoting another owner to member. Последнего owner-а сервер понизить не даст.
  ///
  /// In en, this message translates to:
  /// **'Revoke admin'**
  String get supportTeamRevokeOwner;

  /// TASK48 iter2: label for the team's auto-escalation timeout setting.
  ///
  /// In en, this message translates to:
  /// **'Auto-escalation timeout'**
  String get supportTeamTimeoutLabel;

  /// TASK48 iter2: short unit for minutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get supportTeamMinutesShort;

  /// TASK43: badge for a support team owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get supportTeamRoleOwner;

  /// TASK43: badge for a support team member/operator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get supportTeamRoleMember;

  /// TASK43: badge shown for a bot member of the support team.
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get supportTeamBotBadge;

  /// TASK43: shown when the caller is not a team member (getSupportTeam threw).
  ///
  /// In en, this message translates to:
  /// **'Support team is not available'**
  String get supportTeamUnavailable;

  /// TASK43: generic error snackbar for add/remove failures.
  ///
  /// In en, this message translates to:
  /// **'Action failed — please try again'**
  String get supportTeamActionFailed;

  /// TASK45 phase 2: app-bar / overflow action in an object room that connects the whole NSG support team. Visible to every participant of the object chat.
  ///
  /// In en, this message translates to:
  /// **'Contact developers'**
  String get escalateToDevelopersAction;

  /// TASK45 phase 2: snackbar shown after escalateToSupportTeam succeeds.
  ///
  /// In en, this message translates to:
  /// **'NSG team connected'**
  String get escalateToDevelopersDone;

  /// TASK45 phase 2: snackbar shown when escalateToSupportTeam throws.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect the team — please try again'**
  String get escalateToDevelopersFailed;

  /// TASK48: overflow action in a support chat that calls the next support tier (senior operator).
  ///
  /// In en, this message translates to:
  /// **'Call senior operator'**
  String get escalateSupportAction;

  /// TASK48: snackbar shown after escalateSupportRoom succeeds.
  ///
  /// In en, this message translates to:
  /// **'Senior operator connected'**
  String get escalateSupportDone;

  /// TASK48: snackbar shown when escalateSupportRoom throws.
  ///
  /// In en, this message translates to:
  /// **'Escalation failed — please try again'**
  String get escalateSupportFailed;

  /// TASK48 / review fix #5: snackbar when escalateSupportRoom is a no-op (lost race / no higher tier / already present).
  ///
  /// In en, this message translates to:
  /// **'No one to escalate — no higher tier or already here'**
  String get escalateSupportNoop;

  /// TASK45 phase 1: title of the catalog screen listing a product's object rooms for a support-team member.
  ///
  /// In en, this message translates to:
  /// **'Object chats — {product}'**
  String objectRoomsCatalogTitle(String product);

  /// TASK45 phase 1: empty-state for the object rooms catalog.
  ///
  /// In en, this message translates to:
  /// **'No object chats yet'**
  String get objectRoomsCatalogEmpty;

  /// TASK45 phase 1: shown when the caller is not a support team member (listProductObjectRooms threw).
  ///
  /// In en, this message translates to:
  /// **'Catalog is not available'**
  String get objectRoomsCatalogUnavailable;

  /// TASK45 phase 1: snackbar shown when joinProductRoom throws.
  ///
  /// In en, this message translates to:
  /// **'Failed to join the chat — please try again'**
  String get objectRoomsCatalogJoinFailed;

  /// TASK45 phase 1: badge on a catalog row where the team member has already joined the room.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get objectRoomsCatalogMemberBadge;

  /// TASK45 phase 1: action to leave an object room once the issue is resolved.
  ///
  /// In en, this message translates to:
  /// **'Leave chat'**
  String get objectRoomsCatalogLeaveAction;

  /// TASK45 phase 1: snackbar shown after leaveProductRoom succeeds.
  ///
  /// In en, this message translates to:
  /// **'You left the chat'**
  String get objectRoomsCatalogLeaveDone;

  /// TASK45 phase 1: menu entry (in the support team screen) opening the object rooms catalog.
  ///
  /// In en, this message translates to:
  /// **'Object chats'**
  String get objectRoomsCatalogEntry;

  /// TASK46 (UI): tooltip on the phone IconButton in the direct 1:1 chat app-bar that starts a voice call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callStartTooltip;

  /// Snackbar when the user taps Call while another call is active (one call at a time; hold/conference is future work).
  ///
  /// In en, this message translates to:
  /// **'A call is already in progress'**
  String get callAlreadyActive;

  /// TASK46 (UI): outgoing-call overlay heading while ringing. {peer} is the callee display name.
  ///
  /// In en, this message translates to:
  /// **'Calling {peer}…'**
  String callOutgoingTitle(String peer);

  /// TASK46 (UI): incoming-call overlay heading. {caller} is the caller display name.
  ///
  /// In en, this message translates to:
  /// **'{caller} is calling'**
  String callIncomingTitle(String caller);

  /// TASK46 (UI): incoming-call overlay subtitle shown under the caller name.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get callIncomingSubtitle;

  /// TASK46 (UI): status while the P2P connection is being established (ICE/DTLS negotiation).
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get callConnecting;

  /// TASK46 (UI): label/tooltip for the green accept button on the incoming-call overlay.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get callAccept;

  /// TASK46 (UI): label/tooltip for the red decline button on the incoming-call overlay.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get callDecline;

  /// TASK46 (UI): label/tooltip for the hang-up (end call) button.
  ///
  /// In en, this message translates to:
  /// **'Hang up'**
  String get callHangup;

  /// TASK46 (UI): tooltip for the mute-microphone toggle while in a call.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get callMute;

  /// TASK46 (UI): tooltip for the toggle when the microphone is already muted.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get callUnmute;

  /// TASK46 (UI): tooltip for the toggle that routes call audio to the loudspeaker (hands-free). Shown while audio plays through the quiet earpiece.
  ///
  /// In en, this message translates to:
  /// **'Speaker on'**
  String get callSpeakerOn;

  /// TASK46 (UI): tooltip for the toggle that routes call audio back to the earpiece. Shown while hands-free (loudspeaker) is active.
  ///
  /// In en, this message translates to:
  /// **'Speaker off'**
  String get callSpeakerOff;

  /// TASK46 (UI): generic fallback name shown in call overlays when the peer/caller display name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get callPeerFallback;

  /// TASK46 (UI): toast/status when a call finished normally (local or remote hang-up, timeout).
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get callEndedGeneric;

  /// TASK46 (UI): toast/status when the call was declined.
  ///
  /// In en, this message translates to:
  /// **'Call declined'**
  String get callEndedDeclined;

  /// TASK46 (UI): toast/status when getUserMedia was denied — the user must grant mic permission.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access'**
  String get callEndedMicDenied;

  /// TASK46 (UI): toast/status when the call failed (ICE/DTLS failure or setup error).
  ///
  /// In en, this message translates to:
  /// **'Call error'**
  String get callEndedFailed;

  /// TASK51 (UI): tooltip on the group-call IconButton in the group chat app-bar that starts/joins a mesh conference (call everyone).
  ///
  /// In en, this message translates to:
  /// **'Group call'**
  String get conferenceStartTooltip;

  /// TASK51 (UI): generic heading of the group-call overlay (active screen; incoming fallback when the room name is unknown).
  ///
  /// In en, this message translates to:
  /// **'Group call'**
  String get conferenceTitle;

  /// TASK51 (UI): incoming group-call overlay heading. {room} is the room display name.
  ///
  /// In en, this message translates to:
  /// **'Group call in {room}'**
  String conferenceIncomingTitle(String room);

  /// TASK51 (UI): incoming group-call overlay subtitle naming the de-facto initiator (earliest participant).
  ///
  /// In en, this message translates to:
  /// **'{caller} is inviting you'**
  String conferenceIncomingCaller(String caller);

  /// TASK51 (UI): participant counter shown on the incoming overlay and the ongoing-conference banner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} participant} other{{count} participants}}'**
  String conferenceMemberCount(int count);

  /// TASK51 (UI): title of the banner above the composer shown when a live conference exists in the room and the viewer is not in it.
  ///
  /// In en, this message translates to:
  /// **'Group call in progress'**
  String get conferenceOngoingBannerTitle;

  /// TASK51 (UI): join button on the ongoing-conference banner.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get conferenceJoin;

  /// TASK51 (UI): toast when the server rejected the join because the mesh participant limit is reached. {max} is the server limit.
  ///
  /// In en, this message translates to:
  /// **'Conference is full (max {max})'**
  String conferenceEndedFull(int max);

  /// TASK51 (UI): label marking the viewer's own tile in the conference participant list.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get conferenceYou;

  /// TASK51 (UI): status on a participant tile whose pairwise link failed permanently (conference continues without audio from them).
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get conferencePairFailed;

  /// Forward: action-sheet item — переслать сообщение/альбом в другой чат (внутренний пикер).
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get messageActionForward;

  /// Pin (Issue #35): action-sheet item — закрепить сообщение в чате.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get messageActionPin;

  /// Unpin (Issue #35): action-sheet item — снять закрепление сообщения.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get messageActionUnpin;

  /// Pinned (Issue #35): заголовок плашки закреплённых сообщений над чатом.
  ///
  /// In en, this message translates to:
  /// **'Pinned message'**
  String get pinnedMessagesTitle;

  /// Issue #35: снек об успешном закреплении сообщения.
  ///
  /// In en, this message translates to:
  /// **'Message pinned'**
  String get messagePinnedSnack;

  /// Issue #35: снек об успешном откреплении сообщения.
  ///
  /// In en, this message translates to:
  /// **'Message unpinned'**
  String get messageUnpinnedSnack;

  /// Issue #35: снек об ошибке закрепления.
  ///
  /// In en, this message translates to:
  /// **'Failed to pin message'**
  String get pinMessageFailed;

  /// Issue #35: снек об ошибке открепления.
  ///
  /// In en, this message translates to:
  /// **'Failed to unpin message'**
  String get unpinMessageFailed;

  /// Issue #35: снек когда прав на закрепление недостаточно.
  ///
  /// In en, this message translates to:
  /// **'Only admins can pin messages here'**
  String get pinNotAllowed;

  /// Forward (мультивыбор): action-sheet item — войти в режим выбора нескольких сообщений для пачечной пересылки (Telegram-style).
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get messageActionSelect;

  /// Forward (мультивыбор): заголовок селекшн-аппбара — сколько сообщений выбрано.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCountTitle(int count);

  /// Forward: action-sheet item — поделиться наружу через системный share sheet (share_plus).
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get messageActionShare;

  /// Forward: заголовок bottom-sheet-а выбора целевого чата.
  ///
  /// In en, this message translates to:
  /// **'Forward to…'**
  String get forwardPickerTitle;

  /// Forward: placeholder поля поиска в пикере чата.
  ///
  /// In en, this message translates to:
  /// **'Search chats'**
  String get forwardSearchHint;

  /// Forward: пусто/нет совпадений в пикере чата.
  ///
  /// In en, this message translates to:
  /// **'No chats to forward to'**
  String get forwardNoRooms;

  /// Forward: snackbar-подтверждение после успешной пересылки.
  ///
  /// In en, this message translates to:
  /// **'Forwarded'**
  String get forwardedSnack;

  /// F1: кнопка подтверждения в мультивыборе целевых чатов; count — число выбранных.
  ///
  /// In en, this message translates to:
  /// **'Forward ({count})'**
  String forwardMultiButton(int count);

  /// F1: snackbar после пересылки в несколько чатов; count — число целевых чатов.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Forwarded to {count} chat} other{Forwarded to {count} chats}}'**
  String forwardedToChatsSnack(int count);

  /// Forward: кнопка в snackbar-е — открыть целевой чат после пересылки.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get forwardOpenChat;

  /// Forward: snackbar когда пересылка (RPC) упала.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t forward — try again'**
  String get forwardFailed;

  /// Forward: snackbar когда внешний share упал (скачивание media / share sheet).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share — try again'**
  String get shareFailed;

  /// Action-sheet / fullscreen: скопировать картинку сообщения в буфер обмена (desktop bitmap/файл; mobile/web bitmap).
  ///
  /// In en, this message translates to:
  /// **'Copy image'**
  String get messageActionCopyImage;

  /// Snackbar после успешного копирования картинки в буфер обмена.
  ///
  /// In en, this message translates to:
  /// **'Image copied to clipboard'**
  String get imageCopiedSnack;

  /// OUTBOX: убрать сообщение из персистентной очереди отправки (строка + локальная копия файла). Только для ещё-не-ушедших сообщений — отправленное удаляется через messageActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Cancel sending'**
  String get messageActionCancelSend;

  /// OUTBOX: snackbar когда discard строки очереди упал (например store недоступен).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t cancel sending'**
  String get messageCancelSendFailed;

  /// Snackbar когда копирование картинки в буфер упало (скачивание / запись в буфер).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t copy the image'**
  String get imageCopyFailed;

  /// TASK49 (share-in): title of the chat picker bottom-sheet when content is shared INTO the app from another app (reuses the forward-picker core).
  ///
  /// In en, this message translates to:
  /// **'Send to…'**
  String get sharePickerTitle;

  /// TASK49 (share-in): confirm dialog title — {name} is the target chat name.
  ///
  /// In en, this message translates to:
  /// **'Send to {name}?'**
  String shareConfirmTitle(String name);

  /// TASK49 (share-in): confirm dialog line showing how many files are being shared in.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} file} other{{count} files}}'**
  String shareConfirmFiles(int count);

  /// TASK49 (share-in): send button in the share confirm dialog.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get shareSend;

  /// TASK49 (share-in): progress modal text while sending shared items sequentially.
  ///
  /// In en, this message translates to:
  /// **'Sending {current} of {total}…'**
  String shareProgress(int current, int total);

  /// TASK49 (share-in): snackbar after all shared items were sent successfully.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get shareSent;

  /// OUTBOX: snackbar after shared items were enqueued into the persistent outbox for background delivery.
  ///
  /// In en, this message translates to:
  /// **'Added to send queue'**
  String get shareQueued;

  /// TASK49 (share-in): snackbar when one or more shared items failed to send.
  ///
  /// In en, this message translates to:
  /// **'Some items couldn\'t be sent'**
  String get shareSomeFailed;

  /// TASK49 (share-in): snackbar naming files that exceeded the size limit and were skipped.
  ///
  /// In en, this message translates to:
  /// **'Too large to send: {names}'**
  String shareFileTooLarge(String names);

  /// TASK49 (share-in): snackbar when a second share arrives while a share send is still running (no queueing in MVP).
  ///
  /// In en, this message translates to:
  /// **'Sending is still in progress'**
  String get shareBusy;

  /// Forward: шапка в bubble пересланного сообщения — «Переслано от <имя>».
  ///
  /// In en, this message translates to:
  /// **'Forwarded from {name}'**
  String messageForwardedFrom(String name);

  /// Issue #41: snackbar when tapping the «Forwarded from X» header cannot open the original chat (not a member / room gone).
  ///
  /// In en, this message translates to:
  /// **'Source chat is unavailable'**
  String get forwardSourceUnavailable;

  /// Универсальная кнопка подтверждения в диалогах (dismiss / accept). TASK58: закрыть диалог с webhook-URL.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// TASK58: подпись ссылки в статус-карточке автопоста, когда `link.label` не задан. Открывает `link.url` во внешнем браузере.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusCardOpenLink;

  /// TASK58: заголовок экрана интеграций (`IntegrationsScreen`) + ListTile «Интеграции» в настройках группы (виден только owner/admin).
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get integrationsTitle;

  /// TASK58: заголовок секции автопостов (входящих webhook-ов) на экране интеграций.
  ///
  /// In en, this message translates to:
  /// **'Autoposts'**
  String get integrationsAutopostsSection;

  /// TASK58/TASK59: заголовок секции ботов (self-service бот-интеграций) на экране интеграций.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get integrationsBotsSection;

  /// TASK58: кнопка «+ добавить автопост» — открывает диалог ввода имени и создаёт webhook.
  ///
  /// In en, this message translates to:
  /// **'Add autopost'**
  String get integrationsAddAutopost;

  /// TASK58: empty-state на экране интеграций, когда у комнаты нет webhook-ов.
  ///
  /// In en, this message translates to:
  /// **'No autoposts yet'**
  String get integrationsEmpty;

  /// TASK58: заголовок error-state на экране интеграций, когда listWebhooks() упал.
  ///
  /// In en, this message translates to:
  /// **'Failed to load integrations'**
  String get integrationsLoadFailed;

  /// TASK58: label поля ввода имени автопоста в диалоге создания (напр. «CI · Deploy»).
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get integrationsNameLabel;

  /// TASK58: hint-подсказка в поле ввода имени автопоста.
  ///
  /// In en, this message translates to:
  /// **'e.g. CI · Deploy'**
  String get integrationsNameHint;

  /// TASK58: кнопка подтверждения создания автопоста в диалоге.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get integrationsCreate;

  /// TASK58: label над webhook-URL (показывается один раз после создания/ротации — содержит секретный токен).
  ///
  /// In en, this message translates to:
  /// **'Webhook URL'**
  String get integrationsWebhookUrlLabel;

  /// TASK58: предупреждение под webhook-URL, что токен показывается один раз.
  ///
  /// In en, this message translates to:
  /// **'Copy this URL now — the token is shown only once.'**
  String get integrationsWebhookUrlOnce;

  /// TASK58: snackbar-подтверждение после копирования webhook-URL в буфер обмена.
  ///
  /// In en, this message translates to:
  /// **'URL copied'**
  String get integrationsCopied;

  /// TASK58: tooltip/подпись кнопки копирования webhook-URL (CopyableField).
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get integrationsCopy;

  /// TASK58: пункт ⋯-меню — платформа шлёт пример статус-карточки в комнату для проверки рендера.
  ///
  /// In en, this message translates to:
  /// **'Test post'**
  String get integrationsTestPost;

  /// TASK58: пункт ⋯-меню — ротация токена webhook-а (старый перестаёт работать, показывается новый URL).
  ///
  /// In en, this message translates to:
  /// **'Regenerate token'**
  String get integrationsRotateToken;

  /// TASK58: пункт ⋯-меню — включить выключенный webhook.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get integrationsEnable;

  /// TASK58: пункт ⋯-меню — выключить webhook без удаления.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get integrationsDisable;

  /// TASK58: пункт ⋯-меню — удалить webhook (с confirm-диалогом).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get integrationsDelete;

  /// TASK58: заголовок confirm-диалога удаления webhook-а.
  ///
  /// In en, this message translates to:
  /// **'Delete autopost?'**
  String get integrationsDeleteConfirmTitle;

  /// TASK58: тело confirm-диалога удаления webhook-а.
  ///
  /// In en, this message translates to:
  /// **'The webhook will stop working and its URL will be revoked.'**
  String get integrationsDeleteConfirmBody;

  /// TASK58: бейдж рядом с именем выключенного webhook-а в списке.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get integrationsDisabledBadge;

  /// TASK58: подстрока в списке — когда webhook постил в последний раз (relative time), напр. «last post 5 min ago».
  ///
  /// In en, this message translates to:
  /// **'last post {when}'**
  String integrationsLastPost(String when);

  /// TASK58: подстрока в списке, когда `lastPostedAt == null` (webhook ещё ни разу не постил).
  ///
  /// In en, this message translates to:
  /// **'no posts yet'**
  String get integrationsNeverPosted;

  /// TASK58: snackbar после успешного testPost().
  ///
  /// In en, this message translates to:
  /// **'Test post sent'**
  String get integrationsTestPostSent;

  /// TASK58: snackbar при ошибке любого действия над webhook-ом (rotate/enable/disable/delete/test).
  ///
  /// In en, this message translates to:
  /// **'Action failed — try again'**
  String get integrationsActionFailed;

  /// TASK59: snackbar после копирования произвольного значения (токен/секрет/id) в буфер — используется в диалоге учётных данных бота, в отличие от `integrationsCopied` («URL copied»).
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get integrationsCopiedGeneric;

  /// TASK59: кнопка «＋ добавить бота» + заголовок диалога создания бот-интеграции (спрашивает имя + webhook URL).
  ///
  /// In en, this message translates to:
  /// **'Add bot'**
  String get integrationsAddBot;

  /// TASK59: empty-state секции «Боты», когда у комнаты нет бот-интеграций.
  ///
  /// In en, this message translates to:
  /// **'No bots yet'**
  String get integrationsBotsEmpty;

  /// TASK59: hint-подсказка в поле ввода имени бота в диалоге создания.
  ///
  /// In en, this message translates to:
  /// **'e.g. Deploy Bot'**
  String get integrationsBotNameHint;

  /// TASK59: label поля ввода webhook-URL разработчика (куда платформа доставляет события комнаты) в диалоге создания бота.
  ///
  /// In en, this message translates to:
  /// **'Webhook URL'**
  String get integrationsBotWebhookUrlLabel;

  /// TASK59: hint-подсказка в поле ввода webhook-URL бота.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/webhook'**
  String get integrationsBotWebhookUrlHint;

  /// TASK59: ошибка валидации поля webhook-URL, когда значение пустое или не начинается с https://.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid https:// URL'**
  String get integrationsBotWebhookUrlInvalid;

  /// TASK59: заголовок one-time диалога с учётными данными бота (токен/секрет/apiBase/…), показываемого после создания или ротации секрета.
  ///
  /// In en, this message translates to:
  /// **'Bot credentials'**
  String get integrationsBotCredentialsTitle;

  /// TASK59: предупреждение в диалоге учётных данных бота, что токен и секрет показываются один раз.
  ///
  /// In en, this message translates to:
  /// **'These secrets are shown only once — copy them now.'**
  String get integrationsBotCredentialsOnce;

  /// TASK59: label над bearer-токеном бота (`bot.accessToken`) в диалоге учётных данных.
  ///
  /// In en, this message translates to:
  /// **'Bot token'**
  String get integrationsBotTokenLabel;

  /// TASK59: label над HMAC-секретом webhook-а (`subscription.secret`) в диалоге учётных данных.
  ///
  /// In en, this message translates to:
  /// **'Webhook secret'**
  String get integrationsBotSecretLabel;

  /// TASK59: label над базовым URL API (`apiBase`, напр. https://api.chatista.me) в диалоге учётных данных бота.
  ///
  /// In en, this message translates to:
  /// **'API base'**
  String get integrationsApiBaseLabel;

  /// TASK59: label над идентификатором комнаты в диалоге учётных данных бота.
  ///
  /// In en, this message translates to:
  /// **'Room ID'**
  String get integrationsRoomIdLabel;

  /// TASK59: label над messenger-user-id бота (`bot.messengerUserId`) в диалоге учётных данных.
  ///
  /// In en, this message translates to:
  /// **'Bot user id'**
  String get integrationsBotUserIdLabel;

  /// TASK59: пояснение под полем «Bot user id» — зачем нужен messengerUserId (фильтрация собственных эхо-сообщений бота).
  ///
  /// In en, this message translates to:
  /// **'Use it to filter out the bot\'s own echoed messages.'**
  String get integrationsBotUserIdCaption;

  /// TASK59: label над CSV подписанных webhook-событий (`subscription.eventTypes`) в диалоге учётных данных бота.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get integrationsEventsLabel;

  /// TASK59: подсказка copy-paste в диалоге учётных данных бота — отдать данные разработчику вместе со ссылкой на документацию.
  ///
  /// In en, this message translates to:
  /// **'Hand these credentials to your developer together with a link to the documentation.'**
  String get integrationsBotHandoffHint;

  /// TASK59: пункт ⋯-меню — ротация webhook-секрета бот-интеграции (старая подпись перестаёт совпадать, показывается новый секрет).
  ///
  /// In en, this message translates to:
  /// **'Regenerate secret'**
  String get integrationsRotateSecret;

  /// TASK59: заголовок confirm-диалога удаления бот-интеграции.
  ///
  /// In en, this message translates to:
  /// **'Delete bot?'**
  String get integrationsBotDeleteConfirmTitle;

  /// TASK59: тело confirm-диалога удаления бот-интеграции.
  ///
  /// In en, this message translates to:
  /// **'The bot will be removed from the room and its webhook subscription deleted.'**
  String get integrationsBotDeleteConfirmBody;

  /// TASK36: заголовок админки ботов + пункт входа в настройках (виден только админам из BOT_ADMIN_EMAILS).
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get botsAdminTitle;

  /// TASK36: пустое состояние списка ботов в админке.
  ///
  /// In en, this message translates to:
  /// **'No bots yet. A bot is a program that posts to chats with its own token.'**
  String get botsAdminEmpty;

  /// TASK36: ошибка загрузки списка ботов / журнала аудита.
  ///
  /// In en, this message translates to:
  /// **'Failed to load bots'**
  String get botsAdminLoadFailed;

  /// TASK36: snackbar о неудавшемся действии админки ботов (создание/ротация/вкл-выкл/добавление в чат).
  ///
  /// In en, this message translates to:
  /// **'Action failed — try again'**
  String get botsAdminActionFailed;

  /// TASK36: кнопка/заголовок диалога создания бота.
  ///
  /// In en, this message translates to:
  /// **'Add bot'**
  String get botsAdminCreate;

  /// TASK36: label поля имени бота (оно же displayName в чатах).
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get botsAdminNameLabel;

  /// TASK36: пример имени бота.
  ///
  /// In en, this message translates to:
  /// **'Deploy notifier'**
  String get botsAdminNameHint;

  /// TASK36: label поля email владельца бота — кто отвечает за бота (идёт в аудит).
  ///
  /// In en, this message translates to:
  /// **'Owner email'**
  String get botsAdminOwnerEmailLabel;

  /// TASK36: пример email владельца бота.
  ///
  /// In en, this message translates to:
  /// **'owner@company.com'**
  String get botsAdminOwnerEmailHint;

  /// TASK36: заголовок группы чекбоксов capabilities в диалоге создания бота.
  ///
  /// In en, this message translates to:
  /// **'What the bot is allowed to do'**
  String get botsAdminCapabilitiesLabel;

  /// TASK36: человекочитаемое название capability read_only.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get botsAdminCapReadOnly;

  /// TASK36: человекочитаемое название capability send_messages.
  ///
  /// In en, this message translates to:
  /// **'Send messages'**
  String get botsAdminCapSendMessages;

  /// TASK36: человекочитаемое название capability manage_room (создание комнат, участники, роли, архив).
  ///
  /// In en, this message translates to:
  /// **'Manage chats'**
  String get botsAdminCapManageRoom;

  /// TASK36: человекочитаемое название capability webhook_target.
  ///
  /// In en, this message translates to:
  /// **'Receive webhooks'**
  String get botsAdminCapWebhookTarget;

  /// TASK36: подзаголовок бота без единого гранта (может только слушать).
  ///
  /// In en, this message translates to:
  /// **'no capabilities'**
  String get botsAdminNoCapabilities;

  /// TASK36: заголовок диалога с access-токеном бота (после создания или ротации).
  ///
  /// In en, this message translates to:
  /// **'Bot access token'**
  String get botsAdminTokenTitle;

  /// TASK36: предупреждение под токеном — показывается один раз, восстановить нельзя, только ротация.
  ///
  /// In en, this message translates to:
  /// **'Shown once. Save it now — if lost, the only way back is to rotate the token.'**
  String get botsAdminTokenOnce;

  /// TASK36: пункт ⋯-меню — выдать боту новый токен, отозвав прежние (ответ на утечку credential-а).
  ///
  /// In en, this message translates to:
  /// **'Rotate token'**
  String get botsAdminRotateToken;

  /// TASK36: заголовок confirm-диалога ротации токена бота.
  ///
  /// In en, this message translates to:
  /// **'Rotate token?'**
  String get botsAdminRotateConfirmTitle;

  /// TASK36: тело confirm-диалога ротации — предупреждение о простое бота до подстановки нового токена в его программу.
  ///
  /// In en, this message translates to:
  /// **'The current token stops working immediately. The bot will go silent until its program is updated with the new token. The bot itself, its chats and its history are kept.'**
  String get botsAdminRotateConfirmBody;

  /// TASK36: пункт ⋯-меню — включить бота.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get botsAdminEnable;

  /// TASK36: пункт ⋯-меню — выключить бота (kill-switch: любое gated-действие отклоняется).
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get botsAdminDisable;

  /// TASK36: бейдж рядом с именем выключенного бота.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get botsAdminDisabledBadge;

  /// TASK36: пункт ⋯-меню — добавить бота в чат (без членства бот не может постить).
  ///
  /// In en, this message translates to:
  /// **'Add to chat'**
  String get botsAdminAddToRoom;

  /// TASK36: заголовок диалога выбора чата для добавления бота.
  ///
  /// In en, this message translates to:
  /// **'Choose a chat'**
  String get botsAdminAddToRoomTitle;

  /// TASK36: snackbar об успешном добавлении бота в чат.
  ///
  /// In en, this message translates to:
  /// **'Bot added to the chat'**
  String get botsAdminAddedToRoom;

  /// No description provided for @botsAdminAlreadyInRoom.
  ///
  /// In en, this message translates to:
  /// **'Already added'**
  String get botsAdminAlreadyInRoom;

  /// TASK36: пустое состояние списка чатов в диалоге выбора.
  ///
  /// In en, this message translates to:
  /// **'No chats available'**
  String get botsAdminNoRooms;

  /// TASK36: пункт ⋯-меню — журнал событий бота.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get botsAdminAudit;

  /// TASK36: заголовок листа журнала аудита с именем бота.
  ///
  /// In en, this message translates to:
  /// **'Audit log — {name}'**
  String botsAdminAuditTitle(String name);

  /// TASK36: пустой журнал аудита бота.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get botsAdminAuditEmpty;

  /// TASK36: инициатор события в журнале, когда действие исходило от самого бота (capability_denied), а не от админа.
  ///
  /// In en, this message translates to:
  /// **'the bot itself'**
  String get botsAdminAuditActorBot;

  /// TASK36: инициатор события в журнале, когда за действием нет человека — бота завела платформа (боты-подпорки Pulse / входящих webhook-ов).
  ///
  /// In en, this message translates to:
  /// **'system'**
  String get botsAdminAuditActorSystem;

  /// TASK36: журнал — действие 'created'.
  ///
  /// In en, this message translates to:
  /// **'Bot created'**
  String get botsAdminAuditCreated;

  /// TASK36: журнал — действие 'token_rotated'.
  ///
  /// In en, this message translates to:
  /// **'Token rotated'**
  String get botsAdminAuditTokenRotated;

  /// TASK36: журнал — действие 'enabled'.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get botsAdminAuditEnabled;

  /// TASK36: журнал — действие 'disabled'.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get botsAdminAuditDisabled;

  /// TASK36: журнал — действие 'added_to_room'.
  ///
  /// In en, this message translates to:
  /// **'Added to a chat'**
  String get botsAdminAuditAddedToRoom;

  /// TASK36: журнал — действие 'capability_denied': бот попытался сделать то, на что у него нет гранта (сигнал абьюза или неверных грантов).
  ///
  /// In en, this message translates to:
  /// **'Action denied'**
  String get botsAdminAuditCapabilityDenied;

  /// Issue #49: журнал — действие 'removed_from_room' (владелец отозвал бота из комнаты).
  ///
  /// In en, this message translates to:
  /// **'Removed from a chat'**
  String get botsAdminAuditRemovedFromRoom;

  /// Issue #49: журнал — действие 'discoverable_enabled'.
  ///
  /// In en, this message translates to:
  /// **'Made visible in search'**
  String get botsAdminAuditDiscoverableOn;

  /// Issue #49: журнал — действие 'discoverable_disabled'.
  ///
  /// In en, this message translates to:
  /// **'Hidden from search'**
  String get botsAdminAuditDiscoverableOff;

  /// TASK78 п.3: заголовок платформенной админки секретов тенантов + пункт входа в настройках (виден только админам из PLATFORM_ADMIN_EMAILS).
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platformAdminTitle;

  /// TASK78 п.3: пустое состояние списка тенантов (обвязка деградирует отказ/старый сервер в пустой список).
  ///
  /// In en, this message translates to:
  /// **'No tenants — or no access. The list is served only to platform admins.'**
  String get platformAdminEmpty;

  /// TASK78 п.3: snackbar о неудавшемся действии (включение/ротация/отзыв).
  ///
  /// In en, this message translates to:
  /// **'Action failed — try again'**
  String get platformAdminActionFailed;

  /// TASK78 п.3: статус tenant-а — issued-token-режим включён.
  ///
  /// In en, this message translates to:
  /// **'enabled'**
  String get platformAdminStatusEnabled;

  /// TASK78 п.3: статус tenant-а — режим выключен.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get platformAdminStatusDisabled;

  /// TASK78 п.3: подпись «текущий serviceSecret задан» (сам секрет сервер не отдаёт).
  ///
  /// In en, this message translates to:
  /// **'secret set'**
  String get platformAdminSecretSet;

  /// TASK78 п.3: подпись «секрет не задан».
  ///
  /// In en, this message translates to:
  /// **'no secret'**
  String get platformAdminSecretMissing;

  /// TASK78 п.3: grace-окно ротации — до какого момента ещё принимается прежний секрет.
  ///
  /// In en, this message translates to:
  /// **'previous secret valid until {until}'**
  String platformAdminGraceUntil(String until);

  /// TASK78 п.3: действие — включить issued-token-режим и выдать первый serviceSecret.
  ///
  /// In en, this message translates to:
  /// **'Enable & generate secret'**
  String get platformAdminEnableGenerate;

  /// TASK78 п.3: действие — ротировать serviceSecret (старый живёт grace-окно).
  ///
  /// In en, this message translates to:
  /// **'Rotate secret'**
  String get platformAdminRotate;

  /// TASK78 п.3: заголовок диалога ротации.
  ///
  /// In en, this message translates to:
  /// **'Rotate secret?'**
  String get platformAdminRotateTitle;

  /// TASK78 п.3: тело диалога ротации — объяснение grace-окна.
  ///
  /// In en, this message translates to:
  /// **'A new secret will be issued. The old one keeps working for the grace period below, then dies.'**
  String get platformAdminRotateBody;

  /// TASK78 п.3: label поля grace-периода в минутах в диалоге ротации.
  ///
  /// In en, this message translates to:
  /// **'Grace, minutes (max {max})'**
  String platformAdminGraceLabel(int max);

  /// TASK78 п.3: заголовок диалога одноразового показа serviceSecret.
  ///
  /// In en, this message translates to:
  /// **'Tenant service secret'**
  String get platformAdminSecretTitle;

  /// TASK78 п.3: предупреждение под секретом — показ один раз, в БД только sha256.
  ///
  /// In en, this message translates to:
  /// **'The secret is shown ONCE. The server stores only its hash — if lost, the only way back is rotation.'**
  String get platformAdminSecretOnce;

  /// TASK78 п.3: действие — отозвать режим (kill-switch).
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get platformAdminDisable;

  /// TASK78 п.3: заголовок confirm-диалога отзыва.
  ///
  /// In en, this message translates to:
  /// **'Disable issued-token mode?'**
  String get platformAdminDisableConfirmTitle;

  /// TASK78 п.3: тело confirm-диалога отзыва — обнуляются оба хэша, продукт сразу теряет доступ.
  ///
  /// In en, this message translates to:
  /// **'Kill-switch: both secret hashes are wiped and the product loses access immediately. Re-enabling issues a brand-new secret.'**
  String get platformAdminDisableConfirmBody;

  /// TASK78 п.3: действие — журнал операций с ключами tenant-а.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get platformAdminAudit;

  /// TASK78 п.3: заголовок листа аудита tenant-а.
  ///
  /// In en, this message translates to:
  /// **'Audit — {name}'**
  String platformAdminAuditTitle(String name);

  /// TASK78 п.3: пустой журнал аудита.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get platformAdminAuditEmpty;

  /// TASK78 п.3: журнал — действие 'enabled_and_generated'.
  ///
  /// In en, this message translates to:
  /// **'Enabled, secret generated'**
  String get platformAdminAuditEnabledGenerated;

  /// TASK78 п.3: журнал — действие 'secret_rotated'.
  ///
  /// In en, this message translates to:
  /// **'Secret rotated'**
  String get platformAdminAuditRotated;

  /// TASK78 п.3: журнал — действие 'disabled'.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get platformAdminAuditDisabled;

  /// Issue #49: заголовок экрана «Мои боты» + пункт входа в настройках.
  ///
  /// In en, this message translates to:
  /// **'My bots'**
  String get myBotsTitle;

  /// Issue #49: пустое состояние «Моих ботов» — объясняет, что такое бот (экран виден всем, не только тем, кто уже знает про ботов).
  ///
  /// In en, this message translates to:
  /// **'No bots yet. A bot is a program that posts to chats under its own account using an access token: deploy notifications, reminders, integrations. Create one, add it to your chats — or make it public so others can find it in search.'**
  String get myBotsEmpty;

  /// Issue #49: переключатель видимости бота в поиске (диалог создания).
  ///
  /// In en, this message translates to:
  /// **'Visible in search'**
  String get myBotsDiscoverable;

  /// Issue #49: пояснение к переключателю видимости.
  ///
  /// In en, this message translates to:
  /// **'Anyone can find the bot and add it to their chats'**
  String get myBotsDiscoverableSubtitle;

  /// Issue #49: бейдж discoverable-бота в списке «Моих ботов».
  ///
  /// In en, this message translates to:
  /// **'in search'**
  String get myBotsPublicBadge;

  /// Issue #49: пункт меню — включить видимость бота.
  ///
  /// In en, this message translates to:
  /// **'Show in search'**
  String get myBotsMakeDiscoverable;

  /// Issue #49: пункт меню — выключить видимость бота.
  ///
  /// In en, this message translates to:
  /// **'Hide from search'**
  String get myBotsMakeHidden;

  /// Issue #49: пункт меню — список комнат бота.
  ///
  /// In en, this message translates to:
  /// **'Bot\'s chats'**
  String get myBotsRooms;

  /// Issue #49: заголовок шторки с комнатами бота.
  ///
  /// In en, this message translates to:
  /// **'Chats — {name}'**
  String myBotsRoomsTitle(String name);

  /// Issue #49: пустое состояние списка комнат бота.
  ///
  /// In en, this message translates to:
  /// **'The bot is not in any chats yet'**
  String get myBotsRoomsEmpty;

  /// Issue #49: кнопка отзыва бота из комнаты.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get myBotsRevoke;

  /// Issue #49: заголовок confirm-диалога отзыва.
  ///
  /// In en, this message translates to:
  /// **'Remove bot from this chat?'**
  String get myBotsRevokeConfirmTitle;

  /// Issue #49: тело confirm-диалога отзыва — что именно произойдёт.
  ///
  /// In en, this message translates to:
  /// **'The bot will leave the chat. Its messages stay; the bot can be added back later.'**
  String get myBotsRevokeConfirmBody;

  /// Issue #49: снекбар после успешного отзыва.
  ///
  /// In en, this message translates to:
  /// **'Bot removed from the chat'**
  String get myBotsRevoked;

  /// Issue #49: человекочитаемая ошибка лимита ботов (BotLimitExceededException).
  ///
  /// In en, this message translates to:
  /// **'Bot limit reached ({limit}). Rotate a token or reuse an existing bot instead of creating a new one.'**
  String myBotsLimitReached(int limit);

  /// TASK60: заголовок дашборда мониторинга Connect Pulse + пункт входа в настройках.
  ///
  /// In en, this message translates to:
  /// **'Monitoring'**
  String get pulseTitle;

  /// TASK60: state «нет доступа» — сервер отдал MessengerNotAuthenticatedException (email не в PULSE_ADMIN_EMAILS).
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to monitoring.'**
  String get pulseNoAccess;

  /// TASK60: empty-state дашборда — ни папок, ни мониторов.
  ///
  /// In en, this message translates to:
  /// **'No monitors yet'**
  String get pulseEmpty;

  /// TASK60: ошибка загрузки списка папок/мониторов.
  ///
  /// In en, this message translates to:
  /// **'Failed to load monitoring'**
  String get pulseLoadFailed;

  /// TASK60: снекбар неуспеха мутации (create/rename/delete/pause/rotate/ack).
  ///
  /// In en, this message translates to:
  /// **'Action failed — try again'**
  String get pulseActionFailed;

  /// TASK60: пункт «＋»-меню — создать папку.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get pulseAddFolder;

  /// TASK60: пункт «＋»-меню — создать монитор.
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get pulseAddMonitor;

  /// TASK60: заголовок диалога создания папки.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get pulseNewFolder;

  /// TASK60: заголовок диалога создания монитора.
  ///
  /// In en, this message translates to:
  /// **'New monitor'**
  String get pulseNewMonitor;

  /// TASK60: label поля имени папки/монитора.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get pulseNameLabel;

  /// TASK60: подсказка поля имени папки.
  ///
  /// In en, this message translates to:
  /// **'e.g. Production'**
  String get pulseFolderNameHint;

  /// TASK60: подсказка поля имени монитора.
  ///
  /// In en, this message translates to:
  /// **'e.g. Nightly backup'**
  String get pulseMonitorNameHint;

  /// TASK60: кнопка подтверждения создания папки/монитора/правила.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get pulseCreate;

  /// TASK60: пункт меню / кнопка переименования папки.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get pulseRename;

  /// TASK60: label выбора родительской папки при создании папки/монитора.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get pulseParentFolderLabel;

  /// TASK60: пункт «корень дерева» в выборе папки (folderId/parentId = null).
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get pulseFolderRoot;

  /// TASK60: label выбора ожидаемого интервала сигналов монитора.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get pulsePeriodLabel;

  /// TASK60: label поля допуска (graceSeconds) сверх периода до перехода в down.
  ///
  /// In en, this message translates to:
  /// **'Grace period (sec)'**
  String get pulseGraceLabel;

  /// TASK60: вариант периода — 60 секунд.
  ///
  /// In en, this message translates to:
  /// **'60 sec'**
  String get pulsePeriod60s;

  /// TASK60: вариант периода — 5 минут.
  ///
  /// In en, this message translates to:
  /// **'5 min'**
  String get pulsePeriod5m;

  /// TASK60: вариант периода — 15 минут.
  ///
  /// In en, this message translates to:
  /// **'15 min'**
  String get pulsePeriod15m;

  /// TASK60: вариант периода — 1 час.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get pulsePeriod1h;

  /// TASK60: вариант периода — 24 часа.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get pulsePeriod24h;

  /// TASK60: подзаголовок строки монитора — относительное время последнего сигнала.
  ///
  /// In en, this message translates to:
  /// **'signal {when}'**
  String pulseLastSignal(String when);

  /// TASK60: подзаголовок монитора, который ещё ни разу не стучался (lastBeatAt == null).
  ///
  /// In en, this message translates to:
  /// **'no signal yet'**
  String get pulseNoSignal;

  /// TASK60: бейдж статуса late (просрочка в пределах grace).
  ///
  /// In en, this message translates to:
  /// **'late'**
  String get pulseBadgeLate;

  /// TASK60: бейдж статуса down (сигнал не пришёл за period+grace).
  ///
  /// In en, this message translates to:
  /// **'down'**
  String get pulseBadgeDown;

  /// TASK60: бейдж/подпись приостановленного монитора.
  ///
  /// In en, this message translates to:
  /// **'paused'**
  String get pulsePaused;

  /// TASK60: строка периода/допуска в detail-листе монитора.
  ///
  /// In en, this message translates to:
  /// **'Period {period} · grace {grace}s'**
  String pulseDetailPeriodGrace(String period, int grace);

  /// TASK60: label строки последнего сигнала в detail-листе монитора.
  ///
  /// In en, this message translates to:
  /// **'Last signal'**
  String get pulseLastSignalLabel;

  /// TASK60: заголовок секции инцидентов в detail-листе монитора.
  ///
  /// In en, this message translates to:
  /// **'Incidents'**
  String get pulseIncidents;

  /// TASK60: empty-state секции инцидентов.
  ///
  /// In en, this message translates to:
  /// **'No incidents'**
  String get pulseNoIncidents;

  /// TASK60: кнопка «Взять в работу» на непринятом открытом инциденте.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get pulseAck;

  /// TASK60: пометка открытого (неразрешённого) инцидента.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get pulseIncidentOpen;

  /// TASK60: пометка разрешённого инцидента.
  ///
  /// In en, this message translates to:
  /// **'resolved'**
  String get pulseIncidentResolved;

  /// TASK60: пометка инцидента, принятого в работу (ackedAt задан).
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get pulseIncidentAcked;

  /// TASK60: действие «Пауза» монитора.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pulsePause;

  /// TASK60: действие «Возобновить» монитора.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get pulseResume;

  /// TASK60: действие ротации beat-токена монитора.
  ///
  /// In en, this message translates to:
  /// **'Regenerate token'**
  String get pulseRotateToken;

  /// TASK60: действие удаления монитора/папки/правила.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get pulseDelete;

  /// TASK60: заголовок confirm-диалога удаления монитора.
  ///
  /// In en, this message translates to:
  /// **'Delete monitor?'**
  String get pulseDeleteMonitorConfirmTitle;

  /// TASK60: тело confirm-диалога удаления монитора.
  ///
  /// In en, this message translates to:
  /// **'The monitor and its beat token will stop working and its history will be removed.'**
  String get pulseDeleteMonitorConfirmBody;

  /// TASK60: заголовок confirm-диалога удаления папки.
  ///
  /// In en, this message translates to:
  /// **'Delete folder?'**
  String get pulseDeleteFolderConfirmTitle;

  /// TASK60: тело confirm-диалога удаления папки (удаляется только пустая).
  ///
  /// In en, this message translates to:
  /// **'Only empty folders can be deleted.'**
  String get pulseDeleteFolderConfirmBody;

  /// TASK60: снекбар — сервер отказал в удалении непустой папки.
  ///
  /// In en, this message translates to:
  /// **'Folder is not empty'**
  String get pulseFolderNotEmpty;

  /// TASK60: заголовок one-time диалога с URL для heartbeat.
  ///
  /// In en, this message translates to:
  /// **'Beat URL'**
  String get pulseBeatUrlLabel;

  /// TASK60: предупреждение, что beat-токен показывается один раз.
  ///
  /// In en, this message translates to:
  /// **'Copy this now — the token is shown only once.'**
  String get pulseBeatUrlOnce;

  /// TASK60: подпись над готовым curl-сниппетом в one-time диалоге.
  ///
  /// In en, this message translates to:
  /// **'Ready-to-use snippet:'**
  String get pulseCurlHint;

  /// TASK60: tooltip кнопки копирования в буфер.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get pulseCopy;

  /// TASK60: снекбар после копирования beatUrl/curl в буфер.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get pulseCopied;

  /// TASK60: заголовок экрана/кнопки правил оповещения для scope (папка/монитор).
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get pulseAlerts;

  /// TASK60: кнопка добавления правила оповещения.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get pulseAddRule;

  /// TASK60: empty-state списка правил для scope.
  ///
  /// In en, this message translates to:
  /// **'No alert rules'**
  String get pulseNoRules;

  /// TASK60: label выбора комнаты-получателя карточек алерта.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get pulseRoomLabel;

  /// TASK60: плейсхолдер выбора комнаты в диалоге правила.
  ///
  /// In en, this message translates to:
  /// **'Pick a room'**
  String get pulsePickRoom;

  /// TASK60: label выбора минимальной severity правила.
  ///
  /// In en, this message translates to:
  /// **'Minimum severity'**
  String get pulseMinSeverityLabel;

  /// TASK60: severity warn (человекочитаемо).
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get pulseSeverityWarn;

  /// TASK60: severity error (человекочитаемо).
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get pulseSeverityError;

  /// TASK60: severity down (человекочитаемо).
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get pulseSeverityDown;

  /// TASK60: label необязательного поля escalateAfterMinutes.
  ///
  /// In en, this message translates to:
  /// **'Escalate after (min)'**
  String get pulseEscalateAfterLabel;

  /// TASK60: label поля CSV MUID-ов уровня 1 эскалации.
  ///
  /// In en, this message translates to:
  /// **'Responsible (MUID)'**
  String get pulseLevel1Label;

  /// TASK60: подсказка под полем level1UserIds (CSV MUID).
  ///
  /// In en, this message translates to:
  /// **'Comma-separated messenger user ids to DM on escalation.'**
  String get pulseLevel1Helper;

  /// TASK60: строка правила в списке — минимальная severity и комната.
  ///
  /// In en, this message translates to:
  /// **'≥ {severity} → room {room}'**
  String pulseRuleSummary(String severity, String room);

  /// TASK60: действие удаления правила (long-press / ⋯).
  ///
  /// In en, this message translates to:
  /// **'Delete rule'**
  String get pulseDeleteRule;

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactTitle;

  /// No description provided for @contactCustomNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom name'**
  String get contactCustomNameLabel;

  /// No description provided for @contactCustomNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Only you see it — in the chat list and participants'**
  String get contactCustomNameHelper;

  /// No description provided for @contactNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get contactNoteLabel;

  /// No description provided for @contactNoteHelper.
  ///
  /// In en, this message translates to:
  /// **'Private note about this contact'**
  String get contactNoteHelper;

  /// No description provided for @contactSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get contactSave;

  /// No description provided for @contactSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get contactSaved;

  /// No description provided for @contactSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get contactSaveFailed;

  /// No description provided for @contactLabelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get contactLabelsTitle;

  /// No description provided for @contactNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New label'**
  String get contactNewLabel;

  /// No description provided for @contactNewLabelHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: office, Moscow…'**
  String get contactNewLabelHint;

  /// No description provided for @contactCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get contactCreate;

  /// No description provided for @contactCreateLabelFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create label'**
  String get contactCreateLabelFailed;

  /// No description provided for @contactRenameLabelMenu.
  ///
  /// In en, this message translates to:
  /// **'Rename “{name}”'**
  String contactRenameLabelMenu(Object name);

  /// No description provided for @contactRenameLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename label'**
  String get contactRenameLabelTitle;

  /// No description provided for @contactDeleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete label'**
  String get contactDeleteLabel;

  /// No description provided for @contactDeleteLabelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete label “{name}”?'**
  String contactDeleteLabelConfirm(Object name);

  /// No description provided for @contactDeleteLabelBody.
  ///
  /// In en, this message translates to:
  /// **'The label will be removed from all contacts.'**
  String get contactDeleteLabelBody;

  /// No description provided for @contactDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get contactDelete;

  /// No description provided for @contactRenameFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename'**
  String get contactRenameFailed;

  /// No description provided for @contactDeleteLabelFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete label'**
  String get contactDeleteLabelFailed;

  /// No description provided for @contactLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load contact'**
  String get contactLoadFailed;

  /// No description provided for @contactBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get contactBlock;

  /// No description provided for @contactUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get contactUnblock;

  /// No description provided for @contactBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get contactBlocked;

  /// No description provided for @contactBlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String contactBlockConfirm(Object name);

  /// No description provided for @contactBlockBody.
  ///
  /// In en, this message translates to:
  /// **'They won\'t be able to message you, and you both stop getting notifications from each other. You can undo this later.'**
  String get contactBlockBody;

  /// No description provided for @contactBlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to block'**
  String get contactBlockFailed;

  /// No description provided for @contactUnblockFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unblock'**
  String get contactUnblockFailed;

  /// No description provided for @contactUnblocked.
  ///
  /// In en, this message translates to:
  /// **'Unblocked'**
  String get contactUnblocked;

  /// No description provided for @contactAddedToContacts.
  ///
  /// In en, this message translates to:
  /// **'Added to contacts'**
  String get contactAddedToContacts;

  /// No description provided for @contactRequestOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t message directly'**
  String get contactRequestOfferTitle;

  /// No description provided for @contactRequestOfferBody.
  ///
  /// In en, this message translates to:
  /// **'{name} limited who can message them. Send a request with your card — they decide whether to reply.'**
  String contactRequestOfferBody(Object name);

  /// No description provided for @contactRequestSend.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get contactRequestSend;

  /// No description provided for @contactRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get contactRequestSent;

  /// No description provided for @contactRequestSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the request'**
  String get contactRequestSendFailed;

  /// No description provided for @contactRequestCooldown.
  ///
  /// In en, this message translates to:
  /// **'You recently sent a request — try again later'**
  String get contactRequestCooldown;

  /// No description provided for @requestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Message requests'**
  String get requestsTitle;

  /// No description provided for @requestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get requestsEmpty;

  /// No description provided for @requestsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'When someone who isn\'t in your contacts wants to message you, their request shows up here.'**
  String get requestsEmptyHint;

  /// No description provided for @requestsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load requests'**
  String get requestsLoadFailed;

  /// No description provided for @requestWantsToConnect.
  ///
  /// In en, this message translates to:
  /// **'wants to connect'**
  String get requestWantsToConnect;

  /// No description provided for @requestAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get requestAccept;

  /// No description provided for @requestDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get requestDecline;

  /// No description provided for @requestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get requestDeclined;

  /// No description provided for @requestActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed'**
  String get requestActionFailed;

  /// No description provided for @contactSaveToContacts.
  ///
  /// In en, this message translates to:
  /// **'Save to contacts'**
  String get contactSaveToContacts;

  /// No description provided for @contactShareMyCard.
  ///
  /// In en, this message translates to:
  /// **'Share my card'**
  String get contactShareMyCard;

  /// No description provided for @contactShareCardFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share the card'**
  String get contactShareCardFailed;

  /// No description provided for @chatIntroConnected.
  ///
  /// In en, this message translates to:
  /// **'You\'re now connected — say hello 👋'**
  String get chatIntroConnected;

  /// No description provided for @peopleTitle.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get peopleTitle;

  /// No description provided for @peopleAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get peopleAll;

  /// No description provided for @peopleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get peopleEmpty;

  /// No description provided for @peopleEmptyLabel.
  ///
  /// In en, this message translates to:
  /// **'No one with this label yet — assign labels from a contact\'s profile'**
  String get peopleEmptyLabel;

  /// No description provided for @peopleLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get peopleLoadFailed;

  /// No description provided for @folderPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Folders for “{name}”'**
  String folderPickerTitle(Object name);

  /// No description provided for @folderPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No folders yet — create the first one and this chat will be added to it. One chat can be in several folders.'**
  String get folderPickerEmpty;

  /// No description provided for @folderNewRow.
  ///
  /// In en, this message translates to:
  /// **'New folder…'**
  String get folderNewRow;

  /// No description provided for @folderNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get folderNewTitle;

  /// No description provided for @folderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderNameHint;

  /// No description provided for @folderCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create folder'**
  String get folderCreateFailed;

  /// No description provided for @folderRenameMenu.
  ///
  /// In en, this message translates to:
  /// **'Rename “{name}”'**
  String folderRenameMenu(Object name);

  /// No description provided for @folderRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename folder'**
  String get folderRenameTitle;

  /// No description provided for @folderDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete folder'**
  String get folderDelete;

  /// No description provided for @folderDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete folder “{name}”?'**
  String folderDeleteConfirm(Object name);

  /// No description provided for @folderDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Chats will remain — only the folder is deleted.'**
  String get folderDeleteBody;

  /// No description provided for @folderChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update folder'**
  String get folderChangeFailed;

  /// No description provided for @folderDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete folder'**
  String get folderDeleteFailed;

  /// No description provided for @peopleSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or @username'**
  String get peopleSearchHint;

  /// No description provided for @peopleCount.
  ///
  /// In en, this message translates to:
  /// **'Contacts · {count}'**
  String peopleCount(Object count);

  /// No description provided for @peopleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get peopleNotFound;

  /// No description provided for @peopleWrite.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get peopleWrite;

  /// No description provided for @peopleProfile.
  ///
  /// In en, this message translates to:
  /// **'Contact profile'**
  String get peopleProfile;

  /// No description provided for @folderChatCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{empty} one{{count} chat} other{{count} chats}}'**
  String folderChatCount(num count);

  /// No description provided for @folderDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get folderDone;

  /// No description provided for @folderDoneN.
  ///
  /// In en, this message translates to:
  /// **'Done · {count}'**
  String folderDoneN(Object count);

  /// No description provided for @folderOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get folderOk;

  /// No description provided for @folderPickerHeader.
  ///
  /// In en, this message translates to:
  /// **'Add to folder'**
  String get folderPickerHeader;

  /// No description provided for @lastSeenJustNow.
  ///
  /// In en, this message translates to:
  /// **'last seen just now'**
  String get lastSeenJustNow;

  /// No description provided for @lastSeenMinutes.
  ///
  /// In en, this message translates to:
  /// **'last seen {count} min ago'**
  String lastSeenMinutes(Object count);

  /// No description provided for @lastSeenToday.
  ///
  /// In en, this message translates to:
  /// **'last seen today at {time}'**
  String lastSeenToday(Object time);

  /// No description provided for @lastSeenYesterday.
  ///
  /// In en, this message translates to:
  /// **'last seen yesterday at {time}'**
  String lastSeenYesterday(Object time);

  /// No description provided for @lastSeenDate.
  ///
  /// In en, this message translates to:
  /// **'last seen {date}'**
  String lastSeenDate(Object date);

  /// No description provided for @lastSeenOnline.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get lastSeenOnline;

  /// No description provided for @cardEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'My card'**
  String get cardEditorTitle;

  /// No description provided for @cardSectionStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get cardSectionStyle;

  /// No description provided for @cardSectionFields.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get cardSectionFields;

  /// No description provided for @cardTemplatePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get cardTemplatePhoto;

  /// No description provided for @cardTemplateGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get cardTemplateGradient;

  /// No description provided for @cardTemplateMonogram.
  ///
  /// In en, this message translates to:
  /// **'Monogram'**
  String get cardTemplateMonogram;

  /// No description provided for @cardFontClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get cardFontClassic;

  /// No description provided for @cardFontBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get cardFontBold;

  /// No description provided for @cardFontAiry.
  ///
  /// In en, this message translates to:
  /// **'Airy'**
  String get cardFontAiry;

  /// No description provided for @cardFontMono.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get cardFontMono;

  /// No description provided for @cardColorAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get cardColorAuto;

  /// No description provided for @cardPickPhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get cardPickPhoto;

  /// No description provided for @cardPhotoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo'**
  String get cardPhotoUploadFailed;

  /// No description provided for @cardAboutLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get cardAboutLabel;

  /// No description provided for @cardJobTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get cardJobTitleLabel;

  /// No description provided for @cardCompanyLabel.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get cardCompanyLabel;

  /// No description provided for @cardPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get cardPhoneLabel;

  /// No description provided for @cardEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get cardEmailLabel;

  /// No description provided for @cardWebsiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get cardWebsiteLabel;

  /// No description provided for @cardVisibilityEveryone.
  ///
  /// In en, this message translates to:
  /// **'Visible to everyone'**
  String get cardVisibilityEveryone;

  /// No description provided for @cardVisibilityContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts only'**
  String get cardVisibilityContacts;

  /// No description provided for @cardVisibilityHint.
  ///
  /// In en, this message translates to:
  /// **'Fields with a lock are visible only to your contacts (people you share a chat with)'**
  String get cardVisibilityHint;

  /// No description provided for @cardSaved.
  ///
  /// In en, this message translates to:
  /// **'Card saved'**
  String get cardSaved;

  /// No description provided for @cardSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save card'**
  String get cardSaveFailed;

  /// No description provided for @cardDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete card'**
  String get cardDelete;

  /// No description provided for @cardDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete card?'**
  String get cardDeleteConfirmTitle;

  /// No description provided for @cardDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The design and “about you” fields will be removed. This cannot be undone.'**
  String get cardDeleteConfirmBody;

  /// No description provided for @cardHiddenFieldsNote.
  ///
  /// In en, this message translates to:
  /// **'The full card is visible to contacts'**
  String get cardHiddenFieldsNote;

  /// No description provided for @settingsWhoCanMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Only contacts can message me'**
  String get settingsWhoCanMessageTitle;

  /// No description provided for @settingsWhoCanMessageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only people you already share a chat with can start a new chat with you'**
  String get settingsWhoCanMessageSubtitle;

  /// No description provided for @settingsShowCardsOnCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Cards on call screen'**
  String get settingsShowCardsOnCallTitle;

  /// No description provided for @settingsShowCardsOnCallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the caller\'s card full-screen on incoming calls'**
  String get settingsShowCardsOnCallSubtitle;

  /// No description provided for @settingsPresenceVisibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Show when I\'m online'**
  String get settingsPresenceVisibleTitle;

  /// No description provided for @settingsPresenceVisibleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Peers can see “online” and “last seen…”. If you turn this off, you won\'t see others\' status either'**
  String get settingsPresenceVisibleSubtitle;

  /// No description provided for @peopleSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected: {count}'**
  String peopleSelectedCount(int count);

  /// No description provided for @peopleAssignLabelAction.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get peopleAssignLabelAction;

  /// No description provided for @peopleBatchLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign label · {count}'**
  String peopleBatchLabelTitle(int count);

  /// No description provided for @profileLangBase.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get profileLangBase;

  /// No description provided for @profileLangAdd.
  ///
  /// In en, this message translates to:
  /// **'+ Language'**
  String get profileLangAdd;

  /// No description provided for @profileLangAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add profile language'**
  String get profileLangAddTitle;

  /// No description provided for @profileLangHelper.
  ///
  /// In en, this message translates to:
  /// **'People using {locale} will see these fields. Empty fields fall back to the English or primary version.'**
  String profileLangHelper(String locale);

  /// No description provided for @profileLangSaved.
  ///
  /// In en, this message translates to:
  /// **'{locale} version saved'**
  String profileLangSaved(String locale);

  /// No description provided for @roomCustomNameAction.
  ///
  /// In en, this message translates to:
  /// **'Custom chat name'**
  String get roomCustomNameAction;

  /// No description provided for @roomCustomNameHint.
  ///
  /// In en, this message translates to:
  /// **'Visible only to you — others see the regular name'**
  String get roomCustomNameHint;

  /// No description provided for @roomCustomNameReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get roomCustomNameReset;

  /// No description provided for @roomAdminWriteBanAction.
  ///
  /// In en, this message translates to:
  /// **'Forbid writing'**
  String get roomAdminWriteBanAction;

  /// No description provided for @roomAdminWriteUnbanAction.
  ///
  /// In en, this message translates to:
  /// **'Allow writing'**
  String get roomAdminWriteUnbanAction;

  /// No description provided for @roomAdminWriteBanDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Forbid writing for…'**
  String get roomAdminWriteBanDurationTitle;

  /// No description provided for @roomAdminWriteBanHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get roomAdminWriteBanHour;

  /// No description provided for @roomAdminWriteBanDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get roomAdminWriteBanDay;

  /// No description provided for @roomAdminWriteBanWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get roomAdminWriteBanWeek;

  /// No description provided for @roomAdminWriteBanForever.
  ///
  /// In en, this message translates to:
  /// **'Forever'**
  String get roomAdminWriteBanForever;

  /// No description provided for @roomAdminWriteBannedUntil.
  ///
  /// In en, this message translates to:
  /// **'Forbidden until {until}'**
  String roomAdminWriteBannedUntil(String until);

  /// No description provided for @writeBannedForeverSnack.
  ///
  /// In en, this message translates to:
  /// **'An admin has forbidden you from writing in this chat'**
  String get writeBannedForeverSnack;

  /// No description provided for @writeBannedUntilSnack.
  ///
  /// In en, this message translates to:
  /// **'You cannot write in this chat until {until}'**
  String writeBannedUntilSnack(String until);
}

class _NsgL10nDelegate extends LocalizationsDelegate<NsgL10n> {
  const _NsgL10nDelegate();

  @override
  Future<NsgL10n> load(Locale locale) {
    return SynchronousFuture<NsgL10n>(lookupNsgL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_NsgL10nDelegate old) => false;
}

NsgL10n lookupNsgL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return NsgL10nEn();
    case 'ru':
      return NsgL10nRu();
  }

  throw FlutterError(
    'NsgL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
