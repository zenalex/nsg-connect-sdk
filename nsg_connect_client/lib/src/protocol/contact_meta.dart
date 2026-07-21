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

/// **TASK63**: per-viewer метаданные контакта — «своё имя» (alias) и
/// заметка. ПРИВАТНО: видит только owner; контакту не раскрывается
/// никогда. Owner/contact — plain int (два FK на одну таблицу
/// messenger_users конфликтуют по именам relation-ов; чистка при
/// удалении юзера — бэклог-джоба).
///
/// Строка живёт, пока есть содержимое: обе колонки пустые → сервис
/// удаляет строку (не копим пустышки).
abstract class ContactMeta implements _i1.SerializableModel {
  ContactMeta._({
    this.id,
    required this.ownerMessengerUserId,
    required this.contactMessengerUserId,
    this.customName,
    this.note,
    required this.updatedAt,
  });

  factory ContactMeta({
    int? id,
    required int ownerMessengerUserId,
    required int contactMessengerUserId,
    String? customName,
    String? note,
    required DateTime updatedAt,
  }) = _ContactMetaImpl;

  factory ContactMeta.fromJson(Map<String, dynamic> jsonSerialization) {
    return ContactMeta(
      id: jsonSerialization['id'] as int?,
      ownerMessengerUserId: jsonSerialization['ownerMessengerUserId'] as int,
      contactMessengerUserId:
          jsonSerialization['contactMessengerUserId'] as int,
      customName: jsonSerialization['customName'] as String?,
      note: jsonSerialization['note'] as String?,
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int ownerMessengerUserId;

  int contactMessengerUserId;

  /// «Своё имя» для контакта (alias), которое owner видит ВМЕСТО
  /// displayName в списке чатов/участниках. trim, ≤64, null = не задано.
  String? customName;

  /// Приватная заметка owner-а о контакте. ≤2000.
  String? note;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ContactMeta]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ContactMeta copyWith({
    int? id,
    int? ownerMessengerUserId,
    int? contactMessengerUserId,
    String? customName,
    String? note,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContactMeta',
      if (id != null) 'id': id,
      'ownerMessengerUserId': ownerMessengerUserId,
      'contactMessengerUserId': contactMessengerUserId,
      if (customName != null) 'customName': customName,
      if (note != null) 'note': note,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ContactMetaImpl extends ContactMeta {
  _ContactMetaImpl({
    int? id,
    required int ownerMessengerUserId,
    required int contactMessengerUserId,
    String? customName,
    String? note,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         ownerMessengerUserId: ownerMessengerUserId,
         contactMessengerUserId: contactMessengerUserId,
         customName: customName,
         note: note,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ContactMeta]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ContactMeta copyWith({
    Object? id = _Undefined,
    int? ownerMessengerUserId,
    int? contactMessengerUserId,
    Object? customName = _Undefined,
    Object? note = _Undefined,
    DateTime? updatedAt,
  }) {
    return ContactMeta(
      id: id is int? ? id : this.id,
      ownerMessengerUserId: ownerMessengerUserId ?? this.ownerMessengerUserId,
      contactMessengerUserId:
          contactMessengerUserId ?? this.contactMessengerUserId,
      customName: customName is String? ? customName : this.customName,
      note: note is String? ? note : this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
