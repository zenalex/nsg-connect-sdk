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

/// Серверная запись о выданной сессии. После `MessengerEndpoint.session()`
/// мы кладём сюда `token` + ссылку на `messengerUserId`. Subsequent
/// RPC-вызовы клиента приходят с этим token-ом в Authorization header,
/// Serverpod authenticationHandler находит запись здесь и заполняет
/// `session.authenticated.authId == messengerUserId`. См. TASK12.
///
/// `expiresAt` — TTL сессии (default 24h в session()/refresh()).
/// `revokedAt` != null → токен отозван (logout / админ-revoke).
abstract class MessengerSessionToken implements _i1.SerializableModel {
  MessengerSessionToken._({
    this.id,
    required this.token,
    required this.messengerUserId,
    required this.expiresAt,
    this.revokedAt,
    required this.createdAt,
  });

  factory MessengerSessionToken({
    int? id,
    required String token,
    required int messengerUserId,
    required DateTime expiresAt,
    DateTime? revokedAt,
    required DateTime createdAt,
  }) = _MessengerSessionTokenImpl;

  factory MessengerSessionToken.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MessengerSessionToken(
      id: jsonSerialization['id'] as int?,
      token: jsonSerialization['token'] as String,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String token;

  int messengerUserId;

  DateTime expiresAt;

  DateTime? revokedAt;

  DateTime createdAt;

  /// Returns a shallow copy of this [MessengerSessionToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MessengerSessionToken copyWith({
    int? id,
    String? token,
    int? messengerUserId,
    DateTime? expiresAt,
    DateTime? revokedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MessengerSessionToken',
      if (id != null) 'id': id,
      'token': token,
      'messengerUserId': messengerUserId,
      'expiresAt': expiresAt.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MessengerSessionTokenImpl extends MessengerSessionToken {
  _MessengerSessionTokenImpl({
    int? id,
    required String token,
    required int messengerUserId,
    required DateTime expiresAt,
    DateTime? revokedAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         token: token,
         messengerUserId: messengerUserId,
         expiresAt: expiresAt,
         revokedAt: revokedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [MessengerSessionToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MessengerSessionToken copyWith({
    Object? id = _Undefined,
    String? token,
    int? messengerUserId,
    DateTime? expiresAt,
    Object? revokedAt = _Undefined,
    DateTime? createdAt,
  }) {
    return MessengerSessionToken(
      id: id is int? ? id : this.id,
      token: token ?? this.token,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      expiresAt: expiresAt ?? this.expiresAt,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
