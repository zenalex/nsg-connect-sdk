import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/screens/people_filter.dart';

/// **Отбор списка людей** — §6 `DESIGN_TEAMS_AND_CONTACT_SHARING`
/// (фильтр по командам рядом с фильтром по меткам).
///
/// Экран «Люди» ходит в рантайм и тестами не покрывается, поэтому само
/// правило отбора вынесено функцией: иначе оно осталось бы непроверяемым.
void main() {
  RoomParticipant p(int id, String name, {String? username}) => RoomParticipant(
    messengerUserId: id,
    matrixUserId: '@u$id:l',
    displayName: name,
    username: username,
    role: RoomMemberRole.member,
  );

  final anya = p(1, 'Аня', username: 'anya');
  final borya = p(2, 'Боря');
  final vera = p(3, 'Вера');
  final all = [anya, borya, vera];
  final labels = {
    1: {10}, // Аня — метка «Работа»
    2: {10}, // Боря — «Работа»
  };

  test('без фильтра — весь список', () {
    expect(
      applyPeopleFilter(
        contacts: all,
        filter: const PeopleFilter.all(),
        labelsByContact: labels,
      ),
      all,
    );
  });

  test('метка отбирает только помеченных', () {
    final rows = applyPeopleFilter(
      contacts: all,
      filter: const PeopleFilter.label(10),
      labelsByContact: labels,
    );
    expect(rows.map((c) => c.messengerUserId), [1, 2]);
  });

  test('команда отбирает по составу', () {
    // Ради этого фильтр и заводился: «покажи мне людей проекта».
    final rows = applyPeopleFilter(
      contacts: all,
      filter: const PeopleFilter.team(7),
      labelsByContact: labels,
      teamMembers: {2, 3},
    );
    expect(rows.map((c) => c.messengerUserId), [2, 3]);
  });

  test('состав ещё не загружен — показываем всех, а не пустоту', () {
    // Мигнуть пустым экраном на время запроса хуже, чем показать лишнее
    // на долю секунды: пустой список читается как «никого нет».
    final rows = applyPeopleFilter(
      contacts: all,
      filter: const PeopleFilter.team(7),
      labelsByContact: labels,
    );
    expect(rows, all);
  });

  test('в команде есть тот, кого нет в знакомых, — лишнего не рисуем', () {
    // Состав команды может содержать людей, которых нет в списке (ушли,
    // заблокировали). Фильтр отбирает из НАЛИЧНЫХ строк, а не дорисовывает.
    final rows = applyPeopleFilter(
      contacts: all,
      filter: const PeopleFilter.team(7),
      labelsByContact: labels,
      teamMembers: {2, 99},
    );
    expect(rows.map((c) => c.messengerUserId), [2]);
  });

  test('поиск накладывается поверх фильтра, а не вместо него', () {
    // Запрос нарочно подходит и тому, кого фильтр отсёк: если поиск
    // считать по исходному списку, из-под фильтра вылезет посторонний.
    final rows = applyPeopleFilter(
      contacts: all,
      filter: const PeopleFilter.team(7),
      labelsByContact: labels,
      teamMembers: {2},
      query: 'я',
    );
    expect(rows.map((c) => c.messengerUserId), [2]);
  });

  test('поиск находит и по @нику', () {
    final rows = applyPeopleFilter(
      contacts: all,
      filter: const PeopleFilter.all(),
      labelsByContact: labels,
      query: 'ANY',
    );
    expect(rows.map((c) => c.messengerUserId), [1]);
  });

  group('заглушка под пустым списком', () {
    test('без поиска — показываем «пока нет контактов»', () {
      expect(showsPeopleEmptyPlaceholder(query: ''), isTrue);
    });

    test('идёт поиск — молчим, за нас говорит шапка', () {
      // Иначе человек видел разом «Ничего не найдено» (шапка) и «Пока нет
      // контактов» (заглушка) — второе враньё: контакты есть, не совпал
      // запрос.
      expect(showsPeopleEmptyPlaceholder(query: 'Аня'), isFalse);
    });

    test('пробелы — это не поиск', () {
      // Шапка на пробелах ничего не говорит (отбор их обрезает), значит
      // заглушке молчать нельзя: экран остался бы совсем пустым.
      expect(showsPeopleEmptyPlaceholder(query: '   '), isTrue);
    });
  });
}
