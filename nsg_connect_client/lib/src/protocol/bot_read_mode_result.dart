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
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i3;

/// **TASK77 итер.3**: ответ смены режима чтения бота — сам бот плюс
/// честное предупреждение о том, где приватность НЕ сработает.
///
/// **Зачем отдельный DTO вместо голого `Bot`.** Фильтр privacy mode на
/// push-пути применяется только к webhook-подпискам, привязанным к боту
/// (`WebhookSubscription.botId`) — у подписки уровня тенанта/продукта нет
/// владельца-бота, и определять режим нечем (ограничение, найденное на
/// проде после итер.2). Пользователь, переключивший бота в
/// `read_addressed`, обязан узнать об этом СРАЗУ, а не выяснить потом, что
/// поток событий как шёл целиком, так и идёт. Возвращать это отдельным
/// запросом нельзя: «предупреждение, которое можно не запросить» — это
/// предупреждение, которого нет.
abstract class BotReadModeResult implements _i1.SerializableModel {
  BotReadModeResult._({
    required this.bot,
    required this.unboundSubscriptionCount,
  });

  factory BotReadModeResult({
    required _i2.Bot bot,
    required int unboundSubscriptionCount,
  }) = _BotReadModeResultImpl;

  factory BotReadModeResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return BotReadModeResult(
      bot: _i3.Protocol().deserialize<_i2.Bot>(jsonSerialization['bot']),
      unboundSubscriptionCount:
          jsonSerialization['unboundSubscriptionCount'] as int,
    );
  }

  /// Обновлённый бот (`accessToken` зануляется вызывающим endpoint-ом).
  _i2.Bot bot;

  /// Сколько enabled-подписок БЕЗ `botId` покрывают комнаты этого бота.
  /// `> 0` при `readMode = read_addressed` означает: «чтение истории
  /// ограничено, но поток событий в эти приёмники не фильтруется».
  /// `0` — приватность действует на обеих осях.
  int unboundSubscriptionCount;

  /// Returns a shallow copy of this [BotReadModeResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BotReadModeResult copyWith({
    _i2.Bot? bot,
    int? unboundSubscriptionCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BotReadModeResult',
      'bot': bot.toJson(),
      'unboundSubscriptionCount': unboundSubscriptionCount,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _BotReadModeResultImpl extends BotReadModeResult {
  _BotReadModeResultImpl({
    required _i2.Bot bot,
    required int unboundSubscriptionCount,
  }) : super._(
         bot: bot,
         unboundSubscriptionCount: unboundSubscriptionCount,
       );

  /// Returns a shallow copy of this [BotReadModeResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BotReadModeResult copyWith({
    _i2.Bot? bot,
    int? unboundSubscriptionCount,
  }) {
    return BotReadModeResult(
      bot: bot ?? this.bot.copyWith(),
      unboundSubscriptionCount:
          unboundSubscriptionCount ?? this.unboundSubscriptionCount,
    );
  }
}
