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

/// **TASK91 (issue #65)**: отметка «этот человек объявление уже видел».
///
/// Отдельной строкой, а не флагом в самом объявлении: объявление одно на
/// многих, а «просмотрено» — у каждого своё. Из заявки: «показать текст один
/// раз потом просмотрено».
///
/// Уникальность по паре — чтобы повторный тап «Понятно» (двойное нажатие,
/// ретрай на плохой сети) не плодил строки и не требовал от клиента
/// сообразительности.
abstract class AnnouncementSeen implements _i1.SerializableModel {
  AnnouncementSeen._({
    this.id,
    required this.announcementId,
    required this.messengerUserId,
    required this.seenAt,
  });

  factory AnnouncementSeen({
    int? id,
    required int announcementId,
    required int messengerUserId,
    required DateTime seenAt,
  }) = _AnnouncementSeenImpl;

  factory AnnouncementSeen.fromJson(Map<String, dynamic> jsonSerialization) {
    return AnnouncementSeen(
      id: jsonSerialization['id'] as int?,
      announcementId: jsonSerialization['announcementId'] as int,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      seenAt: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['seenAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int announcementId;

  /// Cascade: удалили пользователя — его отметки уходят с ним.
  int messengerUserId;

  DateTime seenAt;

  /// Returns a shallow copy of this [AnnouncementSeen]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AnnouncementSeen copyWith({
    int? id,
    int? announcementId,
    int? messengerUserId,
    DateTime? seenAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AnnouncementSeen',
      if (id != null) 'id': id,
      'announcementId': announcementId,
      'messengerUserId': messengerUserId,
      'seenAt': seenAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AnnouncementSeenImpl extends AnnouncementSeen {
  _AnnouncementSeenImpl({
    int? id,
    required int announcementId,
    required int messengerUserId,
    required DateTime seenAt,
  }) : super._(
         id: id,
         announcementId: announcementId,
         messengerUserId: messengerUserId,
         seenAt: seenAt,
       );

  /// Returns a shallow copy of this [AnnouncementSeen]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AnnouncementSeen copyWith({
    Object? id = _Undefined,
    int? announcementId,
    int? messengerUserId,
    DateTime? seenAt,
  }) {
    return AnnouncementSeen(
      id: id is int? ? id : this.id,
      announcementId: announcementId ?? this.announcementId,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      seenAt: seenAt ?? this.seenAt,
    );
  }
}
