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

/// **TASK57 фаза 1**: событие тикета — лента прогресса обращения. `type`:
/// `created` / `linked` / `comment` / `closed` / `reopened`. `actor` — кто
/// инициировал (для GitHub-событий — github login). `body` — текст комментария
/// (для type=comment).
abstract class TicketEvent implements _i1.SerializableModel {
  TicketEvent._({
    this.id,
    required this.ticketId,
    required this.type,
    this.actor,
    this.body,
    required this.createdAt,
  });

  factory TicketEvent({
    int? id,
    required int ticketId,
    required String type,
    String? actor,
    String? body,
    required DateTime createdAt,
  }) = _TicketEventImpl;

  factory TicketEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return TicketEvent(
      id: jsonSerialization['id'] as int?,
      ticketId: jsonSerialization['ticketId'] as int,
      type: jsonSerialization['type'] as String,
      actor: jsonSerialization['actor'] as String?,
      body: jsonSerialization['body'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int ticketId;

  String type;

  String? actor;

  String? body;

  DateTime createdAt;

  /// Returns a shallow copy of this [TicketEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TicketEvent copyWith({
    int? id,
    int? ticketId,
    String? type,
    String? actor,
    String? body,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TicketEvent',
      if (id != null) 'id': id,
      'ticketId': ticketId,
      'type': type,
      if (actor != null) 'actor': actor,
      if (body != null) 'body': body,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TicketEventImpl extends TicketEvent {
  _TicketEventImpl({
    int? id,
    required int ticketId,
    required String type,
    String? actor,
    String? body,
    required DateTime createdAt,
  }) : super._(
         id: id,
         ticketId: ticketId,
         type: type,
         actor: actor,
         body: body,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [TicketEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TicketEvent copyWith({
    Object? id = _Undefined,
    int? ticketId,
    String? type,
    Object? actor = _Undefined,
    Object? body = _Undefined,
    DateTime? createdAt,
  }) {
    return TicketEvent(
      id: id is int? ? id : this.id,
      ticketId: ticketId ?? this.ticketId,
      type: type ?? this.type,
      actor: actor is String? ? actor : this.actor,
      body: body is String? ? body : this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
