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

/// **TASK79**: членство в папке мониторинга — зеркало `RoomMembership`.
/// «Создал папку → ты её owner → сам решаешь, кто её видит».
///
/// **Почему отдельная таблица под папки, а не одна полиморфная с
/// `targetType`/`targetId`**: полиморфная ссылка не может иметь FK, и
/// удаление папки оставляло бы сиротские строки членства — их пришлось бы
/// чистить руками в каждом delete-пути. Две честные таблицы дают
/// целостность бесплатно (Cascade).
///
/// **Наследование вниз**: доступ к монитору = собственное членство ИЛИ
/// членство в любой папке-предке (папка в терминах пользователя — это
/// «сервис/проект», и права раздают на проект, а не на каждый heartbeat).
/// Подъём по цепочке `parentId` — прикладной, в [PulseAccessSnapshot]
/// (Serverpod ORM рекурсивных CTE не умеет).
///
/// Tenant тут не хранится намеренно: он приходит из папки (FK →
/// pulse_folders → tenants). Дублировать — значит завести второй источник
/// правды о границе тенанта, которую мы обязаны держать жёсткой.
abstract class PulseFolderMembership implements _i1.SerializableModel {
  PulseFolderMembership._({
    this.id,
    required this.folderId,
    required this.messengerUserId,
    String? role,
    required this.addedAt,
    this.addedByMessengerUserId,
  }) : role = role ?? 'viewer';

  factory PulseFolderMembership({
    int? id,
    required int folderId,
    required int messengerUserId,
    String? role,
    required DateTime addedAt,
    int? addedByMessengerUserId,
  }) = _PulseFolderMembershipImpl;

  factory PulseFolderMembership.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PulseFolderMembership(
      id: jsonSerialization['id'] as int?,
      folderId: jsonSerialization['folderId'] as int,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      role: jsonSerialization['role'] as String?,
      addedAt: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['addedAt']),
      addedByMessengerUserId:
          jsonSerialization['addedByMessengerUserId'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int folderId;

  int messengerUserId;

  /// `owner` | `admin` | `viewer`. Строка (не enum) — как у
  /// `RoomMembership.role`: низкая кардинальность, паттерн-матч в Dart,
  /// не требует миграции при добавлении роли.
  ///
  ///   * `viewer` — видит статусы и инциденты, не меняет ничего. Массовый
  ///     случай (дежурные, тестировщики), которого до TASK79 не было вовсе;
  ///   * `admin` — всё выше + создать/переименовать/удалить внутри, пауза,
  ///     ротация токена, правила алертов, ack инцидента;
  ///   * `owner` — всё выше + удалить сам объект и менять состав участников.
  String role;

  DateTime addedAt;

  /// Кто выдал доступ. SetNull: удаление аккаунта не должно рвать членство
  /// (иначе Cascade увёл бы с собой чужие доступы).
  int? addedByMessengerUserId;

  /// Returns a shallow copy of this [PulseFolderMembership]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PulseFolderMembership copyWith({
    int? id,
    int? folderId,
    int? messengerUserId,
    String? role,
    DateTime? addedAt,
    int? addedByMessengerUserId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PulseFolderMembership',
      if (id != null) 'id': id,
      'folderId': folderId,
      'messengerUserId': messengerUserId,
      'role': role,
      'addedAt': addedAt.toJson(),
      if (addedByMessengerUserId != null)
        'addedByMessengerUserId': addedByMessengerUserId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PulseFolderMembershipImpl extends PulseFolderMembership {
  _PulseFolderMembershipImpl({
    int? id,
    required int folderId,
    required int messengerUserId,
    String? role,
    required DateTime addedAt,
    int? addedByMessengerUserId,
  }) : super._(
         id: id,
         folderId: folderId,
         messengerUserId: messengerUserId,
         role: role,
         addedAt: addedAt,
         addedByMessengerUserId: addedByMessengerUserId,
       );

  /// Returns a shallow copy of this [PulseFolderMembership]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PulseFolderMembership copyWith({
    Object? id = _Undefined,
    int? folderId,
    int? messengerUserId,
    String? role,
    DateTime? addedAt,
    Object? addedByMessengerUserId = _Undefined,
  }) {
    return PulseFolderMembership(
      id: id is int? ? id : this.id,
      folderId: folderId ?? this.folderId,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      role: role ?? this.role,
      addedAt: addedAt ?? this.addedAt,
      addedByMessengerUserId: addedByMessengerUserId is int?
          ? addedByMessengerUserId
          : this.addedByMessengerUserId,
    );
  }
}
