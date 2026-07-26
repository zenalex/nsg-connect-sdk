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

/// **TASK77**: `setMyCommands` получил невалидный список команд.
///
/// Раньше валидация бросала `ArgumentError` — он НЕ serializable, поэтому
/// Serverpod отвечал `500` с пустым телом, и автор бота (в т.ч. внешний
/// разработчик) не мог понять, что именно не так: имя с пробелом, дубль,
/// превышенная длина или слишком много команд. Диагностика по HTTP 500 без
/// тела невозможна — а публичный справочник обещает внятные отказы.
///
/// Поле `reason` — короткая машинно-читаемая причина, `detail` — конкретика
/// для человека (какая команда/какое ограничение). Секретов не несёт: это
/// эхо того, что прислал сам вызывающий.
abstract class InvalidBotCommandsException
    implements _i1.SerializableException, _i1.SerializableModel {
  InvalidBotCommandsException._({
    required this.reason,
    required this.detail,
  });

  factory InvalidBotCommandsException({
    required String reason,
    required String detail,
  }) = _InvalidBotCommandsExceptionImpl;

  factory InvalidBotCommandsException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return InvalidBotCommandsException(
      reason: jsonSerialization['reason'] as String,
      detail: jsonSerialization['detail'] as String,
    );
  }

  /// `bad_name` | `empty_description` | `name_too_long` |
  /// `description_too_long` | `duplicate` | `too_many` | `malformed`.
  String reason;

  /// Человекочитаемое пояснение с конкретикой (напр. имя проблемной
  /// команды и нарушенный предел).
  String detail;

  /// Returns a shallow copy of this [InvalidBotCommandsException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  InvalidBotCommandsException copyWith({
    String? reason,
    String? detail,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InvalidBotCommandsException',
      'reason': reason,
      'detail': detail,
    };
  }

  @override
  String toString() {
    return 'InvalidBotCommandsException(reason: $reason, detail: $detail)';
  }
}

class _InvalidBotCommandsExceptionImpl extends InvalidBotCommandsException {
  _InvalidBotCommandsExceptionImpl({
    required String reason,
    required String detail,
  }) : super._(
         reason: reason,
         detail: detail,
       );

  /// Returns a shallow copy of this [InvalidBotCommandsException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  InvalidBotCommandsException copyWith({
    String? reason,
    String? detail,
  }) {
    return InvalidBotCommandsException(
      reason: reason ?? this.reason,
      detail: detail ?? this.detail,
    );
  }
}
