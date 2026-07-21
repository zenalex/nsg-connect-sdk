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

/// PulseMonitor — единица наблюдения (TASK60, Connect Pulse).
/// Модель push (heartbeat): сервис стучится `POST /hooks/beat/<plt_токен>`
/// раз в `periodSeconds`; свипер переводит в late/down по дедлайнам.
/// Тем же beat-ом сервис может сообщить явный статус (ok|warn|error) + текст.
///
/// `status`: ok | warn | error | late | down (строка — низкая кардинальность,
/// паттерн-матч в Dart). `paused` — ручная пауза (деплой/обслуживание):
/// beat отвечает 403, свипер и алерты пропускают.
/// Токен хранится хешем (SHA-256), как IncomingWebhook.
abstract class PulseMonitor implements _i1.SerializableModel {
  PulseMonitor._({
    this.id,
    required this.tenantId,
    this.folderId,
    required this.name,
    required this.tokenHash,
    required this.periodSeconds,
    required this.graceSeconds,
    String? status,
    this.statusText,
    this.lastBeatAt,
    this.lastChangeAt,
    bool? paused,
    required this.createdBy,
    required this.createdAt,
  }) : status = status ?? 'ok',
       paused = paused ?? false;

  factory PulseMonitor({
    int? id,
    required int tenantId,
    int? folderId,
    required String name,
    required String tokenHash,
    required int periodSeconds,
    required int graceSeconds,
    String? status,
    String? statusText,
    DateTime? lastBeatAt,
    DateTime? lastChangeAt,
    bool? paused,
    required int createdBy,
    required DateTime createdAt,
  }) = _PulseMonitorImpl;

  factory PulseMonitor.fromJson(Map<String, dynamic> jsonSerialization) {
    return PulseMonitor(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      folderId: jsonSerialization['folderId'] as int?,
      name: jsonSerialization['name'] as String,
      tokenHash: jsonSerialization['tokenHash'] as String,
      periodSeconds: jsonSerialization['periodSeconds'] as int,
      graceSeconds: jsonSerialization['graceSeconds'] as int,
      status: jsonSerialization['status'] as String?,
      statusText: jsonSerialization['statusText'] as String?,
      lastBeatAt: jsonSerialization['lastBeatAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastBeatAt']),
      lastChangeAt: jsonSerialization['lastChangeAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastChangeAt'],
            ),
      paused: jsonSerialization['paused'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['paused']),
      createdBy: jsonSerialization['createdBy'] as int,
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

  /// Папка дерева; null = корень. Plain int? (см. PulseFolder).
  int? folderId;

  String name;

  String tokenHash;

  /// Ожидаемый интервал сигналов, сек (напр. 300).
  int periodSeconds;

  /// Допуск сверх периода до перехода в down, сек (напр. 120).
  /// Между period и period+grace монитор жёлтый `late` (без алерта).
  int graceSeconds;

  String status;

  /// Последний явный текст от сервиса ("lag 5 мин").
  String? statusText;

  DateTime? lastBeatAt;

  DateTime? lastChangeAt;

  bool paused;

  int createdBy;

  DateTime createdAt;

  /// Returns a shallow copy of this [PulseMonitor]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PulseMonitor copyWith({
    int? id,
    int? tenantId,
    int? folderId,
    String? name,
    String? tokenHash,
    int? periodSeconds,
    int? graceSeconds,
    String? status,
    String? statusText,
    DateTime? lastBeatAt,
    DateTime? lastChangeAt,
    bool? paused,
    int? createdBy,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PulseMonitor',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      if (folderId != null) 'folderId': folderId,
      'name': name,
      'tokenHash': tokenHash,
      'periodSeconds': periodSeconds,
      'graceSeconds': graceSeconds,
      'status': status,
      if (statusText != null) 'statusText': statusText,
      if (lastBeatAt != null) 'lastBeatAt': lastBeatAt?.toJson(),
      if (lastChangeAt != null) 'lastChangeAt': lastChangeAt?.toJson(),
      'paused': paused,
      'createdBy': createdBy,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PulseMonitorImpl extends PulseMonitor {
  _PulseMonitorImpl({
    int? id,
    required int tenantId,
    int? folderId,
    required String name,
    required String tokenHash,
    required int periodSeconds,
    required int graceSeconds,
    String? status,
    String? statusText,
    DateTime? lastBeatAt,
    DateTime? lastChangeAt,
    bool? paused,
    required int createdBy,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         folderId: folderId,
         name: name,
         tokenHash: tokenHash,
         periodSeconds: periodSeconds,
         graceSeconds: graceSeconds,
         status: status,
         statusText: statusText,
         lastBeatAt: lastBeatAt,
         lastChangeAt: lastChangeAt,
         paused: paused,
         createdBy: createdBy,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PulseMonitor]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PulseMonitor copyWith({
    Object? id = _Undefined,
    int? tenantId,
    Object? folderId = _Undefined,
    String? name,
    String? tokenHash,
    int? periodSeconds,
    int? graceSeconds,
    String? status,
    Object? statusText = _Undefined,
    Object? lastBeatAt = _Undefined,
    Object? lastChangeAt = _Undefined,
    bool? paused,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return PulseMonitor(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      folderId: folderId is int? ? folderId : this.folderId,
      name: name ?? this.name,
      tokenHash: tokenHash ?? this.tokenHash,
      periodSeconds: periodSeconds ?? this.periodSeconds,
      graceSeconds: graceSeconds ?? this.graceSeconds,
      status: status ?? this.status,
      statusText: statusText is String? ? statusText : this.statusText,
      lastBeatAt: lastBeatAt is DateTime? ? lastBeatAt : this.lastBeatAt,
      lastChangeAt: lastChangeAt is DateTime?
          ? lastChangeAt
          : this.lastChangeAt,
      paused: paused ?? this.paused,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
