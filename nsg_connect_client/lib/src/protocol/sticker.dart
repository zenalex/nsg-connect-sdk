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

/// **Один стикер внутри набора** (issue #151).
///
/// Картинка кладётся тем же путём, что и вложения (`AttachmentService`):
/// S3, если он настроен, иначе Matrix media. Отдельного хранилища заводить
/// не стали — стикер это та же картинка, только маленькая и с именем.
///
/// **Почему alias, а не только картинка.** Человек хочет вставлять стикер
/// из клавиатуры и по имени (`:shrug:`), как это делают везде. Имя
/// уникально В ПРЕДЕЛАХ НАБОРА, а не глобально: два набора с `:cat:` —
/// нормально, они и выбираются по одному.
abstract class Sticker implements _i1.SerializableModel {
  Sticker._({
    this.id,
    required this.packId,
    required this.mxcUrl,
    required this.mimeType,
    required this.sizeBytes,
    this.width,
    this.height,
    required this.alias,
    required this.position,
    required this.createdAt,
  });

  factory Sticker({
    int? id,
    required int packId,
    required String mxcUrl,
    required String mimeType,
    required int sizeBytes,
    int? width,
    int? height,
    required String alias,
    required int position,
    required DateTime createdAt,
  }) = _StickerImpl;

  factory Sticker.fromJson(Map<String, dynamic> jsonSerialization) {
    return Sticker(
      id: jsonSerialization['id'] as int?,
      packId: jsonSerialization['packId'] as int,
      mxcUrl: jsonSerialization['mxcUrl'] as String,
      mimeType: jsonSerialization['mimeType'] as String,
      sizeBytes: jsonSerialization['sizeBytes'] as int,
      width: jsonSerialization['width'] as int?,
      height: jsonSerialization['height'] as int?,
      alias: jsonSerialization['alias'] as String,
      position: jsonSerialization['position'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int packId;

  /// Ссылка на картинку в media (mxc://…). Тот же вид, что у вложений, —
  /// значит и раздача, и кэш клиента работают без нового кода.
  String mxcUrl;

  String mimeType;

  int sizeBytes;

  /// Размеры нужны ленте, чтобы не прыгать при загрузке. `null` — сервер
  /// не смог их определить; клиент рисует по своему потолку.
  int? width;

  int? height;

  /// Короткое имя для вставки текстом: строчные латинские, цифры и
  /// подчёркивание (см. политику). Хранится БЕЗ двоеточий.
  String alias;

  /// Порядок в наборе. Целое, а не позиция в списке: вставка в середину не
  /// должна переписывать все строки.
  int position;

  DateTime createdAt;

  /// Returns a shallow copy of this [Sticker]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Sticker copyWith({
    int? id,
    int? packId,
    String? mxcUrl,
    String? mimeType,
    int? sizeBytes,
    int? width,
    int? height,
    String? alias,
    int? position,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Sticker',
      if (id != null) 'id': id,
      'packId': packId,
      'mxcUrl': mxcUrl,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      'alias': alias,
      'position': position,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StickerImpl extends Sticker {
  _StickerImpl({
    int? id,
    required int packId,
    required String mxcUrl,
    required String mimeType,
    required int sizeBytes,
    int? width,
    int? height,
    required String alias,
    required int position,
    required DateTime createdAt,
  }) : super._(
         id: id,
         packId: packId,
         mxcUrl: mxcUrl,
         mimeType: mimeType,
         sizeBytes: sizeBytes,
         width: width,
         height: height,
         alias: alias,
         position: position,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Sticker]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Sticker copyWith({
    Object? id = _Undefined,
    int? packId,
    String? mxcUrl,
    String? mimeType,
    int? sizeBytes,
    Object? width = _Undefined,
    Object? height = _Undefined,
    String? alias,
    int? position,
    DateTime? createdAt,
  }) {
    return Sticker(
      id: id is int? ? id : this.id,
      packId: packId ?? this.packId,
      mxcUrl: mxcUrl ?? this.mxcUrl,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width is int? ? width : this.width,
      height: height is int? ? height : this.height,
      alias: alias ?? this.alias,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
