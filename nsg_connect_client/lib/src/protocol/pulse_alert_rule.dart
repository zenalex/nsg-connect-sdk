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

/// PulseAlertRule — правило оповещения (TASK60). Область — монитор ИЛИ папка
/// (наследуется поддеревом; ближайшее по дереву правило побеждает; правило
/// монитора сильнее правила папки).
/// Уровень 0: статус-карточка в `roomId` (пуш через чат бесплатно).
/// Эскалация: инцидент не принят за `escalateAfterMinutes` → личка
/// level1-пользователям; дальше level2. CSV MUID-ов — low-cardinality.
abstract class PulseAlertRule implements _i1.SerializableModel {
  PulseAlertRule._({
    this.id,
    required this.tenantId,
    this.scopeFolderId,
    this.scopeMonitorId,
    String? minSeverity,
    required this.roomId,
    required this.botMessengerUserId,
    this.escalateAfterMinutes,
    this.level1UserIds,
    this.escalate2AfterMinutes,
    this.level2UserIds,
    required this.createdAt,
  }) : minSeverity = minSeverity ?? 'warn';

  factory PulseAlertRule({
    int? id,
    required int tenantId,
    int? scopeFolderId,
    int? scopeMonitorId,
    String? minSeverity,
    required int roomId,
    required int botMessengerUserId,
    int? escalateAfterMinutes,
    String? level1UserIds,
    int? escalate2AfterMinutes,
    String? level2UserIds,
    required DateTime createdAt,
  }) = _PulseAlertRuleImpl;

  factory PulseAlertRule.fromJson(Map<String, dynamic> jsonSerialization) {
    return PulseAlertRule(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      scopeFolderId: jsonSerialization['scopeFolderId'] as int?,
      scopeMonitorId: jsonSerialization['scopeMonitorId'] as int?,
      minSeverity: jsonSerialization['minSeverity'] as String?,
      roomId: jsonSerialization['roomId'] as int,
      botMessengerUserId: jsonSerialization['botMessengerUserId'] as int,
      escalateAfterMinutes: jsonSerialization['escalateAfterMinutes'] as int?,
      level1UserIds: jsonSerialization['level1UserIds'] as String?,
      escalate2AfterMinutes: jsonSerialization['escalate2AfterMinutes'] as int?,
      level2UserIds: jsonSerialization['level2UserIds'] as String?,
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

  /// Ровно одно из двух задано.
  int? scopeFolderId;

  int? scopeMonitorId;

  /// С какого уровня алертить: warn | error | down.
  String minSeverity;

  /// Куда карточку (уровень 0). Cascade: правило умирает с комнатой.
  int roomId;

  /// MUID бота-подпорки Pulse (отправитель карточек). Заполняется при
  /// создании правила (ensure тенантного Pulse-бота + addBotToRoom).
  int botMessengerUserId;

  int? escalateAfterMinutes;

  /// CSV MUID-ов ответственных (личка при эскалации уровня 1).
  String? level1UserIds;

  int? escalate2AfterMinutes;

  String? level2UserIds;

  DateTime createdAt;

  /// Returns a shallow copy of this [PulseAlertRule]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PulseAlertRule copyWith({
    int? id,
    int? tenantId,
    int? scopeFolderId,
    int? scopeMonitorId,
    String? minSeverity,
    int? roomId,
    int? botMessengerUserId,
    int? escalateAfterMinutes,
    String? level1UserIds,
    int? escalate2AfterMinutes,
    String? level2UserIds,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PulseAlertRule',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      if (scopeFolderId != null) 'scopeFolderId': scopeFolderId,
      if (scopeMonitorId != null) 'scopeMonitorId': scopeMonitorId,
      'minSeverity': minSeverity,
      'roomId': roomId,
      'botMessengerUserId': botMessengerUserId,
      if (escalateAfterMinutes != null)
        'escalateAfterMinutes': escalateAfterMinutes,
      if (level1UserIds != null) 'level1UserIds': level1UserIds,
      if (escalate2AfterMinutes != null)
        'escalate2AfterMinutes': escalate2AfterMinutes,
      if (level2UserIds != null) 'level2UserIds': level2UserIds,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PulseAlertRuleImpl extends PulseAlertRule {
  _PulseAlertRuleImpl({
    int? id,
    required int tenantId,
    int? scopeFolderId,
    int? scopeMonitorId,
    String? minSeverity,
    required int roomId,
    required int botMessengerUserId,
    int? escalateAfterMinutes,
    String? level1UserIds,
    int? escalate2AfterMinutes,
    String? level2UserIds,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         scopeFolderId: scopeFolderId,
         scopeMonitorId: scopeMonitorId,
         minSeverity: minSeverity,
         roomId: roomId,
         botMessengerUserId: botMessengerUserId,
         escalateAfterMinutes: escalateAfterMinutes,
         level1UserIds: level1UserIds,
         escalate2AfterMinutes: escalate2AfterMinutes,
         level2UserIds: level2UserIds,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PulseAlertRule]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PulseAlertRule copyWith({
    Object? id = _Undefined,
    int? tenantId,
    Object? scopeFolderId = _Undefined,
    Object? scopeMonitorId = _Undefined,
    String? minSeverity,
    int? roomId,
    int? botMessengerUserId,
    Object? escalateAfterMinutes = _Undefined,
    Object? level1UserIds = _Undefined,
    Object? escalate2AfterMinutes = _Undefined,
    Object? level2UserIds = _Undefined,
    DateTime? createdAt,
  }) {
    return PulseAlertRule(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      scopeFolderId: scopeFolderId is int? ? scopeFolderId : this.scopeFolderId,
      scopeMonitorId: scopeMonitorId is int?
          ? scopeMonitorId
          : this.scopeMonitorId,
      minSeverity: minSeverity ?? this.minSeverity,
      roomId: roomId ?? this.roomId,
      botMessengerUserId: botMessengerUserId ?? this.botMessengerUserId,
      escalateAfterMinutes: escalateAfterMinutes is int?
          ? escalateAfterMinutes
          : this.escalateAfterMinutes,
      level1UserIds: level1UserIds is String?
          ? level1UserIds
          : this.level1UserIds,
      escalate2AfterMinutes: escalate2AfterMinutes is int?
          ? escalate2AfterMinutes
          : this.escalate2AfterMinutes,
      level2UserIds: level2UserIds is String?
          ? level2UserIds
          : this.level2UserIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
