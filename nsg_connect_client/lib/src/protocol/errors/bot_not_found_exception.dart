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

/// **Issue #49 (myBots)**: бот не найден. Бросается myBots-методами и
/// когда botId не существует, и когда бот существует, но принадлежит
/// ДРУГОМУ владельцу — различать эти случаи наружу нельзя
/// (anti-enumeration: иначе перебором botId можно выяснять, какие id
/// заняты).
abstract class BotNotFoundException
    implements _i1.SerializableException, _i1.SerializableModel {
  BotNotFoundException._({required this.botId});

  factory BotNotFoundException({required int botId}) =
      _BotNotFoundExceptionImpl;

  factory BotNotFoundException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BotNotFoundException(botId: jsonSerialization['botId'] as int);
  }

  /// Запрошенный botId — для сообщения об ошибке в UI/логах клиента.
  int botId;

  /// Returns a shallow copy of this [BotNotFoundException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BotNotFoundException copyWith({int? botId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BotNotFoundException',
      'botId': botId,
    };
  }

  @override
  String toString() {
    return 'BotNotFoundException(botId: $botId)';
  }
}

class _BotNotFoundExceptionImpl extends BotNotFoundException {
  _BotNotFoundExceptionImpl({required int botId}) : super._(botId: botId);

  /// Returns a shallow copy of this [BotNotFoundException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BotNotFoundException copyWith({int? botId}) {
    return BotNotFoundException(botId: botId ?? this.botId);
  }
}
