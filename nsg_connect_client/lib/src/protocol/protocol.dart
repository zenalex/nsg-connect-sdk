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
import 'announcement.dart' as _i2;
import 'announcement_seen.dart' as _i3;
import 'announcement_view.dart' as _i4;
import 'attachment_bytes.dart' as _i5;
import 'attachment_object.dart' as _i6;
import 'attachment_placement.dart' as _i7;
import 'attachment_ref.dart' as _i8;
import 'attachment_url.dart' as _i9;
import 'available_bot.dart' as _i10;
import 'bot.dart' as _i11;
import 'bot_audit_event.dart' as _i12;
import 'bot_channel_health.dart' as _i13;
import 'bot_command.dart' as _i14;
import 'bot_integration_created.dart' as _i15;
import 'bot_integration_view.dart' as _i16;
import 'bot_read_mode_result.dart' as _i17;
import 'call_history_entry.dart' as _i18;
import 'call_ice_candidate.dart' as _i19;
import 'chat_folder.dart' as _i20;
import 'chat_folder_room.dart' as _i21;
import 'chat_folder_view.dart' as _i22;
import 'conference.dart' as _i23;
import 'conference_member.dart' as _i24;
import 'conference_participant.dart' as _i25;
import 'conference_screen_share.dart' as _i26;
import 'conference_state.dart' as _i27;
import 'connect_issued_token.dart' as _i28;
import 'connect_issued_token_result.dart' as _i29;
import 'connect_key_audit_event.dart' as _i30;
import 'connect_tenant_status.dart' as _i31;
import 'contact_block.dart' as _i32;
import 'contact_card.dart' as _i33;
import 'contact_card_info.dart' as _i34;
import 'contact_label.dart' as _i35;
import 'contact_label_assignment.dart' as _i36;
import 'contact_link.dart' as _i37;
import 'contact_meta.dart' as _i38;
import 'contact_profile_view.dart' as _i39;
import 'contact_relation.dart' as _i40;
import 'contact_request.dart' as _i41;
import 'contact_request_view.dart' as _i42;
import 'delivery_pending.dart' as _i43;
import 'device_registration.dart' as _i44;
import 'device_session_info.dart' as _i45;
import 'email_account.dart' as _i46;
import 'email_session.dart' as _i47;
import 'email_verification_code.dart' as _i48;
import 'enums/attachment_reject_reason.dart' as _i49;
import 'enums/call_event_type.dart' as _i50;
import 'enums/call_status.dart' as _i51;
import 'enums/contact_link_source.dart' as _i52;
import 'enums/contact_request_status.dart' as _i53;
import 'enums/device_platform.dart' as _i54;
import 'enums/identity_provider.dart' as _i55;
import 'enums/messenger_event_type.dart' as _i56;
import 'enums/participant_kind.dart' as _i57;
import 'enums/product_notification_status.dart' as _i58;
import 'enums/push_service.dart' as _i59;
import 'enums/room_member_role.dart' as _i60;
import 'enums/room_ownership.dart' as _i61;
import 'enums/room_state.dart' as _i62;
import 'enums/room_type.dart' as _i63;
import 'enums/support_team_role.dart' as _i64;
import 'enums/team_kind.dart' as _i65;
import 'enums/team_member_role.dart' as _i66;
import 'enums/tenant_hosting_mode.dart' as _i67;
import 'enums/trust_token_kind.dart' as _i68;
import 'errors/adapter_not_configured_exception.dart' as _i69;
import 'errors/ambiguous_product_key_exception.dart' as _i70;
import 'errors/attachment_access_denied_exception.dart' as _i71;
import 'errors/attachment_rejected_exception.dart' as _i72;
import 'errors/bot_capability_exception.dart' as _i73;
import 'errors/bot_limit_exceeded_exception.dart' as _i74;
import 'errors/bot_not_found_exception.dart' as _i75;
import 'errors/bot_read_restricted_exception.dart' as _i76;
import 'errors/conference_full_exception.dart' as _i77;
import 'errors/email_auth_exception.dart' as _i78;
import 'errors/insufficient_power_exception.dart' as _i79;
import 'errors/invalid_bot_commands_exception.dart' as _i80;
import 'errors/invalid_external_key_exception.dart' as _i81;
import 'errors/invalid_notification_exception.dart' as _i82;
import 'errors/invalid_token_exception.dart' as _i83;
import 'errors/last_owner_cannot_demote_exception.dart' as _i84;
import 'errors/message_body_too_large_exception.dart' as _i85;
import 'errors/message_deleted_exception.dart' as _i86;
import 'errors/message_not_editable_exception.dart' as _i87;
import 'errors/messenger_not_authenticated_exception.dart' as _i88;
import 'errors/not_object_room_exception.dart' as _i89;
import 'errors/not_support_team_member_exception.dart' as _i90;
import 'errors/not_support_team_owner_exception.dart' as _i91;
import 'errors/operator_email_not_resolved_exception.dart' as _i92;
import 'errors/peer_unavailable_exception.dart' as _i93;
import 'errors/probe_target_not_allowed_exception.dart' as _i94;
import 'errors/product_already_exists_exception.dart' as _i95;
import 'errors/product_in_use_exception.dart' as _i96;
import 'errors/product_not_found_exception.dart' as _i97;
import 'errors/product_not_found_for_caller_exception.dart' as _i98;
import 'errors/rate_limit_exceeded_exception.dart' as _i99;
import 'errors/room_dissolve_partial_exception.dart' as _i100;
import 'errors/room_unavailable_exception.dart' as _i101;
import 'errors/screen_share_busy_exception.dart' as _i102;
import 'errors/task_integration_not_configured_exception.dart' as _i103;
import 'errors/team_access_denied_exception.dart' as _i104;
import 'errors/team_peer_unknown_exception.dart' as _i105;
import 'errors/tenant_already_exists_exception.dart' as _i106;
import 'errors/tenant_not_found_exception.dart' as _i107;
import 'errors/thumbnail_unavailable_exception.dart' as _i108;
import 'errors/write_banned_exception.dart' as _i109;
import 'escalation_result.dart' as _i110;
import 'greetings/greeting.dart' as _i111;
import 'identity_mapping.dart' as _i112;
import 'incoming_webhook.dart' as _i113;
import 'incoming_webhook_created.dart' as _i114;
import 'link_preview.dart' as _i115;
import 'link_preview_view.dart' as _i116;
import 'message_index.dart' as _i117;
import 'messenger_auth_context.dart' as _i118;
import 'messenger_event.dart' as _i119;
import 'messenger_message.dart' as _i120;
import 'messenger_message_list_page.dart' as _i121;
import 'messenger_session.dart' as _i122;
import 'messenger_session_token.dart' as _i123;
import 'messenger_user.dart' as _i124;
import 'nearby_confirm_result.dart' as _i125;
import 'nearby_confirmation.dart' as _i126;
import 'notification_settings.dart' as _i127;
import 'presence_conn_state.dart' as _i128;
import 'presence_info.dart' as _i129;
import 'presence_state.dart' as _i130;
import 'presence_watched_index.dart' as _i131;
import 'presence_watchers.dart' as _i132;
import 'product.dart' as _i133;
import 'product_admin_view.dart' as _i134;
import 'product_delivery_health.dart' as _i135;
import 'product_notification.dart' as _i136;
import 'product_notification_recipient_result.dart' as _i137;
import 'product_notification_send_result.dart' as _i138;
import 'product_object_room.dart' as _i139;
import 'profile_translation.dart' as _i140;
import 'pulse_access_audit_event.dart' as _i141;
import 'pulse_access_entry.dart' as _i142;
import 'pulse_alert_rule.dart' as _i143;
import 'pulse_event.dart' as _i144;
import 'pulse_expiry_reminder.dart' as _i145;
import 'pulse_folder.dart' as _i146;
import 'pulse_folder_membership.dart' as _i147;
import 'pulse_incident.dart' as _i148;
import 'pulse_member_view.dart' as _i149;
import 'pulse_monitor.dart' as _i150;
import 'pulse_monitor_created.dart' as _i151;
import 'pulse_monitor_membership.dart' as _i152;
import 'pulse_probe_allowlist_entry.dart' as _i153;
import 'pulse_tls_probe.dart' as _i154;
import 'pulse_value_threshold.dart' as _i155;
import 'push_queue_message.dart' as _i156;
import 'push_test_job.dart' as _i157;
import 'push_test_result.dart' as _i158;
import 'room.dart' as _i159;
import 'room_bot_commands.dart' as _i160;
import 'room_details.dart' as _i161;
import 'room_list_page.dart' as _i162;
import 'room_membership.dart' as _i163;
import 'room_participant.dart' as _i164;
import 'room_summary.dart' as _i165;
import 'room_task_stats.dart' as _i166;
import 'room_task_view.dart' as _i167;
import 'support_team.dart' as _i168;
import 'support_team_exclusion.dart' as _i169;
import 'support_team_member.dart' as _i170;
import 'support_team_member_view.dart' as _i171;
import 'support_team_view.dart' as _i172;
import 'task_link.dart' as _i173;
import 'task_manager_config.dart' as _i174;
import 'team.dart' as _i175;
import 'team_member.dart' as _i176;
import 'team_member_view.dart' as _i177;
import 'team_view.dart' as _i178;
import 'tenant.dart' as _i179;
import 'tenant_support_member.dart' as _i180;
import 'tenant_support_member_view.dart' as _i181;
import 'thread_read_state.dart' as _i182;
import 'ticket.dart' as _i183;
import 'ticket_event.dart' as _i184;
import 'ticket_view.dart' as _i185;
import 'trust_redeem_result.dart' as _i186;
import 'trust_token.dart' as _i187;
import 'trust_token_issued.dart' as _i188;
import 'turn_credentials.dart' as _i189;
import 'webhook_delivery.dart' as _i190;
import 'webhook_event_message.dart' as _i191;
import 'webhook_subscription.dart' as _i192;
import 'package:nsg_connect_client/src/protocol/webhook_subscription.dart'
    as _i193;
import 'package:nsg_connect_client/src/protocol/webhook_delivery.dart' as _i194;
import 'package:nsg_connect_client/src/protocol/announcement.dart' as _i195;
import 'package:nsg_connect_client/src/protocol/bot_audit_event.dart' as _i196;
import 'package:nsg_connect_client/src/protocol/bot.dart' as _i197;
import 'package:nsg_connect_client/src/protocol/room_summary.dart' as _i198;
import 'package:nsg_connect_client/src/protocol/available_bot.dart' as _i199;
import 'package:nsg_connect_client/src/protocol/bot_integration_view.dart'
    as _i200;
import 'package:nsg_connect_client/src/protocol/connect_tenant_status.dart'
    as _i201;
import 'package:nsg_connect_client/src/protocol/product_delivery_health.dart'
    as _i202;
import 'package:nsg_connect_client/src/protocol/tenant_support_member_view.dart'
    as _i203;
import 'package:nsg_connect_client/src/protocol/product_admin_view.dart'
    as _i204;
import 'package:nsg_connect_client/src/protocol/connect_key_audit_event.dart'
    as _i205;
import 'package:nsg_connect_client/src/protocol/team_view.dart' as _i206;
import 'package:nsg_connect_client/src/protocol/team_member_view.dart' as _i207;
import 'package:nsg_connect_client/src/protocol/device_session_info.dart'
    as _i208;
import 'package:nsg_connect_client/src/protocol/incoming_webhook.dart' as _i209;
import 'package:nsg_connect_client/src/protocol/bot_command.dart' as _i210;
import 'package:nsg_connect_client/src/protocol/room_bot_commands.dart'
    as _i211;
import 'package:nsg_connect_client/src/protocol/messenger_message.dart'
    as _i212;
import 'package:nsg_connect_client/src/protocol/call_ice_candidate.dart'
    as _i213;
import 'package:nsg_connect_client/src/protocol/call_history_entry.dart'
    as _i214;
import 'package:nsg_connect_client/src/protocol/messenger_event.dart' as _i215;
import 'package:nsg_connect_client/src/protocol/link_preview_view.dart'
    as _i216;
import 'package:nsg_connect_client/src/protocol/room_participant.dart' as _i217;
import 'package:nsg_connect_client/src/protocol/ticket_view.dart' as _i218;
import 'package:nsg_connect_client/src/protocol/announcement_view.dart'
    as _i219;
import 'package:nsg_connect_client/src/protocol/room_task_view.dart' as _i220;
import 'package:nsg_connect_client/src/protocol/presence_info.dart' as _i221;
import 'package:nsg_connect_client/src/protocol/chat_folder_view.dart' as _i222;
import 'package:nsg_connect_client/src/protocol/contact_request_view.dart'
    as _i223;
import 'package:nsg_connect_client/src/protocol/contact_label.dart' as _i224;
import 'package:nsg_connect_client/src/protocol/contact_label_assignment.dart'
    as _i225;
import 'package:nsg_connect_client/src/protocol/product_object_room.dart'
    as _i226;
import 'package:nsg_connect_client/src/protocol/product.dart' as _i227;
import 'package:nsg_connect_client/src/protocol/profile_translation.dart'
    as _i228;
import 'package:nsg_connect_client/src/protocol/pulse_folder.dart' as _i229;
import 'package:nsg_connect_client/src/protocol/pulse_monitor.dart' as _i230;
import 'package:nsg_connect_client/src/protocol/pulse_alert_rule.dart' as _i231;
import 'package:nsg_connect_client/src/protocol/pulse_incident.dart' as _i232;
import 'package:nsg_connect_client/src/protocol/pulse_access_entry.dart'
    as _i233;
import 'package:nsg_connect_client/src/protocol/pulse_member_view.dart'
    as _i234;
import 'package:nsg_connect_client/src/protocol/pulse_access_audit_event.dart'
    as _i235;
import 'package:nsg_connect_client/src/protocol/pulse_tls_probe.dart' as _i236;
import 'package:nsg_connect_client/src/protocol/pulse_value_threshold.dart'
    as _i237;
import 'package:nsg_connect_client/src/protocol/pulse_probe_allowlist_entry.dart'
    as _i238;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i239;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i240;
export 'announcement.dart';
export 'announcement_seen.dart';
export 'announcement_view.dart';
export 'attachment_bytes.dart';
export 'attachment_object.dart';
export 'attachment_placement.dart';
export 'attachment_ref.dart';
export 'attachment_url.dart';
export 'available_bot.dart';
export 'bot.dart';
export 'bot_audit_event.dart';
export 'bot_channel_health.dart';
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
export 'delivery_pending.dart';
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
export 'enums/team_kind.dart';
export 'enums/team_member_role.dart';
export 'enums/tenant_hosting_mode.dart';
export 'enums/trust_token_kind.dart';
export 'errors/adapter_not_configured_exception.dart';
export 'errors/ambiguous_product_key_exception.dart';
export 'errors/attachment_access_denied_exception.dart';
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
export 'errors/probe_target_not_allowed_exception.dart';
export 'errors/product_already_exists_exception.dart';
export 'errors/product_in_use_exception.dart';
export 'errors/product_not_found_exception.dart';
export 'errors/product_not_found_for_caller_exception.dart';
export 'errors/rate_limit_exceeded_exception.dart';
export 'errors/room_dissolve_partial_exception.dart';
export 'errors/room_unavailable_exception.dart';
export 'errors/screen_share_busy_exception.dart';
export 'errors/task_integration_not_configured_exception.dart';
export 'errors/team_access_denied_exception.dart';
export 'errors/team_peer_unknown_exception.dart';
export 'errors/tenant_already_exists_exception.dart';
export 'errors/tenant_not_found_exception.dart';
export 'errors/thumbnail_unavailable_exception.dart';
export 'errors/write_banned_exception.dart';
export 'escalation_result.dart';
export 'greetings/greeting.dart';
export 'identity_mapping.dart';
export 'incoming_webhook.dart';
export 'incoming_webhook_created.dart';
export 'link_preview.dart';
export 'link_preview_view.dart';
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
export 'product_delivery_health.dart';
export 'product_notification.dart';
export 'product_notification_recipient_result.dart';
export 'product_notification_send_result.dart';
export 'product_object_room.dart';
export 'profile_translation.dart';
export 'pulse_access_audit_event.dart';
export 'pulse_access_entry.dart';
export 'pulse_alert_rule.dart';
export 'pulse_event.dart';
export 'pulse_expiry_reminder.dart';
export 'pulse_folder.dart';
export 'pulse_folder_membership.dart';
export 'pulse_incident.dart';
export 'pulse_member_view.dart';
export 'pulse_monitor.dart';
export 'pulse_monitor_created.dart';
export 'pulse_monitor_membership.dart';
export 'pulse_probe_allowlist_entry.dart';
export 'pulse_tls_probe.dart';
export 'pulse_value_threshold.dart';
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
export 'room_task_view.dart';
export 'support_team.dart';
export 'support_team_exclusion.dart';
export 'support_team_member.dart';
export 'support_team_member_view.dart';
export 'support_team_view.dart';
export 'task_link.dart';
export 'task_manager_config.dart';
export 'team.dart';
export 'team_member.dart';
export 'team_member_view.dart';
export 'team_view.dart';
export 'tenant.dart';
export 'tenant_support_member.dart';
export 'tenant_support_member_view.dart';
export 'thread_read_state.dart';
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

    if (t == _i2.Announcement) {
      return _i2.Announcement.fromJson(data) as T;
    }
    if (t == _i3.AnnouncementSeen) {
      return _i3.AnnouncementSeen.fromJson(data) as T;
    }
    if (t == _i4.AnnouncementView) {
      return _i4.AnnouncementView.fromJson(data) as T;
    }
    if (t == _i5.AttachmentBytes) {
      return _i5.AttachmentBytes.fromJson(data) as T;
    }
    if (t == _i6.AttachmentObject) {
      return _i6.AttachmentObject.fromJson(data) as T;
    }
    if (t == _i7.AttachmentPlacement) {
      return _i7.AttachmentPlacement.fromJson(data) as T;
    }
    if (t == _i8.AttachmentRef) {
      return _i8.AttachmentRef.fromJson(data) as T;
    }
    if (t == _i9.AttachmentUrl) {
      return _i9.AttachmentUrl.fromJson(data) as T;
    }
    if (t == _i10.AvailableBot) {
      return _i10.AvailableBot.fromJson(data) as T;
    }
    if (t == _i11.Bot) {
      return _i11.Bot.fromJson(data) as T;
    }
    if (t == _i12.BotAuditEvent) {
      return _i12.BotAuditEvent.fromJson(data) as T;
    }
    if (t == _i13.BotChannelHealth) {
      return _i13.BotChannelHealth.fromJson(data) as T;
    }
    if (t == _i14.BotCommand) {
      return _i14.BotCommand.fromJson(data) as T;
    }
    if (t == _i15.BotIntegrationCreated) {
      return _i15.BotIntegrationCreated.fromJson(data) as T;
    }
    if (t == _i16.BotIntegrationView) {
      return _i16.BotIntegrationView.fromJson(data) as T;
    }
    if (t == _i17.BotReadModeResult) {
      return _i17.BotReadModeResult.fromJson(data) as T;
    }
    if (t == _i18.CallHistoryEntry) {
      return _i18.CallHistoryEntry.fromJson(data) as T;
    }
    if (t == _i19.CallIceCandidate) {
      return _i19.CallIceCandidate.fromJson(data) as T;
    }
    if (t == _i20.ChatFolderRecord) {
      return _i20.ChatFolderRecord.fromJson(data) as T;
    }
    if (t == _i21.ChatFolderRoom) {
      return _i21.ChatFolderRoom.fromJson(data) as T;
    }
    if (t == _i22.ChatFolderView) {
      return _i22.ChatFolderView.fromJson(data) as T;
    }
    if (t == _i23.Conference) {
      return _i23.Conference.fromJson(data) as T;
    }
    if (t == _i24.ConferenceMember) {
      return _i24.ConferenceMember.fromJson(data) as T;
    }
    if (t == _i25.ConferenceParticipant) {
      return _i25.ConferenceParticipant.fromJson(data) as T;
    }
    if (t == _i26.ConferenceScreenShare) {
      return _i26.ConferenceScreenShare.fromJson(data) as T;
    }
    if (t == _i27.ConferenceState) {
      return _i27.ConferenceState.fromJson(data) as T;
    }
    if (t == _i28.ConnectIssuedToken) {
      return _i28.ConnectIssuedToken.fromJson(data) as T;
    }
    if (t == _i29.ConnectIssuedTokenResult) {
      return _i29.ConnectIssuedTokenResult.fromJson(data) as T;
    }
    if (t == _i30.ConnectKeyAuditEvent) {
      return _i30.ConnectKeyAuditEvent.fromJson(data) as T;
    }
    if (t == _i31.ConnectTenantStatus) {
      return _i31.ConnectTenantStatus.fromJson(data) as T;
    }
    if (t == _i32.ContactBlock) {
      return _i32.ContactBlock.fromJson(data) as T;
    }
    if (t == _i33.ContactCard) {
      return _i33.ContactCard.fromJson(data) as T;
    }
    if (t == _i34.ContactCardInfo) {
      return _i34.ContactCardInfo.fromJson(data) as T;
    }
    if (t == _i35.ContactLabel) {
      return _i35.ContactLabel.fromJson(data) as T;
    }
    if (t == _i36.ContactLabelAssignment) {
      return _i36.ContactLabelAssignment.fromJson(data) as T;
    }
    if (t == _i37.ContactLink) {
      return _i37.ContactLink.fromJson(data) as T;
    }
    if (t == _i38.ContactMeta) {
      return _i38.ContactMeta.fromJson(data) as T;
    }
    if (t == _i39.ContactProfileView) {
      return _i39.ContactProfileView.fromJson(data) as T;
    }
    if (t == _i40.ContactRelation) {
      return _i40.ContactRelation.fromJson(data) as T;
    }
    if (t == _i41.ContactRequest) {
      return _i41.ContactRequest.fromJson(data) as T;
    }
    if (t == _i42.ContactRequestView) {
      return _i42.ContactRequestView.fromJson(data) as T;
    }
    if (t == _i43.DeliveryPending) {
      return _i43.DeliveryPending.fromJson(data) as T;
    }
    if (t == _i44.DeviceRegistration) {
      return _i44.DeviceRegistration.fromJson(data) as T;
    }
    if (t == _i45.DeviceSessionInfo) {
      return _i45.DeviceSessionInfo.fromJson(data) as T;
    }
    if (t == _i46.EmailAccount) {
      return _i46.EmailAccount.fromJson(data) as T;
    }
    if (t == _i47.EmailSession) {
      return _i47.EmailSession.fromJson(data) as T;
    }
    if (t == _i48.EmailVerificationCode) {
      return _i48.EmailVerificationCode.fromJson(data) as T;
    }
    if (t == _i49.AttachmentRejectReason) {
      return _i49.AttachmentRejectReason.fromJson(data) as T;
    }
    if (t == _i50.CallEventType) {
      return _i50.CallEventType.fromJson(data) as T;
    }
    if (t == _i51.CallStatus) {
      return _i51.CallStatus.fromJson(data) as T;
    }
    if (t == _i52.ContactLinkSource) {
      return _i52.ContactLinkSource.fromJson(data) as T;
    }
    if (t == _i53.ContactRequestStatus) {
      return _i53.ContactRequestStatus.fromJson(data) as T;
    }
    if (t == _i54.DevicePlatform) {
      return _i54.DevicePlatform.fromJson(data) as T;
    }
    if (t == _i55.IdentityProvider) {
      return _i55.IdentityProvider.fromJson(data) as T;
    }
    if (t == _i56.MessengerEventType) {
      return _i56.MessengerEventType.fromJson(data) as T;
    }
    if (t == _i57.ParticipantKind) {
      return _i57.ParticipantKind.fromJson(data) as T;
    }
    if (t == _i58.ProductNotificationStatus) {
      return _i58.ProductNotificationStatus.fromJson(data) as T;
    }
    if (t == _i59.PushService) {
      return _i59.PushService.fromJson(data) as T;
    }
    if (t == _i60.RoomMemberRole) {
      return _i60.RoomMemberRole.fromJson(data) as T;
    }
    if (t == _i61.RoomOwnership) {
      return _i61.RoomOwnership.fromJson(data) as T;
    }
    if (t == _i62.RoomState) {
      return _i62.RoomState.fromJson(data) as T;
    }
    if (t == _i63.RoomType) {
      return _i63.RoomType.fromJson(data) as T;
    }
    if (t == _i64.SupportTeamRole) {
      return _i64.SupportTeamRole.fromJson(data) as T;
    }
    if (t == _i65.TeamKind) {
      return _i65.TeamKind.fromJson(data) as T;
    }
    if (t == _i66.TeamMemberRole) {
      return _i66.TeamMemberRole.fromJson(data) as T;
    }
    if (t == _i67.TenantHostingMode) {
      return _i67.TenantHostingMode.fromJson(data) as T;
    }
    if (t == _i68.TrustTokenKind) {
      return _i68.TrustTokenKind.fromJson(data) as T;
    }
    if (t == _i69.AdapterNotConfiguredException) {
      return _i69.AdapterNotConfiguredException.fromJson(data) as T;
    }
    if (t == _i70.AmbiguousProductKeyException) {
      return _i70.AmbiguousProductKeyException.fromJson(data) as T;
    }
    if (t == _i71.AttachmentAccessDeniedException) {
      return _i71.AttachmentAccessDeniedException.fromJson(data) as T;
    }
    if (t == _i72.AttachmentRejectedException) {
      return _i72.AttachmentRejectedException.fromJson(data) as T;
    }
    if (t == _i73.BotCapabilityException) {
      return _i73.BotCapabilityException.fromJson(data) as T;
    }
    if (t == _i74.BotLimitExceededException) {
      return _i74.BotLimitExceededException.fromJson(data) as T;
    }
    if (t == _i75.BotNotFoundException) {
      return _i75.BotNotFoundException.fromJson(data) as T;
    }
    if (t == _i76.BotReadRestrictedException) {
      return _i76.BotReadRestrictedException.fromJson(data) as T;
    }
    if (t == _i77.ConferenceFullException) {
      return _i77.ConferenceFullException.fromJson(data) as T;
    }
    if (t == _i78.EmailAuthException) {
      return _i78.EmailAuthException.fromJson(data) as T;
    }
    if (t == _i79.InsufficientPowerException) {
      return _i79.InsufficientPowerException.fromJson(data) as T;
    }
    if (t == _i80.InvalidBotCommandsException) {
      return _i80.InvalidBotCommandsException.fromJson(data) as T;
    }
    if (t == _i81.InvalidExternalKeyException) {
      return _i81.InvalidExternalKeyException.fromJson(data) as T;
    }
    if (t == _i82.InvalidNotificationException) {
      return _i82.InvalidNotificationException.fromJson(data) as T;
    }
    if (t == _i83.InvalidTokenException) {
      return _i83.InvalidTokenException.fromJson(data) as T;
    }
    if (t == _i84.LastOwnerCannotDemoteException) {
      return _i84.LastOwnerCannotDemoteException.fromJson(data) as T;
    }
    if (t == _i85.MessageBodyTooLargeException) {
      return _i85.MessageBodyTooLargeException.fromJson(data) as T;
    }
    if (t == _i86.MessageDeletedException) {
      return _i86.MessageDeletedException.fromJson(data) as T;
    }
    if (t == _i87.MessageNotEditableException) {
      return _i87.MessageNotEditableException.fromJson(data) as T;
    }
    if (t == _i88.MessengerNotAuthenticatedException) {
      return _i88.MessengerNotAuthenticatedException.fromJson(data) as T;
    }
    if (t == _i89.NotObjectRoomException) {
      return _i89.NotObjectRoomException.fromJson(data) as T;
    }
    if (t == _i90.NotSupportTeamMemberException) {
      return _i90.NotSupportTeamMemberException.fromJson(data) as T;
    }
    if (t == _i91.NotSupportTeamOwnerException) {
      return _i91.NotSupportTeamOwnerException.fromJson(data) as T;
    }
    if (t == _i92.OperatorEmailNotResolvedException) {
      return _i92.OperatorEmailNotResolvedException.fromJson(data) as T;
    }
    if (t == _i93.PeerUnavailableException) {
      return _i93.PeerUnavailableException.fromJson(data) as T;
    }
    if (t == _i94.ProbeTargetNotAllowedException) {
      return _i94.ProbeTargetNotAllowedException.fromJson(data) as T;
    }
    if (t == _i95.ProductAlreadyExistsException) {
      return _i95.ProductAlreadyExistsException.fromJson(data) as T;
    }
    if (t == _i96.ProductInUseException) {
      return _i96.ProductInUseException.fromJson(data) as T;
    }
    if (t == _i97.ProductNotFoundException) {
      return _i97.ProductNotFoundException.fromJson(data) as T;
    }
    if (t == _i98.ProductNotFoundForCallerException) {
      return _i98.ProductNotFoundForCallerException.fromJson(data) as T;
    }
    if (t == _i99.RateLimitExceededException) {
      return _i99.RateLimitExceededException.fromJson(data) as T;
    }
    if (t == _i100.RoomDissolvePartialException) {
      return _i100.RoomDissolvePartialException.fromJson(data) as T;
    }
    if (t == _i101.RoomUnavailableException) {
      return _i101.RoomUnavailableException.fromJson(data) as T;
    }
    if (t == _i102.ScreenShareBusyException) {
      return _i102.ScreenShareBusyException.fromJson(data) as T;
    }
    if (t == _i103.TaskIntegrationNotConfiguredException) {
      return _i103.TaskIntegrationNotConfiguredException.fromJson(data) as T;
    }
    if (t == _i104.TeamAccessDeniedException) {
      return _i104.TeamAccessDeniedException.fromJson(data) as T;
    }
    if (t == _i105.TeamPeerUnknownException) {
      return _i105.TeamPeerUnknownException.fromJson(data) as T;
    }
    if (t == _i106.TenantAlreadyExistsException) {
      return _i106.TenantAlreadyExistsException.fromJson(data) as T;
    }
    if (t == _i107.TenantNotFoundException) {
      return _i107.TenantNotFoundException.fromJson(data) as T;
    }
    if (t == _i108.ThumbnailUnavailableException) {
      return _i108.ThumbnailUnavailableException.fromJson(data) as T;
    }
    if (t == _i109.WriteBannedException) {
      return _i109.WriteBannedException.fromJson(data) as T;
    }
    if (t == _i110.EscalationResult) {
      return _i110.EscalationResult.fromJson(data) as T;
    }
    if (t == _i111.Greeting) {
      return _i111.Greeting.fromJson(data) as T;
    }
    if (t == _i112.IdentityMapping) {
      return _i112.IdentityMapping.fromJson(data) as T;
    }
    if (t == _i113.IncomingWebhook) {
      return _i113.IncomingWebhook.fromJson(data) as T;
    }
    if (t == _i114.IncomingWebhookCreated) {
      return _i114.IncomingWebhookCreated.fromJson(data) as T;
    }
    if (t == _i115.LinkPreview) {
      return _i115.LinkPreview.fromJson(data) as T;
    }
    if (t == _i116.LinkPreviewView) {
      return _i116.LinkPreviewView.fromJson(data) as T;
    }
    if (t == _i117.MessageIndex) {
      return _i117.MessageIndex.fromJson(data) as T;
    }
    if (t == _i118.MessengerAuthContext) {
      return _i118.MessengerAuthContext.fromJson(data) as T;
    }
    if (t == _i119.MessengerEvent) {
      return _i119.MessengerEvent.fromJson(data) as T;
    }
    if (t == _i120.MessengerMessage) {
      return _i120.MessengerMessage.fromJson(data) as T;
    }
    if (t == _i121.MessengerMessageListPage) {
      return _i121.MessengerMessageListPage.fromJson(data) as T;
    }
    if (t == _i122.MessengerSession) {
      return _i122.MessengerSession.fromJson(data) as T;
    }
    if (t == _i123.MessengerSessionToken) {
      return _i123.MessengerSessionToken.fromJson(data) as T;
    }
    if (t == _i124.MessengerUser) {
      return _i124.MessengerUser.fromJson(data) as T;
    }
    if (t == _i125.NearbyConfirmResult) {
      return _i125.NearbyConfirmResult.fromJson(data) as T;
    }
    if (t == _i126.NearbyConfirmation) {
      return _i126.NearbyConfirmation.fromJson(data) as T;
    }
    if (t == _i127.NotificationSettings) {
      return _i127.NotificationSettings.fromJson(data) as T;
    }
    if (t == _i128.PresenceConnState) {
      return _i128.PresenceConnState.fromJson(data) as T;
    }
    if (t == _i129.PresenceInfo) {
      return _i129.PresenceInfo.fromJson(data) as T;
    }
    if (t == _i130.PresenceState) {
      return _i130.PresenceState.fromJson(data) as T;
    }
    if (t == _i131.PresenceWatchedIndex) {
      return _i131.PresenceWatchedIndex.fromJson(data) as T;
    }
    if (t == _i132.PresenceWatchers) {
      return _i132.PresenceWatchers.fromJson(data) as T;
    }
    if (t == _i133.Product) {
      return _i133.Product.fromJson(data) as T;
    }
    if (t == _i134.ProductAdminView) {
      return _i134.ProductAdminView.fromJson(data) as T;
    }
    if (t == _i135.ProductDeliveryHealth) {
      return _i135.ProductDeliveryHealth.fromJson(data) as T;
    }
    if (t == _i136.ProductNotification) {
      return _i136.ProductNotification.fromJson(data) as T;
    }
    if (t == _i137.ProductNotificationRecipientResult) {
      return _i137.ProductNotificationRecipientResult.fromJson(data) as T;
    }
    if (t == _i138.ProductNotificationSendResult) {
      return _i138.ProductNotificationSendResult.fromJson(data) as T;
    }
    if (t == _i139.ProductObjectRoom) {
      return _i139.ProductObjectRoom.fromJson(data) as T;
    }
    if (t == _i140.ProfileTranslation) {
      return _i140.ProfileTranslation.fromJson(data) as T;
    }
    if (t == _i141.PulseAccessAuditEvent) {
      return _i141.PulseAccessAuditEvent.fromJson(data) as T;
    }
    if (t == _i142.PulseAccessEntry) {
      return _i142.PulseAccessEntry.fromJson(data) as T;
    }
    if (t == _i143.PulseAlertRule) {
      return _i143.PulseAlertRule.fromJson(data) as T;
    }
    if (t == _i144.PulseEvent) {
      return _i144.PulseEvent.fromJson(data) as T;
    }
    if (t == _i145.PulseExpiryReminder) {
      return _i145.PulseExpiryReminder.fromJson(data) as T;
    }
    if (t == _i146.PulseFolder) {
      return _i146.PulseFolder.fromJson(data) as T;
    }
    if (t == _i147.PulseFolderMembership) {
      return _i147.PulseFolderMembership.fromJson(data) as T;
    }
    if (t == _i148.PulseIncident) {
      return _i148.PulseIncident.fromJson(data) as T;
    }
    if (t == _i149.PulseMemberView) {
      return _i149.PulseMemberView.fromJson(data) as T;
    }
    if (t == _i150.PulseMonitor) {
      return _i150.PulseMonitor.fromJson(data) as T;
    }
    if (t == _i151.PulseMonitorCreated) {
      return _i151.PulseMonitorCreated.fromJson(data) as T;
    }
    if (t == _i152.PulseMonitorMembership) {
      return _i152.PulseMonitorMembership.fromJson(data) as T;
    }
    if (t == _i153.PulseProbeAllowlistEntry) {
      return _i153.PulseProbeAllowlistEntry.fromJson(data) as T;
    }
    if (t == _i154.PulseTlsProbe) {
      return _i154.PulseTlsProbe.fromJson(data) as T;
    }
    if (t == _i155.PulseValueThreshold) {
      return _i155.PulseValueThreshold.fromJson(data) as T;
    }
    if (t == _i156.PushQueueMessage) {
      return _i156.PushQueueMessage.fromJson(data) as T;
    }
    if (t == _i157.PushTestJob) {
      return _i157.PushTestJob.fromJson(data) as T;
    }
    if (t == _i158.PushTestResult) {
      return _i158.PushTestResult.fromJson(data) as T;
    }
    if (t == _i159.Room) {
      return _i159.Room.fromJson(data) as T;
    }
    if (t == _i160.RoomBotCommands) {
      return _i160.RoomBotCommands.fromJson(data) as T;
    }
    if (t == _i161.RoomDetails) {
      return _i161.RoomDetails.fromJson(data) as T;
    }
    if (t == _i162.RoomListPage) {
      return _i162.RoomListPage.fromJson(data) as T;
    }
    if (t == _i163.RoomMembership) {
      return _i163.RoomMembership.fromJson(data) as T;
    }
    if (t == _i164.RoomParticipant) {
      return _i164.RoomParticipant.fromJson(data) as T;
    }
    if (t == _i165.RoomSummary) {
      return _i165.RoomSummary.fromJson(data) as T;
    }
    if (t == _i166.RoomTaskStats) {
      return _i166.RoomTaskStats.fromJson(data) as T;
    }
    if (t == _i167.RoomTaskView) {
      return _i167.RoomTaskView.fromJson(data) as T;
    }
    if (t == _i168.SupportTeam) {
      return _i168.SupportTeam.fromJson(data) as T;
    }
    if (t == _i169.SupportTeamExclusion) {
      return _i169.SupportTeamExclusion.fromJson(data) as T;
    }
    if (t == _i170.SupportTeamMember) {
      return _i170.SupportTeamMember.fromJson(data) as T;
    }
    if (t == _i171.SupportTeamMemberView) {
      return _i171.SupportTeamMemberView.fromJson(data) as T;
    }
    if (t == _i172.SupportTeamView) {
      return _i172.SupportTeamView.fromJson(data) as T;
    }
    if (t == _i173.TaskLink) {
      return _i173.TaskLink.fromJson(data) as T;
    }
    if (t == _i174.TaskManagerConfig) {
      return _i174.TaskManagerConfig.fromJson(data) as T;
    }
    if (t == _i175.Team) {
      return _i175.Team.fromJson(data) as T;
    }
    if (t == _i176.TeamMember) {
      return _i176.TeamMember.fromJson(data) as T;
    }
    if (t == _i177.TeamMemberView) {
      return _i177.TeamMemberView.fromJson(data) as T;
    }
    if (t == _i178.TeamView) {
      return _i178.TeamView.fromJson(data) as T;
    }
    if (t == _i179.Tenant) {
      return _i179.Tenant.fromJson(data) as T;
    }
    if (t == _i180.TenantSupportMember) {
      return _i180.TenantSupportMember.fromJson(data) as T;
    }
    if (t == _i181.TenantSupportMemberView) {
      return _i181.TenantSupportMemberView.fromJson(data) as T;
    }
    if (t == _i182.ThreadReadState) {
      return _i182.ThreadReadState.fromJson(data) as T;
    }
    if (t == _i183.Ticket) {
      return _i183.Ticket.fromJson(data) as T;
    }
    if (t == _i184.TicketEvent) {
      return _i184.TicketEvent.fromJson(data) as T;
    }
    if (t == _i185.TicketView) {
      return _i185.TicketView.fromJson(data) as T;
    }
    if (t == _i186.TrustRedeemResult) {
      return _i186.TrustRedeemResult.fromJson(data) as T;
    }
    if (t == _i187.TrustToken) {
      return _i187.TrustToken.fromJson(data) as T;
    }
    if (t == _i188.TrustTokenIssued) {
      return _i188.TrustTokenIssued.fromJson(data) as T;
    }
    if (t == _i189.TurnCredentials) {
      return _i189.TurnCredentials.fromJson(data) as T;
    }
    if (t == _i190.WebhookDelivery) {
      return _i190.WebhookDelivery.fromJson(data) as T;
    }
    if (t == _i191.WebhookEventMessage) {
      return _i191.WebhookEventMessage.fromJson(data) as T;
    }
    if (t == _i192.WebhookSubscription) {
      return _i192.WebhookSubscription.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Announcement?>()) {
      return (data != null ? _i2.Announcement.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AnnouncementSeen?>()) {
      return (data != null ? _i3.AnnouncementSeen.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.AnnouncementView?>()) {
      return (data != null ? _i4.AnnouncementView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.AttachmentBytes?>()) {
      return (data != null ? _i5.AttachmentBytes.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.AttachmentObject?>()) {
      return (data != null ? _i6.AttachmentObject.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.AttachmentPlacement?>()) {
      return (data != null ? _i7.AttachmentPlacement.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.AttachmentRef?>()) {
      return (data != null ? _i8.AttachmentRef.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.AttachmentUrl?>()) {
      return (data != null ? _i9.AttachmentUrl.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.AvailableBot?>()) {
      return (data != null ? _i10.AvailableBot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.Bot?>()) {
      return (data != null ? _i11.Bot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.BotAuditEvent?>()) {
      return (data != null ? _i12.BotAuditEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.BotChannelHealth?>()) {
      return (data != null ? _i13.BotChannelHealth.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.BotCommand?>()) {
      return (data != null ? _i14.BotCommand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.BotIntegrationCreated?>()) {
      return (data != null ? _i15.BotIntegrationCreated.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.BotIntegrationView?>()) {
      return (data != null ? _i16.BotIntegrationView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i17.BotReadModeResult?>()) {
      return (data != null ? _i17.BotReadModeResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.CallHistoryEntry?>()) {
      return (data != null ? _i18.CallHistoryEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.CallIceCandidate?>()) {
      return (data != null ? _i19.CallIceCandidate.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.ChatFolderRecord?>()) {
      return (data != null ? _i20.ChatFolderRecord.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.ChatFolderRoom?>()) {
      return (data != null ? _i21.ChatFolderRoom.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.ChatFolderView?>()) {
      return (data != null ? _i22.ChatFolderView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.Conference?>()) {
      return (data != null ? _i23.Conference.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.ConferenceMember?>()) {
      return (data != null ? _i24.ConferenceMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.ConferenceParticipant?>()) {
      return (data != null ? _i25.ConferenceParticipant.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i26.ConferenceScreenShare?>()) {
      return (data != null ? _i26.ConferenceScreenShare.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i27.ConferenceState?>()) {
      return (data != null ? _i27.ConferenceState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.ConnectIssuedToken?>()) {
      return (data != null ? _i28.ConnectIssuedToken.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i29.ConnectIssuedTokenResult?>()) {
      return (data != null
              ? _i29.ConnectIssuedTokenResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i30.ConnectKeyAuditEvent?>()) {
      return (data != null ? _i30.ConnectKeyAuditEvent.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i31.ConnectTenantStatus?>()) {
      return (data != null ? _i31.ConnectTenantStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i32.ContactBlock?>()) {
      return (data != null ? _i32.ContactBlock.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i33.ContactCard?>()) {
      return (data != null ? _i33.ContactCard.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i34.ContactCardInfo?>()) {
      return (data != null ? _i34.ContactCardInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i35.ContactLabel?>()) {
      return (data != null ? _i35.ContactLabel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i36.ContactLabelAssignment?>()) {
      return (data != null ? _i36.ContactLabelAssignment.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i37.ContactLink?>()) {
      return (data != null ? _i37.ContactLink.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i38.ContactMeta?>()) {
      return (data != null ? _i38.ContactMeta.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i39.ContactProfileView?>()) {
      return (data != null ? _i39.ContactProfileView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i40.ContactRelation?>()) {
      return (data != null ? _i40.ContactRelation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i41.ContactRequest?>()) {
      return (data != null ? _i41.ContactRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i42.ContactRequestView?>()) {
      return (data != null ? _i42.ContactRequestView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i43.DeliveryPending?>()) {
      return (data != null ? _i43.DeliveryPending.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i44.DeviceRegistration?>()) {
      return (data != null ? _i44.DeviceRegistration.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i45.DeviceSessionInfo?>()) {
      return (data != null ? _i45.DeviceSessionInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i46.EmailAccount?>()) {
      return (data != null ? _i46.EmailAccount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i47.EmailSession?>()) {
      return (data != null ? _i47.EmailSession.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i48.EmailVerificationCode?>()) {
      return (data != null ? _i48.EmailVerificationCode.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i49.AttachmentRejectReason?>()) {
      return (data != null ? _i49.AttachmentRejectReason.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i50.CallEventType?>()) {
      return (data != null ? _i50.CallEventType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i51.CallStatus?>()) {
      return (data != null ? _i51.CallStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i52.ContactLinkSource?>()) {
      return (data != null ? _i52.ContactLinkSource.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i53.ContactRequestStatus?>()) {
      return (data != null ? _i53.ContactRequestStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i54.DevicePlatform?>()) {
      return (data != null ? _i54.DevicePlatform.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i55.IdentityProvider?>()) {
      return (data != null ? _i55.IdentityProvider.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i56.MessengerEventType?>()) {
      return (data != null ? _i56.MessengerEventType.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i57.ParticipantKind?>()) {
      return (data != null ? _i57.ParticipantKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i58.ProductNotificationStatus?>()) {
      return (data != null
              ? _i58.ProductNotificationStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i59.PushService?>()) {
      return (data != null ? _i59.PushService.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i60.RoomMemberRole?>()) {
      return (data != null ? _i60.RoomMemberRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i61.RoomOwnership?>()) {
      return (data != null ? _i61.RoomOwnership.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i62.RoomState?>()) {
      return (data != null ? _i62.RoomState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i63.RoomType?>()) {
      return (data != null ? _i63.RoomType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i64.SupportTeamRole?>()) {
      return (data != null ? _i64.SupportTeamRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i65.TeamKind?>()) {
      return (data != null ? _i65.TeamKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i66.TeamMemberRole?>()) {
      return (data != null ? _i66.TeamMemberRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i67.TenantHostingMode?>()) {
      return (data != null ? _i67.TenantHostingMode.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i68.TrustTokenKind?>()) {
      return (data != null ? _i68.TrustTokenKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i69.AdapterNotConfiguredException?>()) {
      return (data != null
              ? _i69.AdapterNotConfiguredException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i70.AmbiguousProductKeyException?>()) {
      return (data != null
              ? _i70.AmbiguousProductKeyException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i71.AttachmentAccessDeniedException?>()) {
      return (data != null
              ? _i71.AttachmentAccessDeniedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i72.AttachmentRejectedException?>()) {
      return (data != null
              ? _i72.AttachmentRejectedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i73.BotCapabilityException?>()) {
      return (data != null ? _i73.BotCapabilityException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i74.BotLimitExceededException?>()) {
      return (data != null
              ? _i74.BotLimitExceededException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i75.BotNotFoundException?>()) {
      return (data != null ? _i75.BotNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i76.BotReadRestrictedException?>()) {
      return (data != null
              ? _i76.BotReadRestrictedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i77.ConferenceFullException?>()) {
      return (data != null ? _i77.ConferenceFullException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i78.EmailAuthException?>()) {
      return (data != null ? _i78.EmailAuthException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i79.InsufficientPowerException?>()) {
      return (data != null
              ? _i79.InsufficientPowerException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i80.InvalidBotCommandsException?>()) {
      return (data != null
              ? _i80.InvalidBotCommandsException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i81.InvalidExternalKeyException?>()) {
      return (data != null
              ? _i81.InvalidExternalKeyException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i82.InvalidNotificationException?>()) {
      return (data != null
              ? _i82.InvalidNotificationException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i83.InvalidTokenException?>()) {
      return (data != null ? _i83.InvalidTokenException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i84.LastOwnerCannotDemoteException?>()) {
      return (data != null
              ? _i84.LastOwnerCannotDemoteException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i85.MessageBodyTooLargeException?>()) {
      return (data != null
              ? _i85.MessageBodyTooLargeException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i86.MessageDeletedException?>()) {
      return (data != null ? _i86.MessageDeletedException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i87.MessageNotEditableException?>()) {
      return (data != null
              ? _i87.MessageNotEditableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i88.MessengerNotAuthenticatedException?>()) {
      return (data != null
              ? _i88.MessengerNotAuthenticatedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i89.NotObjectRoomException?>()) {
      return (data != null ? _i89.NotObjectRoomException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i90.NotSupportTeamMemberException?>()) {
      return (data != null
              ? _i90.NotSupportTeamMemberException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i91.NotSupportTeamOwnerException?>()) {
      return (data != null
              ? _i91.NotSupportTeamOwnerException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i92.OperatorEmailNotResolvedException?>()) {
      return (data != null
              ? _i92.OperatorEmailNotResolvedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i93.PeerUnavailableException?>()) {
      return (data != null
              ? _i93.PeerUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i94.ProbeTargetNotAllowedException?>()) {
      return (data != null
              ? _i94.ProbeTargetNotAllowedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i95.ProductAlreadyExistsException?>()) {
      return (data != null
              ? _i95.ProductAlreadyExistsException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i96.ProductInUseException?>()) {
      return (data != null ? _i96.ProductInUseException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i97.ProductNotFoundException?>()) {
      return (data != null
              ? _i97.ProductNotFoundException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i98.ProductNotFoundForCallerException?>()) {
      return (data != null
              ? _i98.ProductNotFoundForCallerException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i99.RateLimitExceededException?>()) {
      return (data != null
              ? _i99.RateLimitExceededException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i100.RoomDissolvePartialException?>()) {
      return (data != null
              ? _i100.RoomDissolvePartialException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i101.RoomUnavailableException?>()) {
      return (data != null
              ? _i101.RoomUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i102.ScreenShareBusyException?>()) {
      return (data != null
              ? _i102.ScreenShareBusyException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i103.TaskIntegrationNotConfiguredException?>()) {
      return (data != null
              ? _i103.TaskIntegrationNotConfiguredException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i104.TeamAccessDeniedException?>()) {
      return (data != null
              ? _i104.TeamAccessDeniedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i105.TeamPeerUnknownException?>()) {
      return (data != null
              ? _i105.TeamPeerUnknownException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i106.TenantAlreadyExistsException?>()) {
      return (data != null
              ? _i106.TenantAlreadyExistsException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i107.TenantNotFoundException?>()) {
      return (data != null
              ? _i107.TenantNotFoundException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i108.ThumbnailUnavailableException?>()) {
      return (data != null
              ? _i108.ThumbnailUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i109.WriteBannedException?>()) {
      return (data != null ? _i109.WriteBannedException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i110.EscalationResult?>()) {
      return (data != null ? _i110.EscalationResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i111.Greeting?>()) {
      return (data != null ? _i111.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i112.IdentityMapping?>()) {
      return (data != null ? _i112.IdentityMapping.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i113.IncomingWebhook?>()) {
      return (data != null ? _i113.IncomingWebhook.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i114.IncomingWebhookCreated?>()) {
      return (data != null ? _i114.IncomingWebhookCreated.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i115.LinkPreview?>()) {
      return (data != null ? _i115.LinkPreview.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i116.LinkPreviewView?>()) {
      return (data != null ? _i116.LinkPreviewView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i117.MessageIndex?>()) {
      return (data != null ? _i117.MessageIndex.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i118.MessengerAuthContext?>()) {
      return (data != null ? _i118.MessengerAuthContext.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i119.MessengerEvent?>()) {
      return (data != null ? _i119.MessengerEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i120.MessengerMessage?>()) {
      return (data != null ? _i120.MessengerMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i121.MessengerMessageListPage?>()) {
      return (data != null
              ? _i121.MessengerMessageListPage.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i122.MessengerSession?>()) {
      return (data != null ? _i122.MessengerSession.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i123.MessengerSessionToken?>()) {
      return (data != null ? _i123.MessengerSessionToken.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i124.MessengerUser?>()) {
      return (data != null ? _i124.MessengerUser.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i125.NearbyConfirmResult?>()) {
      return (data != null ? _i125.NearbyConfirmResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i126.NearbyConfirmation?>()) {
      return (data != null ? _i126.NearbyConfirmation.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i127.NotificationSettings?>()) {
      return (data != null ? _i127.NotificationSettings.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i128.PresenceConnState?>()) {
      return (data != null ? _i128.PresenceConnState.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i129.PresenceInfo?>()) {
      return (data != null ? _i129.PresenceInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i130.PresenceState?>()) {
      return (data != null ? _i130.PresenceState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i131.PresenceWatchedIndex?>()) {
      return (data != null ? _i131.PresenceWatchedIndex.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i132.PresenceWatchers?>()) {
      return (data != null ? _i132.PresenceWatchers.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i133.Product?>()) {
      return (data != null ? _i133.Product.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i134.ProductAdminView?>()) {
      return (data != null ? _i134.ProductAdminView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i135.ProductDeliveryHealth?>()) {
      return (data != null ? _i135.ProductDeliveryHealth.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i136.ProductNotification?>()) {
      return (data != null ? _i136.ProductNotification.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i137.ProductNotificationRecipientResult?>()) {
      return (data != null
              ? _i137.ProductNotificationRecipientResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i138.ProductNotificationSendResult?>()) {
      return (data != null
              ? _i138.ProductNotificationSendResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i139.ProductObjectRoom?>()) {
      return (data != null ? _i139.ProductObjectRoom.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i140.ProfileTranslation?>()) {
      return (data != null ? _i140.ProfileTranslation.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i141.PulseAccessAuditEvent?>()) {
      return (data != null ? _i141.PulseAccessAuditEvent.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i142.PulseAccessEntry?>()) {
      return (data != null ? _i142.PulseAccessEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i143.PulseAlertRule?>()) {
      return (data != null ? _i143.PulseAlertRule.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i144.PulseEvent?>()) {
      return (data != null ? _i144.PulseEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i145.PulseExpiryReminder?>()) {
      return (data != null ? _i145.PulseExpiryReminder.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i146.PulseFolder?>()) {
      return (data != null ? _i146.PulseFolder.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i147.PulseFolderMembership?>()) {
      return (data != null ? _i147.PulseFolderMembership.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i148.PulseIncident?>()) {
      return (data != null ? _i148.PulseIncident.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i149.PulseMemberView?>()) {
      return (data != null ? _i149.PulseMemberView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i150.PulseMonitor?>()) {
      return (data != null ? _i150.PulseMonitor.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i151.PulseMonitorCreated?>()) {
      return (data != null ? _i151.PulseMonitorCreated.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i152.PulseMonitorMembership?>()) {
      return (data != null ? _i152.PulseMonitorMembership.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i153.PulseProbeAllowlistEntry?>()) {
      return (data != null
              ? _i153.PulseProbeAllowlistEntry.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i154.PulseTlsProbe?>()) {
      return (data != null ? _i154.PulseTlsProbe.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i155.PulseValueThreshold?>()) {
      return (data != null ? _i155.PulseValueThreshold.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i156.PushQueueMessage?>()) {
      return (data != null ? _i156.PushQueueMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i157.PushTestJob?>()) {
      return (data != null ? _i157.PushTestJob.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i158.PushTestResult?>()) {
      return (data != null ? _i158.PushTestResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i159.Room?>()) {
      return (data != null ? _i159.Room.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i160.RoomBotCommands?>()) {
      return (data != null ? _i160.RoomBotCommands.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i161.RoomDetails?>()) {
      return (data != null ? _i161.RoomDetails.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i162.RoomListPage?>()) {
      return (data != null ? _i162.RoomListPage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i163.RoomMembership?>()) {
      return (data != null ? _i163.RoomMembership.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i164.RoomParticipant?>()) {
      return (data != null ? _i164.RoomParticipant.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i165.RoomSummary?>()) {
      return (data != null ? _i165.RoomSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i166.RoomTaskStats?>()) {
      return (data != null ? _i166.RoomTaskStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i167.RoomTaskView?>()) {
      return (data != null ? _i167.RoomTaskView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i168.SupportTeam?>()) {
      return (data != null ? _i168.SupportTeam.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i169.SupportTeamExclusion?>()) {
      return (data != null ? _i169.SupportTeamExclusion.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i170.SupportTeamMember?>()) {
      return (data != null ? _i170.SupportTeamMember.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i171.SupportTeamMemberView?>()) {
      return (data != null ? _i171.SupportTeamMemberView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i172.SupportTeamView?>()) {
      return (data != null ? _i172.SupportTeamView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i173.TaskLink?>()) {
      return (data != null ? _i173.TaskLink.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i174.TaskManagerConfig?>()) {
      return (data != null ? _i174.TaskManagerConfig.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i175.Team?>()) {
      return (data != null ? _i175.Team.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i176.TeamMember?>()) {
      return (data != null ? _i176.TeamMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i177.TeamMemberView?>()) {
      return (data != null ? _i177.TeamMemberView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i178.TeamView?>()) {
      return (data != null ? _i178.TeamView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i179.Tenant?>()) {
      return (data != null ? _i179.Tenant.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i180.TenantSupportMember?>()) {
      return (data != null ? _i180.TenantSupportMember.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i181.TenantSupportMemberView?>()) {
      return (data != null
              ? _i181.TenantSupportMemberView.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i182.ThreadReadState?>()) {
      return (data != null ? _i182.ThreadReadState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i183.Ticket?>()) {
      return (data != null ? _i183.Ticket.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i184.TicketEvent?>()) {
      return (data != null ? _i184.TicketEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i185.TicketView?>()) {
      return (data != null ? _i185.TicketView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i186.TrustRedeemResult?>()) {
      return (data != null ? _i186.TrustRedeemResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i187.TrustToken?>()) {
      return (data != null ? _i187.TrustToken.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i188.TrustTokenIssued?>()) {
      return (data != null ? _i188.TrustTokenIssued.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i189.TurnCredentials?>()) {
      return (data != null ? _i189.TurnCredentials.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i190.WebhookDelivery?>()) {
      return (data != null ? _i190.WebhookDelivery.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i191.WebhookEventMessage?>()) {
      return (data != null ? _i191.WebhookEventMessage.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i192.WebhookSubscription?>()) {
      return (data != null ? _i192.WebhookSubscription.fromJson(data) : null)
          as T;
    }
    if (t == List<_i14.BotCommand>) {
      return (data as List).map((e) => deserialize<_i14.BotCommand>(e)).toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i24.ConferenceMember>) {
      return (data as List)
              .map((e) => deserialize<_i24.ConferenceMember>(e))
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
    if (t == List<_i19.CallIceCandidate>) {
      return (data as List)
              .map((e) => deserialize<_i19.CallIceCandidate>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i19.CallIceCandidate>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i19.CallIceCandidate>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == _i1.getType<List<_i24.ConferenceMember>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i24.ConferenceMember>(e))
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
    if (t == List<_i120.MessengerMessage>) {
      return (data as List)
              .map((e) => deserialize<_i120.MessengerMessage>(e))
              .toList()
          as T;
    }
    if (t == List<_i137.ProductNotificationRecipientResult>) {
      return (data as List)
              .map(
                (e) => deserialize<_i137.ProductNotificationRecipientResult>(e),
              )
              .toList()
          as T;
    }
    if (t == List<_i164.RoomParticipant>) {
      return (data as List)
              .map((e) => deserialize<_i164.RoomParticipant>(e))
              .toList()
          as T;
    }
    if (t == List<_i165.RoomSummary>) {
      return (data as List)
              .map((e) => deserialize<_i165.RoomSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i171.SupportTeamMemberView>) {
      return (data as List)
              .map((e) => deserialize<_i171.SupportTeamMemberView>(e))
              .toList()
          as T;
    }
    if (t == List<_i193.WebhookSubscription>) {
      return (data as List)
              .map((e) => deserialize<_i193.WebhookSubscription>(e))
              .toList()
          as T;
    }
    if (t == List<_i194.WebhookDelivery>) {
      return (data as List)
              .map((e) => deserialize<_i194.WebhookDelivery>(e))
              .toList()
          as T;
    }
    if (t == List<_i195.Announcement>) {
      return (data as List)
              .map((e) => deserialize<_i195.Announcement>(e))
              .toList()
          as T;
    }
    if (t == List<_i196.BotAuditEvent>) {
      return (data as List)
              .map((e) => deserialize<_i196.BotAuditEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i197.Bot>) {
      return (data as List).map((e) => deserialize<_i197.Bot>(e)).toList() as T;
    }
    if (t == List<_i198.RoomSummary>) {
      return (data as List)
              .map((e) => deserialize<_i198.RoomSummary>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i199.AvailableBot>) {
      return (data as List)
              .map((e) => deserialize<_i199.AvailableBot>(e))
              .toList()
          as T;
    }
    if (t == List<_i200.BotIntegrationView>) {
      return (data as List)
              .map((e) => deserialize<_i200.BotIntegrationView>(e))
              .toList()
          as T;
    }
    if (t == List<_i201.ConnectTenantStatus>) {
      return (data as List)
              .map((e) => deserialize<_i201.ConnectTenantStatus>(e))
              .toList()
          as T;
    }
    if (t == List<_i202.ProductDeliveryHealth>) {
      return (data as List)
              .map((e) => deserialize<_i202.ProductDeliveryHealth>(e))
              .toList()
          as T;
    }
    if (t == List<_i203.TenantSupportMemberView>) {
      return (data as List)
              .map((e) => deserialize<_i203.TenantSupportMemberView>(e))
              .toList()
          as T;
    }
    if (t == List<_i204.ProductAdminView>) {
      return (data as List)
              .map((e) => deserialize<_i204.ProductAdminView>(e))
              .toList()
          as T;
    }
    if (t == List<_i205.ConnectKeyAuditEvent>) {
      return (data as List)
              .map((e) => deserialize<_i205.ConnectKeyAuditEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i206.TeamView>) {
      return (data as List).map((e) => deserialize<_i206.TeamView>(e)).toList()
          as T;
    }
    if (t == List<_i207.TeamMemberView>) {
      return (data as List)
              .map((e) => deserialize<_i207.TeamMemberView>(e))
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
    if (t == List<_i208.DeviceSessionInfo>) {
      return (data as List)
              .map((e) => deserialize<_i208.DeviceSessionInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i209.IncomingWebhook>) {
      return (data as List)
              .map((e) => deserialize<_i209.IncomingWebhook>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i210.BotCommand>) {
      return (data as List)
              .map((e) => deserialize<_i210.BotCommand>(e))
              .toList()
          as T;
    }
    if (t == List<_i211.RoomBotCommands>) {
      return (data as List)
              .map((e) => deserialize<_i211.RoomBotCommands>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i212.MessengerMessage>) {
      return (data as List)
              .map((e) => deserialize<_i212.MessengerMessage>(e))
              .toList()
          as T;
    }
    if (t == List<_i213.CallIceCandidate>) {
      return (data as List)
              .map((e) => deserialize<_i213.CallIceCandidate>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i213.CallIceCandidate>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i213.CallIceCandidate>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i214.CallHistoryEntry>) {
      return (data as List)
              .map((e) => deserialize<_i214.CallHistoryEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i215.MessengerEvent>) {
      return (data as List)
              .map((e) => deserialize<_i215.MessengerEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i216.LinkPreviewView>) {
      return (data as List)
              .map((e) => deserialize<_i216.LinkPreviewView>(e))
              .toList()
          as T;
    }
    if (t == List<_i217.RoomParticipant>) {
      return (data as List)
              .map((e) => deserialize<_i217.RoomParticipant>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i218.TicketView>) {
      return (data as List)
              .map((e) => deserialize<_i218.TicketView>(e))
              .toList()
          as T;
    }
    if (t == List<_i219.AnnouncementView>) {
      return (data as List)
              .map((e) => deserialize<_i219.AnnouncementView>(e))
              .toList()
          as T;
    }
    if (t == List<_i220.RoomTaskView>) {
      return (data as List)
              .map((e) => deserialize<_i220.RoomTaskView>(e))
              .toList()
          as T;
    }
    if (t == List<_i221.PresenceInfo>) {
      return (data as List)
              .map((e) => deserialize<_i221.PresenceInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i222.ChatFolderView>) {
      return (data as List)
              .map((e) => deserialize<_i222.ChatFolderView>(e))
              .toList()
          as T;
    }
    if (t == List<_i223.ContactRequestView>) {
      return (data as List)
              .map((e) => deserialize<_i223.ContactRequestView>(e))
              .toList()
          as T;
    }
    if (t == List<_i224.ContactLabel>) {
      return (data as List)
              .map((e) => deserialize<_i224.ContactLabel>(e))
              .toList()
          as T;
    }
    if (t == List<_i225.ContactLabelAssignment>) {
      return (data as List)
              .map((e) => deserialize<_i225.ContactLabelAssignment>(e))
              .toList()
          as T;
    }
    if (t == List<_i226.ProductObjectRoom>) {
      return (data as List)
              .map((e) => deserialize<_i226.ProductObjectRoom>(e))
              .toList()
          as T;
    }
    if (t == List<_i227.Product>) {
      return (data as List).map((e) => deserialize<_i227.Product>(e)).toList()
          as T;
    }
    if (t == List<_i228.ProfileTranslation>) {
      return (data as List)
              .map((e) => deserialize<_i228.ProfileTranslation>(e))
              .toList()
          as T;
    }
    if (t == Map<String, int>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<int>(v)),
          )
          as T;
    }
    if (t == List<_i229.PulseFolder>) {
      return (data as List)
              .map((e) => deserialize<_i229.PulseFolder>(e))
              .toList()
          as T;
    }
    if (t == List<_i230.PulseMonitor>) {
      return (data as List)
              .map((e) => deserialize<_i230.PulseMonitor>(e))
              .toList()
          as T;
    }
    if (t == List<_i231.PulseAlertRule>) {
      return (data as List)
              .map((e) => deserialize<_i231.PulseAlertRule>(e))
              .toList()
          as T;
    }
    if (t == List<_i232.PulseIncident>) {
      return (data as List)
              .map((e) => deserialize<_i232.PulseIncident>(e))
              .toList()
          as T;
    }
    if (t == List<_i233.PulseAccessEntry>) {
      return (data as List)
              .map((e) => deserialize<_i233.PulseAccessEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i234.PulseMemberView>) {
      return (data as List)
              .map((e) => deserialize<_i234.PulseMemberView>(e))
              .toList()
          as T;
    }
    if (t == List<_i235.PulseAccessAuditEvent>) {
      return (data as List)
              .map((e) => deserialize<_i235.PulseAccessAuditEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i236.PulseTlsProbe>) {
      return (data as List)
              .map((e) => deserialize<_i236.PulseTlsProbe>(e))
              .toList()
          as T;
    }
    if (t == List<_i237.PulseValueThreshold>) {
      return (data as List)
              .map((e) => deserialize<_i237.PulseValueThreshold>(e))
              .toList()
          as T;
    }
    if (t == List<_i238.PulseProbeAllowlistEntry>) {
      return (data as List)
              .map((e) => deserialize<_i238.PulseProbeAllowlistEntry>(e))
              .toList()
          as T;
    }
    try {
      return _i239.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i240.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.Announcement => 'Announcement',
      _i3.AnnouncementSeen => 'AnnouncementSeen',
      _i4.AnnouncementView => 'AnnouncementView',
      _i5.AttachmentBytes => 'AttachmentBytes',
      _i6.AttachmentObject => 'AttachmentObject',
      _i7.AttachmentPlacement => 'AttachmentPlacement',
      _i8.AttachmentRef => 'AttachmentRef',
      _i9.AttachmentUrl => 'AttachmentUrl',
      _i10.AvailableBot => 'AvailableBot',
      _i11.Bot => 'Bot',
      _i12.BotAuditEvent => 'BotAuditEvent',
      _i13.BotChannelHealth => 'BotChannelHealth',
      _i14.BotCommand => 'BotCommand',
      _i15.BotIntegrationCreated => 'BotIntegrationCreated',
      _i16.BotIntegrationView => 'BotIntegrationView',
      _i17.BotReadModeResult => 'BotReadModeResult',
      _i18.CallHistoryEntry => 'CallHistoryEntry',
      _i19.CallIceCandidate => 'CallIceCandidate',
      _i20.ChatFolderRecord => 'ChatFolderRecord',
      _i21.ChatFolderRoom => 'ChatFolderRoom',
      _i22.ChatFolderView => 'ChatFolderView',
      _i23.Conference => 'Conference',
      _i24.ConferenceMember => 'ConferenceMember',
      _i25.ConferenceParticipant => 'ConferenceParticipant',
      _i26.ConferenceScreenShare => 'ConferenceScreenShare',
      _i27.ConferenceState => 'ConferenceState',
      _i28.ConnectIssuedToken => 'ConnectIssuedToken',
      _i29.ConnectIssuedTokenResult => 'ConnectIssuedTokenResult',
      _i30.ConnectKeyAuditEvent => 'ConnectKeyAuditEvent',
      _i31.ConnectTenantStatus => 'ConnectTenantStatus',
      _i32.ContactBlock => 'ContactBlock',
      _i33.ContactCard => 'ContactCard',
      _i34.ContactCardInfo => 'ContactCardInfo',
      _i35.ContactLabel => 'ContactLabel',
      _i36.ContactLabelAssignment => 'ContactLabelAssignment',
      _i37.ContactLink => 'ContactLink',
      _i38.ContactMeta => 'ContactMeta',
      _i39.ContactProfileView => 'ContactProfileView',
      _i40.ContactRelation => 'ContactRelation',
      _i41.ContactRequest => 'ContactRequest',
      _i42.ContactRequestView => 'ContactRequestView',
      _i43.DeliveryPending => 'DeliveryPending',
      _i44.DeviceRegistration => 'DeviceRegistration',
      _i45.DeviceSessionInfo => 'DeviceSessionInfo',
      _i46.EmailAccount => 'EmailAccount',
      _i47.EmailSession => 'EmailSession',
      _i48.EmailVerificationCode => 'EmailVerificationCode',
      _i49.AttachmentRejectReason => 'AttachmentRejectReason',
      _i50.CallEventType => 'CallEventType',
      _i51.CallStatus => 'CallStatus',
      _i52.ContactLinkSource => 'ContactLinkSource',
      _i53.ContactRequestStatus => 'ContactRequestStatus',
      _i54.DevicePlatform => 'DevicePlatform',
      _i55.IdentityProvider => 'IdentityProvider',
      _i56.MessengerEventType => 'MessengerEventType',
      _i57.ParticipantKind => 'ParticipantKind',
      _i58.ProductNotificationStatus => 'ProductNotificationStatus',
      _i59.PushService => 'PushService',
      _i60.RoomMemberRole => 'RoomMemberRole',
      _i61.RoomOwnership => 'RoomOwnership',
      _i62.RoomState => 'RoomState',
      _i63.RoomType => 'RoomType',
      _i64.SupportTeamRole => 'SupportTeamRole',
      _i65.TeamKind => 'TeamKind',
      _i66.TeamMemberRole => 'TeamMemberRole',
      _i67.TenantHostingMode => 'TenantHostingMode',
      _i68.TrustTokenKind => 'TrustTokenKind',
      _i69.AdapterNotConfiguredException => 'AdapterNotConfiguredException',
      _i70.AmbiguousProductKeyException => 'AmbiguousProductKeyException',
      _i71.AttachmentAccessDeniedException => 'AttachmentAccessDeniedException',
      _i72.AttachmentRejectedException => 'AttachmentRejectedException',
      _i73.BotCapabilityException => 'BotCapabilityException',
      _i74.BotLimitExceededException => 'BotLimitExceededException',
      _i75.BotNotFoundException => 'BotNotFoundException',
      _i76.BotReadRestrictedException => 'BotReadRestrictedException',
      _i77.ConferenceFullException => 'ConferenceFullException',
      _i78.EmailAuthException => 'EmailAuthException',
      _i79.InsufficientPowerException => 'InsufficientPowerException',
      _i80.InvalidBotCommandsException => 'InvalidBotCommandsException',
      _i81.InvalidExternalKeyException => 'InvalidExternalKeyException',
      _i82.InvalidNotificationException => 'InvalidNotificationException',
      _i83.InvalidTokenException => 'InvalidTokenException',
      _i84.LastOwnerCannotDemoteException => 'LastOwnerCannotDemoteException',
      _i85.MessageBodyTooLargeException => 'MessageBodyTooLargeException',
      _i86.MessageDeletedException => 'MessageDeletedException',
      _i87.MessageNotEditableException => 'MessageNotEditableException',
      _i88.MessengerNotAuthenticatedException =>
        'MessengerNotAuthenticatedException',
      _i89.NotObjectRoomException => 'NotObjectRoomException',
      _i90.NotSupportTeamMemberException => 'NotSupportTeamMemberException',
      _i91.NotSupportTeamOwnerException => 'NotSupportTeamOwnerException',
      _i92.OperatorEmailNotResolvedException =>
        'OperatorEmailNotResolvedException',
      _i93.PeerUnavailableException => 'PeerUnavailableException',
      _i94.ProbeTargetNotAllowedException => 'ProbeTargetNotAllowedException',
      _i95.ProductAlreadyExistsException => 'ProductAlreadyExistsException',
      _i96.ProductInUseException => 'ProductInUseException',
      _i97.ProductNotFoundException => 'ProductNotFoundException',
      _i98.ProductNotFoundForCallerException =>
        'ProductNotFoundForCallerException',
      _i99.RateLimitExceededException => 'RateLimitExceededException',
      _i100.RoomDissolvePartialException => 'RoomDissolvePartialException',
      _i101.RoomUnavailableException => 'RoomUnavailableException',
      _i102.ScreenShareBusyException => 'ScreenShareBusyException',
      _i103.TaskIntegrationNotConfiguredException =>
        'TaskIntegrationNotConfiguredException',
      _i104.TeamAccessDeniedException => 'TeamAccessDeniedException',
      _i105.TeamPeerUnknownException => 'TeamPeerUnknownException',
      _i106.TenantAlreadyExistsException => 'TenantAlreadyExistsException',
      _i107.TenantNotFoundException => 'TenantNotFoundException',
      _i108.ThumbnailUnavailableException => 'ThumbnailUnavailableException',
      _i109.WriteBannedException => 'WriteBannedException',
      _i110.EscalationResult => 'EscalationResult',
      _i111.Greeting => 'Greeting',
      _i112.IdentityMapping => 'IdentityMapping',
      _i113.IncomingWebhook => 'IncomingWebhook',
      _i114.IncomingWebhookCreated => 'IncomingWebhookCreated',
      _i115.LinkPreview => 'LinkPreview',
      _i116.LinkPreviewView => 'LinkPreviewView',
      _i117.MessageIndex => 'MessageIndex',
      _i118.MessengerAuthContext => 'MessengerAuthContext',
      _i119.MessengerEvent => 'MessengerEvent',
      _i120.MessengerMessage => 'MessengerMessage',
      _i121.MessengerMessageListPage => 'MessengerMessageListPage',
      _i122.MessengerSession => 'MessengerSession',
      _i123.MessengerSessionToken => 'MessengerSessionToken',
      _i124.MessengerUser => 'MessengerUser',
      _i125.NearbyConfirmResult => 'NearbyConfirmResult',
      _i126.NearbyConfirmation => 'NearbyConfirmation',
      _i127.NotificationSettings => 'NotificationSettings',
      _i128.PresenceConnState => 'PresenceConnState',
      _i129.PresenceInfo => 'PresenceInfo',
      _i130.PresenceState => 'PresenceState',
      _i131.PresenceWatchedIndex => 'PresenceWatchedIndex',
      _i132.PresenceWatchers => 'PresenceWatchers',
      _i133.Product => 'Product',
      _i134.ProductAdminView => 'ProductAdminView',
      _i135.ProductDeliveryHealth => 'ProductDeliveryHealth',
      _i136.ProductNotification => 'ProductNotification',
      _i137.ProductNotificationRecipientResult =>
        'ProductNotificationRecipientResult',
      _i138.ProductNotificationSendResult => 'ProductNotificationSendResult',
      _i139.ProductObjectRoom => 'ProductObjectRoom',
      _i140.ProfileTranslation => 'ProfileTranslation',
      _i141.PulseAccessAuditEvent => 'PulseAccessAuditEvent',
      _i142.PulseAccessEntry => 'PulseAccessEntry',
      _i143.PulseAlertRule => 'PulseAlertRule',
      _i144.PulseEvent => 'PulseEvent',
      _i145.PulseExpiryReminder => 'PulseExpiryReminder',
      _i146.PulseFolder => 'PulseFolder',
      _i147.PulseFolderMembership => 'PulseFolderMembership',
      _i148.PulseIncident => 'PulseIncident',
      _i149.PulseMemberView => 'PulseMemberView',
      _i150.PulseMonitor => 'PulseMonitor',
      _i151.PulseMonitorCreated => 'PulseMonitorCreated',
      _i152.PulseMonitorMembership => 'PulseMonitorMembership',
      _i153.PulseProbeAllowlistEntry => 'PulseProbeAllowlistEntry',
      _i154.PulseTlsProbe => 'PulseTlsProbe',
      _i155.PulseValueThreshold => 'PulseValueThreshold',
      _i156.PushQueueMessage => 'PushQueueMessage',
      _i157.PushTestJob => 'PushTestJob',
      _i158.PushTestResult => 'PushTestResult',
      _i159.Room => 'Room',
      _i160.RoomBotCommands => 'RoomBotCommands',
      _i161.RoomDetails => 'RoomDetails',
      _i162.RoomListPage => 'RoomListPage',
      _i163.RoomMembership => 'RoomMembership',
      _i164.RoomParticipant => 'RoomParticipant',
      _i165.RoomSummary => 'RoomSummary',
      _i166.RoomTaskStats => 'RoomTaskStats',
      _i167.RoomTaskView => 'RoomTaskView',
      _i168.SupportTeam => 'SupportTeam',
      _i169.SupportTeamExclusion => 'SupportTeamExclusion',
      _i170.SupportTeamMember => 'SupportTeamMember',
      _i171.SupportTeamMemberView => 'SupportTeamMemberView',
      _i172.SupportTeamView => 'SupportTeamView',
      _i173.TaskLink => 'TaskLink',
      _i174.TaskManagerConfig => 'TaskManagerConfig',
      _i175.Team => 'Team',
      _i176.TeamMember => 'TeamMember',
      _i177.TeamMemberView => 'TeamMemberView',
      _i178.TeamView => 'TeamView',
      _i179.Tenant => 'Tenant',
      _i180.TenantSupportMember => 'TenantSupportMember',
      _i181.TenantSupportMemberView => 'TenantSupportMemberView',
      _i182.ThreadReadState => 'ThreadReadState',
      _i183.Ticket => 'Ticket',
      _i184.TicketEvent => 'TicketEvent',
      _i185.TicketView => 'TicketView',
      _i186.TrustRedeemResult => 'TrustRedeemResult',
      _i187.TrustToken => 'TrustToken',
      _i188.TrustTokenIssued => 'TrustTokenIssued',
      _i189.TurnCredentials => 'TurnCredentials',
      _i190.WebhookDelivery => 'WebhookDelivery',
      _i191.WebhookEventMessage => 'WebhookEventMessage',
      _i192.WebhookSubscription => 'WebhookSubscription',
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
      case _i2.Announcement():
        return 'Announcement';
      case _i3.AnnouncementSeen():
        return 'AnnouncementSeen';
      case _i4.AnnouncementView():
        return 'AnnouncementView';
      case _i5.AttachmentBytes():
        return 'AttachmentBytes';
      case _i6.AttachmentObject():
        return 'AttachmentObject';
      case _i7.AttachmentPlacement():
        return 'AttachmentPlacement';
      case _i8.AttachmentRef():
        return 'AttachmentRef';
      case _i9.AttachmentUrl():
        return 'AttachmentUrl';
      case _i10.AvailableBot():
        return 'AvailableBot';
      case _i11.Bot():
        return 'Bot';
      case _i12.BotAuditEvent():
        return 'BotAuditEvent';
      case _i13.BotChannelHealth():
        return 'BotChannelHealth';
      case _i14.BotCommand():
        return 'BotCommand';
      case _i15.BotIntegrationCreated():
        return 'BotIntegrationCreated';
      case _i16.BotIntegrationView():
        return 'BotIntegrationView';
      case _i17.BotReadModeResult():
        return 'BotReadModeResult';
      case _i18.CallHistoryEntry():
        return 'CallHistoryEntry';
      case _i19.CallIceCandidate():
        return 'CallIceCandidate';
      case _i20.ChatFolderRecord():
        return 'ChatFolderRecord';
      case _i21.ChatFolderRoom():
        return 'ChatFolderRoom';
      case _i22.ChatFolderView():
        return 'ChatFolderView';
      case _i23.Conference():
        return 'Conference';
      case _i24.ConferenceMember():
        return 'ConferenceMember';
      case _i25.ConferenceParticipant():
        return 'ConferenceParticipant';
      case _i26.ConferenceScreenShare():
        return 'ConferenceScreenShare';
      case _i27.ConferenceState():
        return 'ConferenceState';
      case _i28.ConnectIssuedToken():
        return 'ConnectIssuedToken';
      case _i29.ConnectIssuedTokenResult():
        return 'ConnectIssuedTokenResult';
      case _i30.ConnectKeyAuditEvent():
        return 'ConnectKeyAuditEvent';
      case _i31.ConnectTenantStatus():
        return 'ConnectTenantStatus';
      case _i32.ContactBlock():
        return 'ContactBlock';
      case _i33.ContactCard():
        return 'ContactCard';
      case _i34.ContactCardInfo():
        return 'ContactCardInfo';
      case _i35.ContactLabel():
        return 'ContactLabel';
      case _i36.ContactLabelAssignment():
        return 'ContactLabelAssignment';
      case _i37.ContactLink():
        return 'ContactLink';
      case _i38.ContactMeta():
        return 'ContactMeta';
      case _i39.ContactProfileView():
        return 'ContactProfileView';
      case _i40.ContactRelation():
        return 'ContactRelation';
      case _i41.ContactRequest():
        return 'ContactRequest';
      case _i42.ContactRequestView():
        return 'ContactRequestView';
      case _i43.DeliveryPending():
        return 'DeliveryPending';
      case _i44.DeviceRegistration():
        return 'DeviceRegistration';
      case _i45.DeviceSessionInfo():
        return 'DeviceSessionInfo';
      case _i46.EmailAccount():
        return 'EmailAccount';
      case _i47.EmailSession():
        return 'EmailSession';
      case _i48.EmailVerificationCode():
        return 'EmailVerificationCode';
      case _i49.AttachmentRejectReason():
        return 'AttachmentRejectReason';
      case _i50.CallEventType():
        return 'CallEventType';
      case _i51.CallStatus():
        return 'CallStatus';
      case _i52.ContactLinkSource():
        return 'ContactLinkSource';
      case _i53.ContactRequestStatus():
        return 'ContactRequestStatus';
      case _i54.DevicePlatform():
        return 'DevicePlatform';
      case _i55.IdentityProvider():
        return 'IdentityProvider';
      case _i56.MessengerEventType():
        return 'MessengerEventType';
      case _i57.ParticipantKind():
        return 'ParticipantKind';
      case _i58.ProductNotificationStatus():
        return 'ProductNotificationStatus';
      case _i59.PushService():
        return 'PushService';
      case _i60.RoomMemberRole():
        return 'RoomMemberRole';
      case _i61.RoomOwnership():
        return 'RoomOwnership';
      case _i62.RoomState():
        return 'RoomState';
      case _i63.RoomType():
        return 'RoomType';
      case _i64.SupportTeamRole():
        return 'SupportTeamRole';
      case _i65.TeamKind():
        return 'TeamKind';
      case _i66.TeamMemberRole():
        return 'TeamMemberRole';
      case _i67.TenantHostingMode():
        return 'TenantHostingMode';
      case _i68.TrustTokenKind():
        return 'TrustTokenKind';
      case _i69.AdapterNotConfiguredException():
        return 'AdapterNotConfiguredException';
      case _i70.AmbiguousProductKeyException():
        return 'AmbiguousProductKeyException';
      case _i71.AttachmentAccessDeniedException():
        return 'AttachmentAccessDeniedException';
      case _i72.AttachmentRejectedException():
        return 'AttachmentRejectedException';
      case _i73.BotCapabilityException():
        return 'BotCapabilityException';
      case _i74.BotLimitExceededException():
        return 'BotLimitExceededException';
      case _i75.BotNotFoundException():
        return 'BotNotFoundException';
      case _i76.BotReadRestrictedException():
        return 'BotReadRestrictedException';
      case _i77.ConferenceFullException():
        return 'ConferenceFullException';
      case _i78.EmailAuthException():
        return 'EmailAuthException';
      case _i79.InsufficientPowerException():
        return 'InsufficientPowerException';
      case _i80.InvalidBotCommandsException():
        return 'InvalidBotCommandsException';
      case _i81.InvalidExternalKeyException():
        return 'InvalidExternalKeyException';
      case _i82.InvalidNotificationException():
        return 'InvalidNotificationException';
      case _i83.InvalidTokenException():
        return 'InvalidTokenException';
      case _i84.LastOwnerCannotDemoteException():
        return 'LastOwnerCannotDemoteException';
      case _i85.MessageBodyTooLargeException():
        return 'MessageBodyTooLargeException';
      case _i86.MessageDeletedException():
        return 'MessageDeletedException';
      case _i87.MessageNotEditableException():
        return 'MessageNotEditableException';
      case _i88.MessengerNotAuthenticatedException():
        return 'MessengerNotAuthenticatedException';
      case _i89.NotObjectRoomException():
        return 'NotObjectRoomException';
      case _i90.NotSupportTeamMemberException():
        return 'NotSupportTeamMemberException';
      case _i91.NotSupportTeamOwnerException():
        return 'NotSupportTeamOwnerException';
      case _i92.OperatorEmailNotResolvedException():
        return 'OperatorEmailNotResolvedException';
      case _i93.PeerUnavailableException():
        return 'PeerUnavailableException';
      case _i94.ProbeTargetNotAllowedException():
        return 'ProbeTargetNotAllowedException';
      case _i95.ProductAlreadyExistsException():
        return 'ProductAlreadyExistsException';
      case _i96.ProductInUseException():
        return 'ProductInUseException';
      case _i97.ProductNotFoundException():
        return 'ProductNotFoundException';
      case _i98.ProductNotFoundForCallerException():
        return 'ProductNotFoundForCallerException';
      case _i99.RateLimitExceededException():
        return 'RateLimitExceededException';
      case _i100.RoomDissolvePartialException():
        return 'RoomDissolvePartialException';
      case _i101.RoomUnavailableException():
        return 'RoomUnavailableException';
      case _i102.ScreenShareBusyException():
        return 'ScreenShareBusyException';
      case _i103.TaskIntegrationNotConfiguredException():
        return 'TaskIntegrationNotConfiguredException';
      case _i104.TeamAccessDeniedException():
        return 'TeamAccessDeniedException';
      case _i105.TeamPeerUnknownException():
        return 'TeamPeerUnknownException';
      case _i106.TenantAlreadyExistsException():
        return 'TenantAlreadyExistsException';
      case _i107.TenantNotFoundException():
        return 'TenantNotFoundException';
      case _i108.ThumbnailUnavailableException():
        return 'ThumbnailUnavailableException';
      case _i109.WriteBannedException():
        return 'WriteBannedException';
      case _i110.EscalationResult():
        return 'EscalationResult';
      case _i111.Greeting():
        return 'Greeting';
      case _i112.IdentityMapping():
        return 'IdentityMapping';
      case _i113.IncomingWebhook():
        return 'IncomingWebhook';
      case _i114.IncomingWebhookCreated():
        return 'IncomingWebhookCreated';
      case _i115.LinkPreview():
        return 'LinkPreview';
      case _i116.LinkPreviewView():
        return 'LinkPreviewView';
      case _i117.MessageIndex():
        return 'MessageIndex';
      case _i118.MessengerAuthContext():
        return 'MessengerAuthContext';
      case _i119.MessengerEvent():
        return 'MessengerEvent';
      case _i120.MessengerMessage():
        return 'MessengerMessage';
      case _i121.MessengerMessageListPage():
        return 'MessengerMessageListPage';
      case _i122.MessengerSession():
        return 'MessengerSession';
      case _i123.MessengerSessionToken():
        return 'MessengerSessionToken';
      case _i124.MessengerUser():
        return 'MessengerUser';
      case _i125.NearbyConfirmResult():
        return 'NearbyConfirmResult';
      case _i126.NearbyConfirmation():
        return 'NearbyConfirmation';
      case _i127.NotificationSettings():
        return 'NotificationSettings';
      case _i128.PresenceConnState():
        return 'PresenceConnState';
      case _i129.PresenceInfo():
        return 'PresenceInfo';
      case _i130.PresenceState():
        return 'PresenceState';
      case _i131.PresenceWatchedIndex():
        return 'PresenceWatchedIndex';
      case _i132.PresenceWatchers():
        return 'PresenceWatchers';
      case _i133.Product():
        return 'Product';
      case _i134.ProductAdminView():
        return 'ProductAdminView';
      case _i135.ProductDeliveryHealth():
        return 'ProductDeliveryHealth';
      case _i136.ProductNotification():
        return 'ProductNotification';
      case _i137.ProductNotificationRecipientResult():
        return 'ProductNotificationRecipientResult';
      case _i138.ProductNotificationSendResult():
        return 'ProductNotificationSendResult';
      case _i139.ProductObjectRoom():
        return 'ProductObjectRoom';
      case _i140.ProfileTranslation():
        return 'ProfileTranslation';
      case _i141.PulseAccessAuditEvent():
        return 'PulseAccessAuditEvent';
      case _i142.PulseAccessEntry():
        return 'PulseAccessEntry';
      case _i143.PulseAlertRule():
        return 'PulseAlertRule';
      case _i144.PulseEvent():
        return 'PulseEvent';
      case _i145.PulseExpiryReminder():
        return 'PulseExpiryReminder';
      case _i146.PulseFolder():
        return 'PulseFolder';
      case _i147.PulseFolderMembership():
        return 'PulseFolderMembership';
      case _i148.PulseIncident():
        return 'PulseIncident';
      case _i149.PulseMemberView():
        return 'PulseMemberView';
      case _i150.PulseMonitor():
        return 'PulseMonitor';
      case _i151.PulseMonitorCreated():
        return 'PulseMonitorCreated';
      case _i152.PulseMonitorMembership():
        return 'PulseMonitorMembership';
      case _i153.PulseProbeAllowlistEntry():
        return 'PulseProbeAllowlistEntry';
      case _i154.PulseTlsProbe():
        return 'PulseTlsProbe';
      case _i155.PulseValueThreshold():
        return 'PulseValueThreshold';
      case _i156.PushQueueMessage():
        return 'PushQueueMessage';
      case _i157.PushTestJob():
        return 'PushTestJob';
      case _i158.PushTestResult():
        return 'PushTestResult';
      case _i159.Room():
        return 'Room';
      case _i160.RoomBotCommands():
        return 'RoomBotCommands';
      case _i161.RoomDetails():
        return 'RoomDetails';
      case _i162.RoomListPage():
        return 'RoomListPage';
      case _i163.RoomMembership():
        return 'RoomMembership';
      case _i164.RoomParticipant():
        return 'RoomParticipant';
      case _i165.RoomSummary():
        return 'RoomSummary';
      case _i166.RoomTaskStats():
        return 'RoomTaskStats';
      case _i167.RoomTaskView():
        return 'RoomTaskView';
      case _i168.SupportTeam():
        return 'SupportTeam';
      case _i169.SupportTeamExclusion():
        return 'SupportTeamExclusion';
      case _i170.SupportTeamMember():
        return 'SupportTeamMember';
      case _i171.SupportTeamMemberView():
        return 'SupportTeamMemberView';
      case _i172.SupportTeamView():
        return 'SupportTeamView';
      case _i173.TaskLink():
        return 'TaskLink';
      case _i174.TaskManagerConfig():
        return 'TaskManagerConfig';
      case _i175.Team():
        return 'Team';
      case _i176.TeamMember():
        return 'TeamMember';
      case _i177.TeamMemberView():
        return 'TeamMemberView';
      case _i178.TeamView():
        return 'TeamView';
      case _i179.Tenant():
        return 'Tenant';
      case _i180.TenantSupportMember():
        return 'TenantSupportMember';
      case _i181.TenantSupportMemberView():
        return 'TenantSupportMemberView';
      case _i182.ThreadReadState():
        return 'ThreadReadState';
      case _i183.Ticket():
        return 'Ticket';
      case _i184.TicketEvent():
        return 'TicketEvent';
      case _i185.TicketView():
        return 'TicketView';
      case _i186.TrustRedeemResult():
        return 'TrustRedeemResult';
      case _i187.TrustToken():
        return 'TrustToken';
      case _i188.TrustTokenIssued():
        return 'TrustTokenIssued';
      case _i189.TurnCredentials():
        return 'TurnCredentials';
      case _i190.WebhookDelivery():
        return 'WebhookDelivery';
      case _i191.WebhookEventMessage():
        return 'WebhookEventMessage';
      case _i192.WebhookSubscription():
        return 'WebhookSubscription';
    }
    className = _i239.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i240.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'Announcement') {
      return deserialize<_i2.Announcement>(data['data']);
    }
    if (dataClassName == 'AnnouncementSeen') {
      return deserialize<_i3.AnnouncementSeen>(data['data']);
    }
    if (dataClassName == 'AnnouncementView') {
      return deserialize<_i4.AnnouncementView>(data['data']);
    }
    if (dataClassName == 'AttachmentBytes') {
      return deserialize<_i5.AttachmentBytes>(data['data']);
    }
    if (dataClassName == 'AttachmentObject') {
      return deserialize<_i6.AttachmentObject>(data['data']);
    }
    if (dataClassName == 'AttachmentPlacement') {
      return deserialize<_i7.AttachmentPlacement>(data['data']);
    }
    if (dataClassName == 'AttachmentRef') {
      return deserialize<_i8.AttachmentRef>(data['data']);
    }
    if (dataClassName == 'AttachmentUrl') {
      return deserialize<_i9.AttachmentUrl>(data['data']);
    }
    if (dataClassName == 'AvailableBot') {
      return deserialize<_i10.AvailableBot>(data['data']);
    }
    if (dataClassName == 'Bot') {
      return deserialize<_i11.Bot>(data['data']);
    }
    if (dataClassName == 'BotAuditEvent') {
      return deserialize<_i12.BotAuditEvent>(data['data']);
    }
    if (dataClassName == 'BotChannelHealth') {
      return deserialize<_i13.BotChannelHealth>(data['data']);
    }
    if (dataClassName == 'BotCommand') {
      return deserialize<_i14.BotCommand>(data['data']);
    }
    if (dataClassName == 'BotIntegrationCreated') {
      return deserialize<_i15.BotIntegrationCreated>(data['data']);
    }
    if (dataClassName == 'BotIntegrationView') {
      return deserialize<_i16.BotIntegrationView>(data['data']);
    }
    if (dataClassName == 'BotReadModeResult') {
      return deserialize<_i17.BotReadModeResult>(data['data']);
    }
    if (dataClassName == 'CallHistoryEntry') {
      return deserialize<_i18.CallHistoryEntry>(data['data']);
    }
    if (dataClassName == 'CallIceCandidate') {
      return deserialize<_i19.CallIceCandidate>(data['data']);
    }
    if (dataClassName == 'ChatFolderRecord') {
      return deserialize<_i20.ChatFolderRecord>(data['data']);
    }
    if (dataClassName == 'ChatFolderRoom') {
      return deserialize<_i21.ChatFolderRoom>(data['data']);
    }
    if (dataClassName == 'ChatFolderView') {
      return deserialize<_i22.ChatFolderView>(data['data']);
    }
    if (dataClassName == 'Conference') {
      return deserialize<_i23.Conference>(data['data']);
    }
    if (dataClassName == 'ConferenceMember') {
      return deserialize<_i24.ConferenceMember>(data['data']);
    }
    if (dataClassName == 'ConferenceParticipant') {
      return deserialize<_i25.ConferenceParticipant>(data['data']);
    }
    if (dataClassName == 'ConferenceScreenShare') {
      return deserialize<_i26.ConferenceScreenShare>(data['data']);
    }
    if (dataClassName == 'ConferenceState') {
      return deserialize<_i27.ConferenceState>(data['data']);
    }
    if (dataClassName == 'ConnectIssuedToken') {
      return deserialize<_i28.ConnectIssuedToken>(data['data']);
    }
    if (dataClassName == 'ConnectIssuedTokenResult') {
      return deserialize<_i29.ConnectIssuedTokenResult>(data['data']);
    }
    if (dataClassName == 'ConnectKeyAuditEvent') {
      return deserialize<_i30.ConnectKeyAuditEvent>(data['data']);
    }
    if (dataClassName == 'ConnectTenantStatus') {
      return deserialize<_i31.ConnectTenantStatus>(data['data']);
    }
    if (dataClassName == 'ContactBlock') {
      return deserialize<_i32.ContactBlock>(data['data']);
    }
    if (dataClassName == 'ContactCard') {
      return deserialize<_i33.ContactCard>(data['data']);
    }
    if (dataClassName == 'ContactCardInfo') {
      return deserialize<_i34.ContactCardInfo>(data['data']);
    }
    if (dataClassName == 'ContactLabel') {
      return deserialize<_i35.ContactLabel>(data['data']);
    }
    if (dataClassName == 'ContactLabelAssignment') {
      return deserialize<_i36.ContactLabelAssignment>(data['data']);
    }
    if (dataClassName == 'ContactLink') {
      return deserialize<_i37.ContactLink>(data['data']);
    }
    if (dataClassName == 'ContactMeta') {
      return deserialize<_i38.ContactMeta>(data['data']);
    }
    if (dataClassName == 'ContactProfileView') {
      return deserialize<_i39.ContactProfileView>(data['data']);
    }
    if (dataClassName == 'ContactRelation') {
      return deserialize<_i40.ContactRelation>(data['data']);
    }
    if (dataClassName == 'ContactRequest') {
      return deserialize<_i41.ContactRequest>(data['data']);
    }
    if (dataClassName == 'ContactRequestView') {
      return deserialize<_i42.ContactRequestView>(data['data']);
    }
    if (dataClassName == 'DeliveryPending') {
      return deserialize<_i43.DeliveryPending>(data['data']);
    }
    if (dataClassName == 'DeviceRegistration') {
      return deserialize<_i44.DeviceRegistration>(data['data']);
    }
    if (dataClassName == 'DeviceSessionInfo') {
      return deserialize<_i45.DeviceSessionInfo>(data['data']);
    }
    if (dataClassName == 'EmailAccount') {
      return deserialize<_i46.EmailAccount>(data['data']);
    }
    if (dataClassName == 'EmailSession') {
      return deserialize<_i47.EmailSession>(data['data']);
    }
    if (dataClassName == 'EmailVerificationCode') {
      return deserialize<_i48.EmailVerificationCode>(data['data']);
    }
    if (dataClassName == 'AttachmentRejectReason') {
      return deserialize<_i49.AttachmentRejectReason>(data['data']);
    }
    if (dataClassName == 'CallEventType') {
      return deserialize<_i50.CallEventType>(data['data']);
    }
    if (dataClassName == 'CallStatus') {
      return deserialize<_i51.CallStatus>(data['data']);
    }
    if (dataClassName == 'ContactLinkSource') {
      return deserialize<_i52.ContactLinkSource>(data['data']);
    }
    if (dataClassName == 'ContactRequestStatus') {
      return deserialize<_i53.ContactRequestStatus>(data['data']);
    }
    if (dataClassName == 'DevicePlatform') {
      return deserialize<_i54.DevicePlatform>(data['data']);
    }
    if (dataClassName == 'IdentityProvider') {
      return deserialize<_i55.IdentityProvider>(data['data']);
    }
    if (dataClassName == 'MessengerEventType') {
      return deserialize<_i56.MessengerEventType>(data['data']);
    }
    if (dataClassName == 'ParticipantKind') {
      return deserialize<_i57.ParticipantKind>(data['data']);
    }
    if (dataClassName == 'ProductNotificationStatus') {
      return deserialize<_i58.ProductNotificationStatus>(data['data']);
    }
    if (dataClassName == 'PushService') {
      return deserialize<_i59.PushService>(data['data']);
    }
    if (dataClassName == 'RoomMemberRole') {
      return deserialize<_i60.RoomMemberRole>(data['data']);
    }
    if (dataClassName == 'RoomOwnership') {
      return deserialize<_i61.RoomOwnership>(data['data']);
    }
    if (dataClassName == 'RoomState') {
      return deserialize<_i62.RoomState>(data['data']);
    }
    if (dataClassName == 'RoomType') {
      return deserialize<_i63.RoomType>(data['data']);
    }
    if (dataClassName == 'SupportTeamRole') {
      return deserialize<_i64.SupportTeamRole>(data['data']);
    }
    if (dataClassName == 'TeamKind') {
      return deserialize<_i65.TeamKind>(data['data']);
    }
    if (dataClassName == 'TeamMemberRole') {
      return deserialize<_i66.TeamMemberRole>(data['data']);
    }
    if (dataClassName == 'TenantHostingMode') {
      return deserialize<_i67.TenantHostingMode>(data['data']);
    }
    if (dataClassName == 'TrustTokenKind') {
      return deserialize<_i68.TrustTokenKind>(data['data']);
    }
    if (dataClassName == 'AdapterNotConfiguredException') {
      return deserialize<_i69.AdapterNotConfiguredException>(data['data']);
    }
    if (dataClassName == 'AmbiguousProductKeyException') {
      return deserialize<_i70.AmbiguousProductKeyException>(data['data']);
    }
    if (dataClassName == 'AttachmentAccessDeniedException') {
      return deserialize<_i71.AttachmentAccessDeniedException>(data['data']);
    }
    if (dataClassName == 'AttachmentRejectedException') {
      return deserialize<_i72.AttachmentRejectedException>(data['data']);
    }
    if (dataClassName == 'BotCapabilityException') {
      return deserialize<_i73.BotCapabilityException>(data['data']);
    }
    if (dataClassName == 'BotLimitExceededException') {
      return deserialize<_i74.BotLimitExceededException>(data['data']);
    }
    if (dataClassName == 'BotNotFoundException') {
      return deserialize<_i75.BotNotFoundException>(data['data']);
    }
    if (dataClassName == 'BotReadRestrictedException') {
      return deserialize<_i76.BotReadRestrictedException>(data['data']);
    }
    if (dataClassName == 'ConferenceFullException') {
      return deserialize<_i77.ConferenceFullException>(data['data']);
    }
    if (dataClassName == 'EmailAuthException') {
      return deserialize<_i78.EmailAuthException>(data['data']);
    }
    if (dataClassName == 'InsufficientPowerException') {
      return deserialize<_i79.InsufficientPowerException>(data['data']);
    }
    if (dataClassName == 'InvalidBotCommandsException') {
      return deserialize<_i80.InvalidBotCommandsException>(data['data']);
    }
    if (dataClassName == 'InvalidExternalKeyException') {
      return deserialize<_i81.InvalidExternalKeyException>(data['data']);
    }
    if (dataClassName == 'InvalidNotificationException') {
      return deserialize<_i82.InvalidNotificationException>(data['data']);
    }
    if (dataClassName == 'InvalidTokenException') {
      return deserialize<_i83.InvalidTokenException>(data['data']);
    }
    if (dataClassName == 'LastOwnerCannotDemoteException') {
      return deserialize<_i84.LastOwnerCannotDemoteException>(data['data']);
    }
    if (dataClassName == 'MessageBodyTooLargeException') {
      return deserialize<_i85.MessageBodyTooLargeException>(data['data']);
    }
    if (dataClassName == 'MessageDeletedException') {
      return deserialize<_i86.MessageDeletedException>(data['data']);
    }
    if (dataClassName == 'MessageNotEditableException') {
      return deserialize<_i87.MessageNotEditableException>(data['data']);
    }
    if (dataClassName == 'MessengerNotAuthenticatedException') {
      return deserialize<_i88.MessengerNotAuthenticatedException>(data['data']);
    }
    if (dataClassName == 'NotObjectRoomException') {
      return deserialize<_i89.NotObjectRoomException>(data['data']);
    }
    if (dataClassName == 'NotSupportTeamMemberException') {
      return deserialize<_i90.NotSupportTeamMemberException>(data['data']);
    }
    if (dataClassName == 'NotSupportTeamOwnerException') {
      return deserialize<_i91.NotSupportTeamOwnerException>(data['data']);
    }
    if (dataClassName == 'OperatorEmailNotResolvedException') {
      return deserialize<_i92.OperatorEmailNotResolvedException>(data['data']);
    }
    if (dataClassName == 'PeerUnavailableException') {
      return deserialize<_i93.PeerUnavailableException>(data['data']);
    }
    if (dataClassName == 'ProbeTargetNotAllowedException') {
      return deserialize<_i94.ProbeTargetNotAllowedException>(data['data']);
    }
    if (dataClassName == 'ProductAlreadyExistsException') {
      return deserialize<_i95.ProductAlreadyExistsException>(data['data']);
    }
    if (dataClassName == 'ProductInUseException') {
      return deserialize<_i96.ProductInUseException>(data['data']);
    }
    if (dataClassName == 'ProductNotFoundException') {
      return deserialize<_i97.ProductNotFoundException>(data['data']);
    }
    if (dataClassName == 'ProductNotFoundForCallerException') {
      return deserialize<_i98.ProductNotFoundForCallerException>(data['data']);
    }
    if (dataClassName == 'RateLimitExceededException') {
      return deserialize<_i99.RateLimitExceededException>(data['data']);
    }
    if (dataClassName == 'RoomDissolvePartialException') {
      return deserialize<_i100.RoomDissolvePartialException>(data['data']);
    }
    if (dataClassName == 'RoomUnavailableException') {
      return deserialize<_i101.RoomUnavailableException>(data['data']);
    }
    if (dataClassName == 'ScreenShareBusyException') {
      return deserialize<_i102.ScreenShareBusyException>(data['data']);
    }
    if (dataClassName == 'TaskIntegrationNotConfiguredException') {
      return deserialize<_i103.TaskIntegrationNotConfiguredException>(
        data['data'],
      );
    }
    if (dataClassName == 'TeamAccessDeniedException') {
      return deserialize<_i104.TeamAccessDeniedException>(data['data']);
    }
    if (dataClassName == 'TeamPeerUnknownException') {
      return deserialize<_i105.TeamPeerUnknownException>(data['data']);
    }
    if (dataClassName == 'TenantAlreadyExistsException') {
      return deserialize<_i106.TenantAlreadyExistsException>(data['data']);
    }
    if (dataClassName == 'TenantNotFoundException') {
      return deserialize<_i107.TenantNotFoundException>(data['data']);
    }
    if (dataClassName == 'ThumbnailUnavailableException') {
      return deserialize<_i108.ThumbnailUnavailableException>(data['data']);
    }
    if (dataClassName == 'WriteBannedException') {
      return deserialize<_i109.WriteBannedException>(data['data']);
    }
    if (dataClassName == 'EscalationResult') {
      return deserialize<_i110.EscalationResult>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i111.Greeting>(data['data']);
    }
    if (dataClassName == 'IdentityMapping') {
      return deserialize<_i112.IdentityMapping>(data['data']);
    }
    if (dataClassName == 'IncomingWebhook') {
      return deserialize<_i113.IncomingWebhook>(data['data']);
    }
    if (dataClassName == 'IncomingWebhookCreated') {
      return deserialize<_i114.IncomingWebhookCreated>(data['data']);
    }
    if (dataClassName == 'LinkPreview') {
      return deserialize<_i115.LinkPreview>(data['data']);
    }
    if (dataClassName == 'LinkPreviewView') {
      return deserialize<_i116.LinkPreviewView>(data['data']);
    }
    if (dataClassName == 'MessageIndex') {
      return deserialize<_i117.MessageIndex>(data['data']);
    }
    if (dataClassName == 'MessengerAuthContext') {
      return deserialize<_i118.MessengerAuthContext>(data['data']);
    }
    if (dataClassName == 'MessengerEvent') {
      return deserialize<_i119.MessengerEvent>(data['data']);
    }
    if (dataClassName == 'MessengerMessage') {
      return deserialize<_i120.MessengerMessage>(data['data']);
    }
    if (dataClassName == 'MessengerMessageListPage') {
      return deserialize<_i121.MessengerMessageListPage>(data['data']);
    }
    if (dataClassName == 'MessengerSession') {
      return deserialize<_i122.MessengerSession>(data['data']);
    }
    if (dataClassName == 'MessengerSessionToken') {
      return deserialize<_i123.MessengerSessionToken>(data['data']);
    }
    if (dataClassName == 'MessengerUser') {
      return deserialize<_i124.MessengerUser>(data['data']);
    }
    if (dataClassName == 'NearbyConfirmResult') {
      return deserialize<_i125.NearbyConfirmResult>(data['data']);
    }
    if (dataClassName == 'NearbyConfirmation') {
      return deserialize<_i126.NearbyConfirmation>(data['data']);
    }
    if (dataClassName == 'NotificationSettings') {
      return deserialize<_i127.NotificationSettings>(data['data']);
    }
    if (dataClassName == 'PresenceConnState') {
      return deserialize<_i128.PresenceConnState>(data['data']);
    }
    if (dataClassName == 'PresenceInfo') {
      return deserialize<_i129.PresenceInfo>(data['data']);
    }
    if (dataClassName == 'PresenceState') {
      return deserialize<_i130.PresenceState>(data['data']);
    }
    if (dataClassName == 'PresenceWatchedIndex') {
      return deserialize<_i131.PresenceWatchedIndex>(data['data']);
    }
    if (dataClassName == 'PresenceWatchers') {
      return deserialize<_i132.PresenceWatchers>(data['data']);
    }
    if (dataClassName == 'Product') {
      return deserialize<_i133.Product>(data['data']);
    }
    if (dataClassName == 'ProductAdminView') {
      return deserialize<_i134.ProductAdminView>(data['data']);
    }
    if (dataClassName == 'ProductDeliveryHealth') {
      return deserialize<_i135.ProductDeliveryHealth>(data['data']);
    }
    if (dataClassName == 'ProductNotification') {
      return deserialize<_i136.ProductNotification>(data['data']);
    }
    if (dataClassName == 'ProductNotificationRecipientResult') {
      return deserialize<_i137.ProductNotificationRecipientResult>(
        data['data'],
      );
    }
    if (dataClassName == 'ProductNotificationSendResult') {
      return deserialize<_i138.ProductNotificationSendResult>(data['data']);
    }
    if (dataClassName == 'ProductObjectRoom') {
      return deserialize<_i139.ProductObjectRoom>(data['data']);
    }
    if (dataClassName == 'ProfileTranslation') {
      return deserialize<_i140.ProfileTranslation>(data['data']);
    }
    if (dataClassName == 'PulseAccessAuditEvent') {
      return deserialize<_i141.PulseAccessAuditEvent>(data['data']);
    }
    if (dataClassName == 'PulseAccessEntry') {
      return deserialize<_i142.PulseAccessEntry>(data['data']);
    }
    if (dataClassName == 'PulseAlertRule') {
      return deserialize<_i143.PulseAlertRule>(data['data']);
    }
    if (dataClassName == 'PulseEvent') {
      return deserialize<_i144.PulseEvent>(data['data']);
    }
    if (dataClassName == 'PulseExpiryReminder') {
      return deserialize<_i145.PulseExpiryReminder>(data['data']);
    }
    if (dataClassName == 'PulseFolder') {
      return deserialize<_i146.PulseFolder>(data['data']);
    }
    if (dataClassName == 'PulseFolderMembership') {
      return deserialize<_i147.PulseFolderMembership>(data['data']);
    }
    if (dataClassName == 'PulseIncident') {
      return deserialize<_i148.PulseIncident>(data['data']);
    }
    if (dataClassName == 'PulseMemberView') {
      return deserialize<_i149.PulseMemberView>(data['data']);
    }
    if (dataClassName == 'PulseMonitor') {
      return deserialize<_i150.PulseMonitor>(data['data']);
    }
    if (dataClassName == 'PulseMonitorCreated') {
      return deserialize<_i151.PulseMonitorCreated>(data['data']);
    }
    if (dataClassName == 'PulseMonitorMembership') {
      return deserialize<_i152.PulseMonitorMembership>(data['data']);
    }
    if (dataClassName == 'PulseProbeAllowlistEntry') {
      return deserialize<_i153.PulseProbeAllowlistEntry>(data['data']);
    }
    if (dataClassName == 'PulseTlsProbe') {
      return deserialize<_i154.PulseTlsProbe>(data['data']);
    }
    if (dataClassName == 'PulseValueThreshold') {
      return deserialize<_i155.PulseValueThreshold>(data['data']);
    }
    if (dataClassName == 'PushQueueMessage') {
      return deserialize<_i156.PushQueueMessage>(data['data']);
    }
    if (dataClassName == 'PushTestJob') {
      return deserialize<_i157.PushTestJob>(data['data']);
    }
    if (dataClassName == 'PushTestResult') {
      return deserialize<_i158.PushTestResult>(data['data']);
    }
    if (dataClassName == 'Room') {
      return deserialize<_i159.Room>(data['data']);
    }
    if (dataClassName == 'RoomBotCommands') {
      return deserialize<_i160.RoomBotCommands>(data['data']);
    }
    if (dataClassName == 'RoomDetails') {
      return deserialize<_i161.RoomDetails>(data['data']);
    }
    if (dataClassName == 'RoomListPage') {
      return deserialize<_i162.RoomListPage>(data['data']);
    }
    if (dataClassName == 'RoomMembership') {
      return deserialize<_i163.RoomMembership>(data['data']);
    }
    if (dataClassName == 'RoomParticipant') {
      return deserialize<_i164.RoomParticipant>(data['data']);
    }
    if (dataClassName == 'RoomSummary') {
      return deserialize<_i165.RoomSummary>(data['data']);
    }
    if (dataClassName == 'RoomTaskStats') {
      return deserialize<_i166.RoomTaskStats>(data['data']);
    }
    if (dataClassName == 'RoomTaskView') {
      return deserialize<_i167.RoomTaskView>(data['data']);
    }
    if (dataClassName == 'SupportTeam') {
      return deserialize<_i168.SupportTeam>(data['data']);
    }
    if (dataClassName == 'SupportTeamExclusion') {
      return deserialize<_i169.SupportTeamExclusion>(data['data']);
    }
    if (dataClassName == 'SupportTeamMember') {
      return deserialize<_i170.SupportTeamMember>(data['data']);
    }
    if (dataClassName == 'SupportTeamMemberView') {
      return deserialize<_i171.SupportTeamMemberView>(data['data']);
    }
    if (dataClassName == 'SupportTeamView') {
      return deserialize<_i172.SupportTeamView>(data['data']);
    }
    if (dataClassName == 'TaskLink') {
      return deserialize<_i173.TaskLink>(data['data']);
    }
    if (dataClassName == 'TaskManagerConfig') {
      return deserialize<_i174.TaskManagerConfig>(data['data']);
    }
    if (dataClassName == 'Team') {
      return deserialize<_i175.Team>(data['data']);
    }
    if (dataClassName == 'TeamMember') {
      return deserialize<_i176.TeamMember>(data['data']);
    }
    if (dataClassName == 'TeamMemberView') {
      return deserialize<_i177.TeamMemberView>(data['data']);
    }
    if (dataClassName == 'TeamView') {
      return deserialize<_i178.TeamView>(data['data']);
    }
    if (dataClassName == 'Tenant') {
      return deserialize<_i179.Tenant>(data['data']);
    }
    if (dataClassName == 'TenantSupportMember') {
      return deserialize<_i180.TenantSupportMember>(data['data']);
    }
    if (dataClassName == 'TenantSupportMemberView') {
      return deserialize<_i181.TenantSupportMemberView>(data['data']);
    }
    if (dataClassName == 'ThreadReadState') {
      return deserialize<_i182.ThreadReadState>(data['data']);
    }
    if (dataClassName == 'Ticket') {
      return deserialize<_i183.Ticket>(data['data']);
    }
    if (dataClassName == 'TicketEvent') {
      return deserialize<_i184.TicketEvent>(data['data']);
    }
    if (dataClassName == 'TicketView') {
      return deserialize<_i185.TicketView>(data['data']);
    }
    if (dataClassName == 'TrustRedeemResult') {
      return deserialize<_i186.TrustRedeemResult>(data['data']);
    }
    if (dataClassName == 'TrustToken') {
      return deserialize<_i187.TrustToken>(data['data']);
    }
    if (dataClassName == 'TrustTokenIssued') {
      return deserialize<_i188.TrustTokenIssued>(data['data']);
    }
    if (dataClassName == 'TurnCredentials') {
      return deserialize<_i189.TurnCredentials>(data['data']);
    }
    if (dataClassName == 'WebhookDelivery') {
      return deserialize<_i190.WebhookDelivery>(data['data']);
    }
    if (dataClassName == 'WebhookEventMessage') {
      return deserialize<_i191.WebhookEventMessage>(data['data']);
    }
    if (dataClassName == 'WebhookSubscription') {
      return deserialize<_i192.WebhookSubscription>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i239.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i240.Protocol().deserializeByClassName(data);
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
      return _i239.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i240.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
