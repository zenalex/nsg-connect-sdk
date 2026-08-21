/// **TASK91 (issue #65)**: показ объявлений при входе в приложение.
///
/// Заявка оператора: предупреждать о плановых работах и нововведениях —
/// «показать текст (один раз потом просмотрено…), какую форму открыть (путь)
/// и payload».
///
/// Правила «что показывать» живут на сервере и здесь не дублируются. Клиенту
/// принадлежат ровно три решения, они и проверяются: КОГДА отметить
/// просмотренным, КАК вести себя без обработчика маршрута и что делать при
/// сбое сети.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/announcements/announcements.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

AnnouncementView _view({
  int id = 1,
  String kind = 'text',
  String? route,
  String? payloadJson,
  String? url,
  String severity = 'warning',
  String body = 'Ночью со вторника на среду возможны сбои.',
}) => AnnouncementView(
  id: id,
  kind: kind,
  title: 'Плановые работы',
  body: body,
  route: route,
  payloadJson: payloadJson,
  url: url,
  severity: severity,
  createdAt: DateTime.utc(2026, 8, 3),
);

/// Подменённый url_launcher: тесту важен сам факт запуска и адрес, а не
/// браузер — его в тестовой среде нет вовсе.
class _FakeLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  final List<String> launched = [];

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  LinkDelegate? get linkDelegate => null;
}

class _FakeRpc implements AnnouncementsRpc {
  _FakeRpc(this._items, {this.failPending = false});

  final List<AnnouncementView> _items;
  final bool failPending;
  final List<int> seen = [];
  final List<String?> productKeys = [];

  @override
  Future<List<AnnouncementView>> pending(String? productExternalKey) async {
    productKeys.add(productExternalKey);
    if (failPending) throw Exception('сеть оборвалась');
    return _items;
  }

  @override
  Future<void> markSeen(int announcementId) async => seen.add(announcementId);
}

Widget _host(void Function(BuildContext) run) => MaterialApp(
  locale: const Locale('ru'),
  localizationsDelegates: const [
    NsgL10n.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: NsgL10n.supportedLocales,
  home: Builder(
    builder: (context) => Scaffold(
      body: ElevatedButton(
        onPressed: () => run(context),
        child: const Text('go'),
      ),
    ),
  ),
);

void main() {
  testWidgets('объявление показано, «Понятно» отмечает просмотренным', (
    tester,
  ) async {
    final rpc = _FakeRpc([_view()]);
    await tester.pumpWidget(
      _host(
        (ctx) => showPendingAnnouncements(
          ctx,
          productExternalKey: 'chatista',
          rpcOverride: rpc,
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('Плановые работы'), findsOneWidget);
    expect(rpc.productKeys, ['chatista']);

    await tester.tap(find.byKey(const Key('announcementDismiss')));
    await tester.pumpAndSettle();
    expect(rpc.seen, [1]);
  });

  testWidgets('пока диалог открыт — просмотр НЕ отмечен', (tester) async {
    // Отметить заранее значит потерять объявление у того, кто закрыл
    // приложение, не дочитав: сервер уже считает его прочитанным, а человек
    // его не видел. Повторный показ безобиднее пропажи.
    final rpc = _FakeRpc([_view()]);
    await tester.pumpWidget(
      _host((ctx) => showPendingAnnouncements(ctx, rpcOverride: rpc)),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('announcementDialog')), findsOneWidget);
    expect(rpc.seen, isEmpty, reason: 'отметка только после показа');
  });

  testWidgets('вид route: «Открыть» отдаёт маршрут и payload хосту', (
    tester,
  ) async {
    final rpc = _FakeRpc([
      _view(kind: 'route', route: '/works', payloadJson: '{"id":7}'),
    ]);
    String? gotRoute;
    String? gotPayload;
    await tester.pumpWidget(
      _host(
        (ctx) => showPendingAnnouncements(
          ctx,
          rpcOverride: rpc,
          onOpenRoute: (r, p) {
            gotRoute = r;
            gotPayload = p;
          },
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('announcementOpen')));
    await tester.pumpAndSettle();

    expect(gotRoute, '/works');
    expect(gotPayload, '{"id":7}');
    expect(rpc.seen, [1], reason: 'ушли по маршруту — объявление прочитано');
  });

  testWidgets('route без обработчика: кнопки нет, но текст читаем', (
    tester,
  ) async {
    // Хост может не уметь маршруты (или ещё не научиться). Показать кнопку,
    // которая никуда не ведёт, — хуже, чем не показать её: человек решит,
    // что приложение сломано. Текст при этом ценен сам по себе.
    final rpc = _FakeRpc([_view(kind: 'route', route: '/works')]);
    await tester.pumpWidget(
      _host((ctx) => showPendingAnnouncements(ctx, rpcOverride: rpc)),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('announcementOpen')), findsNothing);
    expect(find.text('Плановые работы'), findsOneWidget);
  });

  testWidgets('несколько объявлений показываются по очереди', (tester) async {
    final rpc = _FakeRpc([_view(id: 1), _view(id: 2)]);
    await tester.pumpWidget(
      _host((ctx) => showPendingAnnouncements(ctx, rpcOverride: rpc)),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('announcementDismiss')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('announcementDialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('announcementDismiss')));
    await tester.pumpAndSettle();
    expect(rpc.seen, [1, 2]);
  });

  group('Given вид link — кнопка на внешнюю ссылку', () {
    late _FakeLauncher launcher;
    late UrlLauncherPlatform previous;

    setUp(() {
      previous = UrlLauncherPlatform.instance;
      launcher = _FakeLauncher();
      UrlLauncherPlatform.instance = launcher;
    });

    tearDown(() => UrlLauncherPlatform.instance = previous);

    testWidgets('«Перейти» открывает ссылку БЕЗ колбэка хоста', (tester) async {
      // Внешний адрес значит одно и то же в любом приложении, поэтому его
      // открывает сам SDK. Требовать колбэк — значит получить продукт, где
      // объявление со ссылкой молчит, потому что интегратор про него не знал.
      final rpc = _FakeRpc([
        _view(kind: 'link', url: 'https://titan112.ru/app'),
      ]);
      await tester.pumpWidget(
        _host((ctx) => showPendingAnnouncements(ctx, rpcOverride: rpc)),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('Перейти'), findsOneWidget);
      await tester.tap(find.byKey(const Key('announcementOpen')));
      await tester.pumpAndSettle();

      expect(launcher.launched, ['https://titan112.ru/app']);
      expect(rpc.seen, [1]);
    });

    testWidgets('ссылка не-http схемы кнопки не даёт', (tester) async {
      // Открывает ссылку SDK, поэтому и проверяет её здесь: `javascript:`,
      // добравшийся сюда старой строкой в базе, увёл бы человека не туда
      // именно отсюда.
      final rpc = _FakeRpc([
        _view(kind: 'link', url: 'javascript:alert(1)'),
      ]);
      await tester.pumpWidget(
        _host((ctx) => showPendingAnnouncements(ctx, rpcOverride: rpc)),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('announcementOpen')), findsNothing);
      expect(find.text('Плановые работы'), findsOneWidget);
      expect(launcher.launched, isEmpty);
    });

    testWidgets('после ухода по ссылке остальные объявления показываются', (
      tester,
    ) async {
      // Браузер — чужое приложение, наш экран остаётся своим. В отличие от
      // route здесь показывать дальше можно: человек увидит, вернувшись.
      final rpc = _FakeRpc([
        _view(id: 1, kind: 'link', url: 'https://titan112.ru/app'),
        _view(id: 2),
      ]);
      await tester.pumpWidget(
        _host((ctx) => showPendingAnnouncements(ctx, rpcOverride: rpc)),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('announcementOpen')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('announcementDialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('announcementDismiss')));
      await tester.pumpAndSettle();
      expect(rpc.seen, [1, 2]);
    });
  });

  testWidgets('тело объявления — markdown, а не сырой текст', (tester) async {
    // Объявление пишет человек, и «**важно**» он расставит по той же
    // привычке, что и в чате. Показать звёздочки — значит показать разметку
    // вместо текста.
    final rpc = _FakeRpc([
      _view(body: 'Скачайте **новую** программу [ТИТАН](https://titan112.ru)'),
    ]);
    await tester.pumpWidget(
      _host((ctx) => showPendingAnnouncements(ctx, rpcOverride: rpc)),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    // Тело — единственный Text, собранный из спанов; заголовок и кнопки
    // остаются обычными строками.
    final body = tester.widget<Text>(
      find.byWidgetPredicate((w) => w is Text && w.textSpan != null),
    );
    expect(body.textSpan!.toPlainText(), 'Скачайте новую программу ТИТАН');
  });

  testWidgets('сбой сети не роняет вход в приложение', (tester) async {
    // Это фоновая любезность на старте. Не показать объявление неприятно,
    // уронить вход — несравнимо хуже.
    final rpc = _FakeRpc(const [], failPending: true);
    await tester.pumpWidget(
      _host((ctx) => showPendingAnnouncements(ctx, rpcOverride: rpc)),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('announcementDialog')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
