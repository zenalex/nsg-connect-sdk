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
    this.whoCanMessageMe,
    this.showCardsOnCall,
    this.presenceHidden,
  });

  factory NotificationSettings({
    required bool showMessagePreview,
    bool? sendReadReceipts,
    bool? discoverable,
    String? whoCanMessageMe,
    bool? showCardsOnCall,
    bool? presenceHidden,
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
      whoCanMessageMe: jsonSerialization['whoCanMessageMe'] as String?,
      showCardsOnCall: jsonSerialization['showCardsOnCall'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showCardsOnCall'],
            ),
      presenceHidden: jsonSerialization['presenceHidden'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['presenceHidden']),
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

  /// **TASK52 итер.1**: см. doc у `MessengerUser.whoCanMessageMe`
  /// ('everyone' | 'contacts'). Nullable — null на set = «не менять»,
  /// старые клиенты не присылают поле и ничего не ломают.
  String? whoCanMessageMe;

  /// **TASK52 итер.1**: см. doc у `MessengerUser.showCardsOnCall`.
  /// Nullable — те же семантики.
  bool? showCardsOnCall;

  /// **TASK55 итер.3**: см. doc у `MessengerUser.presenceHidden`
  /// (скрыть свой last seen/online; взаимность). Nullable — null на
  /// set = «не менять». Спека называла отдельный `setPresencePrivacy` —
  /// сделано через общий settings-канал (консистентно с остальными
  /// privacy-toggle-ами, меньше поверхности API).
  bool? presenceHidden;

  /// Returns a shallow copy of this [NotificationSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotificationSettings copyWith({
    bool? showMessagePreview,
    bool? sendReadReceipts,
    bool? discoverable,
    String? whoCanMessageMe,
    bool? showCardsOnCall,
    bool? presenceHidden,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NotificationSettings',
      'showMessagePreview': showMessagePreview,
      if (sendReadReceipts != null) 'sendReadReceipts': sendReadReceipts,
      if (discoverable != null) 'discoverable': discoverable,
      if (whoCanMessageMe != null) 'whoCanMessageMe': whoCanMessageMe,
      if (showCardsOnCall != null) 'showCardsOnCall': showCardsOnCall,
      if (presenceHidden != null) 'presenceHidden': presenceHidden,
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
    String? whoCanMessageMe,
    bool? showCardsOnCall,
    bool? presenceHidden,
  }) : super._(
         showMessagePreview: showMessagePreview,
         sendReadReceipts: sendReadReceipts,
         discoverable: discoverable,
         whoCanMessageMe: whoCanMessageMe,
         showCardsOnCall: showCardsOnCall,
         presenceHidden: presenceHidden,
       );

  /// Returns a shallow copy of this [NotificationSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotificationSettings copyWith({
    bool? showMessagePreview,
    Object? sendReadReceipts = _Undefined,
    Object? discoverable = _Undefined,
    Object? whoCanMessageMe = _Undefined,
    Object? showCardsOnCall = _Undefined,
    Object? presenceHidden = _Undefined,
  }) {
    return NotificationSettings(
      showMessagePreview: showMessagePreview ?? this.showMessagePreview,
      sendReadReceipts: sendReadReceipts is bool?
          ? sendReadReceipts
          : this.sendReadReceipts,
      discoverable: discoverable is bool? ? discoverable : this.discoverable,
      whoCanMessageMe: whoCanMessageMe is String?
          ? whoCanMessageMe
          : this.whoCanMessageMe,
      showCardsOnCall: showCardsOnCall is bool?
          ? showCardsOnCall
          : this.showCardsOnCall,
      presenceHidden: presenceHidden is bool?
          ? presenceHidden
          : this.presenceHidden,
    );
  }
}
