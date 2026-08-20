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
import 'enums/room_type.dart' as _i2;
import 'enums/room_ownership.dart' as _i3;
import 'enums/room_state.dart' as _i4;

/// Room — Matrix-комната с продуктовой/NSG-метадатой поверх.
/// Matrix хранит участников и сообщения; здесь — type/ownership/state и
/// product context для быстрых выборок без обращения к Matrix.
/// См. ТЗ §9, §10, §11, §13.
abstract class Room implements _i1.SerializableModel {
  Room._({
    this.id,
    required this.tenantId,
    this.productId,
    required this.matrixRoomId,
    required this.roomType,
    required this.ownership,
    required this.state,
    this.productEntityType,
    this.productEntityId,
    this.name,
    String? contentLocale,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastMessageBody,
    this.lastMessageThreadRootEventId,
    this.supportEscalationTier,
    this.awaitingOperatorSince,
    this.autoCleanupTtlSeconds,
    bool? participantsHidden,
    this.directPairKey,
  }) : contentLocale = contentLocale ?? 'ru',
       participantsHidden = participantsHidden ?? false;

  factory Room({
    int? id,
    required int tenantId,
    int? productId,
    required String matrixRoomId,
    required _i2.RoomType roomType,
    required _i3.RoomOwnership ownership,
    required _i4.RoomState state,
    String? productEntityType,
    String? productEntityId,
    String? name,
    String? contentLocale,
    String? avatarUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastMessageAt,
    String? lastMessageBody,
    String? lastMessageThreadRootEventId,
    int? supportEscalationTier,
    DateTime? awaitingOperatorSince,
    int? autoCleanupTtlSeconds,
    bool? participantsHidden,
    String? directPairKey,
  }) = _RoomImpl;

  factory Room.fromJson(Map<String, dynamic> jsonSerialization) {
    return Room(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int?,
      matrixRoomId: jsonSerialization['matrixRoomId'] as String,
      roomType: _i2.RoomType.fromJson(
        (jsonSerialization['roomType'] as String),
      ),
      ownership: _i3.RoomOwnership.fromJson(
        (jsonSerialization['ownership'] as String),
      ),
      state: _i4.RoomState.fromJson((jsonSerialization['state'] as String)),
      productEntityType: jsonSerialization['productEntityType'] as String?,
      productEntityId: jsonSerialization['productEntityId'] as String?,
      name: jsonSerialization['name'] as String?,
      contentLocale: jsonSerialization['contentLocale'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      lastMessageAt: jsonSerialization['lastMessageAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastMessageAt'],
            ),
      lastMessageBody: jsonSerialization['lastMessageBody'] as String?,
      lastMessageThreadRootEventId:
          jsonSerialization['lastMessageThreadRootEventId'] as String?,
      supportEscalationTier: jsonSerialization['supportEscalationTier'] as int?,
      awaitingOperatorSince: jsonSerialization['awaitingOperatorSince'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['awaitingOperatorSince'],
            ),
      autoCleanupTtlSeconds: jsonSerialization['autoCleanupTtlSeconds'] as int?,
      participantsHidden: jsonSerialization['participantsHidden'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['participantsHidden'],
            ),
      directPairKey: jsonSerialization['directPairKey'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int tenantId;

  /// NULL = комната принадлежит tenant, не привязана к продукту.
  int? productId;

  /// Полный matrix room id `!abc:server`.
  String matrixRoomId;

  _i2.RoomType roomType;

  _i3.RoomOwnership ownership;

  _i4.RoomState state;

  /// Product context (§13). entityType: 'team', 'support_ticket' и т.д.
  String? productEntityType;

  String? productEntityId;

  String? name;

  /// **issue #127**: язык, на котором сервер пишет В ЭТУ КОМНАТУ —
  /// карточки мониторинга, «Задача создана», приветствие поддержки.
  ///
  /// Почему свойство КОМНАТЫ, а не получателя: сообщение в комнате одно
  /// на всех, и «под зрителя» его не перевести. Язык задаётся при
  /// создании по языку создателя; всем существующим комнатам миграция
  /// ставит `ru` — они такими и были.
  String contentLocale;

  /// **B16-ext (group avatar)**: mxc-URL аватара группы. Заполняется
  /// `setRoomAvatar` endpoint-ом (owner/admin only) + при `/sync`
  /// парсинге `m.room.avatar` state event. Для direct-чатов поле
  /// остаётся null — `RoomSummary.avatarUrl` для direct берётся из
  /// peer's MessengerUser.avatarUrl (computed). Для group/team —
  /// берётся отсюда.
  String? avatarUrl;

  DateTime createdAt;

  DateTime updatedAt;

  /// Кэш для listRooms: lastMessageAt + preview body (обрезается до 120 chars).
  /// Заполняется sync-loop-ом TASK09.
  DateTime? lastMessageAt;

  String? lastMessageBody;

  /// **issue #92**: корень треда последнего сообщения — не null, если превью
  /// выше показывает реплику ОБСУЖДЕНИЯ задачи, а не сообщение ленты.
  ///
  /// Зачем. Реплики тредов двигают превью и шлют пуши как обычные сообщения,
  /// но в ленту комнаты не попадают (разделение лент, TASK82). Без этого поля
  /// строка списка чатов показывает текст, а тап по ней открывает ленту, где
  /// текста нет и быть не может: человек видит сообщение, нажимает и приходит
  /// туда, где его нет. Пометка `💬` (см. RoomLastMessageWatcher) сняла ложное
  /// обещание, но пути не дала — путь даёт этот корень.
  ///
  /// Пишется ВЕЗДЕ, где пишется `lastMessageBody`, и всегда вместе с ним:
  /// разъехавшись, они дадут либо пометку без пути, либо путь в чужой тред.
  String? lastMessageThreadRootEventId;

  /// **TASK48**: текущий достигнутый тир эскалации support-комнаты.
  /// `null` = базовый уровень (фронт-линия, не эскалировано). При явной
  /// или авто-эскалации ставится в номер подключённого тира. Значимо
  /// только для support-комнат (roomType == support); у прочих остаётся
  /// null. См. TASK48 §5.2 (конкурентность — условный UPDATE).
  int? supportEscalationTier;

  /// **TASK48 iter2**: момент, с которого support-чат ждёт ответа
  /// ЧЕЛОВЕКА-оператора. Ставится при сообщении заявителя (если ещё
  /// null), снимается (null) при ответе оператора-человека; бот НЕ
  /// снимает. Основа авто-эскалации по таймауту: `SupportEscalationSweep
  /// FutureCall` берёт комнаты, где `now - awaitingOperatorSince >
  /// team.escalationTimeoutMinutes`. null = никто не ждёт. Существующие
  /// комнаты после деплоя стартуют таймер только со следующего сообщения
  /// заявителя (ретроактивной реконструкции нет). См. TASK48 §5.3.
  DateTime? awaitingOperatorSince;

  /// **TASK68 (автоочистка «Избранного»)**: TTL сообщений комнаты в
  /// СЕКУНДАХ. `null` (дефолт) — автоочистка выключена, ничего не
  /// удаляется. Настройка живёт на комнате, а не на пользователе:
  /// «файлообмен» чистится раз в сутки, «заметки» — никогда.
  ///
  /// Секунды, а не Duration, потому что у Serverpod нет колоночного
  /// типа Duration; SDK/UI работают с пресетами (день / неделя /
  /// месяц / свой) — см. `SavedChatPolicy.allowedTtls`.
  ///
  /// Сметает `SavedCleanupFutureCall` — редактит (Matrix redaction)
  /// сообщения старше TTL, **пропуская закреплённые**
  /// (`m.room.pinned_events`). Значимо для любого типа комнаты, но
  /// на TASK68 задаётся только для `RoomType.saved` (см.
  /// `SavedChatService.setAutoCleanupTtl`).
  int? autoCleanupTtlSeconds;

  /// **Issue #40 (двоение личных чатов)**: канонический ключ пары
  /// участников direct-комнаты — `"<minId>:<maxId>"` по
  /// `MessengerUser.id`. Заполняется только для `roomType == direct`;
  /// у group/team/support/saved/product остаётся `null`.
  ///
  /// **Зачем колонка, а не вычисление по RoomMembership**: после
  /// `leaveRoom` строка membership ушедшего УДАЛЯЕТСЯ, и по локальной
  /// БД уже невозможно узнать, между кем была комната. Поэтому
  /// `_findExistingDirect` не находил осиротевшую комнату, `createDirect`
  /// создавал новую, и у оставшегося участника чат двоился. Ключ на комнате
  /// переживает уход любого участника и делает поиск однозначным.
  ///
  /// Индекс намеренно НЕ unique: на момент миграции в проде уже лежат
  /// дубли (это и есть баг), unique-индекс просто не создался бы.
  /// Уникальность держится на уровне приложения (`_findExistingDirect`
  /// + revive вместо создания). Ужесточить до unique можно отдельной
  /// миграцией ПОСЛЕ прогона `bin/cleanup_direct_duplicates.dart`.
  ///
  /// Legacy-комнаты (созданные до миграции) стартуют с `null` и
  /// добираются лениво: `_findExistingDirect` при fallback-поиске по
  /// RoomMembership проставляет ключ найденной комнате.
  /// **issue #62**: админ группы скрыл СОСТАВ от рядовых участников.
  /// Запрос владельца: «в групповых чатах не видно участников, возможно
  /// нужно показывать опционально — решает админ чата». По умолчанию false
  /// (как было: состав открыт всем), включает владелец/админ комнаты.
  ///
  /// Скрывается именно СПИСОК ИМЁН, а не число: «сколько нас» — не тайна,
  /// оно видно и по ленте сообщений, а прятать его значило бы сделать
  /// комнату непонятной без всякой выгоды.
  bool participantsHidden;

  String? directPairKey;

  /// Returns a shallow copy of this [Room]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Room copyWith({
    int? id,
    int? tenantId,
    int? productId,
    String? matrixRoomId,
    _i2.RoomType? roomType,
    _i3.RoomOwnership? ownership,
    _i4.RoomState? state,
    String? productEntityType,
    String? productEntityId,
    String? name,
    String? contentLocale,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    String? lastMessageBody,
    String? lastMessageThreadRootEventId,
    int? supportEscalationTier,
    DateTime? awaitingOperatorSince,
    int? autoCleanupTtlSeconds,
    bool? participantsHidden,
    String? directPairKey,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Room',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      if (productId != null) 'productId': productId,
      'matrixRoomId': matrixRoomId,
      'roomType': roomType.toJson(),
      'ownership': ownership.toJson(),
      'state': state.toJson(),
      if (productEntityType != null) 'productEntityType': productEntityType,
      if (productEntityId != null) 'productEntityId': productEntityId,
      if (name != null) 'name': name,
      'contentLocale': contentLocale,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt?.toJson(),
      if (lastMessageBody != null) 'lastMessageBody': lastMessageBody,
      if (lastMessageThreadRootEventId != null)
        'lastMessageThreadRootEventId': lastMessageThreadRootEventId,
      if (supportEscalationTier != null)
        'supportEscalationTier': supportEscalationTier,
      if (awaitingOperatorSince != null)
        'awaitingOperatorSince': awaitingOperatorSince?.toJson(),
      if (autoCleanupTtlSeconds != null)
        'autoCleanupTtlSeconds': autoCleanupTtlSeconds,
      'participantsHidden': participantsHidden,
      if (directPairKey != null) 'directPairKey': directPairKey,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoomImpl extends Room {
  _RoomImpl({
    int? id,
    required int tenantId,
    int? productId,
    required String matrixRoomId,
    required _i2.RoomType roomType,
    required _i3.RoomOwnership ownership,
    required _i4.RoomState state,
    String? productEntityType,
    String? productEntityId,
    String? name,
    String? contentLocale,
    String? avatarUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastMessageAt,
    String? lastMessageBody,
    String? lastMessageThreadRootEventId,
    int? supportEscalationTier,
    DateTime? awaitingOperatorSince,
    int? autoCleanupTtlSeconds,
    bool? participantsHidden,
    String? directPairKey,
  }) : super._(
         id: id,
         tenantId: tenantId,
         productId: productId,
         matrixRoomId: matrixRoomId,
         roomType: roomType,
         ownership: ownership,
         state: state,
         productEntityType: productEntityType,
         productEntityId: productEntityId,
         name: name,
         contentLocale: contentLocale,
         avatarUrl: avatarUrl,
         createdAt: createdAt,
         updatedAt: updatedAt,
         lastMessageAt: lastMessageAt,
         lastMessageBody: lastMessageBody,
         lastMessageThreadRootEventId: lastMessageThreadRootEventId,
         supportEscalationTier: supportEscalationTier,
         awaitingOperatorSince: awaitingOperatorSince,
         autoCleanupTtlSeconds: autoCleanupTtlSeconds,
         participantsHidden: participantsHidden,
         directPairKey: directPairKey,
       );

  /// Returns a shallow copy of this [Room]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Room copyWith({
    Object? id = _Undefined,
    int? tenantId,
    Object? productId = _Undefined,
    String? matrixRoomId,
    _i2.RoomType? roomType,
    _i3.RoomOwnership? ownership,
    _i4.RoomState? state,
    Object? productEntityType = _Undefined,
    Object? productEntityId = _Undefined,
    Object? name = _Undefined,
    String? contentLocale,
    Object? avatarUrl = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? lastMessageAt = _Undefined,
    Object? lastMessageBody = _Undefined,
    Object? lastMessageThreadRootEventId = _Undefined,
    Object? supportEscalationTier = _Undefined,
    Object? awaitingOperatorSince = _Undefined,
    Object? autoCleanupTtlSeconds = _Undefined,
    bool? participantsHidden,
    Object? directPairKey = _Undefined,
  }) {
    return Room(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      productId: productId is int? ? productId : this.productId,
      matrixRoomId: matrixRoomId ?? this.matrixRoomId,
      roomType: roomType ?? this.roomType,
      ownership: ownership ?? this.ownership,
      state: state ?? this.state,
      productEntityType: productEntityType is String?
          ? productEntityType
          : this.productEntityType,
      productEntityId: productEntityId is String?
          ? productEntityId
          : this.productEntityId,
      name: name is String? ? name : this.name,
      contentLocale: contentLocale ?? this.contentLocale,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt is DateTime?
          ? lastMessageAt
          : this.lastMessageAt,
      lastMessageBody: lastMessageBody is String?
          ? lastMessageBody
          : this.lastMessageBody,
      lastMessageThreadRootEventId: lastMessageThreadRootEventId is String?
          ? lastMessageThreadRootEventId
          : this.lastMessageThreadRootEventId,
      supportEscalationTier: supportEscalationTier is int?
          ? supportEscalationTier
          : this.supportEscalationTier,
      awaitingOperatorSince: awaitingOperatorSince is DateTime?
          ? awaitingOperatorSince
          : this.awaitingOperatorSince,
      autoCleanupTtlSeconds: autoCleanupTtlSeconds is int?
          ? autoCleanupTtlSeconds
          : this.autoCleanupTtlSeconds,
      participantsHidden: participantsHidden ?? this.participantsHidden,
      directPairKey: directPairKey is String?
          ? directPairKey
          : this.directPairKey,
    );
  }
}
