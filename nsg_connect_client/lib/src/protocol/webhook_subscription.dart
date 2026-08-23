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

/// WebhookSubscription — подписка внешнего сервиса на доменные события
/// мессенджера (TASK35 outbound webhooks MVP). Каждая строка — один
/// endpoint (`url`), которому платформа доставляет HMAC-подписанные
/// события, проходящие фильтр по `tenantId`/`productId`/`eventTypes`.
///
/// Циркуляр-брейкер: `failureCount` копит consecutive-fails delivery-worker-а;
/// при достижении порога подписка авто-дизейблится (`enabled=false`,
/// `disabledAt`), чтобы не долбить мёртвый endpoint бесконечно. Admin
/// может ре-энейблить через `updateSubscription` (сбрасывает счётчик).
abstract class WebhookSubscription implements _i1.SerializableModel {
  WebhookSubscription._({
    this.id,
    required this.tenantId,
    this.productId,
    required this.url,
    required this.secret,
    required this.eventTypes,
    this.roomId,
    this.botId,
    String? deliveryMode,
    this.lastPulledDeliveryId,
    this.lastPulledAt,
    bool? enabled,
    int? failureCount,
    this.lastSuccessAt,
    this.disabledAt,
    int? probesSinceDisabled,
    this.lastProbeAt,
    this.probeGaveUpAt,
    this.lastReachCheckAt,
    this.unreachableSince,
    this.description,
    required this.createdAt,
  }) : deliveryMode = deliveryMode ?? 'push',
       enabled = enabled ?? true,
       failureCount = failureCount ?? 0,
       probesSinceDisabled = probesSinceDisabled ?? 0;

  factory WebhookSubscription({
    int? id,
    required int tenantId,
    int? productId,
    required String url,
    required String secret,
    required String eventTypes,
    int? roomId,
    int? botId,
    String? deliveryMode,
    int? lastPulledDeliveryId,
    DateTime? lastPulledAt,
    bool? enabled,
    int? failureCount,
    DateTime? lastSuccessAt,
    DateTime? disabledAt,
    int? probesSinceDisabled,
    DateTime? lastProbeAt,
    DateTime? probeGaveUpAt,
    DateTime? lastReachCheckAt,
    DateTime? unreachableSince,
    String? description,
    required DateTime createdAt,
  }) = _WebhookSubscriptionImpl;

  factory WebhookSubscription.fromJson(Map<String, dynamic> jsonSerialization) {
    return WebhookSubscription(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int?,
      url: jsonSerialization['url'] as String,
      secret: jsonSerialization['secret'] as String,
      eventTypes: jsonSerialization['eventTypes'] as String,
      roomId: jsonSerialization['roomId'] as int?,
      botId: jsonSerialization['botId'] as int?,
      deliveryMode: jsonSerialization['deliveryMode'] as String?,
      lastPulledDeliveryId: jsonSerialization['lastPulledDeliveryId'] as int?,
      lastPulledAt: jsonSerialization['lastPulledAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastPulledAt'],
            ),
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      failureCount: jsonSerialization['failureCount'] as int?,
      lastSuccessAt: jsonSerialization['lastSuccessAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastSuccessAt'],
            ),
      disabledAt: jsonSerialization['disabledAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['disabledAt']),
      probesSinceDisabled: jsonSerialization['probesSinceDisabled'] as int?,
      lastProbeAt: jsonSerialization['lastProbeAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastProbeAt'],
            ),
      probeGaveUpAt: jsonSerialization['probeGaveUpAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['probeGaveUpAt'],
            ),
      lastReachCheckAt: jsonSerialization['lastReachCheckAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastReachCheckAt'],
            ),
      unreachableSince: jsonSerialization['unreachableSince'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['unreachableSince'],
            ),
      description: jsonSerialization['description'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на Tenant. Cascade-delete: подписки удаляются вместе с tenant-ом.
  int tenantId;

  /// NULL = подписка на события всего tenant-а (любой продукт). Иначе —
  /// только события этого продукта. SetNull: при удалении продукта
  /// подписка остаётся (становится tenant-wide).
  int? productId;

  /// Целевой HTTPS-URL. Валидируется SSRF-гардом (WebhookUrlValidator)
  /// на create/update и повторно перед каждой доставкой.
  String url;

  /// Секрет для HMAC-SHA256 подписи тела (заголовок X-Webhook-Signature).
  String secret;

  /// CSV имён webhook-событий, на которые подписан endpoint, например
  /// `message.created,room.created`. Low-cardinality — фильтруем в Dart
  /// (substring/exact match по элементам), без отдельной таблицы.
  String eventTypes;

  /// TASK59 (self-service бот-интеграция): room-scoped подписка — доставлять
  /// ТОЛЬКО события, чей `payload.roomId == roomId`. null = прежнее поведение
  /// (tenant/product-wide). Cascade: удаляется вместе с комнатой.
  int? roomId;

  /// TASK59: если задан — подписка принадлежит self-service бот-интеграции
  /// (ротация/отзыв вместе с ботом). null = обычная admin-подписка (TASK35).
  int? botId;

  /// **issue #154**: как подписчик получает события.
  ///
  ///   * `push` — сервер сам стучится POST-ом по [url] (как было всегда);
  ///   * `pull` — подписчик приходит сам за `POST /events/pull` и читает
  ///     журнал по курсору. Сервер в этом режиме НЕ делает исходящих
  ///     запросов вовсе: строку доставки пишет, попытку не планирует.
  ///
  /// Зачем второй режим. У подписчика может не быть публичного адреса —
  /// наши боты живут на рабочей машине владельца, и до них дотягивались
  /// обратным ssh-туннелем «пока нет полноценных вебхуков». Пять минут
  /// бюджета ретраев короче любого перерыва в работе такой машины, отсюда
  /// 88 потерянных сообщений (#153). В pull-режиме терять нечего: событие
  /// лежит в журнале, пока за ним не придут.
  String deliveryMode;

  /// **issue #154**: курсор pull-подписчика — id последней доставки,
  /// которую он подтвердил (прислал в следующем запросе). Держим на
  /// сервере, чтобы клиенту было достаточно помнить его между запросами,
  /// а восстановиться он мог и без него.
  int? lastPulledDeliveryId;

  /// **issue #154**: когда pull-подписчик приходил в последний раз.
  ///
  /// Признак жизни для pull-канала. Курсор для этого не годится: он
  /// двигается только когда есть события, и на тихом канале стоит часами,
  /// пока подписчик исправно ходит каждые 25 секунд.
  ///
  /// Обновляется на каждом успешном запросе за событиями — одна запись в
  /// 25 секунд на канал, то есть пренебрежимо. Без него «подписчик умер» и
  /// «в чате тихо» неотличимы, а проба HTTP-адреса у pull-подписки
  /// бессмысленна: слушать там некому по построению.
  DateTime? lastPulledAt;

  bool enabled;

  /// Подряд идущих неуспешных ПОПЫТОК доставки (failed HTTP call) для
  /// circuit-breaker — по каждой попытке, не по одной на исчерпавшую ретраи
  /// доставку, иначе мёртвый endpoint не дизейблился бы за разумное время.
  /// Admin-тест (`webhook.test`) не учитывается. Сбрасывается в 0 на первой
  /// успешной доставке.
  int failureCount;

  DateTime? lastSuccessAt;

  /// Выставляется когда circuit-breaker авто-дизейблит подписку.
  ///
  /// **issue #128** — это ещё и признак «выключил размыкатель, а не
  /// человек»: ручной `enabled=false` поля не трогает, а ручной
  /// `enabled=true` его обнуляет. Только по этому различию свипер проб
  /// понимает, кого позволено включить обратно: включить подписку,
  /// выключенную администратором намеренно, было бы хуже, чем не включить
  /// вовсе.
  DateTime? disabledAt;

  /// **issue #128**: сколько проб сделано с момента отключения. Обнуляется
  /// вместе с возвратом в строй. Хранится, а не считается на лету: расписание
  /// проб растущее, и без счётчика после рестарта сервера разгон начинался бы
  /// заново — мёртвый endpoint снова получал бы пробу раз в минуту.
  int probesSinceDisabled;

  /// **issue #128**: когда пробовали последний раз. Отдельно от `disabledAt`:
  /// по первому видно, когда всё сломалось, по второму — жив ли свипер.
  DateTime? lastProbeAt;

  /// **issue #128**: когда пробовать перестали окончательно (неделя
  /// недоступности). Не булев флаг: время нужно, чтобы отличить «оборвали
  /// только что» от «висит мёртвым месяц», и чтобы отчёт здоровья мог
  /// назвать дату. `null` — либо живём, либо ещё пробуем.
  DateTime? probeGaveUpAt;

  /// **issue #131**: когда мы последний раз сами проверяли, достижим ли
  /// endpoint ВКЛЮЧЁННОЙ подписки. Отдельно от `lastProbeAt`: тот про
  /// возврат выключенной в строй, этот — про молчащую, но включённую.
  /// Слить их в одно поле значило бы, что одна проверка стирает след другой.
  DateTime? lastReachCheckAt;

  /// **issue #131**: с какого момента путь до endpoint-а не отвечает.
  /// `null` — последняя проверка удалась (или проверок ещё не было).
  ///
  /// Момент, а не флаг: «не отвечает минуту» и «не отвечает час» — разные
  /// новости, и монитор обязан их различать. Короткий обрыв прощаем
  /// (`webhookUnreachableGrace`), иначе мигнувшая сеть будет поднимать
  /// тревогу; длинный — это ровно тот отказ, который 13.08 висел час и не
  /// был виден никому: подписка включена, размыкатель молчит (трафика нет,
  /// значит и неудачных доставок нет), а канала не существует.
  DateTime? unreachableSince;

  String? description;

  DateTime createdAt;

  /// Returns a shallow copy of this [WebhookSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WebhookSubscription copyWith({
    int? id,
    int? tenantId,
    int? productId,
    String? url,
    String? secret,
    String? eventTypes,
    int? roomId,
    int? botId,
    String? deliveryMode,
    int? lastPulledDeliveryId,
    DateTime? lastPulledAt,
    bool? enabled,
    int? failureCount,
    DateTime? lastSuccessAt,
    DateTime? disabledAt,
    int? probesSinceDisabled,
    DateTime? lastProbeAt,
    DateTime? probeGaveUpAt,
    DateTime? lastReachCheckAt,
    DateTime? unreachableSince,
    String? description,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WebhookSubscription',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      if (productId != null) 'productId': productId,
      'url': url,
      'secret': secret,
      'eventTypes': eventTypes,
      if (roomId != null) 'roomId': roomId,
      if (botId != null) 'botId': botId,
      'deliveryMode': deliveryMode,
      if (lastPulledDeliveryId != null)
        'lastPulledDeliveryId': lastPulledDeliveryId,
      if (lastPulledAt != null) 'lastPulledAt': lastPulledAt?.toJson(),
      'enabled': enabled,
      'failureCount': failureCount,
      if (lastSuccessAt != null) 'lastSuccessAt': lastSuccessAt?.toJson(),
      if (disabledAt != null) 'disabledAt': disabledAt?.toJson(),
      'probesSinceDisabled': probesSinceDisabled,
      if (lastProbeAt != null) 'lastProbeAt': lastProbeAt?.toJson(),
      if (probeGaveUpAt != null) 'probeGaveUpAt': probeGaveUpAt?.toJson(),
      if (lastReachCheckAt != null)
        'lastReachCheckAt': lastReachCheckAt?.toJson(),
      if (unreachableSince != null)
        'unreachableSince': unreachableSince?.toJson(),
      if (description != null) 'description': description,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WebhookSubscriptionImpl extends WebhookSubscription {
  _WebhookSubscriptionImpl({
    int? id,
    required int tenantId,
    int? productId,
    required String url,
    required String secret,
    required String eventTypes,
    int? roomId,
    int? botId,
    String? deliveryMode,
    int? lastPulledDeliveryId,
    DateTime? lastPulledAt,
    bool? enabled,
    int? failureCount,
    DateTime? lastSuccessAt,
    DateTime? disabledAt,
    int? probesSinceDisabled,
    DateTime? lastProbeAt,
    DateTime? probeGaveUpAt,
    DateTime? lastReachCheckAt,
    DateTime? unreachableSince,
    String? description,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         productId: productId,
         url: url,
         secret: secret,
         eventTypes: eventTypes,
         roomId: roomId,
         botId: botId,
         deliveryMode: deliveryMode,
         lastPulledDeliveryId: lastPulledDeliveryId,
         lastPulledAt: lastPulledAt,
         enabled: enabled,
         failureCount: failureCount,
         lastSuccessAt: lastSuccessAt,
         disabledAt: disabledAt,
         probesSinceDisabled: probesSinceDisabled,
         lastProbeAt: lastProbeAt,
         probeGaveUpAt: probeGaveUpAt,
         lastReachCheckAt: lastReachCheckAt,
         unreachableSince: unreachableSince,
         description: description,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WebhookSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WebhookSubscription copyWith({
    Object? id = _Undefined,
    int? tenantId,
    Object? productId = _Undefined,
    String? url,
    String? secret,
    String? eventTypes,
    Object? roomId = _Undefined,
    Object? botId = _Undefined,
    String? deliveryMode,
    Object? lastPulledDeliveryId = _Undefined,
    Object? lastPulledAt = _Undefined,
    bool? enabled,
    int? failureCount,
    Object? lastSuccessAt = _Undefined,
    Object? disabledAt = _Undefined,
    int? probesSinceDisabled,
    Object? lastProbeAt = _Undefined,
    Object? probeGaveUpAt = _Undefined,
    Object? lastReachCheckAt = _Undefined,
    Object? unreachableSince = _Undefined,
    Object? description = _Undefined,
    DateTime? createdAt,
  }) {
    return WebhookSubscription(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      productId: productId is int? ? productId : this.productId,
      url: url ?? this.url,
      secret: secret ?? this.secret,
      eventTypes: eventTypes ?? this.eventTypes,
      roomId: roomId is int? ? roomId : this.roomId,
      botId: botId is int? ? botId : this.botId,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      lastPulledDeliveryId: lastPulledDeliveryId is int?
          ? lastPulledDeliveryId
          : this.lastPulledDeliveryId,
      lastPulledAt: lastPulledAt is DateTime?
          ? lastPulledAt
          : this.lastPulledAt,
      enabled: enabled ?? this.enabled,
      failureCount: failureCount ?? this.failureCount,
      lastSuccessAt: lastSuccessAt is DateTime?
          ? lastSuccessAt
          : this.lastSuccessAt,
      disabledAt: disabledAt is DateTime? ? disabledAt : this.disabledAt,
      probesSinceDisabled: probesSinceDisabled ?? this.probesSinceDisabled,
      lastProbeAt: lastProbeAt is DateTime? ? lastProbeAt : this.lastProbeAt,
      probeGaveUpAt: probeGaveUpAt is DateTime?
          ? probeGaveUpAt
          : this.probeGaveUpAt,
      lastReachCheckAt: lastReachCheckAt is DateTime?
          ? lastReachCheckAt
          : this.lastReachCheckAt,
      unreachableSince: unreachableSince is DateTime?
          ? unreachableSince
          : this.unreachableSince,
      description: description is String? ? description : this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
