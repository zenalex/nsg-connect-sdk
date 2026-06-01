import 'dart:async';

import 'package:nsg_connect_client/nsg_connect_client.dart';

/// Тип callback-а, который [MessengerAuthKeyProvider] зовёт при
/// `refreshAuthKey(force:)` — это перенаправляется в
/// [MessengerSessionManager.refresh]. Через тип-callback избегаем
/// циклической зависимости между provider-ом и manager-ом.
typedef MessengerForceRefresh =
    Future<RefreshAuthKeyResult> Function({bool force});

/// `ClientAuthKeyProvider` для Serverpod Client-а. Возвращает текущий
/// `sessionToken`, обёрнутый как `Bearer <token>`. На 401-retry от
/// Serverpod-а (либо проактивно из таймера) дёргает [_forceRefresh],
/// который рулит [MessengerSessionManager].
///
/// Декорировать обёрткой [MutexRefresherClientAuthKeyProvider] из
/// `serverpod_client` ОБЯЗАТЕЛЬНО — иначе concurrent RPC могут вызвать
/// несколько параллельных refresh-ей. См.
/// [MessengerSessionManager._buildAuthProvider].
class MessengerAuthKeyProvider implements RefresherClientAuthKeyProvider {
  String? _token;
  final MessengerForceRefresh _forceRefresh;

  MessengerAuthKeyProvider({required MessengerForceRefresh onForceRefresh})
    : _forceRefresh = onForceRefresh;

  /// Вызывается [MessengerSessionManager] после каждого успешного
  /// `session()` / `refresh()`.
  void setToken(String? token) {
    _token = token;
  }

  @override
  Future<String?> get authHeaderValue async {
    final t = _token;
    if (t == null) return null;
    return wrapAsBearerAuthHeaderValue(t);
  }

  @override
  Future<RefreshAuthKeyResult> refreshAuthKey({bool force = false}) =>
      _forceRefresh(force: force);
}
