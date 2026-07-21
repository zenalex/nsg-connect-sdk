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

/// **TASK38**: per-tenant конфиг интеграции с внешним таск-трекером
/// («create task from message»). Для MVP единственный adapterType —
/// `generic_webhook`: сервер POST-ит сообщение на `url` с HMAC-подписью,
/// внешняя система создаёт задачу в любом трекере и возвращает {id, url}.
///
/// Резолв конфига при создании задачи: сначала точное (tenantId, productId),
/// иначе tenant-wide (tenantId, productId==null). Unique-индекс
/// (tenantId, productId) гарантирует один enabled-конфиг на пару.
abstract class TaskManagerConfig implements _i1.SerializableModel {
  TaskManagerConfig._({
    this.id,
    required this.tenantId,
    this.productId,
    required this.adapterType,
    required this.url,
    required this.secret,
    bool? enabled,
    required this.createdAt,
  }) : enabled = enabled ?? true;

  factory TaskManagerConfig({
    int? id,
    required int tenantId,
    int? productId,
    required String adapterType,
    required String url,
    required String secret,
    bool? enabled,
    required DateTime createdAt,
  }) = _TaskManagerConfigImpl;

  factory TaskManagerConfig.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaskManagerConfig(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int?,
      adapterType: jsonSerialization['adapterType'] as String,
      url: jsonSerialization['url'] as String,
      secret: jsonSerialization['secret'] as String,
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на Tenant. Cascade-delete: конфиг удаляется вместе с tenant-ом.
  int tenantId;

  /// NULL = tenant-wide конфиг (любой продукт). Иначе — только этот
  /// продукт. SetNull: при удалении продукта конфиг становится tenant-wide.
  int? productId;

  /// Тип адаптера. MVP — только `generic_webhook`.
  String adapterType;

  /// Целевой HTTPS-endpoint интеграции. Валидируется SSRF-гардом
  /// (WebhookUrlValidator) на upsert и повторно перед каждым POST-ом.
  String url;

  /// Секрет для HMAC-SHA256 подписи тела (заголовок X-Task-Signature).
  String secret;

  bool enabled;

  DateTime createdAt;

  /// Returns a shallow copy of this [TaskManagerConfig]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TaskManagerConfig copyWith({
    int? id,
    int? tenantId,
    int? productId,
    String? adapterType,
    String? url,
    String? secret,
    bool? enabled,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TaskManagerConfig',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      if (productId != null) 'productId': productId,
      'adapterType': adapterType,
      'url': url,
      'secret': secret,
      'enabled': enabled,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaskManagerConfigImpl extends TaskManagerConfig {
  _TaskManagerConfigImpl({
    int? id,
    required int tenantId,
    int? productId,
    required String adapterType,
    required String url,
    required String secret,
    bool? enabled,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         productId: productId,
         adapterType: adapterType,
         url: url,
         secret: secret,
         enabled: enabled,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [TaskManagerConfig]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TaskManagerConfig copyWith({
    Object? id = _Undefined,
    int? tenantId,
    Object? productId = _Undefined,
    String? adapterType,
    String? url,
    String? secret,
    bool? enabled,
    DateTime? createdAt,
  }) {
    return TaskManagerConfig(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      productId: productId is int? ? productId : this.productId,
      adapterType: adapterType ?? this.adapterType,
      url: url ?? this.url,
      secret: secret ?? this.secret,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
