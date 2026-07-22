import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_picker.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/messages/messages_state.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;
import 'package:nsg_messenger/src/screens/chat_screen.dart';

/// **Issue #54**: реджект вложения должен быть ВИДЕН пользователю.
///
/// Живой баг на 1.0.80+81: .txt, выбранный через «Прикрепить → Файл»,
/// уходил в фоновый аплоад, сервер реджектил MIME — и всё. Красный «!»
/// на пузыре, ноль строк в stdout, никакого снекбара: путь композера идёт
/// через `onSendAlbum` → `sendAlbumOptimistic`, а единственный снекбар
/// `attachUploadFailed` жил в другой ветке (`sendAttachment`), куда файл
/// из композера не попадает вообще.
///
/// Здесь проверяем именно доставку причины до экрана — и то, что она
/// НЕ включается на обычных сетевых сбоях (их лечит retry по «!», и
/// снекбар на каждый блип был бы шумом).
const _room = 1;

class _FakeRpc implements MessagesRpc {
  /// Что бросить из `uploadAttachment`. null → успешный аплоад.
  Object? uploadError;

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
  Future<AttachmentRef> uploadAttachment({
    required ByteData bytes,
    required String mimeType,
    required String originalFilename,
  }) async {
    final err = uploadError;
    if (err != null) throw err;
    return AttachmentRef(
      mxcUrl: 'mxc://localhost/ok',
      mimeType: mimeType,
      sizeBytes: bytes.lengthInBytes,
      originalFilename: originalFilename,
    );
  }

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

  /// Поднять экран и отправить один файл композерным путём (тем самым,
  /// на котором ошибка терялась).
  Future<MessagesController> sendFile(
    WidgetTester tester, {
    required Object uploadError,
    String filename = 'notes.txt',
    String mimeType = 'text/plain',
  }) async {
    final rpc = _FakeRpc()..uploadError = uploadError;
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
      wrap(ChatScreen(roomId: _room, controllerOverride: controller)),
    );
    await tester.pump(); // init
    await tester.pump(); // Ready

    controller.sendAlbumOptimistic(
      images: [
        PickedAttachment(
          bytes: Uint8List.fromList(List.filled(4, 7)),
          mimeType: mimeType,
          originalFilename: filename,
        ),
      ],
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('неподдерживаемый тип → снекбар с причиной и именем файла', (
    tester,
  ) async {
    final controller = await sendFile(
      tester,
      uploadError: AttachmentRejectedException(
        reason: AttachmentRejectReason.unsupportedType,
        mimeType: 'text/plain',
        filename: 'notes.txt',
      ),
    );

    expect(
      find.text("Can't send “notes.txt” — this file type isn't supported"),
      findsOneWidget,
      reason: 'до фикса тут не было ничего — только красный «!»',
    );
    // Пузырь при этом честно в failed (снекбар не подменяет статус).
    final state = controller.state as MessagesReady;
    expect(state.messages.single.isFailed, isTrue);
  });

  testWidgets('исполняемый файл → своя формулировка, не «тип не поддержан»', (
    tester,
  ) async {
    await sendFile(
      tester,
      filename: 'setup.exe',
      mimeType: 'application/octet-stream',
      uploadError: AttachmentRejectedException(
        reason: AttachmentRejectReason.blockedExtension,
        mimeType: 'application/octet-stream',
        filename: 'setup.exe',
      ),
    );

    expect(
      find.text("Can't send “setup.exe” — executable files aren't allowed"),
      findsOneWidget,
    );
  });

  testWidgets('превышение лимита → снекбар с лимитом в МБ', (tester) async {
    await sendFile(
      tester,
      filename: 'movie.mp4',
      mimeType: 'video/mp4',
      uploadError: AttachmentRejectedException(
        reason: AttachmentRejectReason.tooLarge,
        mimeType: 'video/mp4',
        filename: 'movie.mp4',
        maxBytes: 100 * 1024 * 1024,
        actualBytes: 120 * 1024 * 1024,
      ),
    );

    expect(
      find.text("Can't send “movie.mp4” — the file is larger than 100 MB"),
      findsOneWidget,
    );
  });

  testWidgets('сетевой сбой → снекбара НЕТ (лечится retry по «!»)', (
    tester,
  ) async {
    final controller = await sendFile(
      tester,
      uploadError: Exception('нет сети'),
    );

    expect(
      find.byType(SnackBar),
      findsNothing,
      reason: 'снекбар на каждый сетевой блип — шум; для этого есть retry',
    );
    final state = controller.state as MessagesReady;
    expect(state.messages.single.isFailed, isTrue);
  });
}
