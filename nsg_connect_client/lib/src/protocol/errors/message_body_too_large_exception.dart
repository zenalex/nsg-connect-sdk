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

/// Анти-abuse лимит длины body одного сообщения. Telegram-style
/// лимит 4096 символов (см. `kMessageBodyMaxChars` константа в
/// endpoint-е). Превышение → этот typed exception.
///
/// Зачем явный лимит:
///   * Synapse сам ограничивает Matrix event до ~64KB, но это
///     обрабатывается на их стороне как HTTP 500 / `M_TOO_LARGE` без
///     понятной семантики для клиента;
///   * клиентский UI должен показывать counter заранее (не дать
///     юзеру нажать send и получить мусорную ошибку);
///   * сервер всё равно валидирует — anti-abuse и protection от
///     malformed клиентов.
///
/// Применяется в:
///   * `messengerEndpoint.sendMessage` (включая editMessage путь
///     через replace event).
///
/// UI SDK: показывает snackbar «Сообщение слишком длинное (max
/// N символов)» — поле в `actualLength` / `maxLength` позволяет
/// собрать сообщение клиенту.
abstract class MessageBodyTooLargeException
    implements _i1.SerializableException, _i1.SerializableModel {
  MessageBodyTooLargeException._({
    required this.actualLength,
    required this.maxLength,
  });

  factory MessageBodyTooLargeException({
    required int actualLength,
    required int maxLength,
  }) = _MessageBodyTooLargeExceptionImpl;

  factory MessageBodyTooLargeException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MessageBodyTooLargeException(
      actualLength: jsonSerialization['actualLength'] as int,
      maxLength: jsonSerialization['maxLength'] as int,
    );
  }

  int actualLength;

  int maxLength;

  /// Returns a shallow copy of this [MessageBodyTooLargeException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MessageBodyTooLargeException copyWith({
    int? actualLength,
    int? maxLength,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MessageBodyTooLargeException',
      'actualLength': actualLength,
      'maxLength': maxLength,
    };
  }

  @override
  String toString() {
    return 'MessageBodyTooLargeException(actualLength: $actualLength, maxLength: $maxLength)';
  }
}

class _MessageBodyTooLargeExceptionImpl extends MessageBodyTooLargeException {
  _MessageBodyTooLargeExceptionImpl({
    required int actualLength,
    required int maxLength,
  }) : super._(
         actualLength: actualLength,
         maxLength: maxLength,
       );

  /// Returns a shallow copy of this [MessageBodyTooLargeException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MessageBodyTooLargeException copyWith({
    int? actualLength,
    int? maxLength,
  }) {
    return MessageBodyTooLargeException(
      actualLength: actualLength ?? this.actualLength,
      maxLength: maxLength ?? this.maxLength,
    );
  }
}
