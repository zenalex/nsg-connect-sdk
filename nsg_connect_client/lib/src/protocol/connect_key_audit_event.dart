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

/// **TASK78 п.5**: журнал операций с connect-ключами tenant-а. Отвечает
/// на «кто и когда включил issued-token-режим / сгенерировал / ротировал
/// / отозвал serviceSecret этого tenant-а». Аналог BotAuditEvent, но
/// scope — tenant, а не бот.
///
/// Пишется best-effort: сбой аудита НЕ роняет само действие. Только
/// INSERT, апдейтов нет.
///
/// **Секретов не хранит** — ни плейнтекста, ни хэша: журнал защищает
/// ключи, а не раскрывает их. Хэш живёт только в самом tenant-е.
abstract class ConnectKeyAuditEvent implements _i1.SerializableModel {
  ConnectKeyAuditEvent._({
    this.id,
    required this.tenantId,
    required this.action,
    this.actorMessengerUserId,
    this.actorEmail,
    this.details,
    required this.createdAt,
  });

  factory ConnectKeyAuditEvent({
    int? id,
    required int tenantId,
    required String action,
    int? actorMessengerUserId,
    String? actorEmail,
    String? details,
    required DateTime createdAt,
  }) = _ConnectKeyAuditEventImpl;

  factory ConnectKeyAuditEvent.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConnectKeyAuditEvent(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      action: jsonSerialization['action'] as String,
      actorMessengerUserId: jsonSerialization['actorMessengerUserId'] as int?,
      actorEmail: jsonSerialization['actorEmail'] as String?,
      details: jsonSerialization['details'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на tenant. Cascade — журнал уходит вместе с tenant-ом.
  int tenantId;

  /// Что произошло:
  ///   'enabled_and_generated' — режим включён, выдан первый секрет;
  ///   'secret_rotated'        — выдан новый секрет, старый в grace;
  ///   'secret_regenerated'    — новый секрет без grace (старый мёртв сразу);
  ///   'disabled'              — режим отозван (kill-switch);
  ///   'reenabled'             — режим снова включён без смены секрета.
  String action;

  /// MUID инициатора (платформенный админ). SetNull — удаление аккаунта
  /// не стирает историю.
  int? actorMessengerUserId;

  /// Email инициатора на момент действия (snapshot — аккаунт могут
  /// переименовать/удалить, журнал должен остаться читаемым).
  String? actorEmail;

  /// Свободная заметка БЕЗ секретов (напр. «grace=300s»). Опционально.
  String? details;

  DateTime createdAt;

  /// Returns a shallow copy of this [ConnectKeyAuditEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConnectKeyAuditEvent copyWith({
    int? id,
    int? tenantId,
    String? action,
    int? actorMessengerUserId,
    String? actorEmail,
    String? details,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConnectKeyAuditEvent',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'action': action,
      if (actorMessengerUserId != null)
        'actorMessengerUserId': actorMessengerUserId,
      if (actorEmail != null) 'actorEmail': actorEmail,
      if (details != null) 'details': details,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConnectKeyAuditEventImpl extends ConnectKeyAuditEvent {
  _ConnectKeyAuditEventImpl({
    int? id,
    required int tenantId,
    required String action,
    int? actorMessengerUserId,
    String? actorEmail,
    String? details,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         action: action,
         actorMessengerUserId: actorMessengerUserId,
         actorEmail: actorEmail,
         details: details,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ConnectKeyAuditEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConnectKeyAuditEvent copyWith({
    Object? id = _Undefined,
    int? tenantId,
    String? action,
    Object? actorMessengerUserId = _Undefined,
    Object? actorEmail = _Undefined,
    Object? details = _Undefined,
    DateTime? createdAt,
  }) {
    return ConnectKeyAuditEvent(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      action: action ?? this.action,
      actorMessengerUserId: actorMessengerUserId is int?
          ? actorMessengerUserId
          : this.actorMessengerUserId,
      actorEmail: actorEmail is String? ? actorEmail : this.actorEmail,
      details: details is String? ? details : this.details,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
