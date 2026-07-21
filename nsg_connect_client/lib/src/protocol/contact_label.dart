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

/// **TASK63**: метка (label) контактов — per-owner категория людей
/// («работа», «офис», «Москва»...). Приватна. Один контакт может нести
/// несколько меток ([ContactLabelAssignment]). Дефолтные метки в БД НЕ
/// сидируются — UI предлагает подсказки при пустом списке.
abstract class ContactLabel implements _i1.SerializableModel {
  ContactLabel._({
    this.id,
    required this.ownerMessengerUserId,
    required this.name,
    this.colorHex,
    int? sortOrder,
    required this.createdAt,
  }) : sortOrder = sortOrder ?? 0;

  factory ContactLabel({
    int? id,
    required int ownerMessengerUserId,
    required String name,
    String? colorHex,
    int? sortOrder,
    required DateTime createdAt,
  }) = _ContactLabelImpl;

  factory ContactLabel.fromJson(Map<String, dynamic> jsonSerialization) {
    return ContactLabel(
      id: jsonSerialization['id'] as int?,
      ownerMessengerUserId: jsonSerialization['ownerMessengerUserId'] as int,
      name: jsonSerialization['name'] as String,
      colorHex: jsonSerialization['colorHex'] as String?,
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

  int ownerMessengerUserId;

  /// Имя метки, trim, 1..32, уникально per owner.
  String name;

  /// Опциональный цвет чипа в UI, формат #RRGGBB.
  String? colorHex;

  int sortOrder;

  DateTime createdAt;

  /// Returns a shallow copy of this [ContactLabel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ContactLabel copyWith({
    int? id,
    int? ownerMessengerUserId,
    String? name,
    String? colorHex,
    int? sortOrder,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContactLabel',
      if (id != null) 'id': id,
      'ownerMessengerUserId': ownerMessengerUserId,
      'name': name,
      if (colorHex != null) 'colorHex': colorHex,
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

class _ContactLabelImpl extends ContactLabel {
  _ContactLabelImpl({
    int? id,
    required int ownerMessengerUserId,
    required String name,
    String? colorHex,
    int? sortOrder,
    required DateTime createdAt,
  }) : super._(
         id: id,
         ownerMessengerUserId: ownerMessengerUserId,
         name: name,
         colorHex: colorHex,
         sortOrder: sortOrder,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ContactLabel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ContactLabel copyWith({
    Object? id = _Undefined,
    int? ownerMessengerUserId,
    String? name,
    Object? colorHex = _Undefined,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return ContactLabel(
      id: id is int? ? id : this.id,
      ownerMessengerUserId: ownerMessengerUserId ?? this.ownerMessengerUserId,
      name: name ?? this.name,
      colorHex: colorHex is String? ? colorHex : this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
