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

/// **TASK52 итер.2 (чанк 3)**: результат issueTrustToken — что отдаём
/// клиенту для QR/ссылки. Внутренние поля TrustToken (tenant/useCount)
/// наружу не течут.
abstract class TrustTokenIssued implements _i1.SerializableModel {
  TrustTokenIssued._({
    required this.token,
    required this.expiresAt,
  });

  factory TrustTokenIssued({
    required String token,
    required DateTime expiresAt,
  }) = _TrustTokenIssuedImpl;

  factory TrustTokenIssued.fromJson(Map<String, dynamic> jsonSerialization) {
    return TrustTokenIssued(
      token: jsonSerialization['token'] as String,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  String token;

  DateTime expiresAt;

  /// Returns a shallow copy of this [TrustTokenIssued]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TrustTokenIssued copyWith({
    String? token,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TrustTokenIssued',
      'token': token,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TrustTokenIssuedImpl extends TrustTokenIssued {
  _TrustTokenIssuedImpl({
    required String token,
    required DateTime expiresAt,
  }) : super._(
         token: token,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [TrustTokenIssued]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TrustTokenIssued copyWith({
    String? token,
    DateTime? expiresAt,
  }) {
    return TrustTokenIssued(
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
