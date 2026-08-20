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

/// **issue #113**: до какого сообщения пользователь прочитал ТРЕД задачи.
///
/// Горизонт чтения у нас был только комнатный (`room_memberships.lastReadAt`),
/// и по нему нельзя сказать, в какой из задач комнаты появилось новое: все
/// треды делят одну комнату и один счётчик. Просьба оператора — «наклейки на
/// задачах есть, а задач с непрочитанными сообщениями нет» — упирается именно
/// в это.
///
/// Почему своя таблица, а не тредовые квитанции Matrix. Квитанции мы шлём и
/// дальше (в самом треде синеет галочка), но считать по ним непрочитанное
/// значит на каждый список задач ходить в Synapse за состоянием чужого
/// хранилища. Здесь же счёт — один JOIN с `message_index`, где ответы треда
/// уже проиндексированы (`message_index_thread_idx`).
///
/// **Монотонность** как у комнатного горизонта: строка обновляется только
/// вперёд по времени (`lastReadAt`), иначе отставшая квитанция с другого
/// устройства воскрешала бы прочитанное.
abstract class ThreadReadState implements _i1.SerializableModel {
  ThreadReadState._({
    this.id,
    required this.roomId,
    required this.messengerUserId,
    required this.threadRootEventId,
    required this.lastReadEventId,
    required this.lastReadAt,
  });

  factory ThreadReadState({
    int? id,
    required int roomId,
    required int messengerUserId,
    required String threadRootEventId,
    required String lastReadEventId,
    required DateTime lastReadAt,
  }) = _ThreadReadStateImpl;

  factory ThreadReadState.fromJson(Map<String, dynamic> jsonSerialization) {
    return ThreadReadState(
      id: jsonSerialization['id'] as int?,
      roomId: jsonSerialization['roomId'] as int,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      threadRootEventId: jsonSerialization['threadRootEventId'] as String,
      lastReadEventId: jsonSerialization['lastReadEventId'] as String,
      lastReadAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastReadAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int roomId;

  int messengerUserId;

  /// Matrix event id якорного сообщения задачи (корень треда).
  String threadRootEventId;

  String lastReadEventId;

  DateTime lastReadAt;

  /// Returns a shallow copy of this [ThreadReadState]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ThreadReadState copyWith({
    int? id,
    int? roomId,
    int? messengerUserId,
    String? threadRootEventId,
    String? lastReadEventId,
    DateTime? lastReadAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ThreadReadState',
      if (id != null) 'id': id,
      'roomId': roomId,
      'messengerUserId': messengerUserId,
      'threadRootEventId': threadRootEventId,
      'lastReadEventId': lastReadEventId,
      'lastReadAt': lastReadAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ThreadReadStateImpl extends ThreadReadState {
  _ThreadReadStateImpl({
    int? id,
    required int roomId,
    required int messengerUserId,
    required String threadRootEventId,
    required String lastReadEventId,
    required DateTime lastReadAt,
  }) : super._(
         id: id,
         roomId: roomId,
         messengerUserId: messengerUserId,
         threadRootEventId: threadRootEventId,
         lastReadEventId: lastReadEventId,
         lastReadAt: lastReadAt,
       );

  /// Returns a shallow copy of this [ThreadReadState]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ThreadReadState copyWith({
    Object? id = _Undefined,
    int? roomId,
    int? messengerUserId,
    String? threadRootEventId,
    String? lastReadEventId,
    DateTime? lastReadAt,
  }) {
    return ThreadReadState(
      id: id is int? ? id : this.id,
      roomId: roomId ?? this.roomId,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      threadRootEventId: threadRootEventId ?? this.threadRootEventId,
      lastReadEventId: lastReadEventId ?? this.lastReadEventId,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }
}
