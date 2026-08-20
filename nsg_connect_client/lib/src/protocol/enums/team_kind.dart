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

/// **Вид команды** (см. `DESIGN_TEAMS_AND_CONTACT_SHARING.md`, п.4).
///
/// Различие не косметическое — это главный вопрос безопасности всей
/// затеи. Членство в команде делает людей взаимно видимыми, поэтому
/// право кого-то в неё положить равно праву раздавать знакомства.
///
///   * `org` — оргкоманды тенанта: корпоративный справочник
///     («Компания», «Разработка»). Заводит и наполняет ТОЛЬКО админ
///     платформы; сюда включают без спроса, потому что это оргструктура,
///     а не знакомство по инициативе постороннего. Ими же решается
///     бутстрап новичка: завели человека, положили в «Компанию» — он
///     видит коллег, не зная ни одного адреса.
///
///   * `private` — свои команды пользователя. Создать может любой, но
///     добавлять разрешено только тех, кого добавляющий УЖЕ знает: иначе
///     ограничение поиска по email обходится в один клик — создал
///     команду, вписал кого хотел, получил их в списке.
///
/// На этапе 2 реализован только `org`; значение `private` заведено
/// сразу, чтобы этап 3 не потребовал миграции таблицы.
enum TeamKind implements _i1.SerializableModel {
  org,
  private;

  static TeamKind fromJson(String name) {
    switch (name) {
      case 'org':
        return TeamKind.org;
      case 'private':
        return TeamKind.private;
      default:
        throw ArgumentError('Value "$name" cannot be converted to "TeamKind"');
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
