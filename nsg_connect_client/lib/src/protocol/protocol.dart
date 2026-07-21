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
import 'bot.dart' as _i4;
import 'bot_audit_event.dart' as _i5;
import 'bot_integration_created.dart' as _i6;
import 'bot_integration_view.dart' as _i7;
import 'call_history_entry.dart' as _i8;
import 'call_ice_candidate.dart' as _i9;
import 'chat_folder.dart' as _i10;
import 'chat_folder_room.dart' as _i11;
import 'chat_folder_view.dart' as _i12;
import 'connect_issued_token.dart' as _i13;
import 'connect_issued_token_result.dart' as _i14;
import 'connect_key_audit_event.dart' as _i15;
import 'connect_tenant_status.dart' as _i16;
import 'contact_block.dart' as _i17;
import 'contact_card.dart' as _i18;
import 'contact_card_info.dart' as _i19;
import 'contact_label.dart' as _i20;
import 'contact_label_assignment.dart' as _i21;
import 'contact_link.dart' as _i22;
import 'contact_meta.dart' as _i23;
import 'contact_profile_view.dart' as _i24;
import 'contact_relation.dart' as _i25;
import 'contact_request.dart' as _i26;
import 'contact_request_view.dart' as _i27;
import 'device_registration.dart' as _i28;
import 'device_session_info.dart' as _i29;
import 'email_account.dart' as _i30;
import 'email_session.dart' as _i31;
import 'email_verification_code.dart' as _i32;
import 'enums/call_event_type.dart' as _i33;
import 'enums/call_status.dart' as _i34;
import 'enums/contact_link_source.dart' as _i35;
import 'enums/contact_request_status.dart' as _i36;
import 'enums/device_platform.dart' as _i37;
import 'enums/identity_provider.dart' as _i38;
import 'enums/messenger_event_type.dart' as _i39;
import 'enums/participant_kind.dart' as _i40;
import 'enums/product_notification_status.dart' as _i41;
import 'enums/push_service.dart' as _i42;
import 'enums/room_member_role.dart' as _i43;
import 'enums/room_ownership.dart' as _i44;
import 'enums/room_state.dart' as _i45;
import 'enums/room_type.dart' as _i46;
import 'enums/support_team_role.dart' as _i47;
import 'enums/tenant_hosting_mode.dart' as _i48;
import 'enums/trust_token_kind.dart' as _i49;
import 'errors/adapter_not_configured_exception.dart' as _i50;
import 'errors/bot_capability_exception.dart' as _i51;
import 'errors/bot_limit_exceeded_exception.dart' as _i52;
import 'errors/bot_not_found_exception.dart' as _i53;
import 'errors/email_auth_exception.dart' as _i54;
import 'errors/insufficient_power_exception.dart' as _i55;
import 'errors/invalid_notification_exception.dart' as _i56;
import 'errors/invalid_token_exception.dart' as _i57;
import 'errors/last_owner_cannot_demote_exception.dart' as _i58;
import 'errors/message_body_too_large_exception.dart' as _i59;
import 'errors/message_deleted_exception.dart' as _i60;
import 'errors/message_not_editable_exception.dart' as _i61;
import 'errors/messenger_not_authenticated_exception.dart' as _i62;
import 'errors/not_object_room_exception.dart' as _i63;
import 'errors/not_support_team_member_exception.dart' as _i64;
import 'errors/not_support_team_owner_exception.dart' as _i65;
import 'errors/peer_unavailable_exception.dart' as _i66;
import 'errors/product_not_found_exception.dart' as _i67;
import 'errors/product_not_found_for_caller_exception.dart' as _i68;
import 'errors/rate_limit_exceeded_exception.dart' as _i69;
import 'errors/room_dissolve_partial_exception.dart' as _i70;
import 'errors/room_unavailable_exception.dart' as _i71;
import 'errors/task_integration_not_configured_exception.dart' as _i72;
import 'errors/tenant_not_found_exception.dart' as _i73;
import 'errors/write_banned_exception.dart' as _i74;
import 'escalation_result.dart' as _i75;
import 'greetings/greeting.dart' as _i76;
import 'identity_mapping.dart' as _i77;
import 'incoming_webhook.dart' as _i78;
import 'incoming_webhook_created.dart' as _i79;
import 'message_index.dart' as _i80;
import 'messenger_auth_context.dart' as _i81;
import 'messenger_event.dart' as _i82;
import 'messenger_message.dart' as _i83;
import 'messenger_message_list_page.dart' as _i84;
import 'messenger_session.dart' as _i85;
import 'messenger_session_token.dart' as _i86;
import 'messenger_user.dart' as _i87;
import 'nearby_confirm_result.dart' as _i88;
import 'nearby_confirmation.dart' as _i89;
import 'notification_settings.dart' as _i90;
import 'presence_conn_state.dart' as _i91;
import 'presence_info.dart' as _i92;
import 'presence_state.dart' as _i93;
import 'presence_watched_index.dart' as _i94;
import 'presence_watchers.dart' as _i95;
import 'product.dart' as _i96;
import 'product_notification.dart' as _i97;
import 'product_notification_recipient_result.dart' as _i98;
import 'product_notification_send_result.dart' as _i99;
import 'product_object_room.dart' as _i100;
import 'profile_translation.dart' as _i101;
import 'pulse_alert_rule.dart' as _i102;
import 'pulse_event.dart' as _i103;
import 'pulse_folder.dart' as _i104;
import 'pulse_incident.dart' as _i105;
import 'pulse_monitor.dart' as _i106;
import 'pulse_monitor_created.dart' as _i107;
import 'push_queue_message.dart' as _i108;
import 'push_test_job.dart' as _i109;
import 'push_test_result.dart' as _i110;
import 'room.dart' as _i111;
import 'room_details.dart' as _i112;
import 'room_list_page.dart' as _i113;
import 'room_membership.dart' as _i114;
import 'room_participant.dart' as _i115;
import 'room_summary.dart' as _i116;
import 'support_team.dart' as _i117;
import 'support_team_member.dart' as _i118;
import 'support_team_member_view.dart' as _i119;
import 'support_team_view.dart' as _i120;
import 'task_link.dart' as _i121;
import 'task_manager_config.dart' as _i122;
import 'tenant.dart' as _i123;
import 'ticket.dart' as _i124;
import 'ticket_event.dart' as _i125;
import 'ticket_view.dart' as _i126;
import 'trust_redeem_result.dart' as _i127;
import 'trust_token.dart' as _i128;
import 'trust_token_issued.dart' as _i129;
import 'turn_credentials.dart' as _i130;
import 'webhook_delivery.dart' as _i131;
import 'webhook_event_message.dart' as _i132;
import 'webhook_subscription.dart' as _i133;
import 'package:nsg_connect_client/src/protocol/webhook_subscription.dart'
    as _i134;
import 'package:nsg_connect_client/src/protocol/webhook_delivery.dart' as _i135;
import 'package:nsg_connect_client/src/protocol/bot_audit_event.dart' as _i136;
import 'package:nsg_connect_client/src/protocol/bot.dart' as _i137;
import 'package:nsg_connect_client/src/protocol/room_summary.dart' as _i138;
import 'package:nsg_connect_client/src/protocol/bot_integration_view.dart'
    as _i139;
import 'package:nsg_connect_client/src/protocol/connect_tenant_status.dart'
    as _i140;
import 'package:nsg_connect_client/src/protocol/connect_key_audit_event.dart'
    as _i141;
import 'package:nsg_connect_client/src/protocol/device_session_info.dart'
    as _i142;
import 'package:nsg_connect_client/src/protocol/incoming_webhook.dart' as _i143;
import 'package:nsg_connect_client/src/protocol/messenger_message.dart'
    as _i144;
import 'package:nsg_connect_client/src/protocol/call_ice_candidate.dart'
    as _i145;
import 'package:nsg_connect_client/src/protocol/call_history_entry.dart'
    as _i146;
import 'package:nsg_connect_client/src/protocol/messenger_event.dart' as _i147;
import 'package:nsg_connect_client/src/protocol/room_participant.dart' as _i148;
import 'package:nsg_connect_client/src/protocol/ticket_view.dart' as _i149;
import 'package:nsg_connect_client/src/protocol/presence_info.dart' as _i150;
import 'package:nsg_connect_client/src/protocol/chat_folder_view.dart' as _i151;
import 'package:nsg_connect_client/src/protocol/contact_request_view.dart'
    as _i152;
import 'package:nsg_connect_client/src/protocol/contact_label.dart' as _i153;
import 'package:nsg_connect_client/src/protocol/contact_label_assignment.dart'
    as _i154;
import 'package:nsg_connect_client/src/protocol/product_object_room.dart'
    as _i155;
import 'package:nsg_connect_client/src/protocol/product.dart' as _i156;
import 'package:nsg_connect_client/src/protocol/profile_translation.dart'
    as _i157;
import 'package:nsg_connect_client/src/protocol/pulse_folder.dart' as _i158;
import 'package:nsg_connect_client/src/protocol/pulse_monitor.dart' as _i159;
import 'package:nsg_connect_client/src/protocol/pulse_alert_rule.dart' as _i160;
import 'package:nsg_connect_client/src/protocol/pulse_incident.dart' as _i161;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i162;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i163;
export 'attachment_bytes.dart';
export 'attachment_ref.dart';
export 'bot.dart';
export 'bot_audit_event.dart';
export 'bot_integration_created.dart';
export 'bot_integration_view.dart';
export 'call_history_entry.dart';
export 'call_ice_candidate.dart';
export 'chat_folder.dart';
export 'chat_folder_room.dart';
export 'chat_folder_view.dart';
export 'connect_issued_token.dart';
export 'connect_issued_token_result.dart';
export 'connect_key_audit_event.dart';
export 'connect_tenant_status.dart';
export 'contact_block.dart';
export 'contact_card.dart';
export 'contact_card_info.dart';
export 'contact_label.dart';
export 'contact_label_assignment.dart';
export 'contact_link.dart';
export 'contact_meta.dart';
export 'contact_profile_view.dart';
export 'contact_relation.dart';
export 'contact_request.dart';
export 'contact_request_view.dart';
export 'device_registration.dart';
export 'device_session_info.dart';
export 'email_account.dart';
export 'email_session.dart';
export 'email_verification_code.dart';
export 'enums/call_event_type.dart';
export 'enums/call_status.dart';
export 'enums/contact_link_source.dart';
export 'enums/contact_request_status.dart';
export 'enums/device_platform.dart';
export 'enums/identity_provider.dart';
export 'enums/messenger_event_type.dart';
export 'enums/participant_kind.dart';
export 'enums/product_notification_status.dart';
export 'enums/push_service.dart';
export 'enums/room_member_role.dart';
export 'enums/room_ownership.dart';
export 'enums/room_state.dart';
export 'enums/room_type.dart';
export 'enums/support_team_role.dart';
export 'enums/tenant_hosting_mode.dart';
export 'enums/trust_token_kind.dart';
export 'errors/adapter_not_configured_exception.dart';
export 'errors/bot_capability_exception.dart';
export 'errors/bot_limit_exceeded_exception.dart';
export 'errors/bot_not_found_exception.dart';
export 'errors/email_auth_exception.dart';
export 'errors/insufficient_power_exception.dart';
export 'errors/invalid_notification_exception.dart';
export 'errors/invalid_token_exception.dart';
export 'errors/last_owner_cannot_demote_exception.dart';
export 'errors/message_body_too_large_exception.dart';
export 'errors/message_deleted_exception.dart';
export 'errors/message_not_editable_exception.dart';
export 'errors/messenger_not_authenticated_exception.dart';
export 'errors/not_object_room_exception.dart';
export 'errors/not_support_team_member_exception.dart';
export 'errors/not_support_team_owner_exception.dart';
export 'errors/peer_unavailable_exception.dart';
export 'errors/product_not_found_exception.dart';
export 'errors/product_not_found_for_caller_exception.dart';
export 'errors/rate_limit_exceeded_exception.dart';
export 'errors/room_dissolve_partial_exception.dart';
export 'errors/room_unavailable_exception.dart';
export 'errors/task_integration_not_configured_exception.dart';
export 'errors/tenant_not_found_exception.dart';
export 'errors/write_banned_exception.dart';
export 'escalation_result.dart';
export 'greetings/greeting.dart';
export 'identity_mapping.dart';
export 'incoming_webhook.dart';
export 'incoming_webhook_created.dart';
export 'message_index.dart';
export 'messenger_auth_context.dart';
export 'messenger_event.dart';
export 'messenger_message.dart';
export 'messenger_message_list_page.dart';
export 'messenger_session.dart';
export 'messenger_session_token.dart';
export 'messenger_user.dart';
export 'nearby_confirm_result.dart';
export 'nearby_confirmation.dart';
export 'notification_settings.dart';
export 'presence_conn_state.dart';
export 'presence_info.dart';
export 'presence_state.dart';
export 'presence_watched_index.dart';
export 'presence_watchers.dart';
export 'product.dart';
export 'product_notification.dart';
export 'product_notification_recipient_result.dart';
export 'product_notification_send_result.dart';
export 'product_object_room.dart';
export 'profile_translation.dart';
export 'pulse_alert_rule.dart';
export 'pulse_event.dart';
export 'pulse_folder.dart';
export 'pulse_incident.dart';
export 'pulse_monitor.dart';
export 'pulse_monitor_created.dart';
export 'push_queue_message.dart';
export 'push_test_job.dart';
export 'push_test_result.dart';
export 'room.dart';
export 'room_details.dart';
export 'room_list_page.dart';
export 'room_membership.dart';
export 'room_participant.dart';
export 'room_summary.dart';
export 'support_team.dart';
export 'support_team_member.dart';
export 'support_team_member_view.dart';
export 'support_team_view.dart';
export 'task_link.dart';
export 'task_manager_config.dart';
export 'tenant.dart';
export 'ticket.dart';
export 'ticket_event.dart';
export 'ticket_view.dart';
export 'trust_redeem_result.dart';
export 'trust_token.dart';
export 'trust_token_issued.dart';
export 'turn_credentials.dart';
export 'webhook_delivery.dart';
export 'webhook_event_message.dart';
export 'webhook_subscription.dart';
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
    if (t == _i4.Bot) {
      return _i4.Bot.fromJson(data) as T;
    }
    if (t == _i5.BotAuditEvent) {
      return _i5.BotAuditEvent.fromJson(data) as T;
    }
    if (t == _i6.BotIntegrationCreated) {
      return _i6.BotIntegrationCreated.fromJson(data) as T;
    }
    if (t == _i7.BotIntegrationView) {
      return _i7.BotIntegrationView.fromJson(data) as T;
    }
    if (t == _i8.CallHistoryEntry) {
      return _i8.CallHistoryEntry.fromJson(data) as T;
    }
    if (t == _i9.CallIceCandidate) {
      return _i9.CallIceCandidate.fromJson(data) as T;
    }
    if (t == _i10.ChatFolderRecord) {
      return _i10.ChatFolderRecord.fromJson(data) as T;
    }
    if (t == _i11.ChatFolderRoom) {
      return _i11.ChatFolderRoom.fromJson(data) as T;
    }
    if (t == _i12.ChatFolderView) {
      return _i12.ChatFolderView.fromJson(data) as T;
    }
    if (t == _i13.ConnectIssuedToken) {
      return _i13.ConnectIssuedToken.fromJson(data) as T;
    }
    if (t == _i14.ConnectIssuedTokenResult) {
      return _i14.ConnectIssuedTokenResult.fromJson(data) as T;
    }
    if (t == _i15.ConnectKeyAuditEvent) {
      return _i15.ConnectKeyAuditEvent.fromJson(data) as T;
    }
    if (t == _i16.ConnectTenantStatus) {
      return _i16.ConnectTenantStatus.fromJson(data) as T;
    }
    if (t == _i17.ContactBlock) {
      return _i17.ContactBlock.fromJson(data) as T;
    }
    if (t == _i18.ContactCard) {
      return _i18.ContactCard.fromJson(data) as T;
    }
    if (t == _i19.ContactCardInfo) {
      return _i19.ContactCardInfo.fromJson(data) as T;
    }
    if (t == _i20.ContactLabel) {
      return _i20.ContactLabel.fromJson(data) as T;
    }
    if (t == _i21.ContactLabelAssignment) {
      return _i21.ContactLabelAssignment.fromJson(data) as T;
    }
    if (t == _i22.ContactLink) {
      return _i22.ContactLink.fromJson(data) as T;
    }
    if (t == _i23.ContactMeta) {
      return _i23.ContactMeta.fromJson(data) as T;
    }
    if (t == _i24.ContactProfileView) {
      return _i24.ContactProfileView.fromJson(data) as T;
    }
    if (t == _i25.ContactRelation) {
      return _i25.ContactRelation.fromJson(data) as T;
    }
    if (t == _i26.ContactRequest) {
      return _i26.ContactRequest.fromJson(data) as T;
    }
    if (t == _i27.ContactRequestView) {
      return _i27.ContactRequestView.fromJson(data) as T;
    }
    if (t == _i28.DeviceRegistration) {
      return _i28.DeviceRegistration.fromJson(data) as T;
    }
    if (t == _i29.DeviceSessionInfo) {
      return _i29.DeviceSessionInfo.fromJson(data) as T;
    }
    if (t == _i30.EmailAccount) {
      return _i30.EmailAccount.fromJson(data) as T;
    }
    if (t == _i31.EmailSession) {
      return _i31.EmailSession.fromJson(data) as T;
    }
    if (t == _i32.EmailVerificationCode) {
      return _i32.EmailVerificationCode.fromJson(data) as T;
    }
    if (t == _i33.CallEventType) {
      return _i33.CallEventType.fromJson(data) as T;
    }
    if (t == _i34.CallStatus) {
      return _i34.CallStatus.fromJson(data) as T;
    }
    if (t == _i35.ContactLinkSource) {
      return _i35.ContactLinkSource.fromJson(data) as T;
    }
    if (t == _i36.ContactRequestStatus) {
      return _i36.ContactRequestStatus.fromJson(data) as T;
    }
    if (t == _i37.DevicePlatform) {
      return _i37.DevicePlatform.fromJson(data) as T;
    }
    if (t == _i38.IdentityProvider) {
      return _i38.IdentityProvider.fromJson(data) as T;
    }
    if (t == _i39.MessengerEventType) {
      return _i39.MessengerEventType.fromJson(data) as T;
    }
    if (t == _i40.ParticipantKind) {
      return _i40.ParticipantKind.fromJson(data) as T;
    }
    if (t == _i41.ProductNotificationStatus) {
      return _i41.ProductNotificationStatus.fromJson(data) as T;
    }
    if (t == _i42.PushService) {
      return _i42.PushService.fromJson(data) as T;
    }
    if (t == _i43.RoomMemberRole) {
      return _i43.RoomMemberRole.fromJson(data) as T;
    }
    if (t == _i44.RoomOwnership) {
      return _i44.RoomOwnership.fromJson(data) as T;
    }
    if (t == _i45.RoomState) {
      return _i45.RoomState.fromJson(data) as T;
    }
    if (t == _i46.RoomType) {
      return _i46.RoomType.fromJson(data) as T;
    }
    if (t == _i47.SupportTeamRole) {
      return _i47.SupportTeamRole.fromJson(data) as T;
    }
    if (t == _i48.TenantHostingMode) {
      return _i48.TenantHostingMode.fromJson(data) as T;
    }
    if (t == _i49.TrustTokenKind) {
      return _i49.TrustTokenKind.fromJson(data) as T;
    }
    if (t == _i50.AdapterNotConfiguredException) {
      return _i50.AdapterNotConfiguredException.fromJson(data) as T;
    }
    if (t == _i51.BotCapabilityException) {
      return _i51.BotCapabilityException.fromJson(data) as T;
    }
    if (t == _i52.BotLimitExceededException) {
      return _i52.BotLimitExceededException.fromJson(data) as T;
    }
    if (t == _i53.BotNotFoundException) {
      return _i53.BotNotFoundException.fromJson(data) as T;
    }
    if (t == _i54.EmailAuthException) {
      return _i54.EmailAuthException.fromJson(data) as T;
    }
    if (t == _i55.InsufficientPowerException) {
      return _i55.InsufficientPowerException.fromJson(data) as T;
    }
    if (t == _i56.InvalidNotificationException) {
      return _i56.InvalidNotificationException.fromJson(data) as T;
    }
    if (t == _i57.InvalidTokenException) {
      return _i57.InvalidTokenException.fromJson(data) as T;
    }
    if (t == _i58.LastOwnerCannotDemoteException) {
      return _i58.LastOwnerCannotDemoteException.fromJson(data) as T;
    }
    if (t == _i59.MessageBodyTooLargeException) {
      return _i59.MessageBodyTooLargeException.fromJson(data) as T;
    }
    if (t == _i60.MessageDeletedException) {
      return _i60.MessageDeletedException.fromJson(data) as T;
    }
    if (t == _i61.MessageNotEditableException) {
      return _i61.MessageNotEditableException.fromJson(data) as T;
    }
    if (t == _i62.MessengerNotAuthenticatedException) {
      return _i62.MessengerNotAuthenticatedException.fromJson(data) as T;
    }
    if (t == _i63.NotObjectRoomException) {
      return _i63.NotObjectRoomException.fromJson(data) as T;
    }
    if (t == _i64.NotSupportTeamMemberException) {
      return _i64.NotSupportTeamMemberException.fromJson(data) as T;
    }
    if (t == _i65.NotSupportTeamOwnerException) {
      return _i65.NotSupportTeamOwnerException.fromJson(data) as T;
    }
    if (t == _i66.PeerUnavailableException) {
      return _i66.PeerUnavailableException.fromJson(data) as T;
    }
    if (t == _i67.ProductNotFoundException) {
      return _i67.ProductNotFoundException.fromJson(data) as T;
    }
    if (t == _i68.ProductNotFoundForCallerException) {
      return _i68.ProductNotFoundForCallerException.fromJson(data) as T;
    }
    if (t == _i69.RateLimitExceededException) {
      return _i69.RateLimitExceededException.fromJson(data) as T;
    }
    if (t == _i70.RoomDissolvePartialException) {
      return _i70.RoomDissolvePartialException.fromJson(data) as T;
    }
    if (t == _i71.RoomUnavailableException) {
      return _i71.RoomUnavailableException.fromJson(data) as T;
    }
    if (t == _i72.TaskIntegrationNotConfiguredException) {
      return _i72.TaskIntegrationNotConfiguredException.fromJson(data) as T;
    }
    if (t == _i73.TenantNotFoundException) {
      return _i73.TenantNotFoundException.fromJson(data) as T;
    }
    if (t == _i74.WriteBannedException) {
      return _i74.WriteBannedException.fromJson(data) as T;
    }
    if (t == _i75.EscalationResult) {
      return _i75.EscalationResult.fromJson(data) as T;
    }
    if (t == _i76.Greeting) {
      return _i76.Greeting.fromJson(data) as T;
    }
    if (t == _i77.IdentityMapping) {
      return _i77.IdentityMapping.fromJson(data) as T;
    }
    if (t == _i78.IncomingWebhook) {
      return _i78.IncomingWebhook.fromJson(data) as T;
    }
    if (t == _i79.IncomingWebhookCreated) {
      return _i79.IncomingWebhookCreated.fromJson(data) as T;
    }
    if (t == _i80.MessageIndex) {
      return _i80.MessageIndex.fromJson(data) as T;
    }
    if (t == _i81.MessengerAuthContext) {
      return _i81.MessengerAuthContext.fromJson(data) as T;
    }
    if (t == _i82.MessengerEvent) {
      return _i82.MessengerEvent.fromJson(data) as T;
    }
    if (t == _i83.MessengerMessage) {
      return _i83.MessengerMessage.fromJson(data) as T;
    }
    if (t == _i84.MessengerMessageListPage) {
      return _i84.MessengerMessageListPage.fromJson(data) as T;
    }
    if (t == _i85.MessengerSession) {
      return _i85.MessengerSession.fromJson(data) as T;
    }
    if (t == _i86.MessengerSessionToken) {
      return _i86.MessengerSessionToken.fromJson(data) as T;
    }
    if (t == _i87.MessengerUser) {
      return _i87.MessengerUser.fromJson(data) as T;
    }
    if (t == _i88.NearbyConfirmResult) {
      return _i88.NearbyConfirmResult.fromJson(data) as T;
    }
    if (t == _i89.NearbyConfirmation) {
      return _i89.NearbyConfirmation.fromJson(data) as T;
    }
    if (t == _i90.NotificationSettings) {
      return _i90.NotificationSettings.fromJson(data) as T;
    }
    if (t == _i91.PresenceConnState) {
      return _i91.PresenceConnState.fromJson(data) as T;
    }
    if (t == _i92.PresenceInfo) {
      return _i92.PresenceInfo.fromJson(data) as T;
    }
    if (t == _i93.PresenceState) {
      return _i93.PresenceState.fromJson(data) as T;
    }
    if (t == _i94.PresenceWatchedIndex) {
      return _i94.PresenceWatchedIndex.fromJson(data) as T;
    }
    if (t == _i95.PresenceWatchers) {
      return _i95.PresenceWatchers.fromJson(data) as T;
    }
    if (t == _i96.Product) {
      return _i96.Product.fromJson(data) as T;
    }
    if (t == _i97.ProductNotification) {
      return _i97.ProductNotification.fromJson(data) as T;
    }
    if (t == _i98.ProductNotificationRecipientResult) {
      return _i98.ProductNotificationRecipientResult.fromJson(data) as T;
    }
    if (t == _i99.ProductNotificationSendResult) {
      return _i99.ProductNotificationSendResult.fromJson(data) as T;
    }
    if (t == _i100.ProductObjectRoom) {
      return _i100.ProductObjectRoom.fromJson(data) as T;
    }
    if (t == _i101.ProfileTranslation) {
      return _i101.ProfileTranslation.fromJson(data) as T;
    }
    if (t == _i102.PulseAlertRule) {
      return _i102.PulseAlertRule.fromJson(data) as T;
    }
    if (t == _i103.PulseEvent) {
      return _i103.PulseEvent.fromJson(data) as T;
    }
    if (t == _i104.PulseFolder) {
      return _i104.PulseFolder.fromJson(data) as T;
    }
    if (t == _i105.PulseIncident) {
      return _i105.PulseIncident.fromJson(data) as T;
    }
    if (t == _i106.PulseMonitor) {
      return _i106.PulseMonitor.fromJson(data) as T;
    }
    if (t == _i107.PulseMonitorCreated) {
      return _i107.PulseMonitorCreated.fromJson(data) as T;
    }
    if (t == _i108.PushQueueMessage) {
      return _i108.PushQueueMessage.fromJson(data) as T;
    }
    if (t == _i109.PushTestJob) {
      return _i109.PushTestJob.fromJson(data) as T;
    }
    if (t == _i110.PushTestResult) {
      return _i110.PushTestResult.fromJson(data) as T;
    }
    if (t == _i111.Room) {
      return _i111.Room.fromJson(data) as T;
    }
    if (t == _i112.RoomDetails) {
      return _i112.RoomDetails.fromJson(data) as T;
    }
    if (t == _i113.RoomListPage) {
      return _i113.RoomListPage.fromJson(data) as T;
    }
    if (t == _i114.RoomMembership) {
      return _i114.RoomMembership.fromJson(data) as T;
    }
    if (t == _i115.RoomParticipant) {
      return _i115.RoomParticipant.fromJson(data) as T;
    }
    if (t == _i116.RoomSummary) {
      return _i116.RoomSummary.fromJson(data) as T;
    }
    if (t == _i117.SupportTeam) {
      return _i117.SupportTeam.fromJson(data) as T;
    }
    if (t == _i118.SupportTeamMember) {
      return _i118.SupportTeamMember.fromJson(data) as T;
    }
    if (t == _i119.SupportTeamMemberView) {
      return _i119.SupportTeamMemberView.fromJson(data) as T;
    }
    if (t == _i120.SupportTeamView) {
      return _i120.SupportTeamView.fromJson(data) as T;
    }
    if (t == _i121.TaskLink) {
      return _i121.TaskLink.fromJson(data) as T;
    }
    if (t == _i122.TaskManagerConfig) {
      return _i122.TaskManagerConfig.fromJson(data) as T;
    }
    if (t == _i123.Tenant) {
      return _i123.Tenant.fromJson(data) as T;
    }
    if (t == _i124.Ticket) {
      return _i124.Ticket.fromJson(data) as T;
    }
    if (t == _i125.TicketEvent) {
      return _i125.TicketEvent.fromJson(data) as T;
    }
    if (t == _i126.TicketView) {
      return _i126.TicketView.fromJson(data) as T;
    }
    if (t == _i127.TrustRedeemResult) {
      return _i127.TrustRedeemResult.fromJson(data) as T;
    }
    if (t == _i128.TrustToken) {
      return _i128.TrustToken.fromJson(data) as T;
    }
    if (t == _i129.TrustTokenIssued) {
      return _i129.TrustTokenIssued.fromJson(data) as T;
    }
    if (t == _i130.TurnCredentials) {
      return _i130.TurnCredentials.fromJson(data) as T;
    }
    if (t == _i131.WebhookDelivery) {
      return _i131.WebhookDelivery.fromJson(data) as T;
    }
    if (t == _i132.WebhookEventMessage) {
      return _i132.WebhookEventMessage.fromJson(data) as T;
    }
    if (t == _i133.WebhookSubscription) {
      return _i133.WebhookSubscription.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AttachmentBytes?>()) {
      return (data != null ? _i2.AttachmentBytes.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AttachmentRef?>()) {
      return (data != null ? _i3.AttachmentRef.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Bot?>()) {
      return (data != null ? _i4.Bot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.BotAuditEvent?>()) {
      return (data != null ? _i5.BotAuditEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.BotIntegrationCreated?>()) {
      return (data != null ? _i6.BotIntegrationCreated.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.BotIntegrationView?>()) {
      return (data != null ? _i7.BotIntegrationView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.CallHistoryEntry?>()) {
      return (data != null ? _i8.CallHistoryEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.CallIceCandidate?>()) {
      return (data != null ? _i9.CallIceCandidate.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.ChatFolderRecord?>()) {
      return (data != null ? _i10.ChatFolderRecord.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.ChatFolderRoom?>()) {
      return (data != null ? _i11.ChatFolderRoom.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.ChatFolderView?>()) {
      return (data != null ? _i12.ChatFolderView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.ConnectIssuedToken?>()) {
      return (data != null ? _i13.ConnectIssuedToken.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i14.ConnectIssuedTokenResult?>()) {
      return (data != null
              ? _i14.ConnectIssuedTokenResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i15.ConnectKeyAuditEvent?>()) {
      return (data != null ? _i15.ConnectKeyAuditEvent.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.ConnectTenantStatus?>()) {
      return (data != null ? _i16.ConnectTenantStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i17.ContactBlock?>()) {
      return (data != null ? _i17.ContactBlock.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.ContactCard?>()) {
      return (data != null ? _i18.ContactCard.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.ContactCardInfo?>()) {
      return (data != null ? _i19.ContactCardInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.ContactLabel?>()) {
      return (data != null ? _i20.ContactLabel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.ContactLabelAssignment?>()) {
      return (data != null ? _i21.ContactLabelAssignment.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i22.ContactLink?>()) {
      return (data != null ? _i22.ContactLink.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.ContactMeta?>()) {
      return (data != null ? _i23.ContactMeta.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.ContactProfileView?>()) {
      return (data != null ? _i24.ContactProfileView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i25.ContactRelation?>()) {
      return (data != null ? _i25.ContactRelation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.ContactRequest?>()) {
      return (data != null ? _i26.ContactRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.ContactRequestView?>()) {
      return (data != null ? _i27.ContactRequestView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i28.DeviceRegistration?>()) {
      return (data != null ? _i28.DeviceRegistration.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i29.DeviceSessionInfo?>()) {
      return (data != null ? _i29.DeviceSessionInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.EmailAccount?>()) {
      return (data != null ? _i30.EmailAccount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i31.EmailSession?>()) {
      return (data != null ? _i31.EmailSession.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i32.EmailVerificationCode?>()) {
      return (data != null ? _i32.EmailVerificationCode.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i33.CallEventType?>()) {
      return (data != null ? _i33.CallEventType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i34.CallStatus?>()) {
      return (data != null ? _i34.CallStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i35.ContactLinkSource?>()) {
      return (data != null ? _i35.ContactLinkSource.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i36.ContactRequestStatus?>()) {
      return (data != null ? _i36.ContactRequestStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i37.DevicePlatform?>()) {
      return (data != null ? _i37.DevicePlatform.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i38.IdentityProvider?>()) {
      return (data != null ? _i38.IdentityProvider.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i39.MessengerEventType?>()) {
      return (data != null ? _i39.MessengerEventType.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i40.ParticipantKind?>()) {
      return (data != null ? _i40.ParticipantKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i41.ProductNotificationStatus?>()) {
      return (data != null
              ? _i41.ProductNotificationStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i42.PushService?>()) {
      return (data != null ? _i42.PushService.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i43.RoomMemberRole?>()) {
      return (data != null ? _i43.RoomMemberRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i44.RoomOwnership?>()) {
      return (data != null ? _i44.RoomOwnership.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i45.RoomState?>()) {
      return (data != null ? _i45.RoomState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i46.RoomType?>()) {
      return (data != null ? _i46.RoomType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i47.SupportTeamRole?>()) {
      return (data != null ? _i47.SupportTeamRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i48.TenantHostingMode?>()) {
      return (data != null ? _i48.TenantHostingMode.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i49.TrustTokenKind?>()) {
      return (data != null ? _i49.TrustTokenKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i50.AdapterNotConfiguredException?>()) {
      return (data != null
              ? _i50.AdapterNotConfiguredException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i51.BotCapabilityException?>()) {
      return (data != null ? _i51.BotCapabilityException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i52.BotLimitExceededException?>()) {
      return (data != null
              ? _i52.BotLimitExceededException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i53.BotNotFoundException?>()) {
      return (data != null ? _i53.BotNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i54.EmailAuthException?>()) {
      return (data != null ? _i54.EmailAuthException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i55.InsufficientPowerException?>()) {
      return (data != null
              ? _i55.InsufficientPowerException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i56.InvalidNotificationException?>()) {
      return (data != null
              ? _i56.InvalidNotificationException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i57.InvalidTokenException?>()) {
      return (data != null ? _i57.InvalidTokenException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i58.LastOwnerCannotDemoteException?>()) {
      return (data != null
              ? _i58.LastOwnerCannotDemoteException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i59.MessageBodyTooLargeException?>()) {
      return (data != null
              ? _i59.MessageBodyTooLargeException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i60.MessageDeletedException?>()) {
      return (data != null ? _i60.MessageDeletedException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i61.MessageNotEditableException?>()) {
      return (data != null
              ? _i61.MessageNotEditableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i62.MessengerNotAuthenticatedException?>()) {
      return (data != null
              ? _i62.MessengerNotAuthenticatedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i63.NotObjectRoomException?>()) {
      return (data != null ? _i63.NotObjectRoomException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i64.NotSupportTeamMemberException?>()) {
      return (data != null
              ? _i64.NotSupportTeamMemberException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i65.NotSupportTeamOwnerException?>()) {
      return (data != null
              ? _i65.NotSupportTeamOwnerException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i66.PeerUnavailableException?>()) {
      return (data != null
              ? _i66.PeerUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i67.ProductNotFoundException?>()) {
      return (data != null
              ? _i67.ProductNotFoundException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i68.ProductNotFoundForCallerException?>()) {
      return (data != null
              ? _i68.ProductNotFoundForCallerException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i69.RateLimitExceededException?>()) {
      return (data != null
              ? _i69.RateLimitExceededException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i70.RoomDissolvePartialException?>()) {
      return (data != null
              ? _i70.RoomDissolvePartialException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i71.RoomUnavailableException?>()) {
      return (data != null
              ? _i71.RoomUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i72.TaskIntegrationNotConfiguredException?>()) {
      return (data != null
              ? _i72.TaskIntegrationNotConfiguredException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i73.TenantNotFoundException?>()) {
      return (data != null ? _i73.TenantNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i74.WriteBannedException?>()) {
      return (data != null ? _i74.WriteBannedException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i75.EscalationResult?>()) {
      return (data != null ? _i75.EscalationResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i76.Greeting?>()) {
      return (data != null ? _i76.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i77.IdentityMapping?>()) {
      return (data != null ? _i77.IdentityMapping.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i78.IncomingWebhook?>()) {
      return (data != null ? _i78.IncomingWebhook.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i79.IncomingWebhookCreated?>()) {
      return (data != null ? _i79.IncomingWebhookCreated.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i80.MessageIndex?>()) {
      return (data != null ? _i80.MessageIndex.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i81.MessengerAuthContext?>()) {
      return (data != null ? _i81.MessengerAuthContext.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i82.MessengerEvent?>()) {
      return (data != null ? _i82.MessengerEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i83.MessengerMessage?>()) {
      return (data != null ? _i83.MessengerMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i84.MessengerMessageListPage?>()) {
      return (data != null
              ? _i84.MessengerMessageListPage.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i85.MessengerSession?>()) {
      return (data != null ? _i85.MessengerSession.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i86.MessengerSessionToken?>()) {
      return (data != null ? _i86.MessengerSessionToken.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i87.MessengerUser?>()) {
      return (data != null ? _i87.MessengerUser.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i88.NearbyConfirmResult?>()) {
      return (data != null ? _i88.NearbyConfirmResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i89.NearbyConfirmation?>()) {
      return (data != null ? _i89.NearbyConfirmation.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i90.NotificationSettings?>()) {
      return (data != null ? _i90.NotificationSettings.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i91.PresenceConnState?>()) {
      return (data != null ? _i91.PresenceConnState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i92.PresenceInfo?>()) {
      return (data != null ? _i92.PresenceInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i93.PresenceState?>()) {
      return (data != null ? _i93.PresenceState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i94.PresenceWatchedIndex?>()) {
      return (data != null ? _i94.PresenceWatchedIndex.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i95.PresenceWatchers?>()) {
      return (data != null ? _i95.PresenceWatchers.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i96.Product?>()) {
      return (data != null ? _i96.Product.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i97.ProductNotification?>()) {
      return (data != null ? _i97.ProductNotification.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i98.ProductNotificationRecipientResult?>()) {
      return (data != null
              ? _i98.ProductNotificationRecipientResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i99.ProductNotificationSendResult?>()) {
      return (data != null
              ? _i99.ProductNotificationSendResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i100.ProductObjectRoom?>()) {
      return (data != null ? _i100.ProductObjectRoom.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i101.ProfileTranslation?>()) {
      return (data != null ? _i101.ProfileTranslation.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i102.PulseAlertRule?>()) {
      return (data != null ? _i102.PulseAlertRule.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i103.PulseEvent?>()) {
      return (data != null ? _i103.PulseEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i104.PulseFolder?>()) {
      return (data != null ? _i104.PulseFolder.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i105.PulseIncident?>()) {
      return (data != null ? _i105.PulseIncident.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i106.PulseMonitor?>()) {
      return (data != null ? _i106.PulseMonitor.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i107.PulseMonitorCreated?>()) {
      return (data != null ? _i107.PulseMonitorCreated.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i108.PushQueueMessage?>()) {
      return (data != null ? _i108.PushQueueMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i109.PushTestJob?>()) {
      return (data != null ? _i109.PushTestJob.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i110.PushTestResult?>()) {
      return (data != null ? _i110.PushTestResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i111.Room?>()) {
      return (data != null ? _i111.Room.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i112.RoomDetails?>()) {
      return (data != null ? _i112.RoomDetails.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i113.RoomListPage?>()) {
      return (data != null ? _i113.RoomListPage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i114.RoomMembership?>()) {
      return (data != null ? _i114.RoomMembership.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i115.RoomParticipant?>()) {
      return (data != null ? _i115.RoomParticipant.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i116.RoomSummary?>()) {
      return (data != null ? _i116.RoomSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i117.SupportTeam?>()) {
      return (data != null ? _i117.SupportTeam.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i118.SupportTeamMember?>()) {
      return (data != null ? _i118.SupportTeamMember.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i119.SupportTeamMemberView?>()) {
      return (data != null ? _i119.SupportTeamMemberView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i120.SupportTeamView?>()) {
      return (data != null ? _i120.SupportTeamView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i121.TaskLink?>()) {
      return (data != null ? _i121.TaskLink.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i122.TaskManagerConfig?>()) {
      return (data != null ? _i122.TaskManagerConfig.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i123.Tenant?>()) {
      return (data != null ? _i123.Tenant.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i124.Ticket?>()) {
      return (data != null ? _i124.Ticket.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i125.TicketEvent?>()) {
      return (data != null ? _i125.TicketEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i126.TicketView?>()) {
      return (data != null ? _i126.TicketView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i127.TrustRedeemResult?>()) {
      return (data != null ? _i127.TrustRedeemResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i128.TrustToken?>()) {
      return (data != null ? _i128.TrustToken.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i129.TrustTokenIssued?>()) {
      return (data != null ? _i129.TrustTokenIssued.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i130.TurnCredentials?>()) {
      return (data != null ? _i130.TurnCredentials.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i131.WebhookDelivery?>()) {
      return (data != null ? _i131.WebhookDelivery.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i132.WebhookEventMessage?>()) {
      return (data != null ? _i132.WebhookEventMessage.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i133.WebhookSubscription?>()) {
      return (data != null ? _i133.WebhookSubscription.fromJson(data) : null)
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
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
    if (t == List<_i9.CallIceCandidate>) {
      return (data as List)
              .map((e) => deserialize<_i9.CallIceCandidate>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i9.CallIceCandidate>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i9.CallIceCandidate>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == _i1.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i83.MessengerMessage>) {
      return (data as List)
              .map((e) => deserialize<_i83.MessengerMessage>(e))
              .toList()
          as T;
    }
    if (t == List<_i98.ProductNotificationRecipientResult>) {
      return (data as List)
              .map(
                (e) => deserialize<_i98.ProductNotificationRecipientResult>(e),
              )
              .toList()
          as T;
    }
    if (t == List<_i115.RoomParticipant>) {
      return (data as List)
              .map((e) => deserialize<_i115.RoomParticipant>(e))
              .toList()
          as T;
    }
    if (t == List<_i116.RoomSummary>) {
      return (data as List)
              .map((e) => deserialize<_i116.RoomSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i119.SupportTeamMemberView>) {
      return (data as List)
              .map((e) => deserialize<_i119.SupportTeamMemberView>(e))
              .toList()
          as T;
    }
    if (t == List<_i134.WebhookSubscription>) {
      return (data as List)
              .map((e) => deserialize<_i134.WebhookSubscription>(e))
              .toList()
          as T;
    }
    if (t == List<_i135.WebhookDelivery>) {
      return (data as List)
              .map((e) => deserialize<_i135.WebhookDelivery>(e))
              .toList()
          as T;
    }
    if (t == List<_i136.BotAuditEvent>) {
      return (data as List)
              .map((e) => deserialize<_i136.BotAuditEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i137.Bot>) {
      return (data as List).map((e) => deserialize<_i137.Bot>(e)).toList() as T;
    }
    if (t == List<_i138.RoomSummary>) {
      return (data as List)
              .map((e) => deserialize<_i138.RoomSummary>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i139.BotIntegrationView>) {
      return (data as List)
              .map((e) => deserialize<_i139.BotIntegrationView>(e))
              .toList()
          as T;
    }
    if (t == List<_i140.ConnectTenantStatus>) {
      return (data as List)
              .map((e) => deserialize<_i140.ConnectTenantStatus>(e))
              .toList()
          as T;
    }
    if (t == List<_i141.ConnectKeyAuditEvent>) {
      return (data as List)
              .map((e) => deserialize<_i141.ConnectKeyAuditEvent>(e))
              .toList()
          as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    if (t == _i1.getType<Map<String, String>?>()) {
      return (data != null
              ? (data as Map).map(
                  (k, v) =>
                      MapEntry(deserialize<String>(k), deserialize<String>(v)),
                )
              : null)
          as T;
    }
    if (t == List<_i142.DeviceSessionInfo>) {
      return (data as List)
              .map((e) => deserialize<_i142.DeviceSessionInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i143.IncomingWebhook>) {
      return (data as List)
              .map((e) => deserialize<_i143.IncomingWebhook>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i144.MessengerMessage>) {
      return (data as List)
              .map((e) => deserialize<_i144.MessengerMessage>(e))
              .toList()
          as T;
    }
    if (t == List<_i145.CallIceCandidate>) {
      return (data as List)
              .map((e) => deserialize<_i145.CallIceCandidate>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i145.CallIceCandidate>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i145.CallIceCandidate>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i146.CallHistoryEntry>) {
      return (data as List)
              .map((e) => deserialize<_i146.CallHistoryEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i147.MessengerEvent>) {
      return (data as List)
              .map((e) => deserialize<_i147.MessengerEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i148.RoomParticipant>) {
      return (data as List)
              .map((e) => deserialize<_i148.RoomParticipant>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i149.TicketView>) {
      return (data as List)
              .map((e) => deserialize<_i149.TicketView>(e))
              .toList()
          as T;
    }
    if (t == List<_i150.PresenceInfo>) {
      return (data as List)
              .map((e) => deserialize<_i150.PresenceInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i151.ChatFolderView>) {
      return (data as List)
              .map((e) => deserialize<_i151.ChatFolderView>(e))
              .toList()
          as T;
    }
    if (t == List<_i152.ContactRequestView>) {
      return (data as List)
              .map((e) => deserialize<_i152.ContactRequestView>(e))
              .toList()
          as T;
    }
    if (t == List<_i153.ContactLabel>) {
      return (data as List)
              .map((e) => deserialize<_i153.ContactLabel>(e))
              .toList()
          as T;
    }
    if (t == List<_i154.ContactLabelAssignment>) {
      return (data as List)
              .map((e) => deserialize<_i154.ContactLabelAssignment>(e))
              .toList()
          as T;
    }
    if (t == List<_i155.ProductObjectRoom>) {
      return (data as List)
              .map((e) => deserialize<_i155.ProductObjectRoom>(e))
              .toList()
          as T;
    }
    if (t == List<_i156.Product>) {
      return (data as List).map((e) => deserialize<_i156.Product>(e)).toList()
          as T;
    }
    if (t == List<_i157.ProfileTranslation>) {
      return (data as List)
              .map((e) => deserialize<_i157.ProfileTranslation>(e))
              .toList()
          as T;
    }
    if (t == Map<String, int>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<int>(v)),
          )
          as T;
    }
    if (t == List<_i158.PulseFolder>) {
      return (data as List)
              .map((e) => deserialize<_i158.PulseFolder>(e))
              .toList()
          as T;
    }
    if (t == List<_i159.PulseMonitor>) {
      return (data as List)
              .map((e) => deserialize<_i159.PulseMonitor>(e))
              .toList()
          as T;
    }
    if (t == List<_i160.PulseAlertRule>) {
      return (data as List)
              .map((e) => deserialize<_i160.PulseAlertRule>(e))
              .toList()
          as T;
    }
    if (t == List<_i161.PulseIncident>) {
      return (data as List)
              .map((e) => deserialize<_i161.PulseIncident>(e))
              .toList()
          as T;
    }
    try {
      return _i162.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i163.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AttachmentBytes => 'AttachmentBytes',
      _i3.AttachmentRef => 'AttachmentRef',
      _i4.Bot => 'Bot',
      _i5.BotAuditEvent => 'BotAuditEvent',
      _i6.BotIntegrationCreated => 'BotIntegrationCreated',
      _i7.BotIntegrationView => 'BotIntegrationView',
      _i8.CallHistoryEntry => 'CallHistoryEntry',
      _i9.CallIceCandidate => 'CallIceCandidate',
      _i10.ChatFolderRecord => 'ChatFolderRecord',
      _i11.ChatFolderRoom => 'ChatFolderRoom',
      _i12.ChatFolderView => 'ChatFolderView',
      _i13.ConnectIssuedToken => 'ConnectIssuedToken',
      _i14.ConnectIssuedTokenResult => 'ConnectIssuedTokenResult',
      _i15.ConnectKeyAuditEvent => 'ConnectKeyAuditEvent',
      _i16.ConnectTenantStatus => 'ConnectTenantStatus',
      _i17.ContactBlock => 'ContactBlock',
      _i18.ContactCard => 'ContactCard',
      _i19.ContactCardInfo => 'ContactCardInfo',
      _i20.ContactLabel => 'ContactLabel',
      _i21.ContactLabelAssignment => 'ContactLabelAssignment',
      _i22.ContactLink => 'ContactLink',
      _i23.ContactMeta => 'ContactMeta',
      _i24.ContactProfileView => 'ContactProfileView',
      _i25.ContactRelation => 'ContactRelation',
      _i26.ContactRequest => 'ContactRequest',
      _i27.ContactRequestView => 'ContactRequestView',
      _i28.DeviceRegistration => 'DeviceRegistration',
      _i29.DeviceSessionInfo => 'DeviceSessionInfo',
      _i30.EmailAccount => 'EmailAccount',
      _i31.EmailSession => 'EmailSession',
      _i32.EmailVerificationCode => 'EmailVerificationCode',
      _i33.CallEventType => 'CallEventType',
      _i34.CallStatus => 'CallStatus',
      _i35.ContactLinkSource => 'ContactLinkSource',
      _i36.ContactRequestStatus => 'ContactRequestStatus',
      _i37.DevicePlatform => 'DevicePlatform',
      _i38.IdentityProvider => 'IdentityProvider',
      _i39.MessengerEventType => 'MessengerEventType',
      _i40.ParticipantKind => 'ParticipantKind',
      _i41.ProductNotificationStatus => 'ProductNotificationStatus',
      _i42.PushService => 'PushService',
      _i43.RoomMemberRole => 'RoomMemberRole',
      _i44.RoomOwnership => 'RoomOwnership',
      _i45.RoomState => 'RoomState',
      _i46.RoomType => 'RoomType',
      _i47.SupportTeamRole => 'SupportTeamRole',
      _i48.TenantHostingMode => 'TenantHostingMode',
      _i49.TrustTokenKind => 'TrustTokenKind',
      _i50.AdapterNotConfiguredException => 'AdapterNotConfiguredException',
      _i51.BotCapabilityException => 'BotCapabilityException',
      _i52.BotLimitExceededException => 'BotLimitExceededException',
      _i53.BotNotFoundException => 'BotNotFoundException',
      _i54.EmailAuthException => 'EmailAuthException',
      _i55.InsufficientPowerException => 'InsufficientPowerException',
      _i56.InvalidNotificationException => 'InvalidNotificationException',
      _i57.InvalidTokenException => 'InvalidTokenException',
      _i58.LastOwnerCannotDemoteException => 'LastOwnerCannotDemoteException',
      _i59.MessageBodyTooLargeException => 'MessageBodyTooLargeException',
      _i60.MessageDeletedException => 'MessageDeletedException',
      _i61.MessageNotEditableException => 'MessageNotEditableException',
      _i62.MessengerNotAuthenticatedException =>
        'MessengerNotAuthenticatedException',
      _i63.NotObjectRoomException => 'NotObjectRoomException',
      _i64.NotSupportTeamMemberException => 'NotSupportTeamMemberException',
      _i65.NotSupportTeamOwnerException => 'NotSupportTeamOwnerException',
      _i66.PeerUnavailableException => 'PeerUnavailableException',
      _i67.ProductNotFoundException => 'ProductNotFoundException',
      _i68.ProductNotFoundForCallerException =>
        'ProductNotFoundForCallerException',
      _i69.RateLimitExceededException => 'RateLimitExceededException',
      _i70.RoomDissolvePartialException => 'RoomDissolvePartialException',
      _i71.RoomUnavailableException => 'RoomUnavailableException',
      _i72.TaskIntegrationNotConfiguredException =>
        'TaskIntegrationNotConfiguredException',
      _i73.TenantNotFoundException => 'TenantNotFoundException',
      _i74.WriteBannedException => 'WriteBannedException',
      _i75.EscalationResult => 'EscalationResult',
      _i76.Greeting => 'Greeting',
      _i77.IdentityMapping => 'IdentityMapping',
      _i78.IncomingWebhook => 'IncomingWebhook',
      _i79.IncomingWebhookCreated => 'IncomingWebhookCreated',
      _i80.MessageIndex => 'MessageIndex',
      _i81.MessengerAuthContext => 'MessengerAuthContext',
      _i82.MessengerEvent => 'MessengerEvent',
      _i83.MessengerMessage => 'MessengerMessage',
      _i84.MessengerMessageListPage => 'MessengerMessageListPage',
      _i85.MessengerSession => 'MessengerSession',
      _i86.MessengerSessionToken => 'MessengerSessionToken',
      _i87.MessengerUser => 'MessengerUser',
      _i88.NearbyConfirmResult => 'NearbyConfirmResult',
      _i89.NearbyConfirmation => 'NearbyConfirmation',
      _i90.NotificationSettings => 'NotificationSettings',
      _i91.PresenceConnState => 'PresenceConnState',
      _i92.PresenceInfo => 'PresenceInfo',
      _i93.PresenceState => 'PresenceState',
      _i94.PresenceWatchedIndex => 'PresenceWatchedIndex',
      _i95.PresenceWatchers => 'PresenceWatchers',
      _i96.Product => 'Product',
      _i97.ProductNotification => 'ProductNotification',
      _i98.ProductNotificationRecipientResult =>
        'ProductNotificationRecipientResult',
      _i99.ProductNotificationSendResult => 'ProductNotificationSendResult',
      _i100.ProductObjectRoom => 'ProductObjectRoom',
      _i101.ProfileTranslation => 'ProfileTranslation',
      _i102.PulseAlertRule => 'PulseAlertRule',
      _i103.PulseEvent => 'PulseEvent',
      _i104.PulseFolder => 'PulseFolder',
      _i105.PulseIncident => 'PulseIncident',
      _i106.PulseMonitor => 'PulseMonitor',
      _i107.PulseMonitorCreated => 'PulseMonitorCreated',
      _i108.PushQueueMessage => 'PushQueueMessage',
      _i109.PushTestJob => 'PushTestJob',
      _i110.PushTestResult => 'PushTestResult',
      _i111.Room => 'Room',
      _i112.RoomDetails => 'RoomDetails',
      _i113.RoomListPage => 'RoomListPage',
      _i114.RoomMembership => 'RoomMembership',
      _i115.RoomParticipant => 'RoomParticipant',
      _i116.RoomSummary => 'RoomSummary',
      _i117.SupportTeam => 'SupportTeam',
      _i118.SupportTeamMember => 'SupportTeamMember',
      _i119.SupportTeamMemberView => 'SupportTeamMemberView',
      _i120.SupportTeamView => 'SupportTeamView',
      _i121.TaskLink => 'TaskLink',
      _i122.TaskManagerConfig => 'TaskManagerConfig',
      _i123.Tenant => 'Tenant',
      _i124.Ticket => 'Ticket',
      _i125.TicketEvent => 'TicketEvent',
      _i126.TicketView => 'TicketView',
      _i127.TrustRedeemResult => 'TrustRedeemResult',
      _i128.TrustToken => 'TrustToken',
      _i129.TrustTokenIssued => 'TrustTokenIssued',
      _i130.TurnCredentials => 'TurnCredentials',
      _i131.WebhookDelivery => 'WebhookDelivery',
      _i132.WebhookEventMessage => 'WebhookEventMessage',
      _i133.WebhookSubscription => 'WebhookSubscription',
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
      case _i4.Bot():
        return 'Bot';
      case _i5.BotAuditEvent():
        return 'BotAuditEvent';
      case _i6.BotIntegrationCreated():
        return 'BotIntegrationCreated';
      case _i7.BotIntegrationView():
        return 'BotIntegrationView';
      case _i8.CallHistoryEntry():
        return 'CallHistoryEntry';
      case _i9.CallIceCandidate():
        return 'CallIceCandidate';
      case _i10.ChatFolderRecord():
        return 'ChatFolderRecord';
      case _i11.ChatFolderRoom():
        return 'ChatFolderRoom';
      case _i12.ChatFolderView():
        return 'ChatFolderView';
      case _i13.ConnectIssuedToken():
        return 'ConnectIssuedToken';
      case _i14.ConnectIssuedTokenResult():
        return 'ConnectIssuedTokenResult';
      case _i15.ConnectKeyAuditEvent():
        return 'ConnectKeyAuditEvent';
      case _i16.ConnectTenantStatus():
        return 'ConnectTenantStatus';
      case _i17.ContactBlock():
        return 'ContactBlock';
      case _i18.ContactCard():
        return 'ContactCard';
      case _i19.ContactCardInfo():
        return 'ContactCardInfo';
      case _i20.ContactLabel():
        return 'ContactLabel';
      case _i21.ContactLabelAssignment():
        return 'ContactLabelAssignment';
      case _i22.ContactLink():
        return 'ContactLink';
      case _i23.ContactMeta():
        return 'ContactMeta';
      case _i24.ContactProfileView():
        return 'ContactProfileView';
      case _i25.ContactRelation():
        return 'ContactRelation';
      case _i26.ContactRequest():
        return 'ContactRequest';
      case _i27.ContactRequestView():
        return 'ContactRequestView';
      case _i28.DeviceRegistration():
        return 'DeviceRegistration';
      case _i29.DeviceSessionInfo():
        return 'DeviceSessionInfo';
      case _i30.EmailAccount():
        return 'EmailAccount';
      case _i31.EmailSession():
        return 'EmailSession';
      case _i32.EmailVerificationCode():
        return 'EmailVerificationCode';
      case _i33.CallEventType():
        return 'CallEventType';
      case _i34.CallStatus():
        return 'CallStatus';
      case _i35.ContactLinkSource():
        return 'ContactLinkSource';
      case _i36.ContactRequestStatus():
        return 'ContactRequestStatus';
      case _i37.DevicePlatform():
        return 'DevicePlatform';
      case _i38.IdentityProvider():
        return 'IdentityProvider';
      case _i39.MessengerEventType():
        return 'MessengerEventType';
      case _i40.ParticipantKind():
        return 'ParticipantKind';
      case _i41.ProductNotificationStatus():
        return 'ProductNotificationStatus';
      case _i42.PushService():
        return 'PushService';
      case _i43.RoomMemberRole():
        return 'RoomMemberRole';
      case _i44.RoomOwnership():
        return 'RoomOwnership';
      case _i45.RoomState():
        return 'RoomState';
      case _i46.RoomType():
        return 'RoomType';
      case _i47.SupportTeamRole():
        return 'SupportTeamRole';
      case _i48.TenantHostingMode():
        return 'TenantHostingMode';
      case _i49.TrustTokenKind():
        return 'TrustTokenKind';
      case _i50.AdapterNotConfiguredException():
        return 'AdapterNotConfiguredException';
      case _i51.BotCapabilityException():
        return 'BotCapabilityException';
      case _i52.BotLimitExceededException():
        return 'BotLimitExceededException';
      case _i53.BotNotFoundException():
        return 'BotNotFoundException';
      case _i54.EmailAuthException():
        return 'EmailAuthException';
      case _i55.InsufficientPowerException():
        return 'InsufficientPowerException';
      case _i56.InvalidNotificationException():
        return 'InvalidNotificationException';
      case _i57.InvalidTokenException():
        return 'InvalidTokenException';
      case _i58.LastOwnerCannotDemoteException():
        return 'LastOwnerCannotDemoteException';
      case _i59.MessageBodyTooLargeException():
        return 'MessageBodyTooLargeException';
      case _i60.MessageDeletedException():
        return 'MessageDeletedException';
      case _i61.MessageNotEditableException():
        return 'MessageNotEditableException';
      case _i62.MessengerNotAuthenticatedException():
        return 'MessengerNotAuthenticatedException';
      case _i63.NotObjectRoomException():
        return 'NotObjectRoomException';
      case _i64.NotSupportTeamMemberException():
        return 'NotSupportTeamMemberException';
      case _i65.NotSupportTeamOwnerException():
        return 'NotSupportTeamOwnerException';
      case _i66.PeerUnavailableException():
        return 'PeerUnavailableException';
      case _i67.ProductNotFoundException():
        return 'ProductNotFoundException';
      case _i68.ProductNotFoundForCallerException():
        return 'ProductNotFoundForCallerException';
      case _i69.RateLimitExceededException():
        return 'RateLimitExceededException';
      case _i70.RoomDissolvePartialException():
        return 'RoomDissolvePartialException';
      case _i71.RoomUnavailableException():
        return 'RoomUnavailableException';
      case _i72.TaskIntegrationNotConfiguredException():
        return 'TaskIntegrationNotConfiguredException';
      case _i73.TenantNotFoundException():
        return 'TenantNotFoundException';
      case _i74.WriteBannedException():
        return 'WriteBannedException';
      case _i75.EscalationResult():
        return 'EscalationResult';
      case _i76.Greeting():
        return 'Greeting';
      case _i77.IdentityMapping():
        return 'IdentityMapping';
      case _i78.IncomingWebhook():
        return 'IncomingWebhook';
      case _i79.IncomingWebhookCreated():
        return 'IncomingWebhookCreated';
      case _i80.MessageIndex():
        return 'MessageIndex';
      case _i81.MessengerAuthContext():
        return 'MessengerAuthContext';
      case _i82.MessengerEvent():
        return 'MessengerEvent';
      case _i83.MessengerMessage():
        return 'MessengerMessage';
      case _i84.MessengerMessageListPage():
        return 'MessengerMessageListPage';
      case _i85.MessengerSession():
        return 'MessengerSession';
      case _i86.MessengerSessionToken():
        return 'MessengerSessionToken';
      case _i87.MessengerUser():
        return 'MessengerUser';
      case _i88.NearbyConfirmResult():
        return 'NearbyConfirmResult';
      case _i89.NearbyConfirmation():
        return 'NearbyConfirmation';
      case _i90.NotificationSettings():
        return 'NotificationSettings';
      case _i91.PresenceConnState():
        return 'PresenceConnState';
      case _i92.PresenceInfo():
        return 'PresenceInfo';
      case _i93.PresenceState():
        return 'PresenceState';
      case _i94.PresenceWatchedIndex():
        return 'PresenceWatchedIndex';
      case _i95.PresenceWatchers():
        return 'PresenceWatchers';
      case _i96.Product():
        return 'Product';
      case _i97.ProductNotification():
        return 'ProductNotification';
      case _i98.ProductNotificationRecipientResult():
        return 'ProductNotificationRecipientResult';
      case _i99.ProductNotificationSendResult():
        return 'ProductNotificationSendResult';
      case _i100.ProductObjectRoom():
        return 'ProductObjectRoom';
      case _i101.ProfileTranslation():
        return 'ProfileTranslation';
      case _i102.PulseAlertRule():
        return 'PulseAlertRule';
      case _i103.PulseEvent():
        return 'PulseEvent';
      case _i104.PulseFolder():
        return 'PulseFolder';
      case _i105.PulseIncident():
        return 'PulseIncident';
      case _i106.PulseMonitor():
        return 'PulseMonitor';
      case _i107.PulseMonitorCreated():
        return 'PulseMonitorCreated';
      case _i108.PushQueueMessage():
        return 'PushQueueMessage';
      case _i109.PushTestJob():
        return 'PushTestJob';
      case _i110.PushTestResult():
        return 'PushTestResult';
      case _i111.Room():
        return 'Room';
      case _i112.RoomDetails():
        return 'RoomDetails';
      case _i113.RoomListPage():
        return 'RoomListPage';
      case _i114.RoomMembership():
        return 'RoomMembership';
      case _i115.RoomParticipant():
        return 'RoomParticipant';
      case _i116.RoomSummary():
        return 'RoomSummary';
      case _i117.SupportTeam():
        return 'SupportTeam';
      case _i118.SupportTeamMember():
        return 'SupportTeamMember';
      case _i119.SupportTeamMemberView():
        return 'SupportTeamMemberView';
      case _i120.SupportTeamView():
        return 'SupportTeamView';
      case _i121.TaskLink():
        return 'TaskLink';
      case _i122.TaskManagerConfig():
        return 'TaskManagerConfig';
      case _i123.Tenant():
        return 'Tenant';
      case _i124.Ticket():
        return 'Ticket';
      case _i125.TicketEvent():
        return 'TicketEvent';
      case _i126.TicketView():
        return 'TicketView';
      case _i127.TrustRedeemResult():
        return 'TrustRedeemResult';
      case _i128.TrustToken():
        return 'TrustToken';
      case _i129.TrustTokenIssued():
        return 'TrustTokenIssued';
      case _i130.TurnCredentials():
        return 'TurnCredentials';
      case _i131.WebhookDelivery():
        return 'WebhookDelivery';
      case _i132.WebhookEventMessage():
        return 'WebhookEventMessage';
      case _i133.WebhookSubscription():
        return 'WebhookSubscription';
    }
    className = _i162.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i163.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'Bot') {
      return deserialize<_i4.Bot>(data['data']);
    }
    if (dataClassName == 'BotAuditEvent') {
      return deserialize<_i5.BotAuditEvent>(data['data']);
    }
    if (dataClassName == 'BotIntegrationCreated') {
      return deserialize<_i6.BotIntegrationCreated>(data['data']);
    }
    if (dataClassName == 'BotIntegrationView') {
      return deserialize<_i7.BotIntegrationView>(data['data']);
    }
    if (dataClassName == 'CallHistoryEntry') {
      return deserialize<_i8.CallHistoryEntry>(data['data']);
    }
    if (dataClassName == 'CallIceCandidate') {
      return deserialize<_i9.CallIceCandidate>(data['data']);
    }
    if (dataClassName == 'ChatFolderRecord') {
      return deserialize<_i10.ChatFolderRecord>(data['data']);
    }
    if (dataClassName == 'ChatFolderRoom') {
      return deserialize<_i11.ChatFolderRoom>(data['data']);
    }
    if (dataClassName == 'ChatFolderView') {
      return deserialize<_i12.ChatFolderView>(data['data']);
    }
    if (dataClassName == 'ConnectIssuedToken') {
      return deserialize<_i13.ConnectIssuedToken>(data['data']);
    }
    if (dataClassName == 'ConnectIssuedTokenResult') {
      return deserialize<_i14.ConnectIssuedTokenResult>(data['data']);
    }
    if (dataClassName == 'ConnectKeyAuditEvent') {
      return deserialize<_i15.ConnectKeyAuditEvent>(data['data']);
    }
    if (dataClassName == 'ConnectTenantStatus') {
      return deserialize<_i16.ConnectTenantStatus>(data['data']);
    }
    if (dataClassName == 'ContactBlock') {
      return deserialize<_i17.ContactBlock>(data['data']);
    }
    if (dataClassName == 'ContactCard') {
      return deserialize<_i18.ContactCard>(data['data']);
    }
    if (dataClassName == 'ContactCardInfo') {
      return deserialize<_i19.ContactCardInfo>(data['data']);
    }
    if (dataClassName == 'ContactLabel') {
      return deserialize<_i20.ContactLabel>(data['data']);
    }
    if (dataClassName == 'ContactLabelAssignment') {
      return deserialize<_i21.ContactLabelAssignment>(data['data']);
    }
    if (dataClassName == 'ContactLink') {
      return deserialize<_i22.ContactLink>(data['data']);
    }
    if (dataClassName == 'ContactMeta') {
      return deserialize<_i23.ContactMeta>(data['data']);
    }
    if (dataClassName == 'ContactProfileView') {
      return deserialize<_i24.ContactProfileView>(data['data']);
    }
    if (dataClassName == 'ContactRelation') {
      return deserialize<_i25.ContactRelation>(data['data']);
    }
    if (dataClassName == 'ContactRequest') {
      return deserialize<_i26.ContactRequest>(data['data']);
    }
    if (dataClassName == 'ContactRequestView') {
      return deserialize<_i27.ContactRequestView>(data['data']);
    }
    if (dataClassName == 'DeviceRegistration') {
      return deserialize<_i28.DeviceRegistration>(data['data']);
    }
    if (dataClassName == 'DeviceSessionInfo') {
      return deserialize<_i29.DeviceSessionInfo>(data['data']);
    }
    if (dataClassName == 'EmailAccount') {
      return deserialize<_i30.EmailAccount>(data['data']);
    }
    if (dataClassName == 'EmailSession') {
      return deserialize<_i31.EmailSession>(data['data']);
    }
    if (dataClassName == 'EmailVerificationCode') {
      return deserialize<_i32.EmailVerificationCode>(data['data']);
    }
    if (dataClassName == 'CallEventType') {
      return deserialize<_i33.CallEventType>(data['data']);
    }
    if (dataClassName == 'CallStatus') {
      return deserialize<_i34.CallStatus>(data['data']);
    }
    if (dataClassName == 'ContactLinkSource') {
      return deserialize<_i35.ContactLinkSource>(data['data']);
    }
    if (dataClassName == 'ContactRequestStatus') {
      return deserialize<_i36.ContactRequestStatus>(data['data']);
    }
    if (dataClassName == 'DevicePlatform') {
      return deserialize<_i37.DevicePlatform>(data['data']);
    }
    if (dataClassName == 'IdentityProvider') {
      return deserialize<_i38.IdentityProvider>(data['data']);
    }
    if (dataClassName == 'MessengerEventType') {
      return deserialize<_i39.MessengerEventType>(data['data']);
    }
    if (dataClassName == 'ParticipantKind') {
      return deserialize<_i40.ParticipantKind>(data['data']);
    }
    if (dataClassName == 'ProductNotificationStatus') {
      return deserialize<_i41.ProductNotificationStatus>(data['data']);
    }
    if (dataClassName == 'PushService') {
      return deserialize<_i42.PushService>(data['data']);
    }
    if (dataClassName == 'RoomMemberRole') {
      return deserialize<_i43.RoomMemberRole>(data['data']);
    }
    if (dataClassName == 'RoomOwnership') {
      return deserialize<_i44.RoomOwnership>(data['data']);
    }
    if (dataClassName == 'RoomState') {
      return deserialize<_i45.RoomState>(data['data']);
    }
    if (dataClassName == 'RoomType') {
      return deserialize<_i46.RoomType>(data['data']);
    }
    if (dataClassName == 'SupportTeamRole') {
      return deserialize<_i47.SupportTeamRole>(data['data']);
    }
    if (dataClassName == 'TenantHostingMode') {
      return deserialize<_i48.TenantHostingMode>(data['data']);
    }
    if (dataClassName == 'TrustTokenKind') {
      return deserialize<_i49.TrustTokenKind>(data['data']);
    }
    if (dataClassName == 'AdapterNotConfiguredException') {
      return deserialize<_i50.AdapterNotConfiguredException>(data['data']);
    }
    if (dataClassName == 'BotCapabilityException') {
      return deserialize<_i51.BotCapabilityException>(data['data']);
    }
    if (dataClassName == 'BotLimitExceededException') {
      return deserialize<_i52.BotLimitExceededException>(data['data']);
    }
    if (dataClassName == 'BotNotFoundException') {
      return deserialize<_i53.BotNotFoundException>(data['data']);
    }
    if (dataClassName == 'EmailAuthException') {
      return deserialize<_i54.EmailAuthException>(data['data']);
    }
    if (dataClassName == 'InsufficientPowerException') {
      return deserialize<_i55.InsufficientPowerException>(data['data']);
    }
    if (dataClassName == 'InvalidNotificationException') {
      return deserialize<_i56.InvalidNotificationException>(data['data']);
    }
    if (dataClassName == 'InvalidTokenException') {
      return deserialize<_i57.InvalidTokenException>(data['data']);
    }
    if (dataClassName == 'LastOwnerCannotDemoteException') {
      return deserialize<_i58.LastOwnerCannotDemoteException>(data['data']);
    }
    if (dataClassName == 'MessageBodyTooLargeException') {
      return deserialize<_i59.MessageBodyTooLargeException>(data['data']);
    }
    if (dataClassName == 'MessageDeletedException') {
      return deserialize<_i60.MessageDeletedException>(data['data']);
    }
    if (dataClassName == 'MessageNotEditableException') {
      return deserialize<_i61.MessageNotEditableException>(data['data']);
    }
    if (dataClassName == 'MessengerNotAuthenticatedException') {
      return deserialize<_i62.MessengerNotAuthenticatedException>(data['data']);
    }
    if (dataClassName == 'NotObjectRoomException') {
      return deserialize<_i63.NotObjectRoomException>(data['data']);
    }
    if (dataClassName == 'NotSupportTeamMemberException') {
      return deserialize<_i64.NotSupportTeamMemberException>(data['data']);
    }
    if (dataClassName == 'NotSupportTeamOwnerException') {
      return deserialize<_i65.NotSupportTeamOwnerException>(data['data']);
    }
    if (dataClassName == 'PeerUnavailableException') {
      return deserialize<_i66.PeerUnavailableException>(data['data']);
    }
    if (dataClassName == 'ProductNotFoundException') {
      return deserialize<_i67.ProductNotFoundException>(data['data']);
    }
    if (dataClassName == 'ProductNotFoundForCallerException') {
      return deserialize<_i68.ProductNotFoundForCallerException>(data['data']);
    }
    if (dataClassName == 'RateLimitExceededException') {
      return deserialize<_i69.RateLimitExceededException>(data['data']);
    }
    if (dataClassName == 'RoomDissolvePartialException') {
      return deserialize<_i70.RoomDissolvePartialException>(data['data']);
    }
    if (dataClassName == 'RoomUnavailableException') {
      return deserialize<_i71.RoomUnavailableException>(data['data']);
    }
    if (dataClassName == 'TaskIntegrationNotConfiguredException') {
      return deserialize<_i72.TaskIntegrationNotConfiguredException>(
        data['data'],
      );
    }
    if (dataClassName == 'TenantNotFoundException') {
      return deserialize<_i73.TenantNotFoundException>(data['data']);
    }
    if (dataClassName == 'WriteBannedException') {
      return deserialize<_i74.WriteBannedException>(data['data']);
    }
    if (dataClassName == 'EscalationResult') {
      return deserialize<_i75.EscalationResult>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i76.Greeting>(data['data']);
    }
    if (dataClassName == 'IdentityMapping') {
      return deserialize<_i77.IdentityMapping>(data['data']);
    }
    if (dataClassName == 'IncomingWebhook') {
      return deserialize<_i78.IncomingWebhook>(data['data']);
    }
    if (dataClassName == 'IncomingWebhookCreated') {
      return deserialize<_i79.IncomingWebhookCreated>(data['data']);
    }
    if (dataClassName == 'MessageIndex') {
      return deserialize<_i80.MessageIndex>(data['data']);
    }
    if (dataClassName == 'MessengerAuthContext') {
      return deserialize<_i81.MessengerAuthContext>(data['data']);
    }
    if (dataClassName == 'MessengerEvent') {
      return deserialize<_i82.MessengerEvent>(data['data']);
    }
    if (dataClassName == 'MessengerMessage') {
      return deserialize<_i83.MessengerMessage>(data['data']);
    }
    if (dataClassName == 'MessengerMessageListPage') {
      return deserialize<_i84.MessengerMessageListPage>(data['data']);
    }
    if (dataClassName == 'MessengerSession') {
      return deserialize<_i85.MessengerSession>(data['data']);
    }
    if (dataClassName == 'MessengerSessionToken') {
      return deserialize<_i86.MessengerSessionToken>(data['data']);
    }
    if (dataClassName == 'MessengerUser') {
      return deserialize<_i87.MessengerUser>(data['data']);
    }
    if (dataClassName == 'NearbyConfirmResult') {
      return deserialize<_i88.NearbyConfirmResult>(data['data']);
    }
    if (dataClassName == 'NearbyConfirmation') {
      return deserialize<_i89.NearbyConfirmation>(data['data']);
    }
    if (dataClassName == 'NotificationSettings') {
      return deserialize<_i90.NotificationSettings>(data['data']);
    }
    if (dataClassName == 'PresenceConnState') {
      return deserialize<_i91.PresenceConnState>(data['data']);
    }
    if (dataClassName == 'PresenceInfo') {
      return deserialize<_i92.PresenceInfo>(data['data']);
    }
    if (dataClassName == 'PresenceState') {
      return deserialize<_i93.PresenceState>(data['data']);
    }
    if (dataClassName == 'PresenceWatchedIndex') {
      return deserialize<_i94.PresenceWatchedIndex>(data['data']);
    }
    if (dataClassName == 'PresenceWatchers') {
      return deserialize<_i95.PresenceWatchers>(data['data']);
    }
    if (dataClassName == 'Product') {
      return deserialize<_i96.Product>(data['data']);
    }
    if (dataClassName == 'ProductNotification') {
      return deserialize<_i97.ProductNotification>(data['data']);
    }
    if (dataClassName == 'ProductNotificationRecipientResult') {
      return deserialize<_i98.ProductNotificationRecipientResult>(data['data']);
    }
    if (dataClassName == 'ProductNotificationSendResult') {
      return deserialize<_i99.ProductNotificationSendResult>(data['data']);
    }
    if (dataClassName == 'ProductObjectRoom') {
      return deserialize<_i100.ProductObjectRoom>(data['data']);
    }
    if (dataClassName == 'ProfileTranslation') {
      return deserialize<_i101.ProfileTranslation>(data['data']);
    }
    if (dataClassName == 'PulseAlertRule') {
      return deserialize<_i102.PulseAlertRule>(data['data']);
    }
    if (dataClassName == 'PulseEvent') {
      return deserialize<_i103.PulseEvent>(data['data']);
    }
    if (dataClassName == 'PulseFolder') {
      return deserialize<_i104.PulseFolder>(data['data']);
    }
    if (dataClassName == 'PulseIncident') {
      return deserialize<_i105.PulseIncident>(data['data']);
    }
    if (dataClassName == 'PulseMonitor') {
      return deserialize<_i106.PulseMonitor>(data['data']);
    }
    if (dataClassName == 'PulseMonitorCreated') {
      return deserialize<_i107.PulseMonitorCreated>(data['data']);
    }
    if (dataClassName == 'PushQueueMessage') {
      return deserialize<_i108.PushQueueMessage>(data['data']);
    }
    if (dataClassName == 'PushTestJob') {
      return deserialize<_i109.PushTestJob>(data['data']);
    }
    if (dataClassName == 'PushTestResult') {
      return deserialize<_i110.PushTestResult>(data['data']);
    }
    if (dataClassName == 'Room') {
      return deserialize<_i111.Room>(data['data']);
    }
    if (dataClassName == 'RoomDetails') {
      return deserialize<_i112.RoomDetails>(data['data']);
    }
    if (dataClassName == 'RoomListPage') {
      return deserialize<_i113.RoomListPage>(data['data']);
    }
    if (dataClassName == 'RoomMembership') {
      return deserialize<_i114.RoomMembership>(data['data']);
    }
    if (dataClassName == 'RoomParticipant') {
      return deserialize<_i115.RoomParticipant>(data['data']);
    }
    if (dataClassName == 'RoomSummary') {
      return deserialize<_i116.RoomSummary>(data['data']);
    }
    if (dataClassName == 'SupportTeam') {
      return deserialize<_i117.SupportTeam>(data['data']);
    }
    if (dataClassName == 'SupportTeamMember') {
      return deserialize<_i118.SupportTeamMember>(data['data']);
    }
    if (dataClassName == 'SupportTeamMemberView') {
      return deserialize<_i119.SupportTeamMemberView>(data['data']);
    }
    if (dataClassName == 'SupportTeamView') {
      return deserialize<_i120.SupportTeamView>(data['data']);
    }
    if (dataClassName == 'TaskLink') {
      return deserialize<_i121.TaskLink>(data['data']);
    }
    if (dataClassName == 'TaskManagerConfig') {
      return deserialize<_i122.TaskManagerConfig>(data['data']);
    }
    if (dataClassName == 'Tenant') {
      return deserialize<_i123.Tenant>(data['data']);
    }
    if (dataClassName == 'Ticket') {
      return deserialize<_i124.Ticket>(data['data']);
    }
    if (dataClassName == 'TicketEvent') {
      return deserialize<_i125.TicketEvent>(data['data']);
    }
    if (dataClassName == 'TicketView') {
      return deserialize<_i126.TicketView>(data['data']);
    }
    if (dataClassName == 'TrustRedeemResult') {
      return deserialize<_i127.TrustRedeemResult>(data['data']);
    }
    if (dataClassName == 'TrustToken') {
      return deserialize<_i128.TrustToken>(data['data']);
    }
    if (dataClassName == 'TrustTokenIssued') {
      return deserialize<_i129.TrustTokenIssued>(data['data']);
    }
    if (dataClassName == 'TurnCredentials') {
      return deserialize<_i130.TurnCredentials>(data['data']);
    }
    if (dataClassName == 'WebhookDelivery') {
      return deserialize<_i131.WebhookDelivery>(data['data']);
    }
    if (dataClassName == 'WebhookEventMessage') {
      return deserialize<_i132.WebhookEventMessage>(data['data']);
    }
    if (dataClassName == 'WebhookSubscription') {
      return deserialize<_i133.WebhookSubscription>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i162.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i163.Protocol().deserializeByClassName(data);
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
      return _i162.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i163.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
