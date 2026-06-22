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

/// **TASK20-Phase2 Chunk 4**: per-user notification settings DTO.
/// Возвращается из `getNotificationSettings`, передаётся в
/// `setNotificationSettings`. Wrapper над несколькими полями
/// `MessengerUser` чтобы:
///
///   * SDK получал immutable snapshot за один RPC, не дёргая
///     `MessengerUser` напрямую (privacy: matrixAccessTokenEncrypted
///     никогда не должен ехать на client).
///   * Phase3 expansion (DnD hours / sound / vibrate / per-room
///     toggles) — добавляются в этот DTO без breaking changes к
///     существующим settings call.
abstract class NotificationSettings implements _i1.SerializableModel {
  NotificationSettings._({
    required this.showMessagePreview,
    this.sendReadReceipts,
    this.discoverable,
  });

  factory NotificationSettings({
    required bool showMessagePreview,
    bool? sendReadReceipts,
    bool? discoverable,
  }) = _NotificationSettingsImpl;

  factory NotificationSettings.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return NotificationSettings(
      showMessagePreview: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['showMessagePreview'],
      ),
      sendReadReceipts: jsonSerialization['sendReadReceipts'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['sendReadReceipts'],
            ),
      discoverable: jsonSerialization['discoverable'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['discoverable']),
    );
  }

  /// См. doc у `MessengerUser.showMessagePreview`.
  bool showMessagePreview;

  /// **B11**: см. doc у `MessengerUser.sendReadReceipts`. Nullable —
  /// backward-compat: старый клиент не присылает поле на set → сервер
  /// трактует null как «не менять» (оставляет текущее значение).
  bool? sendReadReceipts;

  /// **Settings (Профиль и Настройки)**: приватность — можно ли найти
  /// юзера в поиске (`searchUsers` + чужой `findUserByEmail`). См. doc
  /// у `MessengerUser.discoverable`. Nullable — те же backward-compat
  /// семантики (null на set = «не менять»).
  bool? discoverable;

  /// Returns a shallow copy of this [NotificationSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotificationSettings copyWith({
    bool? showMessagePreview,
    bool? sendReadReceipts,
    bool? discoverable,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NotificationSettings',
      'showMessagePreview': showMessagePreview,
      if (sendReadReceipts != null) 'sendReadReceipts': sendReadReceipts,
      if (discoverable != null) 'discoverable': discoverable,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NotificationSettingsImpl extends NotificationSettings {
  _NotificationSettingsImpl({
    required bool showMessagePreview,
    bool? sendReadReceipts,
    bool? discoverable,
  }) : super._(
         showMessagePreview: showMessagePreview,
         sendReadReceipts: sendReadReceipts,
         discoverable: discoverable,
       );

  /// Returns a shallow copy of this [NotificationSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotificationSettings copyWith({
    bool? showMessagePreview,
    Object? sendReadReceipts = _Undefined,
    Object? discoverable = _Undefined,
  }) {
    return NotificationSettings(
      showMessagePreview: showMessagePreview ?? this.showMessagePreview,
      sendReadReceipts: sendReadReceipts is bool?
          ? sendReadReceipts
          : this.sendReadReceipts,
      discoverable: discoverable is bool? ? discoverable : this.discoverable,
    );
  }
}
