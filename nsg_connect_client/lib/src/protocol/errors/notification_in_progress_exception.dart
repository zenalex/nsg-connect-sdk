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

/// **issue #161**: точно такой же вызов уже выполняется прямо сейчас.
///
/// Возникает, когда продукт повторил отправку, не дождавшись ответа на
/// первую — типично после клиентского таймаута. Рассылка на 500 адресатов
/// занимает секунды, и повтор в этот момент означал бы вторую такую же
/// порцию работы на уже занятом сервере. Отказ здесь дешевле для обеих
/// сторон.
///
/// **Это НЕ отказ в обслуживании и не ошибка вызова.** Первая отправка
/// идёт своим ходом; повторите запрос через `retryAfterSeconds` — и,
/// скорее всего, получите готовый ответ первой попытки (он держится
/// десять минут), не делая работу заново.
abstract class NotificationInProgressException
    implements _i1.SerializableException, _i1.SerializableModel {
  NotificationInProgressException._({required this.retryAfterSeconds});

  factory NotificationInProgressException({required int retryAfterSeconds}) =
      _NotificationInProgressExceptionImpl;

  factory NotificationInProgressException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return NotificationInProgressException(
      retryAfterSeconds: jsonSerialization['retryAfterSeconds'] as int,
    );
  }

  /// Через сколько секунд имеет смысл переспросить.
  int retryAfterSeconds;

  /// Returns a shallow copy of this [NotificationInProgressException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotificationInProgressException copyWith({int? retryAfterSeconds});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NotificationInProgressException',
      'retryAfterSeconds': retryAfterSeconds,
    };
  }

  @override
  String toString() {
    return 'NotificationInProgressException(retryAfterSeconds: $retryAfterSeconds)';
  }
}

class _NotificationInProgressExceptionImpl
    extends NotificationInProgressException {
  _NotificationInProgressExceptionImpl({required int retryAfterSeconds})
    : super._(retryAfterSeconds: retryAfterSeconds);

  /// Returns a shallow copy of this [NotificationInProgressException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotificationInProgressException copyWith({int? retryAfterSeconds}) {
    return NotificationInProgressException(
      retryAfterSeconds: retryAfterSeconds ?? this.retryAfterSeconds,
    );
  }
}
