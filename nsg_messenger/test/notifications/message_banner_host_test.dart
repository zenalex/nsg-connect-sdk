/// **issue #79 — плашка о новом сообщении поверх приложения.**
///
/// Дыра, оставшаяся после #78: пока человек в приложении, пуш подавляется
/// намеренно (он подтвердил приём), и сообщение в ДРУГОМ чате не подавало
/// ни звука. Здесь проверяются правила показа — прежде всего те, что
/// защищают от ДВУХ уведомлений об одном сообщении.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/notifications/message_banner_host.dart';
import 'package:nsg_messenger/src/runtime/active_room.dart';

const kSelf = 7;
const kPeer = 9;
const kRoom = 42;

void main() {
  late StreamController<MessengerEvent> events;
  late _FakeSource source;

  setUp(() {
    events = StreamController<MessengerEvent>.broadcast();
    source = _FakeSource(events.stream);
    ActiveRoom.reset();
  });

  tearDown(() async {
    await events.close();
    ActiveRoom.reset();
  });

  MessengerEvent message({
    int roomId = kRoom,
    int? senderId = kPeer,
    String body = 'привет',
    String? senderName,
    bool mentionsRoom = false,
    List<int>? mentions,
    String eventId = '\$ev1',
  }) => MessengerEvent(
    eventType: MessengerEventType.messageCreated,
    serverTimestamp: DateTime.now().toUtc(),
    roomId: roomId,
    matrixRoomId: '!r:t',
    message: MessengerMessage(
      matrixEventId: eventId,
      roomId: roomId,
      matrixRoomId: '!r:t',
      senderMessengerUserId: senderId,
      senderMatrixUserId: '@peer:t',
      senderDisplayName: senderName,
      msgType: 'm.text',
      body: body,
      serverTimestamp: DateTime.now().toUtc(),
      mentionedRoom: mentionsRoom,
      mentionedMessengerUserIds: mentions,
    ),
  );

  Future<int?> pumpHost(
    WidgetTester tester, {
    AppLifecycleState lifecycle = AppLifecycleState.resumed,
  }) async {
    int? opened;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          NsgL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: NsgL10n.supportedLocales,
        home: MessageBannerHost(
          source: source,
          lifecycleProbe: () => lifecycle,
          onOpenRoom: (roomId, {eventId}) => opened = roomId,
          child: const Scaffold(body: Text('приложение')),
        ),
      ),
    );
    await tester.pump();
    return opened;
  }

  Future<void> deliver(WidgetTester tester, MessengerEvent e) async {
    events.add(e);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('сообщение из другого чата показывает плашку', (tester) async {
    await pumpHost(tester);
    await deliver(tester, message());
    expect(find.text('Общий чат'), findsOneWidget);
    expect(find.text('привет'), findsOneWidget);
  });

  testWidgets('открытый чат плашкой не дублируется', (tester) async {
    // Сообщение и так появилось на глазах — плашка поверх него шум.
    ActiveRoom.claim(kRoom);
    await pumpHost(tester);
    await deliver(tester, message());
    expect(find.text('привет'), findsNothing);
  });

  testWidgets('своё сообщение не показывается', (tester) async {
    await pumpHost(tester);
    await deliver(tester, message(senderId: kSelf, body: 'моё'));
    expect(find.text('моё'), findsNothing);
  });

  testWidgets('неактивное приложение молчит — там сработает пуш', (
    tester,
  ) async {
    // Главная защита от двух уведомлений об одном сообщении.
    for (final state in [
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
    ]) {
      await pumpHost(tester, lifecycle: state);
      await deliver(tester, message(body: 'фон-$state'));
      expect(find.text('фон-$state'), findsNothing, reason: '$state');
    }
  });

  testWidgets('заглушенный чат молчит', (tester) async {
    source.muted = true;
    await pumpHost(tester);
    await deliver(tester, message(body: 'тихо'));
    expect(find.text('тихо'), findsNothing);
  });

  testWidgets('упоминание пробивает заглушенный чат', (tester) async {
    // То же правило, что у пуша: не беспокоить чатом — не значит «и мной».
    source.muted = true;
    await pumpHost(tester);
    await deliver(tester, message(body: 'ты тут?', mentions: [kSelf]));
    expect(find.text('ты тут?'), findsOneWidget);
  });

  testWidgets('превью выключено — текста нет', (tester) async {
    source.preview = false;
    await pumpHost(tester);
    await deliver(tester, message(body: 'секрет'));
    expect(find.text('секрет'), findsNothing);
    expect(find.text('Новое сообщение'), findsOneWidget);
  });

  testWidgets('в группе видно автора', (tester) async {
    await pumpHost(tester);
    await deliver(tester, message(senderName: 'Пётр', body: 'всем привет'));
    expect(find.text('Пётр: всем привет'), findsOneWidget);
  });

  testWidgets('в личной переписке автора не дублируем', (tester) async {
    // Имя собеседника и так стоит заголовком.
    source.roomType = RoomType.direct;
    await pumpHost(tester);
    await deliver(tester, message(senderName: 'Пётр', body: 'привет'));
    expect(find.text('привет'), findsOneWidget);
  });

  testWidgets('сообщение без текста показывается как вложение', (tester) async {
    await pumpHost(tester);
    await deliver(tester, message(body: '  '));
    expect(find.text('Вложение'), findsOneWidget);
  });

  testWidgets('тап открывает чат и убирает плашку', (tester) async {
    int? opened;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          NsgL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: NsgL10n.supportedLocales,
        home: MessageBannerHost(
          source: source,
          lifecycleProbe: () => AppLifecycleState.resumed,
          onOpenRoom: (roomId, {eventId}) => opened = roomId,
          child: const Scaffold(body: Text('приложение')),
        ),
      ),
    );
    await tester.pump();
    await deliver(tester, message());
    await tester.tap(find.text('привет'));
    await tester.pumpAndSettle();
    expect(opened, kRoom);
    expect(find.text('привет'), findsNothing);
  });

  testWidgets('плашка сама уходит', (tester) async {
    await pumpHost(tester);
    await deliver(tester, message());
    expect(find.text('привет'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('привет'), findsNothing);
  });

  testWidgets('не-сообщения игнорируются', (tester) async {
    await pumpHost(tester);
    await deliver(
      tester,
      MessengerEvent(
        eventType: MessengerEventType.typingChanged,
        serverTimestamp: DateTime.now().toUtc(),
        roomId: kRoom,
        matrixRoomId: '!r:t',
      ),
    );
    expect(find.byType(Material), findsWidgets);
    expect(find.text('Общий чат'), findsNothing);
  });
}

class _FakeSource implements MessageBannerSource {
  _FakeSource(this.events);

  @override
  final Stream<MessengerEvent> events;

  bool muted = false;
  bool preview = true;
  RoomType roomType = RoomType.group;

  @override
  int? get selfMessengerUserId => kSelf;

  @override
  Future<RoomSummary?> room(int roomId) async => RoomSummary(
    id: roomId,
    name: 'Общий чат',
    unreadCount: 0,
    archived: false,
    muted: muted,
    roomType: roomType,
  );

  @override
  Future<bool> showPreview() async => preview;
}
