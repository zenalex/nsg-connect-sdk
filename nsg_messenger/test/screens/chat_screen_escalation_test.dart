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

/// **TASK45 фаза 2**: widget-тесты видимости и действия кнопки
/// «Обратиться к разработчикам» в [ChatScreen].
///
/// Покрывает:
///   * кнопка видна ТОЛЬКО для объектовых чатов (productRoom +
///     productEntityType='object'), не видна для group/direct/support;
///   * тап по пункту меню вызывает escalateToSupportTeam(roomId) и
///     показывает снекбар «Команда NSG подключена».
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

  RoomDetails details({
    required RoomType roomType,
    String? productEntityType,
    bool canEscalateSupport = false,
  }) => RoomDetails(
    id: 7,
    matrixRoomId: '!r:t',
    name: 'ЖК Северный',
    unreadCount: 0,
    archived: false,
    muted: false,
    productEntityType: productEntityType,
    roomType: roomType,
    participants: const [],
    totalParticipants: 2,
    viewerRole: RoomMemberRole.member,
    canEscalateSupport: canEscalateSupport,
  );

  Future<MessagesController> pumpChat(
    WidgetTester tester, {
    required RoomDetails roomDetails,
    EscalateOverride? escalate,
    EscalateSupportOverride? escalateSupport,
  }) async {
    final rpc = _FakeRpc();
    rpc.listMessagesHandler = (_, _, _) =>
        Future.value(MessengerMessageListPage(messages: const []));
    final eventCtrl = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: 7,
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
          roomId: 7,
          controllerOverride: controller,
          roomDetailsOverride: roomDetails,
          escalateOverride: escalate,
          escalateSupportOverride: escalateSupport,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return controller;
  }

  testWidgets('объектовый чат → кнопка «Обратиться к разработчикам» видна', (
    tester,
  ) async {
    await pumpChat(
      tester,
      roomDetails: details(
        roomType: RoomType.productRoom,
        productEntityType: 'object',
      ),
    );
    expect(find.byKey(const Key('chatOverflowMenu')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chatOverflowMenu')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Contact developers'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('обычная группа → кнопки эскалации НЕТ', (tester) async {
    await pumpChat(tester, roomDetails: details(roomType: RoomType.group));
    expect(find.byKey(const Key('chatOverflowMenu')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('productRoom без entityType=object → кнопки НЕТ', (tester) async {
    await pumpChat(
      tester,
      roomDetails: details(
        roomType: RoomType.productRoom,
        productEntityType: 'support_ticket',
      ),
    );
    expect(find.byKey(const Key('chatOverflowMenu')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('тап → escalateToSupportTeam(roomId) + снекбар', (tester) async {
    final calls = <int>[];
    await pumpChat(
      tester,
      roomDetails: details(
        roomType: RoomType.productRoom,
        productEntityType: 'object',
      ),
      escalate: ({required int roomId}) async {
        calls.add(roomId);
      },
    );
    await tester.tap(find.byKey(const Key('chatOverflowMenu')));
    await tester.pumpAndSettle(); // menu open animation settles
    await tester.tap(find.byKey(const Key('escalateToDevelopersItem')));
    await tester.pump(); // menu close + action fire
    await tester.pump(); // snackbar

    expect(calls, [7], reason: 'escalateToSupportTeam вызван с roomId=7');
    expect(find.text('NSG team connected'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  // ── TASK48: кнопка «Позвать старшего» (тир-эскалация support-чата) ──

  testWidgets('support-чат + canEscalateSupport → пункт «Позвать старшего»', (
    tester,
  ) async {
    await pumpChat(
      tester,
      roomDetails: details(
        roomType: RoomType.support,
        productEntityType: 'support_ticket',
        canEscalateSupport: true,
      ),
    );
    expect(find.byKey(const Key('chatOverflowMenu')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chatOverflowMenu')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Call senior operator'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('support-чат без canEscalateSupport → кнопки эскалации НЕТ', (
    tester,
  ) async {
    await pumpChat(
      tester,
      roomDetails: details(
        roomType: RoomType.support,
        productEntityType: 'support_ticket',
      ),
    );
    expect(find.byKey(const Key('chatOverflowMenu')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('тап + подключили → escalateSupportRoom(roomId) + успех', (
    tester,
  ) async {
    final calls = <int>[];
    await pumpChat(
      tester,
      roomDetails: details(
        roomType: RoomType.support,
        productEntityType: 'support_ticket',
        canEscalateSupport: true,
      ),
      escalateSupport: ({required int roomId}) async {
        calls.add(roomId);
        // Кого-то подключили → успех.
        return EscalationResult(
          roomId: roomId,
          addedMessengerUserIds: const [99],
          alreadyPresent: 0,
          systemMessagePosted: true,
        );
      },
    );
    await tester.tap(find.byKey(const Key('chatOverflowMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('escalateSupportItem')));
    await tester.pump();
    await tester.pump();

    expect(calls, [7], reason: 'escalateSupportRoom вызван с roomId=7');
    expect(find.text('Senior operator connected'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  // **Review fix #5**: no-op результат (пустой addedMessengerUserIds) →
  // НЕ ложный успех, а нейтральный «некого подключать».
  testWidgets('тап + no-op результат → снекбар «некого», не успех', (
    tester,
  ) async {
    await pumpChat(
      tester,
      roomDetails: details(
        roomType: RoomType.support,
        productEntityType: 'support_ticket',
        canEscalateSupport: true,
      ),
      escalateSupport: ({required int roomId}) async => EscalationResult(
        roomId: roomId,
        addedMessengerUserIds: const [], // no-op (гонка / нет тира / откат)
        alreadyPresent: 0,
        systemMessagePosted: false,
      ),
    );
    await tester.tap(find.byKey(const Key('chatOverflowMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('escalateSupportItem')));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('No one to escalate — no higher tier or already here'),
      findsOneWidget,
    );
    expect(find.text('Senior operator connected'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _FakeRpc implements MessagesRpc {
  Future<MessengerMessageListPage> Function(int, String?, int)?
  listMessagesHandler;

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) {
    final h = listMessagesHandler;
    if (h == null) throw StateError('listMessagesHandler not set');
    return h(roomId, fromToken, limit);
  }

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
  }) async => true;

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const <MessengerEvent>[];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const <MessengerEvent>[];

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<void> sendTyping({required int roomId, required bool typing}) async {}

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '_FakeRpc: only load-path RPCs mocked (${invocation.memberName})',
  );

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
