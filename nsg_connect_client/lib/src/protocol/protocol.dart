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
import 'available_bot.dart' as _i4;
import 'bot.dart' as _i5;
import 'bot_audit_event.dart' as _i6;
import 'bot_command.dart' as _i7;
import 'bot_integration_created.dart' as _i8;
import 'bot_integration_view.dart' as _i9;
import 'bot_read_mode_result.dart' as _i10;
import 'call_history_entry.dart' as _i11;
import 'call_ice_candidate.dart' as _i12;
import 'chat_folder.dart' as _i13;
import 'chat_folder_room.dart' as _i14;
import 'chat_folder_view.dart' as _i15;
import 'conference.dart' as _i16;
import 'conference_member.dart' as _i17;
import 'conference_participant.dart' as _i18;
import 'conference_screen_share.dart' as _i19;
import 'conference_state.dart' as _i20;
import 'connect_issued_token.dart' as _i21;
import 'connect_issued_token_result.dart' as _i22;
import 'connect_key_audit_event.dart' as _i23;
import 'connect_tenant_status.dart' as _i24;
import 'contact_block.dart' as _i25;
import 'contact_card.dart' as _i26;
import 'contact_card_info.dart' as _i27;
import 'contact_label.dart' as _i28;
import 'contact_label_assignment.dart' as _i29;
import 'contact_link.dart' as _i30;
import 'contact_meta.dart' as _i31;
import 'contact_profile_view.dart' as _i32;
import 'contact_relation.dart' as _i33;
import 'contact_request.dart' as _i34;
import 'contact_request_view.dart' as _i35;
import 'device_registration.dart' as _i36;
import 'device_session_info.dart' as _i37;
import 'email_account.dart' as _i38;
import 'email_session.dart' as _i39;
import 'email_verification_code.dart' as _i40;
import 'enums/attachment_reject_reason.dart' as _i41;
import 'enums/call_event_type.dart' as _i42;
import 'enums/call_status.dart' as _i43;
import 'enums/contact_link_source.dart' as _i44;
import 'enums/contact_request_status.dart' as _i45;
import 'enums/device_platform.dart' as _i46;
import 'enums/identity_provider.dart' as _i47;
import 'enums/messenger_event_type.dart' as _i48;
import 'enums/participant_kind.dart' as _i49;
import 'enums/product_notification_status.dart' as _i50;
import 'enums/push_service.dart' as _i51;
import 'enums/room_member_role.dart' as _i52;
import 'enums/room_ownership.dart' as _i53;
import 'enums/room_state.dart' as _i54;
import 'enums/room_type.dart' as _i55;
import 'enums/support_team_role.dart' as _i56;
import 'enums/tenant_hosting_mode.dart' as _i57;
import 'enums/trust_token_kind.dart' as _i58;
import 'errors/adapter_not_configured_exception.dart' as _i59;
import 'errors/attachment_rejected_exception.dart' as _i60;
import 'errors/bot_capability_exception.dart' as _i61;
import 'errors/bot_limit_exceeded_exception.dart' as _i62;
import 'errors/bot_not_found_exception.dart' as _i63;
import 'errors/bot_read_restricted_exception.dart' as _i64;
import 'errors/conference_full_exception.dart' as _i65;
import 'errors/email_auth_exception.dart' as _i66;
import 'errors/insufficient_power_exception.dart' as _i67;
import 'errors/invalid_bot_commands_exception.dart' as _i68;
import 'errors/invalid_external_key_exception.dart' as _i69;
import 'errors/invalid_notification_exception.dart' as _i70;
import 'errors/invalid_token_exception.dart' as _i71;
import 'errors/last_owner_cannot_demote_exception.dart' as _i72;
import 'errors/message_body_too_large_exception.dart' as _i73;
import 'errors/message_deleted_exception.dart' as _i74;
import 'errors/message_not_editable_exception.dart' as _i75;
import 'errors/messenger_not_authenticated_exception.dart' as _i76;
import 'errors/not_object_room_exception.dart' as _i77;
import 'errors/not_support_team_member_exception.dart' as _i78;
import 'errors/not_support_team_owner_exception.dart' as _i79;
import 'errors/operator_email_not_resolved_exception.dart' as _i80;
import 'errors/peer_unavailable_exception.dart' as _i81;
import 'errors/product_already_exists_exception.dart' as _i82;
import 'errors/product_not_found_exception.dart' as _i83;
import 'errors/product_not_found_for_caller_exception.dart' as _i84;
import 'errors/rate_limit_exceeded_exception.dart' as _i85;
import 'errors/room_dissolve_partial_exception.dart' as _i86;
import 'errors/room_unavailable_exception.dart' as _i87;
import 'errors/screen_share_busy_exception.dart' as _i88;
import 'errors/task_integration_not_configured_exception.dart' as _i89;
import 'errors/tenant_already_exists_exception.dart' as _i90;
import 'errors/tenant_not_found_exception.dart' as _i91;
import 'errors/thumbnail_unavailable_exception.dart' as _i92;
import 'errors/write_banned_exception.dart' as _i93;
import 'escalation_result.dart' as _i94;
import 'greetings/greeting.dart' as _i95;
import 'identity_mapping.dart' as _i96;
import 'incoming_webhook.dart' as _i97;
import 'incoming_webhook_created.dart' as _i98;
import 'message_index.dart' as _i99;
import 'messenger_auth_context.dart' as _i100;
import 'messenger_event.dart' as _i101;
import 'messenger_message.dart' as _i102;
import 'messenger_message_list_page.dart' as _i103;
import 'messenger_session.dart' as _i104;
import 'messenger_session_token.dart' as _i105;
import 'messenger_user.dart' as _i106;
import 'nearby_confirm_result.dart' as _i107;
import 'nearby_confirmation.dart' as _i108;
import 'notification_settings.dart' as _i109;
import 'presence_conn_state.dart' as _i110;
import 'presence_info.dart' as _i111;
import 'presence_state.dart' as _i112;
import 'presence_watched_index.dart' as _i113;
import 'presence_watchers.dart' as _i114;
import 'product.dart' as _i115;
import 'product_admin_view.dart' as _i116;
import 'product_notification.dart' as _i117;
import 'product_notification_recipient_result.dart' as _i118;
import 'product_notification_send_result.dart' as _i119;
import 'product_object_room.dart' as _i120;
import 'profile_translation.dart' as _i121;
import 'pulse_access_audit_event.dart' as _i122;
import 'pulse_access_entry.dart' as _i123;
import 'pulse_alert_rule.dart' as _i124;
import 'pulse_event.dart' as _i125;
import 'pulse_folder.dart' as _i126;
import 'pulse_folder_membership.dart' as _i127;
import 'pulse_incident.dart' as _i128;
import 'pulse_member_view.dart' as _i129;
import 'pulse_monitor.dart' as _i130;
import 'pulse_monitor_created.dart' as _i131;
import 'pulse_monitor_membership.dart' as _i132;
import 'push_queue_message.dart' as _i133;
import 'push_test_job.dart' as _i134;
import 'push_test_result.dart' as _i135;
import 'room.dart' as _i136;
import 'room_bot_commands.dart' as _i137;
import 'room_details.dart' as _i138;
import 'room_list_page.dart' as _i139;
import 'room_membership.dart' as _i140;
import 'room_participant.dart' as _i141;
import 'room_summary.dart' as _i142;
import 'room_task_stats.dart' as _i143;
import 'support_team.dart' as _i144;
import 'support_team_member.dart' as _i145;
import 'support_team_member_view.dart' as _i146;
import 'support_team_view.dart' as _i147;
import 'task_link.dart' as _i148;
import 'task_manager_config.dart' as _i149;
import 'tenant.dart' as _i150;
import 'ticket.dart' as _i151;
import 'ticket_event.dart' as _i152;
import 'ticket_view.dart' as _i153;
import 'trust_redeem_result.dart' as _i154;
import 'trust_token.dart' as _i155;
import 'trust_token_issued.dart' as _i156;
import 'turn_credentials.dart' as _i157;
import 'webhook_delivery.dart' as _i158;
import 'webhook_event_message.dart' as _i159;
import 'webhook_subscription.dart' as _i160;
import 'package:nsg_connect_client/src/protocol/webhook_subscription.dart'
    as _i161;
import 'package:nsg_connect_client/src/protocol/webhook_delivery.dart' as _i162;
import 'package:nsg_connect_client/src/protocol/bot_audit_event.dart' as _i163;
import 'package:nsg_connect_client/src/protocol/bot.dart' as _i164;
import 'package:nsg_connect_client/src/protocol/room_summary.dart' as _i165;
import 'package:nsg_connect_client/src/protocol/available_bot.dart' as _i166;
import 'package:nsg_connect_client/src/protocol/bot_integration_view.dart'
    as _i167;
import 'package:nsg_connect_client/src/protocol/connect_tenant_status.dart'
    as _i168;
import 'package:nsg_connect_client/src/protocol/product_admin_view.dart'
    as _i169;
import 'package:nsg_connect_client/src/protocol/connect_key_audit_event.dart'
    as _i170;
import 'package:nsg_connect_client/src/protocol/device_session_info.dart'
    as _i171;
import 'package:nsg_connect_client/src/protocol/incoming_webhook.dart' as _i172;
import 'package:nsg_connect_client/src/protocol/bot_command.dart' as _i173;
import 'package:nsg_connect_client/src/protocol/room_bot_commands.dart'
    as _i174;
import 'package:nsg_connect_client/src/protocol/messenger_message.dart'
    as _i175;
import 'package:nsg_connect_client/src/protocol/call_ice_candidate.dart'
    as _i176;
import 'package:nsg_connect_client/src/protocol/call_history_entry.dart'
    as _i177;
import 'package:nsg_connect_client/src/protocol/messenger_event.dart' as _i178;
import 'package:nsg_connect_client/src/protocol/room_participant.dart' as _i179;
import 'package:nsg_connect_client/src/protocol/ticket_view.dart' as _i180;
import 'package:nsg_connect_client/src/protocol/presence_info.dart' as _i181;
import 'package:nsg_connect_client/src/protocol/chat_folder_view.dart' as _i182;
import 'package:nsg_connect_client/src/protocol/contact_request_view.dart'
    as _i183;
import 'package:nsg_connect_client/src/protocol/contact_label.dart' as _i184;
import 'package:nsg_connect_client/src/protocol/contact_label_assignment.dart'
    as _i185;
import 'package:nsg_connect_client/src/protocol/product_object_room.dart'
    as _i186;
import 'package:nsg_connect_client/src/protocol/product.dart' as _i187;
import 'package:nsg_connect_client/src/protocol/profile_translation.dart'
    as _i188;
import 'package:nsg_connect_client/src/protocol/pulse_folder.dart' as _i189;
import 'package:nsg_connect_client/src/protocol/pulse_monitor.dart' as _i190;
import 'package:nsg_connect_client/src/protocol/pulse_alert_rule.dart' as _i191;
import 'package:nsg_connect_client/src/protocol/pulse_incident.dart' as _i192;
import 'package:nsg_connect_client/src/protocol/pulse_access_entry.dart'
    as _i193;
import 'package:nsg_connect_client/src/protocol/pulse_member_view.dart'
    as _i194;
import 'package:nsg_connect_client/src/protocol/pulse_access_audit_event.dart'
    as _i195;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i196;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i197;
export 'attachment_bytes.dart';
export 'attachment_ref.dart';
export 'available_bot.dart';
export 'bot.dart';
export 'bot_audit_event.dart';
export 'bot_command.dart';
export 'bot_integration_created.dart';
export 'bot_integration_view.dart';
export 'bot_read_mode_result.dart';
export 'call_history_entry.dart';
export 'call_ice_candidate.dart';
export 'chat_folder.dart';
export 'chat_folder_room.dart';
export 'chat_folder_view.dart';
export 'conference.dart';
export 'conference_member.dart';
export 'conference_participant.dart';
export 'conference_screen_share.dart';
export 'conference_state.dart';
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
export 'enums/attachment_reject_reason.dart';
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
export 'errors/attachment_rejected_exception.dart';
export 'errors/bot_capability_exception.dart';
export 'errors/bot_limit_exceeded_exception.dart';
export 'errors/bot_not_found_exception.dart';
export 'errors/bot_read_restricted_exception.dart';
export 'errors/conference_full_exception.dart';
export 'errors/email_auth_exception.dart';
export 'errors/insufficient_power_exception.dart';
export 'errors/invalid_bot_commands_exception.dart';
export 'errors/invalid_external_key_exception.dart';
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
export 'errors/operator_email_not_resolved_exception.dart';
export 'errors/peer_unavailable_exception.dart';
export 'errors/product_already_exists_exception.dart';
export 'errors/product_not_found_exception.dart';
export 'errors/product_not_found_for_caller_exception.dart';
export 'errors/rate_limit_exceeded_exception.dart';
export 'errors/room_dissolve_partial_exception.dart';
export 'errors/room_unavailable_exception.dart';
export 'errors/screen_share_busy_exception.dart';
export 'errors/task_integration_not_configured_exception.dart';
export 'errors/tenant_already_exists_exception.dart';
export 'errors/tenant_not_found_exception.dart';
export 'errors/thumbnail_unavailable_exception.dart';
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
export 'product_admin_view.dart';
export 'product_notification.dart';
export 'product_notification_recipient_result.dart';
export 'product_notification_send_result.dart';
export 'product_object_room.dart';
export 'profile_translation.dart';
export 'pulse_access_audit_event.dart';
export 'pulse_access_entry.dart';
export 'pulse_alert_rule.dart';
export 'pulse_event.dart';
export 'pulse_folder.dart';
export 'pulse_folder_membership.dart';
export 'pulse_incident.dart';
export 'pulse_member_view.dart';
export 'pulse_monitor.dart';
export 'pulse_monitor_created.dart';
export 'pulse_monitor_membership.dart';
export 'push_queue_message.dart';
export 'push_test_job.dart';
export 'push_test_result.dart';
export 'room.dart';
export 'room_bot_commands.dart';
export 'room_details.dart';
export 'room_list_page.dart';
export 'room_membership.dart';
export 'room_participant.dart';
export 'room_summary.dart';
export 'room_task_stats.dart';
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
    if (t == _i4.AvailableBot) {
      return _i4.AvailableBot.fromJson(data) as T;
    }
    if (t == _i5.Bot) {
      return _i5.Bot.fromJson(data) as T;
    }
    if (t == _i6.BotAuditEvent) {
      return _i6.BotAuditEvent.fromJson(data) as T;
    }
    if (t == _i7.BotCommand) {
      return _i7.BotCommand.fromJson(data) as T;
    }
    if (t == _i8.BotIntegrationCreated) {
      return _i8.BotIntegrationCreated.fromJson(data) as T;
    }
    if (t == _i9.BotIntegrationView) {
      return _i9.BotIntegrationView.fromJson(data) as T;
    }
    if (t == _i10.BotReadModeResult) {
      return _i10.BotReadModeResult.fromJson(data) as T;
    }
    if (t == _i11.CallHistoryEntry) {
      return _i11.CallHistoryEntry.fromJson(data) as T;
    }
    if (t == _i12.CallIceCandidate) {
      return _i12.CallIceCandidate.fromJson(data) as T;
    }
    if (t == _i13.ChatFolderRecord) {
      return _i13.ChatFolderRecord.fromJson(data) as T;
    }
    if (t == _i14.ChatFolderRoom) {
      return _i14.ChatFolderRoom.fromJson(data) as T;
    }
    if (t == _i15.ChatFolderView) {
      return _i15.ChatFolderView.fromJson(data) as T;
    }
    if (t == _i16.Conference) {
      return _i16.Conference.fromJson(data) as T;
    }
    if (t == _i17.ConferenceMember) {
      return _i17.ConferenceMember.fromJson(data) as T;
    }
    if (t == _i18.ConferenceParticipant) {
      return _i18.ConferenceParticipant.fromJson(data) as T;
    }
    if (t == _i19.ConferenceScreenShare) {
      return _i19.ConferenceScreenShare.fromJson(data) as T;
    }
    if (t == _i20.ConferenceState) {
      return _i20.ConferenceState.fromJson(data) as T;
    }
    if (t == _i21.ConnectIssuedToken) {
      return _i21.ConnectIssuedToken.fromJson(data) as T;
    }
    if (t == _i22.ConnectIssuedTokenResult) {
      return _i22.ConnectIssuedTokenResult.fromJson(data) as T;
    }
    if (t == _i23.ConnectKeyAuditEvent) {
      return _i23.ConnectKeyAuditEvent.fromJson(data) as T;
    }
    if (t == _i24.ConnectTenantStatus) {
      return _i24.ConnectTenantStatus.fromJson(data) as T;
    }
    if (t == _i25.ContactBlock) {
      return _i25.ContactBlock.fromJson(data) as T;
    }
    if (t == _i26.ContactCard) {
      return _i26.ContactCard.fromJson(data) as T;
    }
    if (t == _i27.ContactCardInfo) {
      return _i27.ContactCardInfo.fromJson(data) as T;
    }
    if (t == _i28.ContactLabel) {
      return _i28.ContactLabel.fromJson(data) as T;
    }
    if (t == _i29.ContactLabelAssignment) {
      return _i29.ContactLabelAssignment.fromJson(data) as T;
    }
    if (t == _i30.ContactLink) {
      return _i30.ContactLink.fromJson(data) as T;
    }
    if (t == _i31.ContactMeta) {
      return _i31.ContactMeta.fromJson(data) as T;
    }
    if (t == _i32.ContactProfileView) {
      return _i32.ContactProfileView.fromJson(data) as T;
    }
    if (t == _i33.ContactRelation) {
      return _i33.ContactRelation.fromJson(data) as T;
    }
    if (t == _i34.ContactRequest) {
      return _i34.ContactRequest.fromJson(data) as T;
    }
    if (t == _i35.ContactRequestView) {
      return _i35.ContactRequestView.fromJson(data) as T;
    }
    if (t == _i36.DeviceRegistration) {
      return _i36.DeviceRegistration.fromJson(data) as T;
    }
    if (t == _i37.DeviceSessionInfo) {
      return _i37.DeviceSessionInfo.fromJson(data) as T;
    }
    if (t == _i38.EmailAccount) {
      return _i38.EmailAccount.fromJson(data) as T;
    }
    if (t == _i39.EmailSession) {
      return _i39.EmailSession.fromJson(data) as T;
    }
    if (t == _i40.EmailVerificationCode) {
      return _i40.EmailVerificationCode.fromJson(data) as T;
    }
    if (t == _i41.AttachmentRejectReason) {
      return _i41.AttachmentRejectReason.fromJson(data) as T;
    }
    if (t == _i42.CallEventType) {
      return _i42.CallEventType.fromJson(data) as T;
    }
    if (t == _i43.CallStatus) {
      return _i43.CallStatus.fromJson(data) as T;
    }
    if (t == _i44.ContactLinkSource) {
      return _i44.ContactLinkSource.fromJson(data) as T;
    }
    if (t == _i45.ContactRequestStatus) {
      return _i45.ContactRequestStatus.fromJson(data) as T;
    }
    if (t == _i46.DevicePlatform) {
      return _i46.DevicePlatform.fromJson(data) as T;
    }
    if (t == _i47.IdentityProvider) {
      return _i47.IdentityProvider.fromJson(data) as T;
    }
    if (t == _i48.MessengerEventType) {
      return _i48.MessengerEventType.fromJson(data) as T;
    }
    if (t == _i49.ParticipantKind) {
      return _i49.ParticipantKind.fromJson(data) as T;
    }
    if (t == _i50.ProductNotificationStatus) {
      return _i50.ProductNotificationStatus.fromJson(data) as T;
    }
    if (t == _i51.PushService) {
      return _i51.PushService.fromJson(data) as T;
    }
    if (t == _i52.RoomMemberRole) {
      return _i52.RoomMemberRole.fromJson(data) as T;
    }
    if (t == _i53.RoomOwnership) {
      return _i53.RoomOwnership.fromJson(data) as T;
    }
    if (t == _i54.RoomState) {
      return _i54.RoomState.fromJson(data) as T;
    }
    if (t == _i55.RoomType) {
      return _i55.RoomType.fromJson(data) as T;
    }
    if (t == _i56.SupportTeamRole) {
      return _i56.SupportTeamRole.fromJson(data) as T;
    }
    if (t == _i57.TenantHostingMode) {
      return _i57.TenantHostingMode.fromJson(data) as T;
    }
    if (t == _i58.TrustTokenKind) {
      return _i58.TrustTokenKind.fromJson(data) as T;
    }
    if (t == _i59.AdapterNotConfiguredException) {
      return _i59.AdapterNotConfiguredException.fromJson(data) as T;
    }
    if (t == _i60.AttachmentRejectedException) {
      return _i60.AttachmentRejectedException.fromJson(data) as T;
    }
    if (t == _i61.BotCapabilityException) {
      return _i61.BotCapabilityException.fromJson(data) as T;
    }
    if (t == _i62.BotLimitExceededException) {
      return _i62.BotLimitExceededException.fromJson(data) as T;
    }
    if (t == _i63.BotNotFoundException) {
      return _i63.BotNotFoundException.fromJson(data) as T;
    }
    if (t == _i64.BotReadRestrictedException) {
      return _i64.BotReadRestrictedException.fromJson(data) as T;
    }
    if (t == _i65.ConferenceFullException) {
      return _i65.ConferenceFullException.fromJson(data) as T;
    }
    if (t == _i66.EmailAuthException) {
      return _i66.EmailAuthException.fromJson(data) as T;
    }
    if (t == _i67.InsufficientPowerException) {
      return _i67.InsufficientPowerException.fromJson(data) as T;
    }
    if (t == _i68.InvalidBotCommandsException) {
      return _i68.InvalidBotCommandsException.fromJson(data) as T;
    }
    if (t == _i69.InvalidExternalKeyException) {
      return _i69.InvalidExternalKeyException.fromJson(data) as T;
    }
    if (t == _i70.InvalidNotificationException) {
      return _i70.InvalidNotificationException.fromJson(data) as T;
    }
    if (t == _i71.InvalidTokenException) {
      return _i71.InvalidTokenException.fromJson(data) as T;
    }
    if (t == _i72.LastOwnerCannotDemoteException) {
      return _i72.LastOwnerCannotDemoteException.fromJson(data) as T;
    }
    if (t == _i73.MessageBodyTooLargeException) {
      return _i73.MessageBodyTooLargeException.fromJson(data) as T;
    }
    if (t == _i74.MessageDeletedException) {
      return _i74.MessageDeletedException.fromJson(data) as T;
    }
    if (t == _i75.MessageNotEditableException) {
      return _i75.MessageNotEditableException.fromJson(data) as T;
    }
    if (t == _i76.MessengerNotAuthenticatedException) {
      return _i76.MessengerNotAuthenticatedException.fromJson(data) as T;
    }
    if (t == _i77.NotObjectRoomException) {
      return _i77.NotObjectRoomException.fromJson(data) as T;
    }
    if (t == _i78.NotSupportTeamMemberException) {
      return _i78.NotSupportTeamMemberException.fromJson(data) as T;
    }
    if (t == _i79.NotSupportTeamOwnerException) {
      return _i79.NotSupportTeamOwnerException.fromJson(data) as T;
    }
    if (t == _i80.OperatorEmailNotResolvedException) {
      return _i80.OperatorEmailNotResolvedException.fromJson(data) as T;
    }
    if (t == _i81.PeerUnavailableException) {
      return _i81.PeerUnavailableException.fromJson(data) as T;
    }
    if (t == _i82.ProductAlreadyExistsException) {
      return _i82.ProductAlreadyExistsException.fromJson(data) as T;
    }
    if (t == _i83.ProductNotFoundException) {
      return _i83.ProductNotFoundException.fromJson(data) as T;
    }
    if (t == _i84.ProductNotFoundForCallerException) {
      return _i84.ProductNotFoundForCallerException.fromJson(data) as T;
    }
    if (t == _i85.RateLimitExceededException) {
      return _i85.RateLimitExceededException.fromJson(data) as T;
    }
    if (t == _i86.RoomDissolvePartialException) {
      return _i86.RoomDissolvePartialException.fromJson(data) as T;
    }
    if (t == _i87.RoomUnavailableException) {
      return _i87.RoomUnavailableException.fromJson(data) as T;
    }
    if (t == _i88.ScreenShareBusyException) {
      return _i88.ScreenShareBusyException.fromJson(data) as T;
    }
    if (t == _i89.TaskIntegrationNotConfiguredException) {
      return _i89.TaskIntegrationNotConfiguredException.fromJson(data) as T;
    }
    if (t == _i90.TenantAlreadyExistsException) {
      return _i90.TenantAlreadyExistsException.fromJson(data) as T;
    }
    if (t == _i91.TenantNotFoundException) {
      return _i91.TenantNotFoundException.fromJson(data) as T;
    }
    if (t == _i92.ThumbnailUnavailableException) {
      return _i92.ThumbnailUnavailableException.fromJson(data) as T;
    }
    if (t == _i93.WriteBannedException) {
      return _i93.WriteBannedException.fromJson(data) as T;
    }
    if (t == _i94.EscalationResult) {
      return _i94.EscalationResult.fromJson(data) as T;
    }
    if (t == _i95.Greeting) {
      return _i95.Greeting.fromJson(data) as T;
    }
    if (t == _i96.IdentityMapping) {
      return _i96.IdentityMapping.fromJson(data) as T;
    }
    if (t == _i97.IncomingWebhook) {
      return _i97.IncomingWebhook.fromJson(data) as T;
    }
    if (t == _i98.IncomingWebhookCreated) {
      return _i98.IncomingWebhookCreated.fromJson(data) as T;
    }
    if (t == _i99.MessageIndex) {
      return _i99.MessageIndex.fromJson(data) as T;
    }
    if (t == _i100.MessengerAuthContext) {
      return _i100.MessengerAuthContext.fromJson(data) as T;
    }
    if (t == _i101.MessengerEvent) {
      return _i101.MessengerEvent.fromJson(data) as T;
    }
    if (t == _i102.MessengerMessage) {
      return _i102.MessengerMessage.fromJson(data) as T;
    }
    if (t == _i103.MessengerMessageListPage) {
      return _i103.MessengerMessageListPage.fromJson(data) as T;
    }
    if (t == _i104.MessengerSession) {
      return _i104.MessengerSession.fromJson(data) as T;
    }
    if (t == _i105.MessengerSessionToken) {
      return _i105.MessengerSessionToken.fromJson(data) as T;
    }
    if (t == _i106.MessengerUser) {
      return _i106.MessengerUser.fromJson(data) as T;
    }
    if (t == _i107.NearbyConfirmResult) {
      return _i107.NearbyConfirmResult.fromJson(data) as T;
    }
    if (t == _i108.NearbyConfirmation) {
      return _i108.NearbyConfirmation.fromJson(data) as T;
    }
    if (t == _i109.NotificationSettings) {
      return _i109.NotificationSettings.fromJson(data) as T;
    }
    if (t == _i110.PresenceConnState) {
      return _i110.PresenceConnState.fromJson(data) as T;
    }
    if (t == _i111.PresenceInfo) {
      return _i111.PresenceInfo.fromJson(data) as T;
    }
    if (t == _i112.PresenceState) {
      return _i112.PresenceState.fromJson(data) as T;
    }
    if (t == _i113.PresenceWatchedIndex) {
      return _i113.PresenceWatchedIndex.fromJson(data) as T;
    }
    if (t == _i114.PresenceWatchers) {
      return _i114.PresenceWatchers.fromJson(data) as T;
    }
    if (t == _i115.Product) {
      return _i115.Product.fromJson(data) as T;
    }
    if (t == _i116.ProductAdminView) {
      return _i116.ProductAdminView.fromJson(data) as T;
    }
    if (t == _i117.ProductNotification) {
      return _i117.ProductNotification.fromJson(data) as T;
    }
    if (t == _i118.ProductNotificationRecipientResult) {
      return _i118.ProductNotificationRecipientResult.fromJson(data) as T;
    }
    if (t == _i119.ProductNotificationSendResult) {
      return _i119.ProductNotificationSendResult.fromJson(data) as T;
    }
    if (t == _i120.ProductObjectRoom) {
      return _i120.ProductObjectRoom.fromJson(data) as T;
    }
    if (t == _i121.ProfileTranslation) {
      return _i121.ProfileTranslation.fromJson(data) as T;
    }
    if (t == _i122.PulseAccessAuditEvent) {
      return _i122.PulseAccessAuditEvent.fromJson(data) as T;
    }
    if (t == _i123.PulseAccessEntry) {
      return _i123.PulseAccessEntry.fromJson(data) as T;
    }
    if (t == _i124.PulseAlertRule) {
      return _i124.PulseAlertRule.fromJson(data) as T;
    }
    if (t == _i125.PulseEvent) {
      return _i125.PulseEvent.fromJson(data) as T;
    }
    if (t == _i126.PulseFolder) {
      return _i126.PulseFolder.fromJson(data) as T;
    }
    if (t == _i127.PulseFolderMembership) {
      return _i127.PulseFolderMembership.fromJson(data) as T;
    }
    if (t == _i128.PulseIncident) {
      return _i128.PulseIncident.fromJson(data) as T;
    }
    if (t == _i129.PulseMemberView) {
      return _i129.PulseMemberView.fromJson(data) as T;
    }
    if (t == _i130.PulseMonitor) {
      return _i130.PulseMonitor.fromJson(data) as T;
    }
    if (t == _i131.PulseMonitorCreated) {
      return _i131.PulseMonitorCreated.fromJson(data) as T;
    }
    if (t == _i132.PulseMonitorMembership) {
      return _i132.PulseMonitorMembership.fromJson(data) as T;
    }
    if (t == _i133.PushQueueMessage) {
      return _i133.PushQueueMessage.fromJson(data) as T;
    }
    if (t == _i134.PushTestJob) {
      return _i134.PushTestJob.fromJson(data) as T;
    }
    if (t == _i135.PushTestResult) {
      return _i135.PushTestResult.fromJson(data) as T;
    }
    if (t == _i136.Room) {
      return _i136.Room.fromJson(data) as T;
    }
    if (t == _i137.RoomBotCommands) {
      return _i137.RoomBotCommands.fromJson(data) as T;
    }
    if (t == _i138.RoomDetails) {
      return _i138.RoomDetails.fromJson(data) as T;
    }
    if (t == _i139.RoomListPage) {
      return _i139.RoomListPage.fromJson(data) as T;
    }
    if (t == _i140.RoomMembership) {
      return _i140.RoomMembership.fromJson(data) as T;
    }
    if (t == _i141.RoomParticipant) {
      return _i141.RoomParticipant.fromJson(data) as T;
    }
    if (t == _i142.RoomSummary) {
      return _i142.RoomSummary.fromJson(data) as T;
    }
    if (t == _i143.RoomTaskStats) {
      return _i143.RoomTaskStats.fromJson(data) as T;
    }
    if (t == _i144.SupportTeam) {
      return _i144.SupportTeam.fromJson(data) as T;
    }
    if (t == _i145.SupportTeamMember) {
      return _i145.SupportTeamMember.fromJson(data) as T;
    }
    if (t == _i146.SupportTeamMemberView) {
      return _i146.SupportTeamMemberView.fromJson(data) as T;
    }
    if (t == _i147.SupportTeamView) {
      return _i147.SupportTeamView.fromJson(data) as T;
    }
    if (t == _i148.TaskLink) {
      return _i148.TaskLink.fromJson(data) as T;
    }
    if (t == _i149.TaskManagerConfig) {
      return _i149.TaskManagerConfig.fromJson(data) as T;
    }
    if (t == _i150.Tenant) {
      return _i150.Tenant.fromJson(data) as T;
    }
    if (t == _i151.Ticket) {
      return _i151.Ticket.fromJson(data) as T;
    }
    if (t == _i152.TicketEvent) {
      return _i152.TicketEvent.fromJson(data) as T;
    }
    if (t == _i153.TicketView) {
      return _i153.TicketView.fromJson(data) as T;
    }
    if (t == _i154.TrustRedeemResult) {
      return _i154.TrustRedeemResult.fromJson(data) as T;
    }
    if (t == _i155.TrustToken) {
      return _i155.TrustToken.fromJson(data) as T;
    }
    if (t == _i156.TrustTokenIssued) {
      return _i156.TrustTokenIssued.fromJson(data) as T;
    }
    if (t == _i157.TurnCredentials) {
      return _i157.TurnCredentials.fromJson(data) as T;
    }
    if (t == _i158.WebhookDelivery) {
      return _i158.WebhookDelivery.fromJson(data) as T;
    }
    if (t == _i159.WebhookEventMessage) {
      return _i159.WebhookEventMessage.fromJson(data) as T;
    }
    if (t == _i160.WebhookSubscription) {
      return _i160.WebhookSubscription.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AttachmentBytes?>()) {
      return (data != null ? _i2.AttachmentBytes.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AttachmentRef?>()) {
      return (data != null ? _i3.AttachmentRef.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.AvailableBot?>()) {
      return (data != null ? _i4.AvailableBot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.Bot?>()) {
      return (data != null ? _i5.Bot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.BotAuditEvent?>()) {
      return (data != null ? _i6.BotAuditEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.BotCommand?>()) {
      return (data != null ? _i7.BotCommand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.BotIntegrationCreated?>()) {
      return (data != null ? _i8.BotIntegrationCreated.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.BotIntegrationView?>()) {
      return (data != null ? _i9.BotIntegrationView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.BotReadModeResult?>()) {
      return (data != null ? _i10.BotReadModeResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.CallHistoryEntry?>()) {
      return (data != null ? _i11.CallHistoryEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.CallIceCandidate?>()) {
      return (data != null ? _i12.CallIceCandidate.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.ChatFolderRecord?>()) {
      return (data != null ? _i13.ChatFolderRecord.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.ChatFolderRoom?>()) {
      return (data != null ? _i14.ChatFolderRoom.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.ChatFolderView?>()) {
      return (data != null ? _i15.ChatFolderView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.Conference?>()) {
      return (data != null ? _i16.Conference.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.ConferenceMember?>()) {
      return (data != null ? _i17.ConferenceMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.ConferenceParticipant?>()) {
      return (data != null ? _i18.ConferenceParticipant.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.ConferenceScreenShare?>()) {
      return (data != null ? _i19.ConferenceScreenShare.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i20.ConferenceState?>()) {
      return (data != null ? _i20.ConferenceState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.ConnectIssuedToken?>()) {
      return (data != null ? _i21.ConnectIssuedToken.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i22.ConnectIssuedTokenResult?>()) {
      return (data != null
              ? _i22.ConnectIssuedTokenResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i23.ConnectKeyAuditEvent?>()) {
      return (data != null ? _i23.ConnectKeyAuditEvent.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i24.ConnectTenantStatus?>()) {
      return (data != null ? _i24.ConnectTenantStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i25.ContactBlock?>()) {
      return (data != null ? _i25.ContactBlock.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.ContactCard?>()) {
      return (data != null ? _i26.ContactCard.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.ContactCardInfo?>()) {
      return (data != null ? _i27.ContactCardInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.ContactLabel?>()) {
      return (data != null ? _i28.ContactLabel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.ContactLabelAssignment?>()) {
      return (data != null ? _i29.ContactLabelAssignment.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i30.ContactLink?>()) {
      return (data != null ? _i30.ContactLink.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i31.ContactMeta?>()) {
      return (data != null ? _i31.ContactMeta.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i32.ContactProfileView?>()) {
      return (data != null ? _i32.ContactProfileView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i33.ContactRelation?>()) {
      return (data != null ? _i33.ContactRelation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i34.ContactRequest?>()) {
      return (data != null ? _i34.ContactRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i35.ContactRequestView?>()) {
      return (data != null ? _i35.ContactRequestView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i36.DeviceRegistration?>()) {
      return (data != null ? _i36.DeviceRegistration.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i37.DeviceSessionInfo?>()) {
      return (data != null ? _i37.DeviceSessionInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i38.EmailAccount?>()) {
      return (data != null ? _i38.EmailAccount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i39.EmailSession?>()) {
      return (data != null ? _i39.EmailSession.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i40.EmailVerificationCode?>()) {
      return (data != null ? _i40.EmailVerificationCode.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i41.AttachmentRejectReason?>()) {
      return (data != null ? _i41.AttachmentRejectReason.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i42.CallEventType?>()) {
      return (data != null ? _i42.CallEventType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i43.CallStatus?>()) {
      return (data != null ? _i43.CallStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i44.ContactLinkSource?>()) {
      return (data != null ? _i44.ContactLinkSource.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i45.ContactRequestStatus?>()) {
      return (data != null ? _i45.ContactRequestStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i46.DevicePlatform?>()) {
      return (data != null ? _i46.DevicePlatform.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i47.IdentityProvider?>()) {
      return (data != null ? _i47.IdentityProvider.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i48.MessengerEventType?>()) {
      return (data != null ? _i48.MessengerEventType.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i49.ParticipantKind?>()) {
      return (data != null ? _i49.ParticipantKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i50.ProductNotificationStatus?>()) {
      return (data != null
              ? _i50.ProductNotificationStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i51.PushService?>()) {
      return (data != null ? _i51.PushService.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i52.RoomMemberRole?>()) {
      return (data != null ? _i52.RoomMemberRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i53.RoomOwnership?>()) {
      return (data != null ? _i53.RoomOwnership.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i54.RoomState?>()) {
      return (data != null ? _i54.RoomState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i55.RoomType?>()) {
      return (data != null ? _i55.RoomType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i56.SupportTeamRole?>()) {
      return (data != null ? _i56.SupportTeamRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i57.TenantHostingMode?>()) {
      return (data != null ? _i57.TenantHostingMode.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i58.TrustTokenKind?>()) {
      return (data != null ? _i58.TrustTokenKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i59.AdapterNotConfiguredException?>()) {
      return (data != null
              ? _i59.AdapterNotConfiguredException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i60.AttachmentRejectedException?>()) {
      return (data != null
              ? _i60.AttachmentRejectedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i61.BotCapabilityException?>()) {
      return (data != null ? _i61.BotCapabilityException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i62.BotLimitExceededException?>()) {
      return (data != null
              ? _i62.BotLimitExceededException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i63.BotNotFoundException?>()) {
      return (data != null ? _i63.BotNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i64.BotReadRestrictedException?>()) {
      return (data != null
              ? _i64.BotReadRestrictedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i65.ConferenceFullException?>()) {
      return (data != null ? _i65.ConferenceFullException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i66.EmailAuthException?>()) {
      return (data != null ? _i66.EmailAuthException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i67.InsufficientPowerException?>()) {
      return (data != null
              ? _i67.InsufficientPowerException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i68.InvalidBotCommandsException?>()) {
      return (data != null
              ? _i68.InvalidBotCommandsException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i69.InvalidExternalKeyException?>()) {
      return (data != null
              ? _i69.InvalidExternalKeyException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i70.InvalidNotificationException?>()) {
      return (data != null
              ? _i70.InvalidNotificationException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i71.InvalidTokenException?>()) {
      return (data != null ? _i71.InvalidTokenException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i72.LastOwnerCannotDemoteException?>()) {
      return (data != null
              ? _i72.LastOwnerCannotDemoteException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i73.MessageBodyTooLargeException?>()) {
      return (data != null
              ? _i73.MessageBodyTooLargeException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i74.MessageDeletedException?>()) {
      return (data != null ? _i74.MessageDeletedException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i75.MessageNotEditableException?>()) {
      return (data != null
              ? _i75.MessageNotEditableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i76.MessengerNotAuthenticatedException?>()) {
      return (data != null
              ? _i76.MessengerNotAuthenticatedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i77.NotObjectRoomException?>()) {
      return (data != null ? _i77.NotObjectRoomException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i78.NotSupportTeamMemberException?>()) {
      return (data != null
              ? _i78.NotSupportTeamMemberException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i79.NotSupportTeamOwnerException?>()) {
      return (data != null
              ? _i79.NotSupportTeamOwnerException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i80.OperatorEmailNotResolvedException?>()) {
      return (data != null
              ? _i80.OperatorEmailNotResolvedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i81.PeerUnavailableException?>()) {
      return (data != null
              ? _i81.PeerUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i82.ProductAlreadyExistsException?>()) {
      return (data != null
              ? _i82.ProductAlreadyExistsException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i83.ProductNotFoundException?>()) {
      return (data != null
              ? _i83.ProductNotFoundException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i84.ProductNotFoundForCallerException?>()) {
      return (data != null
              ? _i84.ProductNotFoundForCallerException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i85.RateLimitExceededException?>()) {
      return (data != null
              ? _i85.RateLimitExceededException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i86.RoomDissolvePartialException?>()) {
      return (data != null
              ? _i86.RoomDissolvePartialException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i87.RoomUnavailableException?>()) {
      return (data != null
              ? _i87.RoomUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i88.ScreenShareBusyException?>()) {
      return (data != null
              ? _i88.ScreenShareBusyException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i89.TaskIntegrationNotConfiguredException?>()) {
      return (data != null
              ? _i89.TaskIntegrationNotConfiguredException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i90.TenantAlreadyExistsException?>()) {
      return (data != null
              ? _i90.TenantAlreadyExistsException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i91.TenantNotFoundException?>()) {
      return (data != null ? _i91.TenantNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i92.ThumbnailUnavailableException?>()) {
      return (data != null
              ? _i92.ThumbnailUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i93.WriteBannedException?>()) {
      return (data != null ? _i93.WriteBannedException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i94.EscalationResult?>()) {
      return (data != null ? _i94.EscalationResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i95.Greeting?>()) {
      return (data != null ? _i95.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i96.IdentityMapping?>()) {
      return (data != null ? _i96.IdentityMapping.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i97.IncomingWebhook?>()) {
      return (data != null ? _i97.IncomingWebhook.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i98.IncomingWebhookCreated?>()) {
      return (data != null ? _i98.IncomingWebhookCreated.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i99.MessageIndex?>()) {
      return (data != null ? _i99.MessageIndex.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i100.MessengerAuthContext?>()) {
      return (data != null ? _i100.MessengerAuthContext.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i101.MessengerEvent?>()) {
      return (data != null ? _i101.MessengerEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i102.MessengerMessage?>()) {
      return (data != null ? _i102.MessengerMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i103.MessengerMessageListPage?>()) {
      return (data != null
              ? _i103.MessengerMessageListPage.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i104.MessengerSession?>()) {
      return (data != null ? _i104.MessengerSession.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i105.MessengerSessionToken?>()) {
      return (data != null ? _i105.MessengerSessionToken.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i106.MessengerUser?>()) {
      return (data != null ? _i106.MessengerUser.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i107.NearbyConfirmResult?>()) {
      return (data != null ? _i107.NearbyConfirmResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i108.NearbyConfirmation?>()) {
      return (data != null ? _i108.NearbyConfirmation.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i109.NotificationSettings?>()) {
      return (data != null ? _i109.NotificationSettings.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i110.PresenceConnState?>()) {
      return (data != null ? _i110.PresenceConnState.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i111.PresenceInfo?>()) {
      return (data != null ? _i111.PresenceInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i112.PresenceState?>()) {
      return (data != null ? _i112.PresenceState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i113.PresenceWatchedIndex?>()) {
      return (data != null ? _i113.PresenceWatchedIndex.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i114.PresenceWatchers?>()) {
      return (data != null ? _i114.PresenceWatchers.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i115.Product?>()) {
      return (data != null ? _i115.Product.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i116.ProductAdminView?>()) {
      return (data != null ? _i116.ProductAdminView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i117.ProductNotification?>()) {
      return (data != null ? _i117.ProductNotification.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i118.ProductNotificationRecipientResult?>()) {
      return (data != null
              ? _i118.ProductNotificationRecipientResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i119.ProductNotificationSendResult?>()) {
      return (data != null
              ? _i119.ProductNotificationSendResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i120.ProductObjectRoom?>()) {
      return (data != null ? _i120.ProductObjectRoom.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i121.ProfileTranslation?>()) {
      return (data != null ? _i121.ProfileTranslation.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i122.PulseAccessAuditEvent?>()) {
      return (data != null ? _i122.PulseAccessAuditEvent.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i123.PulseAccessEntry?>()) {
      return (data != null ? _i123.PulseAccessEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i124.PulseAlertRule?>()) {
      return (data != null ? _i124.PulseAlertRule.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i125.PulseEvent?>()) {
      return (data != null ? _i125.PulseEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i126.PulseFolder?>()) {
      return (data != null ? _i126.PulseFolder.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i127.PulseFolderMembership?>()) {
      return (data != null ? _i127.PulseFolderMembership.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i128.PulseIncident?>()) {
      return (data != null ? _i128.PulseIncident.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i129.PulseMemberView?>()) {
      return (data != null ? _i129.PulseMemberView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i130.PulseMonitor?>()) {
      return (data != null ? _i130.PulseMonitor.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i131.PulseMonitorCreated?>()) {
      return (data != null ? _i131.PulseMonitorCreated.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i132.PulseMonitorMembership?>()) {
      return (data != null ? _i132.PulseMonitorMembership.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i133.PushQueueMessage?>()) {
      return (data != null ? _i133.PushQueueMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i134.PushTestJob?>()) {
      return (data != null ? _i134.PushTestJob.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i135.PushTestResult?>()) {
      return (data != null ? _i135.PushTestResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i136.Room?>()) {
      return (data != null ? _i136.Room.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i137.RoomBotCommands?>()) {
      return (data != null ? _i137.RoomBotCommands.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i138.RoomDetails?>()) {
      return (data != null ? _i138.RoomDetails.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i139.RoomListPage?>()) {
      return (data != null ? _i139.RoomListPage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i140.RoomMembership?>()) {
      return (data != null ? _i140.RoomMembership.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i141.RoomParticipant?>()) {
      return (data != null ? _i141.RoomParticipant.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i142.RoomSummary?>()) {
      return (data != null ? _i142.RoomSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i143.RoomTaskStats?>()) {
      return (data != null ? _i143.RoomTaskStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i144.SupportTeam?>()) {
      return (data != null ? _i144.SupportTeam.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i145.SupportTeamMember?>()) {
      return (data != null ? _i145.SupportTeamMember.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i146.SupportTeamMemberView?>()) {
      return (data != null ? _i146.SupportTeamMemberView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i147.SupportTeamView?>()) {
      return (data != null ? _i147.SupportTeamView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i148.TaskLink?>()) {
      return (data != null ? _i148.TaskLink.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i149.TaskManagerConfig?>()) {
      return (data != null ? _i149.TaskManagerConfig.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i150.Tenant?>()) {
      return (data != null ? _i150.Tenant.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i151.Ticket?>()) {
      return (data != null ? _i151.Ticket.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i152.TicketEvent?>()) {
      return (data != null ? _i152.TicketEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i153.TicketView?>()) {
      return (data != null ? _i153.TicketView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i154.TrustRedeemResult?>()) {
      return (data != null ? _i154.TrustRedeemResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i155.TrustToken?>()) {
      return (data != null ? _i155.TrustToken.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i156.TrustTokenIssued?>()) {
      return (data != null ? _i156.TrustTokenIssued.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i157.TurnCredentials?>()) {
      return (data != null ? _i157.TurnCredentials.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i158.WebhookDelivery?>()) {
      return (data != null ? _i158.WebhookDelivery.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i159.WebhookEventMessage?>()) {
      return (data != null ? _i159.WebhookEventMessage.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i160.WebhookSubscription?>()) {
      return (data != null ? _i160.WebhookSubscription.fromJson(data) : null)
          as T;
    }
    if (t == List<_i7.BotCommand>) {
      return (data as List).map((e) => deserialize<_i7.BotCommand>(e)).toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i17.ConferenceMember>) {
      return (data as List)
              .map((e) => deserialize<_i17.ConferenceMember>(e))
              .toList()
          as T;
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
    if (t == List<_i12.CallIceCandidate>) {
      return (data as List)
              .map((e) => deserialize<_i12.CallIceCandidate>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i12.CallIceCandidate>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i12.CallIceCandidate>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == _i1.getType<List<_i17.ConferenceMember>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i17.ConferenceMember>(e))
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
    if (t == List<_i102.MessengerMessage>) {
      return (data as List)
              .map((e) => deserialize<_i102.MessengerMessage>(e))
              .toList()
          as T;
    }
    if (t == List<_i118.ProductNotificationRecipientResult>) {
      return (data as List)
              .map(
                (e) => deserialize<_i118.ProductNotificationRecipientResult>(e),
              )
              .toList()
          as T;
    }
    if (t == List<_i141.RoomParticipant>) {
      return (data as List)
              .map((e) => deserialize<_i141.RoomParticipant>(e))
              .toList()
          as T;
    }
    if (t == List<_i142.RoomSummary>) {
      return (data as List)
              .map((e) => deserialize<_i142.RoomSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i146.SupportTeamMemberView>) {
      return (data as List)
              .map((e) => deserialize<_i146.SupportTeamMemberView>(e))
              .toList()
          as T;
    }
    if (t == List<_i161.WebhookSubscription>) {
      return (data as List)
              .map((e) => deserialize<_i161.WebhookSubscription>(e))
              .toList()
          as T;
    }
    if (t == List<_i162.WebhookDelivery>) {
      return (data as List)
              .map((e) => deserialize<_i162.WebhookDelivery>(e))
              .toList()
          as T;
    }
    if (t == List<_i163.BotAuditEvent>) {
      return (data as List)
              .map((e) => deserialize<_i163.BotAuditEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i164.Bot>) {
      return (data as List).map((e) => deserialize<_i164.Bot>(e)).toList() as T;
    }
    if (t == List<_i165.RoomSummary>) {
      return (data as List)
              .map((e) => deserialize<_i165.RoomSummary>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i166.AvailableBot>) {
      return (data as List)
              .map((e) => deserialize<_i166.AvailableBot>(e))
              .toList()
          as T;
    }
    if (t == List<_i167.BotIntegrationView>) {
      return (data as List)
              .map((e) => deserialize<_i167.BotIntegrationView>(e))
              .toList()
          as T;
    }
    if (t == List<_i168.ConnectTenantStatus>) {
      return (data as List)
              .map((e) => deserialize<_i168.ConnectTenantStatus>(e))
              .toList()
          as T;
    }
    if (t == List<_i169.ProductAdminView>) {
      return (data as List)
              .map((e) => deserialize<_i169.ProductAdminView>(e))
              .toList()
          as T;
    }
    if (t == List<_i170.ConnectKeyAuditEvent>) {
      return (data as List)
              .map((e) => deserialize<_i170.ConnectKeyAuditEvent>(e))
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
    if (t == List<_i171.DeviceSessionInfo>) {
      return (data as List)
              .map((e) => deserialize<_i171.DeviceSessionInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i172.IncomingWebhook>) {
      return (data as List)
              .map((e) => deserialize<_i172.IncomingWebhook>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i173.BotCommand>) {
      return (data as List)
              .map((e) => deserialize<_i173.BotCommand>(e))
              .toList()
          as T;
    }
    if (t == List<_i174.RoomBotCommands>) {
      return (data as List)
              .map((e) => deserialize<_i174.RoomBotCommands>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i175.MessengerMessage>) {
      return (data as List)
              .map((e) => deserialize<_i175.MessengerMessage>(e))
              .toList()
          as T;
    }
    if (t == List<_i176.CallIceCandidate>) {
      return (data as List)
              .map((e) => deserialize<_i176.CallIceCandidate>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i176.CallIceCandidate>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i176.CallIceCandidate>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i177.CallHistoryEntry>) {
      return (data as List)
              .map((e) => deserialize<_i177.CallHistoryEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i178.MessengerEvent>) {
      return (data as List)
              .map((e) => deserialize<_i178.MessengerEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i179.RoomParticipant>) {
      return (data as List)
              .map((e) => deserialize<_i179.RoomParticipant>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i180.TicketView>) {
      return (data as List)
              .map((e) => deserialize<_i180.TicketView>(e))
              .toList()
          as T;
    }
    if (t == List<_i181.PresenceInfo>) {
      return (data as List)
              .map((e) => deserialize<_i181.PresenceInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i182.ChatFolderView>) {
      return (data as List)
              .map((e) => deserialize<_i182.ChatFolderView>(e))
              .toList()
          as T;
    }
    if (t == List<_i183.ContactRequestView>) {
      return (data as List)
              .map((e) => deserialize<_i183.ContactRequestView>(e))
              .toList()
          as T;
    }
    if (t == List<_i184.ContactLabel>) {
      return (data as List)
              .map((e) => deserialize<_i184.ContactLabel>(e))
              .toList()
          as T;
    }
    if (t == List<_i185.ContactLabelAssignment>) {
      return (data as List)
              .map((e) => deserialize<_i185.ContactLabelAssignment>(e))
              .toList()
          as T;
    }
    if (t == List<_i186.ProductObjectRoom>) {
      return (data as List)
              .map((e) => deserialize<_i186.ProductObjectRoom>(e))
              .toList()
          as T;
    }
    if (t == List<_i187.Product>) {
      return (data as List).map((e) => deserialize<_i187.Product>(e)).toList()
          as T;
    }
    if (t == List<_i188.ProfileTranslation>) {
      return (data as List)
              .map((e) => deserialize<_i188.ProfileTranslation>(e))
              .toList()
          as T;
    }
    if (t == Map<String, int>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<int>(v)),
          )
          as T;
    }
    if (t == List<_i189.PulseFolder>) {
      return (data as List)
              .map((e) => deserialize<_i189.PulseFolder>(e))
              .toList()
          as T;
    }
    if (t == List<_i190.PulseMonitor>) {
      return (data as List)
              .map((e) => deserialize<_i190.PulseMonitor>(e))
              .toList()
          as T;
    }
    if (t == List<_i191.PulseAlertRule>) {
      return (data as List)
              .map((e) => deserialize<_i191.PulseAlertRule>(e))
              .toList()
          as T;
    }
    if (t == List<_i192.PulseIncident>) {
      return (data as List)
              .map((e) => deserialize<_i192.PulseIncident>(e))
              .toList()
          as T;
    }
    if (t == List<_i193.PulseAccessEntry>) {
      return (data as List)
              .map((e) => deserialize<_i193.PulseAccessEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i194.PulseMemberView>) {
      return (data as List)
              .map((e) => deserialize<_i194.PulseMemberView>(e))
              .toList()
          as T;
    }
    if (t == List<_i195.PulseAccessAuditEvent>) {
      return (data as List)
              .map((e) => deserialize<_i195.PulseAccessAuditEvent>(e))
              .toList()
          as T;
    }
    try {
      return _i196.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i197.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AttachmentBytes => 'AttachmentBytes',
      _i3.AttachmentRef => 'AttachmentRef',
      _i4.AvailableBot => 'AvailableBot',
      _i5.Bot => 'Bot',
      _i6.BotAuditEvent => 'BotAuditEvent',
      _i7.BotCommand => 'BotCommand',
      _i8.BotIntegrationCreated => 'BotIntegrationCreated',
      _i9.BotIntegrationView => 'BotIntegrationView',
      _i10.BotReadModeResult => 'BotReadModeResult',
      _i11.CallHistoryEntry => 'CallHistoryEntry',
      _i12.CallIceCandidate => 'CallIceCandidate',
      _i13.ChatFolderRecord => 'ChatFolderRecord',
      _i14.ChatFolderRoom => 'ChatFolderRoom',
      _i15.ChatFolderView => 'ChatFolderView',
      _i16.Conference => 'Conference',
      _i17.ConferenceMember => 'ConferenceMember',
      _i18.ConferenceParticipant => 'ConferenceParticipant',
      _i19.ConferenceScreenShare => 'ConferenceScreenShare',
      _i20.ConferenceState => 'ConferenceState',
      _i21.ConnectIssuedToken => 'ConnectIssuedToken',
      _i22.ConnectIssuedTokenResult => 'ConnectIssuedTokenResult',
      _i23.ConnectKeyAuditEvent => 'ConnectKeyAuditEvent',
      _i24.ConnectTenantStatus => 'ConnectTenantStatus',
      _i25.ContactBlock => 'ContactBlock',
      _i26.ContactCard => 'ContactCard',
      _i27.ContactCardInfo => 'ContactCardInfo',
      _i28.ContactLabel => 'ContactLabel',
      _i29.ContactLabelAssignment => 'ContactLabelAssignment',
      _i30.ContactLink => 'ContactLink',
      _i31.ContactMeta => 'ContactMeta',
      _i32.ContactProfileView => 'ContactProfileView',
      _i33.ContactRelation => 'ContactRelation',
      _i34.ContactRequest => 'ContactRequest',
      _i35.ContactRequestView => 'ContactRequestView',
      _i36.DeviceRegistration => 'DeviceRegistration',
      _i37.DeviceSessionInfo => 'DeviceSessionInfo',
      _i38.EmailAccount => 'EmailAccount',
      _i39.EmailSession => 'EmailSession',
      _i40.EmailVerificationCode => 'EmailVerificationCode',
      _i41.AttachmentRejectReason => 'AttachmentRejectReason',
      _i42.CallEventType => 'CallEventType',
      _i43.CallStatus => 'CallStatus',
      _i44.ContactLinkSource => 'ContactLinkSource',
      _i45.ContactRequestStatus => 'ContactRequestStatus',
      _i46.DevicePlatform => 'DevicePlatform',
      _i47.IdentityProvider => 'IdentityProvider',
      _i48.MessengerEventType => 'MessengerEventType',
      _i49.ParticipantKind => 'ParticipantKind',
      _i50.ProductNotificationStatus => 'ProductNotificationStatus',
      _i51.PushService => 'PushService',
      _i52.RoomMemberRole => 'RoomMemberRole',
      _i53.RoomOwnership => 'RoomOwnership',
      _i54.RoomState => 'RoomState',
      _i55.RoomType => 'RoomType',
      _i56.SupportTeamRole => 'SupportTeamRole',
      _i57.TenantHostingMode => 'TenantHostingMode',
      _i58.TrustTokenKind => 'TrustTokenKind',
      _i59.AdapterNotConfiguredException => 'AdapterNotConfiguredException',
      _i60.AttachmentRejectedException => 'AttachmentRejectedException',
      _i61.BotCapabilityException => 'BotCapabilityException',
      _i62.BotLimitExceededException => 'BotLimitExceededException',
      _i63.BotNotFoundException => 'BotNotFoundException',
      _i64.BotReadRestrictedException => 'BotReadRestrictedException',
      _i65.ConferenceFullException => 'ConferenceFullException',
      _i66.EmailAuthException => 'EmailAuthException',
      _i67.InsufficientPowerException => 'InsufficientPowerException',
      _i68.InvalidBotCommandsException => 'InvalidBotCommandsException',
      _i69.InvalidExternalKeyException => 'InvalidExternalKeyException',
      _i70.InvalidNotificationException => 'InvalidNotificationException',
      _i71.InvalidTokenException => 'InvalidTokenException',
      _i72.LastOwnerCannotDemoteException => 'LastOwnerCannotDemoteException',
      _i73.MessageBodyTooLargeException => 'MessageBodyTooLargeException',
      _i74.MessageDeletedException => 'MessageDeletedException',
      _i75.MessageNotEditableException => 'MessageNotEditableException',
      _i76.MessengerNotAuthenticatedException =>
        'MessengerNotAuthenticatedException',
      _i77.NotObjectRoomException => 'NotObjectRoomException',
      _i78.NotSupportTeamMemberException => 'NotSupportTeamMemberException',
      _i79.NotSupportTeamOwnerException => 'NotSupportTeamOwnerException',
      _i80.OperatorEmailNotResolvedException =>
        'OperatorEmailNotResolvedException',
      _i81.PeerUnavailableException => 'PeerUnavailableException',
      _i82.ProductAlreadyExistsException => 'ProductAlreadyExistsException',
      _i83.ProductNotFoundException => 'ProductNotFoundException',
      _i84.ProductNotFoundForCallerException =>
        'ProductNotFoundForCallerException',
      _i85.RateLimitExceededException => 'RateLimitExceededException',
      _i86.RoomDissolvePartialException => 'RoomDissolvePartialException',
      _i87.RoomUnavailableException => 'RoomUnavailableException',
      _i88.ScreenShareBusyException => 'ScreenShareBusyException',
      _i89.TaskIntegrationNotConfiguredException =>
        'TaskIntegrationNotConfiguredException',
      _i90.TenantAlreadyExistsException => 'TenantAlreadyExistsException',
      _i91.TenantNotFoundException => 'TenantNotFoundException',
      _i92.ThumbnailUnavailableException => 'ThumbnailUnavailableException',
      _i93.WriteBannedException => 'WriteBannedException',
      _i94.EscalationResult => 'EscalationResult',
      _i95.Greeting => 'Greeting',
      _i96.IdentityMapping => 'IdentityMapping',
      _i97.IncomingWebhook => 'IncomingWebhook',
      _i98.IncomingWebhookCreated => 'IncomingWebhookCreated',
      _i99.MessageIndex => 'MessageIndex',
      _i100.MessengerAuthContext => 'MessengerAuthContext',
      _i101.MessengerEvent => 'MessengerEvent',
      _i102.MessengerMessage => 'MessengerMessage',
      _i103.MessengerMessageListPage => 'MessengerMessageListPage',
      _i104.MessengerSession => 'MessengerSession',
      _i105.MessengerSessionToken => 'MessengerSessionToken',
      _i106.MessengerUser => 'MessengerUser',
      _i107.NearbyConfirmResult => 'NearbyConfirmResult',
      _i108.NearbyConfirmation => 'NearbyConfirmation',
      _i109.NotificationSettings => 'NotificationSettings',
      _i110.PresenceConnState => 'PresenceConnState',
      _i111.PresenceInfo => 'PresenceInfo',
      _i112.PresenceState => 'PresenceState',
      _i113.PresenceWatchedIndex => 'PresenceWatchedIndex',
      _i114.PresenceWatchers => 'PresenceWatchers',
      _i115.Product => 'Product',
      _i116.ProductAdminView => 'ProductAdminView',
      _i117.ProductNotification => 'ProductNotification',
      _i118.ProductNotificationRecipientResult =>
        'ProductNotificationRecipientResult',
      _i119.ProductNotificationSendResult => 'ProductNotificationSendResult',
      _i120.ProductObjectRoom => 'ProductObjectRoom',
      _i121.ProfileTranslation => 'ProfileTranslation',
      _i122.PulseAccessAuditEvent => 'PulseAccessAuditEvent',
      _i123.PulseAccessEntry => 'PulseAccessEntry',
      _i124.PulseAlertRule => 'PulseAlertRule',
      _i125.PulseEvent => 'PulseEvent',
      _i126.PulseFolder => 'PulseFolder',
      _i127.PulseFolderMembership => 'PulseFolderMembership',
      _i128.PulseIncident => 'PulseIncident',
      _i129.PulseMemberView => 'PulseMemberView',
      _i130.PulseMonitor => 'PulseMonitor',
      _i131.PulseMonitorCreated => 'PulseMonitorCreated',
      _i132.PulseMonitorMembership => 'PulseMonitorMembership',
      _i133.PushQueueMessage => 'PushQueueMessage',
      _i134.PushTestJob => 'PushTestJob',
      _i135.PushTestResult => 'PushTestResult',
      _i136.Room => 'Room',
      _i137.RoomBotCommands => 'RoomBotCommands',
      _i138.RoomDetails => 'RoomDetails',
      _i139.RoomListPage => 'RoomListPage',
      _i140.RoomMembership => 'RoomMembership',
      _i141.RoomParticipant => 'RoomParticipant',
      _i142.RoomSummary => 'RoomSummary',
      _i143.RoomTaskStats => 'RoomTaskStats',
      _i144.SupportTeam => 'SupportTeam',
      _i145.SupportTeamMember => 'SupportTeamMember',
      _i146.SupportTeamMemberView => 'SupportTeamMemberView',
      _i147.SupportTeamView => 'SupportTeamView',
      _i148.TaskLink => 'TaskLink',
      _i149.TaskManagerConfig => 'TaskManagerConfig',
      _i150.Tenant => 'Tenant',
      _i151.Ticket => 'Ticket',
      _i152.TicketEvent => 'TicketEvent',
      _i153.TicketView => 'TicketView',
      _i154.TrustRedeemResult => 'TrustRedeemResult',
      _i155.TrustToken => 'TrustToken',
      _i156.TrustTokenIssued => 'TrustTokenIssued',
      _i157.TurnCredentials => 'TurnCredentials',
      _i158.WebhookDelivery => 'WebhookDelivery',
      _i159.WebhookEventMessage => 'WebhookEventMessage',
      _i160.WebhookSubscription => 'WebhookSubscription',
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
      case _i4.AvailableBot():
        return 'AvailableBot';
      case _i5.Bot():
        return 'Bot';
      case _i6.BotAuditEvent():
        return 'BotAuditEvent';
      case _i7.BotCommand():
        return 'BotCommand';
      case _i8.BotIntegrationCreated():
        return 'BotIntegrationCreated';
      case _i9.BotIntegrationView():
        return 'BotIntegrationView';
      case _i10.BotReadModeResult():
        return 'BotReadModeResult';
      case _i11.CallHistoryEntry():
        return 'CallHistoryEntry';
      case _i12.CallIceCandidate():
        return 'CallIceCandidate';
      case _i13.ChatFolderRecord():
        return 'ChatFolderRecord';
      case _i14.ChatFolderRoom():
        return 'ChatFolderRoom';
      case _i15.ChatFolderView():
        return 'ChatFolderView';
      case _i16.Conference():
        return 'Conference';
      case _i17.ConferenceMember():
        return 'ConferenceMember';
      case _i18.ConferenceParticipant():
        return 'ConferenceParticipant';
      case _i19.ConferenceScreenShare():
        return 'ConferenceScreenShare';
      case _i20.ConferenceState():
        return 'ConferenceState';
      case _i21.ConnectIssuedToken():
        return 'ConnectIssuedToken';
      case _i22.ConnectIssuedTokenResult():
        return 'ConnectIssuedTokenResult';
      case _i23.ConnectKeyAuditEvent():
        return 'ConnectKeyAuditEvent';
      case _i24.ConnectTenantStatus():
        return 'ConnectTenantStatus';
      case _i25.ContactBlock():
        return 'ContactBlock';
      case _i26.ContactCard():
        return 'ContactCard';
      case _i27.ContactCardInfo():
        return 'ContactCardInfo';
      case _i28.ContactLabel():
        return 'ContactLabel';
      case _i29.ContactLabelAssignment():
        return 'ContactLabelAssignment';
      case _i30.ContactLink():
        return 'ContactLink';
      case _i31.ContactMeta():
        return 'ContactMeta';
      case _i32.ContactProfileView():
        return 'ContactProfileView';
      case _i33.ContactRelation():
        return 'ContactRelation';
      case _i34.ContactRequest():
        return 'ContactRequest';
      case _i35.ContactRequestView():
        return 'ContactRequestView';
      case _i36.DeviceRegistration():
        return 'DeviceRegistration';
      case _i37.DeviceSessionInfo():
        return 'DeviceSessionInfo';
      case _i38.EmailAccount():
        return 'EmailAccount';
      case _i39.EmailSession():
        return 'EmailSession';
      case _i40.EmailVerificationCode():
        return 'EmailVerificationCode';
      case _i41.AttachmentRejectReason():
        return 'AttachmentRejectReason';
      case _i42.CallEventType():
        return 'CallEventType';
      case _i43.CallStatus():
        return 'CallStatus';
      case _i44.ContactLinkSource():
        return 'ContactLinkSource';
      case _i45.ContactRequestStatus():
        return 'ContactRequestStatus';
      case _i46.DevicePlatform():
        return 'DevicePlatform';
      case _i47.IdentityProvider():
        return 'IdentityProvider';
      case _i48.MessengerEventType():
        return 'MessengerEventType';
      case _i49.ParticipantKind():
        return 'ParticipantKind';
      case _i50.ProductNotificationStatus():
        return 'ProductNotificationStatus';
      case _i51.PushService():
        return 'PushService';
      case _i52.RoomMemberRole():
        return 'RoomMemberRole';
      case _i53.RoomOwnership():
        return 'RoomOwnership';
      case _i54.RoomState():
        return 'RoomState';
      case _i55.RoomType():
        return 'RoomType';
      case _i56.SupportTeamRole():
        return 'SupportTeamRole';
      case _i57.TenantHostingMode():
        return 'TenantHostingMode';
      case _i58.TrustTokenKind():
        return 'TrustTokenKind';
      case _i59.AdapterNotConfiguredException():
        return 'AdapterNotConfiguredException';
      case _i60.AttachmentRejectedException():
        return 'AttachmentRejectedException';
      case _i61.BotCapabilityException():
        return 'BotCapabilityException';
      case _i62.BotLimitExceededException():
        return 'BotLimitExceededException';
      case _i63.BotNotFoundException():
        return 'BotNotFoundException';
      case _i64.BotReadRestrictedException():
        return 'BotReadRestrictedException';
      case _i65.ConferenceFullException():
        return 'ConferenceFullException';
      case _i66.EmailAuthException():
        return 'EmailAuthException';
      case _i67.InsufficientPowerException():
        return 'InsufficientPowerException';
      case _i68.InvalidBotCommandsException():
        return 'InvalidBotCommandsException';
      case _i69.InvalidExternalKeyException():
        return 'InvalidExternalKeyException';
      case _i70.InvalidNotificationException():
        return 'InvalidNotificationException';
      case _i71.InvalidTokenException():
        return 'InvalidTokenException';
      case _i72.LastOwnerCannotDemoteException():
        return 'LastOwnerCannotDemoteException';
      case _i73.MessageBodyTooLargeException():
        return 'MessageBodyTooLargeException';
      case _i74.MessageDeletedException():
        return 'MessageDeletedException';
      case _i75.MessageNotEditableException():
        return 'MessageNotEditableException';
      case _i76.MessengerNotAuthenticatedException():
        return 'MessengerNotAuthenticatedException';
      case _i77.NotObjectRoomException():
        return 'NotObjectRoomException';
      case _i78.NotSupportTeamMemberException():
        return 'NotSupportTeamMemberException';
      case _i79.NotSupportTeamOwnerException():
        return 'NotSupportTeamOwnerException';
      case _i80.OperatorEmailNotResolvedException():
        return 'OperatorEmailNotResolvedException';
      case _i81.PeerUnavailableException():
        return 'PeerUnavailableException';
      case _i82.ProductAlreadyExistsException():
        return 'ProductAlreadyExistsException';
      case _i83.ProductNotFoundException():
        return 'ProductNotFoundException';
      case _i84.ProductNotFoundForCallerException():
        return 'ProductNotFoundForCallerException';
      case _i85.RateLimitExceededException():
        return 'RateLimitExceededException';
      case _i86.RoomDissolvePartialException():
        return 'RoomDissolvePartialException';
      case _i87.RoomUnavailableException():
        return 'RoomUnavailableException';
      case _i88.ScreenShareBusyException():
        return 'ScreenShareBusyException';
      case _i89.TaskIntegrationNotConfiguredException():
        return 'TaskIntegrationNotConfiguredException';
      case _i90.TenantAlreadyExistsException():
        return 'TenantAlreadyExistsException';
      case _i91.TenantNotFoundException():
        return 'TenantNotFoundException';
      case _i92.ThumbnailUnavailableException():
        return 'ThumbnailUnavailableException';
      case _i93.WriteBannedException():
        return 'WriteBannedException';
      case _i94.EscalationResult():
        return 'EscalationResult';
      case _i95.Greeting():
        return 'Greeting';
      case _i96.IdentityMapping():
        return 'IdentityMapping';
      case _i97.IncomingWebhook():
        return 'IncomingWebhook';
      case _i98.IncomingWebhookCreated():
        return 'IncomingWebhookCreated';
      case _i99.MessageIndex():
        return 'MessageIndex';
      case _i100.MessengerAuthContext():
        return 'MessengerAuthContext';
      case _i101.MessengerEvent():
        return 'MessengerEvent';
      case _i102.MessengerMessage():
        return 'MessengerMessage';
      case _i103.MessengerMessageListPage():
        return 'MessengerMessageListPage';
      case _i104.MessengerSession():
        return 'MessengerSession';
      case _i105.MessengerSessionToken():
        return 'MessengerSessionToken';
      case _i106.MessengerUser():
        return 'MessengerUser';
      case _i107.NearbyConfirmResult():
        return 'NearbyConfirmResult';
      case _i108.NearbyConfirmation():
        return 'NearbyConfirmation';
      case _i109.NotificationSettings():
        return 'NotificationSettings';
      case _i110.PresenceConnState():
        return 'PresenceConnState';
      case _i111.PresenceInfo():
        return 'PresenceInfo';
      case _i112.PresenceState():
        return 'PresenceState';
      case _i113.PresenceWatchedIndex():
        return 'PresenceWatchedIndex';
      case _i114.PresenceWatchers():
        return 'PresenceWatchers';
      case _i115.Product():
        return 'Product';
      case _i116.ProductAdminView():
        return 'ProductAdminView';
      case _i117.ProductNotification():
        return 'ProductNotification';
      case _i118.ProductNotificationRecipientResult():
        return 'ProductNotificationRecipientResult';
      case _i119.ProductNotificationSendResult():
        return 'ProductNotificationSendResult';
      case _i120.ProductObjectRoom():
        return 'ProductObjectRoom';
      case _i121.ProfileTranslation():
        return 'ProfileTranslation';
      case _i122.PulseAccessAuditEvent():
        return 'PulseAccessAuditEvent';
      case _i123.PulseAccessEntry():
        return 'PulseAccessEntry';
      case _i124.PulseAlertRule():
        return 'PulseAlertRule';
      case _i125.PulseEvent():
        return 'PulseEvent';
      case _i126.PulseFolder():
        return 'PulseFolder';
      case _i127.PulseFolderMembership():
        return 'PulseFolderMembership';
      case _i128.PulseIncident():
        return 'PulseIncident';
      case _i129.PulseMemberView():
        return 'PulseMemberView';
      case _i130.PulseMonitor():
        return 'PulseMonitor';
      case _i131.PulseMonitorCreated():
        return 'PulseMonitorCreated';
      case _i132.PulseMonitorMembership():
        return 'PulseMonitorMembership';
      case _i133.PushQueueMessage():
        return 'PushQueueMessage';
      case _i134.PushTestJob():
        return 'PushTestJob';
      case _i135.PushTestResult():
        return 'PushTestResult';
      case _i136.Room():
        return 'Room';
      case _i137.RoomBotCommands():
        return 'RoomBotCommands';
      case _i138.RoomDetails():
        return 'RoomDetails';
      case _i139.RoomListPage():
        return 'RoomListPage';
      case _i140.RoomMembership():
        return 'RoomMembership';
      case _i141.RoomParticipant():
        return 'RoomParticipant';
      case _i142.RoomSummary():
        return 'RoomSummary';
      case _i143.RoomTaskStats():
        return 'RoomTaskStats';
      case _i144.SupportTeam():
        return 'SupportTeam';
      case _i145.SupportTeamMember():
        return 'SupportTeamMember';
      case _i146.SupportTeamMemberView():
        return 'SupportTeamMemberView';
      case _i147.SupportTeamView():
        return 'SupportTeamView';
      case _i148.TaskLink():
        return 'TaskLink';
      case _i149.TaskManagerConfig():
        return 'TaskManagerConfig';
      case _i150.Tenant():
        return 'Tenant';
      case _i151.Ticket():
        return 'Ticket';
      case _i152.TicketEvent():
        return 'TicketEvent';
      case _i153.TicketView():
        return 'TicketView';
      case _i154.TrustRedeemResult():
        return 'TrustRedeemResult';
      case _i155.TrustToken():
        return 'TrustToken';
      case _i156.TrustTokenIssued():
        return 'TrustTokenIssued';
      case _i157.TurnCredentials():
        return 'TurnCredentials';
      case _i158.WebhookDelivery():
        return 'WebhookDelivery';
      case _i159.WebhookEventMessage():
        return 'WebhookEventMessage';
      case _i160.WebhookSubscription():
        return 'WebhookSubscription';
    }
    className = _i196.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i197.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'AvailableBot') {
      return deserialize<_i4.AvailableBot>(data['data']);
    }
    if (dataClassName == 'Bot') {
      return deserialize<_i5.Bot>(data['data']);
    }
    if (dataClassName == 'BotAuditEvent') {
      return deserialize<_i6.BotAuditEvent>(data['data']);
    }
    if (dataClassName == 'BotCommand') {
      return deserialize<_i7.BotCommand>(data['data']);
    }
    if (dataClassName == 'BotIntegrationCreated') {
      return deserialize<_i8.BotIntegrationCreated>(data['data']);
    }
    if (dataClassName == 'BotIntegrationView') {
      return deserialize<_i9.BotIntegrationView>(data['data']);
    }
    if (dataClassName == 'BotReadModeResult') {
      return deserialize<_i10.BotReadModeResult>(data['data']);
    }
    if (dataClassName == 'CallHistoryEntry') {
      return deserialize<_i11.CallHistoryEntry>(data['data']);
    }
    if (dataClassName == 'CallIceCandidate') {
      return deserialize<_i12.CallIceCandidate>(data['data']);
    }
    if (dataClassName == 'ChatFolderRecord') {
      return deserialize<_i13.ChatFolderRecord>(data['data']);
    }
    if (dataClassName == 'ChatFolderRoom') {
      return deserialize<_i14.ChatFolderRoom>(data['data']);
    }
    if (dataClassName == 'ChatFolderView') {
      return deserialize<_i15.ChatFolderView>(data['data']);
    }
    if (dataClassName == 'Conference') {
      return deserialize<_i16.Conference>(data['data']);
    }
    if (dataClassName == 'ConferenceMember') {
      return deserialize<_i17.ConferenceMember>(data['data']);
    }
    if (dataClassName == 'ConferenceParticipant') {
      return deserialize<_i18.ConferenceParticipant>(data['data']);
    }
    if (dataClassName == 'ConferenceScreenShare') {
      return deserialize<_i19.ConferenceScreenShare>(data['data']);
    }
    if (dataClassName == 'ConferenceState') {
      return deserialize<_i20.ConferenceState>(data['data']);
    }
    if (dataClassName == 'ConnectIssuedToken') {
      return deserialize<_i21.ConnectIssuedToken>(data['data']);
    }
    if (dataClassName == 'ConnectIssuedTokenResult') {
      return deserialize<_i22.ConnectIssuedTokenResult>(data['data']);
    }
    if (dataClassName == 'ConnectKeyAuditEvent') {
      return deserialize<_i23.ConnectKeyAuditEvent>(data['data']);
    }
    if (dataClassName == 'ConnectTenantStatus') {
      return deserialize<_i24.ConnectTenantStatus>(data['data']);
    }
    if (dataClassName == 'ContactBlock') {
      return deserialize<_i25.ContactBlock>(data['data']);
    }
    if (dataClassName == 'ContactCard') {
      return deserialize<_i26.ContactCard>(data['data']);
    }
    if (dataClassName == 'ContactCardInfo') {
      return deserialize<_i27.ContactCardInfo>(data['data']);
    }
    if (dataClassName == 'ContactLabel') {
      return deserialize<_i28.ContactLabel>(data['data']);
    }
    if (dataClassName == 'ContactLabelAssignment') {
      return deserialize<_i29.ContactLabelAssignment>(data['data']);
    }
    if (dataClassName == 'ContactLink') {
      return deserialize<_i30.ContactLink>(data['data']);
    }
    if (dataClassName == 'ContactMeta') {
      return deserialize<_i31.ContactMeta>(data['data']);
    }
    if (dataClassName == 'ContactProfileView') {
      return deserialize<_i32.ContactProfileView>(data['data']);
    }
    if (dataClassName == 'ContactRelation') {
      return deserialize<_i33.ContactRelation>(data['data']);
    }
    if (dataClassName == 'ContactRequest') {
      return deserialize<_i34.ContactRequest>(data['data']);
    }
    if (dataClassName == 'ContactRequestView') {
      return deserialize<_i35.ContactRequestView>(data['data']);
    }
    if (dataClassName == 'DeviceRegistration') {
      return deserialize<_i36.DeviceRegistration>(data['data']);
    }
    if (dataClassName == 'DeviceSessionInfo') {
      return deserialize<_i37.DeviceSessionInfo>(data['data']);
    }
    if (dataClassName == 'EmailAccount') {
      return deserialize<_i38.EmailAccount>(data['data']);
    }
    if (dataClassName == 'EmailSession') {
      return deserialize<_i39.EmailSession>(data['data']);
    }
    if (dataClassName == 'EmailVerificationCode') {
      return deserialize<_i40.EmailVerificationCode>(data['data']);
    }
    if (dataClassName == 'AttachmentRejectReason') {
      return deserialize<_i41.AttachmentRejectReason>(data['data']);
    }
    if (dataClassName == 'CallEventType') {
      return deserialize<_i42.CallEventType>(data['data']);
    }
    if (dataClassName == 'CallStatus') {
      return deserialize<_i43.CallStatus>(data['data']);
    }
    if (dataClassName == 'ContactLinkSource') {
      return deserialize<_i44.ContactLinkSource>(data['data']);
    }
    if (dataClassName == 'ContactRequestStatus') {
      return deserialize<_i45.ContactRequestStatus>(data['data']);
    }
    if (dataClassName == 'DevicePlatform') {
      return deserialize<_i46.DevicePlatform>(data['data']);
    }
    if (dataClassName == 'IdentityProvider') {
      return deserialize<_i47.IdentityProvider>(data['data']);
    }
    if (dataClassName == 'MessengerEventType') {
      return deserialize<_i48.MessengerEventType>(data['data']);
    }
    if (dataClassName == 'ParticipantKind') {
      return deserialize<_i49.ParticipantKind>(data['data']);
    }
    if (dataClassName == 'ProductNotificationStatus') {
      return deserialize<_i50.ProductNotificationStatus>(data['data']);
    }
    if (dataClassName == 'PushService') {
      return deserialize<_i51.PushService>(data['data']);
    }
    if (dataClassName == 'RoomMemberRole') {
      return deserialize<_i52.RoomMemberRole>(data['data']);
    }
    if (dataClassName == 'RoomOwnership') {
      return deserialize<_i53.RoomOwnership>(data['data']);
    }
    if (dataClassName == 'RoomState') {
      return deserialize<_i54.RoomState>(data['data']);
    }
    if (dataClassName == 'RoomType') {
      return deserialize<_i55.RoomType>(data['data']);
    }
    if (dataClassName == 'SupportTeamRole') {
      return deserialize<_i56.SupportTeamRole>(data['data']);
    }
    if (dataClassName == 'TenantHostingMode') {
      return deserialize<_i57.TenantHostingMode>(data['data']);
    }
    if (dataClassName == 'TrustTokenKind') {
      return deserialize<_i58.TrustTokenKind>(data['data']);
    }
    if (dataClassName == 'AdapterNotConfiguredException') {
      return deserialize<_i59.AdapterNotConfiguredException>(data['data']);
    }
    if (dataClassName == 'AttachmentRejectedException') {
      return deserialize<_i60.AttachmentRejectedException>(data['data']);
    }
    if (dataClassName == 'BotCapabilityException') {
      return deserialize<_i61.BotCapabilityException>(data['data']);
    }
    if (dataClassName == 'BotLimitExceededException') {
      return deserialize<_i62.BotLimitExceededException>(data['data']);
    }
    if (dataClassName == 'BotNotFoundException') {
      return deserialize<_i63.BotNotFoundException>(data['data']);
    }
    if (dataClassName == 'BotReadRestrictedException') {
      return deserialize<_i64.BotReadRestrictedException>(data['data']);
    }
    if (dataClassName == 'ConferenceFullException') {
      return deserialize<_i65.ConferenceFullException>(data['data']);
    }
    if (dataClassName == 'EmailAuthException') {
      return deserialize<_i66.EmailAuthException>(data['data']);
    }
    if (dataClassName == 'InsufficientPowerException') {
      return deserialize<_i67.InsufficientPowerException>(data['data']);
    }
    if (dataClassName == 'InvalidBotCommandsException') {
      return deserialize<_i68.InvalidBotCommandsException>(data['data']);
    }
    if (dataClassName == 'InvalidExternalKeyException') {
      return deserialize<_i69.InvalidExternalKeyException>(data['data']);
    }
    if (dataClassName == 'InvalidNotificationException') {
      return deserialize<_i70.InvalidNotificationException>(data['data']);
    }
    if (dataClassName == 'InvalidTokenException') {
      return deserialize<_i71.InvalidTokenException>(data['data']);
    }
    if (dataClassName == 'LastOwnerCannotDemoteException') {
      return deserialize<_i72.LastOwnerCannotDemoteException>(data['data']);
    }
    if (dataClassName == 'MessageBodyTooLargeException') {
      return deserialize<_i73.MessageBodyTooLargeException>(data['data']);
    }
    if (dataClassName == 'MessageDeletedException') {
      return deserialize<_i74.MessageDeletedException>(data['data']);
    }
    if (dataClassName == 'MessageNotEditableException') {
      return deserialize<_i75.MessageNotEditableException>(data['data']);
    }
    if (dataClassName == 'MessengerNotAuthenticatedException') {
      return deserialize<_i76.MessengerNotAuthenticatedException>(data['data']);
    }
    if (dataClassName == 'NotObjectRoomException') {
      return deserialize<_i77.NotObjectRoomException>(data['data']);
    }
    if (dataClassName == 'NotSupportTeamMemberException') {
      return deserialize<_i78.NotSupportTeamMemberException>(data['data']);
    }
    if (dataClassName == 'NotSupportTeamOwnerException') {
      return deserialize<_i79.NotSupportTeamOwnerException>(data['data']);
    }
    if (dataClassName == 'OperatorEmailNotResolvedException') {
      return deserialize<_i80.OperatorEmailNotResolvedException>(data['data']);
    }
    if (dataClassName == 'PeerUnavailableException') {
      return deserialize<_i81.PeerUnavailableException>(data['data']);
    }
    if (dataClassName == 'ProductAlreadyExistsException') {
      return deserialize<_i82.ProductAlreadyExistsException>(data['data']);
    }
    if (dataClassName == 'ProductNotFoundException') {
      return deserialize<_i83.ProductNotFoundException>(data['data']);
    }
    if (dataClassName == 'ProductNotFoundForCallerException') {
      return deserialize<_i84.ProductNotFoundForCallerException>(data['data']);
    }
    if (dataClassName == 'RateLimitExceededException') {
      return deserialize<_i85.RateLimitExceededException>(data['data']);
    }
    if (dataClassName == 'RoomDissolvePartialException') {
      return deserialize<_i86.RoomDissolvePartialException>(data['data']);
    }
    if (dataClassName == 'RoomUnavailableException') {
      return deserialize<_i87.RoomUnavailableException>(data['data']);
    }
    if (dataClassName == 'ScreenShareBusyException') {
      return deserialize<_i88.ScreenShareBusyException>(data['data']);
    }
    if (dataClassName == 'TaskIntegrationNotConfiguredException') {
      return deserialize<_i89.TaskIntegrationNotConfiguredException>(
        data['data'],
      );
    }
    if (dataClassName == 'TenantAlreadyExistsException') {
      return deserialize<_i90.TenantAlreadyExistsException>(data['data']);
    }
    if (dataClassName == 'TenantNotFoundException') {
      return deserialize<_i91.TenantNotFoundException>(data['data']);
    }
    if (dataClassName == 'ThumbnailUnavailableException') {
      return deserialize<_i92.ThumbnailUnavailableException>(data['data']);
    }
    if (dataClassName == 'WriteBannedException') {
      return deserialize<_i93.WriteBannedException>(data['data']);
    }
    if (dataClassName == 'EscalationResult') {
      return deserialize<_i94.EscalationResult>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i95.Greeting>(data['data']);
    }
    if (dataClassName == 'IdentityMapping') {
      return deserialize<_i96.IdentityMapping>(data['data']);
    }
    if (dataClassName == 'IncomingWebhook') {
      return deserialize<_i97.IncomingWebhook>(data['data']);
    }
    if (dataClassName == 'IncomingWebhookCreated') {
      return deserialize<_i98.IncomingWebhookCreated>(data['data']);
    }
    if (dataClassName == 'MessageIndex') {
      return deserialize<_i99.MessageIndex>(data['data']);
    }
    if (dataClassName == 'MessengerAuthContext') {
      return deserialize<_i100.MessengerAuthContext>(data['data']);
    }
    if (dataClassName == 'MessengerEvent') {
      return deserialize<_i101.MessengerEvent>(data['data']);
    }
    if (dataClassName == 'MessengerMessage') {
      return deserialize<_i102.MessengerMessage>(data['data']);
    }
    if (dataClassName == 'MessengerMessageListPage') {
      return deserialize<_i103.MessengerMessageListPage>(data['data']);
    }
    if (dataClassName == 'MessengerSession') {
      return deserialize<_i104.MessengerSession>(data['data']);
    }
    if (dataClassName == 'MessengerSessionToken') {
      return deserialize<_i105.MessengerSessionToken>(data['data']);
    }
    if (dataClassName == 'MessengerUser') {
      return deserialize<_i106.MessengerUser>(data['data']);
    }
    if (dataClassName == 'NearbyConfirmResult') {
      return deserialize<_i107.NearbyConfirmResult>(data['data']);
    }
    if (dataClassName == 'NearbyConfirmation') {
      return deserialize<_i108.NearbyConfirmation>(data['data']);
    }
    if (dataClassName == 'NotificationSettings') {
      return deserialize<_i109.NotificationSettings>(data['data']);
    }
    if (dataClassName == 'PresenceConnState') {
      return deserialize<_i110.PresenceConnState>(data['data']);
    }
    if (dataClassName == 'PresenceInfo') {
      return deserialize<_i111.PresenceInfo>(data['data']);
    }
    if (dataClassName == 'PresenceState') {
      return deserialize<_i112.PresenceState>(data['data']);
    }
    if (dataClassName == 'PresenceWatchedIndex') {
      return deserialize<_i113.PresenceWatchedIndex>(data['data']);
    }
    if (dataClassName == 'PresenceWatchers') {
      return deserialize<_i114.PresenceWatchers>(data['data']);
    }
    if (dataClassName == 'Product') {
      return deserialize<_i115.Product>(data['data']);
    }
    if (dataClassName == 'ProductAdminView') {
      return deserialize<_i116.ProductAdminView>(data['data']);
    }
    if (dataClassName == 'ProductNotification') {
      return deserialize<_i117.ProductNotification>(data['data']);
    }
    if (dataClassName == 'ProductNotificationRecipientResult') {
      return deserialize<_i118.ProductNotificationRecipientResult>(
        data['data'],
      );
    }
    if (dataClassName == 'ProductNotificationSendResult') {
      return deserialize<_i119.ProductNotificationSendResult>(data['data']);
    }
    if (dataClassName == 'ProductObjectRoom') {
      return deserialize<_i120.ProductObjectRoom>(data['data']);
    }
    if (dataClassName == 'ProfileTranslation') {
      return deserialize<_i121.ProfileTranslation>(data['data']);
    }
    if (dataClassName == 'PulseAccessAuditEvent') {
      return deserialize<_i122.PulseAccessAuditEvent>(data['data']);
    }
    if (dataClassName == 'PulseAccessEntry') {
      return deserialize<_i123.PulseAccessEntry>(data['data']);
    }
    if (dataClassName == 'PulseAlertRule') {
      return deserialize<_i124.PulseAlertRule>(data['data']);
    }
    if (dataClassName == 'PulseEvent') {
      return deserialize<_i125.PulseEvent>(data['data']);
    }
    if (dataClassName == 'PulseFolder') {
      return deserialize<_i126.PulseFolder>(data['data']);
    }
    if (dataClassName == 'PulseFolderMembership') {
      return deserialize<_i127.PulseFolderMembership>(data['data']);
    }
    if (dataClassName == 'PulseIncident') {
      return deserialize<_i128.PulseIncident>(data['data']);
    }
    if (dataClassName == 'PulseMemberView') {
      return deserialize<_i129.PulseMemberView>(data['data']);
    }
    if (dataClassName == 'PulseMonitor') {
      return deserialize<_i130.PulseMonitor>(data['data']);
    }
    if (dataClassName == 'PulseMonitorCreated') {
      return deserialize<_i131.PulseMonitorCreated>(data['data']);
    }
    if (dataClassName == 'PulseMonitorMembership') {
      return deserialize<_i132.PulseMonitorMembership>(data['data']);
    }
    if (dataClassName == 'PushQueueMessage') {
      return deserialize<_i133.PushQueueMessage>(data['data']);
    }
    if (dataClassName == 'PushTestJob') {
      return deserialize<_i134.PushTestJob>(data['data']);
    }
    if (dataClassName == 'PushTestResult') {
      return deserialize<_i135.PushTestResult>(data['data']);
    }
    if (dataClassName == 'Room') {
      return deserialize<_i136.Room>(data['data']);
    }
    if (dataClassName == 'RoomBotCommands') {
      return deserialize<_i137.RoomBotCommands>(data['data']);
    }
    if (dataClassName == 'RoomDetails') {
      return deserialize<_i138.RoomDetails>(data['data']);
    }
    if (dataClassName == 'RoomListPage') {
      return deserialize<_i139.RoomListPage>(data['data']);
    }
    if (dataClassName == 'RoomMembership') {
      return deserialize<_i140.RoomMembership>(data['data']);
    }
    if (dataClassName == 'RoomParticipant') {
      return deserialize<_i141.RoomParticipant>(data['data']);
    }
    if (dataClassName == 'RoomSummary') {
      return deserialize<_i142.RoomSummary>(data['data']);
    }
    if (dataClassName == 'RoomTaskStats') {
      return deserialize<_i143.RoomTaskStats>(data['data']);
    }
    if (dataClassName == 'SupportTeam') {
      return deserialize<_i144.SupportTeam>(data['data']);
    }
    if (dataClassName == 'SupportTeamMember') {
      return deserialize<_i145.SupportTeamMember>(data['data']);
    }
    if (dataClassName == 'SupportTeamMemberView') {
      return deserialize<_i146.SupportTeamMemberView>(data['data']);
    }
    if (dataClassName == 'SupportTeamView') {
      return deserialize<_i147.SupportTeamView>(data['data']);
    }
    if (dataClassName == 'TaskLink') {
      return deserialize<_i148.TaskLink>(data['data']);
    }
    if (dataClassName == 'TaskManagerConfig') {
      return deserialize<_i149.TaskManagerConfig>(data['data']);
    }
    if (dataClassName == 'Tenant') {
      return deserialize<_i150.Tenant>(data['data']);
    }
    if (dataClassName == 'Ticket') {
      return deserialize<_i151.Ticket>(data['data']);
    }
    if (dataClassName == 'TicketEvent') {
      return deserialize<_i152.TicketEvent>(data['data']);
    }
    if (dataClassName == 'TicketView') {
      return deserialize<_i153.TicketView>(data['data']);
    }
    if (dataClassName == 'TrustRedeemResult') {
      return deserialize<_i154.TrustRedeemResult>(data['data']);
    }
    if (dataClassName == 'TrustToken') {
      return deserialize<_i155.TrustToken>(data['data']);
    }
    if (dataClassName == 'TrustTokenIssued') {
      return deserialize<_i156.TrustTokenIssued>(data['data']);
    }
    if (dataClassName == 'TurnCredentials') {
      return deserialize<_i157.TurnCredentials>(data['data']);
    }
    if (dataClassName == 'WebhookDelivery') {
      return deserialize<_i158.WebhookDelivery>(data['data']);
    }
    if (dataClassName == 'WebhookEventMessage') {
      return deserialize<_i159.WebhookEventMessage>(data['data']);
    }
    if (dataClassName == 'WebhookSubscription') {
      return deserialize<_i160.WebhookSubscription>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i196.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i197.Protocol().deserializeByClassName(data);
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
      return _i196.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i197.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
