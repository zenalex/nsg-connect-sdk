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

/// **TASK91 (issue #65)**: кому адресовано объявление — один адресат, одна
/// строка.
///
/// **Зачем понадобилось.** До этой таблицы адресации у объявления не было
/// вовсе: отбор шёл по тенанту, продукту и окнам показа, и объявление видел
/// КАЖДЫЙ пользователь продукта. Титану нужны две вещи, которых так не
/// получить: проверить рассылку на одном своём телефоне до того, как её
/// увидят клиенты, и адресная кампания по списку людей. Push-половина той же
/// кампании (`productNotification/send`) адресоваться умеет — объявление нет,
/// и связка распадалась ровно посередине.
///
/// **Отдельной таблицей, а не массивом в поле объявления.** Список бывает в
/// сотни адресатов (потолок — 500, как у рассылки push), и в поле он означал
/// бы разбор массива на каждый показ. Здесь отбор «адресовано ли это мне»
/// делает индекс, а не Dart.
///
/// **Храним ВНЕШНИЙ идентификатор, а не наш `messengerUserId`** — и это
/// главное решение:
///
///   * это словарь продукта. Те же строки, что у `productNotification/send`:
///     обе половины кампании адресуются одним списком, и разъехаться им
///     нечем. Переведи мы список во внутренние id при заведении — половины
///     стали бы адресоваться по-разному, а заметно это было бы только по
///     жалобе «push пришёл, а объявления нет»;
///   * адресат может быть нам ещё НЕ ИЗВЕСТЕН. Объявление, в отличие от
///     push, ждёт: человек, поставивший приложение через неделю, увидит его
///     при первом входе. Внутренний id на момент заведения ещё не
///     существует, и запись по нему потеряла бы этого человека навсегда;
///   * у одного внешнего идентификатора бывает НЕСКОЛЬКО `messengerUser`
///     (разные провайдеры входа — см. IdentityMapping). Внешний id
///     покрывает их все, в том числе появившиеся позже.
///
/// **Тенанта здесь нет намеренно.** Внешние идентификаторы уникальны внутри
/// тенанта, и объявление уже знает свой; отбор всегда начинается с тенанта
/// объявления, так что совпадение строки `12345` у другой компании ни к чему
/// привести не может. Второй столбец с тем же смыслом означал бы два места,
/// где эту связь можно рассинхронизировать.
abstract class AnnouncementRecipient implements _i1.SerializableModel {
  AnnouncementRecipient._({
    this.id,
    required this.announcementId,
    required this.externalUserId,
  });

  factory AnnouncementRecipient({
    int? id,
    required int announcementId,
    required String externalUserId,
  }) = _AnnouncementRecipientImpl;

  factory AnnouncementRecipient.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AnnouncementRecipient(
      id: jsonSerialization['id'] as int?,
      announcementId: jsonSerialization['announcementId'] as int,
      externalUserId: jsonSerialization['externalUserId'] as String,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Cascade: объявления мы не удаляем (только выключаем), но снос тенанта
  /// или продукта не должен оставлять висячие адресации.
  int announcementId;

  /// Идентификатор человека В СИСТЕМЕ ПРОДУКТА — тот же, что в
  /// `productNotification/send`.
  String externalUserId;

  /// Returns a shallow copy of this [AnnouncementRecipient]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AnnouncementRecipient copyWith({
    int? id,
    int? announcementId,
    String? externalUserId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AnnouncementRecipient',
      if (id != null) 'id': id,
      'announcementId': announcementId,
      'externalUserId': externalUserId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AnnouncementRecipientImpl extends AnnouncementRecipient {
  _AnnouncementRecipientImpl({
    int? id,
    required int announcementId,
    required String externalUserId,
  }) : super._(
         id: id,
         announcementId: announcementId,
         externalUserId: externalUserId,
       );

  /// Returns a shallow copy of this [AnnouncementRecipient]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AnnouncementRecipient copyWith({
    Object? id = _Undefined,
    int? announcementId,
    String? externalUserId,
  }) {
    return AnnouncementRecipient(
      id: id is int? ? id : this.id,
      announcementId: announcementId ?? this.announcementId,
      externalUserId: externalUserId ?? this.externalUserId,
    );
  }
}
