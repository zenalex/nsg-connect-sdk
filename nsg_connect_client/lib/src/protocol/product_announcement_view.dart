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
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i2;

/// **TASK91 (issue #65)**: объявление глазами ПРОДУКТА — ответ ручек
/// `productAnnouncement/*`, которыми сервер продукта заводит и снимает свои
/// объявления под тем же секретом, что и рассылка уведомлений.
///
/// Третье представление одной сущности, и все три нужны:
///
///   * [Announcement] — строка таблицы. В ней `createdByEmail` оператора
///     платформы и внутренние `tenantId`/`productId`. Отдать её продукту
///     значит отдать почту сотрудника другой компании за одну проверку
///     секрета, а числовые id — за ту же цену дать материал для подбора
///     чужих;
///   * [AnnouncementView] — то, что видит КОНЕЧНЫЙ пользователь. Там нет ни
///     выключателя, ни окон показа: клиенту решать нечего, сервер уже решил,
///     что это объявление ему сейчас показывать;
///   * этот класс — то, чем продукт УПРАВЛЯЕТ. Здесь окна и выключатель как
///     раз обязаны быть: без них продукт не увидит, почему его объявление
///     молчит, и заведёт второе.
abstract class ProductAnnouncementView implements _i1.SerializableModel {
  ProductAnnouncementView._({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.route,
    this.payloadJson,
    this.url,
    required this.severity,
    required this.enabled,
    required this.targeted,
    this.unknownRecipients,
    this.startsAt,
    this.expiresAt,
    required this.live,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductAnnouncementView({
    required int id,
    required String kind,
    required String title,
    required String body,
    String? route,
    String? payloadJson,
    String? url,
    required String severity,
    required bool enabled,
    required bool targeted,
    List<String>? unknownRecipients,
    DateTime? startsAt,
    DateTime? expiresAt,
    required bool live,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProductAnnouncementViewImpl;

  factory ProductAnnouncementView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ProductAnnouncementView(
      id: jsonSerialization['id'] as int,
      kind: jsonSerialization['kind'] as String,
      title: jsonSerialization['title'] as String,
      body: jsonSerialization['body'] as String,
      route: jsonSerialization['route'] as String?,
      payloadJson: jsonSerialization['payloadJson'] as String?,
      url: jsonSerialization['url'] as String?,
      severity: jsonSerialization['severity'] as String,
      enabled: _i1.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      targeted: _i1.BoolJsonExtension.fromJson(jsonSerialization['targeted']),
      unknownRecipients: jsonSerialization['unknownRecipients'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['unknownRecipients'],
            ),
      startsAt: jsonSerialization['startsAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['startsAt']),
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      live: _i1.BoolJsonExtension.fromJson(jsonSerialization['live']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// Идентификатор для последующего `setEnabled`. Единственное число,
  /// которое продукт от нас получает, и оно же — единственное, которое ему
  /// нужно, чтобы отозвать ошибочную рассылку.
  int id;

  /// `text` | `route` | `link`. Отдаётся как заведено: продукт прислал его
  /// сам, и подмена незнакомого вида на `text` (правило показа для СТАРОГО
  /// клиента) здесь скрыла бы от него собственную опечатку.
  String kind;

  String title;

  /// Markdown — тот же subset, что в пузырях чата.
  String body;

  /// Только для `kind = route`: маршрут и payload в терминах продукта.
  String? route;

  String? payloadJson;

  /// Только для `kind = link`: внешний http(s)-адрес кнопки. Отдаётся, чтобы
  /// продукту было по чему узнать своё объявление в списке: реклама с одним
  /// и тем же текстом и разными ссылками — это разные кампании, и без этого
  /// поля они в ответе неотличимы.
  String? url;

  /// `info` | `warning`.
  String severity;

  /// Выключатель. `false` — объявление снято с показа, но не удалено:
  /// отметки о просмотре целы, и при повторном включении никто не увидит
  /// его дважды.
  bool enabled;

  /// **Адресное ли объявление**: `true` — показывается только перечисленным
  /// при заведении людям, `false` — каждому пользователю продукта.
  ///
  /// Самих адресатов в ответе нет: их бывает до 500 на объявление, а `list`
  /// возвращает до 200 объявлений — то есть сто тысяч строк ради поля,
  /// которое продукт и так знает (он этот список и прислал). Флага хватает,
  /// чтобы отличить в списке пробную рассылку на себя от боевой на всех —
  /// а перепутать их страшно именно здесь.
  bool targeted;

  /// **Кого из названных адресатов мы пока не знаем** — заполняется ТОЛЬКО
  /// ответом `create`.
  ///
  /// `null` — не считалось (`list`, `setEnabled`); пустой список — все
  /// адресаты известны. Это разные вещи, и путать их нельзя: «не считали»
  /// не означает «все на месте».
  ///
  /// Зачем вообще: продуктовые уведомления уже различают «адресата не
  /// знаем» (`unknown_recipient`) и «устройств нет» (`no_devices`), и
  /// различение появилось не от любви к деталям — прод показал продукт,
  /// полтора месяца сливавший рассылку двум несуществующим адресатам, и по
  /// ответу это было неотличимо от «люди не поставили приложение».
  /// Промолчать здесь значило бы завести ту же яму заново: объявление,
  /// адресованное опечатке, выглядит точно так же, как объявление,
  /// адресованное человеку, который просто ещё не заходил.
  ///
  /// Это НЕ отказ и НЕ ошибка. Объявление, в отличие от push, ждёт: адресат
  /// может стать известен позже (поставит приложение — увидит при входе), и
  /// хранится список по внешним идентификаторам как раз ради этого.
  List<String>? unknownRecipients;

  /// Окно показа, как его задал продукт.
  DateTime? startsAt;

  DateTime? expiresAt;

  /// **Показывается ли ПРЯМО СЕЙЧАС** — итог всех правил показа одним
  /// полем (`AnnouncementService.isLive`).
  ///
  /// Без него продукт вывел бы то же самое из трёх полей выше и вывел бы
  /// неверно: граница `expiresAt` закрыта, `startsAt` открыт. Расхождение
  /// он увидел бы как «у нас числится живым, а людям не показывается» — то
  /// есть в момент разбора жалобы.
  bool live;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ProductAnnouncementView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProductAnnouncementView copyWith({
    int? id,
    String? kind,
    String? title,
    String? body,
    String? route,
    String? payloadJson,
    String? url,
    String? severity,
    bool? enabled,
    bool? targeted,
    List<String>? unknownRecipients,
    DateTime? startsAt,
    DateTime? expiresAt,
    bool? live,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProductAnnouncementView',
      'id': id,
      'kind': kind,
      'title': title,
      'body': body,
      if (route != null) 'route': route,
      if (payloadJson != null) 'payloadJson': payloadJson,
      if (url != null) 'url': url,
      'severity': severity,
      'enabled': enabled,
      'targeted': targeted,
      if (unknownRecipients != null)
        'unknownRecipients': unknownRecipients?.toJson(),
      if (startsAt != null) 'startsAt': startsAt?.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      'live': live,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProductAnnouncementViewImpl extends ProductAnnouncementView {
  _ProductAnnouncementViewImpl({
    required int id,
    required String kind,
    required String title,
    required String body,
    String? route,
    String? payloadJson,
    String? url,
    required String severity,
    required bool enabled,
    required bool targeted,
    List<String>? unknownRecipients,
    DateTime? startsAt,
    DateTime? expiresAt,
    required bool live,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         kind: kind,
         title: title,
         body: body,
         route: route,
         payloadJson: payloadJson,
         url: url,
         severity: severity,
         enabled: enabled,
         targeted: targeted,
         unknownRecipients: unknownRecipients,
         startsAt: startsAt,
         expiresAt: expiresAt,
         live: live,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ProductAnnouncementView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProductAnnouncementView copyWith({
    int? id,
    String? kind,
    String? title,
    String? body,
    Object? route = _Undefined,
    Object? payloadJson = _Undefined,
    Object? url = _Undefined,
    String? severity,
    bool? enabled,
    bool? targeted,
    Object? unknownRecipients = _Undefined,
    Object? startsAt = _Undefined,
    Object? expiresAt = _Undefined,
    bool? live,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductAnnouncementView(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      body: body ?? this.body,
      route: route is String? ? route : this.route,
      payloadJson: payloadJson is String? ? payloadJson : this.payloadJson,
      url: url is String? ? url : this.url,
      severity: severity ?? this.severity,
      enabled: enabled ?? this.enabled,
      targeted: targeted ?? this.targeted,
      unknownRecipients: unknownRecipients is List<String>?
          ? unknownRecipients
          : this.unknownRecipients?.map((e0) => e0).toList(),
      startsAt: startsAt is DateTime? ? startsAt : this.startsAt,
      expiresAt: expiresAt is DateTime? ? expiresAt : this.expiresAt,
      live: live ?? this.live,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
