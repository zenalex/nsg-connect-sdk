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

/// **Исключение тенантного участника из КОНКРЕТНОЙ команды.**
///
/// Наследование от тенанта живое, но бывает продукт, который конкретному
/// оператору вести не нужно. Убрать его из списка тенанта нельзя — он
/// пропал бы во всех командах; значит нужен точечный отказ именно здесь.
///
/// Запись существует ТОЛЬКО для унаследованных людей. Обычного участника
/// команды удаляют удалением его membership-строки — заводить для этого
/// второй способ («исключение») означало бы два разных состояния для
/// одного и того же и вечный вопрос, какое главнее.
abstract class SupportTeamExclusion implements _i1.SerializableModel {
  SupportTeamExclusion._({
    this.id,
    required this.teamId,
    required this.messengerUserId,
    required this.createdAt,
  });

  factory SupportTeamExclusion({
    int? id,
    required int teamId,
    required int messengerUserId,
    required DateTime createdAt,
  }) = _SupportTeamExclusionImpl;

  factory SupportTeamExclusion.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return SupportTeamExclusion(
      id: jsonSerialization['id'] as int?,
      teamId: jsonSerialization['teamId'] as int,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int teamId;

  int messengerUserId;

  DateTime createdAt;

  /// Returns a shallow copy of this [SupportTeamExclusion]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SupportTeamExclusion copyWith({
    int? id,
    int? teamId,
    int? messengerUserId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SupportTeamExclusion',
      if (id != null) 'id': id,
      'teamId': teamId,
      'messengerUserId': messengerUserId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SupportTeamExclusionImpl extends SupportTeamExclusion {
  _SupportTeamExclusionImpl({
    int? id,
    required int teamId,
    required int messengerUserId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         teamId: teamId,
         messengerUserId: messengerUserId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [SupportTeamExclusion]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SupportTeamExclusion copyWith({
    Object? id = _Undefined,
    int? teamId,
    int? messengerUserId,
    DateTime? createdAt,
  }) {
    return SupportTeamExclusion(
      id: id is int? ? id : this.id,
      teamId: teamId ?? this.teamId,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
