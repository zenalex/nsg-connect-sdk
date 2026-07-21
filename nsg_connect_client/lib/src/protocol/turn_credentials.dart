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

/// **TASK46**: эфемерные TURN/STUN креды для WebRTC ICE. Возвращаются из
/// `MessengerEndpoint.getTurnCredentials` (см. TASK46 §2.1/§4.2). Transient
/// DTO (не table). Клиент кладёт в `RTCConfiguration.iceServers` перед
/// созданием `RTCPeerConnection`.
///
/// Схема coturn `use-auth-secret` (TURN REST API,
/// draft-uberti-behave-turn-rest): server генерит per-call
///   username   = `<expiryUnix>:<messengerUserId>`
///   credential = base64(HMAC-SHA1(turnStaticAuthSecret, username))
/// coturn валидирует HMAC сам, без обращения к нашему серверу. Кред живёт
/// `ttlSeconds` (~300с) — утечка не даёт долговременного релея.
///
/// **Feature-toggle**: если env `TURN_URLS` не задан (нет TURN-инфры) —
/// server возвращает `urls: []` (пустой список) с пустыми
/// username/credential; SDK трактует пустой список как «TURN выключен»
/// (используются только публичные STUN на клиенте).
abstract class TurnCredentials implements _i1.SerializableModel {
  TurnCredentials._({
    required this.urls,
    required this.username,
    required this.credential,
    required this.ttlSeconds,
  });

  factory TurnCredentials({
    required List<String> urls,
    required String username,
    required String credential,
    required int ttlSeconds,
  }) = _TurnCredentialsImpl;

  factory TurnCredentials.fromJson(Map<String, dynamic> jsonSerialization) {
    return TurnCredentials(
      urls: _i2.Protocol().deserialize<List<String>>(jsonSerialization['urls']),
      username: jsonSerialization['username'] as String,
      credential: jsonSerialization['credential'] as String,
      ttlSeconds: jsonSerialization['ttlSeconds'] as int,
    );
  }

  /// Список ICE-server URL-ов: `turns:host:5349`, `turn:host:3478`, а также
  /// опционально `stun:...`. Пустой список = TURN не сконфигурирован.
  List<String> urls;

  /// `<expiryUnix>:<messengerUserId>` — coturn REST username. Пусто если
  /// TURN выключен.
  String username;

  /// base64(HMAC-SHA1(secret, username)). Пусто если TURN выключен.
  String credential;

  /// Время жизни кред в секундах (для клиентского refresh перед истечением).
  int ttlSeconds;

  /// Returns a shallow copy of this [TurnCredentials]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TurnCredentials copyWith({
    List<String>? urls,
    String? username,
    String? credential,
    int? ttlSeconds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TurnCredentials',
      'urls': urls.toJson(),
      'username': username,
      'credential': credential,
      'ttlSeconds': ttlSeconds,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TurnCredentialsImpl extends TurnCredentials {
  _TurnCredentialsImpl({
    required List<String> urls,
    required String username,
    required String credential,
    required int ttlSeconds,
  }) : super._(
         urls: urls,
         username: username,
         credential: credential,
         ttlSeconds: ttlSeconds,
       );

  /// Returns a shallow copy of this [TurnCredentials]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TurnCredentials copyWith({
    List<String>? urls,
    String? username,
    String? credential,
    int? ttlSeconds,
  }) {
    return TurnCredentials(
      urls: urls ?? this.urls.map((e0) => e0).toList(),
      username: username ?? this.username,
      credential: credential ?? this.credential,
      ttlSeconds: ttlSeconds ?? this.ttlSeconds,
    );
  }
}
