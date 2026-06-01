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

/// **TASK20-Phase2 Chunk 4**: MessageBus envelope для PushRoutingService
/// → PushQueueWorker delivery. Single field `payloadJson` несёт
/// JSON-serialized [PushPayload] (recipient/token/title/body/data/
/// threadId).
///
/// Зачем `payloadJson: String`, а не отдельные generated fields:
/// `PushPayload.data: Map<String, String>` — Serverpod's spy.yaml
/// natively не поддерживает Map<String, String>; альтернативы (List<
/// KeyValue> wrapper) overhead в DTO-design. Простейший путь — JSON
/// envelope.
abstract class PushQueueMessage implements _i1.SerializableModel {
  PushQueueMessage._({required this.payloadJson});

  factory PushQueueMessage({required String payloadJson}) =
      _PushQueueMessageImpl;

  factory PushQueueMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return PushQueueMessage(
      payloadJson: jsonSerialization['payloadJson'] as String,
    );
  }

  String payloadJson;

  /// Returns a shallow copy of this [PushQueueMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PushQueueMessage copyWith({String? payloadJson});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PushQueueMessage',
      'payloadJson': payloadJson,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PushQueueMessageImpl extends PushQueueMessage {
  _PushQueueMessageImpl({required String payloadJson})
    : super._(payloadJson: payloadJson);

  /// Returns a shallow copy of this [PushQueueMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PushQueueMessage copyWith({String? payloadJson}) {
    return PushQueueMessage(payloadJson: payloadJson ?? this.payloadJson);
  }
}
