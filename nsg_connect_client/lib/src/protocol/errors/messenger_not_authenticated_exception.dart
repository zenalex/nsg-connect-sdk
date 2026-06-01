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

/// Бросается endpoint-методами TASK12 Chunk 2, когда session
/// не аутентифицирована как messenger-юзер: либо `Authorization`
/// отсутствует, либо токен прошёл через JWT-fallback (admin/email-IDP
/// без префикса `mu:`), либо messenger-токен был отозван/истёк и
/// auth handler не вернул AuthenticationInfo.
///
/// SDK на стороне клиента видит этот typed exception в Serverpod-канале
/// (codegen-ится в client-пакете) и решает: попробовать `refresh()`,
/// повторить вызов, либо позвать AuthTokenProvider за свежим контекстом.
/// Реальная логика 401-retry — Chunk 3.
///
/// Поле `reason` — устаревшее без подтверждения; endpoint в большинстве
/// случаев не знает, ПОЧЕМУ session не аутентифицирована (auth handler
/// уже отработал и просто вернул null/wrong-scheme). Поэтому держим
/// exception БЕЗ полей: семантика «401, попробуй refresh» одинаковая
/// для всех случаев. Если в TASK24 (security hardening) auth handler
/// начнёт логировать причину null-ответа, можно будет добавить hint-поле
/// без breaking change.
abstract class MessengerNotAuthenticatedException
    implements _i1.SerializableException, _i1.SerializableModel {
  MessengerNotAuthenticatedException._({this.hint});

  factory MessengerNotAuthenticatedException({String? hint}) =
      _MessengerNotAuthenticatedExceptionImpl;

  factory MessengerNotAuthenticatedException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MessengerNotAuthenticatedException(
      hint: jsonSerialization['hint'] as String?,
    );
  }

  /// Минимальный hint для отладки, БЕЗ utility-логики на клиенте.
  /// Заполняется endpoint-ом в момент броска и помогает отличить
  /// "не было токена" от "не тот scheme" в логах. Не PII.
  String? hint;

  /// Returns a shallow copy of this [MessengerNotAuthenticatedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MessengerNotAuthenticatedException copyWith({String? hint});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MessengerNotAuthenticatedException',
      if (hint != null) 'hint': hint,
    };
  }

  @override
  String toString() {
    return 'MessengerNotAuthenticatedException(hint: $hint)';
  }
}

class _Undefined {}

class _MessengerNotAuthenticatedExceptionImpl
    extends MessengerNotAuthenticatedException {
  _MessengerNotAuthenticatedExceptionImpl({String? hint}) : super._(hint: hint);

  /// Returns a shallow copy of this [MessengerNotAuthenticatedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MessengerNotAuthenticatedException copyWith({Object? hint = _Undefined}) {
    return MessengerNotAuthenticatedException(
      hint: hint is String? ? hint : this.hint,
    );
  }
}
