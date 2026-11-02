import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/crm/crm_deal_banner.dart';
import 'package:nsg_messenger/src/crm/crm_room_controller.dart';
import 'package:nsg_messenger/src/crm/crm_proposal_card.dart';
import 'package:nsg_messenger/src/crm/crm_rpc.dart';
import 'package:nsg_messenger/src/crm/crm_screen.dart';
import 'package:nsg_messenger/src/crm/crm_forms.dart';
import 'package:nsg_messenger/src/crm/crm_state.dart';
import 'crm_screens_test.dart' as f;

ByteData content(Map<String, dynamic> data) =>
    ByteData.sublistView(Uint8List.fromList(utf8.encode(jsonEncode(data))));

class BannerEndpoint extends f.FakeCrm {
  int reads = 0, catalogs = 0;
  @override
  dynamic noSuchMethod(Invocation i) {
    if (i.memberName == #getDeal) {
      reads++;
      return Future.value(f.deal());
    }
    if (i.memberName == #listPipelines) {
      catalogs++;
      return Future.value(
        '{"pipelines":[{"id":1,"name":"TEST","stages":[{"id":1,"name":"Open","kind":"open","sortOrder":1}]}]}',
      );
    }
    if (i.memberName == #listCompanies) {
      return Future<List<CrmCompanyView>>.error(StateError('offline'));
    }
    return super.noSuchMethod(i);
  }
}

void main() {
  testWidgets(
    'ordinary traffic and reply locks do not reload; CRM bursts share cached pipelines',
    (t) async {
      final room = CrmRoomController(), api = BannerEndpoint();
      await t.pumpWidget(
        f.host(
          CrmDealBanner(
            dealId: 1,
            rpc: CrmRpc(api, authRetry: false),
            room: room,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(api.reads, 1);
      expect(api.catalogs, 1);
      for (var n = 0; n < 30; n++) {
        room.messageChanged(content({'body': 'synthetic'}));
      }
      room.beginReply(42);
      room.replyFailed(42);
      await t.pump(const Duration(minutes: 3));
      expect(api.reads, 1);
      for (var n = 0; n < 10; n++) {
        room.messageChanged(
          content({
            'app.nsg.crm_event': {'dealId': 1},
          }),
        );
      }
      await t.pump(const Duration(milliseconds: 299));
      expect(api.reads, 1);
      await t.pump(const Duration(milliseconds: 1));
      await t.pumpAndSettle();
      expect(api.reads, 2);
      expect(api.catalogs, 1);
      await t.pumpWidget(const SizedBox());
      room.dispose();
    },
  );
  testWidgets(
    'proposed cards debounce burst and hide old expiry after denial',
    (t) async {
      final room = CrmRoomController();
      var reads = 0, denied = false;
      await t.pumpWidget(
        f.host(
          CrmProposalCard(
            proposalId: 42,
            body: 'TEST',
            eventId: r'$test',
            room: room,
            readStatus: (_) async {
              reads++;
              if (denied) throw CrmAccessDenied();
              return {
                'status': 'proposed',
                'expiresAt': '2030-01-01T12:00:00Z',
              };
            },
            reply: (_, _) async {},
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(reads, 1);
      expect(find.textContaining('Действует до'), findsOneWidget);
      for (var n = 0; n < 20; n++) {
        room.roomChanged();
      }
      await t.pump(const Duration(milliseconds: 299));
      expect(reads, 1);
      denied = true;
      await t.pump(const Duration(milliseconds: 1));
      await t.pumpAndSettle();
      expect(reads, 2);
      expect(find.textContaining('Действует до'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      await t.pumpWidget(const SizedBox());
      room.dispose();
    },
  );
  testWidgets('first company page failure shows error', (t) async {
    await t.pumpWidget(
      f.host(
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => crmChooseCompany(
              ctx,
              CrmRpc(BannerEndpoint(), authRetry: false),
              1,
            ),
            child: const Text('choose'),
          ),
        ),
      ),
    );
    await t.tap(find.text('choose'));
    await t.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets(
    'touch scroll stays scroll; long press starts drag; reload removes zones',
    (t) async {
      t.view.physicalSize = const Size(1440, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      var deals = List.generate(
        12,
        (i) => f.deal().copyWith(id: i + 1, title: 'TEST $i'),
      );
      Widget board() => f.host(
        CrmKanban(
          stages: const [CrmStageInfo(1, 'Open', CrmStageKind.open, 1)],
          terminalStages: const [CrmStageInfo(2, 'Won', CrmStageKind.won, 2)],
          deals: deals,
          canWrite: true,
          onOpen: (_) {},
          onMove: (_, _) async {},
        ),
      );
      await t.pumpWidget(board());
      var gesture = await t.startGesture(
        t.getCenter(find.byKey(const ValueKey('crm-drag-1'))),
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveBy(const Offset(0, -70));
      await t.pump();
      expect(find.byKey(const ValueKey('crm-drop-2')), findsNothing);
      await gesture.up();
      await t.pumpAndSettle();
      gesture = await t.startGesture(
        t.getCenter(find.byType(CrmPointerDraggable<CrmDealView>).first),
        kind: PointerDeviceKind.touch,
      );
      await t.pump(kLongPressTimeout + const Duration(milliseconds: 10));
      await gesture.moveBy(const Offset(30, 30));
      await t.pump();
      expect(find.byKey(const ValueKey('crm-drop-2')), findsOneWidget);
      deals = [];
      await t.pumpWidget(board());
      await t.pump();
      expect(find.byKey(const ValueKey('crm-drop-2')), findsNothing);
      await gesture.cancel();
      await t.pumpWidget(const SizedBox());
    },
  );
}
