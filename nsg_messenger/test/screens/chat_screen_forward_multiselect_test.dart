import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;
import 'package:nsg_messenger/src/screens/chat_screen.dart';

/// Пересылка (мультивыбор) в [ChatScreen]:
///   * «Выбрать» из action-sheet включает режим (селекшн-аппбар + счётчик);
///   * тап по другому пузырю тогглит выбор — счётчик растёт;
///   * иконка «Переслать» зовёт `forwardMessages` (через fake rpc → sendMessage)
///     и выходит из режима выбора.
void main() {
  setUpAll(registerTimeagoLocales);

  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      NsgL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: NsgL10n.supportedLocales,
    home: child,
  );

  testWidgets('Выбрать → режим; тап тогглит; Forward зовёт forwardMessages', (
    tester,
  ) async {
    // Высокий сюрфейс — чтобы action-sheet (реакции + пункты) и пикер чата
    // помещались без RenderFlex-overflow на дефолтном 800×600.
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final rpc = _FakeRpc()
      ..page = [
        _msg(eventId: 'e2', body: 'second'),
        _msg(eventId: 'e1', body: 'first'),
      ];
    final eventCtrl = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: 1,
      rpc: rpc,
      events: eventCtrl.stream,
      selfMessengerUserId: 42,
      selfMatrixUserId: '@self:t',
      clientTxnIdGenerator: () => 'FWD',
    );
    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });

    await tester.pumpWidget(
      wrap(
        ChatScreen(
          roomId: 1,
          controllerOverride: controller,
          forwardRoomsLoaderOverride: () async => [
            RoomSummary(
              id: 99,
              name: 'Target chat',
              unreadCount: 0,
              archived: false,
              muted: false,
              roomType: RoomType.direct,
            ),
          ],
        ),
      ),
    );
    await tester.pump(); // init
    await tester.pump(); // Ready
    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsOneWidget);

    // Long-press первого пузыря → action-sheet → «Select».
    await tester.longPress(find.text('first'));
    await tester.pumpAndSettle();
    expect(find.text('Select'), findsOneWidget);
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    // Режим выбора активен: счётчик «1 selected».
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byKey(const Key('chatSelectionForward')), findsOneWidget);

    // Тап по второму пузырю → тоггл добавляет → «2 selected». warnIfMissed:
    // false — в режиме выбора AbsorbPointer намеренно уводит тап с текста на
    // внешний selection-GestureDetector (он и обрабатывает тоггл).
    await tester.tap(find.text('second'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('2 selected'), findsOneWidget);

    // Forward → пикер чата (loader override) → выбор комнаты. **F1**: пикер
    // мультивыборный — тап по строке тогглит чекбокс, пересылку запускает
    // кнопка подтверждения «Переслать (N)» (единственный FilledButton листа).
    await tester.tap(find.byKey(const Key('chatSelectionForward')));
    await tester.pumpAndSettle();
    expect(find.text('Target chat'), findsOneWidget);
    await tester.tap(find.text('Target chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // forwardMessages → 2 sendMessage в целевую комнату 99 (по времени ASC).
    expect(rpc.forwardSends.length, 2);
    expect(rpc.forwardSends.every((s) => s.roomId == 99), isTrue);
    expect(rpc.forwardSends.map((s) => s.body).toList(), ['first', 'second']);

    // Вышли из режима выбора: селекшн-аппбар исчез, снек «Forwarded».
    expect(find.text('2 selected'), findsNothing);
    expect(find.byKey(const Key('chatSelectionForward')), findsNothing);
    // **F1**: снек показывает число получателей («Forwarded to 1 chat»).
    expect(find.text('Forwarded to 1 chat'), findsOneWidget);
  });

  testWidgets('крестик выходит из режима без пересылки', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final rpc = _FakeRpc()..page = [_msg(eventId: 'e1', body: 'only')];
    final eventCtrl = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: 1,
      rpc: rpc,
      events: eventCtrl.stream,
      selfMessengerUserId: 42,
      selfMatrixUserId: '@self:t',
    );
    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });

    await tester.pumpWidget(
      wrap(ChatScreen(roomId: 1, controllerOverride: controller)),
    );
    await tester.pump();
    await tester.pump();

    await tester.longPress(find.text('only'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chatSelectionClose')));
    await tester.pump();
    expect(find.text('1 selected'), findsNothing);
    expect(rpc.forwardSends, isEmpty);
  });
}

MessengerMessage _msg({
  required String eventId,
  String body = 'msg',
  int roomId = 1,
}) => MessengerMessage(
  matrixEventId: eventId,
  roomId: roomId,
  matrixRoomId: '!r:t',
  senderMessengerUserId: 2, // peer (self=42) → isOwn=false, long-press доступен
  senderMatrixUserId: '@peer:t',
  msgType: 'm.text',
  body: body,
  serverTimestamp: eventId == 'e1'
      ? DateTime.utc(2026, 1, 1, 12, 1)
      : DateTime.utc(2026, 1, 1, 12, 2),
  senderDisplayName: 'Peer',
);

class _FwdSend {
  _FwdSend(this.roomId, this.body);
  final int roomId;
  final String body;
}

class _FakeRpc implements MessagesRpc {
  List<MessengerMessage> page = [];
  final List<_FwdSend> forwardSends = [];

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(messages: page);

  @override
  Future<MessengerMessage> sendMessage({
    required int roomId,
    required String body,
    required String msgType,
    required String clientTxnId,
    AttachmentRef? attachment,
    String? replyToMatrixEventId,
    List<int>? mentionedMessengerUserIds,
    String? albumId,
    String? forwardedFromName,
    int? forwardedFromMessengerUserId,
    int? forwardedFromRoomId,
    String? forwardedFromEventId,
    // TASK82: тред задачи — фейку достаточно принять параметр.
    String? threadId,
  }) async {
    forwardSends.add(_FwdSend(roomId, body));
    return MessengerMessage(
      matrixEventId: 'srv${forwardSends.length}',
      roomId: roomId,
      matrixRoomId: '!r:t',
      senderMatrixUserId: '@self:t',
      senderMessengerUserId: 42,
      msgType: msgType,
      body: body,
      serverTimestamp: DateTime.utc(2026, 2, 2),
      clientTxnId: clientTxnId,
    );
  }

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const [];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const [];

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
  }) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  // #35 pin — заглушки (эти тесты pin не покрывают).
  @override
  Future<List<String>> pinMessage({
    required int roomId,
    required String matrixEventId,
  }) async => const <String>[];

  @override
  Future<List<String>> unpinMessage({
    required int roomId,
    required String matrixEventId,
  }) async => const <String>[];

  @override
  Future<List<MessengerMessage>> listPinnedMessages({required int roomId}) async =>
      const <MessengerMessage>[];
}
