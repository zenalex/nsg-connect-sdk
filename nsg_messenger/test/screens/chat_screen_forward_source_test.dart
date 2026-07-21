import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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

/// **Issue #41**: тап по шапке «Переслано от X» в [ChatScreen].
///
/// Проверяем именно ПРОМАХИ — они здесь штатные, а не аварийные:
///   * комната-первоисточник недоступна (переслали из чужого чата) —
///     понятный отказ вместо пустого экрана или падения;
///   * источник в этой же комнате — переход внутри экрана, без похода на
///     сервер за чужой комнатой.
const _room = 1;

ByteData _content(Map<String, dynamic> m) =>
    ByteData.sublistView(Uint8List.fromList(utf8.encode(jsonEncode(m))));

MessengerMessage _forwardedMsg({required int sourceRoomId}) => MessengerMessage(
  matrixEventId: 'e1',
  roomId: _room,
  matrixRoomId: '!r:t',
  senderMessengerUserId: 2, // peer (self=42)
  senderMatrixUserId: '@peer:t',
  msgType: 'm.text',
  body: 'forwarded body',
  serverTimestamp: DateTime.utc(2026, 1, 1, 12),
  senderDisplayName: 'Peer',
  content: _content({
    'msgtype': 'm.text',
    'nsg.forwarded_from': 'Alice',
    'nsg.forwarded_room_id': sourceRoomId,
    'nsg.forwarded_event_id': r'$orig',
  }),
);

class _FakeRpc implements MessagesRpc {
  List<MessengerMessage> page = [];

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(messages: page);

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const [];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const [];

  @override
  Future<List<MessengerMessage>> listPinnedMessages({
    required int roomId,
  }) async => const <MessengerMessage>[];

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
  }) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

  Future<MessagesController> pumpChat(
    WidgetTester tester, {
    required int sourceRoomId,
    Future<void> Function(int roomId)? probe,
  }) async {
    final rpc = _FakeRpc()..page = [_forwardedMsg(sourceRoomId: sourceRoomId)];
    final eventCtrl = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: _room,
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
      wrap(
        ChatScreen(
          roomId: _room,
          controllerOverride: controller,
          forwardSourceProbeOverride: probe,
        ),
      ),
    );
    await tester.pump(); // init
    await tester.pump(); // Ready
    return controller;
  }

  testWidgets('недоступная комната-источник → понятный отказ, экран жив', (
    tester,
  ) async {
    var probed = 0;
    await pumpChat(
      tester,
      sourceRoomId: 77,
      probe: (roomId) async {
        probed++;
        expect(roomId, 77);
        // Ровно то, что вернёт сервер, если нас нет в исходной комнате.
        throw RoomUnavailableException();
      },
    );

    expect(find.text('Forwarded from Alice'), findsOneWidget);
    await tester.tap(find.text('Forwarded from Alice'));
    await tester.pumpAndSettle();

    expect(probed, 1);
    expect(find.text('Source chat is unavailable'), findsOneWidget);
    // Никуда не ушли и не упали — исходный чат на месте.
    expect(find.text('forwarded body'), findsOneWidget);
  });

  testWidgets(
    'источник в этой же комнате → скролл на месте, без похода на сервер',
    (tester) async {
      var probed = 0;
      await pumpChat(tester, sourceRoomId: _room, probe: (_) async => probed++);

      await tester.tap(find.text('Forwarded from Alice'));
      await tester.pumpAndSettle();

      expect(probed, 0, reason: 'своя комната — проверять доступ незачем');
      expect(find.text('Source chat is unavailable'), findsNothing);
      expect(find.text('forwarded body'), findsOneWidget);
    },
  );
}
