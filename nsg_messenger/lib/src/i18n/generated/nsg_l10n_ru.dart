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
  String get attachActionSheetTitle => 'Прикрепить';

  @override
  String get attachActionCamera => 'Камера';

  @override
  String get attachActionGallery => 'Галерея';

  @override
  String get attachUploadFailed => 'Не удалось загрузить — попробуйте ещё раз';

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
  String composerReplyingTo(String name) {
    return 'Ответ $name';
  }

  @override
  String get composerCancelReply => 'Отменить ответ';

  @override
  String get composerEditing => 'Редактирование';

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
}
