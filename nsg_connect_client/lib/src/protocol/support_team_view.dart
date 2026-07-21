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
import 'support_team_member_view.dart' as _i2;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i3;

/// **TASK43**: команда поддержки продукта для SDK-экрана «Команда
/// поддержки» и для RPC бота (список operator-MUID). Transient DTO,
/// собирается в `SupportTeamService.getTeamView`.
///
/// Доступ к getSupportTeam гейтится: view отдаётся только участникам
/// команды (людям и боту). Не-участник получает типизированное
/// [NotSupportTeamMemberException] — SDK по нему скрывает экран.
abstract class SupportTeamView implements _i1.SerializableModel {
  SupportTeamView._({
    required this.teamId,
    required this.productExternalKey,
    required this.members,
    required this.viewerIsOwner,
    required this.escalationTimeoutMinutes,
  });

  factory SupportTeamView({
    required int teamId,
    required String productExternalKey,
    required List<_i2.SupportTeamMemberView> members,
    required bool viewerIsOwner,
    required int escalationTimeoutMinutes,
  }) = _SupportTeamViewImpl;

  factory SupportTeamView.fromJson(Map<String, dynamic> jsonSerialization) {
    return SupportTeamView(
      teamId: jsonSerialization['teamId'] as int,
      productExternalKey: jsonSerialization['productExternalKey'] as String,
      members: _i3.Protocol().deserialize<List<_i2.SupportTeamMemberView>>(
        jsonSerialization['members'],
      ),
      viewerIsOwner: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['viewerIsOwner'],
      ),
      escalationTimeoutMinutes:
          jsonSerialization['escalationTimeoutMinutes'] as int,
    );
  }

  int teamId;

  String productExternalKey;

  /// Все участники (люди + бот), owner-ы первыми.
  List<_i2.SupportTeamMemberView> members;

  /// Может ли текущий caller управлять составом (он owner). SDK по
  /// этому флагу показывает/прячет кнопки «добавить»/«удалить».
  bool viewerIsOwner;

  /// **TASK48 iter2**: текущий порог авто-эскалации команды в минутах
  /// (`SupportTeam.escalationTimeoutMinutes`). UI показывает и (owner)
  /// даёт править. Дефолт 60.
  int escalationTimeoutMinutes;

  /// Returns a shallow copy of this [SupportTeamView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SupportTeamView copyWith({
    int? teamId,
    String? productExternalKey,
    List<_i2.SupportTeamMemberView>? members,
    bool? viewerIsOwner,
    int? escalationTimeoutMinutes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SupportTeamView',
      'teamId': teamId,
      'productExternalKey': productExternalKey,
      'members': members.toJson(valueToJson: (v) => v.toJson()),
      'viewerIsOwner': viewerIsOwner,
      'escalationTimeoutMinutes': escalationTimeoutMinutes,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SupportTeamViewImpl extends SupportTeamView {
  _SupportTeamViewImpl({
    required int teamId,
    required String productExternalKey,
    required List<_i2.SupportTeamMemberView> members,
    required bool viewerIsOwner,
    required int escalationTimeoutMinutes,
  }) : super._(
         teamId: teamId,
         productExternalKey: productExternalKey,
         members: members,
         viewerIsOwner: viewerIsOwner,
         escalationTimeoutMinutes: escalationTimeoutMinutes,
       );

  /// Returns a shallow copy of this [SupportTeamView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SupportTeamView copyWith({
    int? teamId,
    String? productExternalKey,
    List<_i2.SupportTeamMemberView>? members,
    bool? viewerIsOwner,
    int? escalationTimeoutMinutes,
  }) {
    return SupportTeamView(
      teamId: teamId ?? this.teamId,
      productExternalKey: productExternalKey ?? this.productExternalKey,
      members: members ?? this.members.map((e0) => e0.copyWith()).toList(),
      viewerIsOwner: viewerIsOwner ?? this.viewerIsOwner,
      escalationTimeoutMinutes:
          escalationTimeoutMinutes ?? this.escalationTimeoutMinutes,
    );
  }
}
