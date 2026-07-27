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

/// **TASK77 итер.2 (privacy mode)**: бот в режиме `read_addressed` попросил
/// то, что этот режим не отдаёт.
///
/// Не путать с [BotCapabilityException]: та про ДЕЙСТВИЯ (нет гранта /
/// выключен), эта — про ЧТЕНИЕ. Режим `read_addressed` означает «боту видны
/// только обращения к нему», поэтому запросы, которые по своей природе
/// требуют доступа ко всей истории, отклоняются, а не молча урезаются:
/// молчаливо усечённый ответ автор бота отладить не смог бы (пришли пустые
/// байты — сеть? права? режим?).
///
/// Сейчас единственный источник — `downloadAttachment` /
/// `downloadAttachmentThumbnail` без координат сообщения-носителя
/// (`roomId` + `messageEventId`): по одному `mxcUrl` сервер не может
/// доказать, что вложение принадлежит адресованному боту сообщению.
/// Ботам в `read_all` и людям метод, как и прежде, не требует координат.
///
/// Поля `operation` (какой метод отказал) и `hint` (что сделать) — чтобы
/// отказ читался в логе бота без похода в исходники платформы.
abstract class BotReadRestrictedException
    implements _i1.SerializableException, _i1.SerializableModel {
  BotReadRestrictedException._({
    required this.operation,
    required this.hint,
  });

  factory BotReadRestrictedException({
    required String operation,
    required String hint,
  }) = _BotReadRestrictedExceptionImpl;

  factory BotReadRestrictedException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BotReadRestrictedException(
      operation: jsonSerialization['operation'] as String,
      hint: jsonSerialization['hint'] as String,
    );
  }

  /// Имя отклонённого метода, напр. `downloadAttachment`.
  String operation;

  /// Что делать: какие аргументы добавить либо какой режим нужен.
  String hint;

  /// Returns a shallow copy of this [BotReadRestrictedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BotReadRestrictedException copyWith({
    String? operation,
    String? hint,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BotReadRestrictedException',
      'operation': operation,
      'hint': hint,
    };
  }

  @override
  String toString() {
    return 'BotReadRestrictedException(operation: $operation, hint: $hint)';
  }
}

class _BotReadRestrictedExceptionImpl extends BotReadRestrictedException {
  _BotReadRestrictedExceptionImpl({
    required String operation,
    required String hint,
  }) : super._(
         operation: operation,
         hint: hint,
       );

  /// Returns a shallow copy of this [BotReadRestrictedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BotReadRestrictedException copyWith({
    String? operation,
    String? hint,
  }) {
    return BotReadRestrictedException(
      operation: operation ?? this.operation,
      hint: hint ?? this.hint,
    );
  }
}
