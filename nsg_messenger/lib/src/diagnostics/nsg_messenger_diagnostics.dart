/// **Куда SDK отдаёт УСТОЙЧИВЫЕ отказы фоновых операций** (issue #117).
///
/// Фоновые операции (квитанция прочтения, синхронизация счётчиков) по
/// построению молчат: пользователю про них сказать нечего, а лог на каждый
/// сетевой чих на мобильном интернете бесполезен. Цена молчания вскрылась в
/// issue #112: markRead отвергался Matrix пять дней подряд у нескольких
/// человек, и единственным следом был бейдж непрочитанных, который не гас.
/// Нашлось раскопками в чужих логах.
///
/// Различать нужно не «сеть или не сеть» — тот отказ приезжал как 500 и по
/// любому классификатору считался бы преходящим, — а **преходящее или
/// постоянное**. Постоянное обязано доехать до трекера ошибок.
///
/// SDK не зависит от Sentry намеренно: он переиспользуется, и выбор трекера
/// — дело хоста. Здесь только точка подключения; `chatista` вешает на неё
/// `Sentry.captureException`.
library;

import 'package:flutter/foundation.dart';

/// Приёмник устойчивых отказов. `null` (никто не подключился) — пишем в
/// debug-лог и живём дальше: диагностика не имеет права ломать работу.
typedef NsgPersistentFailureSink =
    void Function(
      Object error,
      StackTrace? stack,
      Map<String, Object?> context,
    );

class NsgMessengerDiagnostics {
  NsgMessengerDiagnostics._();

  /// Ставится хостом один раз при старте.
  static NsgPersistentFailureSink? onPersistentFailure;

  /// Сообщить об отказе, который **повторяется** и сам не пройдёт.
  ///
  /// Зовущий обязан сам решить, что отказ устойчив (счётчик подряд идущих
  /// неудач, а не тип исключения), и сам обеспечить однократность: этот
  /// метод ничего не дедуплицирует.
  static void reportPersistent(
    Object error,
    StackTrace? stack,
    Map<String, Object?> context,
  ) {
    final sink = onPersistentFailure;
    if (sink == null) {
      if (kDebugMode) {
        debugPrint('[nsg.diagnostics] persistent failure $context: $error');
      }
      return;
    }
    // Сбой самой диагностики не имеет права уронить операцию, о которой
    // она сообщает.
    try {
      sink(error, stack, context);
    } catch (e) {
      if (kDebugMode) debugPrint('[nsg.diagnostics] sink failed: $e');
    }
  }

  /// Сброс между тестами.
  @visibleForTesting
  static void reset() => onPersistentFailure = null;
}
