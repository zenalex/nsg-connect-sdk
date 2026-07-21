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

/// **TASK35**: MessageBus envelope для outbound-webhook event-tap.
/// Mirror [PushQueueMessage] (push_queue_message.spy.yaml): single
/// `payloadJson` field несёт JSON-serialized [WebhookEventEnvelope]
/// (tenantId/productId/eventType/payload/ts).
///
/// Зачем JSON-в-строке, а не generated fields: payload — произвольный
/// `Map<String,dynamic>`, который spy.yaml natively не сериализует.
/// Тот же приём, что и в push-пайплайне. См. WebhookEventService.
abstract class WebhookEventMessage implements _i1.SerializableModel {
  WebhookEventMessage._({required this.payloadJson});

  factory WebhookEventMessage({required String payloadJson}) =
      _WebhookEventMessageImpl;

  factory WebhookEventMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return WebhookEventMessage(
      payloadJson: jsonSerialization['payloadJson'] as String,
    );
  }

  String payloadJson;

  /// Returns a shallow copy of this [WebhookEventMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WebhookEventMessage copyWith({String? payloadJson});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WebhookEventMessage',
      'payloadJson': payloadJson,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _WebhookEventMessageImpl extends WebhookEventMessage {
  _WebhookEventMessageImpl({required String payloadJson})
    : super._(payloadJson: payloadJson);

  /// Returns a shallow copy of this [WebhookEventMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WebhookEventMessage copyWith({String? payloadJson}) {
    return WebhookEventMessage(payloadJson: payloadJson ?? this.payloadJson);
  }
}
