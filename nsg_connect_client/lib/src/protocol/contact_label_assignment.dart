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

/// **TASK63**: M2M «метка ↔ контакт». Cascade от метки (удаление метки
/// снимает её со всех). Contact — plain int (см. ContactMeta).
abstract class ContactLabelAssignment implements _i1.SerializableModel {
  ContactLabelAssignment._({
    this.id,
    required this.labelId,
    required this.contactMessengerUserId,
    required this.createdAt,
  });

  factory ContactLabelAssignment({
    int? id,
    required int labelId,
    required int contactMessengerUserId,
    required DateTime createdAt,
  }) = _ContactLabelAssignmentImpl;

  factory ContactLabelAssignment.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ContactLabelAssignment(
      id: jsonSerialization['id'] as int?,
      labelId: jsonSerialization['labelId'] as int,
      contactMessengerUserId:
          jsonSerialization['contactMessengerUserId'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int labelId;

  int contactMessengerUserId;

  DateTime createdAt;

  /// Returns a shallow copy of this [ContactLabelAssignment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ContactLabelAssignment copyWith({
    int? id,
    int? labelId,
    int? contactMessengerUserId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContactLabelAssignment',
      if (id != null) 'id': id,
      'labelId': labelId,
      'contactMessengerUserId': contactMessengerUserId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ContactLabelAssignmentImpl extends ContactLabelAssignment {
  _ContactLabelAssignmentImpl({
    int? id,
    required int labelId,
    required int contactMessengerUserId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         labelId: labelId,
         contactMessengerUserId: contactMessengerUserId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ContactLabelAssignment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ContactLabelAssignment copyWith({
    Object? id = _Undefined,
    int? labelId,
    int? contactMessengerUserId,
    DateTime? createdAt,
  }) {
    return ContactLabelAssignment(
      id: id is int? ? id : this.id,
      labelId: labelId ?? this.labelId,
      contactMessengerUserId:
          contactMessengerUserId ?? this.contactMessengerUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
