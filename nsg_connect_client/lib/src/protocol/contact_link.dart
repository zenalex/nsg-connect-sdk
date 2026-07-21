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
import 'enums/contact_link_source.dart' as _i2;

/// **TASK52 итер.2**: направленная trust-связь «мои контакты»
/// (owner→contact). Фундамент для видимости contacts-полей визитки,
/// гейта «кто может мне писать» и рекомендаций.
///
/// Жизненный цикл (§3B.7): nearby/QR-handshake создаёт ОБА направления;
/// «удалить из контактов» снимает link (enforcement whoCanMessageMe —
/// к НОВЫМ комнатам, существующий direct не закрывается). owner/contact
/// — plain int (конвенция contact_meta: два FK на messenger_users
/// конфликтуют по relation-именам; чистка при удалении юзера — бэклог).
abstract class ContactLink implements _i1.SerializableModel {
  ContactLink._({
    this.id,
    required this.ownerMessengerUserId,
    required this.contactMessengerUserId,
    required this.source,
    required this.createdAt,
  });

  factory ContactLink({
    int? id,
    required int ownerMessengerUserId,
    required int contactMessengerUserId,
    required _i2.ContactLinkSource source,
    required DateTime createdAt,
  }) = _ContactLinkImpl;

  factory ContactLink.fromJson(Map<String, dynamic> jsonSerialization) {
    return ContactLink(
      id: jsonSerialization['id'] as int?,
      ownerMessengerUserId: jsonSerialization['ownerMessengerUserId'] as int,
      contactMessengerUserId:
          jsonSerialization['contactMessengerUserId'] as int,
      source: _i2.ContactLinkSource.fromJson(
        (jsonSerialization['source'] as String),
      ),
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

  int contactMessengerUserId;

  _i2.ContactLinkSource source;

  DateTime createdAt;

  /// Returns a shallow copy of this [ContactLink]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ContactLink copyWith({
    int? id,
    int? ownerMessengerUserId,
    int? contactMessengerUserId,
    _i2.ContactLinkSource? source,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContactLink',
      if (id != null) 'id': id,
      'ownerMessengerUserId': ownerMessengerUserId,
      'contactMessengerUserId': contactMessengerUserId,
      'source': source.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ContactLinkImpl extends ContactLink {
  _ContactLinkImpl({
    int? id,
    required int ownerMessengerUserId,
    required int contactMessengerUserId,
    required _i2.ContactLinkSource source,
    required DateTime createdAt,
  }) : super._(
         id: id,
         ownerMessengerUserId: ownerMessengerUserId,
         contactMessengerUserId: contactMessengerUserId,
         source: source,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ContactLink]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ContactLink copyWith({
    Object? id = _Undefined,
    int? ownerMessengerUserId,
    int? contactMessengerUserId,
    _i2.ContactLinkSource? source,
    DateTime? createdAt,
  }) {
    return ContactLink(
      id: id is int? ? id : this.id,
      ownerMessengerUserId: ownerMessengerUserId ?? this.ownerMessengerUserId,
      contactMessengerUserId:
          contactMessengerUserId ?? this.contactMessengerUserId,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
