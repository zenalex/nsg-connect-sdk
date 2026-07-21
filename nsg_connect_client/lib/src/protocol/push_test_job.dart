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

/// TASK61: аргумент отложенного FutureCall доставки тестового пуша.
/// FutureCall выполняется в свежей сессии БЕЗ auth, поэтому
/// messengerUserId передаётся явно (не резолвится из session).
abstract class PushTestJob implements _i1.SerializableModel {
  PushTestJob._({required this.messengerUserId});

  factory PushTestJob({required int messengerUserId}) = _PushTestJobImpl;

  factory PushTestJob.fromJson(Map<String, dynamic> jsonSerialization) {
    return PushTestJob(
      messengerUserId: jsonSerialization['messengerUserId'] as int,
    );
  }

  int messengerUserId;

  /// Returns a shallow copy of this [PushTestJob]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PushTestJob copyWith({int? messengerUserId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PushTestJob',
      'messengerUserId': messengerUserId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PushTestJobImpl extends PushTestJob {
  _PushTestJobImpl({required int messengerUserId})
    : super._(messengerUserId: messengerUserId);

  /// Returns a shallow copy of this [PushTestJob]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PushTestJob copyWith({int? messengerUserId}) {
    return PushTestJob(
      messengerUserId: messengerUserId ?? this.messengerUserId,
    );
  }
}
