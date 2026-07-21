import 'package:nsg_connect_client/nsg_connect_client.dart';

/// **TASK57 фаза 1**: состояние экрана «Мои обращения».
@immutable
sealed class MyTicketsState {
  const MyTicketsState();
}

/// Первичная загрузка (listMyTickets ещё не вернулся).
class MyTicketsLoading extends MyTicketsState {
  const MyTicketsLoading();
}

/// Список тикетов загружен (может быть пустым).
class MyTicketsReady extends MyTicketsState {
  const MyTicketsReady({required this.tickets});

  final List<TicketView> tickets;
}

/// Ошибка загрузки — UI показывает retry.
class MyTicketsUnavailable extends MyTicketsState {
  const MyTicketsUnavailable({required this.error});

  final Object error;
}
