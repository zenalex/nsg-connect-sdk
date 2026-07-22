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
}
