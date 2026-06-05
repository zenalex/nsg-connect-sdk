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
import 'attachment_bytes.dart' as _i2;
import 'attachment_ref.dart' as _i3;
import 'device_registration.dart' as _i4;
import 'email_account.dart' as _i5;
import 'email_session.dart' as _i6;
import 'email_verification_code.dart' as _i7;
import 'enums/device_platform.dart' as _i8;
import 'enums/identity_provider.dart' as _i9;
import 'enums/messenger_event_type.dart' as _i10;
import 'enums/participant_kind.dart' as _i11;
import 'enums/push_service.dart' as _i12;
import 'enums/room_member_role.dart' as _i13;
import 'enums/room_ownership.dart' as _i14;
import 'enums/room_state.dart' as _i15;
import 'enums/room_type.dart' as _i16;
import 'enums/tenant_hosting_mode.dart' as _i17;
import 'errors/adapter_not_configured_exception.dart' as _i18;
import 'errors/email_auth_exception.dart' as _i19;
import 'errors/insufficient_power_exception.dart' as _i20;
import 'errors/invalid_token_exception.dart' as _i21;
import 'errors/last_owner_cannot_demote_exception.dart' as _i22;
import 'errors/message_body_too_large_exception.dart' as _i23;
import 'errors/message_deleted_exception.dart' as _i24;
import 'errors/message_not_editable_exception.dart' as _i25;
import 'errors/messenger_not_authenticated_exception.dart' as _i26;
import 'errors/peer_unavailable_exception.dart' as _i27;
import 'errors/product_not_found_exception.dart' as _i28;
import 'errors/product_not_found_for_caller_exception.dart' as _i29;
import 'errors/rate_limit_exceeded_exception.dart' as _i30;
import 'errors/room_dissolve_partial_exception.dart' as _i31;
import 'errors/room_unavailable_exception.dart' as _i32;
import 'errors/tenant_not_found_exception.dart' as _i33;
import 'greetings/greeting.dart' as _i34;
import 'identity_mapping.dart' as _i35;
import 'messenger_auth_context.dart' as _i36;
import 'messenger_event.dart' as _i37;
import 'messenger_message.dart' as _i38;
import 'messenger_message_list_page.dart' as _i39;
import 'messenger_session.dart' as _i40;
import 'messenger_session_token.dart' as _i41;
import 'messenger_user.dart' as _i42;
import 'notification_settings.dart' as _i43;
import 'presence_state.dart' as _i44;
import 'product.dart' as _i45;
import 'push_queue_message.dart' as _i46;
import 'room.dart' as _i47;
import 'room_details.dart' as _i48;
import 'room_membership.dart' as _i49;
import 'room_participant.dart' as _i50;
import 'room_summary.dart' as _i51;
import 'tenant.dart' as _i52;
import 'package:nsg_connect_client/src/protocol/messenger_event.dart' as _i53;
import 'package:nsg_connect_client/src/protocol/room_participant.dart' as _i54;
import 'package:nsg_connect_client/src/protocol/messenger_message.dart' as _i55;
import 'package:nsg_connect_client/src/protocol/room_summary.dart' as _i56;
import 'package:nsg_connect_client/src/protocol/product.dart' as _i57;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i58;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i59;
export 'attachment_bytes.dart';
export 'attachment_ref.dart';
export 'device_registration.dart';
export 'email_account.dart';
export 'email_session.dart';
export 'email_verification_code.dart';
export 'enums/device_platform.dart';
export 'enums/identity_provider.dart';
export 'enums/messenger_event_type.dart';
export 'enums/participant_kind.dart';
export 'enums/push_service.dart';
export 'enums/room_member_role.dart';
export 'enums/room_ownership.dart';
export 'enums/room_state.dart';
export 'enums/room_type.dart';
export 'enums/tenant_hosting_mode.dart';
export 'errors/adapter_not_configured_exception.dart';
export 'errors/email_auth_exception.dart';
export 'errors/insufficient_power_exception.dart';
export 'errors/invalid_token_exception.dart';
export 'errors/last_owner_cannot_demote_exception.dart';
export 'errors/message_body_too_large_exception.dart';
export 'errors/message_deleted_exception.dart';
export 'errors/message_not_editable_exception.dart';
export 'errors/messenger_not_authenticated_exception.dart';
export 'errors/peer_unavailable_exception.dart';
export 'errors/product_not_found_exception.dart';
export 'errors/product_not_found_for_caller_exception.dart';
export 'errors/rate_limit_exceeded_exception.dart';
export 'errors/room_dissolve_partial_exception.dart';
export 'errors/room_unavailable_exception.dart';
export 'errors/tenant_not_found_exception.dart';
export 'greetings/greeting.dart';
export 'identity_mapping.dart';
export 'messenger_auth_context.dart';
export 'messenger_event.dart';
export 'messenger_message.dart';
export 'messenger_message_list_page.dart';
export 'messenger_session.dart';
export 'messenger_session_token.dart';
export 'messenger_user.dart';
export 'notification_settings.dart';
export 'presence_state.dart';
export 'product.dart';
export 'push_queue_message.dart';
export 'room.dart';
export 'room_details.dart';
export 'room_membership.dart';
export 'room_participant.dart';
export 'room_summary.dart';
export 'tenant.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.AttachmentBytes) {
      return _i2.AttachmentBytes.fromJson(data) as T;
    }
    if (t == _i3.AttachmentRef) {
      return _i3.AttachmentRef.fromJson(data) as T;
    }
    if (t == _i4.DeviceRegistration) {
      return _i4.DeviceRegistration.fromJson(data) as T;
    }
    if (t == _i5.EmailAccount) {
      return _i5.EmailAccount.fromJson(data) as T;
    }
    if (t == _i6.EmailSession) {
      return _i6.EmailSession.fromJson(data) as T;
    }
    if (t == _i7.EmailVerificationCode) {
      return _i7.EmailVerificationCode.fromJson(data) as T;
    }
    if (t == _i8.DevicePlatform) {
      return _i8.DevicePlatform.fromJson(data) as T;
    }
    if (t == _i9.IdentityProvider) {
      return _i9.IdentityProvider.fromJson(data) as T;
    }
    if (t == _i10.MessengerEventType) {
      return _i10.MessengerEventType.fromJson(data) as T;
    }
    if (t == _i11.ParticipantKind) {
      return _i11.ParticipantKind.fromJson(data) as T;
    }
    if (t == _i12.PushService) {
      return _i12.PushService.fromJson(data) as T;
    }
    if (t == _i13.RoomMemberRole) {
      return _i13.RoomMemberRole.fromJson(data) as T;
    }
    if (t == _i14.RoomOwnership) {
      return _i14.RoomOwnership.fromJson(data) as T;
    }
    if (t == _i15.RoomState) {
      return _i15.RoomState.fromJson(data) as T;
    }
    if (t == _i16.RoomType) {
      return _i16.RoomType.fromJson(data) as T;
    }
    if (t == _i17.TenantHostingMode) {
      return _i17.TenantHostingMode.fromJson(data) as T;
    }
    if (t == _i18.AdapterNotConfiguredException) {
      return _i18.AdapterNotConfiguredException.fromJson(data) as T;
    }
    if (t == _i19.EmailAuthException) {
      return _i19.EmailAuthException.fromJson(data) as T;
    }
    if (t == _i20.InsufficientPowerException) {
      return _i20.InsufficientPowerException.fromJson(data) as T;
    }
    if (t == _i21.InvalidTokenException) {
      return _i21.InvalidTokenException.fromJson(data) as T;
    }
    if (t == _i22.LastOwnerCannotDemoteException) {
      return _i22.LastOwnerCannotDemoteException.fromJson(data) as T;
    }
    if (t == _i23.MessageBodyTooLargeException) {
      return _i23.MessageBodyTooLargeException.fromJson(data) as T;
    }
    if (t == _i24.MessageDeletedException) {
      return _i24.MessageDeletedException.fromJson(data) as T;
    }
    if (t == _i25.MessageNotEditableException) {
      return _i25.MessageNotEditableException.fromJson(data) as T;
    }
    if (t == _i26.MessengerNotAuthenticatedException) {
      return _i26.MessengerNotAuthenticatedException.fromJson(data) as T;
    }
    if (t == _i27.PeerUnavailableException) {
      return _i27.PeerUnavailableException.fromJson(data) as T;
    }
    if (t == _i28.ProductNotFoundException) {
      return _i28.ProductNotFoundException.fromJson(data) as T;
    }
    if (t == _i29.ProductNotFoundForCallerException) {
      return _i29.ProductNotFoundForCallerException.fromJson(data) as T;
    }
    if (t == _i30.RateLimitExceededException) {
      return _i30.RateLimitExceededException.fromJson(data) as T;
    }
    if (t == _i31.RoomDissolvePartialException) {
      return _i31.RoomDissolvePartialException.fromJson(data) as T;
    }
    if (t == _i32.RoomUnavailableException) {
      return _i32.RoomUnavailableException.fromJson(data) as T;
    }
    if (t == _i33.TenantNotFoundException) {
      return _i33.TenantNotFoundException.fromJson(data) as T;
    }
    if (t == _i34.Greeting) {
      return _i34.Greeting.fromJson(data) as T;
    }
    if (t == _i35.IdentityMapping) {
      return _i35.IdentityMapping.fromJson(data) as T;
    }
    if (t == _i36.MessengerAuthContext) {
      return _i36.MessengerAuthContext.fromJson(data) as T;
    }
    if (t == _i37.MessengerEvent) {
      return _i37.MessengerEvent.fromJson(data) as T;
    }
    if (t == _i38.MessengerMessage) {
      return _i38.MessengerMessage.fromJson(data) as T;
    }
    if (t == _i39.MessengerMessageListPage) {
      return _i39.MessengerMessageListPage.fromJson(data) as T;
    }
    if (t == _i40.MessengerSession) {
      return _i40.MessengerSession.fromJson(data) as T;
    }
    if (t == _i41.MessengerSessionToken) {
      return _i41.MessengerSessionToken.fromJson(data) as T;
    }
    if (t == _i42.MessengerUser) {
      return _i42.MessengerUser.fromJson(data) as T;
    }
    if (t == _i43.NotificationSettings) {
      return _i43.NotificationSettings.fromJson(data) as T;
    }
    if (t == _i44.PresenceState) {
      return _i44.PresenceState.fromJson(data) as T;
    }
    if (t == _i45.Product) {
      return _i45.Product.fromJson(data) as T;
    }
    if (t == _i46.PushQueueMessage) {
      return _i46.PushQueueMessage.fromJson(data) as T;
    }
    if (t == _i47.Room) {
      return _i47.Room.fromJson(data) as T;
    }
    if (t == _i48.RoomDetails) {
      return _i48.RoomDetails.fromJson(data) as T;
    }
    if (t == _i49.RoomMembership) {
      return _i49.RoomMembership.fromJson(data) as T;
    }
    if (t == _i50.RoomParticipant) {
      return _i50.RoomParticipant.fromJson(data) as T;
    }
    if (t == _i51.RoomSummary) {
      return _i51.RoomSummary.fromJson(data) as T;
    }
    if (t == _i52.Tenant) {
      return _i52.Tenant.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AttachmentBytes?>()) {
      return (data != null ? _i2.AttachmentBytes.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AttachmentRef?>()) {
      return (data != null ? _i3.AttachmentRef.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.DeviceRegistration?>()) {
      return (data != null ? _i4.DeviceRegistration.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.EmailAccount?>()) {
      return (data != null ? _i5.EmailAccount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.EmailSession?>()) {
      return (data != null ? _i6.EmailSession.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.EmailVerificationCode?>()) {
      return (data != null ? _i7.EmailVerificationCode.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.DevicePlatform?>()) {
      return (data != null ? _i8.DevicePlatform.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.IdentityProvider?>()) {
      return (data != null ? _i9.IdentityProvider.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.MessengerEventType?>()) {
      return (data != null ? _i10.MessengerEventType.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.ParticipantKind?>()) {
      return (data != null ? _i11.ParticipantKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.PushService?>()) {
      return (data != null ? _i12.PushService.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.RoomMemberRole?>()) {
      return (data != null ? _i13.RoomMemberRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.RoomOwnership?>()) {
      return (data != null ? _i14.RoomOwnership.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.RoomState?>()) {
      return (data != null ? _i15.RoomState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.RoomType?>()) {
      return (data != null ? _i16.RoomType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.TenantHostingMode?>()) {
      return (data != null ? _i17.TenantHostingMode.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.AdapterNotConfiguredException?>()) {
      return (data != null
              ? _i18.AdapterNotConfiguredException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i19.EmailAuthException?>()) {
      return (data != null ? _i19.EmailAuthException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i20.InsufficientPowerException?>()) {
      return (data != null
              ? _i20.InsufficientPowerException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i21.InvalidTokenException?>()) {
      return (data != null ? _i21.InvalidTokenException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i22.LastOwnerCannotDemoteException?>()) {
      return (data != null
              ? _i22.LastOwnerCannotDemoteException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i23.MessageBodyTooLargeException?>()) {
      return (data != null
              ? _i23.MessageBodyTooLargeException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i24.MessageDeletedException?>()) {
      return (data != null ? _i24.MessageDeletedException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i25.MessageNotEditableException?>()) {
      return (data != null
              ? _i25.MessageNotEditableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i26.MessengerNotAuthenticatedException?>()) {
      return (data != null
              ? _i26.MessengerNotAuthenticatedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i27.PeerUnavailableException?>()) {
      return (data != null
              ? _i27.PeerUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i28.ProductNotFoundException?>()) {
      return (data != null
              ? _i28.ProductNotFoundException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i29.ProductNotFoundForCallerException?>()) {
      return (data != null
              ? _i29.ProductNotFoundForCallerException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i30.RateLimitExceededException?>()) {
      return (data != null
              ? _i30.RateLimitExceededException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i31.RoomDissolvePartialException?>()) {
      return (data != null
              ? _i31.RoomDissolvePartialException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i32.RoomUnavailableException?>()) {
      return (data != null
              ? _i32.RoomUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i33.TenantNotFoundException?>()) {
      return (data != null ? _i33.TenantNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i34.Greeting?>()) {
      return (data != null ? _i34.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i35.IdentityMapping?>()) {
      return (data != null ? _i35.IdentityMapping.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i36.MessengerAuthContext?>()) {
      return (data != null ? _i36.MessengerAuthContext.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i37.MessengerEvent?>()) {
      return (data != null ? _i37.MessengerEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i38.MessengerMessage?>()) {
      return (data != null ? _i38.MessengerMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i39.MessengerMessageListPage?>()) {
      return (data != null
              ? _i39.MessengerMessageListPage.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i40.MessengerSession?>()) {
      return (data != null ? _i40.MessengerSession.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i41.MessengerSessionToken?>()) {
      return (data != null ? _i41.MessengerSessionToken.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i42.MessengerUser?>()) {
      return (data != null ? _i42.MessengerUser.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i43.NotificationSettings?>()) {
      return (data != null ? _i43.NotificationSettings.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i44.PresenceState?>()) {
      return (data != null ? _i44.PresenceState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i45.Product?>()) {
      return (data != null ? _i45.Product.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i46.PushQueueMessage?>()) {
      return (data != null ? _i46.PushQueueMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i47.Room?>()) {
      return (data != null ? _i47.Room.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i48.RoomDetails?>()) {
      return (data != null ? _i48.RoomDetails.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i49.RoomMembership?>()) {
      return (data != null ? _i49.RoomMembership.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i50.RoomParticipant?>()) {
      return (data != null ? _i50.RoomParticipant.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i51.RoomSummary?>()) {
      return (data != null ? _i51.RoomSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i52.Tenant?>()) {
      return (data != null ? _i52.Tenant.fromJson(data) : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == _i1.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i38.MessengerMessage>) {
      return (data as List)
              .map((e) => deserialize<_i38.MessengerMessage>(e))
              .toList()
          as T;
    }
    if (t == List<_i50.RoomParticipant>) {
      return (data as List)
              .map((e) => deserialize<_i50.RoomParticipant>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == _i1.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i53.MessengerEvent>) {
      return (data as List)
              .map((e) => deserialize<_i53.MessengerEvent>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i54.RoomParticipant>) {
      return (data as List)
              .map((e) => deserialize<_i54.RoomParticipant>(e))
              .toList()
          as T;
    }
    if (t == List<_i55.MessengerMessage>) {
      return (data as List)
              .map((e) => deserialize<_i55.MessengerMessage>(e))
              .toList()
          as T;
    }
    if (t == List<_i56.RoomSummary>) {
      return (data as List)
              .map((e) => deserialize<_i56.RoomSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i57.Product>) {
      return (data as List).map((e) => deserialize<_i57.Product>(e)).toList()
          as T;
    }
    try {
      return _i58.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i59.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AttachmentBytes => 'AttachmentBytes',
      _i3.AttachmentRef => 'AttachmentRef',
      _i4.DeviceRegistration => 'DeviceRegistration',
      _i5.EmailAccount => 'EmailAccount',
      _i6.EmailSession => 'EmailSession',
      _i7.EmailVerificationCode => 'EmailVerificationCode',
      _i8.DevicePlatform => 'DevicePlatform',
      _i9.IdentityProvider => 'IdentityProvider',
      _i10.MessengerEventType => 'MessengerEventType',
      _i11.ParticipantKind => 'ParticipantKind',
      _i12.PushService => 'PushService',
      _i13.RoomMemberRole => 'RoomMemberRole',
      _i14.RoomOwnership => 'RoomOwnership',
      _i15.RoomState => 'RoomState',
      _i16.RoomType => 'RoomType',
      _i17.TenantHostingMode => 'TenantHostingMode',
      _i18.AdapterNotConfiguredException => 'AdapterNotConfiguredException',
      _i19.EmailAuthException => 'EmailAuthException',
      _i20.InsufficientPowerException => 'InsufficientPowerException',
      _i21.InvalidTokenException => 'InvalidTokenException',
      _i22.LastOwnerCannotDemoteException => 'LastOwnerCannotDemoteException',
      _i23.MessageBodyTooLargeException => 'MessageBodyTooLargeException',
      _i24.MessageDeletedException => 'MessageDeletedException',
      _i25.MessageNotEditableException => 'MessageNotEditableException',
      _i26.MessengerNotAuthenticatedException =>
        'MessengerNotAuthenticatedException',
      _i27.PeerUnavailableException => 'PeerUnavailableException',
      _i28.ProductNotFoundException => 'ProductNotFoundException',
      _i29.ProductNotFoundForCallerException =>
        'ProductNotFoundForCallerException',
      _i30.RateLimitExceededException => 'RateLimitExceededException',
      _i31.RoomDissolvePartialException => 'RoomDissolvePartialException',
      _i32.RoomUnavailableException => 'RoomUnavailableException',
      _i33.TenantNotFoundException => 'TenantNotFoundException',
      _i34.Greeting => 'Greeting',
      _i35.IdentityMapping => 'IdentityMapping',
      _i36.MessengerAuthContext => 'MessengerAuthContext',
      _i37.MessengerEvent => 'MessengerEvent',
      _i38.MessengerMessage => 'MessengerMessage',
      _i39.MessengerMessageListPage => 'MessengerMessageListPage',
      _i40.MessengerSession => 'MessengerSession',
      _i41.MessengerSessionToken => 'MessengerSessionToken',
      _i42.MessengerUser => 'MessengerUser',
      _i43.NotificationSettings => 'NotificationSettings',
      _i44.PresenceState => 'PresenceState',
      _i45.Product => 'Product',
      _i46.PushQueueMessage => 'PushQueueMessage',
      _i47.Room => 'Room',
      _i48.RoomDetails => 'RoomDetails',
      _i49.RoomMembership => 'RoomMembership',
      _i50.RoomParticipant => 'RoomParticipant',
      _i51.RoomSummary => 'RoomSummary',
      _i52.Tenant => 'Tenant',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('nsg_connect.', '');
    }

    switch (data) {
      case _i2.AttachmentBytes():
        return 'AttachmentBytes';
      case _i3.AttachmentRef():
        return 'AttachmentRef';
      case _i4.DeviceRegistration():
        return 'DeviceRegistration';
      case _i5.EmailAccount():
        return 'EmailAccount';
      case _i6.EmailSession():
        return 'EmailSession';
      case _i7.EmailVerificationCode():
        return 'EmailVerificationCode';
      case _i8.DevicePlatform():
        return 'DevicePlatform';
      case _i9.IdentityProvider():
        return 'IdentityProvider';
      case _i10.MessengerEventType():
        return 'MessengerEventType';
      case _i11.ParticipantKind():
        return 'ParticipantKind';
      case _i12.PushService():
        return 'PushService';
      case _i13.RoomMemberRole():
        return 'RoomMemberRole';
      case _i14.RoomOwnership():
        return 'RoomOwnership';
      case _i15.RoomState():
        return 'RoomState';
      case _i16.RoomType():
        return 'RoomType';
      case _i17.TenantHostingMode():
        return 'TenantHostingMode';
      case _i18.AdapterNotConfiguredException():
        return 'AdapterNotConfiguredException';
      case _i19.EmailAuthException():
        return 'EmailAuthException';
      case _i20.InsufficientPowerException():
        return 'InsufficientPowerException';
      case _i21.InvalidTokenException():
        return 'InvalidTokenException';
      case _i22.LastOwnerCannotDemoteException():
        return 'LastOwnerCannotDemoteException';
      case _i23.MessageBodyTooLargeException():
        return 'MessageBodyTooLargeException';
      case _i24.MessageDeletedException():
        return 'MessageDeletedException';
      case _i25.MessageNotEditableException():
        return 'MessageNotEditableException';
      case _i26.MessengerNotAuthenticatedException():
        return 'MessengerNotAuthenticatedException';
      case _i27.PeerUnavailableException():
        return 'PeerUnavailableException';
      case _i28.ProductNotFoundException():
        return 'ProductNotFoundException';
      case _i29.ProductNotFoundForCallerException():
        return 'ProductNotFoundForCallerException';
      case _i30.RateLimitExceededException():
        return 'RateLimitExceededException';
      case _i31.RoomDissolvePartialException():
        return 'RoomDissolvePartialException';
      case _i32.RoomUnavailableException():
        return 'RoomUnavailableException';
      case _i33.TenantNotFoundException():
        return 'TenantNotFoundException';
      case _i34.Greeting():
        return 'Greeting';
      case _i35.IdentityMapping():
        return 'IdentityMapping';
      case _i36.MessengerAuthContext():
        return 'MessengerAuthContext';
      case _i37.MessengerEvent():
        return 'MessengerEvent';
      case _i38.MessengerMessage():
        return 'MessengerMessage';
      case _i39.MessengerMessageListPage():
        return 'MessengerMessageListPage';
      case _i40.MessengerSession():
        return 'MessengerSession';
      case _i41.MessengerSessionToken():
        return 'MessengerSessionToken';
      case _i42.MessengerUser():
        return 'MessengerUser';
      case _i43.NotificationSettings():
        return 'NotificationSettings';
      case _i44.PresenceState():
        return 'PresenceState';
      case _i45.Product():
        return 'Product';
      case _i46.PushQueueMessage():
        return 'PushQueueMessage';
      case _i47.Room():
        return 'Room';
      case _i48.RoomDetails():
        return 'RoomDetails';
      case _i49.RoomMembership():
        return 'RoomMembership';
      case _i50.RoomParticipant():
        return 'RoomParticipant';
      case _i51.RoomSummary():
        return 'RoomSummary';
      case _i52.Tenant():
        return 'Tenant';
    }
    className = _i58.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i59.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AttachmentBytes') {
      return deserialize<_i2.AttachmentBytes>(data['data']);
    }
    if (dataClassName == 'AttachmentRef') {
      return deserialize<_i3.AttachmentRef>(data['data']);
    }
    if (dataClassName == 'DeviceRegistration') {
      return deserialize<_i4.DeviceRegistration>(data['data']);
    }
    if (dataClassName == 'EmailAccount') {
      return deserialize<_i5.EmailAccount>(data['data']);
    }
    if (dataClassName == 'EmailSession') {
      return deserialize<_i6.EmailSession>(data['data']);
    }
    if (dataClassName == 'EmailVerificationCode') {
      return deserialize<_i7.EmailVerificationCode>(data['data']);
    }
    if (dataClassName == 'DevicePlatform') {
      return deserialize<_i8.DevicePlatform>(data['data']);
    }
    if (dataClassName == 'IdentityProvider') {
      return deserialize<_i9.IdentityProvider>(data['data']);
    }
    if (dataClassName == 'MessengerEventType') {
      return deserialize<_i10.MessengerEventType>(data['data']);
    }
    if (dataClassName == 'ParticipantKind') {
      return deserialize<_i11.ParticipantKind>(data['data']);
    }
    if (dataClassName == 'PushService') {
      return deserialize<_i12.PushService>(data['data']);
    }
    if (dataClassName == 'RoomMemberRole') {
      return deserialize<_i13.RoomMemberRole>(data['data']);
    }
    if (dataClassName == 'RoomOwnership') {
      return deserialize<_i14.RoomOwnership>(data['data']);
    }
    if (dataClassName == 'RoomState') {
      return deserialize<_i15.RoomState>(data['data']);
    }
    if (dataClassName == 'RoomType') {
      return deserialize<_i16.RoomType>(data['data']);
    }
    if (dataClassName == 'TenantHostingMode') {
      return deserialize<_i17.TenantHostingMode>(data['data']);
    }
    if (dataClassName == 'AdapterNotConfiguredException') {
      return deserialize<_i18.AdapterNotConfiguredException>(data['data']);
    }
    if (dataClassName == 'EmailAuthException') {
      return deserialize<_i19.EmailAuthException>(data['data']);
    }
    if (dataClassName == 'InsufficientPowerException') {
      return deserialize<_i20.InsufficientPowerException>(data['data']);
    }
    if (dataClassName == 'InvalidTokenException') {
      return deserialize<_i21.InvalidTokenException>(data['data']);
    }
    if (dataClassName == 'LastOwnerCannotDemoteException') {
      return deserialize<_i22.LastOwnerCannotDemoteException>(data['data']);
    }
    if (dataClassName == 'MessageBodyTooLargeException') {
      return deserialize<_i23.MessageBodyTooLargeException>(data['data']);
    }
    if (dataClassName == 'MessageDeletedException') {
      return deserialize<_i24.MessageDeletedException>(data['data']);
    }
    if (dataClassName == 'MessageNotEditableException') {
      return deserialize<_i25.MessageNotEditableException>(data['data']);
    }
    if (dataClassName == 'MessengerNotAuthenticatedException') {
      return deserialize<_i26.MessengerNotAuthenticatedException>(data['data']);
    }
    if (dataClassName == 'PeerUnavailableException') {
      return deserialize<_i27.PeerUnavailableException>(data['data']);
    }
    if (dataClassName == 'ProductNotFoundException') {
      return deserialize<_i28.ProductNotFoundException>(data['data']);
    }
    if (dataClassName == 'ProductNotFoundForCallerException') {
      return deserialize<_i29.ProductNotFoundForCallerException>(data['data']);
    }
    if (dataClassName == 'RateLimitExceededException') {
      return deserialize<_i30.RateLimitExceededException>(data['data']);
    }
    if (dataClassName == 'RoomDissolvePartialException') {
      return deserialize<_i31.RoomDissolvePartialException>(data['data']);
    }
    if (dataClassName == 'RoomUnavailableException') {
      return deserialize<_i32.RoomUnavailableException>(data['data']);
    }
    if (dataClassName == 'TenantNotFoundException') {
      return deserialize<_i33.TenantNotFoundException>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i34.Greeting>(data['data']);
    }
    if (dataClassName == 'IdentityMapping') {
      return deserialize<_i35.IdentityMapping>(data['data']);
    }
    if (dataClassName == 'MessengerAuthContext') {
      return deserialize<_i36.MessengerAuthContext>(data['data']);
    }
    if (dataClassName == 'MessengerEvent') {
      return deserialize<_i37.MessengerEvent>(data['data']);
    }
    if (dataClassName == 'MessengerMessage') {
      return deserialize<_i38.MessengerMessage>(data['data']);
    }
    if (dataClassName == 'MessengerMessageListPage') {
      return deserialize<_i39.MessengerMessageListPage>(data['data']);
    }
    if (dataClassName == 'MessengerSession') {
      return deserialize<_i40.MessengerSession>(data['data']);
    }
    if (dataClassName == 'MessengerSessionToken') {
      return deserialize<_i41.MessengerSessionToken>(data['data']);
    }
    if (dataClassName == 'MessengerUser') {
      return deserialize<_i42.MessengerUser>(data['data']);
    }
    if (dataClassName == 'NotificationSettings') {
      return deserialize<_i43.NotificationSettings>(data['data']);
    }
    if (dataClassName == 'PresenceState') {
      return deserialize<_i44.PresenceState>(data['data']);
    }
    if (dataClassName == 'Product') {
      return deserialize<_i45.Product>(data['data']);
    }
    if (dataClassName == 'PushQueueMessage') {
      return deserialize<_i46.PushQueueMessage>(data['data']);
    }
    if (dataClassName == 'Room') {
      return deserialize<_i47.Room>(data['data']);
    }
    if (dataClassName == 'RoomDetails') {
      return deserialize<_i48.RoomDetails>(data['data']);
    }
    if (dataClassName == 'RoomMembership') {
      return deserialize<_i49.RoomMembership>(data['data']);
    }
    if (dataClassName == 'RoomParticipant') {
      return deserialize<_i50.RoomParticipant>(data['data']);
    }
    if (dataClassName == 'RoomSummary') {
      return deserialize<_i51.RoomSummary>(data['data']);
    }
    if (dataClassName == 'Tenant') {
      return deserialize<_i52.Tenant>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i58.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i59.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i58.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i59.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
