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

/// **TASK78 п.3**: статус issued-token-режима tenant-а для админки/
/// диагностики интегратора. Без секретов — только факты состояния.
/// Не table — transient DTO.
abstract class ConnectTenantStatus implements _i1.SerializableModel {
  ConnectTenantStatus._({
    this.tenantExternalKey,
    this.tenantName,
    required this.enabled,
    required this.hasSecret,
    this.graceActiveUntil,
  });

  factory ConnectTenantStatus({
    String? tenantExternalKey,
    String? tenantName,
    required bool enabled,
    required bool hasSecret,
    DateTime? graceActiveUntil,
  }) = _ConnectTenantStatusImpl;

  factory ConnectTenantStatus.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConnectTenantStatus(
      tenantExternalKey: jsonSerialization['tenantExternalKey'] as String?,
      tenantName: jsonSerialization['tenantName'] as String?,
      enabled: _i1.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      hasSecret: _i1.BoolJsonExtension.fromJson(jsonSerialization['hasSecret']),
      graceActiveUntil: jsonSerialization['graceActiveUntil'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['graceActiveUntil'],
            ),
    );
  }

  /// **TASK78 п.3 (админ-UI)**: чей это статус — Tenant.externalKey.
  /// Nullable для обратной совместимости: старый сервер поля не шлёт,
  /// новый клиент не должен падать на его отсутствии.
  String? tenantExternalKey;

  /// Отображаемое имя tenant-а (Tenant.name) — чтобы админ-экран не
  /// делал второй запрос ради подписи строки. Nullable по той же
  /// причине совместимости.
  String? tenantName;

  /// Включён ли режим (адаптер резолвится).
  bool enabled;

  /// Задан ли текущий serviceSecret (можно выдавать токены).
  bool hasSecret;

  /// До какого момента ещё принимается ПРЕДЫДУЩИЙ секрет (grace
  /// ротации). NULL — grace не активен.
  DateTime? graceActiveUntil;

  /// Returns a shallow copy of this [ConnectTenantStatus]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConnectTenantStatus copyWith({
    String? tenantExternalKey,
    String? tenantName,
    bool? enabled,
    bool? hasSecret,
    DateTime? graceActiveUntil,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConnectTenantStatus',
      if (tenantExternalKey != null) 'tenantExternalKey': tenantExternalKey,
      if (tenantName != null) 'tenantName': tenantName,
      'enabled': enabled,
      'hasSecret': hasSecret,
      if (graceActiveUntil != null)
        'graceActiveUntil': graceActiveUntil?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConnectTenantStatusImpl extends ConnectTenantStatus {
  _ConnectTenantStatusImpl({
    String? tenantExternalKey,
    String? tenantName,
    required bool enabled,
    required bool hasSecret,
    DateTime? graceActiveUntil,
  }) : super._(
         tenantExternalKey: tenantExternalKey,
         tenantName: tenantName,
         enabled: enabled,
         hasSecret: hasSecret,
         graceActiveUntil: graceActiveUntil,
       );

  /// Returns a shallow copy of this [ConnectTenantStatus]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConnectTenantStatus copyWith({
    Object? tenantExternalKey = _Undefined,
    Object? tenantName = _Undefined,
    bool? enabled,
    bool? hasSecret,
    Object? graceActiveUntil = _Undefined,
  }) {
    return ConnectTenantStatus(
      tenantExternalKey: tenantExternalKey is String?
          ? tenantExternalKey
          : this.tenantExternalKey,
      tenantName: tenantName is String? ? tenantName : this.tenantName,
      enabled: enabled ?? this.enabled,
      hasSecret: hasSecret ?? this.hasSecret,
      graceActiveUntil: graceActiveUntil is DateTime?
          ? graceActiveUntil
          : this.graceActiveUntil,
    );
  }
}
