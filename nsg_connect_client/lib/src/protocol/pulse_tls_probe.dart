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

/// **TLS pull-проба** (TASK94, issue #108) — цель и политика проверки.
///
/// Отдельная таблица, а не поля в `pulse_monitors`: у heartbeat-монитора
/// ничего этого нет, и сложив всё в одну таблицу мы бы размыли модель, ради
/// которой Pulse и держится простым. Связь 1:1 с монитором — он остаётся
/// носителем статуса, инцидентов, прав и pause, то есть всего, что уже
/// работает.
///
/// Секретов здесь нет: цель и результаты проверки не тайна, а приватных
/// ключей и PEM Connect не хранит (граница задачи, §15 запроса).
abstract class PulseTlsProbe implements _i1.SerializableModel {
  PulseTlsProbe._({
    this.id,
    required this.monitorId,
    required this.connectHost,
    required this.port,
    required this.serverName,
    int? timeoutSeconds,
    String? validationMode,
    this.expectedSubject,
    this.expectedThumbprint,
    this.certificateSetKey,
    this.setMismatchSince,
    int? warnBeforeDays,
    int? errorBeforeDays,
    int? failureThreshold,
    int? recoveryThreshold,
    int? consecutiveFailures,
    int? consecutiveSuccesses,
    this.lastCheckAt,
    this.lastSuccessAt,
    this.lastLatencyMs,
    this.lastThumbprint,
    this.lastNotBefore,
    this.lastNotAfter,
    this.lastSubject,
    this.lastIssuer,
    this.lastSans,
    this.lastTlsVersion,
    this.lastPolicyErrors,
    required this.createdAt,
    required this.updatedAt,
  }) : timeoutSeconds = timeoutSeconds ?? 10,
       validationMode = validationMode ?? 'publicPki',
       warnBeforeDays = warnBeforeDays ?? 30,
       errorBeforeDays = errorBeforeDays ?? 14,
       failureThreshold = failureThreshold ?? 2,
       recoveryThreshold = recoveryThreshold ?? 1,
       consecutiveFailures = consecutiveFailures ?? 0,
       consecutiveSuccesses = consecutiveSuccesses ?? 0;

  factory PulseTlsProbe({
    int? id,
    required int monitorId,
    required String connectHost,
    required int port,
    required String serverName,
    int? timeoutSeconds,
    String? validationMode,
    String? expectedSubject,
    String? expectedThumbprint,
    String? certificateSetKey,
    DateTime? setMismatchSince,
    int? warnBeforeDays,
    int? errorBeforeDays,
    int? failureThreshold,
    int? recoveryThreshold,
    int? consecutiveFailures,
    int? consecutiveSuccesses,
    DateTime? lastCheckAt,
    DateTime? lastSuccessAt,
    int? lastLatencyMs,
    String? lastThumbprint,
    DateTime? lastNotBefore,
    DateTime? lastNotAfter,
    String? lastSubject,
    String? lastIssuer,
    String? lastSans,
    String? lastTlsVersion,
    String? lastPolicyErrors,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PulseTlsProbeImpl;

  factory PulseTlsProbe.fromJson(Map<String, dynamic> jsonSerialization) {
    return PulseTlsProbe(
      id: jsonSerialization['id'] as int?,
      monitorId: jsonSerialization['monitorId'] as int,
      connectHost: jsonSerialization['connectHost'] as String,
      port: jsonSerialization['port'] as int,
      serverName: jsonSerialization['serverName'] as String,
      timeoutSeconds: jsonSerialization['timeoutSeconds'] as int?,
      validationMode: jsonSerialization['validationMode'] as String?,
      expectedSubject: jsonSerialization['expectedSubject'] as String?,
      expectedThumbprint: jsonSerialization['expectedThumbprint'] as String?,
      certificateSetKey: jsonSerialization['certificateSetKey'] as String?,
      setMismatchSince: jsonSerialization['setMismatchSince'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['setMismatchSince'],
            ),
      warnBeforeDays: jsonSerialization['warnBeforeDays'] as int?,
      errorBeforeDays: jsonSerialization['errorBeforeDays'] as int?,
      failureThreshold: jsonSerialization['failureThreshold'] as int?,
      recoveryThreshold: jsonSerialization['recoveryThreshold'] as int?,
      consecutiveFailures: jsonSerialization['consecutiveFailures'] as int?,
      consecutiveSuccesses: jsonSerialization['consecutiveSuccesses'] as int?,
      lastCheckAt: jsonSerialization['lastCheckAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastCheckAt'],
            ),
      lastSuccessAt: jsonSerialization['lastSuccessAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastSuccessAt'],
            ),
      lastLatencyMs: jsonSerialization['lastLatencyMs'] as int?,
      lastThumbprint: jsonSerialization['lastThumbprint'] as String?,
      lastNotBefore: jsonSerialization['lastNotBefore'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastNotBefore'],
            ),
      lastNotAfter: jsonSerialization['lastNotAfter'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastNotAfter'],
            ),
      lastSubject: jsonSerialization['lastSubject'] as String?,
      lastIssuer: jsonSerialization['lastIssuer'] as String?,
      lastSans: jsonSerialization['lastSans'] as String?,
      lastTlsVersion: jsonSerialization['lastTlsVersion'] as String?,
      lastPolicyErrors: jsonSerialization['lastPolicyErrors'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Монитор, который эта проба обслуживает. Каскад: удалили монитор —
  /// удалилась и проба, иначе останется цель без владельца и прав.
  int monitorId;

  /// Куда подключаться. IP или имя; имя резолвится ПЕРЕД каждым запуском, и
  /// проверяется каждый полученный адрес.
  String connectHost;

  int port;

  /// Какое имя передать в SNI и по какому проверять сертификат. Отдельно от
  /// `connectHost` — это обязательный сценарий заказчика: `futbolista.me`
  /// указывает DNS-ом на другой сервер, а проверить надо конкретный IP.
  String serverName;

  int timeoutSeconds;

  /// `publicPki` — системное доверие цепочке; `pinnedSelfSigned` — доверие
  /// по отпечатку.
  String validationMode;

  String? expectedSubject;

  String? expectedThumbprint;

  /// Группа endpoint одного сертификата (MR3). Заводим сразу: добавлять
  /// колонку в живую таблицу дороже, чем оставить её пустой до своего часа.
  String? certificateSetKey;

  /// **MR3**: с какого момента этот endpoint выбивается из набора. `null` —
  /// не выбивается. Нужно для терпимости: раскатка сертификата по узлам не
  /// мгновенна, и первое же расхождение — чаще всего «ещё катится», а не
  /// «забыли половину». Тревожим, только когда расхождение пережило свой
  /// период проверки, то есть подтвердилось вторым наблюдением.
  DateTime? setMismatchSince;

  int warnBeforeDays;

  int errorBeforeDays;

  /// Сколько подряд ТРАНЗИЕНТНЫХ отказов (DNS/TCP/handshake timeout) нужно,
  /// чтобы уйти в `down`. Детерминированные отказы — имя, цепочка, срок,
  /// pin — порога не ждут и меняют статус сразу.
  int failureThreshold;

  int recoveryThreshold;

  int consecutiveFailures;

  /// Подряд идущие УСПЕХИ — для выхода из `down` по `recoveryThreshold`.
  /// Без этого счётчика `recoveryThreshold` был бы полем, которое ничего не
  /// делает: поле в схеме, обещающее поведение, которого нет, хуже
  /// отсутствующего поля.
  int consecutiveSuccesses;

  /// Последняя ПОПЫТКА и последний УСПЕХ — разные вещи: по первой видно,
  /// что воркер жив, по второму — когда сертификат в последний раз был в
  /// порядке. Слитые в одно поле, они врут в обе стороны.
  DateTime? lastCheckAt;

  DateTime? lastSuccessAt;

  int? lastLatencyMs;

  /// Наблюдения последнего успешного handshake — чтобы понять причину
  /// статуса, не читая серверных логов (§2 запроса).
  String? lastThumbprint;

  DateTime? lastNotBefore;

  DateTime? lastNotAfter;

  String? lastSubject;

  String? lastIssuer;

  String? lastSans;

  String? lastTlsVersion;

  String? lastPolicyErrors;

  /// Рубежей напоминаний здесь НЕТ намеренно (MR2, issue #109): они
  /// живут общим слоем `PulseExpiryReminder` — механика «однократно на
  /// рубеж» не специфична для сертификатов, и во второй раз её пришлось бы
  /// копировать. Проба лишь поставляет туда `NotAfter`.
  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [PulseTlsProbe]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PulseTlsProbe copyWith({
    int? id,
    int? monitorId,
    String? connectHost,
    int? port,
    String? serverName,
    int? timeoutSeconds,
    String? validationMode,
    String? expectedSubject,
    String? expectedThumbprint,
    String? certificateSetKey,
    DateTime? setMismatchSince,
    int? warnBeforeDays,
    int? errorBeforeDays,
    int? failureThreshold,
    int? recoveryThreshold,
    int? consecutiveFailures,
    int? consecutiveSuccesses,
    DateTime? lastCheckAt,
    DateTime? lastSuccessAt,
    int? lastLatencyMs,
    String? lastThumbprint,
    DateTime? lastNotBefore,
    DateTime? lastNotAfter,
    String? lastSubject,
    String? lastIssuer,
    String? lastSans,
    String? lastTlsVersion,
    String? lastPolicyErrors,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PulseTlsProbe',
      if (id != null) 'id': id,
      'monitorId': monitorId,
      'connectHost': connectHost,
      'port': port,
      'serverName': serverName,
      'timeoutSeconds': timeoutSeconds,
      'validationMode': validationMode,
      if (expectedSubject != null) 'expectedSubject': expectedSubject,
      if (expectedThumbprint != null) 'expectedThumbprint': expectedThumbprint,
      if (certificateSetKey != null) 'certificateSetKey': certificateSetKey,
      if (setMismatchSince != null)
        'setMismatchSince': setMismatchSince?.toJson(),
      'warnBeforeDays': warnBeforeDays,
      'errorBeforeDays': errorBeforeDays,
      'failureThreshold': failureThreshold,
      'recoveryThreshold': recoveryThreshold,
      'consecutiveFailures': consecutiveFailures,
      'consecutiveSuccesses': consecutiveSuccesses,
      if (lastCheckAt != null) 'lastCheckAt': lastCheckAt?.toJson(),
      if (lastSuccessAt != null) 'lastSuccessAt': lastSuccessAt?.toJson(),
      if (lastLatencyMs != null) 'lastLatencyMs': lastLatencyMs,
      if (lastThumbprint != null) 'lastThumbprint': lastThumbprint,
      if (lastNotBefore != null) 'lastNotBefore': lastNotBefore?.toJson(),
      if (lastNotAfter != null) 'lastNotAfter': lastNotAfter?.toJson(),
      if (lastSubject != null) 'lastSubject': lastSubject,
      if (lastIssuer != null) 'lastIssuer': lastIssuer,
      if (lastSans != null) 'lastSans': lastSans,
      if (lastTlsVersion != null) 'lastTlsVersion': lastTlsVersion,
      if (lastPolicyErrors != null) 'lastPolicyErrors': lastPolicyErrors,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PulseTlsProbeImpl extends PulseTlsProbe {
  _PulseTlsProbeImpl({
    int? id,
    required int monitorId,
    required String connectHost,
    required int port,
    required String serverName,
    int? timeoutSeconds,
    String? validationMode,
    String? expectedSubject,
    String? expectedThumbprint,
    String? certificateSetKey,
    DateTime? setMismatchSince,
    int? warnBeforeDays,
    int? errorBeforeDays,
    int? failureThreshold,
    int? recoveryThreshold,
    int? consecutiveFailures,
    int? consecutiveSuccesses,
    DateTime? lastCheckAt,
    DateTime? lastSuccessAt,
    int? lastLatencyMs,
    String? lastThumbprint,
    DateTime? lastNotBefore,
    DateTime? lastNotAfter,
    String? lastSubject,
    String? lastIssuer,
    String? lastSans,
    String? lastTlsVersion,
    String? lastPolicyErrors,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         monitorId: monitorId,
         connectHost: connectHost,
         port: port,
         serverName: serverName,
         timeoutSeconds: timeoutSeconds,
         validationMode: validationMode,
         expectedSubject: expectedSubject,
         expectedThumbprint: expectedThumbprint,
         certificateSetKey: certificateSetKey,
         setMismatchSince: setMismatchSince,
         warnBeforeDays: warnBeforeDays,
         errorBeforeDays: errorBeforeDays,
         failureThreshold: failureThreshold,
         recoveryThreshold: recoveryThreshold,
         consecutiveFailures: consecutiveFailures,
         consecutiveSuccesses: consecutiveSuccesses,
         lastCheckAt: lastCheckAt,
         lastSuccessAt: lastSuccessAt,
         lastLatencyMs: lastLatencyMs,
         lastThumbprint: lastThumbprint,
         lastNotBefore: lastNotBefore,
         lastNotAfter: lastNotAfter,
         lastSubject: lastSubject,
         lastIssuer: lastIssuer,
         lastSans: lastSans,
         lastTlsVersion: lastTlsVersion,
         lastPolicyErrors: lastPolicyErrors,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [PulseTlsProbe]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PulseTlsProbe copyWith({
    Object? id = _Undefined,
    int? monitorId,
    String? connectHost,
    int? port,
    String? serverName,
    int? timeoutSeconds,
    String? validationMode,
    Object? expectedSubject = _Undefined,
    Object? expectedThumbprint = _Undefined,
    Object? certificateSetKey = _Undefined,
    Object? setMismatchSince = _Undefined,
    int? warnBeforeDays,
    int? errorBeforeDays,
    int? failureThreshold,
    int? recoveryThreshold,
    int? consecutiveFailures,
    int? consecutiveSuccesses,
    Object? lastCheckAt = _Undefined,
    Object? lastSuccessAt = _Undefined,
    Object? lastLatencyMs = _Undefined,
    Object? lastThumbprint = _Undefined,
    Object? lastNotBefore = _Undefined,
    Object? lastNotAfter = _Undefined,
    Object? lastSubject = _Undefined,
    Object? lastIssuer = _Undefined,
    Object? lastSans = _Undefined,
    Object? lastTlsVersion = _Undefined,
    Object? lastPolicyErrors = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PulseTlsProbe(
      id: id is int? ? id : this.id,
      monitorId: monitorId ?? this.monitorId,
      connectHost: connectHost ?? this.connectHost,
      port: port ?? this.port,
      serverName: serverName ?? this.serverName,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      validationMode: validationMode ?? this.validationMode,
      expectedSubject: expectedSubject is String?
          ? expectedSubject
          : this.expectedSubject,
      expectedThumbprint: expectedThumbprint is String?
          ? expectedThumbprint
          : this.expectedThumbprint,
      certificateSetKey: certificateSetKey is String?
          ? certificateSetKey
          : this.certificateSetKey,
      setMismatchSince: setMismatchSince is DateTime?
          ? setMismatchSince
          : this.setMismatchSince,
      warnBeforeDays: warnBeforeDays ?? this.warnBeforeDays,
      errorBeforeDays: errorBeforeDays ?? this.errorBeforeDays,
      failureThreshold: failureThreshold ?? this.failureThreshold,
      recoveryThreshold: recoveryThreshold ?? this.recoveryThreshold,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      consecutiveSuccesses: consecutiveSuccesses ?? this.consecutiveSuccesses,
      lastCheckAt: lastCheckAt is DateTime? ? lastCheckAt : this.lastCheckAt,
      lastSuccessAt: lastSuccessAt is DateTime?
          ? lastSuccessAt
          : this.lastSuccessAt,
      lastLatencyMs: lastLatencyMs is int? ? lastLatencyMs : this.lastLatencyMs,
      lastThumbprint: lastThumbprint is String?
          ? lastThumbprint
          : this.lastThumbprint,
      lastNotBefore: lastNotBefore is DateTime?
          ? lastNotBefore
          : this.lastNotBefore,
      lastNotAfter: lastNotAfter is DateTime?
          ? lastNotAfter
          : this.lastNotAfter,
      lastSubject: lastSubject is String? ? lastSubject : this.lastSubject,
      lastIssuer: lastIssuer is String? ? lastIssuer : this.lastIssuer,
      lastSans: lastSans is String? ? lastSans : this.lastSans,
      lastTlsVersion: lastTlsVersion is String?
          ? lastTlsVersion
          : this.lastTlsVersion,
      lastPolicyErrors: lastPolicyErrors is String?
          ? lastPolicyErrors
          : this.lastPolicyErrors,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
