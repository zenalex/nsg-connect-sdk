// **TASK22-Phase2 Chunk 2 PART C**: demo runtime intentionally uses
// `@visibleForTesting` factories (`MessengerEventBus.attachWithFactory`,
// `NsgMessengerRooms.attachWithRpcs`, `NsgMessengerSettings.attachWithRpcs`)
// to plug in in-memory fakes. Demo mode is itself a "test flavor" of
// the runtime (not for production use), so we treat the warnings as
// expected. Stripping the annotations off the factories would weaken
// the contract for everyone else.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messages/messages_rpc.dart';
import '../messenger_runtime.dart';
import '../messenger_session_state.dart';
import '../rooms/nsg_messenger_rooms.dart';
import '../rooms/room_summary_tile.dart' show registerTimeagoLocales;
import '../runtime/messenger_event_bus.dart';
import '../runtime/nsg_messenger_config.dart';
import '../settings/nsg_messenger_settings.dart';
import '../theme/nsg_messenger_theme.dart';
import 'demo_fixtures.dart';

/// **TASK22-Phase2 Chunk 2 PART C**: in-memory backing store used by
/// `NsgMessenger.initDemo`. Lookup by `roomId` for messages, plus
/// pre-built `RoomSummary` / `RoomDetails` derived from
/// [DemoRoomFixture].
///
/// **NOT for production use.** Public only because `NsgMessenger`
/// (entry-point) needs to construct it from `lib/src/nsg_messenger.dart`.
@immutable
class DemoRuntimeData {
  const DemoRuntimeData._({
    required this.summaries,
    required this.details,
    required this.messagesByRoom,
    required this.selfMessengerUserId,
    required this.selfMatrixUserId,
  });

  /// All rooms, including archived (the server-side filter is emulated
  /// in `_listRooms`).
  final List<RoomSummary> summaries;

  /// Per-room `RoomDetails` (used by `rooms.get(...)` and ChatScreen
  /// participant fetch).
  final Map<int, RoomDetails> details;

  /// DESC-sorted `MessengerMessage` list per `roomId`. Empty list for
  /// rooms with no fixtures.
  final Map<int, List<MessengerMessage>> messagesByRoom;

  /// Hardcoded self identity for demo controllers (see
  /// `NsgMessenger.initDemo` doc).
  final int selfMessengerUserId;
  final String selfMatrixUserId;

  /// Build a [DemoRuntimeData] from designer-facing fixtures. Converts
  /// each [DemoRoomFixture] into a `RoomSummary` + `RoomDetails` pair
  /// and each [DemoMessageFixture] into a `MessengerMessage`. Returns
  /// the bundle the [installDemoRuntime] consumer expects.
  factory DemoRuntimeData.fromFixtures({
    required List<DemoRoomFixture> rooms,
    required List<DemoMessageFixture> messages,
    required int selfMessengerUserId,
    required String selfMatrixUserId,
  }) {
    // Hardcoded peer participant alongside `self` — needed for
    // `RoomDetails.participants` to contain >= 1 non-self entry so the
    // chat screen renders peer names correctly.
    final selfParticipant = RoomParticipant(
      messengerUserId: selfMessengerUserId,
      matrixUserId: selfMatrixUserId,
      displayName: 'You',
      role: RoomMemberRole.owner,
    );
    final peerParticipant = RoomParticipant(
      messengerUserId: -2,
      matrixUserId: '@demo-peer:demo',
      displayName: 'Demo peer',
      role: RoomMemberRole.member,
    );

    final summaries = <RoomSummary>[];
    final details = <int, RoomDetails>{};

    for (final r in rooms) {
      summaries.add(_summaryFromFixture(r));
      details[r.id] = _detailsFromFixture(
        r,
        participants: [selfParticipant, peerParticipant],
      );
    }

    final messagesByRoom = <int, List<MessengerMessage>>{};
    for (final r in rooms) {
      messagesByRoom[r.id] = <MessengerMessage>[];
    }
    for (final m in messages) {
      final bucket = messagesByRoom[m.roomId];
      if (bucket == null) continue; // orphan — silently dropped.
      bucket.add(
        MessengerMessage(
          matrixEventId: m.eventId,
          roomId: m.roomId,
          matrixRoomId: '!demo-${m.roomId}:demo',
          senderMessengerUserId: m.isOwn ? selfMessengerUserId : -2,
          senderMatrixUserId: m.isOwn ? selfMatrixUserId : '@demo-peer:demo',
          msgType: 'm.text',
          body: m.body,
          serverTimestamp: m.sentAt.toUtc(),
        ),
      );
    }
    // DESC sort (newest first) — matches Matrix `dir=b` page order.
    for (final list in messagesByRoom.values) {
      list.sort((a, b) => b.serverTimestamp.compareTo(a.serverTimestamp));
    }

    return DemoRuntimeData._(
      summaries: summaries,
      details: details,
      messagesByRoom: messagesByRoom,
      selfMessengerUserId: selfMessengerUserId,
      selfMatrixUserId: selfMatrixUserId,
    );
  }

  static RoomSummary _summaryFromFixture(DemoRoomFixture r) {
    return RoomSummary(
      id: r.id,
      name: r.name,
      avatarUrl: r.avatarUrl,
      lastMessagePreview: r.lastMessagePreview,
      lastMessageAt: r.lastMessageAt?.toUtc(),
      unreadCount: r.unreadCount,
      archived: r.archived,
      muted: r.mutedUntil != null && r.mutedUntil!.isAfter(DateTime.now()),
      roomType: _roomTypeFromString(r.roomType),
    );
  }

  static RoomDetails _detailsFromFixture(
    DemoRoomFixture r, {
    required List<RoomParticipant> participants,
  }) {
    return RoomDetails(
      id: r.id,
      matrixRoomId: '!demo-${r.id}:demo',
      name: r.name,
      avatarUrl: r.avatarUrl,
      lastMessagePreview: r.lastMessagePreview,
      lastMessageAt: r.lastMessageAt?.toUtc(),
      unreadCount: r.unreadCount,
      archived: r.archived,
      muted: r.mutedUntil != null && r.mutedUntil!.isAfter(DateTime.now()),
      roomType: _roomTypeFromString(r.roomType),
      participants: participants,
      totalParticipants: participants.length,
      viewerRole: RoomMemberRole.owner,
    );
  }

  static RoomType _roomTypeFromString(String key) {
    switch (key) {
      case 'direct':
        return RoomType.direct;
      case 'product':
        return RoomType.productRoom;
      case 'support':
        return RoomType.support;
      default:
        return RoomType.group;
    }
  }
}

/// **TASK22-Phase2 Chunk 2 PART C**: wires the [DemoRuntimeData] into
/// the global `MessengerRuntime` singleton. Bypasses real Client +
/// session manager + WebSocket; uses the existing `attachWithRpcs` /
/// `attachWithFactory` test seams to plug in-memory fakes.
///
/// **NOT for production use.** Throws [StateError] if the runtime is
/// already initialised (mirrors `NsgMessenger.init`'s contract — call
/// `dispose()` first if you really want to swap modes mid-app).
Future<void> installDemoRuntime({
  required DemoRuntimeData data,
  required NsgMessengerTheme theme,
  required NsgMessengerLocale locale,
  required NsgMessengerConfig? config,
}) async {
  final runtime = MessengerRuntime.instance;
  if (runtime.isInitialized) {
    throw StateError(
      'NsgMessenger.initDemo() called after init() / initDemo(). '
      'Call NsgMessenger.dispose() first if you really want to '
      'switch runtime modes (demo mode is not for production use).',
    );
  }

  // Idempotent — matches what `MessengerRuntime.init` does.
  registerTimeagoLocales();

  // Build a never-completing session-state stream (controller stays
  // open for the lifetime of the demo) — `MessengerEventBus` needs
  // *something* and will sit on it forever waiting for emits.
  final sessionStateCtl = StreamController<MessengerSessionState>.broadcast();

  // Demo event stream: never emits real events. Broadcast so multiple
  // listeners (Rooms + per-screen subscriptions) are fine.
  final demoEventCtl = StreamController<MessengerEvent>.broadcast();

  final eventBus = MessengerEventBus.attachWithFactory(
    streamFactory: () => demoEventCtl.stream,
    sessionStateStream: sessionStateCtl.stream,
  );

  final rooms = NsgMessengerRooms.attachWithRpcs(
    listRpc:
        ({
          int? productId,
          RoomState? state,
          String? search,
          bool? includeArchived,
          required int limit,
          String? cursor,
        }) async {
          var out = data.summaries;
          if (includeArchived != true) {
            out = out.where((r) => !r.archived).toList(growable: false);
          } else {
            // "All" or "Archived" tabs — server returns all; SDK post-
            // filters. Just pass through.
            out = List.of(out);
          }
          if (search != null && search.isNotEmpty) {
            final q = search.toLowerCase();
            out = out
                .where((r) => (r.name ?? '').toLowerCase().contains(q))
                .toList(growable: false);
          }
          return out;
        },
    getRpc: ({required int roomId}) async {
      final d = data.details[roomId];
      if (d == null) {
        throw StateError('Demo: room $roomId not found in fixtures.');
      }
      return d;
    },
    createDirectRpc: _readOnly,
    createGroupRpc: _readOnlyGroup,
    getOrCreateProductRoomRpc: _readOnlyProduct,
    openSupportChatRpc: _readOnlySupport,
    muteRoomRpc:
        ({
          required int roomId,
          DateTime? mutedUntil,
          int? muteForSeconds,
        }) async {},
    unmuteRoomRpc: ({required int roomId}) async {},
    archiveRoomRpc: ({required int roomId}) async {},
    unarchiveRoomRpc: ({required int roomId}) async {},
    leaveRoomRpc: ({required int roomId}) async {},
    getAvailableProductsRpc: () async => const <Product>[],
    kickUserRpc:
        ({
          required int roomId,
          required int targetMessengerUserId,
          String? reason,
        }) async {},
    banUserRpc:
        ({
          required int roomId,
          required int targetMessengerUserId,
          String? reason,
        }) async {},
    unbanUserRpc:
        ({required int roomId, required int targetMessengerUserId}) async {},
    setRoomMemberRoleRpc:
        ({
          required int roomId,
          required int targetMessengerUserId,
          required RoomMemberRole newRole,
        }) async {},
    listBannedUsersRpc: ({required int roomId}) async =>
        const <RoomParticipant>[],
    eventBus: eventBus,
  );

  final settings = NsgMessengerSettings.attachWithRpcs(
    getRpc: () async => NotificationSettings(showMessagePreview: true),
    setRpc:
        ({
          required bool showMessagePreview,
          bool? sendReadReceipts,
          bool? discoverable,
        }) async {},
  );

  // Hand off to the runtime's package-private installer.
  runtime.installDemo(
    rooms: rooms,
    settings: settings,
    eventBus: eventBus,
    sessionStateController: sessionStateCtl,
    demoEventController: demoEventCtl,
    theme: theme,
    locale: locale,
    config: config,
  );
}

/// Build a [MessagesRpc] backed by the demo fixtures. ChatScreen demo
/// flow constructs a `MessagesController` directly with this RPC and
/// passes it via `controllerOverride` — bypassing the
/// `MessengerRuntime.client` getter (which has no real `Client` in
/// demo mode).
MessagesRpc buildDemoMessagesRpc(DemoRuntimeData data) {
  return _DemoMessagesRpc(data);
}

class _DemoMessagesRpc implements MessagesRpc {
  _DemoMessagesRpc(this._data);
  final DemoRuntimeData _data;

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async {
    final all = _data.messagesByRoom[roomId] ?? const <MessengerMessage>[];
    // Single-page only — demo doesn't need pagination tokens.
    return MessengerMessageListPage(
      messages: List.of(all.take(limit)),
      nextToken: null,
      prevToken: null,
    );
  }

  @override
  Future<MessengerMessage> sendMessage({
    required int roomId,
    required String body,
    required String msgType,
    required String clientTxnId,
    AttachmentRef? attachment,
    String? replyToMatrixEventId,
    List<int>? mentionedMessengerUserIds,
  }) {
    throw UnimplementedError(
      'NsgMessenger.initDemo: sendMessage is disabled in demo mode.',
    );
  }

  @override
  Future<AttachmentRef> uploadAttachment({
    required ByteData bytes,
    required String mimeType,
    required String originalFilename,
  }) {
    throw UnimplementedError(
      'NsgMessenger.initDemo: uploadAttachment is disabled in demo mode.',
    );
  }

  @override
  Future<AttachmentBytes> downloadAttachmentThumbnail({
    required String mxcUrl,
    int? width,
    int? height,
  }) {
    throw UnimplementedError(
      'NsgMessenger.initDemo: thumbnail download is disabled in demo mode.',
    );
  }

  @override
  Future<AttachmentBytes> downloadAttachment({required String mxcUrl}) {
    throw UnimplementedError(
      'NsgMessenger.initDemo: attachment download is disabled in demo mode.',
    );
  }

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
  }) async {
    // Silent no-op so the auto-mark-as-read in ChatScreen does not
    // throw and clog the console.
    return true;
  }

  @override
  Future<MessengerMessage> editMessage({
    required int roomId,
    required String matrixEventId,
    required String newBody,
    List<int>? mentionedMessengerUserIds,
  }) {
    throw UnimplementedError(
      'NsgMessenger.initDemo: editMessage is disabled in demo mode.',
    );
  }

  @override
  Future<void> deleteMessage({
    required int roomId,
    required String matrixEventId,
  }) {
    throw UnimplementedError(
      'NsgMessenger.initDemo: deleteMessage is disabled in demo mode.',
    );
  }

  @override
  Future<void> sendTyping({required int roomId, required bool typing}) async {
    // Demo: silent no-op (typing indicator не имеет смысла в
    // single-user demo runtime).
  }

  @override
  Future<String> sendReaction({
    required int roomId,
    required String targetEventId,
    required String key,
  }) async {
    // Demo: реакции отключены — no-op, фиктивный event id.
    return 'demo-reaction';
  }

  @override
  Future<void> removeReaction({
    required int roomId,
    required String reactionEventId,
  }) async {
    // Demo: no-op.
  }

  @override
  Future<List<MessengerMessage>> searchMessages({
    required int roomId,
    required String query,
    int limit = 50,
  }) async {
    // Demo: empty results (search не имеет смысла в demo fixtures).
    return const <MessengerMessage>[];
  }

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async {
    // Demo: нет истории реакций в fixtures.
    return const <MessengerEvent>[];
  }

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async {
    // Demo: нет persisted read-receipts в fixtures.
    return const <MessengerEvent>[];
  }
}

// ───────── shared read-only fallbacks for `NsgMessengerRooms` ──────

Future<RoomDetails> _readOnly({required int peerMessengerUserId}) {
  throw UnimplementedError(
    'NsgMessenger.initDemo: createDirect is disabled in demo mode.',
  );
}

Future<RoomDetails> _readOnlyGroup({
  required String name,
  required List<int> memberMessengerUserIds,
  int? productId,
}) {
  throw UnimplementedError(
    'NsgMessenger.initDemo: createGroup is disabled in demo mode.',
  );
}

Future<RoomDetails> _readOnlyProduct({
  required String productExternalKey,
  required String entityType,
  required String entityId,
  required RoomType roomType,
}) {
  throw UnimplementedError(
    'NsgMessenger.initDemo: getOrCreateProductRoom is disabled in demo mode.',
  );
}

Future<RoomDetails> _readOnlySupport({
  required String productExternalKey,
  required String contextId,
}) {
  throw UnimplementedError(
    'NsgMessenger.initDemo: openSupportChat is disabled in demo mode.',
  );
}
