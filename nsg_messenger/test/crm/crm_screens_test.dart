import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/crm/crm_controller.dart';
import 'package:nsg_messenger/src/crm/crm_rpc.dart';
import 'package:nsg_messenger/src/crm/crm_screen.dart';
import 'package:nsg_messenger/src/crm/crm_detail_screen.dart';
import 'package:nsg_messenger/src/crm/crm_forms.dart';
import 'package:nsg_messenger/src/crm/crm_state.dart';
import 'package:nsg_messenger/src/crm/crm_proposal_card.dart';
import 'package:nsg_messenger/src/crm/crm_room_controller.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/cache/messenger_cache_store.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/outbox/outbox_item.dart';
import 'package:nsg_messenger/src/outbox/outbox_sender.dart';

class FakeCrm extends Fake implements EndpointCrm {
  List<CrmDealView> deals = [];
  Object? error;
  final moves = <Invocation>[];
  final activities = <Invocation>[];
  @override
  dynamic noSuchMethod(Invocation i) {
    if (i.memberName == #listDeals) {
      return error == null
          ? Future.value(CrmDealPage(items: deals))
          : Future<CrmDealPage>.error(error!);
    }
    if (i.memberName == #listPipelines) return Future.value('{"pipelines":[]}');
    if (i.memberName == #addActivity) {
      activities.add(i);
      return error == null
          ? Future.value(
              CrmChangesetView(
                id: 1,
                spaceId: 1,
                actorUserId: 7,
                actorKind: CrmActorKind.user,
                status: CrmChangesetStatus.applied,
                createdAt: DateTime.now(),
                undoable: true,
                items: [],
              ),
            )
          : Future<CrmChangesetView>.error(error!);
    }
    if (i.memberName == #moveStage) {
      moves.add(i);
      return Future.value(
        CrmChangesetView(
          id: 1,
          spaceId: 1,
          actorUserId: 7,
          actorKind: CrmActorKind.user,
          status: CrmChangesetStatus.applied,
          createdAt: DateTime.now(),
          undoable: true,
          items: [],
        ),
      );
    }
    return super.noSuchMethod(i);
  }
}

class FakeMessages extends Fake implements MessagesRpc {}

class DeniedDetails extends FakeCrm {
  DeniedDetails(this.failure);
  final Object failure;
  @override
  dynamic noSuchMethod(Invocation i) {
    if (i.memberName == #getDeal) return Future<CrmDealView>.error(failure);
    if (i.memberName == #getCompany) {
      return Future<CrmCompanyDetails>.error(failure);
    }
    return super.noSuchMethod(i);
  }
}

Widget host(Widget child, {Locale locale = const Locale('ru')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: NsgL10n.localizationsDelegates,
  supportedLocales: NsgL10n.supportedLocales,
  home: Scaffold(body: child),
);

CrmDealView deal({String? amount = '1250.50', String? currency = 'RUB'}) =>
    CrmDealView(
      id: 1,
      spaceId: 1,
      segmentId: 1,
      version: 1,
      pipelineId: 1,
      stageId: 1,
      title: 'Пилот',
      ownerUserId: 7,
      participants: [],
      contacts: [],
      nextStep: 'Встреча',
      nextStepAt: DateTime.now().add(const Duration(minutes: 30)),
      nextStepPending: false,
      nextStepState: CrmNextStepState.open,
      stageChangedAt: DateTime.now(),
      activities: [],
      documents: [],
      metrics: [],
      amount: amount,
      currency: currency,
    );

void main() {
  testWidgets('quick touch sends activity and next step in one generated RPC', (
    t,
  ) async {
    final endpoint = FakeCrm();
    final controller = CrmController(
      rpc: CrmRpc(endpoint, authRetry: false),
      spaceId: 1,
      userId: 7,
    );
    final item = deal().copyWith(
      company: CrmCompanyView(
        id: 11,
        spaceId: 1,
        segmentId: 1,
        version: 1,
        name: 'Тестовая компания',
        kind: CrmCompanyKind.other,
        ownerUserId: 7,
        tags: [],
        status: CrmCompanyStatus.active,
      ),
    );
    await t.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => crmQuickActivity(context, controller, item),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'Тестовый итог');
    await t.enterText(find.byType(TextField).last, 'Тестовый шаг');
    await t.tap(find.text('Сохранить'));
    await t.pumpAndSettle();
    expect(endpoint.activities, hasLength(1));
    final call = endpoint.activities.single;
    final fields = jsonDecode(call.positionalArguments[1] as String) as Map;
    expect(fields['companyId'], 11);
    expect(fields['dealId'], item.id);
    expect(fields['summary'], 'Тестовый итог');
    expect(call.namedArguments[#dealVersion], item.version);
    expect(
      jsonDecode(call.namedArguments[#nextStepJson] as String)['nextStep'],
      'Тестовый шаг',
    );
    expect(call.namedArguments[#idempotencyKey], startsWith('crm-ui:'));
    await t.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets(
    'quick touch reports unavailable parent instead of silently stopping',
    (t) async {
      final controller = CrmController(
        rpc: CrmRpc(FakeCrm(), authRetry: false),
        spaceId: 1,
        userId: 7,
      );
      await t.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => crmQuickActivity(
                context,
                controller,
                deal().copyWith(company: null),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).first, 'Тестовый итог');
      await t.enterText(find.byType(TextField).last, 'Тестовый шаг');
      await t.tap(find.text('Сохранить'));
      await t.pumpAndSettle();
      final l = NsgL10n.of(t.element(find.byType(Scaffold).first));
      expect(find.text(l.crmUnavailable), findsOneWidget);
      Navigator.of(t.element(find.text('Open'))).pop();
      await t.pumpAndSettle();
      await t.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
  for (final denied in [false, true]) {
    for (final company in [false, true]) {
      testWidgets(
        '${company ? "company" : "deal"} error/denial=$denied hides details',
        (t) async {
          final rpc = CrmRpc(
            DeniedDetails(
              denied ? CrmAccessDenied() : StateError('private failure'),
            ),
            authRetry: false,
          );
          await t.pumpWidget(
            host(
              company
                  ? CrmCompanyScreen(id: 1, rpc: rpc)
                  : CrmDealScreen(id: 1, rpc: rpc),
            ),
          );
          await t.pumpAndSettle();
          final l = NsgL10n.of(t.element(find.byType(Scaffold).first));
          expect(
            find.text(denied ? l.crmDenied : l.crmUnavailable),
            findsOneWidget,
          );
          expect(find.textContaining('private failure'), findsNothing);
        },
      );
    }
  }
  for (final (name, error, label) in [
    ('empty', null, 'Здесь пока ничего нет'),
    ('denied', CrmAccessDenied(), 'Нет доступа'),
    (
      'failure',
      StateError('private payload must not be shown'),
      'Не удалось загрузить. Повторите попытку.',
    ),
  ]) {
    testWidgets(name, (tester) async {
      final endpoint = FakeCrm()..error = error;
      final rpc = CrmRpc(endpoint, authRetry: false);
      final controller = CrmController(rpc: rpc, spaceId: 1, userId: 7);
      await tester.pumpWidget(
        host(CrmScreen(rpc: rpc, controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      expect(find.textContaining('private payload'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  }
  testWidgets('server redaction hides names and PD without a fetch', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        CrmContactTile(
          contact: CrmContactView(
            id: 1,
            segmentId: 1,
            version: 1,
            pdRedacted: true,
            fullName: 'Never render',
            phone: '+79990000000',
            email: 'private@example.test',
          ),
        ),
      ),
    );
    expect(find.text('ПДн скрыты'), findsOneWidget);
    expect(find.text('Never render'), findsNothing);
    expect(find.byIcon(Icons.call), findsNothing);
    expect(find.byIcon(Icons.mail_outline), findsNothing);
  });
  testWidgets('deal list renders amount and currency', (tester) async {
    await tester.pumpWidget(host(CrmDealTile(deal: deal(), onOpen: () {})));
    expect(find.textContaining('1\u00a0250,50'), findsOneWidget);
  });
  test('stage totals preserve decimals and separate currencies', () {
    final totals = crmStageTotals([
      deal(amount: '0.1001'),
      deal(amount: '0.2002'),
      deal(amount: '2.50', currency: 'EUR'),
    ]);
    expect(totals['RUB']!.value, BigInt.from(3003));
    expect(totals['RUB']!.scale, 4);
    expect(totals['EUR']!.value, BigInt.from(250));
  });
  for (final status in [
    'proposed',
    'applied',
    'rejected',
    'stale',
    'superseded',
    'expired',
  ]) {
    testWidgets('proposal $status; replies preserve card event', (
      tester,
    ) async {
      final replies = <(String, String)>[];
      await tester.pumpWidget(
        host(
          CrmProposalCard(
            proposalId: 34,
            body: 'Серверный дифф',
            eventId: '\$card',
            readStatus: (_) async => {'status': status},
            reply: (text, event) async {
              replies.add((text, event));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Серверный дифф'), findsOneWidget);
      if (status == 'proposed') {
        await tester.tap(find.text('Да'));
        await tester.pumpAndSettle();
        expect(find.text('Нет'), findsNothing);
        expect(find.text('Да'), findsNothing);
        expect(find.text('Ответ отправлен — ждём сервер'), findsOneWidget);
        expect(replies, [('да', '\$card')]);
      } else {
        expect(find.text('Да'), findsNothing);
        expect(find.text('Нет'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final locale in [const Locale('ru'), const Locale('en')]) {
    for (final initiallyDenied in [true, false]) {
      testWidgets(
        'proposal access denied ${locale.languageCode} initial=$initiallyDenied',
        (tester) async {
          final room = CrmRoomController();
          var denied = initiallyDenied;
          var reads = 0;
          final replies = <String>[];
          await tester.pumpWidget(
            host(
              CrmProposalCard(
                proposalId: 34,
                body: '',
                eventId: r'$card',
                room: room,
                readStatus: (_) async {
                  reads++;
                  if (denied) throw CrmAccessDenied(message: 'diagnostic');
                  return {'status': 'proposed'};
                },
                reply: (text, _) async => replies.add(text),
              ),
              locale: locale,
            ),
          );
          await tester.pumpAndSettle();
          final l = NsgL10n.of(tester.element(find.byType(CrmProposalCard)));
          if (!initiallyDenied) {
            expect(find.text(l.crmYes), findsOneWidget);
            denied = true;
            room.roomChanged();
            await tester.pump(const Duration(milliseconds: 300));
            await tester.pumpAndSettle();
          }
          expect(find.text(l.crmDenied), findsOneWidget);
          expect(find.text(l.crmYes), findsNothing);
          expect(find.text(l.crmNo), findsNothing);
          expect(find.textContaining('diagnostic'), findsNothing);
          final readsAfterDenial = reads;
          await tester.pump(const Duration(minutes: 6));
          expect(reads, readsAfterDenial);
          expect(replies, isEmpty);
          denied = false;
          room.roomChanged();
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pumpAndSettle();
          expect(find.text(l.crmDenied), findsNothing);
          expect(find.text(l.crmYes), findsOneWidget);
          await tester.tap(find.text(l.crmYes));
          await tester.pumpAndSettle();
          expect(replies, ['да']);
          await tester.pumpWidget(const SizedBox());
          room.dispose();
        },
      );
    }
  }
  for (final kind in [CrmStageKind.won, CrmStageKind.lost]) {
    testWidgets('$kind requires reason before moveStage', (tester) async {
      final endpoint = FakeCrm();
      final rpc = CrmRpc(endpoint, authRetry: false);
      await tester.pumpWidget(
        host(
          Builder(
            builder: (ctx) => TextButton(
              onPressed: () => crmMoveStage(
                ctx,
                rpc,
                deal(),
                CrmStageInfo(2, 'Финиш', kind, 2),
                refresh: () async {},
              ),
              child: const Text('Move'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Move'));
      await tester.pumpAndSettle();
      expect(endpoint.moves, isEmpty);
      await tester.enterText(find.byType(TextField), 'Тестовая причина');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(endpoint.moves.single.positionalArguments, [1, 1, 1, 2]);
      expect(
        endpoint.moves.single.namedArguments[#closeReason],
        'Тестовая причина',
      );
    });
  }
  testWidgets('kanban drag opens the move action', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final moves = <int>[];
    await tester.pumpWidget(
      host(
        CrmKanban(
          stages: const [
            CrmStageInfo(1, 'Первый', CrmStageKind.open, 1),
            CrmStageInfo(2, 'Второй', CrmStageKind.open, 2),
          ],
          deals: [deal()],
          canWrite: true,
          onOpen: (_) {},
          onMove: (_, s) async {
            moves.add(s.id);
          },
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Пилот')),
    );
    await tester.pump(const Duration(seconds: 1));
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('crm-stage-2'))),
    );
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moves, [2]);
  });
  test(
    'offline activity survives restart and reuses idempotency key without chat send',
    () async {
      final tmp = Directory.systemTemp.createTempSync('crm-outbox-');
      final store = (await MessengerCacheStore.openForUser(
        directory: tmp.path,
        namespace: 'test',
        userId: 7,
      ))!;
      final keys = <String>[];
      var online = false;
      final sender = OutboxSender(
        store: store,
        rpc: FakeMessages(),
        sendCrmActivity: (item) async {
          if (!online) throw const SocketException('offline');
          keys.add(item.clientTxnId);
        },
      );
      await store.enqueueOutbox(
        OutboxItem(
          clientTxnId: 'crm-key',
          userId: 7,
          roomId: 0,
          kind: OutboxKind.crmActivity,
          body: '{}',
          createdAt: 1,
        ),
      );
      await sender.flush();
      expect(keys, isEmpty);
      expect((await store.allOutbox()).single.clientTxnId, 'crm-key');
      await sender.dispose();
      await store.close();
      final reopened = (await MessengerCacheStore.openForUser(
        directory: tmp.path,
        namespace: 'test',
        userId: 7,
      ))!;
      final second = OutboxSender(
        store: reopened,
        rpc: FakeMessages(),
        sendCrmActivity: (item) async {
          keys.add(item.clientTxnId);
        },
      );
      online = true;
      await reopened.resetOutboxForRetry('crm-key');
      await second.flush();
      await second.flush();
      expect(keys, ['crm-key']);
      expect(await reopened.allOutbox(), isEmpty);
      await second.dispose();
      await reopened.close();
      tmp.deleteSync(recursive: true);
    },
  );
}
