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
import 'sticker_pack.dart' as _i2;
import 'sticker.dart' as _i3;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i4;

/// **issue #151**: набор вместе с содержимым — то, чем открывается пикер.
///
/// Отдельным DTO, а не двумя вызовами: пикер открывают часто, и пять
/// запросов «дай стикеры набора» вместо одного здесь ни к чему.
abstract class StickerPackView implements _i1.SerializableModel {
  StickerPackView._({
    required this.pack,
    required this.stickers,
  });

  factory StickerPackView({
    required _i2.StickerPack pack,
    required List<_i3.Sticker> stickers,
  }) = _StickerPackViewImpl;

  factory StickerPackView.fromJson(Map<String, dynamic> jsonSerialization) {
    return StickerPackView(
      pack: _i4.Protocol().deserialize<_i2.StickerPack>(
        jsonSerialization['pack'],
      ),
      stickers: _i4.Protocol().deserialize<List<_i3.Sticker>>(
        jsonSerialization['stickers'],
      ),
    );
  }

  _i2.StickerPack pack;

  List<_i3.Sticker> stickers;

  /// Returns a shallow copy of this [StickerPackView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  StickerPackView copyWith({
    _i2.StickerPack? pack,
    List<_i3.Sticker>? stickers,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StickerPackView',
      'pack': pack.toJson(),
      'stickers': stickers.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _StickerPackViewImpl extends StickerPackView {
  _StickerPackViewImpl({
    required _i2.StickerPack pack,
    required List<_i3.Sticker> stickers,
  }) : super._(
         pack: pack,
         stickers: stickers,
       );

  /// Returns a shallow copy of this [StickerPackView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  StickerPackView copyWith({
    _i2.StickerPack? pack,
    List<_i3.Sticker>? stickers,
  }) {
    return StickerPackView(
      pack: pack ?? this.pack.copyWith(),
      stickers: stickers ?? this.stickers.map((e0) => e0.copyWith()).toList(),
    );
  }
}
