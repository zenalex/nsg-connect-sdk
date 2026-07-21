/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// **TASK72**: итоговый статус приёма одного продуктового уведомления
/// (одна строка журнала `ProductNotification` = один адресат).
///
/// Значения намеренно описывают, что произошло НА ПРИЁМЕ (резолв +
/// enqueue), а не фактическую доставку на устройство: сам push уходит
/// через `pushQueueChannel` → `PushQueueWorker` → FCM/RuStore-адаптер
/// асинхронно, и per-device успех/провал в этот слой НЕ возвращается
/// (см. решение о retry в `ProductNotificationService`).
///
///   * `delivered`  — резолв нашёл ≥1 устройство, payload-ы поставлены
///                    в очередь (аналог «enqueued»; для продукта это и
///                    есть успех приёма).
///   * `deduped`    — повтор по (productId, effectiveIdempotencyKey):
///                    строка уже была, второй push НЕ ставится в очередь.
///   * `noDevices`  — пользователь резолвится, но у него нет ни одного
///                    подходящего push-токена (не заходил / вышел).
///   * `partial`    — ЗАРЕЗЕРВИРОВАНО: часть устройств не приняла payload.
///                    В текущей итерации не производится (per-device
///                    статуса нет); заведено под follow-up с обратной
///                    связью от воркера.
///   * `failed`     — ЗАРЕЗЕРВИРОВАНО: приём сорвался целиком (та же
///                    причина — нужен per-delivery статус). Ошибки
///                    текущей итерации летят в session.log/Sentry, а
///                    строка журнала до enqueue просто не создаётся.
enum ProductNotificationStatus implements _i1.SerializableModel {
  delivered,
  partial,
  failed,
  deduped,
  noDevices;

  static ProductNotificationStatus fromJson(String name) {
    switch (name) {
      case 'delivered':
        return ProductNotificationStatus.delivered;
      case 'partial':
        return ProductNotificationStatus.partial;
      case 'failed':
        return ProductNotificationStatus.failed;
      case 'deduped':
        return ProductNotificationStatus.deduped;
      case 'noDevices':
        return ProductNotificationStatus.noDevices;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ProductNotificationStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
