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
import 'incoming_webhook.dart' as _i2;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i3;

/// DTO результата create/rotate входящего webhook-а (TASK58): сам webhook +
/// публичный токен. Токен показывается клиенту ОДИН раз (в URL /hooks/<token>),
/// в БД хранится только его хеш — поэтому отдаётся отдельным DTO, а не полем
/// таблицы IncomingWebhook.
abstract class IncomingWebhookCreated implements _i1.SerializableModel {
  IncomingWebhookCreated._({
    required this.webhook,
    required this.token,
  });

  factory IncomingWebhookCreated({
    required _i2.IncomingWebhook webhook,
    required String token,
  }) = _IncomingWebhookCreatedImpl;

  factory IncomingWebhookCreated.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return IncomingWebhookCreated(
      webhook: _i3.Protocol().deserialize<_i2.IncomingWebhook>(
        jsonSerialization['webhook'],
      ),
      token: jsonSerialization['token'] as String,
    );
  }

  _i2.IncomingWebhook webhook;

  /// Публичный токен iwh_… для вставки в URL. Показать один раз; далее только
  /// ротация (rotateToken).
  String token;

  /// Returns a shallow copy of this [IncomingWebhookCreated]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IncomingWebhookCreated copyWith({
    _i2.IncomingWebhook? webhook,
    String? token,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IncomingWebhookCreated',
      'webhook': webhook.toJson(),
      'token': token,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _IncomingWebhookCreatedImpl extends IncomingWebhookCreated {
  _IncomingWebhookCreatedImpl({
    required _i2.IncomingWebhook webhook,
    required String token,
  }) : super._(
         webhook: webhook,
         token: token,
       );

  /// Returns a shallow copy of this [IncomingWebhookCreated]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IncomingWebhookCreated copyWith({
    _i2.IncomingWebhook? webhook,
    String? token,
  }) {
    return IncomingWebhookCreated(
      webhook: webhook ?? this.webhook.copyWith(),
      token: token ?? this.token,
    );
  }
}
