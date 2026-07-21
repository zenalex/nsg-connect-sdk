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
  });

  factory PushTestResult({
    required int deviceCount,
    required List<String> providers,
    required int delaySeconds,
  }) = _PushTestResultImpl;

  factory PushTestResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return PushTestResult(
      deviceCount: jsonSerialization['deviceCount'] as int,
      providers: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['providers'],
      ),
      delaySeconds: jsonSerialization['delaySeconds'] as int,
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

  /// Returns a shallow copy of this [PushTestResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PushTestResult copyWith({
    int? deviceCount,
    List<String>? providers,
    int? delaySeconds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PushTestResult',
      'deviceCount': deviceCount,
      'providers': providers.toJson(),
      'delaySeconds': delaySeconds,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PushTestResultImpl extends PushTestResult {
  _PushTestResultImpl({
    required int deviceCount,
    required List<String> providers,
    required int delaySeconds,
  }) : super._(
         deviceCount: deviceCount,
         providers: providers,
         delaySeconds: delaySeconds,
       );

  /// Returns a shallow copy of this [PushTestResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PushTestResult copyWith({
    int? deviceCount,
    List<String>? providers,
    int? delaySeconds,
  }) {
    return PushTestResult(
      deviceCount: deviceCount ?? this.deviceCount,
      providers: providers ?? this.providers.map((e0) => e0).toList(),
      delaySeconds: delaySeconds ?? this.delaySeconds,
    );
  }
}
