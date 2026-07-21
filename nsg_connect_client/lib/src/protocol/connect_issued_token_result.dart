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

/// Ответ ConnectTokenEndpoint.issueToken (вариант C,
/// DESIGN_CONNECT_ISSUED_TOKENS.md). Это DTO (без `table:`) —
/// единственное место, где плейнтекст-токен существует: продукт-сервер
/// передаёт его своему клиенту, тот кладёт в
/// MessengerAuthContext.accessToken. В БД остаётся только sha256.
abstract class ConnectIssuedTokenResult implements _i1.SerializableModel {
  ConnectIssuedTokenResult._({
    required this.token,
    required this.expiresAt,
  });

  factory ConnectIssuedTokenResult({
    required String token,
    required DateTime expiresAt,
  }) = _ConnectIssuedTokenResultImpl;

  factory ConnectIssuedTokenResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConnectIssuedTokenResult(
      token: jsonSerialization['token'] as String,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  /// Одноразовый токен: base64url от 32 случайных байт (Random.secure).
  String token;

  /// Момент протухания (UTC). Клиент должен успеть вызвать
  /// MessengerEndpoint.session() до этого момента (TTL 5 минут).
  DateTime expiresAt;

  /// Returns a shallow copy of this [ConnectIssuedTokenResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConnectIssuedTokenResult copyWith({
    String? token,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConnectIssuedTokenResult',
      'token': token,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ConnectIssuedTokenResultImpl extends ConnectIssuedTokenResult {
  _ConnectIssuedTokenResultImpl({
    required String token,
    required DateTime expiresAt,
  }) : super._(
         token: token,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [ConnectIssuedTokenResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConnectIssuedTokenResult copyWith({
    String? token,
    DateTime? expiresAt,
  }) {
    return ConnectIssuedTokenResult(
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
