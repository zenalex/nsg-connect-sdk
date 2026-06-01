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
import 'messenger_message.dart' as _i2;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i3;

/// Pagination wrapper для `MessengerEndpoint.listMessages` (TASK15).
///
/// Ранее endpoint возвращал `List<MessengerMessage>` напрямую и
/// обрезал pagination tokens — из-за того что на TASK09 SDK ещё не
/// умел подгружать страницы. TASK15 это завершает: SDK
/// `MessagesController.loadMore` использует `nextToken` для запроса
/// следующей backward-страницы.
///
/// **Семантика tokens — Matrix-native** (не свой курсор поверх БД):
/// `nextToken` соответствует Matrix `/messages` response.end (forward
/// в Matrix-терминах, но семантически OLDER message-ы для нашего
/// `dir=b` запроса), `prevToken` — response.start. Возвращаем оба для
/// симметричности; `loadMore` использует `nextToken`.
///
/// Не table — transient DTO.
abstract class MessengerMessageListPage implements _i1.SerializableModel {
  MessengerMessageListPage._({
    required this.messages,
    this.nextToken,
    this.prevToken,
  });

  factory MessengerMessageListPage({
    required List<_i2.MessengerMessage> messages,
    String? nextToken,
    String? prevToken,
  }) = _MessengerMessageListPageImpl;

  factory MessengerMessageListPage.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MessengerMessageListPage(
      messages: _i3.Protocol().deserialize<List<_i2.MessengerMessage>>(
        jsonSerialization['messages'],
      ),
      nextToken: jsonSerialization['nextToken'] as String?,
      prevToken: jsonSerialization['prevToken'] as String?,
    );
  }

  /// Сообщения, упорядоченные DESC по serverTimestamp (newest first
  /// внутри страницы). Matrix `dir=b` гарантирует этот порядок.
  List<_i2.MessengerMessage> messages;

  /// Token для следующего `listMessages(fromToken: nextToken)` —
  /// подгрузит OLDER страницу. `null` когда история закончилась
  /// (Matrix вернул `end == null`).
  String? nextToken;

  /// Token "противоположного" направления (в forward-сторону по
  /// времени). На MVP не используется — realtime stream доставляет
  /// newer events. Оставлен в DTO для симметрии и будущего
  /// offline-replay use-case (TASK24).
  String? prevToken;

  /// Returns a shallow copy of this [MessengerMessageListPage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MessengerMessageListPage copyWith({
    List<_i2.MessengerMessage>? messages,
    String? nextToken,
    String? prevToken,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MessengerMessageListPage',
      'messages': messages.toJson(valueToJson: (v) => v.toJson()),
      if (nextToken != null) 'nextToken': nextToken,
      if (prevToken != null) 'prevToken': prevToken,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MessengerMessageListPageImpl extends MessengerMessageListPage {
  _MessengerMessageListPageImpl({
    required List<_i2.MessengerMessage> messages,
    String? nextToken,
    String? prevToken,
  }) : super._(
         messages: messages,
         nextToken: nextToken,
         prevToken: prevToken,
       );

  /// Returns a shallow copy of this [MessengerMessageListPage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MessengerMessageListPage copyWith({
    List<_i2.MessengerMessage>? messages,
    Object? nextToken = _Undefined,
    Object? prevToken = _Undefined,
  }) {
    return MessengerMessageListPage(
      messages: messages ?? this.messages.map((e0) => e0.copyWith()).toList(),
      nextToken: nextToken is String? ? nextToken : this.nextToken,
      prevToken: prevToken is String? ? prevToken : this.prevToken,
    );
  }
}
