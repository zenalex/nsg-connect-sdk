/// **Молчаливый отказ квитанции перестаёт быть невидимым** (issue #117).
///
/// markRead не бросает наружу и ничего не показывает — так задумано, и по
/// делу: сказать пользователю нечего, а лог на каждый сетевой чих на
/// мобильном интернете бесполезен. Но в issue #112 из-за этого пять дней
/// жила поломка, у которой единственным следом был бейдж непрочитанных,
/// который не гас.
///
/// Различаем не тип ошибки, а её УСТОЙЧИВОСТЬ: тот отказ приезжал 500-ым и
/// любым классификатором был бы записан в преходящие.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/diagnostics/nsg_messenger_diagnostics.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';

void main() {
  late List<Map<String, Object?>> reports;

  setUp(() {
    reports = [];
    MessagesController.resetMarkReadDiagnostics();
    NsgMessengerDiagnostics.onPersistentFailure = (e, st, ctx) =>
        reports.add(ctx);
  });
  tearDown(() {
    NsgMessengerDiagnostics.reset();
    MessagesController.resetMarkReadDiagnostics();
  });

  MessagesController make(MessagesRpc rpc, {int roomId = 7, String? root}) =>
      MessagesController(
        roomId: roomId,
        rpc: rpc,
        events: const Stream<MessengerEvent>.empty(),
        selfMessengerUserId: 1,
        selfMatrixUserId: '@self:l',
        threadRootEventId: root,
      );

  test('одна неудача — молчим', () async {
    // Оффлайн обычно даёт одну попытку и на этом кончается. Шуметь на неё
    // значит утопить настоящую поломку в сетевых помехах.
    final c = make(_FailingRpc());
    addTearDown(c.dispose);
    await c.markRead(r'$e1');
    expect(reports, isEmpty);
  });

  test('вторая подряд — сообщаем, и ровно один раз', () async {
    final c = make(_FailingRpc());
    addTearDown(c.dispose);
    await c.markRead(r'$e1');
    await c.markRead(r'$e2');
    await c.markRead(r'$e3');
    await c.markRead(r'$e4');

    expect(reports, hasLength(1), reason: 'повтор в трекере — это шум');
    expect(reports.single['op'], 'markRead');
    expect(reports.single['roomId'], 7);
    expect(reports.single['thread'], isFalse);
  });

  test('в контексте видно, что ломается ИМЕННО тред', () async {
    // В #112 ломались только треды задач, а комнатные квитанции проходили.
    // Без этого признака искать пришлось бы снова наугад.
    final c = make(_FailingRpc(), root: r'$root');
    addTearDown(c.dispose);
    await c.markRead(r'$reply');
    await c.markRead(r'$reply2');
    expect(reports.single['thread'], isTrue);
  });

  test('успех закрывает инцидент — следующая поломка сообщается заново',
      () async {
    final rpc = _FlakyRpc();
    final c = make(rpc);
    addTearDown(c.dispose);

    rpc.fail = true;
    await c.markRead(r'$e1');
    await c.markRead(r'$e2');
    expect(reports, hasLength(1));

    rpc.fail = false;
    await c.markRead(r'$e3'); // починилось

    rpc.fail = true;
    await c.markRead(r'$e4');
    await c.markRead(r'$e5');
    expect(
      reports,
      hasLength(2),
      reason: 'сломалось снова — это НОВАЯ поломка, а не та же самая',
    );
  });

  test('счётчик комнатный: чужая комната не гасит тревогу по этой', () async {
    // Поломка бывает в одной комнате (в #112 — в тредах поддержки), и
    // общий счётчик на всё приложение её бы размыл.
    final a = make(_FailingRpc(), roomId: 1);
    final b = make(_FlakyRpc(), roomId: 2);
    addTearDown(a.dispose);
    addTearDown(b.dispose);

    await a.markRead(r'$a1');
    await b.markRead(r'$b1'); // успех в другой комнате
    await a.markRead(r'$a2');

    expect(reports, hasLength(1));
    expect(reports.single['roomId'], 1);
  });
}

class _FailingRpc implements MessagesRpc {
  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
    String? threadRootEventId,
  }) async => throw Exception('500 от сервера');

  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

class _FlakyRpc implements MessagesRpc {
  bool fail = false;

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
    String? threadRootEventId,
  }) async {
    if (fail) throw Exception('500 от сервера');
    return true;
  }

  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}
