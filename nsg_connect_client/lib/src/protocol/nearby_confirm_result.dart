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

/// **TASK52 итер.2 (чанк 3)**: результат confirmNearby.
///   * matched=false — моя отметка записана, ждём ответного тапа peer-а
///     (в окне 60с). Клиент показывает «пусть тоже нажмёт».
///   * matched=true — взаимно подтверждено (или уже контакты) → взаимный
///     ContactLink установлен; contact*/поля заполнены для открытия чата.
abstract class NearbyConfirmResult implements _i1.SerializableModel {
  NearbyConfirmResult._({
    required this.matched,
    this.contactMessengerUserId,
    this.displayName,
    this.avatarUrl,
  });

  factory NearbyConfirmResult({
    required bool matched,
    int? contactMessengerUserId,
    String? displayName,
    String? avatarUrl,
  }) = _NearbyConfirmResultImpl;

  factory NearbyConfirmResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return NearbyConfirmResult(
      matched: _i1.BoolJsonExtension.fromJson(jsonSerialization['matched']),
      contactMessengerUserId:
          jsonSerialization['contactMessengerUserId'] as int?,
      displayName: jsonSerialization['displayName'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
    );
  }

  bool matched;

  int? contactMessengerUserId;

  String? displayName;

  String? avatarUrl;

  /// Returns a shallow copy of this [NearbyConfirmResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NearbyConfirmResult copyWith({
    bool? matched,
    int? contactMessengerUserId,
    String? displayName,
    String? avatarUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NearbyConfirmResult',
      'matched': matched,
      if (contactMessengerUserId != null)
        'contactMessengerUserId': contactMessengerUserId,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NearbyConfirmResultImpl extends NearbyConfirmResult {
  _NearbyConfirmResultImpl({
    required bool matched,
    int? contactMessengerUserId,
    String? displayName,
    String? avatarUrl,
  }) : super._(
         matched: matched,
         contactMessengerUserId: contactMessengerUserId,
         displayName: displayName,
         avatarUrl: avatarUrl,
       );

  /// Returns a shallow copy of this [NearbyConfirmResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NearbyConfirmResult copyWith({
    bool? matched,
    Object? contactMessengerUserId = _Undefined,
    Object? displayName = _Undefined,
    Object? avatarUrl = _Undefined,
  }) {
    return NearbyConfirmResult(
      matched: matched ?? this.matched,
      contactMessengerUserId: contactMessengerUserId is int?
          ? contactMessengerUserId
          : this.contactMessengerUserId,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
    );
  }
}
