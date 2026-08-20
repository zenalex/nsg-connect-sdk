/// **Карточка человека, которой поделились** (`nsg.contact_card`).
///
/// Этап 1 из `DESIGN_TEAMS_AND_CONTACT_SHARING`: людей не найти, не зная
/// email, поэтому контакт передают сообщением — получатель добавляет его
/// нажатием, без диктовки адреса.
///
/// Содержимое собирает СЕРВЕР (`SharedContactService`), клиент только
/// разбирает: имя в карточке обязано быть правдой, иначе ей нельзя верить,
/// а верить ей — весь смысл.
///
/// Имя и аватар — снимок на момент отправки. Человек мог с тех пор
/// переименоваться; тянуть свежий профиль по id из старого сообщения
/// нельзя — это дало бы способ читать чужие профили перебором.
class SharedContactData {
  const SharedContactData({
    required this.messengerUserId,
    this.displayName,
    this.avatarUrl,
  });

  final int messengerUserId;
  final String? displayName;
  final String? avatarUrl;

  /// Ключ custom-поля в сыром Matrix-content-е. Тот же, что на сервере.
  static const String contentKey = 'nsg.contact_card';

  /// msgType сообщения-карточки.
  static const String msgType = 'nsg.contact_card';

  /// Разобрать карточку из сырого content-а. `null` — поля нет, оно не
  /// object, или в нём нет пригодного id.
  ///
  /// Толерантно к мусору: сообщение с битой карточкой должно показаться
  /// обычным текстом (у него есть фолбэк-`body`), а не уронить ленту.
  static SharedContactData? tryParse(Map<String, dynamic>? content) {
    final raw = content?[contentKey];
    if (raw is! Map) return null;
    final id = raw['messengerUserId'];
    if (id is! int || id <= 0) return null;
    final name = raw['displayName'];
    final avatar = raw['avatarUrl'];
    return SharedContactData(
      messengerUserId: id,
      displayName: name is String && name.isNotEmpty ? name : null,
      avatarUrl: avatar is String && avatar.isNotEmpty ? avatar : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SharedContactData &&
      other.messengerUserId == messengerUserId &&
      other.displayName == displayName &&
      other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(messengerUserId, displayName, avatarUrl);
}

/// **Список людей, которым поделились** (`nsg.contact_list`) — «поделиться
/// меткой».
///
/// Та же карточка, только пачкой: получатель добавляет всех разом или
/// выборочно. Сервер отдаёт только тех, кем делиться можно, и обрезает
/// список потолком — клиент рисует то, что реально пришло.
class SharedContactListData {
  const SharedContactListData({required this.contacts, this.label});

  /// Название метки отправителя. Метка личная, поэтому это подсказка
  /// «откуда список», а не общая сущность.
  final String? label;

  final List<SharedContactData> contacts;

  static const String contentKey = 'nsg.contact_list';
  static const String msgType = 'nsg.contact_list';

  /// Разобрать список. `null` — поля нет, оно не object, или в нём не
  /// осталось ни одной пригодной карточки (пустой список рисовать нечем,
  /// а фолбэк-`body` у сообщения есть).
  static SharedContactListData? tryParse(Map<String, dynamic>? content) {
    final raw = content?[contentKey];
    if (raw is! Map) return null;
    final rawContacts = raw['contacts'];
    if (rawContacts is! List) return null;
    final contacts = <SharedContactData>[];
    for (final c in rawContacts) {
      // Каждую карточку разбираем тем же кодом, что одиночную: битая
      // выпадает, остальные остаются — одно кривое имя не должно
      // обнулять весь список.
      final parsed = SharedContactData.tryParse({
        SharedContactData.contentKey: c,
      });
      if (parsed != null) contacts.add(parsed);
    }
    if (contacts.isEmpty) return null;
    final label = raw['label'];
    return SharedContactListData(
      contacts: contacts,
      label: label is String && label.isNotEmpty ? label : null,
    );
  }
}
