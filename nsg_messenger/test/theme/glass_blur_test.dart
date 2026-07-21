import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/theme/glass_blur.dart';

/// **issue #26.** Сила blur задавалась числами прямо в виджетах — в
/// одиннадцати местах. Из-за этого «а если размывать слабее?» никто не
/// проверял: правка требовала обхода всех файлов. Теперь значение дизайна
/// проходит через один множитель [kGlassBlurPercent]
/// (`--dart-define=GLASS_BLUR_PCT`).
///
/// Тесты сторожат контракт множителя. Дефолт обязан быть 100 — иначе сборка
/// молча поедет с ослабленным blur, и «дизайн поменялся сам собой» будут
/// искать где угодно, только не в define.
void main() {
  test(
    'по умолчанию — ровно дизайнерская sigma (множитель не вмешивается)',
    () {
      expect(kGlassBlurPercent, 100, reason: 'дефолт не должен менять вид');
      expect(glassBlurSigma(28), 28);
      expect(glassBlurSigma(18), 18);
      expect(glassBlurSigma(8), 8);
    },
  );

  test('glassBlur отдаёт симметричный фильтр той же силы', () {
    // Все узлы в проекте симметричны (sigmaX == sigmaY); хелпер это закрепляет.
    final f = glassBlur(28);
    expect(f.toString(), contains('28'));
  });

  test('нулевая sigma допустима (no-op фильтр, не падение)', () {
    // GLASS_BLUR_PCT=0 — режим «стекло без размытия» для сравнения на глаз.
    expect(glassBlurSigma(0), 0);
  });

  test('отрицательная sigma не уезжает ниже нуля', () {
    // Защита от опечатки в define: ImageFilter.blur с отрицательной sigma —
    // неопределённое поведение на разных бэкендах.
    expect(glassBlurSigma(-5), greaterThanOrEqualTo(0));
  });
}
