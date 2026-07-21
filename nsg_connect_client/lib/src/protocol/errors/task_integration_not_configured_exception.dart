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

/// **TASK38**: для tenant-а (и продукта) нет enabled-конфига интеграции
/// с таск-трекером. Бросается из TaskService.createTaskFromMessage когда
/// `TaskManagerConfig` не найден / disabled. `hint` — подсказка админу
/// (какой tenant/product нужно сконфигурировать).
abstract class TaskIntegrationNotConfiguredException
    implements _i1.SerializableException, _i1.SerializableModel {
  TaskIntegrationNotConfiguredException._({this.hint});

  factory TaskIntegrationNotConfiguredException({String? hint}) =
      _TaskIntegrationNotConfiguredExceptionImpl;

  factory TaskIntegrationNotConfiguredException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return TaskIntegrationNotConfiguredException(
      hint: jsonSerialization['hint'] as String?,
    );
  }

  String? hint;

  /// Returns a shallow copy of this [TaskIntegrationNotConfiguredException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TaskIntegrationNotConfiguredException copyWith({String? hint});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TaskIntegrationNotConfiguredException',
      if (hint != null) 'hint': hint,
    };
  }

  @override
  String toString() {
    return 'TaskIntegrationNotConfiguredException(hint: $hint)';
  }
}

class _Undefined {}

class _TaskIntegrationNotConfiguredExceptionImpl
    extends TaskIntegrationNotConfiguredException {
  _TaskIntegrationNotConfiguredExceptionImpl({String? hint})
    : super._(hint: hint);

  /// Returns a shallow copy of this [TaskIntegrationNotConfiguredException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TaskIntegrationNotConfiguredException copyWith({Object? hint = _Undefined}) {
    return TaskIntegrationNotConfiguredException(
      hint: hint is String? ? hint : this.hint,
    );
  }
}
