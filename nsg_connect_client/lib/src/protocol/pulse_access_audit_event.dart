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

/// **TASK79 п.8**: журнал доступа к мониторингу по образцу
/// `BotAuditEvent`/`ConnectKeyAuditEvent`. Отвечает на «кто дал Иванову
/// доступ к продовому монитору» и «кто пересоздал beat-токен» — без этого
/// такие вопросы не восстановить вообще.
///
/// Пишется best-effort: сбой аудита НЕ роняет само действие (см.
/// `PulseAccessService.logAudit`). Только INSERT, апдейтов нет.
///
/// **Почему `targetId` здесь БЕЗ FK — в отличие от таблиц членства.**
/// Trade-off ровно обратный и намеренный: членство обязано умирать вместе
/// с объектом (Cascade), а журнал обязан объект пережить. Строка «Петров
/// удалил монитор #17» бессмысленна, если Cascade унёс её вместе с #17.
/// Поэтому здесь полиморфная пара `targetKind`/`targetId` без FK, а
/// привязка к тенанту — своя (Cascade на tenants).
///
/// **Секретов не хранит**: ни старого, ни нового beat-токена — журнал
/// защищает токен, а не раскрывает его.
abstract class PulseAccessAuditEvent implements _i1.SerializableModel {
  PulseAccessAuditEvent._({
    this.id,
    required this.tenantId,
    required this.targetKind,
    required this.targetId,
    required this.action,
    this.actorMessengerUserId,
    this.actorEmail,
    this.subjectMessengerUserId,
    this.details,
    required this.createdAt,
  });

  factory PulseAccessAuditEvent({
    int? id,
    required int tenantId,
    required String targetKind,
    required int targetId,
    required String action,
    int? actorMessengerUserId,
    String? actorEmail,
    int? subjectMessengerUserId,
    String? details,
    required DateTime createdAt,
  }) = _PulseAccessAuditEventImpl;

  factory PulseAccessAuditEvent.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PulseAccessAuditEvent(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      targetKind: jsonSerialization['targetKind'] as String,
      targetId: jsonSerialization['targetId'] as int,
      action: jsonSerialization['action'] as String,
      actorMessengerUserId: jsonSerialization['actorMessengerUserId'] as int?,
      actorEmail: jsonSerialization['actorEmail'] as String?,
      subjectMessengerUserId:
          jsonSerialization['subjectMessengerUserId'] as int?,
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

  int tenantId;

  /// `folder` | `monitor`.
  String targetKind;

  /// id папки/монитора. Без FK — намеренно, см. докстринг класса.
  int targetId;

  /// Что произошло:
  ///   'member_added'        — участник добавлен (роль в `details`);
  ///   'member_role_changed' — роль изменена (`from=..,to=..`);
  ///   'member_removed'      — доступ отозван;
  ///   'token_rotated'       — пересоздан beat-токен монитора;
  ///   'created'             — объект заведён (первый owner).
  String action;

  /// MUID инициатора. SetNull — удаление аккаунта не стирает историю.
  int? actorMessengerUserId;

  /// Email инициатора на момент действия (snapshot — аккаунт могут
  /// переименовать/удалить, журнал должен остаться читаемым).
  String? actorEmail;

  /// MUID того, КОМУ выдали/у кого отозвали доступ. null для действий
  /// без второго участника ('token_rotated', 'created'). Plain int (не FK):
  /// журнал переживает удаление аккаунта, как и `targetId`.
  int? subjectMessengerUserId;

  /// Свободные детали без секретов: `role=viewer`, `from=viewer,to=admin`.
  String? details;

  DateTime createdAt;

  /// Returns a shallow copy of this [PulseAccessAuditEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PulseAccessAuditEvent copyWith({
    int? id,
    int? tenantId,
    String? targetKind,
    int? targetId,
    String? action,
    int? actorMessengerUserId,
    String? actorEmail,
    int? subjectMessengerUserId,
    String? details,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PulseAccessAuditEvent',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'targetKind': targetKind,
      'targetId': targetId,
      'action': action,
      if (actorMessengerUserId != null)
        'actorMessengerUserId': actorMessengerUserId,
      if (actorEmail != null) 'actorEmail': actorEmail,
      if (subjectMessengerUserId != null)
        'subjectMessengerUserId': subjectMessengerUserId,
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

class _PulseAccessAuditEventImpl extends PulseAccessAuditEvent {
  _PulseAccessAuditEventImpl({
    int? id,
    required int tenantId,
    required String targetKind,
    required int targetId,
    required String action,
    int? actorMessengerUserId,
    String? actorEmail,
    int? subjectMessengerUserId,
    String? details,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         targetKind: targetKind,
         targetId: targetId,
         action: action,
         actorMessengerUserId: actorMessengerUserId,
         actorEmail: actorEmail,
         subjectMessengerUserId: subjectMessengerUserId,
         details: details,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PulseAccessAuditEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PulseAccessAuditEvent copyWith({
    Object? id = _Undefined,
    int? tenantId,
    String? targetKind,
    int? targetId,
    String? action,
    Object? actorMessengerUserId = _Undefined,
    Object? actorEmail = _Undefined,
    Object? subjectMessengerUserId = _Undefined,
    Object? details = _Undefined,
    DateTime? createdAt,
  }) {
    return PulseAccessAuditEvent(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      targetKind: targetKind ?? this.targetKind,
      targetId: targetId ?? this.targetId,
      action: action ?? this.action,
      actorMessengerUserId: actorMessengerUserId is int?
          ? actorMessengerUserId
          : this.actorMessengerUserId,
      actorEmail: actorEmail is String? ? actorEmail : this.actorEmail,
      subjectMessengerUserId: subjectMessengerUserId is int?
          ? subjectMessengerUserId
          : this.subjectMessengerUserId,
      details: details is String? ? details : this.details,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
