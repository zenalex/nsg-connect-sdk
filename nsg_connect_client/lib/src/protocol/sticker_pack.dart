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

/// **Набор пользовательских стикеров** (issue #151, заявка #12 из поддержки).
///
/// Просьба звучала как «смайлики», но клавиатура эмодзи закрыта ещё в #85.
/// Предмет заявки — СВОИ картинки, объединённые в наборы.
///
/// Первый шаг намеренно узкий: набор ЛИЧНЫЙ, без расшаривания. Публичные
/// коллекции, обмен наборами и анимация — отдельными шагами; каждый из них
/// тянет свои вопросы (модерация чужих картинок в общей комнате, права,
/// счётчики), и смешивать их с «человек хочет свой стикер» значило бы не
/// сделать ни того, ни другого.
///
/// **Владелец, а не автор.** Поле называется `ownerMessengerUserId`, потому
/// что от него зависят права, а не авторство: набор видит и правит один
/// человек. Когда появится расшаривание, автор и владелец разойдутся, и
/// менять смысл поля будет поздно.
abstract class StickerPack implements _i1.SerializableModel {
  StickerPack._({
    this.id,
    required this.tenantId,
    required this.ownerMessengerUserId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StickerPack({
    int? id,
    required int tenantId,
    required int ownerMessengerUserId,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _StickerPackImpl;

  factory StickerPack.fromJson(Map<String, dynamic> jsonSerialization) {
    return StickerPack(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      ownerMessengerUserId: jsonSerialization['ownerMessengerUserId'] as int,
      name: jsonSerialization['name'] as String,
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

  /// Тенант — жёсткая граница, как везде: набор одного клиента не должен
  /// быть виден другому даже при ошибке в запросе.
  int tenantId;

  int ownerMessengerUserId;

  /// Человеческое имя набора («Рабочие», «Кот»). Пустым не бывает —
  /// проверяется в политике.
  String name;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [StickerPack]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  StickerPack copyWith({
    int? id,
    int? tenantId,
    int? ownerMessengerUserId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StickerPack',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'ownerMessengerUserId': ownerMessengerUserId,
      'name': name,
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

class _StickerPackImpl extends StickerPack {
  _StickerPackImpl({
    int? id,
    required int tenantId,
    required int ownerMessengerUserId,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         ownerMessengerUserId: ownerMessengerUserId,
         name: name,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [StickerPack]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  StickerPack copyWith({
    Object? id = _Undefined,
    int? tenantId,
    int? ownerMessengerUserId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StickerPack(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      ownerMessengerUserId: ownerMessengerUserId ?? this.ownerMessengerUserId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
