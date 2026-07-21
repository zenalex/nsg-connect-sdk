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

/// **TASK66 / issue #17**: перехват «назад» в телефонном пейджере.
/// `ChatScreen` в рабочем наборе получает [ChatScreen.canNavigateBack] +
/// [ChatScreen.onNavigateBack]. Проверяем единую точку PopScope:
///   * canNavigateBack=true → системный back зовёт onNavigateBack и НЕ
///     покидает экран (возврат в предыдущий чат набора);
///   * canNavigateBack=false → back проходит штатно (экран покидается,
///     onNavigateBack не зовётся).
void main() {
  setUpAll(registerTimeagoLocales);

  final navKey = GlobalKey<NavigatorState>();

  Widget app() => MaterialApp(
    navigatorKey: navKey,
    locale: const Locale('en'),
    localizationsDelegates: const [
      NsgL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: NsgL10n.supportedLocales,
    home: const Scaffold(body: SizedBox.shrink()),
  );

  Future<MessagesController> pushChatScreen(
    WidgetTester tester, {
    required bool canNavigateBack,
    required VoidCallback onNavigateBack,
  }) async {
    final rpc = _FakeRpc();
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

    await tester.pumpWidget(app());
    unawaited(
      navKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            roomId: 1,
            controllerOverride: controller,
            canNavigateBack: canNavigateBack,
            onNavigateBack: onNavigateBack,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
    return controller;
  }

  testWidgets('canNavigateBack=true: back зовёт onNavigateBack, экран остаётся',
      (tester) async {
    var backCalls = 0;
    await pushChatScreen(
      tester,
      canNavigateBack: true,
      onNavigateBack: () => backCalls++,
    );

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue, reason: 'back перехвачен');
    expect(backCalls, 1, reason: 'возврат в предыдущий чат набора');
    expect(find.byType(ChatScreen), findsOneWidget,
        reason: 'экран пейджера не покинут');
  });

  testWidgets('canNavigateBack=false: back покидает экран, onNavigateBack молчит',
      (tester) async {
    var backCalls = 0;
    await pushChatScreen(
      tester,
      canNavigateBack: false,
      onNavigateBack: () => backCalls++,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(backCalls, 0, reason: 'в корне истории back не перехватывается');
    expect(find.byType(ChatScreen), findsNothing,
        reason: 'экран пейджера покинут (выход в список)');
  });
}

class _FakeRpc implements MessagesRpc {
  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(messages: const []);

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
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

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
