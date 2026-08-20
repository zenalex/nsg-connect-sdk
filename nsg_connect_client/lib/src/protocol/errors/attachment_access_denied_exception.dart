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

/// **TASK92**: запрошена ссылка на вложение, к которому у человека нет
/// доступа.
///
/// До TASK92 этот отказ выдавал Matrix: Authenticated Media не отдавала
/// байты тому, кто не состоит в комнате с медиа. У S3-объектов Matrix-а
/// нет, поэтому проверку — а значит и отказ — делаем мы.
///
/// Типизированным, а не `StateError`: нетипизированное исключение
/// Serverpod отдаёт клиенту как `500 Internal server error`, и клиент
/// считает такую ошибку транзиентной — то есть ретраит заведомо
/// невозможный запрос бесконечно (ровно грабли issue #54).
///
/// **Причина не детализируется** намеренно: «нет такого вложения» и «есть,
/// но не для вас» — один и тот же ответ. Иначе перебор по идентификаторам
/// рассказал бы, какие вложения существуют.
abstract class AttachmentAccessDeniedException
    implements _i1.SerializableException, _i1.SerializableModel {
  AttachmentAccessDeniedException._({required this.mxcUrl});

  factory AttachmentAccessDeniedException({required String mxcUrl}) =
      _AttachmentAccessDeniedExceptionImpl;

  factory AttachmentAccessDeniedException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AttachmentAccessDeniedException(
      mxcUrl: jsonSerialization['mxcUrl'] as String,
    );
  }

  /// Идентификатор запрошенного вложения — для лога клиента.
  String mxcUrl;

  /// Returns a shallow copy of this [AttachmentAccessDeniedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AttachmentAccessDeniedException copyWith({String? mxcUrl});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AttachmentAccessDeniedException',
      'mxcUrl': mxcUrl,
    };
  }

  @override
  String toString() {
    return 'AttachmentAccessDeniedException(mxcUrl: $mxcUrl)';
  }
}

class _AttachmentAccessDeniedExceptionImpl
    extends AttachmentAccessDeniedException {
  _AttachmentAccessDeniedExceptionImpl({required String mxcUrl})
    : super._(mxcUrl: mxcUrl);

  /// Returns a shallow copy of this [AttachmentAccessDeniedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AttachmentAccessDeniedException copyWith({String? mxcUrl}) {
    return AttachmentAccessDeniedException(mxcUrl: mxcUrl ?? this.mxcUrl);
  }
}
