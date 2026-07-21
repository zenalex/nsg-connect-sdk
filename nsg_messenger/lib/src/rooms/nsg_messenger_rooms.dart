import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../cache/messenger_cache_store.dart';
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
/// **issue #46** — постраничный `listRooms` ВМЕСТЕ с курсором. Отличие
/// от [ListRoomsRpc] ровно одно: ответ говорит, есть ли ещё комнаты, —
/// без этого клиент не мог уйти дальше первой страницы.
typedef ListRoomsPageRpc =
    Future<RoomListPage> Function({
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

// **TASK62**: пользовательские папки чатов (server-side, many-to-many).
typedef ListChatFoldersRpc = Future<List<ChatFolderView>> Function();
typedef CreateChatFolderRpc =
    Future<ChatFolderView> Function({required String name});
typedef RenameChatFolderRpc =
    Future<ChatFolderView> Function({
      required int folderId,
      required String name,
    });
typedef DeleteChatFolderRpc = Future<void> Function({required int folderId});
typedef SetChatFolderRoomRpc =
    Future<void> Function({
      required int folderId,
      required int roomId,
      required bool inFolder,
    });

// **TASK68**: «Избранное» — self-чаты (RoomType.saved) + TTL автоочистки.
// Сигнатуры зеркалят сгенерированный Serverpod-клиент 1:1 (см. коммент к
// блоку typedef-ов выше: Serverpod помечает все именованные параметры
// `required` даже там, где в Dart есть дефолт).
typedef GetOrCreateSelfRoomRpc = Future<RoomDetails> Function();
typedef CreateSavedChatRpc =
    Future<RoomDetails> Function({required String name});
typedef ListSavedChatsRpc = Future<List<RoomSummary>> Function();
typedef SetRoomAutoCleanupTtlRpc =
    Future<RoomDetails> Function({required int roomId, int? ttlSeconds});

/// **B16-ext (group avatar)**: загрузка/смена аватара group/team/
/// productRoom. Принимает image bytes + MIME, возвращает mxcUrl.
/// Direct chats отклоняются.
typedef SetRoomAvatarRpc =
    Future<String> Function({
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

  // **TASK62**: RPC пользовательских папок. Nullable — подключаются
  // через [wireChatFolders] в attach() (тестовые attachWithRpcs без
  // wiring просто не имеют фичи: [chatFoldersAvailable] == false).
  ListChatFoldersRpc? _listChatFoldersRpc;
  CreateChatFolderRpc? _createChatFolderRpc;
  RenameChatFolderRpc? _renameChatFolderRpc;
  DeleteChatFolderRpc? _deleteChatFolderRpc;
  SetChatFolderRoomRpc? _setChatFolderRoomRpc;

  /// **TASK62**: single-entry кэш `listChatFolders` (TTL 30с, как list()).
  List<ChatFolderView>? _chatFoldersCache;
  DateTime? _chatFoldersFetchedAt;

  // **TASK68**: RPC «Избранного». Nullable по той же причине, что и папки
  // — подключаются через [wireSavedChats] в attach(), чтобы не ломать 14
  // существующих call-site-ов `attachWithRpcs` новым required-параметром.
  GetOrCreateSelfRoomRpc? _getOrCreateSelfRoomRpc;
  CreateSavedChatRpc? _createSavedChatRpc;
  ListSavedChatsRpc? _listSavedChatsRpc;
  SetRoomAutoCleanupTtlRpc? _setRoomAutoCleanupTtlRpc;

  // **issue #46**: постраничный list с курсором. Nullable по той же
  // причине, что папки и «Избранное» — подключается через
  // [wireRoomsFullSync], чтобы не ломать существующие call-site-ы
  // `attachWithRpcs`. Если не подключён (старый сервер) — [listAll]
  // честно откатывается на одностраничный [list].
  ListRoomsPageRpc? _listRoomsPageRpc;

  StreamSubscription<MessengerEvent>? _eventsSub;

  /// Single-entry cache для `list()`. Кэшируется последний результат
  /// с ключом-сериализацией параметров. Если параметры меняются —
  /// cache miss и обновление. Большинство host-app вызывают с одинаковыми
  /// (один продукт, один limit), поэтому single-entry достаточно.
  _ListCacheEntry? _listEntry;

  /// **TASK47**: дисковый оффлайн-кэш (null → выключен: web / host не
  /// включил / ошибка открытия). Устанавливается runtime-ом ПОСЛЕ сессии
  /// (когда известен userId). При его наличии `list()` наполняет диск на
  /// успехе и отдаёт диск при сетевой ошибке, а realtime-события мёржатся
  /// в кэш (см. `_mergeEventToCache`).
  MessengerCacheStore? _cache;

  /// **TASK47**: подключить дисковый кэш (idempotent).
  void attachCache(MessengerCacheStore cache) => _cache = cache;

  /// **TASK47**: мёрж realtime-события в дисковый кэш (§5). Best-effort:
  /// любые ошибки БД глушим — доставка событий важнее консистентности
  /// диска (следующий `list()` всё равно перезальёт список с сервера).
  ///   * `messageCreated` → кладём сообщение + двигаем превью/время (с
  ///     guard-ом по timestamp внутри store);
  ///   * `messageDeleted` → убираем сообщение + пересчитываем превью;
  ///   * `membershipLeft/Removed` СВОЁ → удаляем комнату из кэша.
  Future<void> _mergeEventToCache(MessengerEvent event) async {
    final cache = _cache;
    if (cache == null) return;
    try {
      final roomId = event.roomId;
      switch (event.eventType) {
        case MessengerEventType.messageCreated:
          final m = event.message;
          if (m != null) await cache.applyMessageCreated(m);
        case MessengerEventType.messageUpdated:
          // TASK47 gap-фикс: правка тела → обновить кэш-строку + превью
          // (только UPDATE существующей, см. applyMessageUpdated).
          final m = event.message;
          if (m != null) await cache.applyMessageUpdated(m);
        case MessengerEventType.messageDeleted:
          final evtId = event.message?.matrixEventId;
          if (roomId != null && evtId != null) {
            await cache.applyMessageDeleted(roomId, evtId);
          }
        case MessengerEventType.membershipLeft:
        case MessengerEventType.membershipRemoved:
          if (roomId != null &&
              event.membershipMessengerUserId == cache.userId) {
            await cache.removeRoom(roomId);
          }
        default:
          break;
      }
    } catch (_) {
      // best-effort — диск не должен ломать обработку событий.
    }
  }

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

  /// Test-only доступ к привязанному [MessengerEventBus] — для проверки
  /// локального emit-а (`createDirect` → `roomCreated`). В production не
  /// используется: SDK эмитит через `_eventBus` напрямую.
  @visibleForTesting
  MessengerEventBus get eventBus => _eventBus;

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
    final rooms = attachWithRpcs(
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
          ({required int roomId, DateTime? mutedUntil, int? muteForSeconds}) =>
              withAuthRetry(
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
            () => client.messenger.renameRoom(roomId: roomId, newName: newName),
            session(),
          ),
      dissolveRoomRpc: ({required int roomId}) => withAuthRetry(
        () => client.messenger.dissolveRoom(roomId: roomId),
        session(),
      ),
      listKnownContactsRpc: () =>
          withAuthRetry(() => client.messenger.listKnownContacts(), session()),
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
    // **TASK62**: пользовательские папки чатов.
    rooms.wireChatFolders(
      list: () =>
          withAuthRetry(() => client.messenger.listChatFolders(), session()),
      create: ({required String name}) => withAuthRetry(
        () => client.messenger.createChatFolder(name: name),
        session(),
      ),
      rename: ({required int folderId, required String name}) => withAuthRetry(
        () => client.messenger.renameChatFolder(folderId: folderId, name: name),
        session(),
      ),
      delete: ({required int folderId}) => withAuthRetry(
        () => client.messenger.deleteChatFolder(folderId: folderId),
        session(),
      ),
      setRoom:
          ({
            required int folderId,
            required int roomId,
            required bool inFolder,
          }) => withAuthRetry(
            () => inFolder
                ? client.messenger.addRoomToChatFolder(
                    folderId: folderId,
                    roomId: roomId,
                  )
                : client.messenger.removeRoomFromChatFolder(
                    folderId: folderId,
                    roomId: roomId,
                  ),
            session(),
          ),
    );
    // **TASK68**: «Избранное» — self-чаты + TTL автоочистки.
    rooms.wireSavedChats(
      getOrCreateDefault: () => withAuthRetry(
        () => client.messenger.getOrCreateSelfRoom(),
        session(),
      ),
      create: ({required String name}) => withAuthRetry(
        () => client.messenger.createSavedChat(name: name),
        session(),
      ),
      list: () =>
          withAuthRetry(() => client.messenger.listSavedChats(), session()),
      setTtl: ({required int roomId, int? ttlSeconds}) => withAuthRetry(
        () => client.messenger.setRoomAutoCleanupTtl(
          roomId: roomId,
          ttlSeconds: ttlSeconds,
        ),
        session(),
      ),
    );
    // **issue #46**: полный синк списка комнат (страницы + курсор).
    rooms.wireRoomsFullSync(
      listPage:
          ({
            int? productId,
            RoomState? state,
            String? search,
            bool? includeArchived,
            required int limit,
            String? cursor,
          }) => withAuthRetry(
            () => client.messenger.listRoomsPage(
              productId: productId,
              state: state,
              search: search,
              includeArchived: includeArchived,
              limit: limit,
              cursor: cursor,
            ),
            session(),
          ),
    );
    return rooms;
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
    findUserByEmailRpc ??=
        ({required String email, String tenantExternalKey = 'nsg'}) async =>
            throw UnimplementedError(
              'findUserByEmailRpc not set in attachWithRpcs',
            );
    searchUsersRpc ??=
        ({
          required String query,
          int limit = 20,
          String tenantExternalKey = 'nsg',
        }) async => throw UnimplementedError(
          'searchUsersRpc not set in attachWithRpcs',
        );
    inviteToRoomRpc ??=
        ({required int roomId, required int targetMessengerUserId}) async =>
            throw UnimplementedError(
              'inviteToRoomRpc not set in attachWithRpcs',
            );
    renameRoomRpc ??= ({required int roomId, required String newName}) async =>
        throw UnimplementedError('renameRoomRpc not set in attachWithRpcs');
    dissolveRoomRpc ??= ({required int roomId}) async =>
        throw UnimplementedError('dissolveRoomRpc not set in attachWithRpcs');
    listKnownContactsRpc ??= () async => const <RoomParticipant>[];
    setRoomAvatarRpc ??=
        ({
          required int roomId,
          required ByteData bytes,
          required String mimeType,
        }) async => throw UnimplementedError(
          'setRoomAvatarRpc not set in attachWithRpcs',
        );
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

  // ─── TASK62: пользовательские папки чатов ──────────────────────────

  /// **TASK62**: подключить RPC пользовательских папок. Вызывается из
  /// [attach]; тесты могут подключить fake-и (или не подключать вовсе).
  void wireChatFolders({
    required ListChatFoldersRpc list,
    required CreateChatFolderRpc create,
    required RenameChatFolderRpc rename,
    required DeleteChatFolderRpc delete,
    required SetChatFolderRoomRpc setRoom,
  }) {
    _listChatFoldersRpc = list;
    _createChatFolderRpc = create;
    _renameChatFolderRpc = rename;
    _deleteChatFolderRpc = delete;
    _setChatFolderRoomRpc = setRoom;
  }

  /// **TASK62**: доступна ли фича пользовательских папок (wiring сделан).
  bool get chatFoldersAvailable => _listChatFoldersRpc != null;

  /// **TASK62**: пользовательские папки (с roomIds), кэш TTL 30с.
  /// Пустой список, если фича не подключена.
  Future<List<ChatFolderView>> listChatFolders({bool force = false}) async {
    final rpc = _listChatFoldersRpc;
    if (rpc == null) return const [];
    final cached = _chatFoldersCache;
    final at = _chatFoldersFetchedAt;
    if (!force &&
        cached != null &&
        at != null &&
        DateTime.now().difference(at) < kRoomsCacheTtl) {
      return cached;
    }
    final fresh = await rpc();
    _chatFoldersCache = fresh;
    _chatFoldersFetchedAt = DateTime.now();
    return fresh;
  }

  /// **TASK62**: сбросить кэш папок (после мутаций / pull-to-refresh).
  void invalidateChatFolders() {
    _chatFoldersCache = null;
    _chatFoldersFetchedAt = null;
  }

  /// **TASK62**: создать папку. Кэш инвалидируется.
  Future<ChatFolderView> createChatFolder(String name) async {
    final rpc = _createChatFolderRpc;
    if (rpc == null) throw StateError('chat folders не подключены');
    final created = await rpc(name: name);
    invalidateChatFolders();
    return created;
  }

  /// **TASK62**: переименовать папку. Кэш инвалидируется.
  Future<ChatFolderView> renameChatFolder(int folderId, String name) async {
    final rpc = _renameChatFolderRpc;
    if (rpc == null) throw StateError('chat folders не подключены');
    final renamed = await rpc(folderId: folderId, name: name);
    invalidateChatFolders();
    return renamed;
  }

  /// **TASK62**: удалить папку (комнаты не затрагиваются).
  Future<void> deleteChatFolder(int folderId) async {
    final rpc = _deleteChatFolderRpc;
    if (rpc == null) throw StateError('chat folders не подключены');
    await rpc(folderId: folderId);
    invalidateChatFolders();
  }

  /// **TASK62**: положить/убрать комнату в/из папки (идемпотентно).
  Future<void> setRoomInChatFolder({
    required int folderId,
    required int roomId,
    required bool inFolder,
  }) async {
    final rpc = _setChatFolderRoomRpc;
    if (rpc == null) throw StateError('chat folders не подключены');
    await rpc(folderId: folderId, roomId: roomId, inFolder: inFolder);
    invalidateChatFolders();
  }

  // ─── TASK68: «Избранное» (self-чаты) ───────────────────────────────

  /// **TASK68**: подключить RPC «Избранного». Вызывается из [attach];
  /// тесты могут подключить fake-и (или не подключать вовсе — тогда
  /// [savedChatsAvailable] == false и UI прячет раздел).
  void wireSavedChats({
    required GetOrCreateSelfRoomRpc getOrCreateDefault,
    required CreateSavedChatRpc create,
    required ListSavedChatsRpc list,
    required SetRoomAutoCleanupTtlRpc setTtl,
  }) {
    _getOrCreateSelfRoomRpc = getOrCreateDefault;
    _createSavedChatRpc = create;
    _listSavedChatsRpc = list;
    _setRoomAutoCleanupTtlRpc = setTtl;
  }

  /// **TASK68**: доступна ли фича «Избранного» (wiring сделан). Экраны
  /// гейтятся по ней — на старом сервере раздел просто не показывается.
  bool get savedChatsAvailable => _listSavedChatsRpc != null;

  /// **issue #46**: подключить постраничный `listRoomsPage` (полный синк).
  void wireRoomsFullSync({required ListRoomsPageRpc listPage}) {
    _listRoomsPageRpc = listPage;
  }

  /// **issue #46**: умеет ли сервер отдавать курсор (метод появился в
  /// этой версии). На старом сервере [listAll] откатывается на одну
  /// страницу — как было до задачи.
  bool get fullSyncAvailable => _listRoomsPageRpc != null;

  /// Потолок числа страниц в [listAll]. 50 страниц × 200 комнат = 10 000 —
  /// заведомо выше любого реального аккаунта. Это не «разумный лимит
  /// выдачи», а предохранитель от бесконечного цикла, если сервер вдруг
  /// начнёт возвращать курсор, не двигаясь вперёд. Упереться в него —
  /// аномалия, поэтому она репортится, а не проглатывается.
  static const int maxFullSyncPages = 50;

  /// Размер страницы полного синка. 200 — потолок сервера
  /// (`RoomService.listRoomsPage` клампит), берём его целиком: список
  /// комнат лёгкий, а каждая лишняя страница — лишний round-trip.
  static const int fullSyncPageSize = 200;

  /// **issue #46** — ПОЛНЫЙ список комнат: страницами по курсору до конца.
  ///
  /// Раньше UI звал [list] без курсора и получал первые 50 комнат, считая
  /// их всем списком. С 51-й комнаты чаты для пользователя переставали
  /// существовать — молча: ни ошибки, ни признака неполноты. Папки и
  /// бейджи считаются по загруженному набору, поэтому врали вместе с ним.
  ///
  /// Почему полный синк, а не догрузка по мере скролла: список комнат —
  /// это сотни лёгких `RoomSummary`, а любое производное представление
  /// (папки, бейджи, счётчики непрочитанного) обязано видеть набор
  /// целиком, иначе считает по половине данных. Пагинация остаётся там,
  /// где она уместна, — в истории сообщений.
  ///
  /// Ошибка на середине пути ПРОБРАСЫВАЕТСЯ, а не возвращает то, что
  /// успели набрать: неполный список, поданный как полный, — ровно тот
  /// баг, который здесь и чинится. Вызывающий (`ChatsListController`)
  /// покажет ошибку поверх прошлого известного списка.
  Future<List<RoomSummary>> listAll({
    int? productId,
    bool? includeArchived,
    String? search,
  }) async {
    final rpc = _listRoomsPageRpc;
    if (rpc == null) {
      // Старый сервер — ведём себя как раньше (одна страница). Лучше
      // урезанный список, чем неработающий экран.
      return list(
        productId: productId,
        includeArchived: includeArchived,
        search: search,
      );
    }

    // TTL-кэш, как у [list] — иначе каждый event-driven refresh стоил бы
    // N round-trip-ов вместо одного. Ключ помечен `full`, чтобы полный
    // набор не выдавался за ответ постраничного [list] и наоборот.
    final key =
        '${_listKey(productId: productId, includeArchived: includeArchived, search: search, limit: fullSyncPageSize, cursor: null)}|full';
    final cachedEntry = _listEntry;
    if (cachedEntry != null &&
        cachedEntry.key == key &&
        !cachedEntry.isExpired) {
      return cachedEntry.summaries;
    }

    final all = <RoomSummary>[];
    String? cursor;
    var pages = 0;
    while (true) {
      final page = await rpc(
        productId: productId,
        state: null,
        search: search,
        includeArchived: includeArchived,
        limit: fullSyncPageSize,
        cursor: cursor,
      ).timeout(const Duration(seconds: 10));
      all.addAll(page.rooms);
      pages++;
      cursor = page.nextCursor;
      if (cursor == null) break;
      if (pages >= maxFullSyncPages) {
        // Не молчим: усечение списка — это ровно тот класс бага, который
        // задача и закрывает. Уходит и в лог, и в трекер.
        final err = StateError(
          'listAll: упёрлись в потолок $maxFullSyncPages страниц '
          '(${all.length} комнат), список может быть неполным',
        );
        debugPrint('[NsgMessengerRooms] $err');
        MessengerRuntime.instance.reportError(
          err,
          StackTrace.current,
          tags: {'rooms.full_sync': 'page_cap_hit'},
        );
        break;
      }
    }

    final fresh = List<RoomSummary>.unmodifiable(all);
    _listEntry = _ListCacheEntry(
      key: key,
      summaries: fresh,
      fetchedAt: DateTime.now(),
    );

    final cache = _cache;
    if (cache != null) {
      unawaited(cache.putRooms(fresh).catchError((Object _) {}));
      // **TASK47 §3 п.6** — вычистить из кэша «комнаты-призраки» (нас
      // удалили из комнаты, пока мы были оффлайн).
      //
      // У [list] эта реконсиляция запускалась только когда ответ
      // «уместился в limit», то есть у пользователя с 50+ комнатами она
      // не срабатывала НИКОГДА. Полному синку такое условие не нужно:
      // набор полный по построению — кроме случая, когда мы упёрлись в
      // потолок страниц (тогда реконсиляция удалила бы живые комнаты).
      final q = search?.trim() ?? '';
      if (q.isEmpty && pages < maxFullSyncPages) {
        unawaited(
          cache
              .reconcileRooms(
                fresh: fresh,
                productId: productId,
                includeArchived: includeArchived ?? false,
              )
              .catchError((Object _) {}),
        );
      }
    }
    return fresh;
  }

  /// **TASK68**: дефолтный чат «Избранное» (создаётся при первом вызове).
  /// Инвалидирует кэш списка комнат — новая комната должна появиться в
  /// ленте без ручного pull-to-refresh.
  Future<RoomDetails> getOrCreateSelfRoom() async {
    final rpc = _getOrCreateSelfRoomRpc;
    if (rpc == null) throw StateError('saved chats не подключены');
    final details = await rpc();
    invalidate();
    return details;
  }

  /// **TASK68**: создать новый именованный раздел «Избранного».
  ///
  /// Сервер отказывает при пустом/длинном имени, дубле и на потолке в 20
  /// разделов — текст ошибки несёт код (`saved_chat_limit` и т.п.).
  Future<RoomDetails> createSavedChat(String name) async {
    final rpc = _createSavedChatRpc;
    if (rpc == null) throw StateError('saved chats не подключены');
    final created = await rpc(name: name);
    invalidate();
    return created;
  }

  /// **TASK68**: все self-чаты пользователя. Пустой список, если фича не
  /// подключена (старый сервер) — вызывающий код не обязан это проверять.
  ///
  /// Кэша нет намеренно: раздел «Избранное» открывается редко, а его
  /// содержимое обязано быть свежим (с другого устройства мог появиться
  /// новый раздел — это и есть сценарий фичи).
  Future<List<RoomSummary>> listSavedChats() async {
    final rpc = _listSavedChatsRpc;
    if (rpc == null) return const [];
    return rpc();
  }

  /// **TASK68**: задать TTL автоочистки комнаты; `null` — выключить.
  /// Инвалидирует кэш деталей комнаты, чтобы экран настроек перечитал
  /// актуальное значение.
  Future<RoomDetails> setRoomAutoCleanupTtl({
    required int roomId,
    Duration? ttl,
  }) async {
    final rpc = _setRoomAutoCleanupTtlRpc;
    if (rpc == null) throw StateError('saved chats не подключены');
    final details = await rpc(roomId: roomId, ttlSeconds: ttl?.inSeconds);
    invalidate();
    return details;
  }

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
    final List<RoomSummary> fresh;
    try {
      // TASK47: жёсткий таймаут на сетевой вызов. Оффлайн RPC может
      // висеть бесконечно (транспорт не бросает сразу) — тогда
      // catch→дисковый кэш ниже никогда бы не сработал, а UI застрял бы
      // на «connecting». Таймаут бросает TimeoutException → fallback.
      fresh = await _listRpc(
        productId: productId,
        state: null,
        search: search,
        includeArchived: includeArchived,
        limit: limit,
        cursor: cursor,
      ).timeout(const Duration(seconds: 6));
    } catch (e) {
      // **TASK47**: оффлайн/сетевая ошибка → отдаём дисковый кэш (если
      // есть). Пагинация (cursor) оффлайн не поддерживается — только
      // первая страница; при cursor != null пробрасываем ошибку.
      final cache = _cache;
      if (cache != null && cursor == null) {
        final disk = await cache.getRooms(
          productId: productId,
          includeArchived: includeArchived ?? false,
          search: search,
          limit: limit,
        );
        if (disk.isNotEmpty) return disk;
      }
      rethrow;
    }
    _listEntry = _ListCacheEntry(
      key: key,
      summaries: fresh,
      fetchedAt: DateTime.now(),
    );
    // **TASK47**: наполняем дисковый кэш (best-effort, не блокируем ответ).
    final cache = _cache;
    if (cache != null) {
      unawaited(cache.putRooms(fresh).catchError((Object _) {}));
      // **TASK47 §3 п.6 (gap-фикс)**: если ответ покрывает ВЕСЬ скоуп
      // (первая страница, без search, уместилось в limit) — реконсиляция
      // «комнат-призраков»: удаляем из кэша комнаты, которых больше нет
      // на сервере (удалили из комнаты, пока были оффлайн). putRooms и
      // reconcile работают с непересекающимися roomId — порядок не важен.
      final q = search?.trim() ?? '';
      if (cursor == null && q.isEmpty && fresh.length < limit) {
        unawaited(
          cache
              .reconcileRooms(
                fresh: fresh,
                productId: productId,
                includeArchived: includeArchived ?? false,
              )
              .catchError((Object _) {}),
        );
      }
    }
    return fresh;
  }

  /// **TASK47**: прочитать список комнат ТОЛЬКО из дискового кэша, без
  /// сетевого вызова. Возвращает пустой список, если кэш не подключён,
  /// пуст или чтение упало. Используется UI (ChatsListController) для
  /// cache-first первого рендера: оффлайн чаты показываются мгновенно,
  /// пока (или если) сетевой `list()` подтянет свежее.
  Future<List<RoomSummary>> cachedRoomsOrEmpty({
    int? productId,
    bool? includeArchived,
    String? search,
    int limit = 50,
  }) async {
    final c = _cache;
    if (c == null) return const [];
    try {
      return await c.getRooms(
        productId: productId,
        includeArchived: includeArchived ?? false,
        search: search,
        limit: limit,
      );
    } catch (_) {
      return const [];
    }
  }

  Future<RoomDetails> get(int roomId) async {
    final cached = _detailsCache[roomId];
    if (cached != null && !cached.isExpired) {
      // LRU: move-to-end (recently used).
      _detailsCache.remove(roomId);
      _detailsCache[roomId] = cached;
      return cached.details;
    }
    final RoomDetails fresh;
    try {
      // **TASK47-i2**: жёсткий таймаут на сетевой `get`. Оффлайн RPC может
      // висеть бесконечно (транспорт не бросает сразу) — тогда catch→
      // дисковый кэш ниже не сработал бы, а ChatScreen застрял бы на
      // «connecting». Таймаут → TimeoutException → fallback.
      fresh = await _getRpc(roomId: roomId).timeout(const Duration(seconds: 6));
    } catch (e) {
      // **TASK47-i2**: оффлайн/сеть/таймаут → дисковый кэш деталей (если
      // есть), чтобы чат открывался оффлайн. Нет кэша → пробрасываем (в т.ч.
      // доменные RoomUnavailable/NotFound — их маскировать stale-деталями
      // нельзя; на leave/kick кэш деталей чистится removeRoom-ом).
      final disk = await _cache?.getRoomDetails(roomId);
      if (disk != null) {
        _putDetails(disk);
        return disk;
      }
      rethrow;
    }
    _putDetails(fresh);
    // **TASK47-i2**: наполняем дисковый кэш деталей (best-effort, не блокируем).
    final cache = _cache;
    if (cache != null) {
      unawaited(cache.putRoomDetails(roomId, fresh).catchError((Object _) {}));
    }
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

  /// **2026-07-13**: персональное имя комнаты — видит только текущий
  /// пользователь (высший приоритет имени в списке/заголовке). Пустая
  /// строка = сброс к обычному имени.
  Future<void> setRoomCustomName({
    required int roomId,
    required String customName,
  }) async {
    await withAuthRetry(
      () => MessengerRuntime.instance.client.messenger.setRoomCustomName(
        roomId: roomId,
        customName: customName,
      ),
      MessengerRuntime.instance.sessionManager,
    );
    _listEntry = null;
    _detailsCache.remove(roomId);
  }

  /// **2026-07-13**: запретить/разрешить участнику писать в комнату
  /// (админ/владелец; участник остаётся читателем). [untilSeconds] —
  /// длительность; null при [banned]=true — навсегда.
  Future<void> setWriteBan({
    required int roomId,
    required int targetMessengerUserId,
    required bool banned,
    int? untilSeconds,
  }) async {
    await withAuthRetry(
      () => MessengerRuntime.instance.client.messenger.setWriteBan(
        roomId: roomId,
        targetMessengerUserId: targetMessengerUserId,
        banned: banned,
        untilSeconds: untilSeconds,
      ),
      MessengerRuntime.instance.sessionManager,
    );
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

  /// **TASK75 §3**: «закрыть» support-чат у текущего оператора — скрыть до
  /// следующего сообщения заявителя (per-user `dismissedUntilMessage`).
  /// Тикет/комната не закрываются. Возврат — реактивно: сервер на
  /// сообщение заявителя сбрасывает флаг и эмитит `roomMembershipUpdated`,
  /// что через [_onEvent] инвалидирует list-кэш → чат появляется снова.
  /// list invalidate сразу (для immediate hide после server-confirm).
  Future<void> dismissRoom(int roomId) async {
    await withAuthRetry(
      () => MessengerRuntime.instance.client.messenger.dismissRoom(
        roomId: roomId,
      ),
      MessengerRuntime.instance.sessionManager,
    );
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
  }) => _findUserByEmailRpc(email: email, tenantExternalKey: tenantExternalKey);

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
  Future<List<RoomParticipant>> listKnownContacts() => _listKnownContactsRpc();

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
  }) => _searchUsersRpc(
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
    // Драйвим тот же reactive-путь, что прислал бы server `/sync`:
    // caller только что создал/получил доступ к комнате, но сервер
    // эмитит `roomCreated` ТОЛЬКО через Matrix sync-worker (latency,
    // либо membership-event может быть пропущен целиком) — из-за чего
    // чат-лист оставался stale до полного reload. Инжектим локальный
    // `roomCreated`, чтобы `ChatsListController` перезапросил listRooms
    // и комната появилась у создателя сразу. Local-only; peer узнаёт о
    // комнате через свой sync-worker. `_onEvent` тоже поймает это
    // событие (повторный invalidate list-cache — идемпотентно).
    _eventBus.emitLocal(
      MessengerEvent(
        eventType: MessengerEventType.roomCreated,
        serverTimestamp: DateTime.now().toUtc(),
        roomId: result.id,
        matrixRoomId: result.matrixRoomId,
      ),
    );
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
    if (kDebugMode) {
      debugPrint(
        '[NsgMessengerRooms] _subscribeToEvents — calling _eventBus.events.listen',
      );
    }
    _eventsSub = _eventBus.events.listen(
      _onEvent,
      onError: (Object e, StackTrace st) {
        // Underlying error — для cache не критично, оставляем как есть
        // (TTL подстрахует через 30s). Лог для observability.
        if (kDebugMode) {
          debugPrint('[NsgMessengerRooms] event-bus error: $e\n$st');
        }
      },
    );
    if (kDebugMode) {
      debugPrint('[NsgMessengerRooms] _subscribeToEvents — listener attached');
    }
  }

  void _onEvent(MessengerEvent event) {
    // **TASK47**: параллельно мёржим событие в дисковый кэш (best-effort,
    // fire-and-forget — не блокирует in-memory инвалидацию ниже).
    if (_cache != null) unawaited(_mergeEventToCache(event));
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
            _typingNamesByRoom[roomId] = List<String>.unmodifiable(
              names ?? const <String>[],
            );
          }
          _typingVersion.value = _typingVersion.value + 1;
        }
        return;

      case MessengerEventType.contactRequestChanged:
        // Контакт-реквесты (nsg-connect) не относятся к кэшу комнат — skip.
        return;

      case MessengerEventType.messageDeleted:
        // **B23**: redaction может изменить превью списка чатов — если
        // удалено было последнее сообщение комнаты, сервер
        // (`_processRedaction`) пересчитывает `Room.lastMessageBody/At`
        // по последнему НЕ-удалённому сообщению (или placeholder).
        // Инвалидируем list/details cache, чтобы следующий `list()`
        // подтянул свежее превью. Превью-fetch дёшев, поэтому
        // инвалидируем на любой tombstone (даже если превью не
        // изменилось — корректнее, чем пропустить настоящее изменение).
        if (roomId != null) {
          _listEntry = null;
          _detailsCache.remove(roomId);
        }
        return;

      case MessengerEventType.messageUpdated:
      case MessengerEventType.roomUpdated:
      case MessengerEventType.roomArchived:
      case MessengerEventType.roomClosed:
      case MessengerEventType.membershipRoleChanged:
      case MessengerEventType.readReceiptUpdated:
      case MessengerEventType.reactionChanged:
      // **Issue #35**: закрепление сообщений — метаданные комнаты в списке
      // не меняются; обрабатывается в MessagesController открытого чата
      // (плашка закреплённых).
      case MessengerEventType.pinnedMessagesChanged:
        // Эти events НЕ влияют на rooms-list (room metadata не
        // меняется); SDK обработают на уровне MessagesController
        // (reactionChanged → reaction aggregation в открытом чате).
        return;

      case MessengerEventType.callInvite:
      case MessengerEventType.callAnswer:
      case MessengerEventType.callCandidates:
      case MessengerEventType.callHangup:
      case MessengerEventType.callSelectAnswer:
      case MessengerEventType.callReject:
      case MessengerEventType.callNegotiate:
        // **TASK46 (SDK)**: эфемерный call-сигналинг — rooms-list он не
        // касается (метаданные комнаты не меняются). Обрабатывается в
        // CallController (подписан на тот же bus).
        return;
      case MessengerEventType.presenceUpdated:
        // **TASK55 итер.2b**: presence эфемерен, rooms-list не трогает;
        // обрабатывается подписчиком в ChatScreen.
        return;
      case MessengerEventType.chatFoldersChanged:
        // **Realtime-синк**: другое устройство изменило папки — сброс
        // TTL-кэша; controller перечитает по этому же событию.
        invalidateChatFolders();
        return;
      case MessengerEventType.contactMetaChanged:
        // **Realtime-синк**: alias мог смениться — имена direct-комнат
        // в списке устарели; кэш меток сбрасывает runtime-листенер.
        invalidate();
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
