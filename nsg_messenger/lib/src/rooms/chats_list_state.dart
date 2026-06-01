import 'package:nsg_connect_client/nsg_connect_client.dart';

/// Состояние [ChatsListController]. Sealed-style (Dart 3 sealed).
/// UI делает `switch` по типу для рендеринга нужного состояния.
@immutable
sealed class ChatsListState {
  const ChatsListState();
}

/// Первая загрузка, ничего ещё не было.
class ChatsListLoading extends ChatsListState {
  const ChatsListLoading();
}

/// Загруженный список. `refreshing == true` означает, что в фоне идёт
/// повторный запрос (на realtime-event или manual refresh) — UI рендерит
/// текущий [rooms] (без flicker), может показать subtle indicator.
/// **Закрывает ревью 8985cce #3** (placeholder показывал spinner на
/// каждом event; здесь — `lastKnown` сохраняется в самом state-е).
class ChatsListReady extends ChatsListState {
  final List<RoomSummary> rooms;
  final bool refreshing;
  const ChatsListReady({required this.rooms, this.refreshing = false});

  ChatsListReady copyWith({List<RoomSummary>? rooms, bool? refreshing}) =>
      ChatsListReady(
        rooms: rooms ?? this.rooms,
        refreshing: refreshing ?? this.refreshing,
      );
}

/// Ошибка получения списка. Если список ранее был получен — он сохранён
/// в [lastKnown]; UI рендерит его + error banner (UX «онлайн потеряли,
/// показываем кэш»). Если ошибка на первом запросе (нет lastKnown) —
/// UI показывает retry-screen.
class ChatsListError extends ChatsListState {
  final Object error;
  final List<RoomSummary>? lastKnown;
  const ChatsListError({required this.error, this.lastKnown});
}
