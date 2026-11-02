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
import '../crm/crm_company_view.dart' as _i2;
import '../crm/crm_deal_view.dart' as _i3;
import '../crm/crm_contact_view.dart' as _i4;
import '../crm/crm_activity_view.dart' as _i5;
import '../crm/crm_document_view.dart' as _i6;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i7;

/// Scoped company card. Related rows retain their own segment scope.
abstract class CrmCompanyDetails implements _i1.SerializableModel {
  CrmCompanyDetails._({
    required this.company,
    required this.deals,
    required this.contacts,
    required this.activities,
    required this.documents,
  });

  factory CrmCompanyDetails({
    required _i2.CrmCompanyView company,
    required List<_i3.CrmDealView> deals,
    required List<_i4.CrmContactView> contacts,
    required List<_i5.CrmActivityView> activities,
    required List<_i6.CrmDocumentView> documents,
  }) = _CrmCompanyDetailsImpl;

  factory CrmCompanyDetails.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmCompanyDetails(
      company: _i7.Protocol().deserialize<_i2.CrmCompanyView>(
        jsonSerialization['company'],
      ),
      deals: _i7.Protocol().deserialize<List<_i3.CrmDealView>>(
        jsonSerialization['deals'],
      ),
      contacts: _i7.Protocol().deserialize<List<_i4.CrmContactView>>(
        jsonSerialization['contacts'],
      ),
      activities: _i7.Protocol().deserialize<List<_i5.CrmActivityView>>(
        jsonSerialization['activities'],
      ),
      documents: _i7.Protocol().deserialize<List<_i6.CrmDocumentView>>(
        jsonSerialization['documents'],
      ),
    );
  }

  _i2.CrmCompanyView company;

  List<_i3.CrmDealView> deals;

  List<_i4.CrmContactView> contacts;

  List<_i5.CrmActivityView> activities;

  List<_i6.CrmDocumentView> documents;

  /// Returns a shallow copy of this [CrmCompanyDetails]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmCompanyDetails copyWith({
    _i2.CrmCompanyView? company,
    List<_i3.CrmDealView>? deals,
    List<_i4.CrmContactView>? contacts,
    List<_i5.CrmActivityView>? activities,
    List<_i6.CrmDocumentView>? documents,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmCompanyDetails',
      'company': company.toJson(),
      'deals': deals.toJson(valueToJson: (v) => v.toJson()),
      'contacts': contacts.toJson(valueToJson: (v) => v.toJson()),
      'activities': activities.toJson(valueToJson: (v) => v.toJson()),
      'documents': documents.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CrmCompanyDetailsImpl extends CrmCompanyDetails {
  _CrmCompanyDetailsImpl({
    required _i2.CrmCompanyView company,
    required List<_i3.CrmDealView> deals,
    required List<_i4.CrmContactView> contacts,
    required List<_i5.CrmActivityView> activities,
    required List<_i6.CrmDocumentView> documents,
  }) : super._(
         company: company,
         deals: deals,
         contacts: contacts,
         activities: activities,
         documents: documents,
       );

  /// Returns a shallow copy of this [CrmCompanyDetails]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmCompanyDetails copyWith({
    _i2.CrmCompanyView? company,
    List<_i3.CrmDealView>? deals,
    List<_i4.CrmContactView>? contacts,
    List<_i5.CrmActivityView>? activities,
    List<_i6.CrmDocumentView>? documents,
  }) {
    return CrmCompanyDetails(
      company: company ?? this.company.copyWith(),
      deals: deals ?? this.deals.map((e0) => e0.copyWith()).toList(),
      contacts: contacts ?? this.contacts.map((e0) => e0.copyWith()).toList(),
      activities:
          activities ?? this.activities.map((e0) => e0.copyWith()).toList(),
      documents:
          documents ?? this.documents.map((e0) => e0.copyWith()).toList(),
    );
  }
}
