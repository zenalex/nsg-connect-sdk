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

/// PulseFolder — папка дерева мониторинга (TASK60, Connect Pulse).
/// Статус папки НЕ хранится: roll-up = worst-of(дети) вычисляется на клиенте
/// из плоских списков папок/мониторов (объёмы копеечные).
/// `parentId` — plain int? (не FK-relation): самоссылка усложняет миграцию,
/// удаление непустой папки запрещено на уровне endpoint-а.
abstract class PulseFolder implements _i1.SerializableModel {
  PulseFolder._({
    this.id,
    required this.tenantId,
    this.parentId,
    required this.name,
    int? sortOrder,
    required this.createdAt,
  }) : sortOrder = sortOrder ?? 0;

  factory PulseFolder({
    int? id,
    required int tenantId,
    int? parentId,
    required String name,
    int? sortOrder,
    required DateTime createdAt,
  }) = _PulseFolderImpl;

  factory PulseFolder.fromJson(Map<String, dynamic> jsonSerialization) {
    return PulseFolder(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      parentId: jsonSerialization['parentId'] as int?,
      name: jsonSerialization['name'] as String,
      sortOrder: jsonSerialization['sortOrder'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int tenantId;

  /// null = корень дерева.
  int? parentId;

  String name;

  int sortOrder;

  DateTime createdAt;

  /// Returns a shallow copy of this [PulseFolder]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PulseFolder copyWith({
    int? id,
    int? tenantId,
    int? parentId,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PulseFolder',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      if (parentId != null) 'parentId': parentId,
      'name': name,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PulseFolderImpl extends PulseFolder {
  _PulseFolderImpl({
    int? id,
    required int tenantId,
    int? parentId,
    required String name,
    int? sortOrder,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         parentId: parentId,
         name: name,
         sortOrder: sortOrder,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PulseFolder]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PulseFolder copyWith({
    Object? id = _Undefined,
    int? tenantId,
    Object? parentId = _Undefined,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return PulseFolder(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      parentId: parentId is int? ? parentId : this.parentId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
