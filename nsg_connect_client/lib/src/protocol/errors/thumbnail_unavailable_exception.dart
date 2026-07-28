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

/// У вложения нет и не будет миниатюры.
///
/// Штатный исход, а не поломка: Synapse отвечает 400 «Failed to find any
/// generated thumbnails» либо 404, если превью для этого файла не
/// существует. Так бывает у всего, что не картинка (PDF, документ,
/// произвольный файл), и у картинок, которые Synapse не смог уменьшить.
///
/// Раньше это исключение было нетипизированным и Serverpod отдавал его
/// клиенту как `500 Internal server error`. Клиент переживал (тянул
/// полный файл вместо превью), но в мониторинге каждый PDF в переписке
/// выглядел серверной аварией, а в клиентском логе — красной строкой.
/// Мимо цели в обе стороны: 500 обязан означать «у нас сломалось».
///
/// Поле [reason] несёт то, что сказал сам Synapse (`errcode`/`error`), —
/// иначе причина отказа выясняется только через логи гомсервера.
abstract class ThumbnailUnavailableException
    implements _i1.SerializableException, _i1.SerializableModel {
  ThumbnailUnavailableException._({
    required this.mxcUrl,
    required this.reason,
  });

  factory ThumbnailUnavailableException({
    required String mxcUrl,
    required String reason,
  }) = _ThumbnailUnavailableExceptionImpl;

  factory ThumbnailUnavailableException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ThumbnailUnavailableException(
      mxcUrl: jsonSerialization['mxcUrl'] as String,
      reason: jsonSerialization['reason'] as String,
    );
  }

  /// `mxc://…` вложения, у которого нет превью.
  String mxcUrl;

  /// Ответ Synapse дословно (усечён) — почему превью нет.
  String reason;

  /// Returns a shallow copy of this [ThumbnailUnavailableException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ThumbnailUnavailableException copyWith({
    String? mxcUrl,
    String? reason,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ThumbnailUnavailableException',
      'mxcUrl': mxcUrl,
      'reason': reason,
    };
  }

  @override
  String toString() {
    return 'ThumbnailUnavailableException(mxcUrl: $mxcUrl, reason: $reason)';
  }
}

class _ThumbnailUnavailableExceptionImpl extends ThumbnailUnavailableException {
  _ThumbnailUnavailableExceptionImpl({
    required String mxcUrl,
    required String reason,
  }) : super._(
         mxcUrl: mxcUrl,
         reason: reason,
       );

  /// Returns a shallow copy of this [ThumbnailUnavailableException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ThumbnailUnavailableException copyWith({
    String? mxcUrl,
    String? reason,
  }) {
    return ThumbnailUnavailableException(
      mxcUrl: mxcUrl ?? this.mxcUrl,
      reason: reason ?? this.reason,
    );
  }
}
