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
/// # Системные папки продуктов для чатов поддержки (решение владельца)
///
/// Обращения в поддержку раскладываются **по продуктам**: на каждый
/// продукт, по которому смотрящий — ОПЕРАТОР хотя бы одного обращения,
/// получается папка с именем продукта, а внутри чаты уже названы по
/// заявителям (perspective-именование делает сервер, см.
/// `SupportRoomNaming.perspectiveName`). Единый агрегат «Поддержка» этим
/// заменён: у оператора трёх продуктов в одной куче лежали чужие друг
/// другу очереди.
///
/// **Собственное обращение человека в папку НЕ попадает.** Оно остаётся
/// обычной строкой в корне списка и названо по продукту («Чатиста») —
/// это его личный чат с поддержкой, а не элемент чьей-то очереди.
/// Различить два случая можно только по `supportViewerIsRequester`:
/// `supportRequesterName` заполнен с обеих сторон.
///
/// **Почему папки СИСТЕМНЫЕ, а не обычные с автозаполнением.** Обычную
/// папку человек вправе переименовать, удалить или вынуть из неё чат — и
/// тогда автоматика с ним конфликтует: вынул чат — вернули, удалил папку
/// — создали заново. Если же не трогать, раскладка со временем врёт.
/// Поэтому системная папка не хранится вовсе: она вычисляется при каждом
/// чтении из текущего списка комнат и потому всегда верна, а
/// переименовать / удалить / вынуть из неё чат нельзя — см.
/// [ChatFolder.isSystem]. Тот же принцип выбран для команд: считать при
/// чтении, синхронизация постоянная (см.
/// `platform/docs/DESIGN_TEAMS_AND_CONTACT_SHARING.md`).
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

  /// **Системные папки продуктов**: префикс ключа папки продукта, в
  /// которой лежит операторский инбокс (`kind == support`). Полный ключ —
  /// `support:<productId>`. Отдельный префикс (а не общий `product:`)
  /// нужен UI: по нему drill-in экран узнаёт, что строки надо рисовать
  /// операторским рендером (заявитель + «светофор» SLA + стадия тикета),
  /// не спрашивая у контроллера саму папку.
  static const String supportSelectionPrefix = 'support:';

  /// **TASK68**: стабильный ключ агрегатной папки «Избранное» (self-чаты).
  static const String savedSelectionKey = '__saved__';

  /// Стабильный ключ выбора/идентификации папки. `all` / `personal` /
  /// `saved` — по виду; `product` / `support` — по `productId`; `custom` —
  /// по серверному id.
  String get selectionKey => switch (kind) {
    ChatFolderKind.all => '__all__',
    ChatFolderKind.personal => '__personal__',
    ChatFolderKind.saved => savedSelectionKey,
    ChatFolderKind.support => '$supportSelectionPrefix$productId',
    ChatFolderKind.product => 'product:$productId',
    ChatFolderKind.custom => 'custom:$customFolderId',
  };

  /// **Системная папка** — вычисляется при чтении из текущего списка
  /// комнат, а не хранится. Системными являются все папки, кроме
  /// пользовательских (`custom`, TASK62).
  ///
  /// Что именно человеку запрещено и чем это обеспечено: у системной папки
  /// нет строки в `chat_folders`, поэтому [customFolderId] у неё всегда
  /// `null`, а весь мутирующий API (`renameChatFolder` / `deleteChatFolder`
  /// / `setRoomInChatFolder`) адресуется ИМЕННО этим `int folderId`.
  /// То есть переименовать, удалить или вынуть чат нельзя не по запрету в
  /// коде, а потому, что вызову нечего передать — запрет структурный, его
  /// нельзя обойти ни из UI, ни с другого клиента. Обратная сторона того
  /// же свойства: раскладка не может «протухнуть» — она пересчитывается на
  /// каждом чтении списка.
  ///
  /// Положить тот же чат ещё и в свою ручную папку человеку можно: ручная
  /// папка — быстрый доступ, а не перемещение (см. `buildRootRows`), и на
  /// системную раскладку она не влияет.
  bool get isSystem => kind != ChatFolderKind.custom;

  /// Проходит ли комната фильтр этой папки.
  ///
  ///   * `all` — все комнаты.
  ///   * `personal` — только `productId == null`.
  ///   * `saved` (**TASK68**) — только self-чаты «Избранного».
  ///   * `product` / `support` — комнаты с совпадающим `productId`. Из них
  ///     исключены собственные обращения смотрящего (их место — корень
  ///     списка) и «закрытые» оператором support-комнаты (скрыты до
  ///     сообщения заявителя). Правило одно на два вида: `support` — это
  ///     та же папка продукта, просто в ней есть операторские обращения,
  ///     и вид отличает лишь рендер (иконка + операторские строки).
  ///   * `custom` — только комнаты из явного [roomIds] (TASK62).
  bool matches(RoomSummary room) => switch (kind) {
    ChatFolderKind.all => true,
    // **TASK68**: self-чаты не «личные» — у них своя папка «Избранное».
    // Без этого исключения они дублировались бы в двух местах списка.
    ChatFolderKind.personal => room.productId == null && !isSavedRoom(room),
    ChatFolderKind.saved => isSavedRoom(room),
    ChatFolderKind.support || ChatFolderKind.product =>
      room.productId == productId &&
          !isOwnSupportRequest(room) &&
          !isDismissedSupportRoom(room),
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

/// Вид папки. `all`/`personal`/`product`/`support`/`saved` — системные,
/// вычисляемые при чтении (TASK44/75/68 + системные папки продуктов);
/// `custom` — пользовательская server-side папка (TASK62).
///
/// `support` — это папка ПРОДУКТА, в которой есть обращения, где смотрящий
/// оператор. От `product` она отличается только рендером (иконка + строки
/// операторским стилем): состав считается одним правилом, см.
/// [ChatFolder.matches].
enum ChatFolderKind { all, personal, support, saved, product, custom }

/// **TASK68**: комната — раздел «Избранного» (self-чат, единственный
/// участник — сам владелец). Такие комнаты собираются в агрегатную папку
/// «Избранное» и НЕ рендерятся плоскими строками в корне списка (иначе
/// «заметки», «файлообмен» и т.д. забивали бы ленту чатов).
bool isSavedRoom(RoomSummary room) => room.roomType == RoomType.saved;

/// **Системные папки продуктов**: комната — СОБСТВЕННОЕ обращение
/// смотрящего (он в ней заявитель, а не оператор). Такие чаты живут в
/// корне списка и названы по продукту; в системную папку продукта они не
/// попадают, иначе человек искал бы свой вопрос среди чужих очередей.
///
/// `supportViewerIsRequester == null` (старый сервер) трактуем как «не
/// заявитель»: тогда чат просто окажется в папке продукта. Обратный дефолт
/// вывалил бы весь операторский инбокс в корень — цена ошибки несимметрична.
bool isOwnSupportRequest(RoomSummary room) =>
    room.roomType == RoomType.support &&
    (room.supportViewerIsRequester ?? false);

/// **TASK75**: комната относится к операторскому support-инбоксу — это
/// support-комната, которую текущий оператор ещё НЕ «закрыл до ответа»
/// (`dismissedUntilMessage != true`). «Закрытые» комнаты прячутся из всех
/// списков до нового сообщения заявителя (сервер сбрасывает флаг). Общий
/// предикат для системных папок продуктов, root-rows и фильтрации в UI.
///
/// **Системные папки продуктов**: собственное обращение смотрящего
/// инбоксом не является — оператор разбирает чужие вопросы, а свой ведёт
/// как обычный чат (см. [isOwnSupportRequest]).
bool isSupportInboxRoom(RoomSummary room) =>
    room.roomType == RoomType.support &&
    !(room.dismissedUntilMessage ?? false) &&
    !isOwnSupportRequest(room);

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
/// комнаты без продукта. **Системные папки продуктов**: собственное
/// обращение смотрящего комнатой папки не считается, поэтому по продукту,
/// куда человек только написал сам, папки не заводится вовсе — будет один
/// чат в корне.
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
  // **Системные папки продуктов**: продукты, по которым у смотрящего есть
  // хотя бы одно обращение в роли ОПЕРАТОРА. Только они делают папку
  // продукта операторским инбоксом (`kind == support`) — с иконкой
  // наушников и операторским рендером строк внутри.
  final productHasOperatorSupport = <int>{};
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
    // **TASK68**: self-чаты уходят в агрегат «Избранное», а НЕ в «Личные»
    // (у них `productId == null`, иначе провалились бы туда ниже).
    if (isSavedRoom(r)) {
      savedUnread += r.unreadCount;
      savedRooms += 1;
      if (isFresher(r, savedFreshest)) savedFreshest = r;
      continue;
    }
    final pid = r.productId;
    // **Системные папки продуктов**: собственное обращение в агрегаты
    // папки не идёт вообще — его место в корне списка (см. `buildRootRows`).
    // Иначе бейдж папки считал бы непрочитанное по своему же вопросу, а сам
    // вопрос человек искал бы среди чужих обращений.
    if (isOwnSupportRequest(r)) continue;
    if (pid == null) {
      // Support-комната без продукта — аномалия (обращения заводятся через
      // `getOrCreateProductRoom`, продукт есть всегда). Раскладывать её
      // некуда, поэтому считаем «личной»: показать чат в корне честнее,
      // чем потерять его вместе с несуществующей папкой.
      personalUnread += r.unreadCount;
      personalRooms += 1;
      if (isFresher(r, personalFreshest)) personalFreshest = r;
    } else {
      productUnread[pid] = (productUnread[pid] ?? 0) + r.unreadCount;
      productRooms[pid] = (productRooms[pid] ?? 0) + 1;
      if (isFresher(r, productFreshest[pid])) productFreshest[pid] = r;
      if (r.roomType == RoomType.support) productHasOperatorSupport.add(pid);
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

  // **TASK68**: агрегатная папка «Избранное» — сразу после «Все»,
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
        // **Системные папки продуктов**: на продукт ровно ОДНА папка. Если
        // среди её комнат есть обращения, где смотрящий — оператор, папка
        // становится его инбоксом по этому продукту (`support`). Два вида
        // на один продукт не заводим: человек увидел бы две папки с
        // одинаковым именем и гадал, в какой из них искать.
        kind: productHasOperatorSupport.contains(pid)
            ? ChatFolderKind.support
            : ChatFolderKind.product,
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
  // **Системные папки продуктов**: папка продукта с операторским инбоксом
  // (`support`) закреплена ВСЕГДА, в том числе когда содержательная группа
  // всего одна и обёртка по правилу [foldersVisible] не нужна. Системная
  // папка обязана быть верна при любом составе списка, а «развернуть» её —
  // значит высыпать чужие обращения в корень рядом с собственным чатом по
  // тому же продукту: два одинаково выглядящих чата, из которых один твой,
  // а другой — чей-то вопрос.
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

  // Комната идёт в корень плоской строкой? «Закрытые» и операторские
  // обращения — нет (их место в папке продукта), self-чаты — нет
  // («Избранное»). Собственное обращение — ДА, даже если у него есть
  // продукт и папка этого продукта существует.
  bool isRootChat(RoomSummary r) =>
      !isDismissedSupportRoom(r) && !isSupportInboxRoom(r) && !isSavedRoom(r);

  // Одна авто-группа или пусто → плоский список (плюс закреплённые папки).
  if (!foldersVisible(folders)) {
    final rows = <ChatRootRow>[
      ...pinnedRows,
      for (final r in rooms)
        if (isRootChat(r)) ChatRoomRow(r),
    ];
    _sortRootRows(rows);
    return rows;
  }

  final rows = <ChatRootRow>[...pinnedRows];
  // Безпродуктовые комнаты — обычными строками; плюс собственные обращения
  // (у них продукт есть, но папка — не их место).
  for (final r in rooms) {
    if (!isRootChat(r)) continue;
    if (r.productId == null || isOwnSupportRequest(r)) rows.add(ChatRoomRow(r));
  }
  // Продуктовые папки без операторского инбокса — синтетическими строками
  // (папки с инбоксом уже закреплены выше).
  for (final f in folders) {
    if (f.kind == ChatFolderKind.product) rows.add(ChatFolderRow(f));
  }
  _sortRootRows(rows);
  return rows;
}

/// Только поддержка: операторские очереди папками, свои обращения строками.
///
/// Предложение владельца 10.08.2026: подвид «Группы» оказался бесполезен —
/// «туда попадает по сути всё». На его месте нужен разрез, который человек
/// действительно ищет: где мои обращения и где очереди по продуктам.
///
/// Это ФИЛЬТР готового корневого списка, а не вторая раскладка: внутри всё
/// выглядит ровно как на вкладке «Все» — чужие обращения папками продуктов,
/// свои отдельными строками. Иначе один и тот же чат выглядел бы по-разному
/// в двух местах.
List<ChatRootRow> supportRootRows(List<ChatRootRow> rows) => [
  for (final row in rows)
    if (switch (row) {
      ChatFolderRow(:final folder) => folder.kind == ChatFolderKind.support,
      ChatRoomRow(:final room) => isOwnSupportRequest(room),
    })
      row,
];

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
