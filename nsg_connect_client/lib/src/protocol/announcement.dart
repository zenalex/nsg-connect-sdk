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

/// **TASK91 (issue #65)**: объявление — то, что показывается пользователю ПРИ
/// ВХОДЕ в приложение: предупреждение о работах, новость, просьба что-то
/// открыть.
///
/// Дословно из заявки: «чтобы могли предупреждать о предстоящих работах,
/// нововведениях и прочем… показать текст (один раз потом просмотрено, срок
/// актуальности после которого не показываем), какую форму открыть (путь) и
/// payload».
///
/// **Это не push и не сообщение в чат.** Push (TASK72) догоняет человека, где
/// бы он ни был, и живёт ровно один раз; объявление, наоборот, ждёт, пока
/// человек сам откроет приложение, и до тех пор остаётся. Поэтому и отдельная
/// сущность, а не поле у уведомления: у них разные условия показа и разные
/// условия «больше не показывать».
///
/// Сделано кросс-продуктово (заявка: «для всех наших приложений»): tenant
/// обязателен, продукт — опционально.
abstract class Announcement implements _i1.SerializableModel {
  Announcement._({
    this.id,
    required this.tenantId,
    this.productId,
    String? kind,
    required this.title,
    required this.body,
    this.route,
    this.payloadJson,
    this.url,
    String? severity,
    this.startsAt,
    this.expiresAt,
    bool? enabled,
    this.createdByEmail,
    required this.createdAt,
    required this.updatedAt,
  }) : kind = kind ?? 'text',
       severity = severity ?? 'info',
       enabled = enabled ?? true;

  factory Announcement({
    int? id,
    required int tenantId,
    int? productId,
    String? kind,
    required String title,
    required String body,
    String? route,
    String? payloadJson,
    String? url,
    String? severity,
    DateTime? startsAt,
    DateTime? expiresAt,
    bool? enabled,
    String? createdByEmail,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AnnouncementImpl;

  factory Announcement.fromJson(Map<String, dynamic> jsonSerialization) {
    return Announcement(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int?,
      kind: jsonSerialization['kind'] as String?,
      title: jsonSerialization['title'] as String,
      body: jsonSerialization['body'] as String,
      route: jsonSerialization['route'] as String?,
      payloadJson: jsonSerialization['payloadJson'] as String?,
      url: jsonSerialization['url'] as String?,
      severity: jsonSerialization['severity'] as String?,
      startsAt: jsonSerialization['startsAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['startsAt']),
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      createdByEmail: jsonSerialization['createdByEmail'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на Tenant. Cascade: объявления уходят вместе с тенантом.
  int tenantId;

  /// NULL = всем продуктам тенанта. Иначе — только этому продукту.
  /// SetNull: удалили продукт — объявление становится общим, а не пропадает
  /// молча вместе с ним.
  int? productId;

  /// `text` — показать текст и закрыть. `route` — предложить открыть экран
  /// приложения ([route] + [payloadJson]). `link` — предложить открыть
  /// ВНЕШНЮЮ ссылку ([url]). Строкой, а не enum: набор видов
  /// будет расти со стороны продуктов, а старый клиент обязан пережить
  /// незнакомый вид (см. правило в AnnouncementService).
  String kind;

  String title;

  /// Markdown (тот же subset, что в пузырях чата) — у всех видов.
  String body;

  /// Куда вести по кнопке действия (`kind = route`): маршрут В ТЕРМИНАХ
  /// ПРОДУКТА, сервер его не разбирает и не проверяет. Знать маршруты чужого
  /// приложения он не может, а вид «сервер валидирует пути клиента» означал
  /// бы релиз сервера ради нового экрана в приложении.
  String? route;

  /// Произвольный payload к маршруту (JSON-строка). Сервер не интерпретирует.
  String? payloadJson;

  /// Внешняя ссылка для кнопки действия (`kind = link`), обязательна при этом
  /// виде. Отдельным полем, а не через [route]: маршрут разбирает хост, а
  /// ссылку открывает сам SDK, и путать эти два адресата в одном поле значит
  /// отдать внешний URL в навигацию продукта.
  String? url;

  /// Оформление на клиенте: `info` | `warning`. Плановые работы — не то же,
  /// что новость о функции, и человек должен различать их до чтения.
  String severity;

  /// С какого момента показывать. NULL — сразу.
  DateTime? startsAt;

  /// **Срок актуальности из заявки**: после него не показываем ВОВСЕ, даже
  /// тем, кто ещё не видел. Предупреждение о работах, которые уже прошли,
  /// хуже отсутствия предупреждения. NULL — бессрочно.
  DateTime? expiresAt;

  /// Выключатель для оператора: снять объявление, не удаляя (и не потеряв
  /// отметки о просмотре).
  bool enabled;

  /// Кто завёл — для аудита (админский e-mail, как в остальных admin-путях).
  String? createdByEmail;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Announcement]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Announcement copyWith({
    int? id,
    int? tenantId,
    int? productId,
    String? kind,
    String? title,
    String? body,
    String? route,
    String? payloadJson,
    String? url,
    String? severity,
    DateTime? startsAt,
    DateTime? expiresAt,
    bool? enabled,
    String? createdByEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Announcement',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      if (productId != null) 'productId': productId,
      'kind': kind,
      'title': title,
      'body': body,
      if (route != null) 'route': route,
      if (payloadJson != null) 'payloadJson': payloadJson,
      if (url != null) 'url': url,
      'severity': severity,
      if (startsAt != null) 'startsAt': startsAt?.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      'enabled': enabled,
      if (createdByEmail != null) 'createdByEmail': createdByEmail,
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

class _AnnouncementImpl extends Announcement {
  _AnnouncementImpl({
    int? id,
    required int tenantId,
    int? productId,
    String? kind,
    required String title,
    required String body,
    String? route,
    String? payloadJson,
    String? url,
    String? severity,
    DateTime? startsAt,
    DateTime? expiresAt,
    bool? enabled,
    String? createdByEmail,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         productId: productId,
         kind: kind,
         title: title,
         body: body,
         route: route,
         payloadJson: payloadJson,
         url: url,
         severity: severity,
         startsAt: startsAt,
         expiresAt: expiresAt,
         enabled: enabled,
         createdByEmail: createdByEmail,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Announcement]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Announcement copyWith({
    Object? id = _Undefined,
    int? tenantId,
    Object? productId = _Undefined,
    String? kind,
    String? title,
    String? body,
    Object? route = _Undefined,
    Object? payloadJson = _Undefined,
    Object? url = _Undefined,
    String? severity,
    Object? startsAt = _Undefined,
    Object? expiresAt = _Undefined,
    bool? enabled,
    Object? createdByEmail = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Announcement(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      productId: productId is int? ? productId : this.productId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      body: body ?? this.body,
      route: route is String? ? route : this.route,
      payloadJson: payloadJson is String? ? payloadJson : this.payloadJson,
      url: url is String? ? url : this.url,
      severity: severity ?? this.severity,
      startsAt: startsAt is DateTime? ? startsAt : this.startsAt,
      expiresAt: expiresAt is DateTime? ? expiresAt : this.expiresAt,
      enabled: enabled ?? this.enabled,
      createdByEmail: createdByEmail is String?
          ? createdByEmail
          : this.createdByEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
