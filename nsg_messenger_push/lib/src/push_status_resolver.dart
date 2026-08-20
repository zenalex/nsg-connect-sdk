import 'package:nsg_messenger/nsg_messenger.dart';

/// **Issue #86**: перевод «что удалось получить от платформы» в «почему
/// уведомление не придёт». Общее для всех провайдеров (FCM, RuStore) —
/// иначе каждый молчал бы по-своему.
///
/// Порядок проверок не косметический: разрешение проверяется ПЕРВЫМ.
/// Совет не по адресу хуже молчания — предлагать «разрешите уведомления»
/// тому, кто их уже разрешил (а токен не пришёл из-за заблокированного
/// порта 5223), значит отправить человека по кругу.
///
/// Обратите внимание на комбинацию «разрешения нет, но токен есть»: так
/// живёт Android 13+ с отклонённым POST_NOTIFICATIONS — FCM-токен
/// выдаётся, регистрация на сервере валидна, а уведомления система всё
/// равно не покажет. Пользователю важен именно этот факт, поэтому
/// отсутствие разрешения перевешивает наличие токена.
PushTokenStatus resolvePushTokenStatus({
  required bool permissionGranted,
  required String? token,
}) {
  if (!permissionGranted) return PushTokenStatus.permissionDenied;
  if (token == null || token.isEmpty) return PushTokenStatus.tokenUnavailable;
  return PushTokenStatus.ready;
}
