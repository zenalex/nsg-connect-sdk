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

/// **TASK91 (issue #65)**: объявление в том виде, в каком его получает
/// клиент. Транзиентный DTO (без `table:`).
///
/// Отдельно от [Announcement] потому, что наружу нельзя отдавать ни
/// `enabled`, ни окна показа, ни автора: клиенту решать нечего — сервер уже
/// решил, что это объявление ему сейчас показывать. Отдавать поля «на всякий
/// случай» — верный способ получить второй, расходящийся фильтр на клиенте.
abstract class AnnouncementView implements _i1.SerializableModel {
  AnnouncementView._({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.route,
    this.payloadJson,
    this.url,
    required this.severity,
    this.expiresAt,
    required this.createdAt,
  });

  factory AnnouncementView({
    required int id,
    required String kind,
    required String title,
    required String body,
    String? route,
    String? payloadJson,
    String? url,
    required String severity,
    DateTime? expiresAt,
    required DateTime createdAt,
  }) = _AnnouncementViewImpl;

  factory AnnouncementView.fromJson(Map<String, dynamic> jsonSerialization) {
    return AnnouncementView(
      id: jsonSerialization['id'] as int,
      kind: jsonSerialization['kind'] as String,
      title: jsonSerialization['title'] as String,
      body: jsonSerialization['body'] as String,
      route: jsonSerialization['route'] as String?,
      payloadJson: jsonSerialization['payloadJson'] as String?,
      url: jsonSerialization['url'] as String?,
      severity: jsonSerialization['severity'] as String,
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int id;

  /// `text` | `route` | `link`. Незнакомый вид клиент показывает как `text` —
  /// см. AnnouncementService.
  String kind;

  String title;

  /// Markdown (тот же subset, что в пузырях чата) — у всех видов.
  String body;

  /// Только для `route`: маршрут и payload в терминах ПРОДУКТА. Куда вести —
  /// знает хост-приложение, SDK лишь передаёт строку.
  String? route;

  String? payloadJson;

  /// Только для `link`: внешняя ссылка. В отличие от [route] её открывает сам
  /// SDK — внешний адрес не зависит от того, какой продукт его показывает.
  String? url;

  /// `info` | `warning` — оформление.
  String severity;

  /// Когда объявление перестанет быть актуальным. Клиенту нужно, чтобы не
  /// показывать протухшее, если экран провисел открытым дольше срока.
  DateTime? expiresAt;

  DateTime createdAt;

  /// Returns a shallow copy of this [AnnouncementView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AnnouncementView copyWith({
    int? id,
    String? kind,
    String? title,
    String? body,
    String? route,
    String? payloadJson,
    String? url,
    String? severity,
    DateTime? expiresAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AnnouncementView',
      'id': id,
      'kind': kind,
      'title': title,
      'body': body,
      if (route != null) 'route': route,
      if (payloadJson != null) 'payloadJson': payloadJson,
      if (url != null) 'url': url,
      'severity': severity,
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AnnouncementViewImpl extends AnnouncementView {
  _AnnouncementViewImpl({
    required int id,
    required String kind,
    required String title,
    required String body,
    String? route,
    String? payloadJson,
    String? url,
    required String severity,
    DateTime? expiresAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         kind: kind,
         title: title,
         body: body,
         route: route,
         payloadJson: payloadJson,
         url: url,
         severity: severity,
         expiresAt: expiresAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [AnnouncementView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AnnouncementView copyWith({
    int? id,
    String? kind,
    String? title,
    String? body,
    Object? route = _Undefined,
    Object? payloadJson = _Undefined,
    Object? url = _Undefined,
    String? severity,
    Object? expiresAt = _Undefined,
    DateTime? createdAt,
  }) {
    return AnnouncementView(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      body: body ?? this.body,
      route: route is String? ? route : this.route,
      payloadJson: payloadJson is String? ? payloadJson : this.payloadJson,
      url: url is String? ? url : this.url,
      severity: severity ?? this.severity,
      expiresAt: expiresAt is DateTime? ? expiresAt : this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
