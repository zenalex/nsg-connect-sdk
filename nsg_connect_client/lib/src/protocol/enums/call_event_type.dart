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

/// **TASK46**: тип call-события 1:1 сигналинга (WebRTC поверх Matrix).
/// Параметр RPC `MessengerEndpoint.sendCallEvent` — по нему server
/// выбирает, какой Matrix `m.call.*` event собрать и отправить в комнату
/// (server-proxy сигналинг, см. TASK46 §1/§4). Маппинг на Matrix VoIP
/// spec (MSC2746 / spec «Voice over IP»):
///   * `invite`       → `m.call.invite`       (caller шлёт SDP offer)
///   * `answer`       → `m.call.answer`       (callee шлёт SDP answer)
///   * `candidates`   → `m.call.candidates`   (trickle ICE, обе стороны)
///   * `hangup`       → `m.call.hangup`       (завершение / отклонение)
///   * `selectAnswer` → `m.call.select_answer`(glare multi-device: caller
///                                             выбрал одного из ответивших)
///   * `reject`       → `m.call.reject`       (явный decline, v1)
///   * `negotiate`    → `m.call.negotiate`    (перезаключение сессии —
///                                             ICE restart при смене сети /
///                                             disconnect; `description:{type,
///                                             sdp}` — offer от caller-а,
///                                             answer от callee, TASK46 §resilience)
///
/// **НЕ путать** с [MessengerEventType] `call*` значениями — тот enum —
/// дискриминатор realtime-события В СТРИМЕ (Matrix → клиент), этот —
/// параметр исходящего RPC (клиент → Matrix). Разделены сознательно:
/// входящий поток может расширяться независимо (напр. server-side
/// синтетические события) без изменения контракта отправки.
enum CallEventType implements _i1.SerializableModel {
  invite,
  answer,
  candidates,
  hangup,
  selectAnswer,
  reject,
  negotiate;

  static CallEventType fromJson(String name) {
    switch (name) {
      case 'invite':
        return CallEventType.invite;
      case 'answer':
        return CallEventType.answer;
      case 'candidates':
        return CallEventType.candidates;
      case 'hangup':
        return CallEventType.hangup;
      case 'selectAnswer':
        return CallEventType.selectAnswer;
      case 'reject':
        return CallEventType.reject;
      case 'negotiate':
        return CallEventType.negotiate;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "CallEventType"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
