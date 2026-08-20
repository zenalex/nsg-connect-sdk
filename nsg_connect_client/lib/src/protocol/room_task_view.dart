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

/// **TASK90**: строка списка задач КОМНАТЫ. Транзиентный DTO (без `table:`),
/// собирается в `TaskService` из `TaskLink` + стадии одноимённого `Ticket`.
///
/// Почему не переиспользован `TicketView`. Его `id` — идентификатор тикета,
/// то есть ОБРАЩЕНИЯ, а у комнаты поддержки оно ровно одно (`UNIQUE roomId`
/// в `tickets`). Задач же в обращении сколько угодно, и подстановка
/// `TaskLink.id` в поле, которое клиент трактует как id тикета, дала бы тап,
/// открывающий чужую запись. Разные сущности — разные DTO.
///
/// Ровно на смешении этих двух сущностей и построен баг TASK90: бейдж в шапке
/// считал задачи (`TaskLink`), а экран listMyTasks(roomId:) показывал
/// обращения (`Ticket`) — «горит 10, внутри одна».
abstract class RoomTaskView implements _i1.SerializableModel {
  RoomTaskView._({
    required this.id,
    required this.roomId,
    required this.externalTaskUrl,
    this.externalTaskKey,
    this.title,
    this.stage,
    required this.anchorEventId,
    int? unreadCount,
    required this.createdAt,
  }) : unreadCount = unreadCount ?? 0;

  factory RoomTaskView({
    required int id,
    required int roomId,
    required String externalTaskUrl,
    String? externalTaskKey,
    String? title,
    String? stage,
    required String anchorEventId,
    int? unreadCount,
    required DateTime createdAt,
  }) = _RoomTaskViewImpl;

  factory RoomTaskView.fromJson(Map<String, dynamic> jsonSerialization) {
    return RoomTaskView(
      id: jsonSerialization['id'] as int,
      roomId: jsonSerialization['roomId'] as int,
      externalTaskUrl: jsonSerialization['externalTaskUrl'] as String,
      externalTaskKey: jsonSerialization['externalTaskKey'] as String?,
      title: jsonSerialization['title'] as String?,
      stage: jsonSerialization['stage'] as String?,
      anchorEventId: jsonSerialization['anchorEventId'] as String,
      unreadCount: jsonSerialization['unreadCount'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// id связи (`TaskLink`), НЕ тикета. Для ключей списка и дедупа на клиенте.
  int id;

  int roomId;

  /// URL issue во внешнем трекере. Он же ключ дедупа: повторная регистрация
  /// той же задачи (ретрай бота) не должна двоить строку.
  String externalTaskUrl;

  /// Человекочитаемый ключ, напр. `#83`. null — URL не распарсился в номер.
  String? externalTaskKey;

  /// Заголовок задачи. null у задач, заведённых до появления поля, — строка
  /// показывает ключ.
  String? title;

  /// Стадия задачи: `new` / `in_progress` / `accepted` / `rejected`.
  ///
  /// **issue #97**: источник — собственное состояние задачи (`TaskLink.stage`),
  /// а тикет остался запасным. Раньше стадию брали ТОЛЬКО из `Ticket` по
  /// `externalTaskUrl`, и это врало: тикет один на комнату (`UNIQUE roomId`) и
  /// указывает лишь на один issue из многих, поэтому все прочие задачи
  /// приходили с `null` — а `null` клиент подписывает «Заведена». Сделанные,
  /// закрытые и отклонённые выглядели одинаково заведёнными.
  ///
  /// `null` теперь значит именно «не знаем»: ни своего состояния, ни тикета.
  /// Так остаётся у строк, заведённых до появления поля и не заполненных из
  /// GitHub. Клиент показывает такую задачу активной — молча прятать её нельзя.
  String? stage;

  /// Сообщение, которым задача заведена: корень треда обсуждения. Строка
  /// списка ведёт в этот тред.
  String anchorEventId;

  /// **issue #113**: непрочитанных ответов в треде задачи — для бейджа рядом
  /// со стадией. Стадия отвечает «что с задачей», а этот счётчик — «есть ли
  /// там новое для меня»; без него задачи приходится открывать по очереди.
  ///
  /// Считается по горизонту чтения ТРЕДА (`thread_read_states`), с откатом на
  /// комнатный для тредов, прочитанных до его появления. Своё не считается.
  int unreadCount;

  DateTime createdAt;

  /// Returns a shallow copy of this [RoomTaskView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomTaskView copyWith({
    int? id,
    int? roomId,
    String? externalTaskUrl,
    String? externalTaskKey,
    String? title,
    String? stage,
    String? anchorEventId,
    int? unreadCount,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomTaskView',
      'id': id,
      'roomId': roomId,
      'externalTaskUrl': externalTaskUrl,
      if (externalTaskKey != null) 'externalTaskKey': externalTaskKey,
      if (title != null) 'title': title,
      if (stage != null) 'stage': stage,
      'anchorEventId': anchorEventId,
      'unreadCount': unreadCount,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoomTaskViewImpl extends RoomTaskView {
  _RoomTaskViewImpl({
    required int id,
    required int roomId,
    required String externalTaskUrl,
    String? externalTaskKey,
    String? title,
    String? stage,
    required String anchorEventId,
    int? unreadCount,
    required DateTime createdAt,
  }) : super._(
         id: id,
         roomId: roomId,
         externalTaskUrl: externalTaskUrl,
         externalTaskKey: externalTaskKey,
         title: title,
         stage: stage,
         anchorEventId: anchorEventId,
         unreadCount: unreadCount,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [RoomTaskView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomTaskView copyWith({
    int? id,
    int? roomId,
    String? externalTaskUrl,
    Object? externalTaskKey = _Undefined,
    Object? title = _Undefined,
    Object? stage = _Undefined,
    String? anchorEventId,
    int? unreadCount,
    DateTime? createdAt,
  }) {
    return RoomTaskView(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      externalTaskUrl: externalTaskUrl ?? this.externalTaskUrl,
      externalTaskKey: externalTaskKey is String?
          ? externalTaskKey
          : this.externalTaskKey,
      title: title is String? ? title : this.title,
      stage: stage is String? ? stage : this.stage,
      anchorEventId: anchorEventId ?? this.anchorEventId,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
