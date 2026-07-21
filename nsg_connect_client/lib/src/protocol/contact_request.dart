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
import 'enums/contact_request_status.dart' as _i2;

/// **TASK52 итер.2 (§8)**: карточка-заявка «показать свою визитку» —
/// когда гейт whoCanMessageMe='contacts' отбивает незнакомца, он шлёт
/// заявку; получатель принимает → взаимный ContactLink + direct.
///
/// Анти-абьюз (§8): максимум ОДНА активная (pending) заявка на пару
/// from→to; cooldown ~7 дней на повтор после declined; дневной лимит
/// заявок на отправителя; заявка заблокировавшему — тихо «в никуда»
/// (сервис не создаёт строку, но наружу — как отправлено).
/// from/to — plain int (конвенция contact_meta).
abstract class ContactRequest implements _i1.SerializableModel {
  ContactRequest._({
    this.id,
    required this.fromMessengerUserId,
    required this.toMessengerUserId,
    required this.status,
    this.note,
    required this.createdAt,
    this.respondedAt,
  });

  factory ContactRequest({
    int? id,
    required int fromMessengerUserId,
    required int toMessengerUserId,
    required _i2.ContactRequestStatus status,
    String? note,
    required DateTime createdAt,
    DateTime? respondedAt,
  }) = _ContactRequestImpl;

  factory ContactRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return ContactRequest(
      id: jsonSerialization['id'] as int?,
      fromMessengerUserId: jsonSerialization['fromMessengerUserId'] as int,
      toMessengerUserId: jsonSerialization['toMessengerUserId'] as int,
      status: _i2.ContactRequestStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      note: jsonSerialization['note'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      respondedAt: jsonSerialization['respondedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['respondedAt'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int fromMessengerUserId;

  int toMessengerUserId;

  _i2.ContactRequestStatus status;

  /// Короткое сообщение-приписка к заявке (опционально, ≤200).
  String? note;

  DateTime createdAt;

  /// Момент ответа (accept/decline); null пока pending.
  DateTime? respondedAt;

  /// Returns a shallow copy of this [ContactRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ContactRequest copyWith({
    int? id,
    int? fromMessengerUserId,
    int? toMessengerUserId,
    _i2.ContactRequestStatus? status,
    String? note,
    DateTime? createdAt,
    DateTime? respondedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContactRequest',
      if (id != null) 'id': id,
      'fromMessengerUserId': fromMessengerUserId,
      'toMessengerUserId': toMessengerUserId,
      'status': status.toJson(),
      if (note != null) 'note': note,
      'createdAt': createdAt.toJson(),
      if (respondedAt != null) 'respondedAt': respondedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ContactRequestImpl extends ContactRequest {
  _ContactRequestImpl({
    int? id,
    required int fromMessengerUserId,
    required int toMessengerUserId,
    required _i2.ContactRequestStatus status,
    String? note,
    required DateTime createdAt,
    DateTime? respondedAt,
  }) : super._(
         id: id,
         fromMessengerUserId: fromMessengerUserId,
         toMessengerUserId: toMessengerUserId,
         status: status,
         note: note,
         createdAt: createdAt,
         respondedAt: respondedAt,
       );

  /// Returns a shallow copy of this [ContactRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ContactRequest copyWith({
    Object? id = _Undefined,
    int? fromMessengerUserId,
    int? toMessengerUserId,
    _i2.ContactRequestStatus? status,
    Object? note = _Undefined,
    DateTime? createdAt,
    Object? respondedAt = _Undefined,
  }) {
    return ContactRequest(
      id: id is int? ? id : this.id,
      fromMessengerUserId: fromMessengerUserId ?? this.fromMessengerUserId,
      toMessengerUserId: toMessengerUserId ?? this.toMessengerUserId,
      status: status ?? this.status,
      note: note is String? ? note : this.note,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt is DateTime? ? respondedAt : this.respondedAt,
    );
  }
}
