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
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i2;

/// Серверная сессия, выдаваемая SDK после успешного `session()`.
/// См. ТЗ §7, TASK05/TASK12.
///
/// sessionToken — opaque server-generated значение; SDK хранит его
/// и пробрасывает в последующие endpoint-ы. Реальная привязка к
/// Serverpod auth-сервисам — задача TASK12 (там же refresh-цикл).
abstract class MessengerSession implements _i1.SerializableModel {
  MessengerSession._({
    required this.sessionToken,
    required this.messengerUserId,
    required this.matrixUserId,
    required this.tenantId,
    this.productId,
    this.displayName,
    this.avatarUrl,
    required this.expiresAt,
    bool? crmEnabled,
    this.crmRoles,
    this.crmAgentRoomId,
  }) : crmEnabled = crmEnabled ?? false;

  factory MessengerSession({
    required String sessionToken,
    required int messengerUserId,
    required String matrixUserId,
    required int tenantId,
    int? productId,
    String? displayName,
    String? avatarUrl,
    required DateTime expiresAt,
    bool? crmEnabled,
    List<String>? crmRoles,
    int? crmAgentRoomId,
  }) = _MessengerSessionImpl;

  factory MessengerSession.fromJson(Map<String, dynamic> jsonSerialization) {
    return MessengerSession(
      sessionToken: jsonSerialization['sessionToken'] as String,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      matrixUserId: jsonSerialization['matrixUserId'] as String,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int?,
      displayName: jsonSerialization['displayName'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      crmEnabled: jsonSerialization['crmEnabled'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['crmEnabled']),
      crmRoles: jsonSerialization['crmRoles'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['crmRoles'],
            ),
      crmAgentRoomId: jsonSerialization['crmAgentRoomId'] as int?,
    );
  }

  String sessionToken;

  int messengerUserId;

  String matrixUserId;

  int tenantId;

  int? productId;

  String? displayName;

  String? avatarUrl;

  DateTime expiresAt;

  /// Server-derived CRM module state; input cannot grant a role.
  bool crmEnabled;

  List<String>? crmRoles;

  int? crmAgentRoomId;

  /// Returns a shallow copy of this [MessengerSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MessengerSession copyWith({
    String? sessionToken,
    int? messengerUserId,
    String? matrixUserId,
    int? tenantId,
    int? productId,
    String? displayName,
    String? avatarUrl,
    DateTime? expiresAt,
    bool? crmEnabled,
    List<String>? crmRoles,
    int? crmAgentRoomId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MessengerSession',
      'sessionToken': sessionToken,
      'messengerUserId': messengerUserId,
      'matrixUserId': matrixUserId,
      'tenantId': tenantId,
      if (productId != null) 'productId': productId,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'expiresAt': expiresAt.toJson(),
      'crmEnabled': crmEnabled,
      if (crmRoles != null) 'crmRoles': crmRoles?.toJson(),
      if (crmAgentRoomId != null) 'crmAgentRoomId': crmAgentRoomId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MessengerSessionImpl extends MessengerSession {
  _MessengerSessionImpl({
    required String sessionToken,
    required int messengerUserId,
    required String matrixUserId,
    required int tenantId,
    int? productId,
    String? displayName,
    String? avatarUrl,
    required DateTime expiresAt,
    bool? crmEnabled,
    List<String>? crmRoles,
    int? crmAgentRoomId,
  }) : super._(
         sessionToken: sessionToken,
         messengerUserId: messengerUserId,
         matrixUserId: matrixUserId,
         tenantId: tenantId,
         productId: productId,
         displayName: displayName,
         avatarUrl: avatarUrl,
         expiresAt: expiresAt,
         crmEnabled: crmEnabled,
         crmRoles: crmRoles,
         crmAgentRoomId: crmAgentRoomId,
       );

  /// Returns a shallow copy of this [MessengerSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MessengerSession copyWith({
    String? sessionToken,
    int? messengerUserId,
    String? matrixUserId,
    int? tenantId,
    Object? productId = _Undefined,
    Object? displayName = _Undefined,
    Object? avatarUrl = _Undefined,
    DateTime? expiresAt,
    bool? crmEnabled,
    Object? crmRoles = _Undefined,
    Object? crmAgentRoomId = _Undefined,
  }) {
    return MessengerSession(
      sessionToken: sessionToken ?? this.sessionToken,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      matrixUserId: matrixUserId ?? this.matrixUserId,
      tenantId: tenantId ?? this.tenantId,
      productId: productId is int? ? productId : this.productId,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      expiresAt: expiresAt ?? this.expiresAt,
      crmEnabled: crmEnabled ?? this.crmEnabled,
      crmRoles: crmRoles is List<String>?
          ? crmRoles
          : this.crmRoles?.map((e0) => e0).toList(),
      crmAgentRoomId: crmAgentRoomId is int?
          ? crmAgentRoomId
          : this.crmAgentRoomId,
    );
  }
}
