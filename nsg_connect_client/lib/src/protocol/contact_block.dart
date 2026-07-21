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

/// **TASK52 итер.2 (§3B.8a)**: блокировка — owner запретил target-у
/// писать/навязываться. Минимальный примитив (полный compliance —
/// TASK29 Phase2): гейт в createDirect (неотличимо от not-found) +
/// подавление push от заблокированного в существующих общих комнатах.
/// owner/target — plain int (конвенция contact_meta).
abstract class ContactBlock implements _i1.SerializableModel {
  ContactBlock._({
    this.id,
    required this.ownerMessengerUserId,
    required this.targetMessengerUserId,
    required this.createdAt,
  });

  factory ContactBlock({
    int? id,
    required int ownerMessengerUserId,
    required int targetMessengerUserId,
    required DateTime createdAt,
  }) = _ContactBlockImpl;

  factory ContactBlock.fromJson(Map<String, dynamic> jsonSerialization) {
    return ContactBlock(
      id: jsonSerialization['id'] as int?,
      ownerMessengerUserId: jsonSerialization['ownerMessengerUserId'] as int,
      targetMessengerUserId: jsonSerialization['targetMessengerUserId'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int ownerMessengerUserId;

  int targetMessengerUserId;

  DateTime createdAt;

  /// Returns a shallow copy of this [ContactBlock]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ContactBlock copyWith({
    int? id,
    int? ownerMessengerUserId,
    int? targetMessengerUserId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContactBlock',
      if (id != null) 'id': id,
      'ownerMessengerUserId': ownerMessengerUserId,
      'targetMessengerUserId': targetMessengerUserId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ContactBlockImpl extends ContactBlock {
  _ContactBlockImpl({
    int? id,
    required int ownerMessengerUserId,
    required int targetMessengerUserId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         ownerMessengerUserId: ownerMessengerUserId,
         targetMessengerUserId: targetMessengerUserId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ContactBlock]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ContactBlock copyWith({
    Object? id = _Undefined,
    int? ownerMessengerUserId,
    int? targetMessengerUserId,
    DateTime? createdAt,
  }) {
    return ContactBlock(
      id: id is int? ? id : this.id,
      ownerMessengerUserId: ownerMessengerUserId ?? this.ownerMessengerUserId,
      targetMessengerUserId:
          targetMessengerUserId ?? this.targetMessengerUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
