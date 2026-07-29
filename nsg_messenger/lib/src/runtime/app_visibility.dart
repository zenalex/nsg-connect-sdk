import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding;

/// **Видит ли человек приложение прямо сейчас.**
///
/// Обычно правду знает сам Flutter: [AppLifecycleState.resumed] — окно на
/// переднем плане и в фокусе. Но одну дыру биндинг не закрывает: **окно,
/// спрятанное в трей**, состояние жизненного цикла не меняет — приложение
/// остаётся `resumed`, хотя на экране его нет.
///
/// Цена этой дыры высокая. Клиент, считающий себя активным, подтверждает
/// доставку (см. `DeliveryAckSender`), а подтверждённое сообщение не
/// шлёт пуш НИКУДА — человек, ушедший от компьютера с приложением в
/// трее, остался бы без уведомлений на телефоне. Ровно та жалоба, с
/// которой начиналась работа над доставкой.
///
/// Поэтому host-app, умеющий прятать окно мимо жизненного цикла,
/// сообщает об этом сам — [setHidden].
class AppVisibility {
  AppVisibility._();

  static bool _hiddenByHost = false;

  /// Host-app спрятал окно (трей) или показал обратно.
  static void setHidden(bool hidden) => _hiddenByHost = hidden;

  /// Приложение перед человеком: и Flutter так считает, и host-app не
  /// сообщал об обратном.
  static bool get isActive =>
      !_hiddenByHost && _lifecycle() == AppLifecycleState.resumed;

  static AppLifecycleState _lifecycle() {
    try {
      return WidgetsBinding.instance.lifecycleState ??
          AppLifecycleState.resumed;
    } catch (_) {
      // Биндинг не инициализирован (чистый Dart-тест) — не наше дело.
      return AppLifecycleState.resumed;
    }
  }

  @visibleForTesting
  static void reset() => _hiddenByHost = false;
}
