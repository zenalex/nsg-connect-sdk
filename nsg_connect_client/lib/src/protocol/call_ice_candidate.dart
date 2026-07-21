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

/// **TASK46**: один ICE-кандидат trickle-сигналинга (WebRTC). Transient
/// DTO (не table) — эфемерный, не хранится. Соответствует полю элемента
/// массива `candidates[]` в Matrix `m.call.candidates` content (MSC2746)
/// и структуре `RTCIceCandidateInit` во flutter_webrtc.
///
/// Отправляется клиентом в `sendCallEvent(eventType: candidates, ...)`,
/// сервер кладёт список as-is в `content.candidates`. Входящие кандидаты
/// из Matrix `/sync` собираются dispatcher-ом в этот же тип и едут в
/// `MessengerEvent.callCandidates`.
abstract class CallIceCandidate implements _i1.SerializableModel {
  CallIceCandidate._({
    required this.candidate,
    this.sdpMid,
    this.sdpMLineIndex,
  });

  factory CallIceCandidate({
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) = _CallIceCandidateImpl;

  factory CallIceCandidate.fromJson(Map<String, dynamic> jsonSerialization) {
    return CallIceCandidate(
      candidate: jsonSerialization['candidate'] as String,
      sdpMid: jsonSerialization['sdpMid'] as String?,
      sdpMLineIndex: jsonSerialization['sdpMLineIndex'] as int?,
    );
  }

  /// Строка SDP-кандидата (`candidate:...`). Matrix / WebRTC поле
  /// `candidate`. Пустая строка допустима — сигнал «end-of-candidates».
  String candidate;

  /// Media stream identification tag (`sdpMid`). Nullable — WebRTC
  /// допускает кандидаты без mid (используется sdpMLineIndex).
  String? sdpMid;

  /// Индекс m-line в SDP (`sdpMLineIndex`). Nullable — см. sdpMid.
  int? sdpMLineIndex;

  /// Returns a shallow copy of this [CallIceCandidate]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CallIceCandidate copyWith({
    String? candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CallIceCandidate',
      'candidate': candidate,
      if (sdpMid != null) 'sdpMid': sdpMid,
      if (sdpMLineIndex != null) 'sdpMLineIndex': sdpMLineIndex,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CallIceCandidateImpl extends CallIceCandidate {
  _CallIceCandidateImpl({
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) : super._(
         candidate: candidate,
         sdpMid: sdpMid,
         sdpMLineIndex: sdpMLineIndex,
       );

  /// Returns a shallow copy of this [CallIceCandidate]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CallIceCandidate copyWith({
    String? candidate,
    Object? sdpMid = _Undefined,
    Object? sdpMLineIndex = _Undefined,
  }) {
    return CallIceCandidate(
      candidate: candidate ?? this.candidate,
      sdpMid: sdpMid is String? ? sdpMid : this.sdpMid,
      sdpMLineIndex: sdpMLineIndex is int? ? sdpMLineIndex : this.sdpMLineIndex,
    );
  }
}
