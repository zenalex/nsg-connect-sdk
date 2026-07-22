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

/// **TASK51 итерация 1 (mesh-мультизвонок)** — активная конференция
/// комнаты. Server-авторитетное состояние группового звонка: строка
/// существует = конференция идёт; конец конференции (последний leave /
/// зачистка призраков) = DELETE строки. Истории конференций тут нет —
/// история звонков остаётся за `call_history_entries` (TASK46).
///
/// **Почему Postgres, а не Matrix state-event `nsg.conference`
/// (MSC3401)** — решение проработки TASK51 §3A.2:
///   * серверный ЛИМИТ участников (§3A.5) требует атомарной
///     проверки-вставки; на state-event-е два одновременных join читают
///     старый состав и оба пишут — лимит дырявый. Unique-индексы БД
///     дают гейт честно;
///   * зачистка «призраков» (краш участника) — TTL по `lastSeenAt`
///     обычным SQL; в Matrix пришлось бы перезаписывать state-event от
///     лица умершего юзера (невозможно) или держать server-бота;
///   * состав доставляется клиентам НАШЕЙ шиной (`conferenceUpdated`,
///     как presence/unread), а не Matrix `/sync` — state-event не даёт
///     выигрыша, зато светит состав федерации/Element-клиентам;
///   * интеграционные тесты репо — Postgres без Synapse.
/// Сигналинг при этом НЕ дублируется: pairwise `m.call.*` продолжают
/// ходить через Matrix (`sendCallEvent`, TASK46) — таблица хранит
/// только членство.
abstract class Conference implements _i1.SerializableModel {
  Conference._({
    this.id,
    required this.confId,
    required this.roomId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conference({
    int? id,
    required String confId,
    required int roomId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConferenceImpl;

  factory Conference.fromJson(Map<String, dynamic> jsonSerialization) {
    return Conference(
      id: jsonSerialization['id'] as int?,
      confId: jsonSerialization['confId'] as String,
      roomId: jsonSerialization['roomId'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Публичный стабильный id конференции (`conf_<32 hex>`). Им клеятся
  /// pairwise-звонки mesh-а (CallKit-коллапс iOS: callId = confId) —
  /// поэтому это НЕ строковый PK таблицы, а отдельное поле: PK (int)
  /// остаётся внутренним для FK participants.
  String confId;

  /// Комната конференции. Cascade: комната умерла — конференция тоже.
  int roomId;

  DateTime createdAt;

  /// Обновляется при каждом изменении состава (join/leave/prune) —
  /// свипер по нему отличает живую конференцию от брошенной.
  DateTime updatedAt;

  /// Returns a shallow copy of this [Conference]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Conference copyWith({
    int? id,
    String? confId,
    int? roomId,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Conference',
      if (id != null) 'id': id,
      'confId': confId,
      'roomId': roomId,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConferenceImpl extends Conference {
  _ConferenceImpl({
    int? id,
    required String confId,
    required int roomId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         confId: confId,
         roomId: roomId,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Conference]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Conference copyWith({
    Object? id = _Undefined,
    String? confId,
    int? roomId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conference(
      id: id is int? ? id : this.id,
      confId: confId ?? this.confId,
      roomId: roomId ?? this.roomId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
