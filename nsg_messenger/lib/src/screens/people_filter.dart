import 'package:nsg_connect_client/nsg_connect_client.dart';

/// Что сейчас отбирает список людей: ничего, метка или команда.
///
/// Ровно ОДИН активный фильтр, а не пересечение метки с командой. Люди
/// читают чипы как «покажи это», и пустой экран от невидимого пересечения
/// двух отборов выглядит поломкой, а не результатом.
sealed class PeopleFilter {
  const PeopleFilter();
  const factory PeopleFilter.all() = PeopleFilterAll;
  const factory PeopleFilter.label(int labelId) = PeopleFilterLabel;
  const factory PeopleFilter.team(int teamId) = PeopleFilterTeam;
}

class PeopleFilterAll extends PeopleFilter {
  const PeopleFilterAll();
}

class PeopleFilterLabel extends PeopleFilter {
  const PeopleFilterLabel(this.labelId);
  final int labelId;
}

class PeopleFilterTeam extends PeopleFilter {
  const PeopleFilterTeam(this.teamId);
  final int teamId;
}

/// Отбор строк экрана «Люди»: фильтр + поиск по имени/@нику.
///
/// Вынесено из экрана отдельной функцией не ради красоты: экран ходит в
/// рантайм за списками и тестами не покрывается, а отбор — это правило,
/// которое обязано быть проверяемым. §6 `DESIGN_TEAMS_AND_CONTACT_SHARING`
/// (фильтр по командам рядом с фильтром по меткам).
///
/// [teamMembers] — состав команды, если он уже загружен. `null` означает
/// «ещё не знаем»: тогда список не режем, а показываем как есть — мигать
/// пустотой на время запроса хуже, чем показать лишнее на долю секунды.
List<RoomParticipant> applyPeopleFilter({
  required List<RoomParticipant> contacts,
  required PeopleFilter filter,
  required Map<int, Set<int>> labelsByContact,
  Set<int>? teamMembers,
  String query = '',
}) {
  var rows = contacts;
  switch (filter) {
    case PeopleFilterAll():
      break;
    case PeopleFilterLabel(:final labelId):
      rows = [
        for (final c in rows)
          if (labelsByContact[c.messengerUserId]?.contains(labelId) ?? false) c,
      ];
    case PeopleFilterTeam():
      if (teamMembers != null) {
        rows = [
          for (final c in rows)
            if (teamMembers.contains(c.messengerUserId)) c,
        ];
      }
  }
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return rows;
  return [
    for (final c in rows)
      if ((c.displayName ?? '').toLowerCase().contains(q) ||
          (c.username ?? '').toLowerCase().contains(q))
        c,
  ];
}

/// Показывать ли под пустым списком заглушку «пока нет контактов».
///
/// При активном поиске — нет. Контакты есть, просто ни один не подошёл под
/// запрос, и «Пока нет контактов» здесь — враньё; про пустой результат уже
/// сказано в шапке («Ничего не найдено»). Раньше человек видел оба
/// сообщения разом, и они противоречили друг другу.
///
/// Вынесено сюда по той же причине, что и [applyPeopleFilter]: экран ходит
/// в рантайм и тестами не покрывается, а это — правило, а не оформление.
bool showsPeopleEmptyPlaceholder({required String query}) =>
    query.trim().isEmpty;
