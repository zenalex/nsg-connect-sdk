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

/// Безопасное представление бот-интеграции для списка «Боты» (TASK59) —
/// БЕЗ токена и секрета. Собирается из Bot + его room-scoped
/// WebhookSubscription. Для управления в UI (вкл/выкл, ротация, удаление).
abstract class BotIntegrationView implements _i1.SerializableModel {
  BotIntegrationView._({
    required this.botId,
    required this.botMessengerUserId,
    required this.name,
    required this.botEnabled,
    required this.webhookUrl,
    required this.eventTypes,
    required this.subscriptionEnabled,
    required this.subscriptionFailureCount,
    this.lastSuccessAt,
    required this.createdAt,
  });

  factory BotIntegrationView({
    required int botId,
    required int botMessengerUserId,
    required String name,
    required bool botEnabled,
    required String webhookUrl,
    required String eventTypes,
    required bool subscriptionEnabled,
    required int subscriptionFailureCount,
    DateTime? lastSuccessAt,
    required DateTime createdAt,
  }) = _BotIntegrationViewImpl;

  factory BotIntegrationView.fromJson(Map<String, dynamic> jsonSerialization) {
    return BotIntegrationView(
      botId: jsonSerialization['botId'] as int,
      botMessengerUserId: jsonSerialization['botMessengerUserId'] as int,
      name: jsonSerialization['name'] as String,
      botEnabled: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['botEnabled'],
      ),
      webhookUrl: jsonSerialization['webhookUrl'] as String,
      eventTypes: jsonSerialization['eventTypes'] as String,
      subscriptionEnabled: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['subscriptionEnabled'],
      ),
      subscriptionFailureCount:
          jsonSerialization['subscriptionFailureCount'] as int,
      lastSuccessAt: jsonSerialization['lastSuccessAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastSuccessAt'],
            ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int botId;

  int botMessengerUserId;

  String name;

  bool botEnabled;

  String webhookUrl;

  String eventTypes;

  bool subscriptionEnabled;

  int subscriptionFailureCount;

  DateTime? lastSuccessAt;

  DateTime createdAt;

  /// Returns a shallow copy of this [BotIntegrationView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BotIntegrationView copyWith({
    int? botId,
    int? botMessengerUserId,
    String? name,
    bool? botEnabled,
    String? webhookUrl,
    String? eventTypes,
    bool? subscriptionEnabled,
    int? subscriptionFailureCount,
    DateTime? lastSuccessAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BotIntegrationView',
      'botId': botId,
      'botMessengerUserId': botMessengerUserId,
      'name': name,
      'botEnabled': botEnabled,
      'webhookUrl': webhookUrl,
      'eventTypes': eventTypes,
      'subscriptionEnabled': subscriptionEnabled,
      'subscriptionFailureCount': subscriptionFailureCount,
      if (lastSuccessAt != null) 'lastSuccessAt': lastSuccessAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BotIntegrationViewImpl extends BotIntegrationView {
  _BotIntegrationViewImpl({
    required int botId,
    required int botMessengerUserId,
    required String name,
    required bool botEnabled,
    required String webhookUrl,
    required String eventTypes,
    required bool subscriptionEnabled,
    required int subscriptionFailureCount,
    DateTime? lastSuccessAt,
    required DateTime createdAt,
  }) : super._(
         botId: botId,
         botMessengerUserId: botMessengerUserId,
         name: name,
         botEnabled: botEnabled,
         webhookUrl: webhookUrl,
         eventTypes: eventTypes,
         subscriptionEnabled: subscriptionEnabled,
         subscriptionFailureCount: subscriptionFailureCount,
         lastSuccessAt: lastSuccessAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [BotIntegrationView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BotIntegrationView copyWith({
    int? botId,
    int? botMessengerUserId,
    String? name,
    bool? botEnabled,
    String? webhookUrl,
    String? eventTypes,
    bool? subscriptionEnabled,
    int? subscriptionFailureCount,
    Object? lastSuccessAt = _Undefined,
    DateTime? createdAt,
  }) {
    return BotIntegrationView(
      botId: botId ?? this.botId,
      botMessengerUserId: botMessengerUserId ?? this.botMessengerUserId,
      name: name ?? this.name,
      botEnabled: botEnabled ?? this.botEnabled,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      eventTypes: eventTypes ?? this.eventTypes,
      subscriptionEnabled: subscriptionEnabled ?? this.subscriptionEnabled,
      subscriptionFailureCount:
          subscriptionFailureCount ?? this.subscriptionFailureCount,
      lastSuccessAt: lastSuccessAt is DateTime?
          ? lastSuccessAt
          : this.lastSuccessAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
