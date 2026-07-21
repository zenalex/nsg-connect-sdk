import 'package:nsg_connect_client/nsg_connect_client.dart';

/// TASK44 — авто-папки чатов (Telegram-style folders).
///
/// **Фаза 1.5 (folder-as-row):** продуктовая папка рендерится строкой в
/// основном списке чатов (как «Архив» в Telegram), а не табом в полосе.
/// Тап по строке-папке проваливает в drill-in экран со списком чатов
/// только этого продукта. Полоса-табы (`ChatFolderStrip` /
/// `GlassFolderStrip`) удалена.
///
/// Папки вычисляются **клиентски** из уже загруженного списка
/// [RoomSummary] — без новых RPC. Три вида (см. [ChatFolderKind]):
///
///   * `all` — агрегат по всем комнатам (сумма unread / самый свежий чат).
///     Не рендерится как строка; служит для «полоса скрыта при 1 группе».
///   * `product` — одна папка на каждый `productId`, по которому у
///     пользователя есть хотя бы одна комната. Человекочитаемое имя
///     резолвится из `getAvailableProducts` (TASK42), fallback — ключ
///     продукта / «Product N». Рендерится строкой-папкой.
///   * `personal` — комнаты без продукта (`productId == null`): direct-ы,
///     обычные группы. В модели folder-as-row они остаются обычными
///     строками-чатами в корне (не заворачиваются в папку).
///
/// **Обёртка-папка скрыта при одной группе.** Если у пользователя комнаты
/// только одного «происхождения» (например, только один продукт и нет
/// личных), заворачивать чаты в папку смысла нет — список показывается
/// плоско (см. [foldersVisible]).
@immutable
class ChatFolder {
  const ChatFolder({
    required this.kind,
    this.productId,
    this.productKey,
    this.productDisplayName,
    this.productAvatarUrl,
    this.customFolderId,
    this.customName,
    this.roomIds,
    required this.unreadCount,
    required this.roomCount,
    this.lastMessageAt,
    this.lastMessagePreview,
  });

  final ChatFolderKind kind;

  /// **TASK62**: только для [ChatFolderKind.custom] — id серверной папки
  /// (`chat_folders.id`). Нужен для мутаций (rename/delete/add/remove).
  final int? customFolderId;

  /// **TASK62**: только для custom — имя, заданное пользователем.
  final String? customName;

  /// **TASK62**: только для custom — явный набор roomId папки (M2M с
  /// сервера). Для авто-папок null — их membership производный.
  final Set<int>? roomIds;

  /// Только для [ChatFolderKind.product] — `RoomSummary.productId`
  /// этой папки. Одновременно — её стабильный идентификатор выбора.
  final int? productId;

  /// Только для [ChatFolderKind.product] — `Product.externalKey`, если
  /// продукт нашёлся в `getAvailableProducts`; иначе `null`. Используется
  /// как fallback-подпись, когда `displayName` недоступен.
  final String? productKey;

  /// Только для [ChatFolderKind.product] — человекочитаемое имя из
  /// `Product.displayName`. `null`, если продукт не резолвился (комнаты
  /// есть, а `getAvailableProducts` их продукт не вернул / ещё не
  /// загружен) — UI покажет [productKey] или generic-подпись.
  final String? productDisplayName;

  /// Только для [ChatFolderKind.product] — URL аватара продукта, если он
  /// резолвится. `Product` в текущей схеме аватара не несёт, поэтому это
  /// всегда `null` (UI строки-папки показывает иконку-папку как fallback).
  /// Поле оставлено в контракте для будущего product-branding (TASK28).
  final String? productAvatarUrl;

  /// Сумма `unreadCount` по всем комнатам папки. Для бейджа строки-папки.
  final int unreadCount;

  /// Число комнат в папке (для тестов / отладки; UI не обязателен).
  final int roomCount;

  /// **Фаза 1.5:** время последней активности самого свежего чата папки
  /// (max `RoomSummary.lastMessageAt` по комнатам). Используется для
  /// сортировки строки-папки среди обычных чатов и для метки времени.
  /// `null`, если ни у одной комнаты папки нет `lastMessageAt`.
  final DateTime? lastMessageAt;

  /// **Фаза 1.5:** превью последнего сообщения самого свежего чата папки
  /// (`RoomSummary.lastMessagePreview` комнаты с max `lastMessageAt`).
  /// `null`, если у самого свежего чата нет превью / папка пуста.
  final String? lastMessagePreview;

  /// **TASK75**: стабильный ключ агрегатной папки «Поддержка».
  static const String supportSelectionKey = '__support__';

  /// **TASK68**: стабильный ключ агрегатной папки «Избранное» (self-чаты).
  static const String savedSelectionKey = '__saved__';

  /// Стабильный ключ выбора/идентификации папки. `all` / `personal` /
  /// `support` / `saved` — по виду; `product` — по `productId`; `custom` —
  /// по серверному id.
  String get selectionKey => switch (kind) {
    ChatFolderKind.all => '__all__',
    ChatFolderKind.personal => '__personal__',
    ChatFolderKind.support => supportSelectionKey,
    ChatFolderKind.saved => savedSelectionKey,
    ChatFolderKind.product => 'product:$productId',
    ChatFolderKind.custom => 'custom:$customFolderId',
  };

  /// Проходит ли комната фильтр этой папки.
  ///
  ///   * `all` — все комнаты.
  ///   * `personal` — только `productId == null`.
  ///   * `support` (**TASK75**) — только support-комнаты, НЕ «закрытые»
  ///     оператором (`dismissedUntilMessage`).
  ///   * `saved` (**TASK68**) — только self-чаты «Избранного».
  ///   * `product` — комнаты с совпадающим `productId`, КРОМЕ support
  ///     (они живут в агрегатной папке «Поддержка», не в продуктовых).
  ///   * `custom` — только комнаты из явного [roomIds] (TASK62).
  bool matches(RoomSummary room) => switch (kind) {
    ChatFolderKind.all => true,
    // **TASK68**: self-чаты не «личные» — у них своя папка «Избранное».
    // Без этого исключения они дублировались бы в двух местах списка.
    ChatFolderKind.personal => room.productId == null && !isSavedRoom(room),
    ChatFolderKind.support => isSupportInboxRoom(room),
    ChatFolderKind.saved => isSavedRoom(room),
    ChatFolderKind.product =>
      room.productId == productId && room.roomType != RoomType.support,
    ChatFolderKind.custom => roomIds?.contains(room.id) ?? false,
  };

  @override
  bool operator ==(Object other) =>
      other is ChatFolder &&
      other.kind == kind &&
      other.customFolderId == customFolderId &&
      other.customName == customName &&
      other.productId == productId &&
      other.productKey == productKey &&
      other.productDisplayName == productDisplayName &&
      other.productAvatarUrl == productAvatarUrl &&
      other.unreadCount == unreadCount &&
      other.roomCount == roomCount &&
      other.lastMessageAt == lastMessageAt &&
      other.lastMessagePreview == lastMessagePreview;

  @override
  int get hashCode => Object.hash(
    kind,
    customFolderId,
    customName,
    productId,
    productKey,
    productDisplayName,
    productAvatarUrl,
    unreadCount,
    roomCount,
    lastMessageAt,
    lastMessagePreview,
  );

  @override
  String toString() =>
      'ChatFolder($selectionKey, name=$productDisplayName, '
      'unread=$unreadCount, rooms=$roomCount, lastAt=$lastMessageAt)';
}

/// Вид папки. `all`/`personal`/`product`/`support`/`saved` — авто
/// (TASK44/75/68); `custom` — пользовательская server-side папка (TASK62).
enum ChatFolderKind { all, personal, support, saved, product, custom }

/// **TASK68**: комната — раздел «Избранного» (self-чат, единственный
/// участник — сам владелец). Такие комнаты собираются в агрегатную папку
/// «Избранное» и НЕ рендерятся плоскими строками в корне списка (иначе
/// «заметки», «файлообмен» и т.д. забивали бы ленту чатов).
bool isSavedRoom(RoomSummary room) => room.roomType == RoomType.saved;

/// **TASK75**: комната относится к операторскому support-инбоксу — это
/// support-комната, которую текущий оператор ещё НЕ «закрыл до ответа»
/// (`dismissedUntilMessage != true`). «Закрытые» комнаты прячутся из всех
/// списков до нового сообщения заявителя (сервер сбрасывает флаг). Общий
/// предикат для агрегатной папки, root-rows и фильтрации в UI.
bool isSupportInboxRoom(RoomSummary room) =>
    room.roomType == RoomType.support && !(room.dismissedUntilMessage ?? false);

/// **TASK75**: «закрытая» (dismissed) оператором support-комната — скрыта
/// из всех списков до следующего сообщения заявителя.
bool isDismissedSupportRoom(RoomSummary room) =>
    room.roomType == RoomType.support && (room.dismissedUntilMessage ?? false);

/// Чистая функция группировки комнат в авто-папки (TASK44).
///
/// Порядок результата детерминирован:
///   1. «Все» — всегда первой (агрегат; строкой не рендерится);
///   2. продуктовые папки — по возрастанию `productId` (стабильно между
///      перестройками при realtime-обновлениях);
///   3. «Личные» — последней, если есть комнаты без продукта.
///
/// [rooms] — текущий (уже отфильтрованный по archived/search) список из
/// [ChatsListReady]. [products] — кэш `getAvailableProducts` (может быть
/// `null`, пока не загружен: тогда продуктовые имена берутся fallback-ом).
///
/// Каждая папка несёт агрегаты для строки-папки (фаза 1.5): сумма unread,
/// число комнат, а также [ChatFolder.lastMessageAt] /
/// [ChatFolder.lastMessagePreview] — от самого свежего чата папки (max по
/// `lastMessageAt`).
///
/// Пустые папки не создаются: продуктовая папка появляется, только если
/// по этому продукту есть хоть одна комната; «Личные» — только если есть
/// комнаты без продукта.
/// [customFolders] (TASK62) — пользовательские server-side папки
/// (`listChatFolders`). Каждая превращается в [ChatFolder] с
/// `kind=custom` и агрегатами по её комнатам, присутствующим в [rooms].
/// В отличие от авто-папок ПУСТАЯ кастомная папка видна (юзер только что
/// создал её и ждёт увидеть). Кастомные идут сразу после агрегата «Все»,
/// ПЕРЕД продуктовыми (пользовательский выбор приоритетнее автоматики).
List<ChatFolder> buildFolders(
  List<RoomSummary> rooms, {
  List<Product>? products,
  List<ChatFolderView>? customFolders,
}) {
  // Агрегаты по productId.
  final productUnread = <int, int>{};
  final productRooms = <int, int>{};
  // Самый свежий чат папки: храним RoomSummary с max lastMessageAt.
  final productFreshest = <int, RoomSummary>{};
  var personalUnread = 0;
  var personalRooms = 0;
  RoomSummary? personalFreshest;
  var totalUnread = 0;
  RoomSummary? allFreshest;
  // **TASK75**: агрегат «Поддержка» — все support-комнаты (кроме
  // «закрытых» оператором) по всем продуктам.
  var supportUnread = 0;
  var supportRooms = 0;
  RoomSummary? supportFreshest;
  // **TASK68**: агрегат «Избранное» — все self-чаты пользователя.
  var savedUnread = 0;
  var savedRooms = 0;
  RoomSummary? savedFreshest;

  // true если у [candidate] более свежий lastMessageAt, чем у [current].
  // Комната без lastMessageAt считается «старее» любой с датой; при равных
  // датах / обоих null — оставляем текущего (стабильность).
  bool isFresher(RoomSummary candidate, RoomSummary? current) {
    if (current == null) return true;
    final c = candidate.lastMessageAt;
    final cur = current.lastMessageAt;
    if (c == null) return false;
    if (cur == null) return true;
    return c.isAfter(cur);
  }

  for (final r in rooms) {
    // **TASK75**: «закрытые» оператором support-комнаты не участвуют ни в
    // одном агрегате — они скрыты до сообщения заявителя.
    if (isDismissedSupportRoom(r)) continue;
    totalUnread += r.unreadCount;
    if (isFresher(r, allFreshest)) allFreshest = r;
    // **TASK75**: support-комнаты уходят в агрегат «Поддержка», а НЕ в
    // продуктовые/личные папки (оператор работает единым инбоксом).
    if (r.roomType == RoomType.support) {
      supportUnread += r.unreadCount;
      supportRooms += 1;
      if (isFresher(r, supportFreshest)) supportFreshest = r;
      continue;
    }
    // **TASK68**: self-чаты уходят в агрегат «Избранное», а НЕ в «Личные»
    // (у них `productId == null`, иначе провалились бы туда ниже).
    if (isSavedRoom(r)) {
      savedUnread += r.unreadCount;
      savedRooms += 1;
      if (isFresher(r, savedFreshest)) savedFreshest = r;
      continue;
    }
    final pid = r.productId;
    if (pid == null) {
      personalUnread += r.unreadCount;
      personalRooms += 1;
      if (isFresher(r, personalFreshest)) personalFreshest = r;
    } else {
      productUnread[pid] = (productUnread[pid] ?? 0) + r.unreadCount;
      productRooms[pid] = (productRooms[pid] ?? 0) + 1;
      if (isFresher(r, productFreshest[pid])) productFreshest[pid] = r;
    }
  }

  // Индекс productId -> Product для резолва имени.
  final byId = <int, Product>{};
  if (products != null) {
    for (final p in products) {
      final id = p.id;
      if (id != null) byId[id] = p;
    }
  }

  final folders = <ChatFolder>[
    ChatFolder(
      kind: ChatFolderKind.all,
      unreadCount: totalUnread,
      roomCount: rooms.length,
      lastMessageAt: allFreshest?.lastMessageAt,
      lastMessagePreview: allFreshest?.lastMessagePreview,
    ),
  ];

  // **TASK75**: агрегатная папка «Поддержка» — сразу после «Все», перед
  // кастомными/продуктовыми (операторский инбокс приоритетен). Появляется,
  // только если есть хоть одна НЕ-«закрытая» support-комната.
  if (supportRooms > 0) {
    folders.add(
      ChatFolder(
        kind: ChatFolderKind.support,
        unreadCount: supportUnread,
        roomCount: supportRooms,
        lastMessageAt: supportFreshest?.lastMessageAt,
        lastMessagePreview: supportFreshest?.lastMessagePreview,
      ),
    );
  }

  // **TASK68**: агрегатная папка «Избранное» — сразу после «Поддержки»,
  // перед кастомными/продуктовыми (свои заметки под рукой). Появляется,
  // только если у пользователя есть хоть один self-чат: дефолтный
  // «Избранное» сервер создаёт по первому входу в раздел, до этого
  // засорять список нечем.
  if (savedRooms > 0) {
    folders.add(
      ChatFolder(
        kind: ChatFolderKind.saved,
        unreadCount: savedUnread,
        roomCount: savedRooms,
        lastMessageAt: savedFreshest?.lastMessageAt,
        lastMessagePreview: savedFreshest?.lastMessagePreview,
      ),
    );
  }

  // **TASK62**: кастомные папки — сразу после агрегата «Все».
  if (customFolders != null) {
    final byRoomId = <int, RoomSummary>{for (final r in rooms) r.id: r};
    for (final view in customFolders) {
      final ids = view.roomIds.toSet();
      var unread = 0;
      var count = 0;
      RoomSummary? freshest;
      for (final id in ids) {
        final room = byRoomId[id];
        if (room == null) continue; // комната вне текущего фильтра/скоупа
        unread += room.unreadCount;
        count += 1;
        if (isFresher(room, freshest)) freshest = room;
      }
      folders.add(
        ChatFolder(
          kind: ChatFolderKind.custom,
          customFolderId: view.id,
          customName: view.name,
          roomIds: ids,
          unreadCount: unread,
          roomCount: count,
          lastMessageAt: freshest?.lastMessageAt,
          lastMessagePreview: freshest?.lastMessagePreview,
        ),
      );
    }
  }

  final sortedProductIds = productRooms.keys.toList()..sort();
  for (final pid in sortedProductIds) {
    final product = byId[pid];
    final freshest = productFreshest[pid];
    folders.add(
      ChatFolder(
        kind: ChatFolderKind.product,
        productId: pid,
        productKey: product?.externalKey,
        productDisplayName: product?.displayName,
        unreadCount: productUnread[pid] ?? 0,
        roomCount: productRooms[pid] ?? 0,
        lastMessageAt: freshest?.lastMessageAt,
        lastMessagePreview: freshest?.lastMessagePreview,
      ),
    );
  }

  if (personalRooms > 0) {
    folders.add(
      ChatFolder(
        kind: ChatFolderKind.personal,
        unreadCount: personalUnread,
        roomCount: personalRooms,
        lastMessageAt: personalFreshest?.lastMessageAt,
        lastMessagePreview: personalFreshest?.lastMessagePreview,
      ),
    );
  }

  return folders;
}

/// «Обёртка-папка» имеет смысл только когда групп больше одной. Если
/// после [buildFolders] есть ≤ 1 продуктовой/личной группы (т.е. только
/// «Все» + максимум одна группа), заворачивать не нужно — UI показывает
/// чаты плоско. См. TASK44 §Фаза 1.5.
///
/// Считаем «содержательные» группы (всё кроме агрегата `all`):
///   * 0 групп (пустой список) → плоско;
///   * 1 группа (один продукт без личных, ИЛИ только личные) → плоско;
///   * ≥ 2 групп (продукт + личные, или несколько продуктов) → папки.
bool foldersVisible(List<ChatFolder> folders) {
  final groups = folders.where((f) => f.kind != ChatFolderKind.all).length;
  return groups > 1;
}

/// **Фаза 1.5 — строка корневого списка чатов.** Модель «папка-как-строка»:
/// корень чат-листа содержит смесь обычных чатов ([ChatRoomRow]) и
/// синтетических строк-папок ([ChatFolderRow]). UI рендерит их одним
/// проходом; тап по [ChatFolderRow] проваливает в drill-in экран.
///
/// Порядок между строками — по времени последней активности (самый свежий
/// сверху), едино для чатов и папок (см. [buildRootRows]).
sealed class ChatRootRow {
  const ChatRootRow();

  /// Время для сортировки корневого списка: `lastMessageAt` чата или
  /// самого свежего чата папки. `null` — если активности нет (уходит вниз).
  DateTime? get sortKey;
}

/// Корневая строка — обычный чат (личный / безпродуктовый / комната,
/// когда папки не заворачиваются).
final class ChatRoomRow extends ChatRootRow {
  const ChatRoomRow(this.room);

  final RoomSummary room;

  @override
  DateTime? get sortKey => room.lastMessageAt;
}

/// Корневая строка — синтетическая папка продукта. Несёт [ChatFolder] с
/// агрегатами (unread-сумма, превью/время самого свежего чата) для рендера
/// строки-папки. Тап → drill-in.
final class ChatFolderRow extends ChatRootRow {
  const ChatFolderRow(this.folder);

  final ChatFolder folder;

  @override
  DateTime? get sortKey => folder.lastMessageAt;
}

/// **Фаза 1.5 — построение корневого списка «папка-как-строка».**
///
/// Из плоского [rooms] и вычисленных [folders] (результат [buildFolders])
/// собирает смешанный список [ChatRootRow]:
///   * личные/безпродуктовые чаты → [ChatRoomRow] (как есть);
///   * каждая продуктовая папка → одна [ChatFolderRow];
///   * если [foldersVisible] == false (≤ 1 группа) — заворачивать не
///     нужно, ВСЕ комнаты идут плоско как [ChatRoomRow].
///
/// Сортировка — по [ChatRootRow.sortKey] (самый свежий сверху; строки без
/// активности — в конце, стабильно по исходному порядку).
List<ChatRootRow> buildRootRows(
  List<RoomSummary> rooms,
  List<ChatFolder> folders,
) {
  // **TASK62**: кастомные папки-строки видны ВСЕГДА (даже пустые и даже
  // когда продуктовая обёртка не нужна). Чаты из кастомных папок НЕ
  // прячутся из корня: папка — быстрый доступ, не перемещение (один чат
  // может быть в нескольких папках и одновременно личным).
  //
  // **TASK75**: агрегатная папка «Поддержка» — тоже всегда строкой (если
  // есть support-комнаты). Сами support-комнаты в корень плоскими строками
  // НЕ выносятся — они живут только внутри этой папки.
  //
  // **TASK68**: то же для «Избранного» — разделы self-чатов видны только
  // внутри своей папки, иначе «заметки»/«файлообмен»/«документы» забили бы
  // корень ленты наравне с настоящими собеседниками.
  final pinnedRows = <ChatRootRow>[
    for (final f in folders)
      if (f.kind == ChatFolderKind.custom ||
          f.kind == ChatFolderKind.support ||
          f.kind == ChatFolderKind.saved)
        ChatFolderRow(f),
  ];

  // Одна авто-группа или пусто → плоский список (плюс закреплённые папки).
  if (!foldersVisible(folders)) {
    final rows = <ChatRootRow>[
      ...pinnedRows,
      for (final r in rooms)
        if (r.roomType != RoomType.support && !isSavedRoom(r)) ChatRoomRow(r),
    ];
    _sortRootRows(rows);
    return rows;
  }

  final rows = <ChatRootRow>[...pinnedRows];
  // Безпродуктовые комнаты — обычными строками (кроме support и saved).
  for (final r in rooms) {
    if (r.productId == null &&
        r.roomType != RoomType.support &&
        !isSavedRoom(r)) {
      rows.add(ChatRoomRow(r));
    }
  }
  // Продуктовые папки — синтетическими строками.
  for (final f in folders) {
    if (f.kind == ChatFolderKind.product) rows.add(ChatFolderRow(f));
  }
  _sortRootRows(rows);
  return rows;
}

/// Стабильная сортировка корневых строк: свежие сверху, `null`-sortKey —
/// в конец (с сохранением исходного относительного порядка).
void _sortRootRows(List<ChatRootRow> rows) {
  // mergeSort даёт stable-порядок; dart `sort` не гарантирует стабильность.
  // Реализуем стабильность через индекс-tie-break на обычном sort.
  final indexed = [for (var i = 0; i < rows.length; i++) (i, rows[i])];
  indexed.sort((a, b) {
    final ak = a.$2.sortKey;
    final bk = b.$2.sortKey;
    if (ak == null && bk == null) return a.$1.compareTo(b.$1);
    if (ak == null) return 1; // a без даты → ниже
    if (bk == null) return -1; // b без даты → ниже
    final cmp = bk.compareTo(ak); // свежий (больший) — выше
    return cmp != 0 ? cmp : a.$1.compareTo(b.$1);
  });
  for (var i = 0; i < indexed.length; i++) {
    rows[i] = indexed[i].$2;
  }
}
