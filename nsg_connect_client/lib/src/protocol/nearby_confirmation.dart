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

/// **TASK52 итер.2 (чанк 3)**: отметка «я подтверждаю, что рядом с
/// peer» для BLE-обмена «Рядом». BLE-обнаружение НЕДОВЕРЕННОЕ (любой
/// может вещать любой messengerUserId), поэтому trust даётся только при
/// ВЗАИМНОМ подтверждении в окне ~60с: оба нажали друг на друга →
/// взаимный ContactLink (source=nearby). Одностороннего доверия нет —
/// имперсонатор с чужим id не станет вашим контактом без ответного тапа.
///
/// Строки эфемерны: reciprocal-запрос фильтрует по окну, старые отметки
/// безвредны (чистятся при матче + перезаписью). from/to — plain int.
abstract class NearbyConfirmation implements _i1.SerializableModel {
  NearbyConfirmation._({
    this.id,
    required this.tenantId,
    required this.fromMessengerUserId,
    required this.toMessengerUserId,
    required this.createdAt,
  });

  factory NearbyConfirmation({
    int? id,
    required int tenantId,
    required int fromMessengerUserId,
    required int toMessengerUserId,
    required DateTime createdAt,
  }) = _NearbyConfirmationImpl;

  factory NearbyConfirmation.fromJson(Map<String, dynamic> jsonSerialization) {
    return NearbyConfirmation(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      fromMessengerUserId: jsonSerialization['fromMessengerUserId'] as int,
      toMessengerUserId: jsonSerialization['toMessengerUserId'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int tenantId;

  int fromMessengerUserId;

  int toMessengerUserId;

  DateTime createdAt;

  /// Returns a shallow copy of this [NearbyConfirmation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NearbyConfirmation copyWith({
    int? id,
    int? tenantId,
    int? fromMessengerUserId,
    int? toMessengerUserId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NearbyConfirmation',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'fromMessengerUserId': fromMessengerUserId,
      'toMessengerUserId': toMessengerUserId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NearbyConfirmationImpl extends NearbyConfirmation {
  _NearbyConfirmationImpl({
    int? id,
    required int tenantId,
    required int fromMessengerUserId,
    required int toMessengerUserId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         fromMessengerUserId: fromMessengerUserId,
         toMessengerUserId: toMessengerUserId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [NearbyConfirmation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NearbyConfirmation copyWith({
    Object? id = _Undefined,
    int? tenantId,
    int? fromMessengerUserId,
    int? toMessengerUserId,
    DateTime? createdAt,
  }) {
    return NearbyConfirmation(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      fromMessengerUserId: fromMessengerUserId ?? this.fromMessengerUserId,
      toMessengerUserId: toMessengerUserId ?? this.toMessengerUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
