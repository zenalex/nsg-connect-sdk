import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger_push/src/call_push_presenter.dart';

/// **TASK51 чанк 4 (CallKit-коллапс)**: гард повторного показа «входящего».
///
/// Плагин `flutter_callkit_incoming` идемпотентным по id НЕ является: на
/// Android повторный `showCallkitIncoming` с тем же id заново заводит
/// рингтон и full-screen-intent. Основной механизм схлопывания —
/// одинаковый `CallPushData.callKitId` у всех побудок конференции; этот
/// гард — второй рубеж на случай доставки в обход серверного дедупа.
void main() {
  group('CallPushPresenter.shouldSkipDuplicateShow', () {
    final now = DateTime.utc(2026, 7, 22, 12, 0, 0);
    const confKitId = '01234567-89ab-cdef-0123-456789abcdef';

    test('первый показ (ничего не показывали) → не пропускаем', () {
      expect(
        CallPushPresenter.shouldSkipDuplicateShow(
          callKitId: confKitId,
          lastShownId: null,
          lastShownAt: null,
          now: now,
        ),
        isFalse,
      );
    });

    test('тот же id внутри окна → пропускаем (главный кейс)', () {
      expect(
        CallPushPresenter.shouldSkipDuplicateShow(
          callKitId: confKitId,
          lastShownId: confKitId,
          lastShownAt: now.subtract(const Duration(seconds: 3)),
          now: now,
        ),
        isTrue,
      );
    });

    test('другой id → показываем (это другой звонок)', () {
      expect(
        CallPushPresenter.shouldSkipDuplicateShow(
          callKitId: confKitId,
          lastShownId: 'call-uuid-1',
          lastShownAt: now.subtract(const Duration(seconds: 3)),
          now: now,
        ),
        isFalse,
      );
    });

    test('тот же id за окном → показываем снова', () {
      // Прежний «входящий» система уже сняла как пропущенный; конференция
      // может ещё идти — второй шанс ответить нужен.
      expect(
        CallPushPresenter.shouldSkipDuplicateShow(
          callKitId: confKitId,
          lastShownId: confKitId,
          lastShownAt: now.subtract(const Duration(seconds: 61)),
          now: now,
        ),
        isFalse,
      );
    });

    test('окно = 60с (совпадает с duration «входящего»)', () {
      expect(
        CallPushPresenter.duplicateShowWindow,
        const Duration(seconds: 60),
      );
      // Ровно на границе окна — уже не дубль.
      expect(
        CallPushPresenter.shouldSkipDuplicateShow(
          callKitId: confKitId,
          lastShownId: confKitId,
          lastShownAt: now.subtract(CallPushPresenter.duplicateShowWindow),
          now: now,
        ),
        isFalse,
      );
    });
  });

  /// **issue #180 — чем подписан экран входящего звонка.**
  ///
  /// На iOS это `CXProviderConfiguration.localizedName`: система пишет им
  /// «через <имя>». Здесь было зашито имя нашего приложения, а SDK
  /// встраивают чужие продукты — их пользователь видел чужой бренд на
  /// одном из самых заметных системных экранов.
  group('CallPushPresenter.resolveAppName', () {
    setUp(() {
      CallPushPresenter.appNameOverride = null;
      CallPushPresenter.resetAppNameCache();
    });
    tearDown(() {
      CallPushPresenter.appNameOverride = null;
      CallPushPresenter.resetAppNameCache();
    });

    test('хост назвался сам — берём его слово', () async {
      CallPushPresenter.appNameOverride = 'Титан ЛК';
      final name = await CallPushPresenter.resolveAppName(
        platformName: () async => 'не должно спрашиваться',
      );
      expect(name, 'Титан ЛК');
    });

    test('хост молчит — спрашиваем платформу', () async {
      final name = await CallPushPresenter.resolveAppName(
        platformName: () async => 'CHATista',
      );
      expect(name, 'CHATista');
    });

    // Плагины в фоновом изоляте могли не подняться. Пропущенный звонок —
    // цена несопоставимо большая, чем неподписанный экран.
    test('платформа не отвечает — null, но не исключение', () async {
      final name = await CallPushPresenter.resolveAppName(
        platformName: () async => throw StateError('нет плагина'),
      );
      expect(name, isNull);
    });

    test('второй раз платформу не дёргаем', () async {
      var calls = 0;
      Future<String> probe() async {
        calls++;
        return 'CHATista';
      }

      await CallPushPresenter.resolveAppName(platformName: probe);
      await CallPushPresenter.resolveAppName(platformName: probe);
      expect(calls, 1, reason: 'звонок не должен ждать повторного опроса');
    });

    test('пустое имя от платформы — тоже null', () async {
      final name = await CallPushPresenter.resolveAppName(
        platformName: () async => '   ',
      );
      expect(name, isNull);
    });
  });
}
