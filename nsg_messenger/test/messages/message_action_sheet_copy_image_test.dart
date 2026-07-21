import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/attachments/image_actions.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/message_action_sheet.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';

/// Widget-тесты пункта «Скопировать изображение» в меню сообщения:
///   * виден только для сообщений-картинок (не для текста);
///   * тап зовёт [ImageActions.copyImage] и показывает snackbar.
class _FakeRpc implements MessagesRpc {
  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(messages: const []);

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

void main() {
  late MessagesController controller;

  setUp(() async {
    controller = MessagesController(
      roomId: 1,
      rpc: _FakeRpc(),
      events: const Stream<MessengerEvent>.empty(),
      selfMessengerUserId: 1,
      selfMatrixUserId: '@self:t',
    );
    await controller.init();
    addTearDown(controller.dispose);
  });

  ChatMessage msg({required bool image}) => ChatMessage(
    clientTxnId: null,
    matrixEventId: 'ev1',
    senderMatrixUserId: '@a:t',
    senderMessengerUserId: 2,
    body: image ? '' : 'hello',
    msgType: image ? 'm.image' : 'm.text',
    serverTimestamp: DateTime.utc(2026, 1, 1),
    status: ChatMessageStatus.sent,
    attachment: image
        ? AttachmentRef(
            mxcUrl: 'mxc://s/1',
            mimeType: 'image/png',
            sizeBytes: 10,
            originalFilename: 'a.png',
          )
        : null,
  );

  Widget app(ChatMessage m, ImageActions actions) => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => showMessageActionSheet(
            context: ctx,
            message: m,
            isOwn: false,
            controller: controller,
            imageActions: actions,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );

  ImageActions recordingActions(List<Uint8List> copied) => ImageActions(
    loadBytes: (_) async => Uint8List.fromList([1, 2, 3]),
    copyImageBytes: (b) async => copied.add(b),
    platformOverride: TargetPlatform.windows,
    isWebOverride: false,
  );

  testWidgets('картинка → пункт есть; тап копирует + snackbar', (tester) async {
    final copied = <Uint8List>[];
    await tester.pumpWidget(app(msg(image: true), recordingActions(copied)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Copy image'), findsOneWidget);

    await tester.tap(find.text('Copy image'));
    await tester.pump(); // pop листа + старт async
    await tester.pump(const Duration(seconds: 1));

    expect(copied.single, [1, 2, 3]);
    expect(find.text('Image copied to clipboard'), findsOneWidget);
  });

  testWidgets('текстовое сообщение → пункта «Скопировать изображение» нет', (
    tester,
  ) async {
    await tester.pumpWidget(app(msg(image: false), recordingActions([])));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Copy image'), findsNothing);
    // Текстовый «Копировать» (body) при этом на месте.
    expect(find.text('Copy'), findsOneWidget);
  });
}
