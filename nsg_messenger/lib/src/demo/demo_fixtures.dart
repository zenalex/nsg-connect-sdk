/// **TASK22-Phase2 Chunk 2 PART C**: data fixtures for headless demo
/// mode (`NsgMessenger.initDemo`). Designer-friendly DTOs that don't
/// expose the Serverpod-generated types — keeps the demo wiring trivial.
///
/// **NOT for production use.** These types only exist so a designer can
/// hand the SDK a list of rooms + messages to render without booting
/// the real backend.
library;

/// One room fixture for the demo runtime. Mirrors the subset of
/// `RoomSummary` / `RoomDetails` fields that the SDK widgets actually
/// render in the chat list + chat screen.
class DemoRoomFixture {
  const DemoRoomFixture({
    required this.id,
    required this.name,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.avatarUrl,
    this.archived = false,
    this.mutedUntil,
    this.roomType = 'group',
  });

  /// SDK-internal numeric room id. Must be unique across all fixtures.
  final int id;

  /// Display name (group title or peer name for direct chats).
  final String name;

  /// Short last-message text shown under the room name in the list.
  final String? lastMessagePreview;

  /// Timestamp of the last message — drives the "5 min ago" line in
  /// the tile.
  final DateTime? lastMessageAt;

  /// Number of unread messages — drives the badge.
  final int unreadCount;

  /// Optional avatar URL (currently unused by the demo renderer — kept
  /// for completeness; real assets are not loaded in demo mode).
  final String? avatarUrl;

  /// `true` -> room appears under the "Archived" tab only.
  final bool archived;

  /// If non-null and in the future, the room is rendered as muted.
  final DateTime? mutedUntil;

  /// Free-form room type tag. Currently accepted: `'group'`, `'direct'`,
  /// `'product'`. Anything else falls back to `group`.
  final String roomType;
}

/// One message fixture inside a [DemoRoomFixture].
class DemoMessageFixture {
  const DemoMessageFixture({
    required this.roomId,
    required this.eventId,
    required this.body,
    required this.senderName,
    required this.sentAt,
    this.isOwn = false,
  });

  /// `DemoRoomFixture.id` this message belongs to. Messages with no
  /// matching room are ignored.
  final int roomId;

  /// Stable per-message id (used as Matrix `eventId` internally for
  /// dedup). Must be unique across all messages.
  final String eventId;

  /// Body text rendered inside the bubble.
  final String body;

  /// Display name shown above the bubble (peer messages only).
  final String senderName;

  /// Server timestamp — drives bubble ordering and the timestamp label.
  final DateTime sentAt;

  /// `true` -> rendered as own bubble (right-aligned), `false` -> peer.
  final bool isOwn;
}
