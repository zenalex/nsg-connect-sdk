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
    String? kind,
    this.tokenHash,
    required this.periodSeconds,
    required this.graceSeconds,
    String? status,
    this.statusText,
    this.lastBeatAt,
    this.lastValuesJson,
    this.lastChangeAt,
    this.lastEvaluatedAt,
    bool? paused,
    required this.createdBy,
    required this.createdAt,
  }) : kind = kind ?? 'heartbeat',
       status = status ?? 'ok',
       paused = paused ?? false;

  factory PulseMonitor({
    int? id,
    required int tenantId,
    int? folderId,
    required String name,
    String? kind,
    String? tokenHash,
    required int periodSeconds,
    required int graceSeconds,
    String? status,
    String? statusText,
    DateTime? lastBeatAt,
    String? lastValuesJson,
    DateTime? lastChangeAt,
    DateTime? lastEvaluatedAt,
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
      kind: jsonSerialization['kind'] as String?,
      tokenHash: jsonSerialization['tokenHash'] as String?,
      periodSeconds: jsonSerialization['periodSeconds'] as int,
      graceSeconds: jsonSerialization['graceSeconds'] as int,
      status: jsonSerialization['status'] as String?,
      statusText: jsonSerialization['statusText'] as String?,
      lastBeatAt: jsonSerialization['lastBeatAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastBeatAt']),
      lastValuesJson: jsonSerialization['lastValuesJson'] as String?,
      lastChangeAt: jsonSerialization['lastChangeAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastChangeAt'],
            ),
      lastEvaluatedAt: jsonSerialization['lastEvaluatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastEvaluatedAt'],
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

  /// **TASK94 (#108)**: `heartbeat` — монитор ждёт beat снаружи;
  /// `tlsProbe` — сервер сам ходит и проверяет сертификат. Дефолт делает
  /// миграцию существующих записей тождественной: всё, что есть сейчас, —
  /// heartbeat, и семантика их не меняется.
  String kind;

  /// **TASK94 (#108)**: стало необязательным. У TLS-пробы токена НЕТ и не
  /// должно быть: пока он существует, кто-нибудь однажды пошлёт beat и
  /// замаскирует протухший сертификат — ровно тот отказ, ради которого
  /// пробы и заводятся. Отсутствие секрета надёжнее, чем секрет, который
  /// мы обещали не принимать.
  ///
  /// Уникальный индекс это переживает: несколько NULL в Postgres не
  /// конфликтуют.
  String? tokenHash;

  /// Ожидаемый интервал сигналов, сек (напр. 300).
  int periodSeconds;

  /// Допуск сверх периода до перехода в down, сек (напр. 120).
  /// Между period и period+grace монитор жёлтый `late` (без алерта).
  int graceSeconds;

  String status;

  /// Последний явный текст от сервиса ("lag 5 мин").
  String? statusText;

  DateTime? lastBeatAt;

  /// **issue #116**: последние ЧИСЛА из beat, JSON-объект `имя → число`.
  /// Снимок, а не ряд: заводить под него таблицу значило бы притвориться
  /// хранилищем метрик, которым мы быть не собираемся (см. §7 дизайна
  /// плагинов-мониторов). Графики за год — другой продукт.
  String? lastValuesJson;

  DateTime? lastChangeAt;

  /// **issue #131**: когда сервер в последний раз ПЕРЕСЧИТЫВАЛ статус
  /// монитора, который считает сам (`kind` — проба или здоровье каналов).
  ///
  /// Нужно, потому что такие мониторы освобождены от дедлайна молчания —
  /// beat им слать некому. Освобождение честное, но за него платят: встань
  /// считающий воркер, и монитор замрёт на последнем статусе, оставшись
  /// зелёным навсегда. Ровно та беда, от которой мониторинг и заводят, —
  /// сломанное молчит и потому выглядит работающим.
  ///
  /// Отличается от `lastChangeAt`: тот отмечает СМЕНУ статуса, а спокойный
  /// монитор не меняется месяцами, и по нему живость воркера не отличить от
  /// затянувшегося покоя.
  DateTime? lastEvaluatedAt;

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
    String? kind,
    String? tokenHash,
    int? periodSeconds,
    int? graceSeconds,
    String? status,
    String? statusText,
    DateTime? lastBeatAt,
    String? lastValuesJson,
    DateTime? lastChangeAt,
    DateTime? lastEvaluatedAt,
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
      'kind': kind,
      if (tokenHash != null) 'tokenHash': tokenHash,
      'periodSeconds': periodSeconds,
      'graceSeconds': graceSeconds,
      'status': status,
      if (statusText != null) 'statusText': statusText,
      if (lastBeatAt != null) 'lastBeatAt': lastBeatAt?.toJson(),
      if (lastValuesJson != null) 'lastValuesJson': lastValuesJson,
      if (lastChangeAt != null) 'lastChangeAt': lastChangeAt?.toJson(),
      if (lastEvaluatedAt != null) 'lastEvaluatedAt': lastEvaluatedAt?.toJson(),
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
    String? kind,
    String? tokenHash,
    required int periodSeconds,
    required int graceSeconds,
    String? status,
    String? statusText,
    DateTime? lastBeatAt,
    String? lastValuesJson,
    DateTime? lastChangeAt,
    DateTime? lastEvaluatedAt,
    bool? paused,
    required int createdBy,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         folderId: folderId,
         name: name,
         kind: kind,
         tokenHash: tokenHash,
         periodSeconds: periodSeconds,
         graceSeconds: graceSeconds,
         status: status,
         statusText: statusText,
         lastBeatAt: lastBeatAt,
         lastValuesJson: lastValuesJson,
         lastChangeAt: lastChangeAt,
         lastEvaluatedAt: lastEvaluatedAt,
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
    String? kind,
    Object? tokenHash = _Undefined,
    int? periodSeconds,
    int? graceSeconds,
    String? status,
    Object? statusText = _Undefined,
    Object? lastBeatAt = _Undefined,
    Object? lastValuesJson = _Undefined,
    Object? lastChangeAt = _Undefined,
    Object? lastEvaluatedAt = _Undefined,
    bool? paused,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return PulseMonitor(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      folderId: folderId is int? ? folderId : this.folderId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      tokenHash: tokenHash is String? ? tokenHash : this.tokenHash,
      periodSeconds: periodSeconds ?? this.periodSeconds,
      graceSeconds: graceSeconds ?? this.graceSeconds,
      status: status ?? this.status,
      statusText: statusText is String? ? statusText : this.statusText,
      lastBeatAt: lastBeatAt is DateTime? ? lastBeatAt : this.lastBeatAt,
      lastValuesJson: lastValuesJson is String?
          ? lastValuesJson
          : this.lastValuesJson,
      lastChangeAt: lastChangeAt is DateTime?
          ? lastChangeAt
          : this.lastChangeAt,
      lastEvaluatedAt: lastEvaluatedAt is DateTime?
          ? lastEvaluatedAt
          : this.lastEvaluatedAt,
      paused: paused ?? this.paused,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
