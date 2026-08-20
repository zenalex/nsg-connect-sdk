import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart' show MessengerSessionState;
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';
import 'package:nsg_messenger/src/screens/chat_screen.dart';

import '../test_helpers.dart';

/// **issue #92 (жалоба 06.08.2026)**: непрочитанное не снималось с комнаты,
/// открытой в панели рабочего набора.
///
/// Причина — дедуп `markRead` по newest event ЛЕНТЫ. Реплика обсуждения
/// задачи увеличивает unread комнаты, но в ленту не попадает (разделение
/// лент, TASK82), поэтому newest event не сдвигается. У keep-alive экрана
/// (`IndexedStack` панелей) поле дедупа переживает переключение панелей — и
/// markRead не уходил уже НИКОГДА: человек смотрит на комнату, а счётчик
/// висит. На телефоне каждый заход создавал новый `State`, дедуп был пуст, и
/// баг не воспроизводился — отсюда «в двух панелях, а в одной работает».
///
/// Проверяется именно повторная активация: тот случай, где раньше был
/// молчаливый no-op.
void main() {
  ({
    List<String> marks,
    MessagesController controller,
    Future<void> Function() close,
  })
  setUp$() {
    final marks = <String>[];
    final upstream = StreamController<MessengerEvent>.broadcast();
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final eventBus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    final controller = MessagesController(
      roomId: 42,
      rpc: _StubRpc(marks),
      events: eventBus.events,
      selfMessengerUserId: 1,
      selfMatrixUserId: '@alice:test',
    );
    return (
      marks: marks,
      controller: controller,
      close: () async {
        await controller.dispose();
        await upstream.close();
        await stateCtl.close();
      },
    );
  }

  Widget pane(MessagesController c, {required bool active}) => wrapL10n(
    ChatScreen(
      roomId: 42,
      active: active,
      controllerOverride: c,
      setPresenceOverride:
          ({int? currentRoomId, required bool foreground}) async {},
    ),
  );

  testWidgets('повторная активация панели метит прочитанным ещё раз', (
    tester,
  ) async {
    final env = setUp$();
    addTearDown(env.close);

    await tester.pumpWidget(pane(env.controller, active: true));
    await tester.pumpAndSettle();
    expect(env.marks, hasLength(1), reason: 'первый показ метит');

    // Ушли на соседнюю панель и вернулись. Лента не изменилась — но пока нас
    // не было, в комнату могла прийти реплика обсуждения, и unread на сервере
    // отличен от нуля. Экран это увидеть не может: реплики в ленте нет.
    await tester.pumpWidget(pane(env.controller, active: false));
    await tester.pump();
    await tester.pumpWidget(pane(env.controller, active: true));
    await tester.pumpAndSettle();

    expect(
      env.marks,
      hasLength(2),
      reason: 'до фикса дедуп молча гасил этот вызов — счётчик висел навсегда',
    );
    expect(env.marks.last, r'$evt-1');
  });

  testWidgets('возврат из перекрывшего маршрута тоже метит', (tester) async {
    // Тот же класс: пока сверху был открыт профиль/тред, могла прийти
    // реплика обсуждения.
    final env = setUp$();
    addTearDown(env.close);

    await tester.pumpWidget(pane(env.controller, active: true));
    await tester.pumpAndSettle();
    expect(env.marks, hasLength(1));

    final stateObj = tester.state(find.byType(ChatScreen));
    // ignore: avoid_dynamic_calls
    (stateObj as dynamic).didPopNext();
    await tester.pump();

    expect(env.marks, hasLength(2));
  });

  testWidgets('неактивная панель по-прежнему молчит', (tester) async {
    // Гейт видимости (issue #37) снимать нельзя: фоновая панель не должна
    // ставить ✓✓ за пользователя, который на неё не смотрит.
    final env = setUp$();
    addTearDown(env.close);

    await tester.pumpWidget(pane(env.controller, active: false));
    await tester.pumpAndSettle();

    expect(env.marks, isEmpty);
  });
}

class _StubRpc implements MessagesRpc {
  _StubRpc(this.marks);

  final List<String> marks;

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(
    messages: [
      MessengerMessage(
        roomId: roomId,
        matrixRoomId: '!r:test',
        matrixEventId: r'$evt-1',
        senderMessengerUserId: 2,
        senderMatrixUserId: '@bob:test',
        body: 'сообщение ленты',
        msgType: 'm.text',
        serverTimestamp: DateTime.utc(2026, 8, 6),
      ),
    ],
  );

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
    String? threadRootEventId,
  }) async {
    marks.add(matrixEventId);
    return true;
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
    String? albumId,
    String? forwardedFromName,
    int? forwardedFromMessengerUserId,
    int? forwardedFromRoomId,
    String? forwardedFromEventId,
    String? threadId,
  }) => throw UnimplementedError();

  @override
  Future<AttachmentRef> uploadAttachment({
    required ByteData bytes,
    required String mimeType,
    required String originalFilename,
  }) => throw UnimplementedError();

  @override
  Future<AttachmentBytes> downloadAttachmentThumbnail({
    required String mxcUrl,
    int? width,
    int? height,
  }) => throw UnimplementedError();

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  /// Прочее ленте не нужно: тест про markRead, а не про начинку экрана.
  /// `null` вместо throw — иначе `init()` падает на первом же необъявленном
  /// вызове и до markRead дело не доходит.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
