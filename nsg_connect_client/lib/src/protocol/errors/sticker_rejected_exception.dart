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

/// **issue #151**: стикер или набор не приняты.
///
/// Типизированным, а не `StateError`: нетипизированное исключение Serverpod
/// отдаёт клиенту как `500`, и клиент считает такую ошибку транзиентной —
/// то есть повторяет заведомо невозможный запрос (грабли issue #54). А
/// «картинка тяжелее 512 КБ» невозможен ровно столько, сколько человек не
/// возьмёт другую картинку.
///
/// **Причина здесь детализируется** — в отличие от отказов доступа. Это не
/// граница безопасности, а подсказка: человек должен понять, что чинить,
/// иначе он будет менять картинку, когда дело в имени.
abstract class StickerRejectedException
    implements _i1.SerializableException, _i1.SerializableModel {
  StickerRejectedException._({
    required this.reason,
    required this.detail,
  });

  factory StickerRejectedException({
    required String reason,
    required String detail,
  }) = _StickerRejectedExceptionImpl;

  factory StickerRejectedException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return StickerRejectedException(
      reason: jsonSerialization['reason'] as String,
      detail: jsonSerialization['detail'] as String,
    );
  }

  /// Машинное имя причины (`tooLarge`, `aliasTaken`, …) — для клиента,
  /// который захочет разветвиться сам.
  String reason;

  /// Готовый человеческий текст: клиент показывает его как есть, чтобы
  /// формулировка не разъехалась между платформами.
  String detail;

  /// Returns a shallow copy of this [StickerRejectedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  StickerRejectedException copyWith({
    String? reason,
    String? detail,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StickerRejectedException',
      'reason': reason,
      'detail': detail,
    };
  }

  @override
  String toString() {
    return 'StickerRejectedException(reason: $reason, detail: $detail)';
  }
}

class _StickerRejectedExceptionImpl extends StickerRejectedException {
  _StickerRejectedExceptionImpl({
    required String reason,
    required String detail,
  }) : super._(
         reason: reason,
         detail: detail,
       );

  /// Returns a shallow copy of this [StickerRejectedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  StickerRejectedException copyWith({
    String? reason,
    String? detail,
  }) {
    return StickerRejectedException(
      reason: reason ?? this.reason,
      detail: detail ?? this.detail,
    );
  }
}
