import 'package:nsg_connect_client/nsg_connect_client.dart';

/// **TASK43**: состояние экрана «Команда поддержки».
@immutable
sealed class SupportTeamState {
  const SupportTeamState();
}

/// Первичная загрузка (getSupportTeam ещё не вернулся).
class SupportTeamLoading extends SupportTeamState {
  const SupportTeamLoading();
}

/// Команда загружена. `busy` — идёт add/remove (UI блокирует кнопки).
class SupportTeamReady extends SupportTeamState {
  const SupportTeamReady({required this.view, this.busy = false});

  final SupportTeamView view;
  final bool busy;

  SupportTeamReady copyWith({SupportTeamView? view, bool? busy}) =>
      SupportTeamReady(view: view ?? this.view, busy: busy ?? this.busy);
}

/// Экран недоступен — caller не участник команды (getSupportTeam бросил
/// [NotSupportTeamMemberException]) ИЛИ иная ошибка загрузки. SDK по
/// [unavailable] решает: скрыть экран (не участник) vs показать retry.
class SupportTeamUnavailable extends SupportTeamState {
  const SupportTeamUnavailable({
    required this.error,
    required this.unavailable,
  });

  /// Причина.
  final Object error;

  /// `true` — caller не участник (гейт): host-app скрывает вход в экран.
  /// `false` — временная ошибка (сеть и т.п.): можно показать retry.
  final bool unavailable;
}
