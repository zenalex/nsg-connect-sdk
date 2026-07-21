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
import 'bot.dart' as _i2;
import 'webhook_subscription.dart' as _i3;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i4;

/// DTO create/rotate self-service бот-интеграции (TASK59). Секреты
/// показываются клиенту ОДИН раз:
///   * `bot.accessToken` — Bearer-токен бота для `messenger/sendMessage`;
///   * `subscription.secret` — секрет для проверки HMAC входящих webhook-ов.
/// `apiBase` — база для вызовов API (напр. https://api.chatista.me).
abstract class BotIntegrationCreated implements _i1.SerializableModel {
  BotIntegrationCreated._({
    required this.bot,
    required this.subscription,
    required this.apiBase,
  });

  factory BotIntegrationCreated({
    required _i2.Bot bot,
    required _i3.WebhookSubscription subscription,
    required String apiBase,
  }) = _BotIntegrationCreatedImpl;

  factory BotIntegrationCreated.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BotIntegrationCreated(
      bot: _i4.Protocol().deserialize<_i2.Bot>(jsonSerialization['bot']),
      subscription: _i4.Protocol().deserialize<_i3.WebhookSubscription>(
        jsonSerialization['subscription'],
      ),
      apiBase: jsonSerialization['apiBase'] as String,
    );
  }

  _i2.Bot bot;

  _i3.WebhookSubscription subscription;

  String apiBase;

  /// Returns a shallow copy of this [BotIntegrationCreated]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BotIntegrationCreated copyWith({
    _i2.Bot? bot,
    _i3.WebhookSubscription? subscription,
    String? apiBase,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BotIntegrationCreated',
      'bot': bot.toJson(),
      'subscription': subscription.toJson(),
      'apiBase': apiBase,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _BotIntegrationCreatedImpl extends BotIntegrationCreated {
  _BotIntegrationCreatedImpl({
    required _i2.Bot bot,
    required _i3.WebhookSubscription subscription,
    required String apiBase,
  }) : super._(
         bot: bot,
         subscription: subscription,
         apiBase: apiBase,
       );

  /// Returns a shallow copy of this [BotIntegrationCreated]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BotIntegrationCreated copyWith({
    _i2.Bot? bot,
    _i3.WebhookSubscription? subscription,
    String? apiBase,
  }) {
    return BotIntegrationCreated(
      bot: bot ?? this.bot.copyWith(),
      subscription: subscription ?? this.subscription.copyWith(),
      apiBase: apiBase ?? this.apiBase,
    );
  }
}
