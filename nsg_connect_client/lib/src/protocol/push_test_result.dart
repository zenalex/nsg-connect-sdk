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
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i2;

/// TASK61: результат запроса «Проверить пуш» из профиля. Возвращается
/// синхронно на нажатие кнопки — сам пуш придёт с задержкой (delaySeconds)
/// через FutureCall, чтобы пользователь успел свернуть/закрыть приложение.
abstract class PushTestResult implements _i1.SerializableModel {
  PushTestResult._({
    required this.deviceCount,
    required this.providers,
    required this.delaySeconds,
    this.lastSeenAt,
    required this.staleCount,
  });

  factory PushTestResult({
    required int deviceCount,
    required List<String> providers,
    required int delaySeconds,
    DateTime? lastSeenAt,
    required int staleCount,
  }) = _PushTestResultImpl;

  factory PushTestResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return PushTestResult(
      deviceCount: jsonSerialization['deviceCount'] as int,
      providers: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['providers'],
      ),
      delaySeconds: jsonSerialization['delaySeconds'] as int,
      lastSeenAt: jsonSerialization['lastSeenAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastSeenAt']),
      staleCount: jsonSerialization['staleCount'] as int,
    );
  }

  /// Сколько устройств пользователя получат тестовый пуш (voip-каналы
  /// исключены — они только для звонков).
  int deviceCount;

  /// Через каких провайдеров придёт пуш (distinct значения
  /// DeviceRegistration.pushService: 'fcm' / 'rustore' / ...). Клиент
  /// показывает человекочитаемое имя.
  List<String> providers;

  /// Задержка доставки в секундах (обычно 10) — чтобы пользователь
  /// проверил и с открытым, и с закрытым приложением.
  int delaySeconds;

  /// **Issue #86**: когда push-регистрация продлевалась в последний раз —
  /// самая свежая из тех, что учтены в `deviceCount` (UTC).
  ///
  /// Зачем здесь: именно этот вопрос («а токен-то вообще живой?») решает
  /// жалобу «пуши не приходят», и до сих пор ответ на него был только в
  /// прод-базе. «Проверить пуш» — ровно то место, куда человек приходит,
  /// когда уведомления молчат, поэтому дата отдаётся тут, а не новым
  /// админ-эндпоинтом.
  ///
  /// `null` — учитывать нечего (`deviceCount == 0`).
  DateTime? lastSeenAt;

  /// **Issue #86**: сколько из учтённых регистраций не продлевалось дольше
  /// порога (`DeviceRegistrationService.registrationFreshness`).
  ///
  /// Прод-случай выглядит как `deviceCount == 1, staleCount == 1`: пуш
  /// формально «уходит на одно устройство», но это установка, которой на
  /// телефоне уже нет. Само число отправку не отменяет — тест на то и
  /// тест, чтобы выяснить, жив ли токен.
  int staleCount;

  /// Returns a shallow copy of this [PushTestResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PushTestResult copyWith({
    int? deviceCount,
    List<String>? providers,
    int? delaySeconds,
    DateTime? lastSeenAt,
    int? staleCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PushTestResult',
      'deviceCount': deviceCount,
      'providers': providers.toJson(),
      'delaySeconds': delaySeconds,
      if (lastSeenAt != null) 'lastSeenAt': lastSeenAt?.toJson(),
      'staleCount': staleCount,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PushTestResultImpl extends PushTestResult {
  _PushTestResultImpl({
    required int deviceCount,
    required List<String> providers,
    required int delaySeconds,
    DateTime? lastSeenAt,
    required int staleCount,
  }) : super._(
         deviceCount: deviceCount,
         providers: providers,
         delaySeconds: delaySeconds,
         lastSeenAt: lastSeenAt,
         staleCount: staleCount,
       );

  /// Returns a shallow copy of this [PushTestResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PushTestResult copyWith({
    int? deviceCount,
    List<String>? providers,
    int? delaySeconds,
    Object? lastSeenAt = _Undefined,
    int? staleCount,
  }) {
    return PushTestResult(
      deviceCount: deviceCount ?? this.deviceCount,
      providers: providers ?? this.providers.map((e0) => e0).toList(),
      delaySeconds: delaySeconds ?? this.delaySeconds,
      lastSeenAt: lastSeenAt is DateTime? ? lastSeenAt : this.lastSeenAt,
      staleCount: staleCount ?? this.staleCount,
    );
  }
}
