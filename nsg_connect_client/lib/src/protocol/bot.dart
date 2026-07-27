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

/// Bot — программный клиент мессенджера (TASK36 Bots MVP). Постит в чаты
/// через long-lived bearer-токен с capability-гейтингом. Каждый бот —
/// это обычный `MessengerUser` (matrixUserId + encrypted Matrix-токен),
/// которому выдан session-токен с far-future expiry в
/// `MessengerSessionToken` — поэтому существующий
/// `MessengerSessionAuthHandler` резолвит bot-токен в bot-а
/// messengerUserId без изменений в auth-слое.
///
/// Enforcement: action-сайты (`sendMessage` / room-management) зовут
/// `BotService.requireCapability` — для людей (botFor==null) no-op, для
/// бота — проверка `enabled` + наличие capability в CSV. **ЧТЕНИЕ**
/// гейтится отдельной осью — `readMode` (TASK77 итер.2): capabilities
/// решают, что боту можно ДЕЛАТЬ, `readMode` — что он вправе ВИДЕТЬ.
abstract class Bot implements _i1.SerializableModel {
  Bot._({
    this.id,
    required this.messengerUserId,
    required this.tenantId,
    this.productId,
    required this.name,
    required this.ownerEmail,
    required this.accessToken,
    required this.capabilities,
    bool? enabled,
    this.commandsJson,
    this.readMode,
    this.description,
    bool? discoverable,
    required this.createdAt,
  }) : enabled = enabled ?? true,
       discoverable = discoverable ?? false;

  factory Bot({
    int? id,
    required int messengerUserId,
    required int tenantId,
    int? productId,
    required String name,
    required String ownerEmail,
    required String accessToken,
    required String capabilities,
    bool? enabled,
    String? commandsJson,
    String? readMode,
    String? description,
    bool? discoverable,
    required DateTime createdAt,
  }) = _BotImpl;

  factory Bot.fromJson(Map<String, dynamic> jsonSerialization) {
    return Bot(
      id: jsonSerialization['id'] as int?,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int?,
      name: jsonSerialization['name'] as String,
      ownerEmail: jsonSerialization['ownerEmail'] as String,
      accessToken: jsonSerialization['accessToken'] as String,
      capabilities: jsonSerialization['capabilities'] as String,
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      commandsJson: jsonSerialization['commandsJson'] as String?,
      readMode: jsonSerialization['readMode'] as String?,
      description: jsonSerialization['description'] as String?,
      discoverable: jsonSerialization['discoverable'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['discoverable']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на bot-овский MessengerUser. Cascade: бот удаляется вместе со
  /// своим MessengerUser-ом (и наоборот через app-level cleanup).
  int messengerUserId;

  /// FK на Tenant. Cascade-delete: боты удаляются вместе с tenant-ом.
  int tenantId;

  /// NULL = бот не привязан к конкретному продукту (tenant-wide).
  /// SetNull: при удалении продукта бот остаётся.
  int? productId;

  /// Человекочитаемое имя (= displayName MessengerUser-а).
  String name;

  /// Email владельца/ответственного (audit; кто создал бота).
  String ownerEmail;

  /// Bearer-токен бота (`bot_` + hex). Дублируется в
  /// `MessengerSessionToken.token` для auth-резолва. Показывается
  /// админу ОДИН раз при создании.
  String accessToken;

  /// CSV capability-grant-ов: `read_only,send_messages,manage_room,
  /// webhook_target`. Low-cardinality — substring/exact match в Dart.
  String capabilities;

  /// Kill-switch. `false` → requireCapability бросает на любой
  /// gated-action (бот не может постить/управлять). Чтение остаётся.
  bool enabled;

  /// **TASK77 итер.1**: реестр slash-команд бота — JSON-массив
  /// `[{"command":"deploy","description":"..."}]`, ровно
  /// `BotCommand.toJson()` (симметрично парсится и на сервере
  /// `BotService.decodeCommands`, и на клиенте `decodeBotCommands`).
  /// `null`/пусто = бот команд не объявил.
  ///
  /// **Почему JSON-строка, а не CSV и не отдельная таблица.** CSV (как у
  /// `capabilities`) здесь не годится принципиально: значение — ПАРА, а
  /// описание — свободный текст с пробелами и запятыми, любой разделитель
  /// пришлось бы экранировать, т.е. изобретать формат. Отдельная таблица
  /// `bot_commands` (FK + индекс + поле порядка + CRUD) — оплата
  /// реляционной модели там, где реляционного доступа нет: список всегда
  /// читается и пишется ЦЕЛИКОМ (`setMyCommands` — полная замена, ≤32
  /// записи), «найди ботов с командой /deploy» никому не нужно, а порядок
  /// элементов — часть UX бота и в JSON-массиве он бесплатный. Это
  /// документ, а не сущность. Плюс миграция: nullable-колонка добавляется
  /// безопасно, без backfill-а существующих ботов.
  String? commandsJson;

  /// **TASK77 итер.2 (privacy mode)**: что боту вообще ДОСТАВЛЯЕТСЯ и что он
  /// вправе вычитать из истории. Значения — `BotService.readModeAll`
  /// (`read_all`, вся переписка комнат бота) и
  /// `BotService.readModeAddressed` (`read_addressed`, только обращения:
  /// упоминание, `/команда`, reply на сообщение бота, тред с участием бота,
  /// 1:1 с ботом). Гейтится и push (webhook/`userEventStream`), и pull
  /// (`listMessages`/поиск/вложения) — см. `BotReadFilter`.
  ///
  /// **Почему строка, а не enum.** Соседи по записи — тоже строки
  /// (`capabilities` CSV, `commandsJson` JSON), и режим чтения ровно того же
  /// сорта: хранимая политика, которую сервер сравнивает с константой.
  /// Enum-колонка дала бы типизацию, но и жёсткость: любое НЕизвестное
  /// значение (ручная правка, откат кода) сломало бы десериализацию строки
  /// целиком, тогда как со строкой мы деградируем осознанно — неизвестное
  /// значение трактуется как `read_addressed` (fail closed, приватность
  /// важнее удобства). Плюс режим не едет новым enum-ом в клиентский
  /// протокол — старые клиенты просто игнорируют лишний ключ.
  ///
  /// **Почему nullable, а не `default=read_addressed`.** `NULL` = «бот
  /// заведён до TASK77 итер.2» и означает grandfathered `read_all` (решение
  /// владельца платформы): миграция — чистый `ADD COLUMN` без backfill-а,
  /// и живой support-бот, который отвечает на КАЖДОЕ сообщение своей
  /// комнаты, не слепнет в момент деплоя. `default=read_addressed` пришлось
  /// бы либо задавать всем существующим строкам (ослепив их), либо
  /// сопровождать data-скриптом-контрмерой — лишний шаг с тем же итогом.
  /// Новым ботам режим пишет явно `BotService.createBot`
  /// (дефолт — `read_addressed`, privacy by default).
  String? readMode;

  /// **TASK77 итер.3**: свободное описание «что этот бот делает» — то, что
  /// читает человек в каталоге «Добавить бота» и в карточке бота ПЕРЕД тем,
  /// как пустить программу в свою группу. Имени и списка команд для этого
  /// решения мало: команды говорят «что можно попросить», а не «что бот
  /// делает с тем, что видит».
  ///
  /// Задаётся владельцем (`myBots.setDescription`) либо самим ботом своим
  /// токеном (`messenger.setMyDescription`, симметрично `setMyCommands`
  /// итер.1 — автор бота описывает свою программу из её же кода, без
  /// похода в UI). `null`/пусто = описания нет, каталог показывает бота
  /// без него.
  ///
  /// Nullable-колонка → миграция чистым `ADD COLUMN`, существующие боты не
  /// трогаются.
  String? description;

  /// **Issue #49 (открытая платформа)**: видимость в `searchUsers`.
  /// `false` (дефолт) — бот НЕ находится поиском, добавить его в чужую
  /// комнату «с улицы» нельзя; публичность — осознанный выбор владельца.
  /// Существующие боты помечаются `true` data-скриптом
  /// `infra/scripts/backfill_bots_discoverable.sql` (не ломаем текущее
  /// поведение: их и так находили).
  bool discoverable;

  DateTime createdAt;

  /// Returns a shallow copy of this [Bot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Bot copyWith({
    int? id,
    int? messengerUserId,
    int? tenantId,
    int? productId,
    String? name,
    String? ownerEmail,
    String? accessToken,
    String? capabilities,
    bool? enabled,
    String? commandsJson,
    String? readMode,
    String? description,
    bool? discoverable,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Bot',
      if (id != null) 'id': id,
      'messengerUserId': messengerUserId,
      'tenantId': tenantId,
      if (productId != null) 'productId': productId,
      'name': name,
      'ownerEmail': ownerEmail,
      'accessToken': accessToken,
      'capabilities': capabilities,
      'enabled': enabled,
      if (commandsJson != null) 'commandsJson': commandsJson,
      if (readMode != null) 'readMode': readMode,
      if (description != null) 'description': description,
      'discoverable': discoverable,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BotImpl extends Bot {
  _BotImpl({
    int? id,
    required int messengerUserId,
    required int tenantId,
    int? productId,
    required String name,
    required String ownerEmail,
    required String accessToken,
    required String capabilities,
    bool? enabled,
    String? commandsJson,
    String? readMode,
    String? description,
    bool? discoverable,
    required DateTime createdAt,
  }) : super._(
         id: id,
         messengerUserId: messengerUserId,
         tenantId: tenantId,
         productId: productId,
         name: name,
         ownerEmail: ownerEmail,
         accessToken: accessToken,
         capabilities: capabilities,
         enabled: enabled,
         commandsJson: commandsJson,
         readMode: readMode,
         description: description,
         discoverable: discoverable,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Bot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Bot copyWith({
    Object? id = _Undefined,
    int? messengerUserId,
    int? tenantId,
    Object? productId = _Undefined,
    String? name,
    String? ownerEmail,
    String? accessToken,
    String? capabilities,
    bool? enabled,
    Object? commandsJson = _Undefined,
    Object? readMode = _Undefined,
    Object? description = _Undefined,
    bool? discoverable,
    DateTime? createdAt,
  }) {
    return Bot(
      id: id is int? ? id : this.id,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      tenantId: tenantId ?? this.tenantId,
      productId: productId is int? ? productId : this.productId,
      name: name ?? this.name,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      accessToken: accessToken ?? this.accessToken,
      capabilities: capabilities ?? this.capabilities,
      enabled: enabled ?? this.enabled,
      commandsJson: commandsJson is String? ? commandsJson : this.commandsJson,
      readMode: readMode is String? ? readMode : this.readMode,
      description: description is String? ? description : this.description,
      discoverable: discoverable ?? this.discoverable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
