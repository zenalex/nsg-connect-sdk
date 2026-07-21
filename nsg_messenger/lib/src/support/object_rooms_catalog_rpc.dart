import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// **TASK45 фаза 1 п.5**: RPC-абстракция каталога объектовых комнат
/// продукта. Отдельный интерфейс (а не прямой вызов client) — чтобы
/// `ObjectRoomsCatalogController` был unit-тестируем с hand-written fake
/// (как `SupportTeamRpc`).
abstract class ObjectRoomsCatalogRpc {
  /// Каталог объектовых комнат продукта. Бросает
  /// [NotSupportTeamMemberException], если caller не член команды (SDK по
  /// этому гейтит экран).
  Future<List<ProductObjectRoom>> listProductObjectRooms({
    required String productExternalKey,
  });

  /// Войти в объектовую комнату (член команды). Возвращает [RoomDetails].
  Future<RoomDetails> joinProductRoom({required int roomId});

  /// Выйти из объектовой комнаты (когда вопрос решён).
  Future<void> leaveProductRoom({required int roomId});
}

/// Продакшн-реализация: ходит в generated Serverpod-client через
/// `withAuthRetry` (self-heal на token-rotation, как в остальном SDK).
class ClientObjectRoomsCatalogRpc implements ObjectRoomsCatalogRpc {
  ClientObjectRoomsCatalogRpc(this._client);

  final Client _client;

  MessengerSessionManager get _session =>
      MessengerRuntime.instance.sessionManager;

  @override
  Future<List<ProductObjectRoom>> listProductObjectRooms({
    required String productExternalKey,
  }) => withAuthRetry(
    () => _client.messenger.listProductObjectRooms(
      productExternalKey: productExternalKey,
    ),
    _session,
  );

  @override
  Future<RoomDetails> joinProductRoom({required int roomId}) => withAuthRetry(
    () => _client.messenger.joinProductRoom(roomId: roomId),
    _session,
  );

  @override
  Future<void> leaveProductRoom({required int roomId}) => withAuthRetry(
    () => _client.messenger.leaveProductRoom(roomId: roomId),
    _session,
  );
}
