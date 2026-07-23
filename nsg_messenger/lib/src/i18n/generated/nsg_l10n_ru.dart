// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'nsg_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class NsgL10nRu extends NsgL10n {
  NsgL10nRu([String locale = 'ru']) : super(locale);

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonNewChat => 'Новый чат';

  @override
  String get commonConnectionLost => 'Соединение потеряно — показываем кэш';

  @override
  String get chatsListTitle => 'Чаты';

  @override
  String get chatsListEmpty => 'Нет чатов';

  @override
  String get chatsListLoadFailed => 'Не удалось загрузить чаты';

  @override
  String get createChatInvalidId => 'Введите числовой messengerUserId';

  @override
  String get createChatPeerUnavailable => 'Пользователь недоступен';

  @override
  String get createChatHelp =>
      'Создание direct-чата по messengerUserId. Поиск по имени — TASK42.';

  @override
  String get createChatSubmit => 'Создать direct-чат';

  @override
  String get chatScreenEmpty => 'Сообщений пока нет — напиши первое';

  @override
  String get chatScreenLoadFailed => 'Не удалось загрузить сообщения';

  @override
  String get chatJumpToLatestTooltip => 'К последнему сообщению';

  @override
  String get chatScreenSendHint => 'Сообщение…';

  @override
  String get chatScreenSendTooltip => 'Отправить';

  @override
  String get roomSummaryNoName => '(без имени)';

  @override
  String get roomSummaryNoMessages => 'Нет сообщений';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get roomActionSheetTitle => 'Действия';

  @override
  String get roomActionMute => 'Заглушить';

  @override
  String get roomActionUnmute => 'Включить уведомления';

  @override
  String get roomActionMuteFor1Hour => '1 час';

  @override
  String get roomActionMuteFor8Hours => '8 часов';

  @override
  String get roomActionMuteFor1Day => '1 день';

  @override
  String get roomActionMuteFor1Week => '1 неделя';

  @override
  String get roomActionMuteForever => 'Навсегда';

  @override
  String get roomActionMuteUntilTitle => 'Заглушить до';

  @override
  String get roomActionArchive => 'В архив';

  @override
  String get roomActionUnarchive => 'Из архива';

  @override
  String get roomActionDismissSupport => 'Закрыть (до ответа)';

  @override
  String get roomActionLeave => 'Покинуть чат';

  @override
  String get roomActionLeaveConfirmTitle => 'Покинуть чат?';

  @override
  String get roomActionLeaveConfirmBody =>
      'Вас удалят из переписки. Остальные участники увидят, что вы вышли.';

  @override
  String get roomActionFailedSnack => 'Не удалось — попробуйте ещё раз';

  @override
  String get chatsListFilterMenuTooltip => 'Фильтр';

  @override
  String get chatsListFilterActive => 'Активные';

  @override
  String get chatsListFilterArchived => 'Архив';

  @override
  String get chatsListFilterAll => 'Все';

  @override
  String get chatsListSearchTooltip => 'Поиск';

  @override
  String get chatsListSearchHint => 'Поиск по чатам…';

  @override
  String get chatsListSearchClearTooltip => 'Очистить';

  @override
  String get chatsListSearchEmpty => 'Ничего не найдено';

  @override
  String get chatsListProductFilterTooltip => 'Продукт';

  @override
  String get chatsListProductFilterAll => 'Все продукты';

  @override
  String get chatsListFolderAll => 'Все';

  @override
  String get chatsListFolderPersonal => 'Личные';

  @override
  String chatsListFolderProductFallback(int productId) {
    return 'Продукт $productId';
  }

  @override
  String chatsListFolderRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count чата',
      many: '$count чатов',
      few: '$count чата',
      one: '$count чат',
    );
    return '$_temp0';
  }

  @override
  String get chatsListFolderSupportSection => 'Поддержка';

  @override
  String get chatsListFolderOtherSection => 'Чаты';

  @override
  String get chatsListFolderSupport => 'Поддержка';

  @override
  String get chatsListFolderCustom => 'Папка';

  @override
  String get savedChatsTitle => 'Избранное';

  @override
  String get savedChatsCreateAction => 'Новый раздел';

  @override
  String get savedChatsCreateHint => 'Название раздела';

  @override
  String get savedChatsEmpty =>
      'Отправляйте себе заметки, файлы и ссылки — они синхронизируются на всех ваших устройствах.';

  @override
  String savedChatsLimitReached(int limit) {
    return 'Достигнут предел разделов ($limit). Удалите ненужный.';
  }

  @override
  String get savedChatsNameTaken => 'Раздел с таким названием уже есть.';

  @override
  String get autoCleanupTitle => 'Автоудаление сообщений';

  @override
  String get autoCleanupHint => 'Закреплённые сообщения не удаляются';

  @override
  String get autoCleanupOff => 'Никогда';

  @override
  String autoCleanupAfterDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Через $days дня',
      many: 'Через $days дней',
      few: 'Через $days дня',
      one: 'Через $days день',
    );
    return '$_temp0';
  }

  @override
  String get attachActionSheetTitle => 'Прикрепить';

  @override
  String get attachActionCamera => 'Камера';

  @override
  String get attachActionGallery => 'Галерея';

  @override
  String get attachActionImage => 'Изображение';

  @override
  String get attachActionFile => 'Файл';

  @override
  String attachFileTooLarge(String names) {
    return 'Слишком большой (лимит 50 МБ), не прикреплён: $names';
  }

  @override
  String get attachUploadFailed => 'Не удалось загрузить — попробуйте ещё раз';

  @override
  String attachRejectedType(String filename) {
    return 'Не удалось отправить «$filename» — этот тип файла не поддерживается';
  }

  @override
  String attachRejectedExecutable(String filename) {
    return 'Не удалось отправить «$filename» — исполняемые файлы отправлять нельзя';
  }

  @override
  String attachRejectedTooLarge(String filename, int maxMb) {
    return 'Не удалось отправить «$filename» — файл больше $maxMb МБ';
  }

  @override
  String get attachUnnamedFallback => 'Без имени';

  @override
  String get attachTooltip => 'Прикрепить файл';

  @override
  String get voiceRecordTooltip => 'Удерживайте для записи';

  @override
  String get voiceRecordingHint => 'Запись…';

  @override
  String get voiceRecordTooShort => 'Запись слишком короткая';

  @override
  String get voiceRecordPermissionDenied => 'Нет доступа к микрофону';

  @override
  String get voiceRecordError => 'Не удалось записать';

  @override
  String get messageActionSheetTitle => 'Сообщение';

  @override
  String get messageActionEdit => 'Редактировать';

  @override
  String get messageActionDelete => 'Удалить';

  @override
  String get messageActionCopy => 'Копировать';

  @override
  String get messageActionEditDialogTitle => 'Редактирование';

  @override
  String get messageActionEditSave => 'Сохранить';

  @override
  String get messageActionDeleteConfirmTitle => 'Удалить сообщение?';

  @override
  String get messageActionDeleteConfirmBody =>
      'Действие нельзя отменить. Сообщение будет скрыто у всех участников чата.';

  @override
  String get messageEditFailed =>
      'Не удалось отредактировать — попробуйте ещё раз';

  @override
  String get messageDeleteFailed => 'Не удалось удалить — попробуйте ещё раз';

  @override
  String get messageDeletedPlaceholder => 'Сообщение удалено';

  @override
  String get messageEditedBadge => 'изменено';

  @override
  String get messageShowMore => 'Показать полностью';

  @override
  String get messageCopiedSnack => 'Скопировано';

  @override
  String get messageActionReply => 'Ответить';

  @override
  String get messageActionReplyWithMention => 'Ответить с упоминанием';

  @override
  String get mentionParticipantAction => 'Упомянуть';

  @override
  String get emojiPickerTitle => 'Выберите реакцию';

  @override
  String get emojiCategorySmileys => 'Смайлы и эмоции';

  @override
  String get emojiCategoryGestures => 'Жесты и люди';

  @override
  String get emojiCategoryHearts => 'Сердца и символы';

  @override
  String get emojiCategoryAnimals => 'Животные и природа';

  @override
  String get emojiCategoryFood => 'Еда и напитки';

  @override
  String get emojiCategoryActivity => 'Активности и объекты';

  @override
  String get emojiCategorySymbols => 'Символы';

  @override
  String get messageActionCreateTask => 'Создать задачу';

  @override
  String taskCreatedSnack(String taskKey) {
    return 'Задача $taskKey создана';
  }

  @override
  String get taskCreateFailed => 'Не удалось создать задачу';

  @override
  String get taskIntegrationDisabled => 'Интеграция с задачами не настроена';

  @override
  String composerReplyingTo(String name) {
    return 'Ответ $name';
  }

  @override
  String get composerCancelReply => 'Отменить ответ';

  @override
  String get composerEditing => 'Редактирование';

  @override
  String get composerEditingAlbum => 'Редактирование альбома';

  @override
  String get composerFormatBold => 'Жирный';

  @override
  String get composerFormatItalic => 'Курсив';

  @override
  String get composerCancelEdit => 'Отменить редактирование';

  @override
  String get messageComposerSaveTooltip => 'Сохранить';

  @override
  String typingSingle(String name) {
    return '$name печатает…';
  }

  @override
  String typingPair(String name1, String name2) {
    return '$name1 и $name2 печатают…';
  }

  @override
  String get roomRenameTitle => 'Переименовать чат';

  @override
  String get roomRenameHint => 'Новое название';

  @override
  String get roomRenameSave => 'Сохранить';

  @override
  String get roomRenameCancel => 'Отмена';

  @override
  String get roomRenameFailed =>
      'Не удалось переименовать — попробуй ещё раз или проверь права';

  @override
  String get readReceiptsSheetTitle => 'Просмотрели';

  @override
  String get readReceiptsSectionRead => 'Прочитали';

  @override
  String get readReceiptsSectionUnread => 'Не прочитали';

  @override
  String readReceiptsLargeGroupHint(int count, int total) {
    return 'Подробный список доступен только для групп до 25 участников. Прочитали $count из $total.';
  }

  @override
  String get readReceiptsNobodyRead => 'Пока никто не прочитал';

  @override
  String readReceiptsCountLabel(int count) {
    return '$count';
  }

  @override
  String get groupDissolveAction => 'Удалить группу';

  @override
  String groupDissolveConfirmTitle(String name) {
    return 'Удалить группу «$name»?';
  }

  @override
  String get groupDissolveConfirmBody =>
      'Все участники будут выкинуты, чат закроется. Действие нельзя отменить.';

  @override
  String get groupDissolveProgress => 'Удаляем группу…';

  @override
  String groupDissolveFailed(int kicked, int total) {
    return 'Не удалось полностью удалить — попробуй ещё раз. Участников выкинуто: $kicked из $total.';
  }

  @override
  String get groupDissolveSuccess => 'Группа удалена';

  @override
  String typingManyCount(int count) {
    return '$count участников печатают…';
  }

  @override
  String get replyChipUnavailable => 'Исходное сообщение недоступно';

  @override
  String get mentionTypeaheadEmpty => 'Нет совпадений';

  @override
  String mentionTypeaheadShowingHeader(int shown, int total) {
    return 'Показано $shown из $total';
  }

  @override
  String get roleBadgeOwner => 'Владелец';

  @override
  String get roleBadgeAdmin => 'Администратор';

  @override
  String get roomAdminKickAction => 'Удалить из комнаты';

  @override
  String get roomAdminBanAction => 'Заблокировать';

  @override
  String get roomAdminPromoteAction => 'Сделать администратором';

  @override
  String get roomAdminPromoteOwnerAction => 'Сделать владельцем';

  @override
  String get roomAdminDemoteAction => 'Понизить до участника';

  @override
  String roomAdminKickConfirmTitle(String name) {
    return 'Удалить $name?';
  }

  @override
  String roomAdminKickConfirmBody(String name) {
    return '$name сможет вернуться по приглашению.';
  }

  @override
  String roomAdminBanConfirmTitle(String name) {
    return 'Заблокировать $name?';
  }

  @override
  String roomAdminBanConfirmBody(String name) {
    return '$name не сможет вернуться, пока вы не снимете блокировку.';
  }

  @override
  String get roomAdminLastOwnerError =>
      'Нельзя понизить последнего владельца. Сначала назначьте другого.';

  @override
  String get roomAdminInsufficientPowerError =>
      'Недостаточно прав для этого действия.';

  @override
  String get roomAdminGenericError =>
      'Не удалось выполнить — попробуйте ещё раз.';

  @override
  String get bannedUsersTitle => 'Заблокированные';

  @override
  String get bannedUsersEmpty => 'Нет заблокированных';

  @override
  String get bannedUsersUnbanAction => 'Разблокировать';

  @override
  String get bannedUsersUnbanSuccess =>
      'Разблокирован — при необходимости пригласите заново';

  @override
  String get bannedUsersReinviteAction => 'Пригласить заново';

  @override
  String get bannedUsersReinviteSuccess => 'Приглашение отправлено';

  @override
  String get participantsTitle => 'Участники';

  @override
  String get participantsBannedMenuItem => 'Заблокированные';

  @override
  String get notificationSettingsTitle => 'Уведомления';

  @override
  String get notificationSettingsPreviewTitle => 'Показывать текст сообщений';

  @override
  String get notificationSettingsPreviewSubtitle =>
      'Имя отправителя и текст видны на экране блокировки. Выключите, чтобы скрыть содержимое.';

  @override
  String get notificationSettingsReadReceiptsTitle =>
      'Отправлять отметки о прочтении';

  @override
  String get notificationSettingsReadReceiptsSubtitle =>
      'Другие видят, что вы прочитали их сообщения. Выключите, чтобы читать незаметно.';

  @override
  String get notificationSettingsSaveFailed =>
      'Не удалось сохранить — попробуйте ещё раз';

  @override
  String get settingsPrivacySectionTitle => 'Приватность';

  @override
  String get notificationSettingsDiscoverableTitle =>
      'Меня можно найти в поиске';

  @override
  String get notificationSettingsDiscoverableSubtitle =>
      'Другие могут найти вас по имени или email. Выключите, чтобы скрыться из поиска.';

  @override
  String get connectionStateHealthy => 'Подключено';

  @override
  String get connectionStateReconnecting => 'Переподключение…';

  @override
  String get connectionStateDisconnected => 'Соединение потеряно';

  @override
  String get supportTeamTitle => 'Команда поддержки';

  @override
  String get supportTeamEmpty => 'В команде пока нет участников';

  @override
  String get supportTeamAddHint => 'Добавить оператора по email';

  @override
  String get supportTeamAddAction => 'Добавить';

  @override
  String get supportTeamRemoveAction => 'Удалить';

  @override
  String get supportTeamTierEscalation => 'Эскалация';

  @override
  String get supportTeamMakeEscalation => 'Сделать старшим (эскалация)';

  @override
  String get supportTeamMakeFrontline => 'Вернуть в фронт-линию';

  @override
  String get supportTeamMakeOwner => 'Назначить администратором';

  @override
  String get supportTeamRevokeOwner => 'Снять администратора';

  @override
  String get supportTeamTimeoutLabel => 'Таймаут авто-эскалации';

  @override
  String get supportTeamMinutesShort => 'мин';

  @override
  String get supportTeamRoleOwner => 'Владелец';

  @override
  String get supportTeamRoleMember => 'Оператор';

  @override
  String get supportTeamBotBadge => 'Бот';

  @override
  String get supportTeamUnavailable => 'Команда поддержки недоступна';

  @override
  String get supportTeamActionFailed =>
      'Не удалось выполнить — попробуйте ещё раз';

  @override
  String get escalateToDevelopersAction => 'Обратиться к разработчикам';

  @override
  String get escalateToDevelopersDone => 'Команда NSG подключена';

  @override
  String get escalateToDevelopersFailed =>
      'Не удалось подключить команду — попробуйте ещё раз';

  @override
  String get escalateSupportAction => 'Позвать старшего';

  @override
  String get escalateSupportDone => 'Старший оператор подключён';

  @override
  String get escalateSupportFailed =>
      'Не удалось эскалировать — попробуйте ещё раз';

  @override
  String get escalateSupportNoop =>
      'Некого подключать — старших нет или они уже в чате';

  @override
  String objectRoomsCatalogTitle(String product) {
    return 'Объектовые чаты — $product';
  }

  @override
  String get objectRoomsCatalogEmpty => 'Пока нет объектовых чатов';

  @override
  String get objectRoomsCatalogUnavailable => 'Каталог недоступен';

  @override
  String get objectRoomsCatalogJoinFailed =>
      'Не удалось войти в чат — попробуйте ещё раз';

  @override
  String get objectRoomsCatalogMemberBadge => 'Вы в чате';

  @override
  String get objectRoomsCatalogLeaveAction => 'Выйти из чата';

  @override
  String get objectRoomsCatalogLeaveDone => 'Вы вышли из чата';

  @override
  String get objectRoomsCatalogEntry => 'Объектовые чаты';

  @override
  String get callStartTooltip => 'Позвонить';

  @override
  String get callAlreadyActive => 'Уже идёт звонок — сначала завершите его';

  @override
  String callOutgoingTitle(String peer) {
    return 'Звоним $peer…';
  }

  @override
  String callIncomingTitle(String caller) {
    return '$caller звонит';
  }

  @override
  String get callIncomingSubtitle => 'Входящий звонок';

  @override
  String get callConnecting => 'Соединение…';

  @override
  String get callAccept => 'Принять';

  @override
  String get callDecline => 'Отклонить';

  @override
  String get callHangup => 'Завершить';

  @override
  String get callMute => 'Выключить микрофон';

  @override
  String get callUnmute => 'Включить микрофон';

  @override
  String get callSpeakerOn => 'Включить громкую связь';

  @override
  String get callSpeakerOff => 'Выключить громкую связь';

  @override
  String get callPeerFallback => 'Собеседник';

  @override
  String get callEndedGeneric => 'Звонок завершён';

  @override
  String get callEndedDeclined => 'Отклонён';

  @override
  String get callEndedMicDenied => 'Разрешите доступ к микрофону';

  @override
  String get callEndedFailed => 'Ошибка';

  @override
  String get conferenceStartTooltip => 'Групповой звонок';

  @override
  String get conferenceTitle => 'Групповой звонок';

  @override
  String conferenceIncomingTitle(String room) {
    return 'Групповой звонок в $room';
  }

  @override
  String conferenceIncomingCaller(String caller) {
    return '$caller приглашает вас';
  }

  @override
  String conferenceMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count участника',
      many: '$count участников',
      few: '$count участника',
      one: '$count участник',
    );
    return '$_temp0';
  }

  @override
  String get conferenceOngoingBannerTitle => 'Идёт групповой звонок';

  @override
  String get conferenceJoin => 'Присоединиться';

  @override
  String conferenceEndedFull(int max) {
    return 'Конференция заполнена (макс. $max)';
  }

  @override
  String get conferenceYou => 'Вы';

  @override
  String get conferencePairFailed => 'Нет связи';

  @override
  String get messageActionForward => 'Переслать';

  @override
  String get messageActionPin => 'Закрепить';

  @override
  String get messageActionUnpin => 'Открепить';

  @override
  String get pinnedMessagesTitle => 'Закреплённое сообщение';

  @override
  String get messagePinnedSnack => 'Сообщение закреплено';

  @override
  String get messageUnpinnedSnack => 'Сообщение откреплено';

  @override
  String get pinMessageFailed => 'Не удалось закрепить сообщение';

  @override
  String get unpinMessageFailed => 'Не удалось открепить сообщение';

  @override
  String get pinNotAllowed =>
      'Закреплять сообщения здесь могут только администраторы';

  @override
  String get messageActionSelect => 'Выбрать';

  @override
  String selectedCountTitle(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get messageActionShare => 'Поделиться';

  @override
  String get forwardPickerTitle => 'Переслать в…';

  @override
  String get forwardSearchHint => 'Поиск чатов';

  @override
  String get forwardNoRooms => 'Нет чатов для пересылки';

  @override
  String get forwardedSnack => 'Переслано';

  @override
  String forwardMultiButton(int count) {
    return 'Переслать ($count)';
  }

  @override
  String forwardedToChatsSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Переслано в $count чата',
      many: 'Переслано в $count чатов',
      few: 'Переслано в $count чата',
      one: 'Переслано в $count чат',
    );
    return '$_temp0';
  }

  @override
  String get forwardOpenChat => 'Открыть';

  @override
  String get forwardFailed => 'Не удалось переслать — попробуйте ещё раз';

  @override
  String get shareFailed => 'Не удалось поделиться — попробуйте ещё раз';

  @override
  String get messageActionCopyImage => 'Скопировать изображение';

  @override
  String get imageCopiedSnack => 'Изображение скопировано в буфер обмена';

  @override
  String get messageActionCancelSend => 'Отменить отправку';

  @override
  String get messageCancelSendFailed => 'Не удалось отменить отправку';

  @override
  String get imageCopyFailed => 'Не удалось скопировать изображение';

  @override
  String get sharePickerTitle => 'Отправить в…';

  @override
  String shareConfirmTitle(String name) {
    return 'Отправить в «$name»?';
  }

  @override
  String shareConfirmFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла',
      many: '$count файлов',
      few: '$count файла',
      one: '$count файл',
    );
    return '$_temp0';
  }

  @override
  String get shareSend => 'Отправить';

  @override
  String shareProgress(int current, int total) {
    return 'Отправка $current из $total…';
  }

  @override
  String get shareSent => 'Отправлено';

  @override
  String get shareQueued => 'Добавлено в очередь отправки';

  @override
  String get shareSomeFailed => 'Часть вложений не отправилась';

  @override
  String shareFileTooLarge(String names) {
    return 'Слишком большой размер: $names';
  }

  @override
  String get shareBusy => 'Отправка ещё идёт';

  @override
  String messageForwardedFrom(String name) {
    return 'Переслано от $name';
  }

  @override
  String get forwardSourceUnavailable => 'Исходный чат недоступен';

  @override
  String get commonOk => 'ОК';

  @override
  String get statusCardOpenLink => 'Открыть';

  @override
  String get integrationsTitle => 'Интеграции';

  @override
  String get integrationsAutopostsSection => 'Автопосты';

  @override
  String get integrationsBotsSection => 'Боты';

  @override
  String get integrationsAddAutopost => 'Добавить автопост';

  @override
  String get integrationsEmpty => 'Автопостов пока нет';

  @override
  String get integrationsLoadFailed => 'Не удалось загрузить интеграции';

  @override
  String get integrationsNameLabel => 'Название';

  @override
  String get integrationsNameHint => 'напр. CI · Деплой';

  @override
  String get integrationsCreate => 'Создать';

  @override
  String get integrationsWebhookUrlLabel => 'URL webhook-а';

  @override
  String get integrationsWebhookUrlOnce =>
      'Скопируйте URL сейчас — токен показывается один раз.';

  @override
  String get integrationsCopied => 'URL скопирован';

  @override
  String get integrationsCopy => 'Копировать';

  @override
  String get integrationsTestPost => 'Тестовый пост';

  @override
  String get integrationsRotateToken => 'Пересоздать токен';

  @override
  String get integrationsEnable => 'Включить';

  @override
  String get integrationsDisable => 'Выключить';

  @override
  String get integrationsDelete => 'Удалить';

  @override
  String get integrationsDeleteConfirmTitle => 'Удалить автопост?';

  @override
  String get integrationsDeleteConfirmBody =>
      'Webhook перестанет работать, его URL станет недействительным.';

  @override
  String get integrationsDisabledBadge => 'выключен';

  @override
  String integrationsLastPost(String when) {
    return 'последний пост $when';
  }

  @override
  String get integrationsNeverPosted => 'постов ещё не было';

  @override
  String get integrationsTestPostSent => 'Тестовый пост отправлен';

  @override
  String get integrationsActionFailed =>
      'Действие не удалось — попробуйте ещё раз';

  @override
  String get integrationsCopiedGeneric => 'Скопировано';

  @override
  String get integrationsAddBot => 'Добавить бота';

  @override
  String get integrationsBotsEmpty => 'Ботов пока нет';

  @override
  String get integrationsBotNameHint => 'напр. Бот деплоя';

  @override
  String get integrationsBotWebhookUrlLabel => 'Webhook URL';

  @override
  String get integrationsBotWebhookUrlHint => 'https://example.com/webhook';

  @override
  String get integrationsBotWebhookUrlInvalid =>
      'Введите корректный https:// URL';

  @override
  String get integrationsBotCredentialsTitle => 'Учётные данные бота';

  @override
  String get integrationsBotCredentialsOnce =>
      'Эти секреты показываются один раз — скопируйте их сейчас.';

  @override
  String get integrationsBotTokenLabel => 'Токен бота';

  @override
  String get integrationsBotSecretLabel => 'Секрет webhook-а';

  @override
  String get integrationsApiBaseLabel => 'Базовый URL API';

  @override
  String get integrationsRoomIdLabel => 'ID комнаты';

  @override
  String get integrationsBotUserIdLabel => 'ID пользователя бота';

  @override
  String get integrationsBotUserIdCaption =>
      'Нужен, чтобы отфильтровать собственные эхо-сообщения бота.';

  @override
  String get integrationsEventsLabel => 'События';

  @override
  String get integrationsBotHandoffHint =>
      'Отдайте эти данные разработчику вместе со ссылкой на документацию.';

  @override
  String get integrationsRotateSecret => 'Пересоздать секрет';

  @override
  String get integrationsBotDeleteConfirmTitle => 'Удалить бота?';

  @override
  String get integrationsBotDeleteConfirmBody =>
      'Бот будет удалён из комнаты, его подписка на webhook — удалена.';

  @override
  String get botsAdminTitle => 'Боты';

  @override
  String get botsAdminEmpty =>
      'Ботов пока нет. Бот — это программа, которая постит в чаты своим токеном.';

  @override
  String get botsAdminLoadFailed => 'Не удалось загрузить ботов';

  @override
  String get botsAdminActionFailed => 'Не получилось — попробуйте ещё раз';

  @override
  String get botsAdminCreate => 'Добавить бота';

  @override
  String get botsAdminNameLabel => 'Имя';

  @override
  String get botsAdminNameHint => 'Оповещения о деплое';

  @override
  String get botsAdminOwnerEmailLabel => 'Email владельца';

  @override
  String get botsAdminOwnerEmailHint => 'owner@company.com';

  @override
  String get botsAdminCapabilitiesLabel => 'Что боту разрешено';

  @override
  String get botsAdminCapReadOnly => 'Только чтение';

  @override
  String get botsAdminCapSendMessages => 'Отправлять сообщения';

  @override
  String get botsAdminCapManageRoom => 'Управлять чатами';

  @override
  String get botsAdminCapWebhookTarget => 'Принимать webhook-и';

  @override
  String get botsAdminNoCapabilities => 'без прав';

  @override
  String get botsAdminTokenTitle => 'Токен доступа бота';

  @override
  String get botsAdminTokenOnce =>
      'Показывается один раз. Сохраните сейчас — если потеряете, останется только ротация токена.';

  @override
  String get botsAdminRotateToken => 'Ротировать токен';

  @override
  String get botsAdminRotateConfirmTitle => 'Ротировать токен?';

  @override
  String get botsAdminRotateConfirmBody =>
      'Текущий токен перестанет работать сразу. Бот замолчит, пока в его программу не подставят новый токен. Сам бот, его чаты и история сохранятся.';

  @override
  String get botsAdminEnable => 'Включить';

  @override
  String get botsAdminDisable => 'Выключить';

  @override
  String get botsAdminDisabledBadge => 'выключен';

  @override
  String get botsAdminAddToRoom => 'Добавить в чат';

  @override
  String get botsAdminAddToRoomTitle => 'Выберите чат';

  @override
  String get botsAdminAddedToRoom => 'Бот добавлен в чат';

  @override
  String get botsAdminAlreadyInRoom => 'Уже добавлен';

  @override
  String get botsAdminNoRooms => 'Нет доступных чатов';

  @override
  String get botsAdminAudit => 'Журнал';

  @override
  String botsAdminAuditTitle(String name) {
    return 'Журнал — $name';
  }

  @override
  String get botsAdminAuditEmpty => 'Событий пока нет';

  @override
  String get botsAdminAuditActorBot => 'сам бот';

  @override
  String get botsAdminAuditActorSystem => 'система';

  @override
  String get botsAdminAuditCreated => 'Бот создан';

  @override
  String get botsAdminAuditTokenRotated => 'Токен ротирован';

  @override
  String get botsAdminAuditEnabled => 'Включён';

  @override
  String get botsAdminAuditDisabled => 'Выключен';

  @override
  String get botsAdminAuditAddedToRoom => 'Добавлен в чат';

  @override
  String get botsAdminAuditCapabilityDenied => 'Действие отклонено';

  @override
  String get botsAdminAuditRemovedFromRoom => 'Отозван из чата';

  @override
  String get botsAdminAuditDiscoverableOn => 'Включена видимость в поиске';

  @override
  String get botsAdminAuditDiscoverableOff => 'Скрыт из поиска';

  @override
  String get platformAdminTitle => 'Платформа';

  @override
  String get platformAdminEmpty =>
      'Тенантов нет — или нет доступа. Список отдаётся только платформенным админам.';

  @override
  String get platformAdminActionFailed => 'Не получилось — попробуйте ещё раз';

  @override
  String get platformAdminStatusEnabled => 'включено';

  @override
  String get platformAdminStatusDisabled => 'выключено';

  @override
  String get platformAdminSecretSet => 'секрет задан';

  @override
  String get platformAdminSecretMissing => 'секрета нет';

  @override
  String platformAdminGraceUntil(String until) {
    return 'прежний секрет действует до $until';
  }

  @override
  String get platformAdminEnableGenerate => 'Включить и сгенерировать секрет';

  @override
  String get platformAdminRotate => 'Ротировать секрет';

  @override
  String get platformAdminRotateTitle => 'Ротировать секрет?';

  @override
  String get platformAdminRotateBody =>
      'Будет выдан новый секрет. Старый продолжит работать grace-период ниже, затем умрёт.';

  @override
  String platformAdminGraceLabel(int max) {
    return 'Grace, минут (макс. $max)';
  }

  @override
  String get platformAdminSecretTitle => 'Сервисный секрет тенанта';

  @override
  String get platformAdminSecretOnce =>
      'Секрет показывается ОДИН раз. Сервер хранит только хеш — если потеряете, останется только ротация.';

  @override
  String get platformAdminDisable => 'Выключить';

  @override
  String get platformAdminDisableConfirmTitle =>
      'Выключить issued-token-режим?';

  @override
  String get platformAdminDisableConfirmBody =>
      'Kill-switch: оба хеша секрета обнуляются, продукт сразу теряет доступ. Повторное включение выдаст совершенно новый секрет.';

  @override
  String get platformAdminAudit => 'Журнал';

  @override
  String platformAdminAuditTitle(String name) {
    return 'Журнал — $name';
  }

  @override
  String get platformAdminAuditEmpty => 'Событий пока нет';

  @override
  String get platformAdminAuditEnabledGenerated =>
      'Режим включён, секрет выдан';

  @override
  String get platformAdminAuditRotated => 'Секрет ротирован';

  @override
  String get platformAdminAuditDisabled => 'Режим выключен';

  @override
  String get myBotsTitle => 'Мои боты';

  @override
  String get myBotsEmpty =>
      'Ботов пока нет. Бот — это программа, которая пишет в чаты от собственного аккаунта по токену доступа: уведомления о деплоях, напоминания, интеграции. Создайте бота и добавьте его в свои чаты — или сделайте публичным, чтобы его находили поиском.';

  @override
  String get myBotsDiscoverable => 'Виден в поиске';

  @override
  String get myBotsDiscoverableSubtitle =>
      'Любой сможет найти бота и добавить его в свои чаты';

  @override
  String get myBotsPublicBadge => 'в поиске';

  @override
  String get myBotsMakeDiscoverable => 'Показывать в поиске';

  @override
  String get myBotsMakeHidden => 'Скрыть из поиска';

  @override
  String get myBotsRooms => 'Чаты бота';

  @override
  String myBotsRoomsTitle(String name) {
    return 'Чаты — $name';
  }

  @override
  String get myBotsRoomsEmpty => 'Бот пока не состоит ни в одном чате';

  @override
  String get myBotsRevoke => 'Отозвать';

  @override
  String get myBotsRevokeConfirmTitle => 'Отозвать бота из чата?';

  @override
  String get myBotsRevokeConfirmBody =>
      'Бот выйдет из чата. Его сообщения останутся; позже бота можно добавить снова.';

  @override
  String get myBotsRevoked => 'Бот отозван из чата';

  @override
  String myBotsLimitReached(int limit) {
    return 'Достигнут лимит ботов ($limit). Вместо нового бота ротируйте токен или переиспользуйте существующего.';
  }

  @override
  String get pulseTitle => 'Мониторинг';

  @override
  String get pulseNoAccess => 'У вас нет доступа к мониторингу.';

  @override
  String get pulseEmpty => 'Мониторов пока нет';

  @override
  String get pulseLoadFailed => 'Не удалось загрузить мониторинг';

  @override
  String get pulseActionFailed => 'Действие не выполнено — попробуйте ещё раз';

  @override
  String get pulseAddFolder => 'Папка';

  @override
  String get pulseAddMonitor => 'Монитор';

  @override
  String get pulseNewFolder => 'Новая папка';

  @override
  String get pulseNewMonitor => 'Новый монитор';

  @override
  String get pulseNameLabel => 'Название';

  @override
  String get pulseFolderNameHint => 'напр. Продакшн';

  @override
  String get pulseMonitorNameHint => 'напр. Ночной бэкап';

  @override
  String get pulseCreate => 'Создать';

  @override
  String get pulseRename => 'Переименовать';

  @override
  String get pulseParentFolderLabel => 'Папка';

  @override
  String get pulseFolderRoot => 'Корень';

  @override
  String get pulsePeriodLabel => 'Период';

  @override
  String get pulseGraceLabel => 'Допуск (сек)';

  @override
  String get pulsePeriod60s => '60 сек';

  @override
  String get pulsePeriod5m => '5 мин';

  @override
  String get pulsePeriod15m => '15 мин';

  @override
  String get pulsePeriod1h => '1 час';

  @override
  String get pulsePeriod24h => '24 часа';

  @override
  String pulseLastSignal(String when) {
    return 'сигнал $when';
  }

  @override
  String get pulseNoSignal => 'сигналов ещё не было';

  @override
  String get pulseBadgeLate => 'опоздание';

  @override
  String get pulseBadgeDown => 'нет связи';

  @override
  String get pulsePaused => 'пауза';

  @override
  String pulseDetailPeriodGrace(String period, int grace) {
    return 'Период $period · допуск $grace сек';
  }

  @override
  String get pulseLastSignalLabel => 'Последний сигнал';

  @override
  String get pulseIncidents => 'Инциденты';

  @override
  String get pulseNoIncidents => 'Инцидентов нет';

  @override
  String get pulseAck => 'Взять в работу';

  @override
  String get pulseIncidentOpen => 'открыт';

  @override
  String get pulseIncidentResolved => 'закрыт';

  @override
  String get pulseIncidentAcked => 'в работе';

  @override
  String get pulsePause => 'Пауза';

  @override
  String get pulseResume => 'Возобновить';

  @override
  String get pulseRotateToken => 'Пересоздать токен';

  @override
  String get pulseDelete => 'Удалить';

  @override
  String get pulseDeleteMonitorConfirmTitle => 'Удалить монитор?';

  @override
  String get pulseDeleteMonitorConfirmBody =>
      'Монитор и его beat-токен перестанут работать, история будет удалена.';

  @override
  String get pulseDeleteFolderConfirmTitle => 'Удалить папку?';

  @override
  String get pulseDeleteFolderConfirmBody =>
      'Удалить можно только пустую папку.';

  @override
  String get pulseFolderNotEmpty => 'Папка не пуста';

  @override
  String get pulseBeatUrlLabel => 'URL для сигналов';

  @override
  String get pulseBeatUrlOnce =>
      'Скопируйте сейчас — токен показывается только один раз.';

  @override
  String get pulseCurlHint => 'Готовый сниппет:';

  @override
  String get pulseCopy => 'Копировать';

  @override
  String get pulseCopied => 'Скопировано';

  @override
  String get pulseAlerts => 'Алерты';

  @override
  String get pulseAddRule => 'Добавить правило';

  @override
  String get pulseNoRules => 'Правил оповещения нет';

  @override
  String get pulseRoomLabel => 'Комната';

  @override
  String get pulsePickRoom => 'Выберите комнату';

  @override
  String get pulseMinSeverityLabel => 'Минимальная важность';

  @override
  String get pulseSeverityWarn => 'Предупреждение';

  @override
  String get pulseSeverityError => 'Ошибка';

  @override
  String get pulseSeverityDown => 'Нет связи';

  @override
  String get pulseEscalateAfterLabel => 'Эскалация через (мин)';

  @override
  String get pulseLevel1Label => 'Ответственные (MUID)';

  @override
  String get pulseLevel1Helper =>
      'ID пользователей мессенджера через запятую — им уйдёт личка при эскалации.';

  @override
  String pulseRuleSummary(String severity, String room) {
    return '≥ $severity → комната $room';
  }

  @override
  String get pulseDeleteRule => 'Удалить правило';

  @override
  String get contactTitle => 'Контакт';

  @override
  String get contactCustomNameLabel => 'Своё имя';

  @override
  String get contactCustomNameHelper =>
      'Видите только вы — в списке чатов и участниках';

  @override
  String get contactNoteLabel => 'Заметка';

  @override
  String get contactNoteHelper => 'Приватная заметка о контакте';

  @override
  String get contactSave => 'Сохранить';

  @override
  String get contactSaved => 'Сохранено';

  @override
  String get contactSaveFailed => 'Не удалось сохранить';

  @override
  String get contactLabelsTitle => 'Метки';

  @override
  String get contactNewLabel => 'Новая метка';

  @override
  String get contactNewLabelHint => 'Например: офис, Москва…';

  @override
  String get contactCreate => 'Создать';

  @override
  String get contactCreateLabelFailed => 'Не удалось создать метку';

  @override
  String contactRenameLabelMenu(Object name) {
    return 'Переименовать «$name»';
  }

  @override
  String get contactRenameLabelTitle => 'Переименовать метку';

  @override
  String get contactDeleteLabel => 'Удалить метку';

  @override
  String contactDeleteLabelConfirm(Object name) {
    return 'Удалить метку «$name»?';
  }

  @override
  String get contactDeleteLabelBody => 'Метка будет снята со всех контактов.';

  @override
  String get contactDelete => 'Удалить';

  @override
  String get contactRenameFailed => 'Не удалось переименовать';

  @override
  String get contactDeleteLabelFailed => 'Не удалось удалить метку';

  @override
  String get contactLoadFailed => 'Не удалось загрузить контакт';

  @override
  String get contactBlock => 'Заблокировать';

  @override
  String get contactUnblock => 'Разблокировать';

  @override
  String get contactBlocked => 'Заблокирован';

  @override
  String contactBlockConfirm(Object name) {
    return 'Заблокировать «$name»?';
  }

  @override
  String get contactBlockBody =>
      'Он не сможет вам писать, взаимные уведомления отключатся. Это можно отменить.';

  @override
  String get contactBlockFailed => 'Не удалось заблокировать';

  @override
  String get contactUnblockFailed => 'Не удалось разблокировать';

  @override
  String get contactUnblocked => 'Разблокирован';

  @override
  String get contactAddedToContacts => 'Добавлен в контакты';

  @override
  String get contactRequestOfferTitle => 'Написать напрямую нельзя';

  @override
  String contactRequestOfferBody(Object name) {
    return '«$name» ограничил, кто может ему писать. Отправьте заявку со своей визиткой — решение за ним.';
  }

  @override
  String get contactRequestSend => 'Отправить заявку';

  @override
  String get contactRequestSent => 'Заявка отправлена';

  @override
  String get contactRequestSendFailed => 'Не удалось отправить заявку';

  @override
  String get contactRequestCooldown =>
      'Вы недавно отправляли заявку — попробуйте позже';

  @override
  String get requestsTitle => 'Заявки в личку';

  @override
  String get requestsEmpty => 'Заявок нет';

  @override
  String get requestsEmptyHint =>
      'Когда кто-то не из ваших контактов захочет вам написать, его заявка появится здесь.';

  @override
  String get requestsLoadFailed => 'Не удалось загрузить заявки';

  @override
  String get requestWantsToConnect => 'хочет связаться';

  @override
  String get requestAccept => 'Принять';

  @override
  String get requestDecline => 'Отклонить';

  @override
  String get requestDeclined => 'Заявка отклонена';

  @override
  String get requestActionFailed => 'Не удалось выполнить';

  @override
  String get contactSaveToContacts => 'Сохранить в контакты';

  @override
  String get contactShareMyCard => 'Поделиться визиткой';

  @override
  String get contactShareCardFailed => 'Не удалось поделиться визиткой';

  @override
  String get chatIntroConnected => 'Вы теперь на связи — поздоровайтесь 👋';

  @override
  String get peopleTitle => 'Люди';

  @override
  String get peopleAll => 'Все';

  @override
  String get peopleEmpty => 'Пока нет контактов';

  @override
  String get peopleEmptyLabel =>
      'С этой меткой пока никого — назначайте метки из профиля контакта';

  @override
  String get peopleLoadFailed => 'Не удалось загрузить';

  @override
  String folderPickerTitle(Object name) {
    return 'Папки для «$name»';
  }

  @override
  String get folderPickerEmpty =>
      'Папок пока нет — создайте первую, и чат сразу попадёт в неё. Один чат может быть в нескольких папках.';

  @override
  String get folderNewRow => 'Новая папка…';

  @override
  String get folderNewTitle => 'Новая папка';

  @override
  String get folderNameHint => 'Название папки';

  @override
  String get folderCreateFailed => 'Не удалось создать папку';

  @override
  String folderRenameMenu(Object name) {
    return 'Переименовать «$name»';
  }

  @override
  String get folderRenameTitle => 'Переименовать папку';

  @override
  String get folderDelete => 'Удалить папку';

  @override
  String folderDeleteConfirm(Object name) {
    return 'Удалить папку «$name»?';
  }

  @override
  String get folderDeleteBody => 'Чаты останутся — удалится только папка.';

  @override
  String get folderChangeFailed => 'Не удалось изменить папку';

  @override
  String get folderDeleteFailed => 'Не удалось удалить папку';

  @override
  String get peopleSearchHint => 'Поиск по имени или @нику';

  @override
  String peopleCount(Object count) {
    return 'Контакты · $count';
  }

  @override
  String get peopleNotFound => 'Ничего не найдено';

  @override
  String get peopleWrite => 'Написать';

  @override
  String get peopleProfile => 'Профиль контакта';

  @override
  String folderChatCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count чатов',
      few: '$count чата',
      one: '$count чат',
      zero: 'пусто',
    );
    return '$_temp0';
  }

  @override
  String get folderDone => 'Готово';

  @override
  String folderDoneN(Object count) {
    return 'Готово · $count';
  }

  @override
  String get folderOk => 'ОК';

  @override
  String get folderPickerHeader => 'Добавить в папку';

  @override
  String get lastSeenJustNow => 'был(а) в сети только что';

  @override
  String lastSeenMinutes(Object count) {
    return 'был(а) в сети $count мин назад';
  }

  @override
  String lastSeenToday(Object time) {
    return 'был(а) в сети сегодня в $time';
  }

  @override
  String lastSeenYesterday(Object time) {
    return 'был(а) в сети вчера в $time';
  }

  @override
  String lastSeenDate(Object date) {
    return 'был(а) в сети $date';
  }

  @override
  String get lastSeenOnline => 'в сети';

  @override
  String get cardEditorTitle => 'Моя визитка';

  @override
  String get cardSectionStyle => 'Стиль';

  @override
  String get cardSectionFields => 'О себе';

  @override
  String get cardTemplatePhoto => 'Фото';

  @override
  String get cardTemplateGradient => 'Градиент';

  @override
  String get cardTemplateMonogram => 'Монограмма';

  @override
  String get cardFontClassic => 'Классика';

  @override
  String get cardFontBold => 'Жирный';

  @override
  String get cardFontAiry => 'Воздушный';

  @override
  String get cardFontMono => 'Моно';

  @override
  String get cardColorAuto => 'Авто';

  @override
  String get cardPickPhoto => 'Выбрать фото';

  @override
  String get cardPhotoUploadFailed => 'Не удалось загрузить фото';

  @override
  String get cardAboutLabel => 'О себе';

  @override
  String get cardJobTitleLabel => 'Должность';

  @override
  String get cardCompanyLabel => 'Компания';

  @override
  String get cardPhoneLabel => 'Телефон';

  @override
  String get cardEmailLabel => 'Email';

  @override
  String get cardWebsiteLabel => 'Сайт';

  @override
  String get cardVisibilityEveryone => 'Видно всем';

  @override
  String get cardVisibilityContacts => 'Только контактам';

  @override
  String get cardVisibilityHint =>
      'Замок у поля — его увидят только ваши контакты (люди, с которыми есть общий чат)';

  @override
  String get cardSaved => 'Визитка сохранена';

  @override
  String get cardSaveFailed => 'Не удалось сохранить визитку';

  @override
  String get cardDelete => 'Удалить визитку';

  @override
  String get cardDeleteConfirmTitle => 'Удалить визитку?';

  @override
  String get cardDeleteConfirmBody =>
      'Оформление и поля «о себе» будут удалены. Это действие нельзя отменить.';

  @override
  String get cardHiddenFieldsNote => 'Полная визитка видна контактам';

  @override
  String get settingsWhoCanMessageTitle => 'Писать могут только контакты';

  @override
  String get settingsWhoCanMessageSubtitle =>
      'Новый чат со мной могут начать только люди, с которыми уже есть общий чат';

  @override
  String get settingsShowCardsOnCallTitle => 'Визитки на звонке';

  @override
  String get settingsShowCardsOnCallSubtitle =>
      'Показывать визитку звонящего на весь экран входящего звонка';

  @override
  String get settingsPresenceVisibleTitle => 'Показывать, когда я в сети';

  @override
  String get settingsPresenceVisibleSubtitle =>
      '«В сети» и «был(а) в сети…» видны собеседникам. Если выключить — вы тоже не будете видеть чужой статус';

  @override
  String peopleSelectedCount(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get peopleAssignLabelAction => 'Метка';

  @override
  String peopleBatchLabelTitle(int count) {
    return 'Назначить метку · $count';
  }

  @override
  String get profileLangBase => 'Основной';

  @override
  String get profileLangAdd => '+ Язык';

  @override
  String get profileLangAddTitle => 'Добавить язык профиля';

  @override
  String profileLangHelper(String locale) {
    return 'Эти поля увидят пользователи с языком $locale. Пустые поля возьмутся из английской или основной версии.';
  }

  @override
  String profileLangSaved(String locale) {
    return 'Версия $locale сохранена';
  }

  @override
  String get roomCustomNameAction => 'Своё название чата';

  @override
  String get roomCustomNameHint =>
      'Видно только вам — другие участники видят обычное название';

  @override
  String get roomCustomNameReset => 'Сбросить';

  @override
  String get roomAdminWriteBanAction => 'Запретить писать';

  @override
  String get roomAdminWriteUnbanAction => 'Разрешить писать';

  @override
  String get roomAdminWriteBanDurationTitle => 'Запретить писать на…';

  @override
  String get roomAdminWriteBanHour => '1 час';

  @override
  String get roomAdminWriteBanDay => '1 день';

  @override
  String get roomAdminWriteBanWeek => '7 дней';

  @override
  String get roomAdminWriteBanForever => 'Навсегда';

  @override
  String roomAdminWriteBannedUntil(String until) {
    return 'Запрещено до $until';
  }

  @override
  String get writeBannedForeverSnack =>
      'Администратор запретил вам писать в этот чат';

  @override
  String writeBannedUntilSnack(String until) {
    return 'Вам запрещено писать в этот чат до $until';
  }

  @override
  String threadOpenDiscussion(int count) {
    return 'Обсуждение ($count)';
  }

  @override
  String get threadScreenTitle => 'Обсуждение задачи';

  @override
  String get threadScreenEmpty =>
      'Ответов пока нет. Задайте здесь вопрос по задаче.';

  @override
  String taskBadgeTooltip(String status) {
    return 'Задача: $status';
  }

  @override
  String get taskStageCreated => 'Заведена';

  @override
  String get taskStageNew => 'Новая';

  @override
  String get taskStageInProgress => 'В работе';

  @override
  String get taskStageAccepted => 'Принята';

  @override
  String get taskStageRejected => 'Отклонена';
}
