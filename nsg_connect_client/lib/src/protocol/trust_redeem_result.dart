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

/// **TASK52 итер.2 (чанк 3)**: результат redeemTrustToken — с кем теперь
/// взаимный контакт (для открытия direct-чата / интро-карточки).
/// Публичные поля issuer-а вложены, чтобы не делать второй round-trip.
abstract class TrustRedeemResult implements _i1.SerializableModel {
  TrustRedeemResult._({
    required this.contactMessengerUserId,
    this.displayName,
    this.avatarUrl,
  });

  factory TrustRedeemResult({
    required int contactMessengerUserId,
    String? displayName,
    String? avatarUrl,
  }) = _TrustRedeemResultImpl;

  factory TrustRedeemResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return TrustRedeemResult(
      contactMessengerUserId:
          jsonSerialization['contactMessengerUserId'] as int,
      displayName: jsonSerialization['displayName'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
    );
  }

  int contactMessengerUserId;

  String? displayName;

  String? avatarUrl;

  /// Returns a shallow copy of this [TrustRedeemResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TrustRedeemResult copyWith({
    int? contactMessengerUserId,
    String? displayName,
    String? avatarUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TrustRedeemResult',
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

class _TrustRedeemResultImpl extends TrustRedeemResult {
  _TrustRedeemResultImpl({
    required int contactMessengerUserId,
    String? displayName,
    String? avatarUrl,
  }) : super._(
         contactMessengerUserId: contactMessengerUserId,
         displayName: displayName,
         avatarUrl: avatarUrl,
       );

  /// Returns a shallow copy of this [TrustRedeemResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TrustRedeemResult copyWith({
    int? contactMessengerUserId,
    Object? displayName = _Undefined,
    Object? avatarUrl = _Undefined,
  }) {
    return TrustRedeemResult(
      contactMessengerUserId:
          contactMessengerUserId ?? this.contactMessengerUserId,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
    );
  }
}
