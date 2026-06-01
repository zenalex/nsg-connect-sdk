/// Жизненный цикл `MessengerSession` в SDK. SDK эмитит переходы через
/// `NsgMessenger.sessionStateStream()` — host-app может показать
/// "соединение восстанавливается", "session истекла" и т.п. (см. ТЗ
/// §15 / TASK12).
enum MessengerSessionState {
  /// `init()` ещё не вызван либо `dispose()` уже сработал.
  uninitialised,

  /// Сессия активна: serverToken есть и не истёк.
  active,

  /// Идёт refresh — новый serverToken запрашивается.
  refreshing,

  /// 401 от сервера, refresh-цикл не помог. Host-app должен либо
  /// `reauthenticate()`, либо обновить customer accessToken и вызвать
  /// `init` заново.
  expired,

  /// Какая-то иная ошибка (сеть, server 5xx). Подробности — в логах /
  /// ErrorReporter.
  error,
}
