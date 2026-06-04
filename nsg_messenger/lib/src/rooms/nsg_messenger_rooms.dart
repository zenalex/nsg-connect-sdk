import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../runtime/messenger_event_bus.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// Один TTL для list+get — упрощает мental model. TTL это **fallback**
/// для случая, когда realtime не сработал; основной invalidation —
/// через `messageCreated` event из [MessengerEventBus]. Расширение
/// (например, длинный TTL для details после TASK17 membershipChanged
/// event) — отдельной задачей.
@visibleForTesting
const Duration kRoomsCacheTtl = Duration(seconds: 30);

/// Hard-cap для LRU-кэша [RoomDetails]. В long-running session юзер
/// может открыть много чатов; map без eviction вырастает без предела.
/// 50 — компромисс между memory footprint и hit-rate (типичный юзер
/// активно работает с 5–15 чатами).
@visibleForTesting
const int kRoomDetailsLruCapacity = 50;

/// Sentinel значение «mute навсегда» для [NsgMessengerRooms.muteRoom].
///
/// **Single source of truth — server: `RoomService.kMuteForever`**
/// (`server/.../lib/src/business/room_service.dart`). Здесь хардкод
/// даёт SDK consistent UI («Mute forever» button) без дополнительного
/// `getMuteForeverSentinel()` RPC. При изменении на server-side —
/// синхронизировать с этой константой.
final DateTime kMuteForever = DateTime.utc(9999, 1, 1);

/// Сигнатуры RPC — для тестов через инъекцию (тот же pattern что
/// `MessengerSessionManager.attachWithRpcs`).
// Сигнатуры подобраны 1:1 с Serverpod-сгенерированным client-ом
// (`client.messenger.X`). Serverpod помечает все named params как
// required даже если у Dart-овской версии есть default — клиент
// не видит default-ы. Если расходиться — рантайм-несовместимость.
typedef ListRoomsRpc =
    Future<List<RoomSummary>> Function({
      int? productId,
      RoomState? state,
      String? search,
      bool? includeArchived,
      required int limit,
      String? cursor,
    });
typedef GetRoomRpc = Future<RoomDetails> Function({required int roomId});
typedef CreateDirectRpc =
    Future<RoomDetails> Function({required int peerMessengerUserId});
typedef CreateGroupRpc =
    Future<RoomDetails> Function({
      required String name,
      required List<int> memberMessengerUserIds,
      int? productId,
    });
typedef GetOrCreateProductRoomRpc =
    Future<RoomDetails> Function({
      required String productExternalKey,
      required String entityType,
      required String entityId,
      required RoomType roomType,
    });
typedef OpenSupportChatRpc =
    Future<RoomDetails> Function({
      required String productExternalKey,
      required String contextId,
    });
typedef MuteRoomRpc =
    Future<void> Function({
      required int roomId,
      DateTime? mutedUntil,
      int? muteForSeconds,
    });
typedef UnmuteRoomRpc = Future<void> Function({required int roomId});
typedef ArchiveRoomRpc = Future<void> Function({required int roomId});
typedef UnarchiveRoomRpc = Future<void> Function({required int roomId});
typedef LeaveRoomRpc = Future<void> Function({required int roomId});
typedef GetAvailableProductsRpc = Future<List<Product>> Function();

/// TASK29 Chunk 2: admin/moderation RPC typedefs.
typedef KickUserRpc =
    Future<void> Function({
      required int roomId,
      required int targetMessengerUserId,
      String? reason,
    });
typedef BanUserRpc =
    Future<void> Function({
      required int roomId,
      required int targetMessengerUserId,
      String? reason,
    });
typedef UnbanUserRpc =
    Future<void> Function({
      required int roomId,
      required int targetMessengerUserId,
    });
typedef SetRoomMemberRoleRpc =
    Future<void> Function({
      required int roomId,
      required int targetMessengerUserId,
      required RoomMemberRole newRole,
    });
typedef ListBannedUsersRpc =
    Future<List<RoomParticipant>> Function({required int roomId});

/// **Chat-create flow**: lookup messenger user by exact email match
/// (case-insensitive). Throws [PeerUnavailableException] if not found.
typedef FindUserByEmailRpc =
    Future<RoomParticipant> Function({
      required String email,
      String tenantExternalKey,
    });

/// **Chat-create flow (extended)**: search users by email OR nickname.
/// Returns up to [limit] matches; empty list if query < 2 chars.
typedef SearchUsersRpc =
    Future<List<RoomParticipant>> Function({
      required String query,
      int limit,
      String tenantExternalKey,
    });

/// **Add user to chat**: invite an existing messenger user to an
/// existing room. Caller must be member of room; target must be in
/// same tenant. Idempotent — if target already member, no-op.
typedef InviteToRoomRpc =
    Future<void> Function({
      required int roomId,
      required int targetMessengerUserId,
    });

/// **B15 rename room**: caller-admin переименовывает group-чат.
/// Direct chats reject-аются (semantic). Validation на сервере:
/// trim non-empty + length ≤ 100.
typedef RenameRoomRpc =
    Future<void> Function({required int roomId, required String newName});

/// **Atomic dissolveRoom**: owner распускает group-комнату одним RPC —
/// сервер kick-ает всех peer-ов и leave-ит сам. При partial failure
/// бросает `RoomDissolvePartialException(kicked, total, cause)`.
/// Direct chats отклоняются (`ArgumentError`).
typedef DissolveRoomRpc = Future<void> Function({required int roomId});

/// **Known contacts**: participants всех моих комнат, distinct,
/// без self / ghosts. UI default-список в picker-ах (create group,
/// add member) ДО любого ввода в поиск.
typedef ListKnownContactsRpc = Future<List<RoomParticipant>> Function();

/// **B16-ext (group avatar)**: загрузка/смена аватара group/team/
/// productRoom. Принимает image bytes + MIME, возвращает mxcUrl.
/// Direct chats отклоняются.
typedef SetRoomAvatarRpc = Future<String> Function({
  required int roomId,
  required ByteData bytes,
  required String mimeType,
});

/// Public API для работы с комнатами из host-app. Доступен через
/// `NsgMessenger.rooms`. Под капотом:
///   * proxy-вызовы Serverpod RPC через `client.messenger.X`;
///   * in-memory cache `list()` (single-entry, key — params) и
///     `get(id)` (LRU 50);
///   * invalidation через [MessengerEventBus] (`messageCreated` →
///     инвалидация list cache + update preview/order у details);
///   * `create*` populate `_detailsCache` результатом RPC, `list`
///     cache invalidates (порядок и preview меняются).
///
/// **Cache invalidation таблица** (актуально на TASK13 Chunk 2):
///
/// | Event                                          | Invalidate                          |
/// |------------------------------------------------|-------------------------------------|
/// | `MessengerEvent.messageCreated(roomId=X)`      | list (preview/order меняется), details[X] |
/// | `MessengerSessionState.expired/error`          | clear all                           |
/// | `create*` RPC return                           | list invalidate, details[X] populate|
///
/// Расширения для TASK17 (когда MessengerEvent добавит новые типы):
///   * `roomCreated` → list invalidate;
///   * `membershipChanged(X)` → details[X];
///   * `roomStateChanged(X)` → list + details[X].
class NsgMessengerRooms {
  final ListRoomsRpc _listRpc;
  final GetRoomRpc _getRpc;
  final CreateDirectRpc _createDirectRpc;
  final CreateGroupRpc _createGroupRpc;
  final GetOrCreateProductRoomRpc _getOrCreateProductRoomRpc;
  final OpenSupportChatRpc _openSupportChatRpc;
  final MuteRoomRpc _muteRoomRpc;
  final UnmuteRoomRpc _unmuteRoomRpc;
  final ArchiveRoomRpc _archiveRoomRpc;
  final UnarchiveRoomRpc _unarchiveRoomRpc;
  final LeaveRoomRpc _leaveRoomRpc;
  final GetAvailableProductsRpc _getAvailableProductsRpc;
  // TASK29 Chunk 2: admin RPCs.
  final KickUserRpc _kickUserRpc;
  final BanUserRpc _banUserRpc;
  final UnbanUserRpc _unbanUserRpc;
  final SetRoomMemberRoleRpc _setRoomMemberRoleRpc;
  final ListBannedUsersRpc _listBannedUsersRpc;
  // Chat-create flow (find user by email + invite to existing room).
  final FindUserByEmailRpc _findUserByEmailRpc;
  final SearchUsersRpc _searchUsersRpc;
  final InviteToRoomRpc _inviteToRoomRpc;
  final RenameRoomRpc _renameRoomRpc;
  final DissolveRoomRpc _dissolveRoomRpc;
  final ListKnownContactsRpc _listKnownContactsRpc;
  final SetRoomAvatarRpc _setRoomAvatarRpc;
  final MessengerEventBus _eventBus;

  StreamSubscription<MessengerEvent>? _eventsSub;

  /// Single-entry cache для `list()`. Кэшируется последний результат
  /// с ключом-сериализацией параметров. Если параметры меняются —
  /// cache miss и обновление. Большинство host-app вызывают с одинаковыми
  /// (один продукт, один limit), поэтому single-entry достаточно.
  _ListCacheEntry? _listEntry;

  /// LRU-кэш `get(roomId)`. `LinkedHashMap` сохраняет порядок вставки;
  /// move-to-end pattern: при чтении — `remove` + `[]=` чтобы пометить
  /// recently-used. При превышении [kRoomDetailsLruCapacity] —
  /// удаляем head (least recently used).
  final LinkedHashMap<int, _DetailsCacheEntry> _detailsCache = LinkedHashMap();

  /// **B9 typing per-room map** — `roomId → matrixUserIds set`.
  /// Обновляется на каждый `typingChanged` event (FULL override,
  /// Matrix-конвенция). Пусто или `null` → никто не печатает.
  ///
  /// Используется chats-list UI (chatista `GlassChatRow` / SDK
  /// `RoomSummaryTile`) — заменяет preview `lastMessageBody` на
  /// «X печатает…» когда `typingByRoom[roomId]?.isNotEmpty == true`.
  ///
  /// На уровне chat-screen используется собственный `_typingPeers`
  /// в [MessagesController] — отдельная подписка на тот же bus event.
  final Map<int, Set<String>> _typingByRoom = <int, Set<String>>{};

  /// Параллельный к [_typingByRoom] список display-name-ов peer-ов
  /// (server резолвит при emit-е, fallback на matrix localpart).
  /// Используется UI чтобы показать «zenkov печатает…» вместо
  /// matrix-id вида `nsg-nsg-oe6bsvh2hwbix7vy`.
  final Map<int, List<String>> _typingNamesByRoom = <int, List<String>>{};

  final ValueNotifier<int> _typingVersion = ValueNotifier(0);

  /// ValueListenable инкрементируется на каждом изменении
  /// [typingMatrixUserIdsFor] / [typingDisplayNamesFor]. Подписчик
  /// может через listener триггернуть rebuild списка комнат.
  ValueListenable<int> get typingListenable => _typingVersion;

  /// Snapshot matrix-id-ов текущих печатающих. Empty/`null` → footer
  /// hidden.
  Set<String> typingMatrixUserIdsFor(int roomId) =>
      _typingByRoom[roomId] ?? const <String>{};

  /// Snapshot отображаемых имён печатающих (server-resolved). Длина
  /// списка равна `typingMatrixUserIdsFor(roomId).length`. UI обычно
  /// использует эти строки прямо для рендера.
  List<String> typingDisplayNamesFor(int roomId) =>
      _typingNamesByRoom[roomId] ?? const <String>[];

  NsgMessengerRooms._({
    required ListRoomsRpc listRpc,
    required GetRoomRpc getRpc,
    required CreateDirectRpc createDirectRpc,
    required CreateGroupRpc createGroupRpc,
    required GetOrCreateProductRoomRpc getOrCreateProductRoomRpc,
    required OpenSupportChatRpc openSupportChatRpc,
    required MuteRoomRpc muteRoomRpc,
    required UnmuteRoomRpc unmuteRoomRpc,
    required ArchiveRoomRpc archiveRoomRpc,
    required UnarchiveRoomRpc unarchiveRoomRpc,
    required LeaveRoomRpc leaveRoomRpc,
    required GetAvailableProductsRpc getAvailableProductsRpc,
    required KickUserRpc kickUserRpc,
    required BanUserRpc banUserRpc,
    required UnbanUserRpc unbanUserRpc,
    required SetRoomMemberRoleRpc setRoomMemberRoleRpc,
    required ListBannedUsersRpc listBannedUsersRpc,
    required FindUserByEmailRpc findUserByEmailRpc,
    required SearchUsersRpc searchUsersRpc,
    required InviteToRoomRpc inviteToRoomRpc,
    required RenameRoomRpc renameRoomRpc,
    required DissolveRoomRpc dissolveRoomRpc,
    required ListKnownContactsRpc listKnownContactsRpc,
    required SetRoomAvatarRpc setRoomAvatarRpc,
    required MessengerEventBus eventBus,
  }) : _listRpc = listRpc,
       _getRpc = getRpc,
       _createDirectRpc = createDirectRpc,
       _createGroupRpc = createGroupRpc,
       _getOrCreateProductRoomRpc = getOrCreateProductRoomRpc,
       _openSupportChatRpc = openSupportChatRpc,
       _muteRoomRpc = muteRoomRpc,
       _unmuteRoomRpc = unmuteRoomRpc,
       _archiveRoomRpc = archiveRoomRpc,
       _unarchiveRoomRpc = unarchiveRoomRpc,
       _leaveRoomRpc = leaveRoomRpc,
       _getAvailableProductsRpc = getAvailableProductsRpc,
       _kickUserRpc = kickUserRpc,
       _banUserRpc = banUserRpc,
       _unbanUserRpc = unbanUserRpc,
       _setRoomMemberRoleRpc = setRoomMemberRoleRpc,
       _listBannedUsersRpc = listBannedUsersRpc,
       _findUserByEmailRpc = findUserByEmailRpc,
       _searchUsersRpc = searchUsersRpc,
       _inviteToRoomRpc = inviteToRoomRpc,
       _renameRoomRpc = renameRoomRpc,
       _dissolveRoomRpc = dissolveRoomRpc,
       _listKnownContactsRpc = listKnownContactsRpc,
       _setRoomAvatarRpc = setRoomAvatarRpc,
       _eventBus = eventBus;

  /// Production-фабрика. Привязывается к `client.messenger.*` методам.
  ///
  /// **TASK20 followup (α)**: каждый RPC оборачивается в [withAuthRetry]
  /// для self-heal на типизированную auth-invalidation
  /// ([MessengerNotAuthenticatedException] / [InvalidTokenException] на
  /// 200-ответе сервера, который Serverpod 401-retry pipeline НЕ
  /// перехватывает). [MessengerSessionManager] резолвится лениво через
  /// [MessengerRuntime.instance.sessionManager] — closures выполняются
  /// после init(), к этому моменту runtime гарантированно поднят. Test-
  /// factory [attachWithRpcs] инжектит свои closures напрямую (без
  /// withAuthRetry) — так тесты не зависят от runtime singleton-а.
  static NsgMessengerRooms attach({
    required Client client,
    required MessengerEventBus eventBus,
  }) {
    MessengerSessionManager session() =>
        MessengerRuntime.instance.sessionManager;
    return attachWithRpcs(
      listRpc:
          ({
            int? productId,
            RoomState? state,
            String? search,
            bool? includeArchived,
            required int limit,
            String? cursor,
          }) => withAuthRetry(
            () => client.messenger.listRooms(
              productId: productId,
              state: state,
              search: search,
              includeArchived: includeArchived,
              limit: limit,
              cursor: cursor,
            ),
            session(),
          ),
      getRpc: ({required int roomId}) => withAuthRetry(
        () => client.messenger.getRoom(roomId: roomId),
        session(),
      ),
      createDirectRpc: ({required int peerMessengerUserId}) => withAuthRetry(
        () => client.messenger.createDirect(
          peerMessengerUserId: peerMessengerUserId,
        ),
        session(),
      ),
      createGroupRpc:
          ({
            required String name,
            required List<int> memberMessengerUserIds,
            int? productId,
          }) => withAuthRetry(
            () => client.messenger.createGroup(
              name: name,
              memberMessengerUserIds: memberMessengerUserIds,
              productId: productId,
            ),
            session(),
          ),
      getOrCreateProductRoomRpc:
          ({
            required String productExternalKey,
            required String entityType,
            required String entityId,
            required RoomType roomType,
          }) => withAuthRetry(
            () => client.messenger.getOrCreateProductRoom(
              productExternalKey: productExternalKey,
              entityType: entityType,
              entityId: entityId,
              roomType: roomType,
            ),
            session(),
          ),
      openSupportChatRpc:
          ({required String productExternalKey, required String contextId}) =>
              withAuthRetry(
                () => client.messenger.openSupportChat(
                  productExternalKey: productExternalKey,
                  contextId: contextId,
                ),
                session(),
              ),
      muteRoomRpc:
          ({
            required int roomId,
            DateTime? mutedUntil,
            int? muteForSeconds,
          }) => withAuthRetry(
            () => client.messenger.muteRoom(
              roomId: roomId,
              mutedUntil: mutedUntil,
              muteForSeconds: muteForSeconds,
            ),
            session(),
          ),
      unmuteRoomRpc: ({required int roomId}) => withAuthRetry(
        () => client.messenger.unmuteRoom(roomId: roomId),
        session(),
      ),
      archiveRoomRpc: ({required int roomId}) => withAuthRetry(
        () => client.messenger.archiveRoom(roomId: roomId),
        session(),
      ),
      unarchiveRoomRpc: ({required int roomId}) => withAuthRetry(
        () => client.messenger.unarchiveRoom(roomId: roomId),
        session(),
      ),
      leaveRoomRpc: ({required int roomId}) => withAuthRetry(
        () => client.messenger.leaveRoom(roomId: roomId),
        session(),
      ),
      // NOTE: getAvailableProducts НЕ оборачивается — это lightweight
      // dropdown fetch, server-side вызывается под обычным auth-handler-
      // ом, Serverpod 401-retry уже его покрывает. Если когда-нибудь
      // обнаружим случай типизированного NotAuth на этот эндпоинт —
      // добавим wrap-ер. Сейчас держим простую функцию.
      getAvailableProductsRpc: client.messenger.getAvailableProducts,
      kickUserRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            String? reason,
          }) => withAuthRetry(
            () => client.messenger.kickUser(
              roomId: roomId,
              targetMessengerUserId: targetMessengerUserId,
              reason: reason,
            ),
            session(),
          ),
      banUserRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            String? reason,
          }) => withAuthRetry(
            () => client.messenger.banUser(
              roomId: roomId,
              targetMessengerUserId: targetMessengerUserId,
              reason: reason,
            ),
            session(),
          ),
      unbanUserRpc:
          ({required int roomId, required int targetMessengerUserId}) =>
              withAuthRetry(
                () => client.messenger.unbanUser(
                  roomId: roomId,
                  targetMessengerUserId: targetMessengerUserId,
                ),
                session(),
              ),
      setRoomMemberRoleRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            required RoomMemberRole newRole,
          }) => withAuthRetry(
            () => client.messenger.setRoomMemberRole(
              roomId: roomId,
              targetMessengerUserId: targetMessengerUserId,
              newRole: newRole,
            ),
            session(),
          ),
      listBannedUsersRpc: ({required int roomId}) => withAuthRetry(
        () => client.messenger.listBannedUsers(roomId: roomId),
        session(),
      ),
      findUserByEmailRpc:
          ({required String email, String tenantExternalKey = 'nsg'}) =>
              withAuthRetry(
                () => client.messenger.findUserByEmail(
                  email: email,
                  tenantExternalKey: tenantExternalKey,
                ),
                session(),
              ),
      searchUsersRpc:
          ({
            required String query,
            int limit = 20,
            String tenantExternalKey = 'nsg',
          }) => withAuthRetry(
            () => client.messenger.searchUsers(
              query: query,
              limit: limit,
              tenantExternalKey: tenantExternalKey,
            ),
            session(),
          ),
      inviteToRoomRpc:
          ({required int roomId, required int targetMessengerUserId}) =>
              withAuthRetry(
                () => client.messenger.inviteToRoom(
                  roomId: roomId,
                  targetMessengerUserId: targetMessengerUserId,
                ),
                session(),
              ),
      renameRoomRpc: ({required int roomId, required String newName}) =>
          withAuthRetry(
            () => client.messenger.renameRoom(
              roomId: roomId,
              newName: newName,
            ),
            session(),
          ),
      dissolveRoomRpc: ({required int roomId}) => withAuthRetry(
        () => client.messenger.dissolveRoom(roomId: roomId),
        session(),
      ),
      listKnownContactsRpc: () => withAuthRetry(
        () => client.messenger.listKnownContacts(),
        session(),
      ),
      setRoomAvatarRpc:
          ({
            required int roomId,
            required ByteData bytes,
            required String mimeType,
          }) => withAuthRetry(
            () => client.messenger.setRoomAvatar(
              roomId: roomId,
              bytes: bytes,
              mimeType: mimeType,
            ),
            session(),
          ),
      eventBus: eventBus,
    );
  }

  /// Test-фабрика. Тесты подменяют RPC и event-bus на in-memory fake-и.
  @visibleForTesting
  static NsgMessengerRooms attachWithRpcs({
    required ListRoomsRpc listRpc,
    required GetRoomRpc getRpc,
    required CreateDirectRpc createDirectRpc,
    required CreateGroupRpc createGroupRpc,
    required GetOrCreateProductRoomRpc getOrCreateProductRoomRpc,
    required OpenSupportChatRpc openSupportChatRpc,
    required MuteRoomRpc muteRoomRpc,
    required UnmuteRoomRpc unmuteRoomRpc,
    required ArchiveRoomRpc archiveRoomRpc,
    required UnarchiveRoomRpc unarchiveRoomRpc,
    required LeaveRoomRpc leaveRoomRpc,
    required GetAvailableProductsRpc getAvailableProductsRpc,
    required KickUserRpc kickUserRpc,
    required BanUserRpc banUserRpc,
    required UnbanUserRpc unbanUserRpc,
    required SetRoomMemberRoleRpc setRoomMemberRoleRpc,
    required ListBannedUsersRpc listBannedUsersRpc,
    FindUserByEmailRpc? findUserByEmailRpc,
    SearchUsersRpc? searchUsersRpc,
    InviteToRoomRpc? inviteToRoomRpc,
    RenameRoomRpc? renameRoomRpc,
    DissolveRoomRpc? dissolveRoomRpc,
    ListKnownContactsRpc? listKnownContactsRpc,
    SetRoomAvatarRpc? setRoomAvatarRpc,
    required MessengerEventBus eventBus,
  }) {
    // Test factories may omit the chat-create RPCs — default to stubs
    // that throw so tests calling those paths fail loudly.
    findUserByEmailRpc ??= ({
      required String email,
      String tenantExternalKey = 'nsg',
    }) async => throw UnimplementedError(
          'findUserByEmailRpc not set in attachWithRpcs',
        );
    searchUsersRpc ??= ({
      required String query,
      int limit = 20,
      String tenantExternalKey = 'nsg',
    }) async => throw UnimplementedError(
          'searchUsersRpc not set in attachWithRpcs',
        );
    inviteToRoomRpc ??= ({
      required int roomId,
      required int targetMessengerUserId,
    }) async => throw UnimplementedError(
          'inviteToRoomRpc not set in attachWithRpcs',
        );
    renameRoomRpc ??=
        ({required int roomId, required String newName}) async =>
            throw UnimplementedError(
              'renameRoomRpc not set in attachWithRpcs',
            );
    dissolveRoomRpc ??= ({required int roomId}) async => throw
        UnimplementedError('dissolveRoomRpc not set in attachWithRpcs');
    listKnownContactsRpc ??=
        () async => const <RoomParticipant>[];
    setRoomAvatarRpc ??= ({
      required int roomId,
      required ByteData bytes,
      required String mimeType,
    }) async =>
        throw UnimplementedError('setRoomAvatarRpc not set in attachWithRpcs');
    final r = NsgMessengerRooms._(
      listRpc: listRpc,
      getRpc: getRpc,
      createDirectRpc: createDirectRpc,
      createGroupRpc: createGroupRpc,
      getOrCreateProductRoomRpc: getOrCreateProductRoomRpc,
      openSupportChatRpc: openSupportChatRpc,
      muteRoomRpc: muteRoomRpc,
      unmuteRoomRpc: unmuteRoomRpc,
      archiveRoomRpc: archiveRoomRpc,
      unarchiveRoomRpc: unarchiveRoomRpc,
      leaveRoomRpc: leaveRoomRpc,
      getAvailableProductsRpc: getAvailableProductsRpc,
      kickUserRpc: kickUserRpc,
      banUserRpc: banUserRpc,
      unbanUserRpc: unbanUserRpc,
      setRoomMemberRoleRpc: setRoomMemberRoleRpc,
      listBannedUsersRpc: listBannedUsersRpc,
      findUserByEmailRpc: findUserByEmailRpc,
      searchUsersRpc: searchUsersRpc,
      inviteToRoomRpc: inviteToRoomRpc,
      renameRoomRpc: renameRoomRpc,
      dissolveRoomRpc: dissolveRoomRpc,
      listKnownContactsRpc: listKnownContactsRpc,
      setRoomAvatarRpc: setRoomAvatarRpc,
      eventBus: eventBus,
    );
    r._subscribeToEvents();
    return r;
  }

  // ───────────────────────────────────────────────────────────────────
  // Public API
  // ───────────────────────────────────────────────────────────────────

  /// Возвращает список комнат пользователя с in-memory cache (TTL 30s).
  ///
  /// `includeArchived` (TASK42 Chunk 2): `null/false` — server фильтрует
  /// archived RoomMembership; `true` — возвращает все, UI сам делает
  /// post-filter для «Archived» tab.
  ///
  /// `search` (TASK42 Chunk 3): server-side ILIKE на Room.name с
  /// _escapeLike (см. RoomService.listRooms). Пустая/null строка =
  /// без фильтра. Включается в cache key — каждый query дёргает
  /// сервер (single-entry cache не выдержал бы typeahead).
  Future<List<RoomSummary>> list({
    int? productId,
    bool? includeArchived,
    String? search,
    int limit = 50,
    String? cursor,
  }) async {
    final key = _listKey(
      productId: productId,
      includeArchived: includeArchived,
      search: search,
      limit: limit,
      cursor: cursor,
    );
    final cached = _listEntry;
    if (cached != null && cached.key == key && !cached.isExpired) {
      return cached.summaries;
    }
    final fresh = await _listRpc(
      productId: productId,
      state: null,
      search: search,
      includeArchived: includeArchived,
      limit: limit,
      cursor: cursor,
    );
    _listEntry = _ListCacheEntry(
      key: key,
      summaries: fresh,
      fetchedAt: DateTime.now(),
    );
    return fresh;
  }

  Future<RoomDetails> get(int roomId) async {
    final cached = _detailsCache[roomId];
    if (cached != null && !cached.isExpired) {
      // LRU: move-to-end (recently used).
      _detailsCache.remove(roomId);
      _detailsCache[roomId] = cached;
      return cached.details;
    }
    final fresh = await _getRpc(roomId: roomId);
    _putDetails(fresh);
    return fresh;
  }

  /// Принудительно сбросить cache. Если [roomId] передан — только
  /// конкретная запись details (list cache не трогается). Без аргумента
  /// — clear-им всё (list + details).
  void invalidate({int? roomId}) {
    if (roomId == null) {
      _listEntry = null;
      _detailsCache.clear();
      return;
    }
    _detailsCache.remove(roomId);
  }

  Future<RoomDetails> createDirect(int peerMessengerUserId) async {
    final result = await _createDirectRpc(
      peerMessengerUserId: peerMessengerUserId,
    );
    _onCreateResult(result);
    return result;
  }

  Future<RoomDetails> createGroup({
    required String name,
    required List<int> memberMessengerUserIds,
    int? productId,
  }) async {
    final result = await _createGroupRpc(
      name: name,
      memberMessengerUserIds: memberMessengerUserIds,
      productId: productId,
    );
    _onCreateResult(result);
    return result;
  }

  Future<RoomDetails> getOrCreateProductRoom({
    required String productExternalKey,
    required String entityType,
    required String entityId,
    RoomType roomType = RoomType.productRoom,
  }) async {
    final result = await _getOrCreateProductRoomRpc(
      productExternalKey: productExternalKey,
      entityType: entityType,
      entityId: entityId,
      roomType: roomType,
    );
    _onCreateResult(result);
    return result;
  }

  Future<RoomDetails> openSupportChat({
    required String productExternalKey,
    required String contextId,
  }) async {
    final result = await _openSupportChatRpc(
      productExternalKey: productExternalKey,
      contextId: contextId,
    );
    _onCreateResult(result);
    return result;
  }

  // ─── TASK42: per-user room state mutations ────────────────────────

  /// Mute room до момента [mutedUntil] (либо `now + muteForSeconds`).
  /// Передавайте РОВНО ОДИН из параметров; оба одновременно — server
  /// бросит ArgumentError. Для «mute навсегда» — [kMuteForever].
  ///
  /// Cache: list + details(roomId) invalidate сразу (для immediate UI
  /// rerender после server-confirm). Дополнительно server эмитит
  /// `roomMembershipUpdated` event на каналы устройств этого user-а
  /// (cross-device); reactor `_onEvent` вторично invalidate-ит — что
  /// no-op если cache уже пуст.
  Future<void> muteRoom({
    required int roomId,
    DateTime? mutedUntil,
    int? muteForSeconds,
  }) async {
    await _muteRoomRpc(
      roomId: roomId,
      mutedUntil: mutedUntil,
      muteForSeconds: muteForSeconds,
    );
    _listEntry = null;
    _detailsCache.remove(roomId);
  }

  Future<void> unmuteRoom(int roomId) async {
    await _unmuteRoomRpc(roomId: roomId);
    _listEntry = null;
    _detailsCache.remove(roomId);
  }

  Future<void> archiveRoom(int roomId) async {
    await _archiveRoomRpc(roomId: roomId);
    _listEntry = null;
    _detailsCache.remove(roomId);
  }

  Future<void> unarchiveRoom(int roomId) async {
    await _unarchiveRoomRpc(roomId: roomId);
    _listEntry = null;
    _detailsCache.remove(roomId);
  }

  /// Покинуть комнату. Direct chat — после leave + новый
  /// `createDirect(peer)` создаст fresh Matrix room (см. server-side
  /// `RoomService.leaveRoom` doc). list invalidate (room исчезает),
  /// details(roomId) — point-cache уже невалиден (membership delete-нут,
  /// дальнейший `get(roomId)` вернёт `RoomUnavailableException`).
  Future<void> leaveRoom(int roomId) async {
    await _leaveRoomRpc(roomId: roomId);
    _listEntry = null;
    _detailsCache.remove(roomId);
  }

  // ─────────────────────────────────────────────────────────────────
  // TASK29 Chunk 2: admin/moderation actions
  // ─────────────────────────────────────────────────────────────────

  /// **TASK29**: kick — caller-admin удаляет target из комнаты.
  /// Target может re-join (через invite). Authorization: caller `role
  /// >= admin` server-side.
  ///
  /// Cache: list + details(roomId) invalidate сразу. Server также
  /// эмитит `roomMembershipUpdated` через sync dispatcher → cross-
  /// device propagation.
  Future<void> kickUser({
    required int roomId,
    required int targetMessengerUserId,
    String? reason,
  }) async {
    await _kickUserRpc(
      roomId: roomId,
      targetMessengerUserId: targetMessengerUserId,
      reason: reason,
    );
    _listEntry = null;
    _detailsCache.remove(roomId);
  }

  /// **B15 rename room**: caller-admin (PL ≥ 50) меняет название
  /// group-комнаты. Direct chats отклоняются сервером
  /// (`ArgumentError` → SerializableException на клиенте).
  ///
  /// Server-side валидирует: trim non-empty, length ≤ 100.
  /// Realtime: после успешного PUT server эмитит `roomStateChanged`,
  /// который inval-идирует list/details кэши автоматически. Здесь
  /// дополнительно invalidate-им сразу, чтобы next `list()`/`get()`
  /// после await-а вернули свежие данные без задержки sync.
  Future<void> renameRoom({
    required int roomId,
    required String newName,
  }) async {
    await _renameRoomRpc(roomId: roomId, newName: newName);
    _listEntry = null;
    _detailsCache.remove(roomId);
  }

  /// **Atomic dissolveRoom**: owner распускает group-комнату одним
  /// серверным RPC — сервер kick-ает всех остальных участников и
  /// затем leave-ит сам. Заменяет старый client-side loop
  /// kick+leave (см. [GroupSettingsScreen._dissolveGroup]).
  ///
  /// Authorization: caller `role == 'owner'` server-side. Direct
  /// chats отклоняются `ArgumentError`.
  ///
  /// При partial failure сервер бросает
  /// `RoomDissolvePartialException(kicked, total, cause)`; повторный
  /// вызов идемпотентен (already-not-member kick'и сервер пропустит).
  ///
  /// Cache: list invalidate (комната пропадает у caller); details
  /// удаляем (membership delete-нут, следующий `get(roomId)` вернёт
  /// `RoomUnavailableException`).
  Future<void> dissolveRoom(int roomId) async {
    await _dissolveRoomRpc(roomId: roomId);
    _listEntry = null;
    _detailsCache.remove(roomId);
  }

  /// **B16-ext (group avatar)**: загрузить новый аватар группы.
  /// Принимает image bytes + MIME, возвращает mxcUrl. Direct chats
  /// reject. После успеха invalidate-им cache list+details чтобы
  /// следующие listRooms/get подтянули свежий avatarUrl.
  Future<String> setRoomAvatar({
    required int roomId,
    required ByteData bytes,
    required String mimeType,
  }) async {
    final mxc = await _setRoomAvatarRpc(
      roomId: roomId,
      bytes: bytes,
      mimeType: mimeType,
    );
    _listEntry = null;
    _detailsCache.remove(roomId);
    return mxc;
  }

  /// **TASK29**: ban — caller-admin удаляет target И блокирует rejoin.
  Future<void> banUser({
    required int roomId,
    required int targetMessengerUserId,
    String? reason,
  }) async {
    await _banUserRpc(
      roomId: roomId,
      targetMessengerUserId: targetMessengerUserId,
      reason: reason,
    );
    _listEntry = null;
    _detailsCache.remove(roomId);
  }

  /// **TASK29**: unban — снимает ban; target снова может invite-ся.
  /// Membership НЕ восстанавливается автоматически — требует invite
  /// (server-side `RoomService.inviteToRoom`, TASK13).
  Future<void> unbanUser({
    required int roomId,
    required int targetMessengerUserId,
  }) async {
    await _unbanUserRpc(
      roomId: roomId,
      targetMessengerUserId: targetMessengerUserId,
    );
    // Banned list кэша нет (lazy load per screen open) — invalidate не
    // нужен. Detail тоже не affected (banned users не в participants).
  }

  /// **TASK29**: setRoomMemberRole — promote / demote target's role.
  /// Authorization: caller `role == owner` server-side. Last-owner
  /// demote rejected с `LastOwnerCannotDemoteException`.
  Future<void> setRoomMemberRole({
    required int roomId,
    required int targetMessengerUserId,
    required RoomMemberRole newRole,
  }) async {
    await _setRoomMemberRoleRpc(
      roomId: roomId,
      targetMessengerUserId: targetMessengerUserId,
      newRole: newRole,
    );
    _listEntry = null;
    _detailsCache.remove(roomId);
  }

  /// **TASK29 Chunk 2**: список banned users в комнате — для
  /// `BannedUsersScreen`. Lazy fetch на каждый screen open (в SDK
  /// не кэшируется — banned list rare-access; cache даёт risk
  /// stale-data после unban с другого device).
  Future<List<RoomParticipant>> listBannedUsers(int roomId) =>
      _listBannedUsersRpc(roomId: roomId);

  /// **Chat-create flow**: look up a messenger user by exact email match
  /// (case-insensitive, scoped to caller's tenant).
  ///
  /// Throws [PeerUnavailableException] if no account with that email
  /// exists OR the account exists but the user hasn't completed first
  /// messenger session yet. Same error for both — anti-enumeration:
  /// attackers can't distinguish "no such email" from "exists but
  /// not-yet-onboarded".
  Future<RoomParticipant> findUserByEmail({
    required String email,
    String tenantExternalKey = 'nsg',
  }) =>
      _findUserByEmailRpc(
        email: email,
        tenantExternalKey: tenantExternalKey,
      );

  /// **Known contacts** — все participants комнат, в которых я состою,
  /// distinct, без self / ghosts. Сортировка `displayName ASC`.
  ///
  /// Используется UI default-списком в picker-ах (создание группы,
  /// добавление участника) ДО ввода в поиск. Privacy-aware: не
  /// раскрывает справочник всех зарегистрированных пользователей,
  /// только тех, с кем у меня уже есть хоть одна общая комната.
  ///
  /// Без кэширования: список достаточно небольшой (десятки людей),
  /// сервер делает 3 SQL запроса. Если станет узким местом — добавим
  /// in-memory cache с invalidation на membershipChanged/messageCreated.
  Future<List<RoomParticipant>> listKnownContacts() =>
      _listKnownContactsRpc();

  /// **Chat-create flow (extended)**: search users by email exact-match
  /// (when query contains `@`) OR by nickname/displayName ILIKE
  /// substring. Returns up to [limit] matches (default 20, max 50).
  ///
  /// Empty list for queries < 2 chars (anti-fishing). Caller's tenant
  /// scope. Ghost users (no Matrix identity) filtered out. Self
  /// excluded.
  Future<List<RoomParticipant>> searchUsers({
    required String query,
    int limit = 20,
    String tenantExternalKey = 'nsg',
  }) =>
      _searchUsersRpc(
        query: query,
        limit: limit,
        tenantExternalKey: tenantExternalKey,
      );

  /// **Add user to existing chat**: invite a messenger user (same tenant)
  /// to a room caller is already member of. Idempotent — if target is
  /// already member, no-op.
  ///
  /// Throws [RoomUnavailableException] if caller is not a room member,
  /// [PeerUnavailableException] if target user is missing or
  /// cross-tenant.
  ///
  /// Cache invalidation: drops cached details for [roomId] so next
  /// `get(roomId)` fetches the fresh participants list with the new
  /// member.
  Future<void> inviteToRoom({
    required int roomId,
    required int targetMessengerUserId,
  }) async {
    await _inviteToRoomRpc(
      roomId: roomId,
      targetMessengerUserId: targetMessengerUserId,
    );
    _detailsCache.remove(roomId);
  }

  /// Список Product-ов, в которых у viewer есть >=1 RoomMembership.
  /// Используется в TASK42 Chunk 3 ProductFilter dropdown (standalone
  /// mode). НЕ кэшируется на стороне SDK — список меняется редко, и
  /// dropdown открывается раз в сессию. Server считает DISTINCT через
  /// JOIN; cost минимален.
  Future<List<Product>> availableProducts() => _getAvailableProductsRpc();

  // ──────────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _eventsSub?.cancel();
    _eventsSub = null;
    _listEntry = null;
    _detailsCache.clear();
    _typingByRoom.clear();
    _typingNamesByRoom.clear();
    _typingVersion.dispose();
  }

  // ───────────────────────────────────────────────────────────────────
  // Internals
  // ───────────────────────────────────────────────────────────────────

  /// После каждого `create*` RPC: list cache invalidate (порядок и
  /// summary меняются), details — populate result-ом (next `get(id)`
  /// возьмёт из cache, не идёт по сети). См. ревью fc7cbe3 #6.
  void _onCreateResult(RoomDetails result) {
    _listEntry = null;
    _putDetails(result);
  }

  void _putDetails(RoomDetails d) {
    // Move-to-end: если уже есть, удаляем чтобы переставить в конец
    // (recently used).
    _detailsCache.remove(d.id);
    _detailsCache[d.id] = _DetailsCacheEntry(
      details: d,
      fetchedAt: DateTime.now(),
    );
    // LRU eviction: head — least recently used.
    while (_detailsCache.length > kRoomDetailsLruCapacity) {
      _detailsCache.remove(_detailsCache.keys.first);
    }
  }

  /// Подписка на realtime события для invalidation cache.
  void _subscribeToEvents() {
    if (kDebugMode) debugPrint('[NsgMessengerRooms] _subscribeToEvents — calling _eventBus.events.listen');
    _eventsSub = _eventBus.events.listen(
      _onEvent,
      onError: (Object e, StackTrace st) {
        // Underlying error — для cache не критично, оставляем как есть
        // (TTL подстрахует через 30s). Лог для observability.
        if (kDebugMode) debugPrint('[NsgMessengerRooms] event-bus error: $e\n$st');
      },
    );
    if (kDebugMode) debugPrint('[NsgMessengerRooms] _subscribeToEvents — listener attached');
  }

  void _onEvent(MessengerEvent event) {
    final roomId = event.roomId;
    switch (event.eventType) {
      case MessengerEventType.messageCreated:
        // list — preview + order меняются; details — lastMessageAt/Body.
        if (roomId == null) {
          if (kDebugMode) {
            debugPrint(
              '[NsgMessengerRooms] messageCreated event has no roomId — '
              'server bug or new semantics?',
            );
          }
          return;
        }
        _listEntry = null;
        _detailsCache.remove(roomId);

      case MessengerEventType.roomCreated:
        // Caller получил доступ к новой комнате — list перерисовать.
        // details не trogaем — комната ещё не в нашем кэше; первый
        // `get(roomId)` подтянет свежее.
        _listEntry = null;

      case MessengerEventType.membershipJoined:
      case MessengerEventType.membershipLeft:
      case MessengerEventType.membershipRemoved:
        // Participants изменились → details[roomId] инвалидируем.
        // list НЕ трогаем: имя/аватар/order/lastMessage не меняются
        // от change membership-а.
        if (roomId == null) {
          if (kDebugMode) {
            debugPrint(
              '[NsgMessengerRooms] membership event has no roomId — '
              'server bug?',
            );
          }
          return;
        }
        _detailsCache.remove(roomId);

      case MessengerEventType.roomStateChanged:
        // На TASK17 dispatcher эмитит только `field='name'` (см. TASK17
        // Chunk 2 Q2). Имя в RoomSummary — invalidate list; имя в
        // RoomDetails тоже — invalidate details. Если backend в
        // будущем расширит на topic/avatar — оба cache всё равно
        // должны invalidate.
        if (roomId == null) {
          if (kDebugMode) {
            debugPrint(
              '[NsgMessengerRooms] roomStateChanged event has no roomId — '
              'server bug?',
            );
          }
          return;
        }
        _listEntry = null;
        _detailsCache.remove(roomId);

      case MessengerEventType.roomUnreadChanged:
        // TASK18: counter обновился (либо dispatcher инкрементил на
        // новое сообщение в room, либо markRead обнулил — в т.ч.
        // cross-device от другого устройства того же юзера). list-
        // cache invalidate, чтобы badge в ChatsListScreen перерисовался
        // при следующем `list()` вызове. details также — `RoomDetails`
        // содержит unreadCount, и открытый ChatScreen может (теоретически)
        // показывать счётчик в title, хотя на TASK15 не показывает.
        if (roomId == null) {
          if (kDebugMode) {
            debugPrint(
              '[NsgMessengerRooms] roomUnreadChanged event has no roomId — '
              'server bug?',
            );
          }
          return;
        }
        _listEntry = null;
        _detailsCache.remove(roomId);

      case MessengerEventType.roomMembershipUpdated:
        // TASK42: per-user mute/archive flag toggled. Server эмитит
        // ТОЛЬКО в channel того user-а, чей RoomMembership row updated
        // (privacy boundary — см. TASK42 plan Q1).
        // **TASK29 Chunk 2**: тот же event теперь эмитится из
        // `MatrixSyncDispatcher._processPowerLevels` для role/powerLevel
        // changes (NOT privacy-restricted — Matrix state публичный).
        // Каждый member's worker эмитит независимо в свой channel; SDK
        // reactor invalidate-ит cache → next `get(roomId)` подтягивает
        // fresh participants с обновлёнными role badges.
        // Both list и details содержат membership state — invalidate оба.
        // Cross-device: alice device A → device B получает event и
        // обновляет UI без user-action.
        if (roomId == null) {
          if (kDebugMode) {
            debugPrint(
              '[NsgMessengerRooms] roomMembershipUpdated event has no roomId — '
              'server bug?',
            );
          }
          return;
        }
        _listEntry = null;
        _detailsCache.remove(roomId);

      // Зарезервированные типы (TASK37 / TASK29 / TASK33) — пока skip;
      // когда понадобятся, добавим ветки.
      case MessengerEventType.typingChanged:
        // **B9 typing indicator в chats-list**: обновляем per-room
        // typing map + parallel display-names. ChatScreen контроллер
        // тоже подписан на этот же bus event (отдельный _typingPeers);
        // двойная bookkeeping — но дёшево.
        if (roomId != null) {
          final ids = event.typingMatrixUserIds;
          final names = event.typingDisplayNames;
          if (ids == null || ids.isEmpty) {
            _typingByRoom.remove(roomId);
            _typingNamesByRoom.remove(roomId);
          } else {
            _typingByRoom[roomId] = Set<String>.unmodifiable(ids);
            _typingNamesByRoom[roomId] =
                List<String>.unmodifiable(names ?? const <String>[]);
          }
          _typingVersion.value = _typingVersion.value + 1;
        }
        return;

      case MessengerEventType.messageUpdated:
      case MessengerEventType.messageDeleted:
      case MessengerEventType.roomUpdated:
      case MessengerEventType.roomArchived:
      case MessengerEventType.roomClosed:
      case MessengerEventType.membershipRoleChanged:
      case MessengerEventType.readReceiptUpdated:
        // Эти events НЕ влияют на rooms-list (room metadata не
        // меняется); SDK обработают на уровне MessagesController.
        return;
    }
  }

  static String _listKey({
    required int? productId,
    required bool? includeArchived,
    required String? search,
    required int limit,
    required String? cursor,
  }) =>
      'p=${productId ?? '_'}|a=${includeArchived ?? '_'}|s=${search ?? '_'}|l=$limit|c=${cursor ?? '_'}';
}

class _ListCacheEntry {
  final String key;
  final List<RoomSummary> summaries;
  final DateTime fetchedAt;

  _ListCacheEntry({
    required this.key,
    required this.summaries,
    required this.fetchedAt,
  });

  bool get isExpired => DateTime.now().difference(fetchedAt) > kRoomsCacheTtl;
}

class _DetailsCacheEntry {
  final RoomDetails details;
  final DateTime fetchedAt;

  _DetailsCacheEntry({required this.details, required this.fetchedAt});

  bool get isExpired => DateTime.now().difference(fetchedAt) > kRoomsCacheTtl;
}
