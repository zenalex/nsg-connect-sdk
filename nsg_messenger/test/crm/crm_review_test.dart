import 'package:nsg_messenger/src/crm/crm_components.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/crm/crm_forms.dart';
import 'package:nsg_messenger/src/crm/crm_screen.dart';
import 'package:nsg_messenger/src/crm/crm_state.dart';
import 'package:nsg_messenger/src/crm/crm_rpc.dart';
import 'package:nsg_messenger/src/crm/crm_controller.dart';
import 'package:nsg_messenger/src/cache/messenger_cache_store.dart';
import 'package:nsg_messenger/src/outbox/outbox_sender.dart';
import 'package:nsg_messenger/src/outbox/outbox_item.dart';
import 'crm_screens_test.dart' as f;

class ReplyRpc extends Fake implements MessagesRpc {
  final calls = <Invocation>[];
  final response = Completer<MessengerMessage>();
  @override
  dynamic noSuchMethod(Invocation i) {
    if (i.memberName == #sendMessage) {
      calls.add(i);
      return response.future;
    }
    return super.noSuchMethod(i);
  }
}

void main() {
  test(
    'retention timer removes failed CRM while idle; legacy retry time is not expiry',
    () async {
      final tmp = Directory.systemTemp.createTempSync('crm-retention-timer-');
      final store = (await MessengerCacheStore.openForUser(
        directory: tmp.path,
        namespace: 'test',
        userId: 7,
      ))!;
      final now = DateTime.now().millisecondsSinceEpoch;
      await store.enqueueOutbox(
        OutboxItem(
          clientTxnId: 'legacy',
          userId: 7,
          roomId: 0,
          kind: OutboxKind.crmActivity,
          body: '{"spaceId":1}',
          createdAt: now - const Duration(days: 1).inMilliseconds,
        ),
      );
      await store.markOutboxFailed('legacy', retentionDeadline: now - 1);
      await store.enqueueOutbox(
        OutboxItem(
          clientTxnId: 'timed',
          userId: 7,
          roomId: 0,
          kind: OutboxKind.crmActivity,
          body: '{"spaceId":1}',
          createdAt: now - const Duration(days: 20).inMilliseconds,
        ),
      );
      await store.markOutboxFailed('timed', retentionDeadline: now + 500);
      final sender = OutboxSender(store: store, rpc: f.FakeMessages());
      await sender.flush();
      for (var n = 0; n < 100 && (await store.allOutbox()).length > 1; n++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect((await store.allOutbox()).single.clientTxnId, 'legacy');
      expect(await store.getCrm('expiredActivities:1'), '1');
      await sender.dispose();
      await store.close();
      tmp.deleteSync(recursive: true);
    },
  );
  for (final text in ['Да', 'Нет', 'Yes', 'No']) {
    testWidgets(
      'actual message bubble $text sends one ordinary reply; remount stays locked',
      (t) async {
        final rpc = ReplyRpc();
        final controller = MessagesController(
          roomId: 17,
          rpc: rpc,
          events: const Stream<MessengerEvent>.empty(),
          selfMessengerUserId: 7,
          selfMatrixUserId: '@self:test',
        );
        var status = 'proposed', reads = 0;
        final english = text == 'Yes' || text == 'No';
        Widget bubble() => f.host(
          MessageBubble(
            message: ChatMessage(
              clientTxnId: null,
              matrixEventId: '\$proposal',
              senderMatrixUserId: '@agent:test',
              senderMessengerUserId: 8,
              body: '  Этап: Диалог → Пилот',
              msgType: 'm.notice',
              serverTimestamp: DateTime.now(),
              status: ChatMessageStatus.sent,
              crmProposalId: 42,
            ),
            isOwn: false,
            onRetry: (_) {},
            crmRoom: controller.crmRoom,
            crmReadStatus: (_) async {
              reads++;
              return {'status': status};
            },
            onCrmReply: (body, event) async {
              await controller.sendMessage(
                body: body,
                replyToMatrixEventId: event,
              );
            },
          ),
          locale: Locale(english ? 'en' : 'ru'),
        );
        await t.pumpWidget(bubble());
        await t.pumpAndSettle();
        final yes = t
            .widget<CrmPill>(
              find.widgetWithText(CrmPill, english ? 'Yes' : 'Да'),
            )
            .onPressed!;
        final no = t
            .widget<CrmPill>(
              find.widgetWithText(CrmPill, english ? 'No' : 'Нет'),
            )
            .onPressed!;
        await t.tap(find.text(text));
        await t.pump();
        yes();
        no();
        await t.pump();
        expect(rpc.calls, hasLength(1));
        expect(
          rpc.calls.single.namedArguments[#body],
          text == 'Да' || text == 'Yes' ? 'да' : 'нет',
        );
        expect(
          rpc.calls.single.namedArguments[#replyToMatrixEventId],
          '\$proposal',
        );
        expect(rpc.calls.single.namedArguments[#roomId], 17);
        expect(find.text('Да'), findsNothing);
        expect(find.text('Нет'), findsNothing);
        await t.pumpWidget(const SizedBox());
        await t.pumpWidget(bubble());
        await t.pumpAndSettle();
        expect(
          find.text(
            english
                ? 'Reply sent — waiting for the server'
                : 'Ответ отправлен — ждём сервер',
          ),
          findsOneWidget,
        );
        expect(rpc.calls, hasLength(1));
        status = 'applied';
        controller.crmRoom.roomChanged();
        await t.pump(const Duration(milliseconds: 300));
        await t.pumpAndSettle();
        final finalReads = reads;
        await t.pump(const Duration(minutes: 5));
        expect(reads, finalReads);
        await t.pumpWidget(const SizedBox());
        await controller.dispose();
      },
    );
  }
  for (final kind in [CrmStageKind.won, CrmStageKind.lost]) {
    testWidgets(
      'real desktop drag to $kind requests reason and versioned RPC',
      (t) async {
        t.view.physicalSize = const Size(1440, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final endpoint = f.FakeCrm();
        final actual = CrmRpc(endpoint, authRetry: false);
        await t.pumpWidget(
          f.host(
            Builder(
              builder: (ctx) => CrmKanban(
                stages: const [
                  CrmStageInfo(1, 'Открыто', CrmStageKind.open, 1),
                ],
                terminalStages: [CrmStageInfo(2, 'Финиш', kind, 2)],
                deals: [f.deal().copyWith(version: 12)],
                canWrite: true,
                onOpen: (_) {},
                onMove: (d, s) =>
                    crmMoveStage(ctx, actual, d, s, refresh: () async {}),
              ),
            ),
          ),
        );
        final start = t.getCenter(find.byKey(const ValueKey('crm-drag-1')));
        final drag = await t.startGesture(start, kind: PointerDeviceKind.mouse);
        await drag.moveBy(const Offset(30, 30));
        await t.pump();
        expect(find.byKey(const ValueKey('crm-drop-2')), findsOneWidget);
        await drag.moveTo(
          t.getCenter(find.byKey(const ValueKey('crm-drop-2'))),
        );
        await t.pump();
        await drag.up();
        await t.pumpAndSettle();
        expect(endpoint.moves, isEmpty);
        expect(find.text('Причина закрытия'), findsWidgets);
        await t.enterText(find.byType(TextField), 'Тестовая причина');
        await t.tap(find.text('Сохранить'));
        await t.pumpAndSettle();
        expect(endpoint.moves.single.positionalArguments, [1, 1, 12, 2]);
        expect(
          endpoint.moves.single.namedArguments[#closeReason],
          'Тестовая причина',
        );
      },
    );
  }
  test(
    'failed CRM expires seven days after failure, notice survives reopening',
    () async {
      final tmp = Directory.systemTemp.createTempSync('crm-retention-');
      final store = (await MessengerCacheStore.openForUser(
        directory: tmp.path,
        namespace: 'test',
        userId: 7,
      ))!;
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final (key, deadline) in [
        ('expired', now - 1),
        ('recent', now + 10000),
      ]) {
        await store.enqueueOutbox(
          OutboxItem(
            clientTxnId: key,
            userId: 7,
            roomId: 0,
            kind: OutboxKind.crmActivity,
            body: '{"spaceId":1,"fields":{"summary":"test"}}',
            createdAt: now - const Duration(days: 20).inMilliseconds,
          ),
        );
        await store.markOutboxFailed(key, retentionDeadline: deadline);
      }
      await store.purgeFailedCrmActivities(now);
      expect((await store.allOutbox()).single.clientTxnId, 'recent');
      await store.close();
      final reopened = (await MessengerCacheStore.openForUser(
        directory: tmp.path,
        namespace: 'test',
        userId: 7,
      ))!;
      expect(await reopened.getCrm('expiredActivities:1'), '1');
      await reopened.purgeFailedCrmActivities(now);
      expect(await reopened.getCrm('expiredActivities:1'), '1');
      await reopened.close();
      tmp.deleteSync(recursive: true);
    },
  );
  test(
    'queued version conflict keeps failed row and rereads current deal',
    () async {
      final tmp = Directory.systemTemp.createTempSync('crm-conflict-');
      final store = (await MessengerCacheStore.openForUser(
        directory: tmp.path,
        namespace: 'test',
        userId: 7,
      ))!;
      final endpoint = f.FakeCrm()..deals = [f.deal().copyWith(version: 2)];
      final sender = OutboxSender(
        store: store,
        rpc: f.FakeMessages(),
        sendCrmActivity: (_) async {
          throw CrmVersionConflict(conflicts: []);
        },
      );
      final controller = CrmController(
        rpc: CrmRpc(endpoint, authRetry: false),
        spaceId: 1,
        userId: 7,
        cache: store,
        outbox: sender,
      );
      await store.enqueueOutbox(
        OutboxItem(
          clientTxnId: 'conflict',
          userId: 7,
          roomId: 0,
          kind: OutboxKind.crmActivity,
          body: '{"spaceId":1}',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await sender.flush();
      for (var n = 0; n < 100 && controller.state is! CrmReady; n++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(
        (await store.allOutbox()).single.lastError,
        'crm_version_conflict',
      );
      expect((controller.state as CrmReady).deals.single.version, 2);
      controller.dispose();
      await sender.dispose();
      await store.close();
      tmp.deleteSync(recursive: true);
    },
  );
}
