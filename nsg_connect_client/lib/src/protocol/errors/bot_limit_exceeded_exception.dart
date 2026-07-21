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

/// **Issue #49 (myBots)**: у владельца уже [limit] ботов — создание
/// отклонено. Типизированное (а не ArgumentError), чтобы клиент показал
/// человекочитаемое «достигнут лимит N», а не generic-ошибку.
abstract class BotLimitExceededException
    implements _i1.SerializableException, _i1.SerializableModel {
  BotLimitExceededException._({required this.limit});

  factory BotLimitExceededException({required int limit}) =
      _BotLimitExceededExceptionImpl;

  factory BotLimitExceededException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BotLimitExceededException(limit: jsonSerialization['limit'] as int);
  }

  /// Действующий лимит ботов на владельца (BotService.maxBotsPerOwner).
  int limit;

  /// Returns a shallow copy of this [BotLimitExceededException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BotLimitExceededException copyWith({int? limit});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BotLimitExceededException',
      'limit': limit,
    };
  }

  @override
  String toString() {
    return 'BotLimitExceededException(limit: $limit)';
  }
}

class _BotLimitExceededExceptionImpl extends BotLimitExceededException {
  _BotLimitExceededExceptionImpl({required int limit}) : super._(limit: limit);

  /// Returns a shallow copy of this [BotLimitExceededException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BotLimitExceededException copyWith({int? limit}) {
    return BotLimitExceededException(limit: limit ?? this.limit);
  }
}
