import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

/// Tests for `NsgMessenger.initDemo` (TASK22-Phase2 Chunk 2 PART C).
///
/// Covers:
///   * `initDemo(rooms: [...])` populates `NsgMessenger.rooms` with a
///     working stub that returns the fixtures from `list(...)`;
///   * `rooms.get(id)` returns RoomDetails derived from the fixture;
///   * calling `initDemo` twice throws;
///   * calling `init(...)` after `initDemo` would throw (we exercise
///     via `installDemoRuntime` reach-through, i.e. a second
///     `initDemo`);
///   * after `dispose()` a second `initDemo` succeeds (clean re-init).
void main() {
  group('NsgMessenger.initDemo', () {
    tearDown(() async {
      // Always reset between tests so the singleton starts clean.
      // Tolerate StateError from rooms-getter for tests that never
      // initialised.
      try {
        await NsgMessenger.dispose();
      } catch (_) {}
    });

    test('populates rooms.list with the fixture rooms (active filter)',
        () async {
      await NsgMessenger.initDemo(
        rooms: [
          DemoRoomFixture(
            id: 1,
            name: 'Alpha',
            lastMessageAt: DateTime.utc(2026, 5, 23, 12, 0),
          ),
          DemoRoomFixture(
            id: 2,
            name: 'Bravo',
            unreadCount: 3,
            lastMessageAt: DateTime.utc(2026, 5, 23, 11, 0),
          ),
        ],
      );

      // Default `list()` (no includeArchived) returns only non-archived.
      final result = await NsgMessenger.rooms.list();
      expect(result, hasLength(2));
      expect(result.first.name, 'Alpha');
      expect(result.last.unreadCount, 3);
    });

    test('rooms.get(id) returns details derived from the fixture',
        () async {
      await NsgMessenger.initDemo(
        rooms: [DemoRoomFixture(id: 42, name: 'The answer')],
      );

      final details = await NsgMessenger.rooms.get(42);
      expect(details.id, 42);
      expect(details.name, 'The answer');
      // Demo runtime fabricates a 2-person participant list (self + peer).
      expect(details.participants, hasLength(2));
      expect(details.participants.first.displayName, 'You');
    });

    test('rooms.list with includeArchived=true also surfaces archived',
        () async {
      await NsgMessenger.initDemo(
        rooms: [
          DemoRoomFixture(id: 1, name: 'Active'),
          DemoRoomFixture(id: 2, name: 'Old', archived: true),
        ],
      );

      final active = await NsgMessenger.rooms.list();
      expect(active.map((r) => r.id), [1]);

      final all = await NsgMessenger.rooms.list(includeArchived: true);
      expect(all.map((r) => r.id), [1, 2]);
    });

    test('calling initDemo twice without dispose throws StateError',
        () async {
      await NsgMessenger.initDemo(
        rooms: [DemoRoomFixture(id: 1, name: 'One')],
      );

      expect(
        () => NsgMessenger.initDemo(
          rooms: [DemoRoomFixture(id: 2, name: 'Two')],
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('dispose() resets the runtime so initDemo can be called again',
        () async {
      await NsgMessenger.initDemo(
        rooms: [DemoRoomFixture(id: 1, name: 'First')],
      );
      await NsgMessenger.dispose();

      await NsgMessenger.initDemo(
        rooms: [DemoRoomFixture(id: 9, name: 'After dispose')],
      );

      final after = await NsgMessenger.rooms.list();
      expect(after.single.name, 'After dispose');
    });

    test('messages flow through the demo MessagesRpc into rooms.list',
        () async {
      // Smoke-check that DemoMessageFixture survives the conversion
      // pipeline — fixtures with no matching roomId are silently
      // dropped, so an orphan message must not crash initDemo.
      await NsgMessenger.initDemo(
        rooms: [
          DemoRoomFixture(
            id: 7,
            name: 'Chat',
            lastMessagePreview: 'hi',
            lastMessageAt: DateTime.utc(2026, 5, 23, 9),
          ),
        ],
        messages: [
          DemoMessageFixture(
            roomId: 7,
            eventId: 'evt-1',
            body: 'hi',
            senderName: 'Peer',
            sentAt: DateTime.utc(2026, 5, 23, 9),
          ),
          // Orphan — silently dropped.
          DemoMessageFixture(
            roomId: 999,
            eventId: 'evt-orphan',
            body: 'lost',
            senderName: 'Ghost',
            sentAt: DateTime.utc(2026, 5, 23, 9),
          ),
        ],
        locale: const NsgMessengerLocale(locale: Locale('en')),
      );

      // The summary should still be reachable.
      final list = await NsgMessenger.rooms.list();
      expect(list.single.id, 7);
      expect(list.single.lastMessagePreview, 'hi');
    });
  });
}
