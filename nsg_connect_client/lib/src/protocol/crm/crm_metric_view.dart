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

/// TASK98 A contract; see TASK95 sections 4-7.
abstract class CrmMetricView implements _i1.SerializableModel {
  CrmMetricView._({
    required this.source,
    required this.payloadJson,
    required this.fetchedAt,
    required this.ttl,
  });

  factory CrmMetricView({
    required String source,
    required String payloadJson,
    required DateTime fetchedAt,
    required int ttl,
  }) = _CrmMetricViewImpl;

  factory CrmMetricView.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmMetricView(
      source: jsonSerialization['source'] as String,
      payloadJson: jsonSerialization['payloadJson'] as String,
      fetchedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
      ttl: jsonSerialization['ttl'] as int,
    );
  }

  String source;

  String payloadJson;

  DateTime fetchedAt;

  int ttl;

  /// Returns a shallow copy of this [CrmMetricView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmMetricView copyWith({
    String? source,
    String? payloadJson,
    DateTime? fetchedAt,
    int? ttl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmMetricView',
      'source': source,
      'payloadJson': payloadJson,
      'fetchedAt': fetchedAt.toJson(),
      'ttl': ttl,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CrmMetricViewImpl extends CrmMetricView {
  _CrmMetricViewImpl({
    required String source,
    required String payloadJson,
    required DateTime fetchedAt,
    required int ttl,
  }) : super._(
         source: source,
         payloadJson: payloadJson,
         fetchedAt: fetchedAt,
         ttl: ttl,
       );

  /// Returns a shallow copy of this [CrmMetricView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmMetricView copyWith({
    String? source,
    String? payloadJson,
    DateTime? fetchedAt,
    int? ttl,
  }) {
    return CrmMetricView(
      source: source ?? this.source,
      payloadJson: payloadJson ?? this.payloadJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      ttl: ttl ?? this.ttl,
    );
  }
}
