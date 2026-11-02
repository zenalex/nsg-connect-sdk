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
import '../crm/crm_deal_view.dart' as _i2;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i3;

/// Stable keyset cursor; authorization is reevaluated for every page.
abstract class CrmDealPage implements _i1.SerializableModel {
  CrmDealPage._({
    required this.items,
    this.nextCursor,
  });

  factory CrmDealPage({
    required List<_i2.CrmDealView> items,
    String? nextCursor,
  }) = _CrmDealPageImpl;

  factory CrmDealPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmDealPage(
      items: _i3.Protocol().deserialize<List<_i2.CrmDealView>>(
        jsonSerialization['items'],
      ),
      nextCursor: jsonSerialization['nextCursor'] as String?,
    );
  }

  List<_i2.CrmDealView> items;

  String? nextCursor;

  /// Returns a shallow copy of this [CrmDealPage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmDealPage copyWith({
    List<_i2.CrmDealView>? items,
    String? nextCursor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmDealPage',
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      if (nextCursor != null) 'nextCursor': nextCursor,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CrmDealPageImpl extends CrmDealPage {
  _CrmDealPageImpl({
    required List<_i2.CrmDealView> items,
    String? nextCursor,
  }) : super._(
         items: items,
         nextCursor: nextCursor,
       );

  /// Returns a shallow copy of this [CrmDealPage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmDealPage copyWith({
    List<_i2.CrmDealView>? items,
    Object? nextCursor = _Undefined,
  }) {
    return CrmDealPage(
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      nextCursor: nextCursor is String? ? nextCursor : this.nextCursor,
    );
  }
}
