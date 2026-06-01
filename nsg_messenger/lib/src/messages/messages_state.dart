import 'package:flutter/foundation.dart';

import 'chat_message.dart';

/// State machine для [MessagesController] (TASK15).
///
/// Тот же `lastKnown` pattern что в `ChatsListController` (TASK14):
/// Error содержит ссылку на последний успешный Ready, чтобы UI мог
/// показать stale data + error banner при network failure.
@immutable
sealed class MessagesState {
  const MessagesState();
}

/// Первая загрузка (init) ещё не завершилась.
class MessagesLoading extends MessagesState {
  const MessagesLoading();
}

/// Готовое состояние со списком сообщений.
class MessagesReady extends MessagesState {
  const MessagesReady({
    required this.messages,
    required this.hasMore,
    required this.paginating,
  });

  /// Список сообщений в DESC-порядке (newest at index 0). Pending
  /// optimistic bubbles вставляются на index 0; промоут pending → sent
  /// сохраняет позицию (replace-in-place).
  final List<ChatMessage> messages;

  /// Есть ли страница старее текущей самой старой? `false` — история
  /// прочитана до начала комнаты, `loadMore()` no-op.
  final bool hasMore;

  /// True во время `loadMore()`. UI показывает «загружаю историю…».
  final bool paginating;

  MessagesReady copyWith({
    List<ChatMessage>? messages,
    bool? hasMore,
    bool? paginating,
  }) => MessagesReady(
    messages: messages ?? this.messages,
    hasMore: hasMore ?? this.hasMore,
    paginating: paginating ?? this.paginating,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessagesReady &&
        listEquals(other.messages, messages) &&
        other.hasMore == hasMore &&
        other.paginating == paginating;
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(messages), hasMore, paginating);
}

/// Ошибка любого RPC (init / loadMore / sendMessage). [lastKnown] —
/// последний успешный `Ready`, если был; UI рендерит messages из него
/// + banner ошибки.
class MessagesError extends MessagesState {
  const MessagesError({required this.error, this.lastKnown});

  final Object error;
  final MessagesReady? lastKnown;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessagesError &&
        other.error == error &&
        other.lastKnown == lastKnown;
  }

  @override
  int get hashCode => Object.hash(error, lastKnown);
}
