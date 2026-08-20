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

/// Строка списка поддержки тенанта для админки: кто и с каким тиром по
/// умолчанию наследуется в команды всех продуктов тенанта.
abstract class TenantSupportMemberView implements _i1.SerializableModel {
  TenantSupportMemberView._({
    required this.messengerUserId,
    this.displayName,
    this.avatarUrl,
    required this.tier,
  });

  factory TenantSupportMemberView({
    required int messengerUserId,
    String? displayName,
    String? avatarUrl,
    required int tier,
  }) = _TenantSupportMemberViewImpl;

  factory TenantSupportMemberView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return TenantSupportMemberView(
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      displayName: jsonSerialization['displayName'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      tier: jsonSerialization['tier'] as int,
    );
  }

  int messengerUserId;

  String? displayName;

  String? avatarUrl;

  int tier;

  /// Returns a shallow copy of this [TenantSupportMemberView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TenantSupportMemberView copyWith({
    int? messengerUserId,
    String? displayName,
    String? avatarUrl,
    int? tier,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TenantSupportMemberView',
      'messengerUserId': messengerUserId,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'tier': tier,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TenantSupportMemberViewImpl extends TenantSupportMemberView {
  _TenantSupportMemberViewImpl({
    required int messengerUserId,
    String? displayName,
    String? avatarUrl,
    required int tier,
  }) : super._(
         messengerUserId: messengerUserId,
         displayName: displayName,
         avatarUrl: avatarUrl,
         tier: tier,
       );

  /// Returns a shallow copy of this [TenantSupportMemberView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TenantSupportMemberView copyWith({
    int? messengerUserId,
    Object? displayName = _Undefined,
    Object? avatarUrl = _Undefined,
    int? tier,
  }) {
    return TenantSupportMemberView(
      messengerUserId: messengerUserId ?? this.messengerUserId,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      tier: tier ?? this.tier,
    );
  }
}
