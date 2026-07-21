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

/// **TASK36**: бот не имеет права на запрошенное действие — либо бот
/// дизейблен (`enabled=false`), либо его CSV-capabilities не содержит
/// требуемого grant-а (например `send_messages` для постинга,
/// `manage_room` для room-management).
///
/// Бросается из [BotService.requireCapability] на action-сайтах
/// (sendMessage / createGroup / createDirect / inviteToRoom / kick /
/// role-change). Для людей (botFor==null) сайт ничего не бросает.
///
/// Поле `capability` — какой grant требовался; `enabled` — был ли бот
/// включён. SDK/админ показывает «bot lacks capability X» или «bot
/// disabled».
abstract class BotCapabilityException
    implements _i1.SerializableException, _i1.SerializableModel {
  BotCapabilityException._({
    required this.capability,
    required this.enabled,
  });

  factory BotCapabilityException({
    required String capability,
    required bool enabled,
  }) = _BotCapabilityExceptionImpl;

  factory BotCapabilityException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BotCapabilityException(
      capability: jsonSerialization['capability'] as String,
      enabled: _i1.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
    );
  }

  /// Требуемая capability (`send_messages` / `manage_room` / ...).
  String capability;

  /// `false` если бот дизейблен (kill-switch); `true` если просто нет
  /// нужного grant-а.
  bool enabled;

  /// Returns a shallow copy of this [BotCapabilityException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BotCapabilityException copyWith({
    String? capability,
    bool? enabled,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BotCapabilityException',
      'capability': capability,
      'enabled': enabled,
    };
  }

  @override
  String toString() {
    return 'BotCapabilityException(capability: $capability, enabled: $enabled)';
  }
}

class _BotCapabilityExceptionImpl extends BotCapabilityException {
  _BotCapabilityExceptionImpl({
    required String capability,
    required bool enabled,
  }) : super._(
         capability: capability,
         enabled: enabled,
       );

  /// Returns a shallow copy of this [BotCapabilityException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BotCapabilityException copyWith({
    String? capability,
    bool? enabled,
  }) {
    return BotCapabilityException(
      capability: capability ?? this.capability,
      enabled: enabled ?? this.enabled,
    );
  }
}
