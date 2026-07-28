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

/// Продукт тенанта глазами платформенной админки (issue-смежное с TASK78).
/// DTO (без `table:`): экран показывает дерево «тенант → продукт →
/// команда поддержки», и по каждому продукту сразу видно, заведена ли
/// поддержка — иначе «создать команду» приходится тыкать вслепую.
abstract class ProductAdminView implements _i1.SerializableModel {
  ProductAdminView._({
    required this.externalKey,
    required this.displayName,
    required this.hasSupportTeam,
    required this.supportTeamSize,
  });

  factory ProductAdminView({
    required String externalKey,
    required String displayName,
    required bool hasSupportTeam,
    required int supportTeamSize,
  }) = _ProductAdminViewImpl;

  factory ProductAdminView.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProductAdminView(
      externalKey: jsonSerialization['externalKey'] as String,
      displayName: jsonSerialization['displayName'] as String,
      hasSupportTeam: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['hasSupportTeam'],
      ),
      supportTeamSize: jsonSerialization['supportTeamSize'] as int,
    );
  }

  /// Ключ продукта — тот самый productExternalKey из MessengerAuthContext.
  String externalKey;

  String displayName;

  /// Заведена ли команда поддержки этого продукта.
  bool hasSupportTeam;

  /// Сколько человек в команде (0, если команды нет).
  int supportTeamSize;

  /// Returns a shallow copy of this [ProductAdminView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProductAdminView copyWith({
    String? externalKey,
    String? displayName,
    bool? hasSupportTeam,
    int? supportTeamSize,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProductAdminView',
      'externalKey': externalKey,
      'displayName': displayName,
      'hasSupportTeam': hasSupportTeam,
      'supportTeamSize': supportTeamSize,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ProductAdminViewImpl extends ProductAdminView {
  _ProductAdminViewImpl({
    required String externalKey,
    required String displayName,
    required bool hasSupportTeam,
    required int supportTeamSize,
  }) : super._(
         externalKey: externalKey,
         displayName: displayName,
         hasSupportTeam: hasSupportTeam,
         supportTeamSize: supportTeamSize,
       );

  /// Returns a shallow copy of this [ProductAdminView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProductAdminView copyWith({
    String? externalKey,
    String? displayName,
    bool? hasSupportTeam,
    int? supportTeamSize,
  }) {
    return ProductAdminView(
      externalKey: externalKey ?? this.externalKey,
      displayName: displayName ?? this.displayName,
      hasSupportTeam: hasSupportTeam ?? this.hasSupportTeam,
      supportTeamSize: supportTeamSize ?? this.supportTeamSize,
    );
  }
}
