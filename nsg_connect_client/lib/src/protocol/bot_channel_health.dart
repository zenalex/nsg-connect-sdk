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

/// **Здоровье канала доставки глазами самого бота** (issue #131).
///
/// Бот спрашивает СВОИМ токеном, доходят ли до него события. 11.08 это был
/// единственный неизвестный: процесс жил, порт слушал, туннель стоял, а
/// подписка была выключена — и снаружи это выглядело исправностью.
///
/// **Только счётчики и вердикт.** Ни url, ни секретов, ни идентификаторов
/// подписок: боты живут на клиентских машинах, и «здоровье» не повод
/// отдавать туда устройство чужой доставки.
abstract class BotChannelHealth implements _i1.SerializableModel {
  BotChannelHealth._({
    required this.botId,
    required this.botName,
    required this.scope,
    required this.subscriptions,
    required this.breakerDisabled,
    required this.gaveUp,
    required this.offByHand,
    required this.lostRecently,
    this.lastSuccessAt,
    required this.verdict,
    required this.detail,
  });

  factory BotChannelHealth({
    required int botId,
    required String botName,
    required String scope,
    required int subscriptions,
    required int breakerDisabled,
    required int gaveUp,
    required int offByHand,
    required int lostRecently,
    DateTime? lastSuccessAt,
    required String verdict,
    required String detail,
  }) = _BotChannelHealthImpl;

  factory BotChannelHealth.fromJson(Map<String, dynamic> jsonSerialization) {
    return BotChannelHealth(
      botId: jsonSerialization['botId'] as int,
      botName: jsonSerialization['botName'] as String,
      scope: jsonSerialization['scope'] as String,
      subscriptions: jsonSerialization['subscriptions'] as int,
      breakerDisabled: jsonSerialization['breakerDisabled'] as int,
      gaveUp: jsonSerialization['gaveUp'] as int,
      offByHand: jsonSerialization['offByHand'] as int,
      lostRecently: jsonSerialization['lostRecently'] as int,
      lastSuccessAt: jsonSerialization['lastSuccessAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastSuccessAt'],
            ),
      verdict: jsonSerialization['verdict'] as String,
      detail: jsonSerialization['detail'] as String,
    );
  }

  int botId;

  String botName;

  /// Какой областью получен ответ: `bot` — подписки привязаны к этому боту
  /// (точный ответ); `product` / `tenant` — привязки нет, отвечаем по
  /// продукту или тенанту (ответ шире, чем спрошено).
  ///
  /// Поле обязательное и в ответе видно всегда: молча выдать ответ по
  /// тенанту за ответ про конкретного бота значило бы сказать «у тебя всё
  /// хорошо» о чужих каналах.
  String scope;

  /// Подписок в области. Ноль — отдельная беда: событий не доставляет
  /// никто, и зелёным это быть не может.
  int subscriptions;

  /// Выключено размыкателем (пробы идут, канал может вернуться сам).
  int breakerDisabled;

  /// Оборвано окончательно: неделя недоступности, дальше нужен человек.
  int gaveUp;

  /// Выключено человеком — не поломка, но канал молчит, и знать об этом надо.
  int offByHand;

  /// Доставок в DLQ за последний час: события теряются прямо сейчас.
  int lostRecently;

  /// Когда доставка в последний раз удалась хоть по одной подписке области.
  /// На вердикт не влияет (тишина неотличима от отсутствия событий), но в
  /// разборе это первое, на что смотрят.
  DateTime? lastSuccessAt;

  /// `ok` | `warn` | `error` — тот же вердикт и по тому же правилу, что у
  /// монитора Pulse: считает одна и та же чистая функция.
  String verdict;

  /// Человекочитаемая причина. Имена каналов — без url.
  String detail;

  /// Returns a shallow copy of this [BotChannelHealth]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BotChannelHealth copyWith({
    int? botId,
    String? botName,
    String? scope,
    int? subscriptions,
    int? breakerDisabled,
    int? gaveUp,
    int? offByHand,
    int? lostRecently,
    DateTime? lastSuccessAt,
    String? verdict,
    String? detail,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BotChannelHealth',
      'botId': botId,
      'botName': botName,
      'scope': scope,
      'subscriptions': subscriptions,
      'breakerDisabled': breakerDisabled,
      'gaveUp': gaveUp,
      'offByHand': offByHand,
      'lostRecently': lostRecently,
      if (lastSuccessAt != null) 'lastSuccessAt': lastSuccessAt?.toJson(),
      'verdict': verdict,
      'detail': detail,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BotChannelHealthImpl extends BotChannelHealth {
  _BotChannelHealthImpl({
    required int botId,
    required String botName,
    required String scope,
    required int subscriptions,
    required int breakerDisabled,
    required int gaveUp,
    required int offByHand,
    required int lostRecently,
    DateTime? lastSuccessAt,
    required String verdict,
    required String detail,
  }) : super._(
         botId: botId,
         botName: botName,
         scope: scope,
         subscriptions: subscriptions,
         breakerDisabled: breakerDisabled,
         gaveUp: gaveUp,
         offByHand: offByHand,
         lostRecently: lostRecently,
         lastSuccessAt: lastSuccessAt,
         verdict: verdict,
         detail: detail,
       );

  /// Returns a shallow copy of this [BotChannelHealth]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BotChannelHealth copyWith({
    int? botId,
    String? botName,
    String? scope,
    int? subscriptions,
    int? breakerDisabled,
    int? gaveUp,
    int? offByHand,
    int? lostRecently,
    Object? lastSuccessAt = _Undefined,
    String? verdict,
    String? detail,
  }) {
    return BotChannelHealth(
      botId: botId ?? this.botId,
      botName: botName ?? this.botName,
      scope: scope ?? this.scope,
      subscriptions: subscriptions ?? this.subscriptions,
      breakerDisabled: breakerDisabled ?? this.breakerDisabled,
      gaveUp: gaveUp ?? this.gaveUp,
      offByHand: offByHand ?? this.offByHand,
      lostRecently: lostRecently ?? this.lostRecently,
      lastSuccessAt: lastSuccessAt is DateTime?
          ? lastSuccessAt
          : this.lastSuccessAt,
      verdict: verdict ?? this.verdict,
      detail: detail ?? this.detail,
    );
  }
}
