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
import 'room_participant.dart' as _i2;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i3;

/// **TASK45 фаза 1 п.5**: одна объектовая комната продукта в каталоге
/// «Объектовые чаты» для члена команды поддержки. Transient DTO (не
/// table), собирается в `ObjectRoomCatalogService.listProductObjectRooms`.
///
/// Каталог показывает ВСЕ объектовые комнаты продукта (entityType=object),
/// включая те, где caller (член команды) ещё НЕ участник — команда NSG не
/// входит в объектовые комнаты по умолчанию (модель «видит-но-не-беспокоит»,
/// см. TASK45 §3.10). Флаг [viewerIsMember] говорит UI, нужен ли join перед
/// открытием.
abstract class ProductObjectRoom implements _i1.SerializableModel {
  ProductObjectRoom._({
    required this.roomId,
    required this.matrixRoomId,
    this.name,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.objectId,
    required this.viewerIsMember,
    required this.participantsPreview,
    required this.totalParticipants,
  });

  factory ProductObjectRoom({
    required int roomId,
    required String matrixRoomId,
    String? name,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    String? objectId,
    required bool viewerIsMember,
    required List<_i2.RoomParticipant> participantsPreview,
    required int totalParticipants,
  }) = _ProductObjectRoomImpl;

  factory ProductObjectRoom.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProductObjectRoom(
      roomId: jsonSerialization['roomId'] as int,
      matrixRoomId: jsonSerialization['matrixRoomId'] as String,
      name: jsonSerialization['name'] as String?,
      lastMessagePreview: jsonSerialization['lastMessagePreview'] as String?,
      lastMessageAt: jsonSerialization['lastMessageAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastMessageAt'],
            ),
      objectId: jsonSerialization['objectId'] as String?,
      viewerIsMember: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['viewerIsMember'],
      ),
      participantsPreview: _i3.Protocol()
          .deserialize<List<_i2.RoomParticipant>>(
            jsonSerialization['participantsPreview'],
          ),
      totalParticipants: jsonSerialization['totalParticipants'] as int,
    );
  }

  int roomId;

  String matrixRoomId;

  /// Имя объекта (Room.name). null → UI показывает fallback.
  String? name;

  /// Превью последнего сообщения (Room.lastMessageBody), обрезано.
  String? lastMessagePreview;

  DateTime? lastMessageAt;

  /// productEntityId (id объекта в titan) — для дедупа/навигации.
  String? objectId;

  /// Является ли текущий caller участником комнаты. false → член команды
  /// видит комнату в каталоге, но должен вызвать joinProductRoom перед
  /// тем как читать/отвечать (вход по запросу).
  bool viewerIsMember;

  /// Превью участников (до 8) — ответственный/куратор/бот. UI рисует
  /// аватарки/имена, чтобы член команды понимал, кто в чате.
  List<_i2.RoomParticipant> participantsPreview;

  /// Общее число участников комнаты.
  int totalParticipants;

  /// Returns a shallow copy of this [ProductObjectRoom]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProductObjectRoom copyWith({
    int? roomId,
    String? matrixRoomId,
    String? name,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    String? objectId,
    bool? viewerIsMember,
    List<_i2.RoomParticipant>? participantsPreview,
    int? totalParticipants,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProductObjectRoom',
      'roomId': roomId,
      'matrixRoomId': matrixRoomId,
      if (name != null) 'name': name,
      if (lastMessagePreview != null) 'lastMessagePreview': lastMessagePreview,
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt?.toJson(),
      if (objectId != null) 'objectId': objectId,
      'viewerIsMember': viewerIsMember,
      'participantsPreview': participantsPreview.toJson(
        valueToJson: (v) => v.toJson(),
      ),
      'totalParticipants': totalParticipants,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProductObjectRoomImpl extends ProductObjectRoom {
  _ProductObjectRoomImpl({
    required int roomId,
    required String matrixRoomId,
    String? name,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    String? objectId,
    required bool viewerIsMember,
    required List<_i2.RoomParticipant> participantsPreview,
    required int totalParticipants,
  }) : super._(
         roomId: roomId,
         matrixRoomId: matrixRoomId,
         name: name,
         lastMessagePreview: lastMessagePreview,
         lastMessageAt: lastMessageAt,
         objectId: objectId,
         viewerIsMember: viewerIsMember,
         participantsPreview: participantsPreview,
         totalParticipants: totalParticipants,
       );

  /// Returns a shallow copy of this [ProductObjectRoom]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProductObjectRoom copyWith({
    int? roomId,
    String? matrixRoomId,
    Object? name = _Undefined,
    Object? lastMessagePreview = _Undefined,
    Object? lastMessageAt = _Undefined,
    Object? objectId = _Undefined,
    bool? viewerIsMember,
    List<_i2.RoomParticipant>? participantsPreview,
    int? totalParticipants,
  }) {
    return ProductObjectRoom(
      roomId: roomId ?? this.roomId,
      matrixRoomId: matrixRoomId ?? this.matrixRoomId,
      name: name is String? ? name : this.name,
      lastMessagePreview: lastMessagePreview is String?
          ? lastMessagePreview
          : this.lastMessagePreview,
      lastMessageAt: lastMessageAt is DateTime?
          ? lastMessageAt
          : this.lastMessageAt,
      objectId: objectId is String? ? objectId : this.objectId,
      viewerIsMember: viewerIsMember ?? this.viewerIsMember,
      participantsPreview:
          participantsPreview ??
          this.participantsPreview.map((e0) => e0.copyWith()).toList(),
      totalParticipants: totalParticipants ?? this.totalParticipants,
    );
  }
}
