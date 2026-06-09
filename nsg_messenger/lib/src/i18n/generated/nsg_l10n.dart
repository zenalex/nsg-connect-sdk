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

  /// TASK19 Chunk 3: snackbar когда upload через `messenger.uploadAttachment` упал (network / server reject mime). UI revert composer state.
  ///
  /// In en, this message translates to:
  /// **'Upload failed — try again'**
  String get attachUploadFailed;

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
