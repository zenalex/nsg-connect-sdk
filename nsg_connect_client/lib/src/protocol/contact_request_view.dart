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

/// **TASK52 итер.2**: входящая заявка глазами получателя — id заявки +
/// публичные поля отправителя (для строки списка / интро-карточки).
/// Визитку отправителя UI дочитывает через getContactCard.
abstract class ContactRequestView implements _i1.SerializableModel {
  ContactRequestView._({
    required this.requestId,
    required this.fromMessengerUserId,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.note,
    required this.createdAt,
  });

  factory ContactRequestView({
    required int requestId,
    required int fromMessengerUserId,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? note,
    required DateTime createdAt,
  }) = _ContactRequestViewImpl;

  factory ContactRequestView.fromJson(Map<String, dynamic> jsonSerialization) {
    return ContactRequestView(
      requestId: jsonSerialization['requestId'] as int,
      fromMessengerUserId: jsonSerialization['fromMessengerUserId'] as int,
      displayName: jsonSerialization['displayName'] as String?,
      username: jsonSerialization['username'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      note: jsonSerialization['note'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int requestId;

  int fromMessengerUserId;

  String? displayName;

  String? username;

  String? avatarUrl;

  String? note;

  DateTime createdAt;

  /// Returns a shallow copy of this [ContactRequestView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ContactRequestView copyWith({
    int? requestId,
    int? fromMessengerUserId,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? note,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContactRequestView',
      'requestId': requestId,
      'fromMessengerUserId': fromMessengerUserId,
      if (displayName != null) 'displayName': displayName,
      if (username != null) 'username': username,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (note != null) 'note': note,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ContactRequestViewImpl extends ContactRequestView {
  _ContactRequestViewImpl({
    required int requestId,
    required int fromMessengerUserId,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? note,
    required DateTime createdAt,
  }) : super._(
         requestId: requestId,
         fromMessengerUserId: fromMessengerUserId,
         displayName: displayName,
         username: username,
         avatarUrl: avatarUrl,
         note: note,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ContactRequestView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ContactRequestView copyWith({
    int? requestId,
    int? fromMessengerUserId,
    Object? displayName = _Undefined,
    Object? username = _Undefined,
    Object? avatarUrl = _Undefined,
    Object? note = _Undefined,
    DateTime? createdAt,
  }) {
    return ContactRequestView(
      requestId: requestId ?? this.requestId,
      fromMessengerUserId: fromMessengerUserId ?? this.fromMessengerUserId,
      displayName: displayName is String? ? displayName : this.displayName,
      username: username is String? ? username : this.username,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      note: note is String? ? note : this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
