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
import 'announcement_recipient.dart' as _i3;
import 'announcement_seen.dart' as _i4;
import 'announcement_view.dart' as _i5;
import 'attachment_bytes.dart' as _i6;
import 'attachment_object.dart' as _i7;
import 'attachment_placement.dart' as _i8;
import 'attachment_ref.dart' as _i9;
import 'attachment_url.dart' as _i10;
import 'available_bot.dart' as _i11;
import 'bot.dart' as _i12;
import 'bot_audit_event.dart' as _i13;
import 'bot_channel_health.dart' as _i14;
import 'bot_command.dart' as _i15;
import 'bot_integration_created.dart' as _i16;
import 'bot_integration_view.dart' as _i17;
import 'bot_read_mode_result.dart' as _i18;
import 'call_history_entry.dart' as _i19;
import 'call_ice_candidate.dart' as _i20;
import 'chat_folder.dart' as _i21;
import 'chat_folder_room.dart' as _i22;
import 'chat_folder_view.dart' as _i23;
import 'conference.dart' as _i24;
import 'conference_member.dart' as _i25;
import 'conference_participant.dart' as _i26;
import 'conference_screen_share.dart' as _i27;
import 'conference_state.dart' as _i28;
import 'connect_issued_token.dart' as _i29;
import 'connect_issued_token_result.dart' as _i30;
import 'connect_key_audit_event.dart' as _i31;
import 'connect_tenant_status.dart' as _i32;
import 'contact_block.dart' as _i33;
import 'contact_card.dart' as _i34;
import 'contact_card_info.dart' as _i35;
import 'contact_label.dart' as _i36;
import 'contact_label_assignment.dart' as _i37;
import 'contact_link.dart' as _i38;
import 'contact_meta.dart' as _i39;
import 'contact_profile_view.dart' as _i40;
import 'contact_relation.dart' as _i41;
import 'contact_request.dart' as _i42;
import 'contact_request_view.dart' as _i43;
import 'crm/crm_access_denied.dart' as _i44;
import 'crm/crm_activity_type.dart' as _i45;
import 'crm/crm_activity_view.dart' as _i46;
import 'crm/crm_actor_kind.dart' as _i47;
import 'crm/crm_bridge_not_configured.dart' as _i48;
import 'crm/crm_change_operation.dart' as _i49;
import 'crm/crm_change_view.dart' as _i50;
import 'crm/crm_changeset_status.dart' as _i51;
import 'crm/crm_changeset_view.dart' as _i52;
import 'crm/crm_company_details.dart' as _i53;
import 'crm/crm_company_kind.dart' as _i54;
import 'crm/crm_company_status.dart' as _i55;
import 'crm/crm_company_view.dart' as _i56;
import 'crm/crm_confirmation_required.dart' as _i57;
import 'crm/crm_contact_view.dart' as _i58;
import 'crm/crm_deal_page.dart' as _i59;
import 'crm/crm_deal_view.dart' as _i60;
import 'crm/crm_digest.dart' as _i61;
import 'crm/crm_document_kind.dart' as _i62;
import 'crm/crm_document_view.dart' as _i63;
import 'crm/crm_entity_kind.dart' as _i64;
import 'crm/crm_input_invalid.dart' as _i65;
import 'crm/crm_metric_view.dart' as _i66;
import 'crm/crm_next_step_state.dart' as _i67;
import 'crm/crm_pd_basis.dart' as _i68;
import 'crm/crm_personal_grant_view.dart' as _i69;
import 'crm/crm_pipeline_in_use.dart' as _i70;
import 'crm/crm_pipeline_invalid.dart' as _i71;
import 'crm/crm_proposal.dart' as _i72;
import 'crm/crm_proposal_stale.dart' as _i73;
import 'crm/crm_segment_role.dart' as _i74;
import 'crm/crm_stage_count.dart' as _i75;
import 'crm/crm_stage_in_use.dart' as _i76;
import 'crm/crm_stage_kind.dart' as _i77;
import 'crm/crm_stage_order_conflict.dart' as _i78;
import 'crm/crm_user_view.dart' as _i79;
import 'crm/crm_version_conflict.dart' as _i80;
import 'crm/crm_version_conflict_item.dart' as _i81;
import 'delivery_journal_entry.dart' as _i82;
import 'delivery_journal_page.dart' as _i83;
import 'delivery_pending.dart' as _i84;
import 'delivery_recipient_state.dart' as _i85;
import 'delivery_recipient_status.dart' as _i86;
import 'delivery_silent_page.dart' as _i87;
import 'delivery_silent_recipient.dart' as _i88;
import 'delivery_usage.dart' as _i89;
import 'device_registration.dart' as _i90;
import 'device_registration_removal.dart' as _i91;
import 'device_session_info.dart' as _i92;
import 'email_account.dart' as _i93;
import 'email_session.dart' as _i94;
import 'email_verification_code.dart' as _i95;
import 'enums/attachment_reject_reason.dart' as _i96;
import 'enums/call_event_type.dart' as _i97;
import 'enums/call_status.dart' as _i98;
import 'enums/contact_link_source.dart' as _i99;
import 'enums/contact_request_status.dart' as _i100;
import 'enums/device_platform.dart' as _i101;
import 'enums/device_removal_reason.dart' as _i102;
import 'enums/identity_provider.dart' as _i103;
import 'enums/messenger_event_type.dart' as _i104;
import 'enums/participant_kind.dart' as _i105;
import 'enums/product_notification_status.dart' as _i106;
import 'enums/push_service.dart' as _i107;
import 'enums/room_member_role.dart' as _i108;
import 'enums/room_ownership.dart' as _i109;
import 'enums/room_state.dart' as _i110;
import 'enums/room_type.dart' as _i111;
import 'enums/support_team_role.dart' as _i112;
import 'enums/team_kind.dart' as _i113;
import 'enums/team_member_role.dart' as _i114;
import 'enums/tenant_hosting_mode.dart' as _i115;
import 'enums/trust_token_kind.dart' as _i116;
import 'errors/adapter_not_configured_exception.dart' as _i117;
import 'errors/ambiguous_product_key_exception.dart' as _i118;
import 'errors/attachment_access_denied_exception.dart' as _i119;
import 'errors/attachment_rejected_exception.dart' as _i120;
import 'errors/bot_capability_exception.dart' as _i121;
import 'errors/bot_limit_exceeded_exception.dart' as _i122;
import 'errors/bot_not_found_exception.dart' as _i123;
import 'errors/bot_read_restricted_exception.dart' as _i124;
import 'errors/conference_full_exception.dart' as _i125;
import 'errors/email_auth_exception.dart' as _i126;
import 'errors/insufficient_power_exception.dart' as _i127;
import 'errors/invalid_bot_commands_exception.dart' as _i128;
import 'errors/invalid_external_key_exception.dart' as _i129;
import 'errors/invalid_notification_exception.dart' as _i130;
import 'errors/invalid_token_exception.dart' as _i131;
import 'errors/last_owner_cannot_demote_exception.dart' as _i132;
import 'errors/message_body_too_large_exception.dart' as _i133;
import 'errors/message_deleted_exception.dart' as _i134;
import 'errors/message_not_editable_exception.dart' as _i135;
import 'errors/messenger_not_authenticated_exception.dart' as _i136;
import 'errors/not_object_room_exception.dart' as _i137;
import 'errors/not_support_team_member_exception.dart' as _i138;
import 'errors/not_support_team_owner_exception.dart' as _i139;
import 'errors/notification_in_progress_exception.dart' as _i140;
import 'errors/operator_email_not_resolved_exception.dart' as _i141;
import 'errors/peer_unavailable_exception.dart' as _i142;
import 'errors/probe_target_not_allowed_exception.dart' as _i143;
import 'errors/product_already_exists_exception.dart' as _i144;
import 'errors/product_in_use_exception.dart' as _i145;
import 'errors/product_not_found_exception.dart' as _i146;
import 'errors/product_not_found_for_caller_exception.dart' as _i147;
import 'errors/rate_limit_exceeded_exception.dart' as _i148;
import 'errors/room_capacity_exceeded_exception.dart' as _i149;
import 'errors/room_dissolve_partial_exception.dart' as _i150;
import 'errors/room_unavailable_exception.dart' as _i151;
import 'errors/screen_share_busy_exception.dart' as _i152;
import 'errors/sticker_rejected_exception.dart' as _i153;
import 'errors/task_integration_not_configured_exception.dart' as _i154;
import 'errors/team_access_denied_exception.dart' as _i155;
import 'errors/team_peer_unknown_exception.dart' as _i156;
import 'errors/tenant_already_exists_exception.dart' as _i157;
import 'errors/tenant_not_found_exception.dart' as _i158;
import 'errors/thumbnail_unavailable_exception.dart' as _i159;
import 'errors/webhook_subscription_exception.dart' as _i160;
import 'errors/write_banned_exception.dart' as _i161;
import 'escalation_result.dart' as _i162;
import 'greetings/greeting.dart' as _i163;
import 'identity_mapping.dart' as _i164;
import 'incoming_webhook.dart' as _i165;
import 'incoming_webhook_created.dart' as _i166;
import 'link_preview.dart' as _i167;
import 'link_preview_view.dart' as _i168;
import 'message_index.dart' as _i169;
import 'messenger_auth_context.dart' as _i170;
import 'messenger_event.dart' as _i171;
import 'messenger_message.dart' as _i172;
import 'messenger_message_list_page.dart' as _i173;
import 'messenger_session.dart' as _i174;
import 'messenger_session_token.dart' as _i175;
import 'messenger_user.dart' as _i176;
import 'nearby_confirm_result.dart' as _i177;
import 'nearby_confirmation.dart' as _i178;
import 'notification_settings.dart' as _i179;
import 'presence_conn_state.dart' as _i180;
import 'presence_info.dart' as _i181;
import 'presence_state.dart' as _i182;
import 'presence_watched_index.dart' as _i183;
import 'presence_watchers.dart' as _i184;
import 'product.dart' as _i185;
import 'product_admin_view.dart' as _i186;
import 'product_announcement_view.dart' as _i187;
import 'product_delivery_health.dart' as _i188;
import 'product_notification.dart' as _i189;
import 'product_notification_recipient_result.dart' as _i190;
import 'product_notification_send_result.dart' as _i191;
import 'product_object_room.dart' as _i192;
import 'profile_translation.dart' as _i193;
import 'pulse_access_audit_event.dart' as _i194;
import 'pulse_access_entry.dart' as _i195;
import 'pulse_alert_rule.dart' as _i196;
import 'pulse_event.dart' as _i197;
import 'pulse_expiry_reminder.dart' as _i198;
import 'pulse_folder.dart' as _i199;
import 'pulse_folder_membership.dart' as _i200;
import 'pulse_incident.dart' as _i201;
import 'pulse_member_view.dart' as _i202;
import 'pulse_monitor.dart' as _i203;
import 'pulse_monitor_created.dart' as _i204;
import 'pulse_monitor_membership.dart' as _i205;
import 'pulse_probe_allowlist_entry.dart' as _i206;
import 'pulse_tls_probe.dart' as _i207;
import 'pulse_value_threshold.dart' as _i208;
import 'push_queue_message.dart' as _i209;
import 'push_test_job.dart' as _i210;
import 'push_test_result.dart' as _i211;
import 'room.dart' as _i212;
import 'room_bot_commands.dart' as _i213;
import 'room_delivery_backstop.dart' as _i214;
import 'room_details.dart' as _i215;
import 'room_list_page.dart' as _i216;
import 'room_membership.dart' as _i217;
import 'room_participant.dart' as _i218;
import 'room_summary.dart' as _i219;
import 'room_task_stats.dart' as _i220;
import 'room_task_view.dart' as _i221;
import 'sticker.dart' as _i222;
import 'sticker_pack.dart' as _i223;
import 'sticker_pack_view.dart' as _i224;
import 'support_team.dart' as _i225;
import 'support_team_exclusion.dart' as _i226;
import 'support_team_member.dart' as _i227;
import 'support_team_member_view.dart' as _i228;
import 'support_team_view.dart' as _i229;
import 'task_link.dart' as _i230;
import 'task_manager_config.dart' as _i231;
import 'team.dart' as _i232;
import 'team_member.dart' as _i233;
import 'team_member_view.dart' as _i234;
import 'team_view.dart' as _i235;
import 'tenant.dart' as _i236;
import 'tenant_support_member.dart' as _i237;
import 'tenant_support_member_view.dart' as _i238;
import 'thread_read_state.dart' as _i239;
import 'ticket.dart' as _i240;
import 'ticket_event.dart' as _i241;
import 'ticket_view.dart' as _i242;
import 'trust_redeem_result.dart' as _i243;
import 'trust_token.dart' as _i244;
import 'trust_token_issued.dart' as _i245;
import 'turn_credentials.dart' as _i246;
import 'webhook_delivery.dart' as _i247;
import 'webhook_event_message.dart' as _i248;
import 'webhook_subscription.dart' as _i249;
import 'package:nsg_connect_client/src/protocol/webhook_subscription.dart'
    as _i250;
import 'package:nsg_connect_client/src/protocol/webhook_delivery.dart' as _i251;
import 'package:nsg_connect_client/src/protocol/announcement.dart' as _i252;
import 'package:nsg_connect_client/src/protocol/bot_audit_event.dart' as _i253;
import 'package:nsg_connect_client/src/protocol/bot.dart' as _i254;
import 'package:nsg_connect_client/src/protocol/room_summary.dart' as _i255;
import 'package:nsg_connect_client/src/protocol/available_bot.dart' as _i256;
import 'package:nsg_connect_client/src/protocol/bot_integration_view.dart'
    as _i257;
import 'package:nsg_connect_client/src/protocol/connect_tenant_status.dart'
    as _i258;
import 'package:nsg_connect_client/src/protocol/product_delivery_health.dart'
    as _i259;
import 'package:nsg_connect_client/src/protocol/tenant_support_member_view.dart'
    as _i260;
import 'package:nsg_connect_client/src/protocol/product_admin_view.dart'
    as _i261;
import 'package:nsg_connect_client/src/protocol/connect_key_audit_event.dart'
    as _i262;
import 'package:nsg_connect_client/src/protocol/team_view.dart' as _i263;
import 'package:nsg_connect_client/src/protocol/team_member_view.dart' as _i264;
import 'package:nsg_connect_client/src/protocol/crm/crm_user_view.dart'
    as _i265;
import 'package:nsg_connect_client/src/protocol/crm/crm_personal_grant_view.dart'
    as _i266;
import 'package:nsg_connect_client/src/protocol/crm/crm_company_view.dart'
    as _i267;
import 'package:nsg_connect_client/src/protocol/crm/crm_contact_view.dart'
    as _i268;
import 'package:nsg_connect_client/src/protocol/crm/crm_entity_kind.dart'
    as _i269;
import 'package:nsg_connect_client/src/protocol/crm/crm_deal_view.dart'
    as _i270;
import 'package:nsg_connect_client/src/protocol/crm/crm_activity_view.dart'
    as _i271;
import 'package:nsg_connect_client/src/protocol/delivery_recipient_status.dart'
    as _i272;
import 'package:nsg_connect_client/src/protocol/device_session_info.dart'
    as _i273;
import 'package:nsg_connect_client/src/protocol/incoming_webhook.dart' as _i274;
import 'package:nsg_connect_client/src/protocol/bot_command.dart' as _i275;
import 'package:nsg_connect_client/src/protocol/room_bot_commands.dart'
    as _i276;
import 'package:nsg_connect_client/src/protocol/messenger_message.dart'
    as _i277;
import 'package:nsg_connect_client/src/protocol/call_ice_candidate.dart'
    as _i278;
import 'package:nsg_connect_client/src/protocol/call_history_entry.dart'
    as _i279;
import 'package:nsg_connect_client/src/protocol/messenger_event.dart' as _i280;
import 'package:nsg_connect_client/src/protocol/link_preview_view.dart'
    as _i281;
import 'package:nsg_connect_client/src/protocol/room_participant.dart' as _i282;
import 'package:nsg_connect_client/src/protocol/ticket_view.dart' as _i283;
import 'package:nsg_connect_client/src/protocol/announcement_view.dart'
    as _i284;
import 'package:nsg_connect_client/src/protocol/room_task_view.dart' as _i285;
import 'package:nsg_connect_client/src/protocol/presence_info.dart' as _i286;
import 'package:nsg_connect_client/src/protocol/chat_folder_view.dart' as _i287;
import 'package:nsg_connect_client/src/protocol/contact_request_view.dart'
    as _i288;
import 'package:nsg_connect_client/src/protocol/contact_label.dart' as _i289;
import 'package:nsg_connect_client/src/protocol/contact_label_assignment.dart'
    as _i290;
import 'package:nsg_connect_client/src/protocol/product_object_room.dart'
    as _i291;
import 'package:nsg_connect_client/src/protocol/product.dart' as _i292;
import 'package:nsg_connect_client/src/protocol/profile_translation.dart'
    as _i293;
import 'package:nsg_connect_client/src/protocol/product_announcement_view.dart'
    as _i294;
import 'package:nsg_connect_client/src/protocol/pulse_folder.dart' as _i295;
import 'package:nsg_connect_client/src/protocol/pulse_monitor.dart' as _i296;
import 'package:nsg_connect_client/src/protocol/pulse_alert_rule.dart' as _i297;
import 'package:nsg_connect_client/src/protocol/pulse_incident.dart' as _i298;
import 'package:nsg_connect_client/src/protocol/pulse_access_entry.dart'
    as _i299;
import 'package:nsg_connect_client/src/protocol/pulse_member_view.dart'
    as _i300;
import 'package:nsg_connect_client/src/protocol/pulse_access_audit_event.dart'
    as _i301;
import 'package:nsg_connect_client/src/protocol/pulse_tls_probe.dart' as _i302;
import 'package:nsg_connect_client/src/protocol/pulse_value_threshold.dart'
    as _i303;
import 'package:nsg_connect_client/src/protocol/pulse_probe_allowlist_entry.dart'
    as _i304;
import 'package:nsg_connect_client/src/protocol/sticker_pack_view.dart'
    as _i305;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i306;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i307;
export 'announcement.dart';
export 'announcement_recipient.dart';
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
export 'crm/crm_access_denied.dart';
export 'crm/crm_activity_type.dart';
export 'crm/crm_activity_view.dart';
export 'crm/crm_actor_kind.dart';
export 'crm/crm_bridge_not_configured.dart';
export 'crm/crm_change_operation.dart';
export 'crm/crm_change_view.dart';
export 'crm/crm_changeset_status.dart';
export 'crm/crm_changeset_view.dart';
export 'crm/crm_company_details.dart';
export 'crm/crm_company_kind.dart';
export 'crm/crm_company_status.dart';
export 'crm/crm_company_view.dart';
export 'crm/crm_confirmation_required.dart';
export 'crm/crm_contact_view.dart';
export 'crm/crm_deal_page.dart';
export 'crm/crm_deal_view.dart';
export 'crm/crm_digest.dart';
export 'crm/crm_document_kind.dart';
export 'crm/crm_document_view.dart';
export 'crm/crm_entity_kind.dart';
export 'crm/crm_input_invalid.dart';
export 'crm/crm_metric_view.dart';
export 'crm/crm_next_step_state.dart';
export 'crm/crm_pd_basis.dart';
export 'crm/crm_personal_grant_view.dart';
export 'crm/crm_pipeline_in_use.dart';
export 'crm/crm_pipeline_invalid.dart';
export 'crm/crm_proposal.dart';
export 'crm/crm_proposal_stale.dart';
export 'crm/crm_segment_role.dart';
export 'crm/crm_stage_count.dart';
export 'crm/crm_stage_in_use.dart';
export 'crm/crm_stage_kind.dart';
export 'crm/crm_stage_order_conflict.dart';
export 'crm/crm_user_view.dart';
export 'crm/crm_version_conflict.dart';
export 'crm/crm_version_conflict_item.dart';
export 'delivery_journal_entry.dart';
export 'delivery_journal_page.dart';
export 'delivery_pending.dart';
export 'delivery_recipient_state.dart';
export 'delivery_recipient_status.dart';
export 'delivery_silent_page.dart';
export 'delivery_silent_recipient.dart';
export 'delivery_usage.dart';
export 'device_registration.dart';
export 'device_registration_removal.dart';
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
export 'enums/device_removal_reason.dart';
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
export 'errors/notification_in_progress_exception.dart';
export 'errors/operator_email_not_resolved_exception.dart';
export 'errors/peer_unavailable_exception.dart';
export 'errors/probe_target_not_allowed_exception.dart';
export 'errors/product_already_exists_exception.dart';
export 'errors/product_in_use_exception.dart';
export 'errors/product_not_found_exception.dart';
export 'errors/product_not_found_for_caller_exception.dart';
export 'errors/rate_limit_exceeded_exception.dart';
export 'errors/room_capacity_exceeded_exception.dart';
export 'errors/room_dissolve_partial_exception.dart';
export 'errors/room_unavailable_exception.dart';
export 'errors/screen_share_busy_exception.dart';
export 'errors/sticker_rejected_exception.dart';
export 'errors/task_integration_not_configured_exception.dart';
export 'errors/team_access_denied_exception.dart';
export 'errors/team_peer_unknown_exception.dart';
export 'errors/tenant_already_exists_exception.dart';
export 'errors/tenant_not_found_exception.dart';
export 'errors/thumbnail_unavailable_exception.dart';
export 'errors/webhook_subscription_exception.dart';
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
export 'product_announcement_view.dart';
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
export 'room_delivery_backstop.dart';
export 'room_details.dart';
export 'room_list_page.dart';
export 'room_membership.dart';
export 'room_participant.dart';
export 'room_summary.dart';
export 'room_task_stats.dart';
export 'room_task_view.dart';
export 'sticker.dart';
export 'sticker_pack.dart';
export 'sticker_pack_view.dart';
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
    if (t == _i3.AnnouncementRecipient) {
      return _i3.AnnouncementRecipient.fromJson(data) as T;
    }
    if (t == _i4.AnnouncementSeen) {
      return _i4.AnnouncementSeen.fromJson(data) as T;
    }
    if (t == _i5.AnnouncementView) {
      return _i5.AnnouncementView.fromJson(data) as T;
    }
    if (t == _i6.AttachmentBytes) {
      return _i6.AttachmentBytes.fromJson(data) as T;
    }
    if (t == _i7.AttachmentObject) {
      return _i7.AttachmentObject.fromJson(data) as T;
    }
    if (t == _i8.AttachmentPlacement) {
      return _i8.AttachmentPlacement.fromJson(data) as T;
    }
    if (t == _i9.AttachmentRef) {
      return _i9.AttachmentRef.fromJson(data) as T;
    }
    if (t == _i10.AttachmentUrl) {
      return _i10.AttachmentUrl.fromJson(data) as T;
    }
    if (t == _i11.AvailableBot) {
      return _i11.AvailableBot.fromJson(data) as T;
    }
    if (t == _i12.Bot) {
      return _i12.Bot.fromJson(data) as T;
    }
    if (t == _i13.BotAuditEvent) {
      return _i13.BotAuditEvent.fromJson(data) as T;
    }
    if (t == _i14.BotChannelHealth) {
      return _i14.BotChannelHealth.fromJson(data) as T;
    }
    if (t == _i15.BotCommand) {
      return _i15.BotCommand.fromJson(data) as T;
    }
    if (t == _i16.BotIntegrationCreated) {
      return _i16.BotIntegrationCreated.fromJson(data) as T;
    }
    if (t == _i17.BotIntegrationView) {
      return _i17.BotIntegrationView.fromJson(data) as T;
    }
    if (t == _i18.BotReadModeResult) {
      return _i18.BotReadModeResult.fromJson(data) as T;
    }
    if (t == _i19.CallHistoryEntry) {
      return _i19.CallHistoryEntry.fromJson(data) as T;
    }
    if (t == _i20.CallIceCandidate) {
      return _i20.CallIceCandidate.fromJson(data) as T;
    }
    if (t == _i21.ChatFolderRecord) {
      return _i21.ChatFolderRecord.fromJson(data) as T;
    }
    if (t == _i22.ChatFolderRoom) {
      return _i22.ChatFolderRoom.fromJson(data) as T;
    }
    if (t == _i23.ChatFolderView) {
      return _i23.ChatFolderView.fromJson(data) as T;
    }
    if (t == _i24.Conference) {
      return _i24.Conference.fromJson(data) as T;
    }
    if (t == _i25.ConferenceMember) {
      return _i25.ConferenceMember.fromJson(data) as T;
    }
    if (t == _i26.ConferenceParticipant) {
      return _i26.ConferenceParticipant.fromJson(data) as T;
    }
    if (t == _i27.ConferenceScreenShare) {
      return _i27.ConferenceScreenShare.fromJson(data) as T;
    }
    if (t == _i28.ConferenceState) {
      return _i28.ConferenceState.fromJson(data) as T;
    }
    if (t == _i29.ConnectIssuedToken) {
      return _i29.ConnectIssuedToken.fromJson(data) as T;
    }
    if (t == _i30.ConnectIssuedTokenResult) {
      return _i30.ConnectIssuedTokenResult.fromJson(data) as T;
    }
    if (t == _i31.ConnectKeyAuditEvent) {
      return _i31.ConnectKeyAuditEvent.fromJson(data) as T;
    }
    if (t == _i32.ConnectTenantStatus) {
      return _i32.ConnectTenantStatus.fromJson(data) as T;
    }
    if (t == _i33.ContactBlock) {
      return _i33.ContactBlock.fromJson(data) as T;
    }
    if (t == _i34.ContactCard) {
      return _i34.ContactCard.fromJson(data) as T;
    }
    if (t == _i35.ContactCardInfo) {
      return _i35.ContactCardInfo.fromJson(data) as T;
    }
    if (t == _i36.ContactLabel) {
      return _i36.ContactLabel.fromJson(data) as T;
    }
    if (t == _i37.ContactLabelAssignment) {
      return _i37.ContactLabelAssignment.fromJson(data) as T;
    }
    if (t == _i38.ContactLink) {
      return _i38.ContactLink.fromJson(data) as T;
    }
    if (t == _i39.ContactMeta) {
      return _i39.ContactMeta.fromJson(data) as T;
    }
    if (t == _i40.ContactProfileView) {
      return _i40.ContactProfileView.fromJson(data) as T;
    }
    if (t == _i41.ContactRelation) {
      return _i41.ContactRelation.fromJson(data) as T;
    }
    if (t == _i42.ContactRequest) {
      return _i42.ContactRequest.fromJson(data) as T;
    }
    if (t == _i43.ContactRequestView) {
      return _i43.ContactRequestView.fromJson(data) as T;
    }
    if (t == _i44.CrmAccessDenied) {
      return _i44.CrmAccessDenied.fromJson(data) as T;
    }
    if (t == _i45.CrmActivityType) {
      return _i45.CrmActivityType.fromJson(data) as T;
    }
    if (t == _i46.CrmActivityView) {
      return _i46.CrmActivityView.fromJson(data) as T;
    }
    if (t == _i47.CrmActorKind) {
      return _i47.CrmActorKind.fromJson(data) as T;
    }
    if (t == _i48.CrmBridgeNotConfigured) {
      return _i48.CrmBridgeNotConfigured.fromJson(data) as T;
    }
    if (t == _i49.CrmChangeOperation) {
      return _i49.CrmChangeOperation.fromJson(data) as T;
    }
    if (t == _i50.CrmChangeView) {
      return _i50.CrmChangeView.fromJson(data) as T;
    }
    if (t == _i51.CrmChangesetStatus) {
      return _i51.CrmChangesetStatus.fromJson(data) as T;
    }
    if (t == _i52.CrmChangesetView) {
      return _i52.CrmChangesetView.fromJson(data) as T;
    }
    if (t == _i53.CrmCompanyDetails) {
      return _i53.CrmCompanyDetails.fromJson(data) as T;
    }
    if (t == _i54.CrmCompanyKind) {
      return _i54.CrmCompanyKind.fromJson(data) as T;
    }
    if (t == _i55.CrmCompanyStatus) {
      return _i55.CrmCompanyStatus.fromJson(data) as T;
    }
    if (t == _i56.CrmCompanyView) {
      return _i56.CrmCompanyView.fromJson(data) as T;
    }
    if (t == _i57.CrmConfirmationRequired) {
      return _i57.CrmConfirmationRequired.fromJson(data) as T;
    }
    if (t == _i58.CrmContactView) {
      return _i58.CrmContactView.fromJson(data) as T;
    }
    if (t == _i59.CrmDealPage) {
      return _i59.CrmDealPage.fromJson(data) as T;
    }
    if (t == _i60.CrmDealView) {
      return _i60.CrmDealView.fromJson(data) as T;
    }
    if (t == _i61.CrmDigest) {
      return _i61.CrmDigest.fromJson(data) as T;
    }
    if (t == _i62.CrmDocumentKind) {
      return _i62.CrmDocumentKind.fromJson(data) as T;
    }
    if (t == _i63.CrmDocumentView) {
      return _i63.CrmDocumentView.fromJson(data) as T;
    }
    if (t == _i64.CrmEntityKind) {
      return _i64.CrmEntityKind.fromJson(data) as T;
    }
    if (t == _i65.CrmInputInvalid) {
      return _i65.CrmInputInvalid.fromJson(data) as T;
    }
    if (t == _i66.CrmMetricView) {
      return _i66.CrmMetricView.fromJson(data) as T;
    }
    if (t == _i67.CrmNextStepState) {
      return _i67.CrmNextStepState.fromJson(data) as T;
    }
    if (t == _i68.CrmPdBasis) {
      return _i68.CrmPdBasis.fromJson(data) as T;
    }
    if (t == _i69.CrmPersonalGrantView) {
      return _i69.CrmPersonalGrantView.fromJson(data) as T;
    }
    if (t == _i70.CrmPipelineInUse) {
      return _i70.CrmPipelineInUse.fromJson(data) as T;
    }
    if (t == _i71.CrmPipelineInvalid) {
      return _i71.CrmPipelineInvalid.fromJson(data) as T;
    }
    if (t == _i72.CrmProposal) {
      return _i72.CrmProposal.fromJson(data) as T;
    }
    if (t == _i73.CrmProposalStale) {
      return _i73.CrmProposalStale.fromJson(data) as T;
    }
    if (t == _i74.CrmSegmentRole) {
      return _i74.CrmSegmentRole.fromJson(data) as T;
    }
    if (t == _i75.CrmStageCount) {
      return _i75.CrmStageCount.fromJson(data) as T;
    }
    if (t == _i76.CrmStageInUse) {
      return _i76.CrmStageInUse.fromJson(data) as T;
    }
    if (t == _i77.CrmStageKind) {
      return _i77.CrmStageKind.fromJson(data) as T;
    }
    if (t == _i78.CrmStageOrderConflict) {
      return _i78.CrmStageOrderConflict.fromJson(data) as T;
    }
    if (t == _i79.CrmUserView) {
      return _i79.CrmUserView.fromJson(data) as T;
    }
    if (t == _i80.CrmVersionConflict) {
      return _i80.CrmVersionConflict.fromJson(data) as T;
    }
    if (t == _i81.CrmVersionConflictItem) {
      return _i81.CrmVersionConflictItem.fromJson(data) as T;
    }
    if (t == _i82.DeliveryJournalEntry) {
      return _i82.DeliveryJournalEntry.fromJson(data) as T;
    }
    if (t == _i83.DeliveryJournalPage) {
      return _i83.DeliveryJournalPage.fromJson(data) as T;
    }
    if (t == _i84.DeliveryPending) {
      return _i84.DeliveryPending.fromJson(data) as T;
    }
    if (t == _i85.DeliveryRecipientState) {
      return _i85.DeliveryRecipientState.fromJson(data) as T;
    }
    if (t == _i86.DeliveryRecipientStatus) {
      return _i86.DeliveryRecipientStatus.fromJson(data) as T;
    }
    if (t == _i87.DeliverySilentPage) {
      return _i87.DeliverySilentPage.fromJson(data) as T;
    }
    if (t == _i88.DeliverySilentRecipient) {
      return _i88.DeliverySilentRecipient.fromJson(data) as T;
    }
    if (t == _i89.DeliveryUsage) {
      return _i89.DeliveryUsage.fromJson(data) as T;
    }
    if (t == _i90.DeviceRegistration) {
      return _i90.DeviceRegistration.fromJson(data) as T;
    }
    if (t == _i91.DeviceRegistrationRemoval) {
      return _i91.DeviceRegistrationRemoval.fromJson(data) as T;
    }
    if (t == _i92.DeviceSessionInfo) {
      return _i92.DeviceSessionInfo.fromJson(data) as T;
    }
    if (t == _i93.EmailAccount) {
      return _i93.EmailAccount.fromJson(data) as T;
    }
    if (t == _i94.EmailSession) {
      return _i94.EmailSession.fromJson(data) as T;
    }
    if (t == _i95.EmailVerificationCode) {
      return _i95.EmailVerificationCode.fromJson(data) as T;
    }
    if (t == _i96.AttachmentRejectReason) {
      return _i96.AttachmentRejectReason.fromJson(data) as T;
    }
    if (t == _i97.CallEventType) {
      return _i97.CallEventType.fromJson(data) as T;
    }
    if (t == _i98.CallStatus) {
      return _i98.CallStatus.fromJson(data) as T;
    }
    if (t == _i99.ContactLinkSource) {
      return _i99.ContactLinkSource.fromJson(data) as T;
    }
    if (t == _i100.ContactRequestStatus) {
      return _i100.ContactRequestStatus.fromJson(data) as T;
    }
    if (t == _i101.DevicePlatform) {
      return _i101.DevicePlatform.fromJson(data) as T;
    }
    if (t == _i102.DeviceRemovalReason) {
      return _i102.DeviceRemovalReason.fromJson(data) as T;
    }
    if (t == _i103.IdentityProvider) {
      return _i103.IdentityProvider.fromJson(data) as T;
    }
    if (t == _i104.MessengerEventType) {
      return _i104.MessengerEventType.fromJson(data) as T;
    }
    if (t == _i105.ParticipantKind) {
      return _i105.ParticipantKind.fromJson(data) as T;
    }
    if (t == _i106.ProductNotificationStatus) {
      return _i106.ProductNotificationStatus.fromJson(data) as T;
    }
    if (t == _i107.PushService) {
      return _i107.PushService.fromJson(data) as T;
    }
    if (t == _i108.RoomMemberRole) {
      return _i108.RoomMemberRole.fromJson(data) as T;
    }
    if (t == _i109.RoomOwnership) {
      return _i109.RoomOwnership.fromJson(data) as T;
    }
    if (t == _i110.RoomState) {
      return _i110.RoomState.fromJson(data) as T;
    }
    if (t == _i111.RoomType) {
      return _i111.RoomType.fromJson(data) as T;
    }
    if (t == _i112.SupportTeamRole) {
      return _i112.SupportTeamRole.fromJson(data) as T;
    }
    if (t == _i113.TeamKind) {
      return _i113.TeamKind.fromJson(data) as T;
    }
    if (t == _i114.TeamMemberRole) {
      return _i114.TeamMemberRole.fromJson(data) as T;
    }
    if (t == _i115.TenantHostingMode) {
      return _i115.TenantHostingMode.fromJson(data) as T;
    }
    if (t == _i116.TrustTokenKind) {
      return _i116.TrustTokenKind.fromJson(data) as T;
    }
    if (t == _i117.AdapterNotConfiguredException) {
      return _i117.AdapterNotConfiguredException.fromJson(data) as T;
    }
    if (t == _i118.AmbiguousProductKeyException) {
      return _i118.AmbiguousProductKeyException.fromJson(data) as T;
    }
    if (t == _i119.AttachmentAccessDeniedException) {
      return _i119.AttachmentAccessDeniedException.fromJson(data) as T;
    }
    if (t == _i120.AttachmentRejectedException) {
      return _i120.AttachmentRejectedException.fromJson(data) as T;
    }
    if (t == _i121.BotCapabilityException) {
      return _i121.BotCapabilityException.fromJson(data) as T;
    }
    if (t == _i122.BotLimitExceededException) {
      return _i122.BotLimitExceededException.fromJson(data) as T;
    }
    if (t == _i123.BotNotFoundException) {
      return _i123.BotNotFoundException.fromJson(data) as T;
    }
    if (t == _i124.BotReadRestrictedException) {
      return _i124.BotReadRestrictedException.fromJson(data) as T;
    }
    if (t == _i125.ConferenceFullException) {
      return _i125.ConferenceFullException.fromJson(data) as T;
    }
    if (t == _i126.EmailAuthException) {
      return _i126.EmailAuthException.fromJson(data) as T;
    }
    if (t == _i127.InsufficientPowerException) {
      return _i127.InsufficientPowerException.fromJson(data) as T;
    }
    if (t == _i128.InvalidBotCommandsException) {
      return _i128.InvalidBotCommandsException.fromJson(data) as T;
    }
    if (t == _i129.InvalidExternalKeyException) {
      return _i129.InvalidExternalKeyException.fromJson(data) as T;
    }
    if (t == _i130.InvalidNotificationException) {
      return _i130.InvalidNotificationException.fromJson(data) as T;
    }
    if (t == _i131.InvalidTokenException) {
      return _i131.InvalidTokenException.fromJson(data) as T;
    }
    if (t == _i132.LastOwnerCannotDemoteException) {
      return _i132.LastOwnerCannotDemoteException.fromJson(data) as T;
    }
    if (t == _i133.MessageBodyTooLargeException) {
      return _i133.MessageBodyTooLargeException.fromJson(data) as T;
    }
    if (t == _i134.MessageDeletedException) {
      return _i134.MessageDeletedException.fromJson(data) as T;
    }
    if (t == _i135.MessageNotEditableException) {
      return _i135.MessageNotEditableException.fromJson(data) as T;
    }
    if (t == _i136.MessengerNotAuthenticatedException) {
      return _i136.MessengerNotAuthenticatedException.fromJson(data) as T;
    }
    if (t == _i137.NotObjectRoomException) {
      return _i137.NotObjectRoomException.fromJson(data) as T;
    }
    if (t == _i138.NotSupportTeamMemberException) {
      return _i138.NotSupportTeamMemberException.fromJson(data) as T;
    }
    if (t == _i139.NotSupportTeamOwnerException) {
      return _i139.NotSupportTeamOwnerException.fromJson(data) as T;
    }
    if (t == _i140.NotificationInProgressException) {
      return _i140.NotificationInProgressException.fromJson(data) as T;
    }
    if (t == _i141.OperatorEmailNotResolvedException) {
      return _i141.OperatorEmailNotResolvedException.fromJson(data) as T;
    }
    if (t == _i142.PeerUnavailableException) {
      return _i142.PeerUnavailableException.fromJson(data) as T;
    }
    if (t == _i143.ProbeTargetNotAllowedException) {
      return _i143.ProbeTargetNotAllowedException.fromJson(data) as T;
    }
    if (t == _i144.ProductAlreadyExistsException) {
      return _i144.ProductAlreadyExistsException.fromJson(data) as T;
    }
    if (t == _i145.ProductInUseException) {
      return _i145.ProductInUseException.fromJson(data) as T;
    }
    if (t == _i146.ProductNotFoundException) {
      return _i146.ProductNotFoundException.fromJson(data) as T;
    }
    if (t == _i147.ProductNotFoundForCallerException) {
      return _i147.ProductNotFoundForCallerException.fromJson(data) as T;
    }
    if (t == _i148.RateLimitExceededException) {
      return _i148.RateLimitExceededException.fromJson(data) as T;
    }
    if (t == _i149.RoomCapacityExceededException) {
      return _i149.RoomCapacityExceededException.fromJson(data) as T;
    }
    if (t == _i150.RoomDissolvePartialException) {
      return _i150.RoomDissolvePartialException.fromJson(data) as T;
    }
    if (t == _i151.RoomUnavailableException) {
      return _i151.RoomUnavailableException.fromJson(data) as T;
    }
    if (t == _i152.ScreenShareBusyException) {
      return _i152.ScreenShareBusyException.fromJson(data) as T;
    }
    if (t == _i153.StickerRejectedException) {
      return _i153.StickerRejectedException.fromJson(data) as T;
    }
    if (t == _i154.TaskIntegrationNotConfiguredException) {
      return _i154.TaskIntegrationNotConfiguredException.fromJson(data) as T;
    }
    if (t == _i155.TeamAccessDeniedException) {
      return _i155.TeamAccessDeniedException.fromJson(data) as T;
    }
    if (t == _i156.TeamPeerUnknownException) {
      return _i156.TeamPeerUnknownException.fromJson(data) as T;
    }
    if (t == _i157.TenantAlreadyExistsException) {
      return _i157.TenantAlreadyExistsException.fromJson(data) as T;
    }
    if (t == _i158.TenantNotFoundException) {
      return _i158.TenantNotFoundException.fromJson(data) as T;
    }
    if (t == _i159.ThumbnailUnavailableException) {
      return _i159.ThumbnailUnavailableException.fromJson(data) as T;
    }
    if (t == _i160.WebhookSubscriptionException) {
      return _i160.WebhookSubscriptionException.fromJson(data) as T;
    }
    if (t == _i161.WriteBannedException) {
      return _i161.WriteBannedException.fromJson(data) as T;
    }
    if (t == _i162.EscalationResult) {
      return _i162.EscalationResult.fromJson(data) as T;
    }
    if (t == _i163.Greeting) {
      return _i163.Greeting.fromJson(data) as T;
    }
    if (t == _i164.IdentityMapping) {
      return _i164.IdentityMapping.fromJson(data) as T;
    }
    if (t == _i165.IncomingWebhook) {
      return _i165.IncomingWebhook.fromJson(data) as T;
    }
    if (t == _i166.IncomingWebhookCreated) {
      return _i166.IncomingWebhookCreated.fromJson(data) as T;
    }
    if (t == _i167.LinkPreview) {
      return _i167.LinkPreview.fromJson(data) as T;
    }
    if (t == _i168.LinkPreviewView) {
      return _i168.LinkPreviewView.fromJson(data) as T;
    }
    if (t == _i169.MessageIndex) {
      return _i169.MessageIndex.fromJson(data) as T;
    }
    if (t == _i170.MessengerAuthContext) {
      return _i170.MessengerAuthContext.fromJson(data) as T;
    }
    if (t == _i171.MessengerEvent) {
      return _i171.MessengerEvent.fromJson(data) as T;
    }
    if (t == _i172.MessengerMessage) {
      return _i172.MessengerMessage.fromJson(data) as T;
    }
    if (t == _i173.MessengerMessageListPage) {
      return _i173.MessengerMessageListPage.fromJson(data) as T;
    }
    if (t == _i174.MessengerSession) {
      return _i174.MessengerSession.fromJson(data) as T;
    }
    if (t == _i175.MessengerSessionToken) {
      return _i175.MessengerSessionToken.fromJson(data) as T;
    }
    if (t == _i176.MessengerUser) {
      return _i176.MessengerUser.fromJson(data) as T;
    }
    if (t == _i177.NearbyConfirmResult) {
      return _i177.NearbyConfirmResult.fromJson(data) as T;
    }
    if (t == _i178.NearbyConfirmation) {
      return _i178.NearbyConfirmation.fromJson(data) as T;
    }
    if (t == _i179.NotificationSettings) {
      return _i179.NotificationSettings.fromJson(data) as T;
    }
    if (t == _i180.PresenceConnState) {
      return _i180.PresenceConnState.fromJson(data) as T;
    }
    if (t == _i181.PresenceInfo) {
      return _i181.PresenceInfo.fromJson(data) as T;
    }
    if (t == _i182.PresenceState) {
      return _i182.PresenceState.fromJson(data) as T;
    }
    if (t == _i183.PresenceWatchedIndex) {
      return _i183.PresenceWatchedIndex.fromJson(data) as T;
    }
    if (t == _i184.PresenceWatchers) {
      return _i184.PresenceWatchers.fromJson(data) as T;
    }
    if (t == _i185.Product) {
      return _i185.Product.fromJson(data) as T;
    }
    if (t == _i186.ProductAdminView) {
      return _i186.ProductAdminView.fromJson(data) as T;
    }
    if (t == _i187.ProductAnnouncementView) {
      return _i187.ProductAnnouncementView.fromJson(data) as T;
    }
    if (t == _i188.ProductDeliveryHealth) {
      return _i188.ProductDeliveryHealth.fromJson(data) as T;
    }
    if (t == _i189.ProductNotification) {
      return _i189.ProductNotification.fromJson(data) as T;
    }
    if (t == _i190.ProductNotificationRecipientResult) {
      return _i190.ProductNotificationRecipientResult.fromJson(data) as T;
    }
    if (t == _i191.ProductNotificationSendResult) {
      return _i191.ProductNotificationSendResult.fromJson(data) as T;
    }
    if (t == _i192.ProductObjectRoom) {
      return _i192.ProductObjectRoom.fromJson(data) as T;
    }
    if (t == _i193.ProfileTranslation) {
      return _i193.ProfileTranslation.fromJson(data) as T;
    }
    if (t == _i194.PulseAccessAuditEvent) {
      return _i194.PulseAccessAuditEvent.fromJson(data) as T;
    }
    if (t == _i195.PulseAccessEntry) {
      return _i195.PulseAccessEntry.fromJson(data) as T;
    }
    if (t == _i196.PulseAlertRule) {
      return _i196.PulseAlertRule.fromJson(data) as T;
    }
    if (t == _i197.PulseEvent) {
      return _i197.PulseEvent.fromJson(data) as T;
    }
    if (t == _i198.PulseExpiryReminder) {
      return _i198.PulseExpiryReminder.fromJson(data) as T;
    }
    if (t == _i199.PulseFolder) {
      return _i199.PulseFolder.fromJson(data) as T;
    }
    if (t == _i200.PulseFolderMembership) {
      return _i200.PulseFolderMembership.fromJson(data) as T;
    }
    if (t == _i201.PulseIncident) {
      return _i201.PulseIncident.fromJson(data) as T;
    }
    if (t == _i202.PulseMemberView) {
      return _i202.PulseMemberView.fromJson(data) as T;
    }
    if (t == _i203.PulseMonitor) {
      return _i203.PulseMonitor.fromJson(data) as T;
    }
    if (t == _i204.PulseMonitorCreated) {
      return _i204.PulseMonitorCreated.fromJson(data) as T;
    }
    if (t == _i205.PulseMonitorMembership) {
      return _i205.PulseMonitorMembership.fromJson(data) as T;
    }
    if (t == _i206.PulseProbeAllowlistEntry) {
      return _i206.PulseProbeAllowlistEntry.fromJson(data) as T;
    }
    if (t == _i207.PulseTlsProbe) {
      return _i207.PulseTlsProbe.fromJson(data) as T;
    }
    if (t == _i208.PulseValueThreshold) {
      return _i208.PulseValueThreshold.fromJson(data) as T;
    }
    if (t == _i209.PushQueueMessage) {
      return _i209.PushQueueMessage.fromJson(data) as T;
    }
    if (t == _i210.PushTestJob) {
      return _i210.PushTestJob.fromJson(data) as T;
    }
    if (t == _i211.PushTestResult) {
      return _i211.PushTestResult.fromJson(data) as T;
    }
    if (t == _i212.Room) {
      return _i212.Room.fromJson(data) as T;
    }
    if (t == _i213.RoomBotCommands) {
      return _i213.RoomBotCommands.fromJson(data) as T;
    }
    if (t == _i214.RoomDeliveryBackstop) {
      return _i214.RoomDeliveryBackstop.fromJson(data) as T;
    }
    if (t == _i215.RoomDetails) {
      return _i215.RoomDetails.fromJson(data) as T;
    }
    if (t == _i216.RoomListPage) {
      return _i216.RoomListPage.fromJson(data) as T;
    }
    if (t == _i217.RoomMembership) {
      return _i217.RoomMembership.fromJson(data) as T;
    }
    if (t == _i218.RoomParticipant) {
      return _i218.RoomParticipant.fromJson(data) as T;
    }
    if (t == _i219.RoomSummary) {
      return _i219.RoomSummary.fromJson(data) as T;
    }
    if (t == _i220.RoomTaskStats) {
      return _i220.RoomTaskStats.fromJson(data) as T;
    }
    if (t == _i221.RoomTaskView) {
      return _i221.RoomTaskView.fromJson(data) as T;
    }
    if (t == _i222.Sticker) {
      return _i222.Sticker.fromJson(data) as T;
    }
    if (t == _i223.StickerPack) {
      return _i223.StickerPack.fromJson(data) as T;
    }
    if (t == _i224.StickerPackView) {
      return _i224.StickerPackView.fromJson(data) as T;
    }
    if (t == _i225.SupportTeam) {
      return _i225.SupportTeam.fromJson(data) as T;
    }
    if (t == _i226.SupportTeamExclusion) {
      return _i226.SupportTeamExclusion.fromJson(data) as T;
    }
    if (t == _i227.SupportTeamMember) {
      return _i227.SupportTeamMember.fromJson(data) as T;
    }
    if (t == _i228.SupportTeamMemberView) {
      return _i228.SupportTeamMemberView.fromJson(data) as T;
    }
    if (t == _i229.SupportTeamView) {
      return _i229.SupportTeamView.fromJson(data) as T;
    }
    if (t == _i230.TaskLink) {
      return _i230.TaskLink.fromJson(data) as T;
    }
    if (t == _i231.TaskManagerConfig) {
      return _i231.TaskManagerConfig.fromJson(data) as T;
    }
    if (t == _i232.Team) {
      return _i232.Team.fromJson(data) as T;
    }
    if (t == _i233.TeamMember) {
      return _i233.TeamMember.fromJson(data) as T;
    }
    if (t == _i234.TeamMemberView) {
      return _i234.TeamMemberView.fromJson(data) as T;
    }
    if (t == _i235.TeamView) {
      return _i235.TeamView.fromJson(data) as T;
    }
    if (t == _i236.Tenant) {
      return _i236.Tenant.fromJson(data) as T;
    }
    if (t == _i237.TenantSupportMember) {
      return _i237.TenantSupportMember.fromJson(data) as T;
    }
    if (t == _i238.TenantSupportMemberView) {
      return _i238.TenantSupportMemberView.fromJson(data) as T;
    }
    if (t == _i239.ThreadReadState) {
      return _i239.ThreadReadState.fromJson(data) as T;
    }
    if (t == _i240.Ticket) {
      return _i240.Ticket.fromJson(data) as T;
    }
    if (t == _i241.TicketEvent) {
      return _i241.TicketEvent.fromJson(data) as T;
    }
    if (t == _i242.TicketView) {
      return _i242.TicketView.fromJson(data) as T;
    }
    if (t == _i243.TrustRedeemResult) {
      return _i243.TrustRedeemResult.fromJson(data) as T;
    }
    if (t == _i244.TrustToken) {
      return _i244.TrustToken.fromJson(data) as T;
    }
    if (t == _i245.TrustTokenIssued) {
      return _i245.TrustTokenIssued.fromJson(data) as T;
    }
    if (t == _i246.TurnCredentials) {
      return _i246.TurnCredentials.fromJson(data) as T;
    }
    if (t == _i247.WebhookDelivery) {
      return _i247.WebhookDelivery.fromJson(data) as T;
    }
    if (t == _i248.WebhookEventMessage) {
      return _i248.WebhookEventMessage.fromJson(data) as T;
    }
    if (t == _i249.WebhookSubscription) {
      return _i249.WebhookSubscription.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Announcement?>()) {
      return (data != null ? _i2.Announcement.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AnnouncementRecipient?>()) {
      return (data != null ? _i3.AnnouncementRecipient.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i4.AnnouncementSeen?>()) {
      return (data != null ? _i4.AnnouncementSeen.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.AnnouncementView?>()) {
      return (data != null ? _i5.AnnouncementView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.AttachmentBytes?>()) {
      return (data != null ? _i6.AttachmentBytes.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.AttachmentObject?>()) {
      return (data != null ? _i7.AttachmentObject.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.AttachmentPlacement?>()) {
      return (data != null ? _i8.AttachmentPlacement.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.AttachmentRef?>()) {
      return (data != null ? _i9.AttachmentRef.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.AttachmentUrl?>()) {
      return (data != null ? _i10.AttachmentUrl.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.AvailableBot?>()) {
      return (data != null ? _i11.AvailableBot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.Bot?>()) {
      return (data != null ? _i12.Bot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.BotAuditEvent?>()) {
      return (data != null ? _i13.BotAuditEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.BotChannelHealth?>()) {
      return (data != null ? _i14.BotChannelHealth.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.BotCommand?>()) {
      return (data != null ? _i15.BotCommand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.BotIntegrationCreated?>()) {
      return (data != null ? _i16.BotIntegrationCreated.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i17.BotIntegrationView?>()) {
      return (data != null ? _i17.BotIntegrationView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i18.BotReadModeResult?>()) {
      return (data != null ? _i18.BotReadModeResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.CallHistoryEntry?>()) {
      return (data != null ? _i19.CallHistoryEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.CallIceCandidate?>()) {
      return (data != null ? _i20.CallIceCandidate.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.ChatFolderRecord?>()) {
      return (data != null ? _i21.ChatFolderRecord.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.ChatFolderRoom?>()) {
      return (data != null ? _i22.ChatFolderRoom.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.ChatFolderView?>()) {
      return (data != null ? _i23.ChatFolderView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.Conference?>()) {
      return (data != null ? _i24.Conference.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.ConferenceMember?>()) {
      return (data != null ? _i25.ConferenceMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.ConferenceParticipant?>()) {
      return (data != null ? _i26.ConferenceParticipant.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i27.ConferenceScreenShare?>()) {
      return (data != null ? _i27.ConferenceScreenShare.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i28.ConferenceState?>()) {
      return (data != null ? _i28.ConferenceState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.ConnectIssuedToken?>()) {
      return (data != null ? _i29.ConnectIssuedToken.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i30.ConnectIssuedTokenResult?>()) {
      return (data != null
              ? _i30.ConnectIssuedTokenResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i31.ConnectKeyAuditEvent?>()) {
      return (data != null ? _i31.ConnectKeyAuditEvent.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i32.ConnectTenantStatus?>()) {
      return (data != null ? _i32.ConnectTenantStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i33.ContactBlock?>()) {
      return (data != null ? _i33.ContactBlock.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i34.ContactCard?>()) {
      return (data != null ? _i34.ContactCard.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i35.ContactCardInfo?>()) {
      return (data != null ? _i35.ContactCardInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i36.ContactLabel?>()) {
      return (data != null ? _i36.ContactLabel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i37.ContactLabelAssignment?>()) {
      return (data != null ? _i37.ContactLabelAssignment.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i38.ContactLink?>()) {
      return (data != null ? _i38.ContactLink.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i39.ContactMeta?>()) {
      return (data != null ? _i39.ContactMeta.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i40.ContactProfileView?>()) {
      return (data != null ? _i40.ContactProfileView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i41.ContactRelation?>()) {
      return (data != null ? _i41.ContactRelation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i42.ContactRequest?>()) {
      return (data != null ? _i42.ContactRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i43.ContactRequestView?>()) {
      return (data != null ? _i43.ContactRequestView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i44.CrmAccessDenied?>()) {
      return (data != null ? _i44.CrmAccessDenied.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i45.CrmActivityType?>()) {
      return (data != null ? _i45.CrmActivityType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i46.CrmActivityView?>()) {
      return (data != null ? _i46.CrmActivityView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i47.CrmActorKind?>()) {
      return (data != null ? _i47.CrmActorKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i48.CrmBridgeNotConfigured?>()) {
      return (data != null ? _i48.CrmBridgeNotConfigured.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i49.CrmChangeOperation?>()) {
      return (data != null ? _i49.CrmChangeOperation.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i50.CrmChangeView?>()) {
      return (data != null ? _i50.CrmChangeView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i51.CrmChangesetStatus?>()) {
      return (data != null ? _i51.CrmChangesetStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i52.CrmChangesetView?>()) {
      return (data != null ? _i52.CrmChangesetView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i53.CrmCompanyDetails?>()) {
      return (data != null ? _i53.CrmCompanyDetails.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i54.CrmCompanyKind?>()) {
      return (data != null ? _i54.CrmCompanyKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i55.CrmCompanyStatus?>()) {
      return (data != null ? _i55.CrmCompanyStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i56.CrmCompanyView?>()) {
      return (data != null ? _i56.CrmCompanyView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i57.CrmConfirmationRequired?>()) {
      return (data != null ? _i57.CrmConfirmationRequired.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i58.CrmContactView?>()) {
      return (data != null ? _i58.CrmContactView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i59.CrmDealPage?>()) {
      return (data != null ? _i59.CrmDealPage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i60.CrmDealView?>()) {
      return (data != null ? _i60.CrmDealView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i61.CrmDigest?>()) {
      return (data != null ? _i61.CrmDigest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i62.CrmDocumentKind?>()) {
      return (data != null ? _i62.CrmDocumentKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i63.CrmDocumentView?>()) {
      return (data != null ? _i63.CrmDocumentView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i64.CrmEntityKind?>()) {
      return (data != null ? _i64.CrmEntityKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i65.CrmInputInvalid?>()) {
      return (data != null ? _i65.CrmInputInvalid.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i66.CrmMetricView?>()) {
      return (data != null ? _i66.CrmMetricView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i67.CrmNextStepState?>()) {
      return (data != null ? _i67.CrmNextStepState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i68.CrmPdBasis?>()) {
      return (data != null ? _i68.CrmPdBasis.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i69.CrmPersonalGrantView?>()) {
      return (data != null ? _i69.CrmPersonalGrantView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i70.CrmPipelineInUse?>()) {
      return (data != null ? _i70.CrmPipelineInUse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i71.CrmPipelineInvalid?>()) {
      return (data != null ? _i71.CrmPipelineInvalid.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i72.CrmProposal?>()) {
      return (data != null ? _i72.CrmProposal.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i73.CrmProposalStale?>()) {
      return (data != null ? _i73.CrmProposalStale.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i74.CrmSegmentRole?>()) {
      return (data != null ? _i74.CrmSegmentRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i75.CrmStageCount?>()) {
      return (data != null ? _i75.CrmStageCount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i76.CrmStageInUse?>()) {
      return (data != null ? _i76.CrmStageInUse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i77.CrmStageKind?>()) {
      return (data != null ? _i77.CrmStageKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i78.CrmStageOrderConflict?>()) {
      return (data != null ? _i78.CrmStageOrderConflict.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i79.CrmUserView?>()) {
      return (data != null ? _i79.CrmUserView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i80.CrmVersionConflict?>()) {
      return (data != null ? _i80.CrmVersionConflict.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i81.CrmVersionConflictItem?>()) {
      return (data != null ? _i81.CrmVersionConflictItem.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i82.DeliveryJournalEntry?>()) {
      return (data != null ? _i82.DeliveryJournalEntry.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i83.DeliveryJournalPage?>()) {
      return (data != null ? _i83.DeliveryJournalPage.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i84.DeliveryPending?>()) {
      return (data != null ? _i84.DeliveryPending.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i85.DeliveryRecipientState?>()) {
      return (data != null ? _i85.DeliveryRecipientState.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i86.DeliveryRecipientStatus?>()) {
      return (data != null ? _i86.DeliveryRecipientStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i87.DeliverySilentPage?>()) {
      return (data != null ? _i87.DeliverySilentPage.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i88.DeliverySilentRecipient?>()) {
      return (data != null ? _i88.DeliverySilentRecipient.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i89.DeliveryUsage?>()) {
      return (data != null ? _i89.DeliveryUsage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i90.DeviceRegistration?>()) {
      return (data != null ? _i90.DeviceRegistration.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i91.DeviceRegistrationRemoval?>()) {
      return (data != null
              ? _i91.DeviceRegistrationRemoval.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i92.DeviceSessionInfo?>()) {
      return (data != null ? _i92.DeviceSessionInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i93.EmailAccount?>()) {
      return (data != null ? _i93.EmailAccount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i94.EmailSession?>()) {
      return (data != null ? _i94.EmailSession.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i95.EmailVerificationCode?>()) {
      return (data != null ? _i95.EmailVerificationCode.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i96.AttachmentRejectReason?>()) {
      return (data != null ? _i96.AttachmentRejectReason.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i97.CallEventType?>()) {
      return (data != null ? _i97.CallEventType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i98.CallStatus?>()) {
      return (data != null ? _i98.CallStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i99.ContactLinkSource?>()) {
      return (data != null ? _i99.ContactLinkSource.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i100.ContactRequestStatus?>()) {
      return (data != null ? _i100.ContactRequestStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i101.DevicePlatform?>()) {
      return (data != null ? _i101.DevicePlatform.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i102.DeviceRemovalReason?>()) {
      return (data != null ? _i102.DeviceRemovalReason.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i103.IdentityProvider?>()) {
      return (data != null ? _i103.IdentityProvider.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i104.MessengerEventType?>()) {
      return (data != null ? _i104.MessengerEventType.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i105.ParticipantKind?>()) {
      return (data != null ? _i105.ParticipantKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i106.ProductNotificationStatus?>()) {
      return (data != null
              ? _i106.ProductNotificationStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i107.PushService?>()) {
      return (data != null ? _i107.PushService.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i108.RoomMemberRole?>()) {
      return (data != null ? _i108.RoomMemberRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i109.RoomOwnership?>()) {
      return (data != null ? _i109.RoomOwnership.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i110.RoomState?>()) {
      return (data != null ? _i110.RoomState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i111.RoomType?>()) {
      return (data != null ? _i111.RoomType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i112.SupportTeamRole?>()) {
      return (data != null ? _i112.SupportTeamRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i113.TeamKind?>()) {
      return (data != null ? _i113.TeamKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i114.TeamMemberRole?>()) {
      return (data != null ? _i114.TeamMemberRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i115.TenantHostingMode?>()) {
      return (data != null ? _i115.TenantHostingMode.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i116.TrustTokenKind?>()) {
      return (data != null ? _i116.TrustTokenKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i117.AdapterNotConfiguredException?>()) {
      return (data != null
              ? _i117.AdapterNotConfiguredException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i118.AmbiguousProductKeyException?>()) {
      return (data != null
              ? _i118.AmbiguousProductKeyException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i119.AttachmentAccessDeniedException?>()) {
      return (data != null
              ? _i119.AttachmentAccessDeniedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i120.AttachmentRejectedException?>()) {
      return (data != null
              ? _i120.AttachmentRejectedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i121.BotCapabilityException?>()) {
      return (data != null ? _i121.BotCapabilityException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i122.BotLimitExceededException?>()) {
      return (data != null
              ? _i122.BotLimitExceededException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i123.BotNotFoundException?>()) {
      return (data != null ? _i123.BotNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i124.BotReadRestrictedException?>()) {
      return (data != null
              ? _i124.BotReadRestrictedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i125.ConferenceFullException?>()) {
      return (data != null
              ? _i125.ConferenceFullException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i126.EmailAuthException?>()) {
      return (data != null ? _i126.EmailAuthException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i127.InsufficientPowerException?>()) {
      return (data != null
              ? _i127.InsufficientPowerException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i128.InvalidBotCommandsException?>()) {
      return (data != null
              ? _i128.InvalidBotCommandsException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i129.InvalidExternalKeyException?>()) {
      return (data != null
              ? _i129.InvalidExternalKeyException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i130.InvalidNotificationException?>()) {
      return (data != null
              ? _i130.InvalidNotificationException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i131.InvalidTokenException?>()) {
      return (data != null ? _i131.InvalidTokenException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i132.LastOwnerCannotDemoteException?>()) {
      return (data != null
              ? _i132.LastOwnerCannotDemoteException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i133.MessageBodyTooLargeException?>()) {
      return (data != null
              ? _i133.MessageBodyTooLargeException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i134.MessageDeletedException?>()) {
      return (data != null
              ? _i134.MessageDeletedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i135.MessageNotEditableException?>()) {
      return (data != null
              ? _i135.MessageNotEditableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i136.MessengerNotAuthenticatedException?>()) {
      return (data != null
              ? _i136.MessengerNotAuthenticatedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i137.NotObjectRoomException?>()) {
      return (data != null ? _i137.NotObjectRoomException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i138.NotSupportTeamMemberException?>()) {
      return (data != null
              ? _i138.NotSupportTeamMemberException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i139.NotSupportTeamOwnerException?>()) {
      return (data != null
              ? _i139.NotSupportTeamOwnerException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i140.NotificationInProgressException?>()) {
      return (data != null
              ? _i140.NotificationInProgressException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i141.OperatorEmailNotResolvedException?>()) {
      return (data != null
              ? _i141.OperatorEmailNotResolvedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i142.PeerUnavailableException?>()) {
      return (data != null
              ? _i142.PeerUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i143.ProbeTargetNotAllowedException?>()) {
      return (data != null
              ? _i143.ProbeTargetNotAllowedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i144.ProductAlreadyExistsException?>()) {
      return (data != null
              ? _i144.ProductAlreadyExistsException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i145.ProductInUseException?>()) {
      return (data != null ? _i145.ProductInUseException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i146.ProductNotFoundException?>()) {
      return (data != null
              ? _i146.ProductNotFoundException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i147.ProductNotFoundForCallerException?>()) {
      return (data != null
              ? _i147.ProductNotFoundForCallerException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i148.RateLimitExceededException?>()) {
      return (data != null
              ? _i148.RateLimitExceededException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i149.RoomCapacityExceededException?>()) {
      return (data != null
              ? _i149.RoomCapacityExceededException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i150.RoomDissolvePartialException?>()) {
      return (data != null
              ? _i150.RoomDissolvePartialException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i151.RoomUnavailableException?>()) {
      return (data != null
              ? _i151.RoomUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i152.ScreenShareBusyException?>()) {
      return (data != null
              ? _i152.ScreenShareBusyException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i153.StickerRejectedException?>()) {
      return (data != null
              ? _i153.StickerRejectedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i154.TaskIntegrationNotConfiguredException?>()) {
      return (data != null
              ? _i154.TaskIntegrationNotConfiguredException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i155.TeamAccessDeniedException?>()) {
      return (data != null
              ? _i155.TeamAccessDeniedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i156.TeamPeerUnknownException?>()) {
      return (data != null
              ? _i156.TeamPeerUnknownException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i157.TenantAlreadyExistsException?>()) {
      return (data != null
              ? _i157.TenantAlreadyExistsException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i158.TenantNotFoundException?>()) {
      return (data != null
              ? _i158.TenantNotFoundException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i159.ThumbnailUnavailableException?>()) {
      return (data != null
              ? _i159.ThumbnailUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i160.WebhookSubscriptionException?>()) {
      return (data != null
              ? _i160.WebhookSubscriptionException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i161.WriteBannedException?>()) {
      return (data != null ? _i161.WriteBannedException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i162.EscalationResult?>()) {
      return (data != null ? _i162.EscalationResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i163.Greeting?>()) {
      return (data != null ? _i163.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i164.IdentityMapping?>()) {
      return (data != null ? _i164.IdentityMapping.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i165.IncomingWebhook?>()) {
      return (data != null ? _i165.IncomingWebhook.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i166.IncomingWebhookCreated?>()) {
      return (data != null ? _i166.IncomingWebhookCreated.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i167.LinkPreview?>()) {
      return (data != null ? _i167.LinkPreview.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i168.LinkPreviewView?>()) {
      return (data != null ? _i168.LinkPreviewView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i169.MessageIndex?>()) {
      return (data != null ? _i169.MessageIndex.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i170.MessengerAuthContext?>()) {
      return (data != null ? _i170.MessengerAuthContext.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i171.MessengerEvent?>()) {
      return (data != null ? _i171.MessengerEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i172.MessengerMessage?>()) {
      return (data != null ? _i172.MessengerMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i173.MessengerMessageListPage?>()) {
      return (data != null
              ? _i173.MessengerMessageListPage.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i174.MessengerSession?>()) {
      return (data != null ? _i174.MessengerSession.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i175.MessengerSessionToken?>()) {
      return (data != null ? _i175.MessengerSessionToken.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i176.MessengerUser?>()) {
      return (data != null ? _i176.MessengerUser.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i177.NearbyConfirmResult?>()) {
      return (data != null ? _i177.NearbyConfirmResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i178.NearbyConfirmation?>()) {
      return (data != null ? _i178.NearbyConfirmation.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i179.NotificationSettings?>()) {
      return (data != null ? _i179.NotificationSettings.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i180.PresenceConnState?>()) {
      return (data != null ? _i180.PresenceConnState.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i181.PresenceInfo?>()) {
      return (data != null ? _i181.PresenceInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i182.PresenceState?>()) {
      return (data != null ? _i182.PresenceState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i183.PresenceWatchedIndex?>()) {
      return (data != null ? _i183.PresenceWatchedIndex.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i184.PresenceWatchers?>()) {
      return (data != null ? _i184.PresenceWatchers.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i185.Product?>()) {
      return (data != null ? _i185.Product.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i186.ProductAdminView?>()) {
      return (data != null ? _i186.ProductAdminView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i187.ProductAnnouncementView?>()) {
      return (data != null
              ? _i187.ProductAnnouncementView.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i188.ProductDeliveryHealth?>()) {
      return (data != null ? _i188.ProductDeliveryHealth.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i189.ProductNotification?>()) {
      return (data != null ? _i189.ProductNotification.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i190.ProductNotificationRecipientResult?>()) {
      return (data != null
              ? _i190.ProductNotificationRecipientResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i191.ProductNotificationSendResult?>()) {
      return (data != null
              ? _i191.ProductNotificationSendResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i192.ProductObjectRoom?>()) {
      return (data != null ? _i192.ProductObjectRoom.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i193.ProfileTranslation?>()) {
      return (data != null ? _i193.ProfileTranslation.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i194.PulseAccessAuditEvent?>()) {
      return (data != null ? _i194.PulseAccessAuditEvent.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i195.PulseAccessEntry?>()) {
      return (data != null ? _i195.PulseAccessEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i196.PulseAlertRule?>()) {
      return (data != null ? _i196.PulseAlertRule.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i197.PulseEvent?>()) {
      return (data != null ? _i197.PulseEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i198.PulseExpiryReminder?>()) {
      return (data != null ? _i198.PulseExpiryReminder.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i199.PulseFolder?>()) {
      return (data != null ? _i199.PulseFolder.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i200.PulseFolderMembership?>()) {
      return (data != null ? _i200.PulseFolderMembership.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i201.PulseIncident?>()) {
      return (data != null ? _i201.PulseIncident.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i202.PulseMemberView?>()) {
      return (data != null ? _i202.PulseMemberView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i203.PulseMonitor?>()) {
      return (data != null ? _i203.PulseMonitor.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i204.PulseMonitorCreated?>()) {
      return (data != null ? _i204.PulseMonitorCreated.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i205.PulseMonitorMembership?>()) {
      return (data != null ? _i205.PulseMonitorMembership.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i206.PulseProbeAllowlistEntry?>()) {
      return (data != null
              ? _i206.PulseProbeAllowlistEntry.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i207.PulseTlsProbe?>()) {
      return (data != null ? _i207.PulseTlsProbe.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i208.PulseValueThreshold?>()) {
      return (data != null ? _i208.PulseValueThreshold.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i209.PushQueueMessage?>()) {
      return (data != null ? _i209.PushQueueMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i210.PushTestJob?>()) {
      return (data != null ? _i210.PushTestJob.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i211.PushTestResult?>()) {
      return (data != null ? _i211.PushTestResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i212.Room?>()) {
      return (data != null ? _i212.Room.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i213.RoomBotCommands?>()) {
      return (data != null ? _i213.RoomBotCommands.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i214.RoomDeliveryBackstop?>()) {
      return (data != null ? _i214.RoomDeliveryBackstop.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i215.RoomDetails?>()) {
      return (data != null ? _i215.RoomDetails.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i216.RoomListPage?>()) {
      return (data != null ? _i216.RoomListPage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i217.RoomMembership?>()) {
      return (data != null ? _i217.RoomMembership.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i218.RoomParticipant?>()) {
      return (data != null ? _i218.RoomParticipant.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i219.RoomSummary?>()) {
      return (data != null ? _i219.RoomSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i220.RoomTaskStats?>()) {
      return (data != null ? _i220.RoomTaskStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i221.RoomTaskView?>()) {
      return (data != null ? _i221.RoomTaskView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i222.Sticker?>()) {
      return (data != null ? _i222.Sticker.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i223.StickerPack?>()) {
      return (data != null ? _i223.StickerPack.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i224.StickerPackView?>()) {
      return (data != null ? _i224.StickerPackView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i225.SupportTeam?>()) {
      return (data != null ? _i225.SupportTeam.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i226.SupportTeamExclusion?>()) {
      return (data != null ? _i226.SupportTeamExclusion.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i227.SupportTeamMember?>()) {
      return (data != null ? _i227.SupportTeamMember.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i228.SupportTeamMemberView?>()) {
      return (data != null ? _i228.SupportTeamMemberView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i229.SupportTeamView?>()) {
      return (data != null ? _i229.SupportTeamView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i230.TaskLink?>()) {
      return (data != null ? _i230.TaskLink.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i231.TaskManagerConfig?>()) {
      return (data != null ? _i231.TaskManagerConfig.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i232.Team?>()) {
      return (data != null ? _i232.Team.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i233.TeamMember?>()) {
      return (data != null ? _i233.TeamMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i234.TeamMemberView?>()) {
      return (data != null ? _i234.TeamMemberView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i235.TeamView?>()) {
      return (data != null ? _i235.TeamView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i236.Tenant?>()) {
      return (data != null ? _i236.Tenant.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i237.TenantSupportMember?>()) {
      return (data != null ? _i237.TenantSupportMember.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i238.TenantSupportMemberView?>()) {
      return (data != null
              ? _i238.TenantSupportMemberView.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i239.ThreadReadState?>()) {
      return (data != null ? _i239.ThreadReadState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i240.Ticket?>()) {
      return (data != null ? _i240.Ticket.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i241.TicketEvent?>()) {
      return (data != null ? _i241.TicketEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i242.TicketView?>()) {
      return (data != null ? _i242.TicketView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i243.TrustRedeemResult?>()) {
      return (data != null ? _i243.TrustRedeemResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i244.TrustToken?>()) {
      return (data != null ? _i244.TrustToken.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i245.TrustTokenIssued?>()) {
      return (data != null ? _i245.TrustTokenIssued.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i246.TurnCredentials?>()) {
      return (data != null ? _i246.TurnCredentials.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i247.WebhookDelivery?>()) {
      return (data != null ? _i247.WebhookDelivery.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i248.WebhookEventMessage?>()) {
      return (data != null ? _i248.WebhookEventMessage.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i249.WebhookSubscription?>()) {
      return (data != null ? _i249.WebhookSubscription.fromJson(data) : null)
          as T;
    }
    if (t == List<_i15.BotCommand>) {
      return (data as List).map((e) => deserialize<_i15.BotCommand>(e)).toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i25.ConferenceMember>) {
      return (data as List)
              .map((e) => deserialize<_i25.ConferenceMember>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i50.CrmChangeView>) {
      return (data as List)
              .map((e) => deserialize<_i50.CrmChangeView>(e))
              .toList()
          as T;
    }
    if (t == List<_i60.CrmDealView>) {
      return (data as List)
              .map((e) => deserialize<_i60.CrmDealView>(e))
              .toList()
          as T;
    }
    if (t == List<_i58.CrmContactView>) {
      return (data as List)
              .map((e) => deserialize<_i58.CrmContactView>(e))
              .toList()
          as T;
    }
    if (t == List<_i46.CrmActivityView>) {
      return (data as List)
              .map((e) => deserialize<_i46.CrmActivityView>(e))
              .toList()
          as T;
    }
    if (t == List<_i63.CrmDocumentView>) {
      return (data as List)
              .map((e) => deserialize<_i63.CrmDocumentView>(e))
              .toList()
          as T;
    }
    if (t == List<_i79.CrmUserView>) {
      return (data as List)
              .map((e) => deserialize<_i79.CrmUserView>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i79.CrmUserView>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i79.CrmUserView>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i66.CrmMetricView>) {
      return (data as List)
              .map((e) => deserialize<_i66.CrmMetricView>(e))
              .toList()
          as T;
    }
    if (t == List<_i75.CrmStageCount>) {
      return (data as List)
              .map((e) => deserialize<_i75.CrmStageCount>(e))
              .toList()
          as T;
    }
    if (t == List<_i82.DeliveryJournalEntry>) {
      return (data as List)
              .map((e) => deserialize<_i82.DeliveryJournalEntry>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i88.DeliverySilentRecipient>) {
      return (data as List)
              .map((e) => deserialize<_i88.DeliverySilentRecipient>(e))
              .toList()
          as T;
    }
    if (t == List<_i20.CallIceCandidate>) {
      return (data as List)
              .map((e) => deserialize<_i20.CallIceCandidate>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i20.CallIceCandidate>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i20.CallIceCandidate>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == _i1.getType<List<_i25.ConferenceMember>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i25.ConferenceMember>(e))
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
    if (t == List<_i172.MessengerMessage>) {
      return (data as List)
              .map((e) => deserialize<_i172.MessengerMessage>(e))
              .toList()
          as T;
    }
    if (t == List<_i190.ProductNotificationRecipientResult>) {
      return (data as List)
              .map(
                (e) => deserialize<_i190.ProductNotificationRecipientResult>(e),
              )
              .toList()
          as T;
    }
    if (t == List<_i218.RoomParticipant>) {
      return (data as List)
              .map((e) => deserialize<_i218.RoomParticipant>(e))
              .toList()
          as T;
    }
    if (t == List<_i219.RoomSummary>) {
      return (data as List)
              .map((e) => deserialize<_i219.RoomSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i222.Sticker>) {
      return (data as List).map((e) => deserialize<_i222.Sticker>(e)).toList()
          as T;
    }
    if (t == List<_i228.SupportTeamMemberView>) {
      return (data as List)
              .map((e) => deserialize<_i228.SupportTeamMemberView>(e))
              .toList()
          as T;
    }
    if (t == List<_i250.WebhookSubscription>) {
      return (data as List)
              .map((e) => deserialize<_i250.WebhookSubscription>(e))
              .toList()
          as T;
    }
    if (t == List<_i251.WebhookDelivery>) {
      return (data as List)
              .map((e) => deserialize<_i251.WebhookDelivery>(e))
              .toList()
          as T;
    }
    if (t == List<_i252.Announcement>) {
      return (data as List)
              .map((e) => deserialize<_i252.Announcement>(e))
              .toList()
          as T;
    }
    if (t == List<_i253.BotAuditEvent>) {
      return (data as List)
              .map((e) => deserialize<_i253.BotAuditEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i254.Bot>) {
      return (data as List).map((e) => deserialize<_i254.Bot>(e)).toList() as T;
    }
    if (t == List<_i255.RoomSummary>) {
      return (data as List)
              .map((e) => deserialize<_i255.RoomSummary>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i256.AvailableBot>) {
      return (data as List)
              .map((e) => deserialize<_i256.AvailableBot>(e))
              .toList()
          as T;
    }
    if (t == List<_i257.BotIntegrationView>) {
      return (data as List)
              .map((e) => deserialize<_i257.BotIntegrationView>(e))
              .toList()
          as T;
    }
    if (t == List<_i258.ConnectTenantStatus>) {
      return (data as List)
              .map((e) => deserialize<_i258.ConnectTenantStatus>(e))
              .toList()
          as T;
    }
    if (t == List<_i259.ProductDeliveryHealth>) {
      return (data as List)
              .map((e) => deserialize<_i259.ProductDeliveryHealth>(e))
              .toList()
          as T;
    }
    if (t == List<_i260.TenantSupportMemberView>) {
      return (data as List)
              .map((e) => deserialize<_i260.TenantSupportMemberView>(e))
              .toList()
          as T;
    }
    if (t == List<_i261.ProductAdminView>) {
      return (data as List)
              .map((e) => deserialize<_i261.ProductAdminView>(e))
              .toList()
          as T;
    }
    if (t == List<_i262.ConnectKeyAuditEvent>) {
      return (data as List)
              .map((e) => deserialize<_i262.ConnectKeyAuditEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i263.TeamView>) {
      return (data as List).map((e) => deserialize<_i263.TeamView>(e)).toList()
          as T;
    }
    if (t == List<_i264.TeamMemberView>) {
      return (data as List)
              .map((e) => deserialize<_i264.TeamMemberView>(e))
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
    if (t == List<_i265.CrmUserView>) {
      return (data as List)
              .map((e) => deserialize<_i265.CrmUserView>(e))
              .toList()
          as T;
    }
    if (t == List<_i266.CrmPersonalGrantView>) {
      return (data as List)
              .map((e) => deserialize<_i266.CrmPersonalGrantView>(e))
              .toList()
          as T;
    }
    if (t == List<_i267.CrmCompanyView>) {
      return (data as List)
              .map((e) => deserialize<_i267.CrmCompanyView>(e))
              .toList()
          as T;
    }
    if (t == List<_i268.CrmContactView>) {
      return (data as List)
              .map((e) => deserialize<_i268.CrmContactView>(e))
              .toList()
          as T;
    }
    if (t == List<_i269.CrmEntityKind>) {
      return (data as List)
              .map((e) => deserialize<_i269.CrmEntityKind>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i269.CrmEntityKind>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i269.CrmEntityKind>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i270.CrmDealView>) {
      return (data as List)
              .map((e) => deserialize<_i270.CrmDealView>(e))
              .toList()
          as T;
    }
    if (t == List<_i271.CrmActivityView>) {
      return (data as List)
              .map((e) => deserialize<_i271.CrmActivityView>(e))
              .toList()
          as T;
    }
    if (t == List<_i272.DeliveryRecipientStatus>) {
      return (data as List)
              .map((e) => deserialize<_i272.DeliveryRecipientStatus>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i273.DeviceSessionInfo>) {
      return (data as List)
              .map((e) => deserialize<_i273.DeviceSessionInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i274.IncomingWebhook>) {
      return (data as List)
              .map((e) => deserialize<_i274.IncomingWebhook>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i275.BotCommand>) {
      return (data as List)
              .map((e) => deserialize<_i275.BotCommand>(e))
              .toList()
          as T;
    }
    if (t == List<_i276.RoomBotCommands>) {
      return (data as List)
              .map((e) => deserialize<_i276.RoomBotCommands>(e))
              .toList()
          as T;
    }
    if (t == List<_i277.MessengerMessage>) {
      return (data as List)
              .map((e) => deserialize<_i277.MessengerMessage>(e))
              .toList()
          as T;
    }
    if (t == List<_i278.CallIceCandidate>) {
      return (data as List)
              .map((e) => deserialize<_i278.CallIceCandidate>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i278.CallIceCandidate>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i278.CallIceCandidate>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i279.CallHistoryEntry>) {
      return (data as List)
              .map((e) => deserialize<_i279.CallHistoryEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i280.MessengerEvent>) {
      return (data as List)
              .map((e) => deserialize<_i280.MessengerEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i281.LinkPreviewView>) {
      return (data as List)
              .map((e) => deserialize<_i281.LinkPreviewView>(e))
              .toList()
          as T;
    }
    if (t == List<_i282.RoomParticipant>) {
      return (data as List)
              .map((e) => deserialize<_i282.RoomParticipant>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i283.TicketView>) {
      return (data as List)
              .map((e) => deserialize<_i283.TicketView>(e))
              .toList()
          as T;
    }
    if (t == List<_i284.AnnouncementView>) {
      return (data as List)
              .map((e) => deserialize<_i284.AnnouncementView>(e))
              .toList()
          as T;
    }
    if (t == List<_i285.RoomTaskView>) {
      return (data as List)
              .map((e) => deserialize<_i285.RoomTaskView>(e))
              .toList()
          as T;
    }
    if (t == List<_i286.PresenceInfo>) {
      return (data as List)
              .map((e) => deserialize<_i286.PresenceInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i287.ChatFolderView>) {
      return (data as List)
              .map((e) => deserialize<_i287.ChatFolderView>(e))
              .toList()
          as T;
    }
    if (t == List<_i288.ContactRequestView>) {
      return (data as List)
              .map((e) => deserialize<_i288.ContactRequestView>(e))
              .toList()
          as T;
    }
    if (t == List<_i289.ContactLabel>) {
      return (data as List)
              .map((e) => deserialize<_i289.ContactLabel>(e))
              .toList()
          as T;
    }
    if (t == List<_i290.ContactLabelAssignment>) {
      return (data as List)
              .map((e) => deserialize<_i290.ContactLabelAssignment>(e))
              .toList()
          as T;
    }
    if (t == List<_i291.ProductObjectRoom>) {
      return (data as List)
              .map((e) => deserialize<_i291.ProductObjectRoom>(e))
              .toList()
          as T;
    }
    if (t == List<_i292.Product>) {
      return (data as List).map((e) => deserialize<_i292.Product>(e)).toList()
          as T;
    }
    if (t == List<_i293.ProfileTranslation>) {
      return (data as List)
              .map((e) => deserialize<_i293.ProfileTranslation>(e))
              .toList()
          as T;
    }
    if (t == Map<String, int>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<int>(v)),
          )
          as T;
    }
    if (t == List<_i294.ProductAnnouncementView>) {
      return (data as List)
              .map((e) => deserialize<_i294.ProductAnnouncementView>(e))
              .toList()
          as T;
    }
    if (t == List<_i295.PulseFolder>) {
      return (data as List)
              .map((e) => deserialize<_i295.PulseFolder>(e))
              .toList()
          as T;
    }
    if (t == List<_i296.PulseMonitor>) {
      return (data as List)
              .map((e) => deserialize<_i296.PulseMonitor>(e))
              .toList()
          as T;
    }
    if (t == List<_i297.PulseAlertRule>) {
      return (data as List)
              .map((e) => deserialize<_i297.PulseAlertRule>(e))
              .toList()
          as T;
    }
    if (t == List<_i298.PulseIncident>) {
      return (data as List)
              .map((e) => deserialize<_i298.PulseIncident>(e))
              .toList()
          as T;
    }
    if (t == List<_i299.PulseAccessEntry>) {
      return (data as List)
              .map((e) => deserialize<_i299.PulseAccessEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i300.PulseMemberView>) {
      return (data as List)
              .map((e) => deserialize<_i300.PulseMemberView>(e))
              .toList()
          as T;
    }
    if (t == List<_i301.PulseAccessAuditEvent>) {
      return (data as List)
              .map((e) => deserialize<_i301.PulseAccessAuditEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i302.PulseTlsProbe>) {
      return (data as List)
              .map((e) => deserialize<_i302.PulseTlsProbe>(e))
              .toList()
          as T;
    }
    if (t == List<_i303.PulseValueThreshold>) {
      return (data as List)
              .map((e) => deserialize<_i303.PulseValueThreshold>(e))
              .toList()
          as T;
    }
    if (t == List<_i304.PulseProbeAllowlistEntry>) {
      return (data as List)
              .map((e) => deserialize<_i304.PulseProbeAllowlistEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i305.StickerPackView>) {
      return (data as List)
              .map((e) => deserialize<_i305.StickerPackView>(e))
              .toList()
          as T;
    }
    try {
      return _i306.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i307.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.Announcement => 'Announcement',
      _i3.AnnouncementRecipient => 'AnnouncementRecipient',
      _i4.AnnouncementSeen => 'AnnouncementSeen',
      _i5.AnnouncementView => 'AnnouncementView',
      _i6.AttachmentBytes => 'AttachmentBytes',
      _i7.AttachmentObject => 'AttachmentObject',
      _i8.AttachmentPlacement => 'AttachmentPlacement',
      _i9.AttachmentRef => 'AttachmentRef',
      _i10.AttachmentUrl => 'AttachmentUrl',
      _i11.AvailableBot => 'AvailableBot',
      _i12.Bot => 'Bot',
      _i13.BotAuditEvent => 'BotAuditEvent',
      _i14.BotChannelHealth => 'BotChannelHealth',
      _i15.BotCommand => 'BotCommand',
      _i16.BotIntegrationCreated => 'BotIntegrationCreated',
      _i17.BotIntegrationView => 'BotIntegrationView',
      _i18.BotReadModeResult => 'BotReadModeResult',
      _i19.CallHistoryEntry => 'CallHistoryEntry',
      _i20.CallIceCandidate => 'CallIceCandidate',
      _i21.ChatFolderRecord => 'ChatFolderRecord',
      _i22.ChatFolderRoom => 'ChatFolderRoom',
      _i23.ChatFolderView => 'ChatFolderView',
      _i24.Conference => 'Conference',
      _i25.ConferenceMember => 'ConferenceMember',
      _i26.ConferenceParticipant => 'ConferenceParticipant',
      _i27.ConferenceScreenShare => 'ConferenceScreenShare',
      _i28.ConferenceState => 'ConferenceState',
      _i29.ConnectIssuedToken => 'ConnectIssuedToken',
      _i30.ConnectIssuedTokenResult => 'ConnectIssuedTokenResult',
      _i31.ConnectKeyAuditEvent => 'ConnectKeyAuditEvent',
      _i32.ConnectTenantStatus => 'ConnectTenantStatus',
      _i33.ContactBlock => 'ContactBlock',
      _i34.ContactCard => 'ContactCard',
      _i35.ContactCardInfo => 'ContactCardInfo',
      _i36.ContactLabel => 'ContactLabel',
      _i37.ContactLabelAssignment => 'ContactLabelAssignment',
      _i38.ContactLink => 'ContactLink',
      _i39.ContactMeta => 'ContactMeta',
      _i40.ContactProfileView => 'ContactProfileView',
      _i41.ContactRelation => 'ContactRelation',
      _i42.ContactRequest => 'ContactRequest',
      _i43.ContactRequestView => 'ContactRequestView',
      _i44.CrmAccessDenied => 'CrmAccessDenied',
      _i45.CrmActivityType => 'CrmActivityType',
      _i46.CrmActivityView => 'CrmActivityView',
      _i47.CrmActorKind => 'CrmActorKind',
      _i48.CrmBridgeNotConfigured => 'CrmBridgeNotConfigured',
      _i49.CrmChangeOperation => 'CrmChangeOperation',
      _i50.CrmChangeView => 'CrmChangeView',
      _i51.CrmChangesetStatus => 'CrmChangesetStatus',
      _i52.CrmChangesetView => 'CrmChangesetView',
      _i53.CrmCompanyDetails => 'CrmCompanyDetails',
      _i54.CrmCompanyKind => 'CrmCompanyKind',
      _i55.CrmCompanyStatus => 'CrmCompanyStatus',
      _i56.CrmCompanyView => 'CrmCompanyView',
      _i57.CrmConfirmationRequired => 'CrmConfirmationRequired',
      _i58.CrmContactView => 'CrmContactView',
      _i59.CrmDealPage => 'CrmDealPage',
      _i60.CrmDealView => 'CrmDealView',
      _i61.CrmDigest => 'CrmDigest',
      _i62.CrmDocumentKind => 'CrmDocumentKind',
      _i63.CrmDocumentView => 'CrmDocumentView',
      _i64.CrmEntityKind => 'CrmEntityKind',
      _i65.CrmInputInvalid => 'CrmInputInvalid',
      _i66.CrmMetricView => 'CrmMetricView',
      _i67.CrmNextStepState => 'CrmNextStepState',
      _i68.CrmPdBasis => 'CrmPdBasis',
      _i69.CrmPersonalGrantView => 'CrmPersonalGrantView',
      _i70.CrmPipelineInUse => 'CrmPipelineInUse',
      _i71.CrmPipelineInvalid => 'CrmPipelineInvalid',
      _i72.CrmProposal => 'CrmProposal',
      _i73.CrmProposalStale => 'CrmProposalStale',
      _i74.CrmSegmentRole => 'CrmSegmentRole',
      _i75.CrmStageCount => 'CrmStageCount',
      _i76.CrmStageInUse => 'CrmStageInUse',
      _i77.CrmStageKind => 'CrmStageKind',
      _i78.CrmStageOrderConflict => 'CrmStageOrderConflict',
      _i79.CrmUserView => 'CrmUserView',
      _i80.CrmVersionConflict => 'CrmVersionConflict',
      _i81.CrmVersionConflictItem => 'CrmVersionConflictItem',
      _i82.DeliveryJournalEntry => 'DeliveryJournalEntry',
      _i83.DeliveryJournalPage => 'DeliveryJournalPage',
      _i84.DeliveryPending => 'DeliveryPending',
      _i85.DeliveryRecipientState => 'DeliveryRecipientState',
      _i86.DeliveryRecipientStatus => 'DeliveryRecipientStatus',
      _i87.DeliverySilentPage => 'DeliverySilentPage',
      _i88.DeliverySilentRecipient => 'DeliverySilentRecipient',
      _i89.DeliveryUsage => 'DeliveryUsage',
      _i90.DeviceRegistration => 'DeviceRegistration',
      _i91.DeviceRegistrationRemoval => 'DeviceRegistrationRemoval',
      _i92.DeviceSessionInfo => 'DeviceSessionInfo',
      _i93.EmailAccount => 'EmailAccount',
      _i94.EmailSession => 'EmailSession',
      _i95.EmailVerificationCode => 'EmailVerificationCode',
      _i96.AttachmentRejectReason => 'AttachmentRejectReason',
      _i97.CallEventType => 'CallEventType',
      _i98.CallStatus => 'CallStatus',
      _i99.ContactLinkSource => 'ContactLinkSource',
      _i100.ContactRequestStatus => 'ContactRequestStatus',
      _i101.DevicePlatform => 'DevicePlatform',
      _i102.DeviceRemovalReason => 'DeviceRemovalReason',
      _i103.IdentityProvider => 'IdentityProvider',
      _i104.MessengerEventType => 'MessengerEventType',
      _i105.ParticipantKind => 'ParticipantKind',
      _i106.ProductNotificationStatus => 'ProductNotificationStatus',
      _i107.PushService => 'PushService',
      _i108.RoomMemberRole => 'RoomMemberRole',
      _i109.RoomOwnership => 'RoomOwnership',
      _i110.RoomState => 'RoomState',
      _i111.RoomType => 'RoomType',
      _i112.SupportTeamRole => 'SupportTeamRole',
      _i113.TeamKind => 'TeamKind',
      _i114.TeamMemberRole => 'TeamMemberRole',
      _i115.TenantHostingMode => 'TenantHostingMode',
      _i116.TrustTokenKind => 'TrustTokenKind',
      _i117.AdapterNotConfiguredException => 'AdapterNotConfiguredException',
      _i118.AmbiguousProductKeyException => 'AmbiguousProductKeyException',
      _i119.AttachmentAccessDeniedException =>
        'AttachmentAccessDeniedException',
      _i120.AttachmentRejectedException => 'AttachmentRejectedException',
      _i121.BotCapabilityException => 'BotCapabilityException',
      _i122.BotLimitExceededException => 'BotLimitExceededException',
      _i123.BotNotFoundException => 'BotNotFoundException',
      _i124.BotReadRestrictedException => 'BotReadRestrictedException',
      _i125.ConferenceFullException => 'ConferenceFullException',
      _i126.EmailAuthException => 'EmailAuthException',
      _i127.InsufficientPowerException => 'InsufficientPowerException',
      _i128.InvalidBotCommandsException => 'InvalidBotCommandsException',
      _i129.InvalidExternalKeyException => 'InvalidExternalKeyException',
      _i130.InvalidNotificationException => 'InvalidNotificationException',
      _i131.InvalidTokenException => 'InvalidTokenException',
      _i132.LastOwnerCannotDemoteException => 'LastOwnerCannotDemoteException',
      _i133.MessageBodyTooLargeException => 'MessageBodyTooLargeException',
      _i134.MessageDeletedException => 'MessageDeletedException',
      _i135.MessageNotEditableException => 'MessageNotEditableException',
      _i136.MessengerNotAuthenticatedException =>
        'MessengerNotAuthenticatedException',
      _i137.NotObjectRoomException => 'NotObjectRoomException',
      _i138.NotSupportTeamMemberException => 'NotSupportTeamMemberException',
      _i139.NotSupportTeamOwnerException => 'NotSupportTeamOwnerException',
      _i140.NotificationInProgressException =>
        'NotificationInProgressException',
      _i141.OperatorEmailNotResolvedException =>
        'OperatorEmailNotResolvedException',
      _i142.PeerUnavailableException => 'PeerUnavailableException',
      _i143.ProbeTargetNotAllowedException => 'ProbeTargetNotAllowedException',
      _i144.ProductAlreadyExistsException => 'ProductAlreadyExistsException',
      _i145.ProductInUseException => 'ProductInUseException',
      _i146.ProductNotFoundException => 'ProductNotFoundException',
      _i147.ProductNotFoundForCallerException =>
        'ProductNotFoundForCallerException',
      _i148.RateLimitExceededException => 'RateLimitExceededException',
      _i149.RoomCapacityExceededException => 'RoomCapacityExceededException',
      _i150.RoomDissolvePartialException => 'RoomDissolvePartialException',
      _i151.RoomUnavailableException => 'RoomUnavailableException',
      _i152.ScreenShareBusyException => 'ScreenShareBusyException',
      _i153.StickerRejectedException => 'StickerRejectedException',
      _i154.TaskIntegrationNotConfiguredException =>
        'TaskIntegrationNotConfiguredException',
      _i155.TeamAccessDeniedException => 'TeamAccessDeniedException',
      _i156.TeamPeerUnknownException => 'TeamPeerUnknownException',
      _i157.TenantAlreadyExistsException => 'TenantAlreadyExistsException',
      _i158.TenantNotFoundException => 'TenantNotFoundException',
      _i159.ThumbnailUnavailableException => 'ThumbnailUnavailableException',
      _i160.WebhookSubscriptionException => 'WebhookSubscriptionException',
      _i161.WriteBannedException => 'WriteBannedException',
      _i162.EscalationResult => 'EscalationResult',
      _i163.Greeting => 'Greeting',
      _i164.IdentityMapping => 'IdentityMapping',
      _i165.IncomingWebhook => 'IncomingWebhook',
      _i166.IncomingWebhookCreated => 'IncomingWebhookCreated',
      _i167.LinkPreview => 'LinkPreview',
      _i168.LinkPreviewView => 'LinkPreviewView',
      _i169.MessageIndex => 'MessageIndex',
      _i170.MessengerAuthContext => 'MessengerAuthContext',
      _i171.MessengerEvent => 'MessengerEvent',
      _i172.MessengerMessage => 'MessengerMessage',
      _i173.MessengerMessageListPage => 'MessengerMessageListPage',
      _i174.MessengerSession => 'MessengerSession',
      _i175.MessengerSessionToken => 'MessengerSessionToken',
      _i176.MessengerUser => 'MessengerUser',
      _i177.NearbyConfirmResult => 'NearbyConfirmResult',
      _i178.NearbyConfirmation => 'NearbyConfirmation',
      _i179.NotificationSettings => 'NotificationSettings',
      _i180.PresenceConnState => 'PresenceConnState',
      _i181.PresenceInfo => 'PresenceInfo',
      _i182.PresenceState => 'PresenceState',
      _i183.PresenceWatchedIndex => 'PresenceWatchedIndex',
      _i184.PresenceWatchers => 'PresenceWatchers',
      _i185.Product => 'Product',
      _i186.ProductAdminView => 'ProductAdminView',
      _i187.ProductAnnouncementView => 'ProductAnnouncementView',
      _i188.ProductDeliveryHealth => 'ProductDeliveryHealth',
      _i189.ProductNotification => 'ProductNotification',
      _i190.ProductNotificationRecipientResult =>
        'ProductNotificationRecipientResult',
      _i191.ProductNotificationSendResult => 'ProductNotificationSendResult',
      _i192.ProductObjectRoom => 'ProductObjectRoom',
      _i193.ProfileTranslation => 'ProfileTranslation',
      _i194.PulseAccessAuditEvent => 'PulseAccessAuditEvent',
      _i195.PulseAccessEntry => 'PulseAccessEntry',
      _i196.PulseAlertRule => 'PulseAlertRule',
      _i197.PulseEvent => 'PulseEvent',
      _i198.PulseExpiryReminder => 'PulseExpiryReminder',
      _i199.PulseFolder => 'PulseFolder',
      _i200.PulseFolderMembership => 'PulseFolderMembership',
      _i201.PulseIncident => 'PulseIncident',
      _i202.PulseMemberView => 'PulseMemberView',
      _i203.PulseMonitor => 'PulseMonitor',
      _i204.PulseMonitorCreated => 'PulseMonitorCreated',
      _i205.PulseMonitorMembership => 'PulseMonitorMembership',
      _i206.PulseProbeAllowlistEntry => 'PulseProbeAllowlistEntry',
      _i207.PulseTlsProbe => 'PulseTlsProbe',
      _i208.PulseValueThreshold => 'PulseValueThreshold',
      _i209.PushQueueMessage => 'PushQueueMessage',
      _i210.PushTestJob => 'PushTestJob',
      _i211.PushTestResult => 'PushTestResult',
      _i212.Room => 'Room',
      _i213.RoomBotCommands => 'RoomBotCommands',
      _i214.RoomDeliveryBackstop => 'RoomDeliveryBackstop',
      _i215.RoomDetails => 'RoomDetails',
      _i216.RoomListPage => 'RoomListPage',
      _i217.RoomMembership => 'RoomMembership',
      _i218.RoomParticipant => 'RoomParticipant',
      _i219.RoomSummary => 'RoomSummary',
      _i220.RoomTaskStats => 'RoomTaskStats',
      _i221.RoomTaskView => 'RoomTaskView',
      _i222.Sticker => 'Sticker',
      _i223.StickerPack => 'StickerPack',
      _i224.StickerPackView => 'StickerPackView',
      _i225.SupportTeam => 'SupportTeam',
      _i226.SupportTeamExclusion => 'SupportTeamExclusion',
      _i227.SupportTeamMember => 'SupportTeamMember',
      _i228.SupportTeamMemberView => 'SupportTeamMemberView',
      _i229.SupportTeamView => 'SupportTeamView',
      _i230.TaskLink => 'TaskLink',
      _i231.TaskManagerConfig => 'TaskManagerConfig',
      _i232.Team => 'Team',
      _i233.TeamMember => 'TeamMember',
      _i234.TeamMemberView => 'TeamMemberView',
      _i235.TeamView => 'TeamView',
      _i236.Tenant => 'Tenant',
      _i237.TenantSupportMember => 'TenantSupportMember',
      _i238.TenantSupportMemberView => 'TenantSupportMemberView',
      _i239.ThreadReadState => 'ThreadReadState',
      _i240.Ticket => 'Ticket',
      _i241.TicketEvent => 'TicketEvent',
      _i242.TicketView => 'TicketView',
      _i243.TrustRedeemResult => 'TrustRedeemResult',
      _i244.TrustToken => 'TrustToken',
      _i245.TrustTokenIssued => 'TrustTokenIssued',
      _i246.TurnCredentials => 'TurnCredentials',
      _i247.WebhookDelivery => 'WebhookDelivery',
      _i248.WebhookEventMessage => 'WebhookEventMessage',
      _i249.WebhookSubscription => 'WebhookSubscription',
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
      case _i3.AnnouncementRecipient():
        return 'AnnouncementRecipient';
      case _i4.AnnouncementSeen():
        return 'AnnouncementSeen';
      case _i5.AnnouncementView():
        return 'AnnouncementView';
      case _i6.AttachmentBytes():
        return 'AttachmentBytes';
      case _i7.AttachmentObject():
        return 'AttachmentObject';
      case _i8.AttachmentPlacement():
        return 'AttachmentPlacement';
      case _i9.AttachmentRef():
        return 'AttachmentRef';
      case _i10.AttachmentUrl():
        return 'AttachmentUrl';
      case _i11.AvailableBot():
        return 'AvailableBot';
      case _i12.Bot():
        return 'Bot';
      case _i13.BotAuditEvent():
        return 'BotAuditEvent';
      case _i14.BotChannelHealth():
        return 'BotChannelHealth';
      case _i15.BotCommand():
        return 'BotCommand';
      case _i16.BotIntegrationCreated():
        return 'BotIntegrationCreated';
      case _i17.BotIntegrationView():
        return 'BotIntegrationView';
      case _i18.BotReadModeResult():
        return 'BotReadModeResult';
      case _i19.CallHistoryEntry():
        return 'CallHistoryEntry';
      case _i20.CallIceCandidate():
        return 'CallIceCandidate';
      case _i21.ChatFolderRecord():
        return 'ChatFolderRecord';
      case _i22.ChatFolderRoom():
        return 'ChatFolderRoom';
      case _i23.ChatFolderView():
        return 'ChatFolderView';
      case _i24.Conference():
        return 'Conference';
      case _i25.ConferenceMember():
        return 'ConferenceMember';
      case _i26.ConferenceParticipant():
        return 'ConferenceParticipant';
      case _i27.ConferenceScreenShare():
        return 'ConferenceScreenShare';
      case _i28.ConferenceState():
        return 'ConferenceState';
      case _i29.ConnectIssuedToken():
        return 'ConnectIssuedToken';
      case _i30.ConnectIssuedTokenResult():
        return 'ConnectIssuedTokenResult';
      case _i31.ConnectKeyAuditEvent():
        return 'ConnectKeyAuditEvent';
      case _i32.ConnectTenantStatus():
        return 'ConnectTenantStatus';
      case _i33.ContactBlock():
        return 'ContactBlock';
      case _i34.ContactCard():
        return 'ContactCard';
      case _i35.ContactCardInfo():
        return 'ContactCardInfo';
      case _i36.ContactLabel():
        return 'ContactLabel';
      case _i37.ContactLabelAssignment():
        return 'ContactLabelAssignment';
      case _i38.ContactLink():
        return 'ContactLink';
      case _i39.ContactMeta():
        return 'ContactMeta';
      case _i40.ContactProfileView():
        return 'ContactProfileView';
      case _i41.ContactRelation():
        return 'ContactRelation';
      case _i42.ContactRequest():
        return 'ContactRequest';
      case _i43.ContactRequestView():
        return 'ContactRequestView';
      case _i44.CrmAccessDenied():
        return 'CrmAccessDenied';
      case _i45.CrmActivityType():
        return 'CrmActivityType';
      case _i46.CrmActivityView():
        return 'CrmActivityView';
      case _i47.CrmActorKind():
        return 'CrmActorKind';
      case _i48.CrmBridgeNotConfigured():
        return 'CrmBridgeNotConfigured';
      case _i49.CrmChangeOperation():
        return 'CrmChangeOperation';
      case _i50.CrmChangeView():
        return 'CrmChangeView';
      case _i51.CrmChangesetStatus():
        return 'CrmChangesetStatus';
      case _i52.CrmChangesetView():
        return 'CrmChangesetView';
      case _i53.CrmCompanyDetails():
        return 'CrmCompanyDetails';
      case _i54.CrmCompanyKind():
        return 'CrmCompanyKind';
      case _i55.CrmCompanyStatus():
        return 'CrmCompanyStatus';
      case _i56.CrmCompanyView():
        return 'CrmCompanyView';
      case _i57.CrmConfirmationRequired():
        return 'CrmConfirmationRequired';
      case _i58.CrmContactView():
        return 'CrmContactView';
      case _i59.CrmDealPage():
        return 'CrmDealPage';
      case _i60.CrmDealView():
        return 'CrmDealView';
      case _i61.CrmDigest():
        return 'CrmDigest';
      case _i62.CrmDocumentKind():
        return 'CrmDocumentKind';
      case _i63.CrmDocumentView():
        return 'CrmDocumentView';
      case _i64.CrmEntityKind():
        return 'CrmEntityKind';
      case _i65.CrmInputInvalid():
        return 'CrmInputInvalid';
      case _i66.CrmMetricView():
        return 'CrmMetricView';
      case _i67.CrmNextStepState():
        return 'CrmNextStepState';
      case _i68.CrmPdBasis():
        return 'CrmPdBasis';
      case _i69.CrmPersonalGrantView():
        return 'CrmPersonalGrantView';
      case _i70.CrmPipelineInUse():
        return 'CrmPipelineInUse';
      case _i71.CrmPipelineInvalid():
        return 'CrmPipelineInvalid';
      case _i72.CrmProposal():
        return 'CrmProposal';
      case _i73.CrmProposalStale():
        return 'CrmProposalStale';
      case _i74.CrmSegmentRole():
        return 'CrmSegmentRole';
      case _i75.CrmStageCount():
        return 'CrmStageCount';
      case _i76.CrmStageInUse():
        return 'CrmStageInUse';
      case _i77.CrmStageKind():
        return 'CrmStageKind';
      case _i78.CrmStageOrderConflict():
        return 'CrmStageOrderConflict';
      case _i79.CrmUserView():
        return 'CrmUserView';
      case _i80.CrmVersionConflict():
        return 'CrmVersionConflict';
      case _i81.CrmVersionConflictItem():
        return 'CrmVersionConflictItem';
      case _i82.DeliveryJournalEntry():
        return 'DeliveryJournalEntry';
      case _i83.DeliveryJournalPage():
        return 'DeliveryJournalPage';
      case _i84.DeliveryPending():
        return 'DeliveryPending';
      case _i85.DeliveryRecipientState():
        return 'DeliveryRecipientState';
      case _i86.DeliveryRecipientStatus():
        return 'DeliveryRecipientStatus';
      case _i87.DeliverySilentPage():
        return 'DeliverySilentPage';
      case _i88.DeliverySilentRecipient():
        return 'DeliverySilentRecipient';
      case _i89.DeliveryUsage():
        return 'DeliveryUsage';
      case _i90.DeviceRegistration():
        return 'DeviceRegistration';
      case _i91.DeviceRegistrationRemoval():
        return 'DeviceRegistrationRemoval';
      case _i92.DeviceSessionInfo():
        return 'DeviceSessionInfo';
      case _i93.EmailAccount():
        return 'EmailAccount';
      case _i94.EmailSession():
        return 'EmailSession';
      case _i95.EmailVerificationCode():
        return 'EmailVerificationCode';
      case _i96.AttachmentRejectReason():
        return 'AttachmentRejectReason';
      case _i97.CallEventType():
        return 'CallEventType';
      case _i98.CallStatus():
        return 'CallStatus';
      case _i99.ContactLinkSource():
        return 'ContactLinkSource';
      case _i100.ContactRequestStatus():
        return 'ContactRequestStatus';
      case _i101.DevicePlatform():
        return 'DevicePlatform';
      case _i102.DeviceRemovalReason():
        return 'DeviceRemovalReason';
      case _i103.IdentityProvider():
        return 'IdentityProvider';
      case _i104.MessengerEventType():
        return 'MessengerEventType';
      case _i105.ParticipantKind():
        return 'ParticipantKind';
      case _i106.ProductNotificationStatus():
        return 'ProductNotificationStatus';
      case _i107.PushService():
        return 'PushService';
      case _i108.RoomMemberRole():
        return 'RoomMemberRole';
      case _i109.RoomOwnership():
        return 'RoomOwnership';
      case _i110.RoomState():
        return 'RoomState';
      case _i111.RoomType():
        return 'RoomType';
      case _i112.SupportTeamRole():
        return 'SupportTeamRole';
      case _i113.TeamKind():
        return 'TeamKind';
      case _i114.TeamMemberRole():
        return 'TeamMemberRole';
      case _i115.TenantHostingMode():
        return 'TenantHostingMode';
      case _i116.TrustTokenKind():
        return 'TrustTokenKind';
      case _i117.AdapterNotConfiguredException():
        return 'AdapterNotConfiguredException';
      case _i118.AmbiguousProductKeyException():
        return 'AmbiguousProductKeyException';
      case _i119.AttachmentAccessDeniedException():
        return 'AttachmentAccessDeniedException';
      case _i120.AttachmentRejectedException():
        return 'AttachmentRejectedException';
      case _i121.BotCapabilityException():
        return 'BotCapabilityException';
      case _i122.BotLimitExceededException():
        return 'BotLimitExceededException';
      case _i123.BotNotFoundException():
        return 'BotNotFoundException';
      case _i124.BotReadRestrictedException():
        return 'BotReadRestrictedException';
      case _i125.ConferenceFullException():
        return 'ConferenceFullException';
      case _i126.EmailAuthException():
        return 'EmailAuthException';
      case _i127.InsufficientPowerException():
        return 'InsufficientPowerException';
      case _i128.InvalidBotCommandsException():
        return 'InvalidBotCommandsException';
      case _i129.InvalidExternalKeyException():
        return 'InvalidExternalKeyException';
      case _i130.InvalidNotificationException():
        return 'InvalidNotificationException';
      case _i131.InvalidTokenException():
        return 'InvalidTokenException';
      case _i132.LastOwnerCannotDemoteException():
        return 'LastOwnerCannotDemoteException';
      case _i133.MessageBodyTooLargeException():
        return 'MessageBodyTooLargeException';
      case _i134.MessageDeletedException():
        return 'MessageDeletedException';
      case _i135.MessageNotEditableException():
        return 'MessageNotEditableException';
      case _i136.MessengerNotAuthenticatedException():
        return 'MessengerNotAuthenticatedException';
      case _i137.NotObjectRoomException():
        return 'NotObjectRoomException';
      case _i138.NotSupportTeamMemberException():
        return 'NotSupportTeamMemberException';
      case _i139.NotSupportTeamOwnerException():
        return 'NotSupportTeamOwnerException';
      case _i140.NotificationInProgressException():
        return 'NotificationInProgressException';
      case _i141.OperatorEmailNotResolvedException():
        return 'OperatorEmailNotResolvedException';
      case _i142.PeerUnavailableException():
        return 'PeerUnavailableException';
      case _i143.ProbeTargetNotAllowedException():
        return 'ProbeTargetNotAllowedException';
      case _i144.ProductAlreadyExistsException():
        return 'ProductAlreadyExistsException';
      case _i145.ProductInUseException():
        return 'ProductInUseException';
      case _i146.ProductNotFoundException():
        return 'ProductNotFoundException';
      case _i147.ProductNotFoundForCallerException():
        return 'ProductNotFoundForCallerException';
      case _i148.RateLimitExceededException():
        return 'RateLimitExceededException';
      case _i149.RoomCapacityExceededException():
        return 'RoomCapacityExceededException';
      case _i150.RoomDissolvePartialException():
        return 'RoomDissolvePartialException';
      case _i151.RoomUnavailableException():
        return 'RoomUnavailableException';
      case _i152.ScreenShareBusyException():
        return 'ScreenShareBusyException';
      case _i153.StickerRejectedException():
        return 'StickerRejectedException';
      case _i154.TaskIntegrationNotConfiguredException():
        return 'TaskIntegrationNotConfiguredException';
      case _i155.TeamAccessDeniedException():
        return 'TeamAccessDeniedException';
      case _i156.TeamPeerUnknownException():
        return 'TeamPeerUnknownException';
      case _i157.TenantAlreadyExistsException():
        return 'TenantAlreadyExistsException';
      case _i158.TenantNotFoundException():
        return 'TenantNotFoundException';
      case _i159.ThumbnailUnavailableException():
        return 'ThumbnailUnavailableException';
      case _i160.WebhookSubscriptionException():
        return 'WebhookSubscriptionException';
      case _i161.WriteBannedException():
        return 'WriteBannedException';
      case _i162.EscalationResult():
        return 'EscalationResult';
      case _i163.Greeting():
        return 'Greeting';
      case _i164.IdentityMapping():
        return 'IdentityMapping';
      case _i165.IncomingWebhook():
        return 'IncomingWebhook';
      case _i166.IncomingWebhookCreated():
        return 'IncomingWebhookCreated';
      case _i167.LinkPreview():
        return 'LinkPreview';
      case _i168.LinkPreviewView():
        return 'LinkPreviewView';
      case _i169.MessageIndex():
        return 'MessageIndex';
      case _i170.MessengerAuthContext():
        return 'MessengerAuthContext';
      case _i171.MessengerEvent():
        return 'MessengerEvent';
      case _i172.MessengerMessage():
        return 'MessengerMessage';
      case _i173.MessengerMessageListPage():
        return 'MessengerMessageListPage';
      case _i174.MessengerSession():
        return 'MessengerSession';
      case _i175.MessengerSessionToken():
        return 'MessengerSessionToken';
      case _i176.MessengerUser():
        return 'MessengerUser';
      case _i177.NearbyConfirmResult():
        return 'NearbyConfirmResult';
      case _i178.NearbyConfirmation():
        return 'NearbyConfirmation';
      case _i179.NotificationSettings():
        return 'NotificationSettings';
      case _i180.PresenceConnState():
        return 'PresenceConnState';
      case _i181.PresenceInfo():
        return 'PresenceInfo';
      case _i182.PresenceState():
        return 'PresenceState';
      case _i183.PresenceWatchedIndex():
        return 'PresenceWatchedIndex';
      case _i184.PresenceWatchers():
        return 'PresenceWatchers';
      case _i185.Product():
        return 'Product';
      case _i186.ProductAdminView():
        return 'ProductAdminView';
      case _i187.ProductAnnouncementView():
        return 'ProductAnnouncementView';
      case _i188.ProductDeliveryHealth():
        return 'ProductDeliveryHealth';
      case _i189.ProductNotification():
        return 'ProductNotification';
      case _i190.ProductNotificationRecipientResult():
        return 'ProductNotificationRecipientResult';
      case _i191.ProductNotificationSendResult():
        return 'ProductNotificationSendResult';
      case _i192.ProductObjectRoom():
        return 'ProductObjectRoom';
      case _i193.ProfileTranslation():
        return 'ProfileTranslation';
      case _i194.PulseAccessAuditEvent():
        return 'PulseAccessAuditEvent';
      case _i195.PulseAccessEntry():
        return 'PulseAccessEntry';
      case _i196.PulseAlertRule():
        return 'PulseAlertRule';
      case _i197.PulseEvent():
        return 'PulseEvent';
      case _i198.PulseExpiryReminder():
        return 'PulseExpiryReminder';
      case _i199.PulseFolder():
        return 'PulseFolder';
      case _i200.PulseFolderMembership():
        return 'PulseFolderMembership';
      case _i201.PulseIncident():
        return 'PulseIncident';
      case _i202.PulseMemberView():
        return 'PulseMemberView';
      case _i203.PulseMonitor():
        return 'PulseMonitor';
      case _i204.PulseMonitorCreated():
        return 'PulseMonitorCreated';
      case _i205.PulseMonitorMembership():
        return 'PulseMonitorMembership';
      case _i206.PulseProbeAllowlistEntry():
        return 'PulseProbeAllowlistEntry';
      case _i207.PulseTlsProbe():
        return 'PulseTlsProbe';
      case _i208.PulseValueThreshold():
        return 'PulseValueThreshold';
      case _i209.PushQueueMessage():
        return 'PushQueueMessage';
      case _i210.PushTestJob():
        return 'PushTestJob';
      case _i211.PushTestResult():
        return 'PushTestResult';
      case _i212.Room():
        return 'Room';
      case _i213.RoomBotCommands():
        return 'RoomBotCommands';
      case _i214.RoomDeliveryBackstop():
        return 'RoomDeliveryBackstop';
      case _i215.RoomDetails():
        return 'RoomDetails';
      case _i216.RoomListPage():
        return 'RoomListPage';
      case _i217.RoomMembership():
        return 'RoomMembership';
      case _i218.RoomParticipant():
        return 'RoomParticipant';
      case _i219.RoomSummary():
        return 'RoomSummary';
      case _i220.RoomTaskStats():
        return 'RoomTaskStats';
      case _i221.RoomTaskView():
        return 'RoomTaskView';
      case _i222.Sticker():
        return 'Sticker';
      case _i223.StickerPack():
        return 'StickerPack';
      case _i224.StickerPackView():
        return 'StickerPackView';
      case _i225.SupportTeam():
        return 'SupportTeam';
      case _i226.SupportTeamExclusion():
        return 'SupportTeamExclusion';
      case _i227.SupportTeamMember():
        return 'SupportTeamMember';
      case _i228.SupportTeamMemberView():
        return 'SupportTeamMemberView';
      case _i229.SupportTeamView():
        return 'SupportTeamView';
      case _i230.TaskLink():
        return 'TaskLink';
      case _i231.TaskManagerConfig():
        return 'TaskManagerConfig';
      case _i232.Team():
        return 'Team';
      case _i233.TeamMember():
        return 'TeamMember';
      case _i234.TeamMemberView():
        return 'TeamMemberView';
      case _i235.TeamView():
        return 'TeamView';
      case _i236.Tenant():
        return 'Tenant';
      case _i237.TenantSupportMember():
        return 'TenantSupportMember';
      case _i238.TenantSupportMemberView():
        return 'TenantSupportMemberView';
      case _i239.ThreadReadState():
        return 'ThreadReadState';
      case _i240.Ticket():
        return 'Ticket';
      case _i241.TicketEvent():
        return 'TicketEvent';
      case _i242.TicketView():
        return 'TicketView';
      case _i243.TrustRedeemResult():
        return 'TrustRedeemResult';
      case _i244.TrustToken():
        return 'TrustToken';
      case _i245.TrustTokenIssued():
        return 'TrustTokenIssued';
      case _i246.TurnCredentials():
        return 'TurnCredentials';
      case _i247.WebhookDelivery():
        return 'WebhookDelivery';
      case _i248.WebhookEventMessage():
        return 'WebhookEventMessage';
      case _i249.WebhookSubscription():
        return 'WebhookSubscription';
    }
    className = _i306.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i307.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'AnnouncementRecipient') {
      return deserialize<_i3.AnnouncementRecipient>(data['data']);
    }
    if (dataClassName == 'AnnouncementSeen') {
      return deserialize<_i4.AnnouncementSeen>(data['data']);
    }
    if (dataClassName == 'AnnouncementView') {
      return deserialize<_i5.AnnouncementView>(data['data']);
    }
    if (dataClassName == 'AttachmentBytes') {
      return deserialize<_i6.AttachmentBytes>(data['data']);
    }
    if (dataClassName == 'AttachmentObject') {
      return deserialize<_i7.AttachmentObject>(data['data']);
    }
    if (dataClassName == 'AttachmentPlacement') {
      return deserialize<_i8.AttachmentPlacement>(data['data']);
    }
    if (dataClassName == 'AttachmentRef') {
      return deserialize<_i9.AttachmentRef>(data['data']);
    }
    if (dataClassName == 'AttachmentUrl') {
      return deserialize<_i10.AttachmentUrl>(data['data']);
    }
    if (dataClassName == 'AvailableBot') {
      return deserialize<_i11.AvailableBot>(data['data']);
    }
    if (dataClassName == 'Bot') {
      return deserialize<_i12.Bot>(data['data']);
    }
    if (dataClassName == 'BotAuditEvent') {
      return deserialize<_i13.BotAuditEvent>(data['data']);
    }
    if (dataClassName == 'BotChannelHealth') {
      return deserialize<_i14.BotChannelHealth>(data['data']);
    }
    if (dataClassName == 'BotCommand') {
      return deserialize<_i15.BotCommand>(data['data']);
    }
    if (dataClassName == 'BotIntegrationCreated') {
      return deserialize<_i16.BotIntegrationCreated>(data['data']);
    }
    if (dataClassName == 'BotIntegrationView') {
      return deserialize<_i17.BotIntegrationView>(data['data']);
    }
    if (dataClassName == 'BotReadModeResult') {
      return deserialize<_i18.BotReadModeResult>(data['data']);
    }
    if (dataClassName == 'CallHistoryEntry') {
      return deserialize<_i19.CallHistoryEntry>(data['data']);
    }
    if (dataClassName == 'CallIceCandidate') {
      return deserialize<_i20.CallIceCandidate>(data['data']);
    }
    if (dataClassName == 'ChatFolderRecord') {
      return deserialize<_i21.ChatFolderRecord>(data['data']);
    }
    if (dataClassName == 'ChatFolderRoom') {
      return deserialize<_i22.ChatFolderRoom>(data['data']);
    }
    if (dataClassName == 'ChatFolderView') {
      return deserialize<_i23.ChatFolderView>(data['data']);
    }
    if (dataClassName == 'Conference') {
      return deserialize<_i24.Conference>(data['data']);
    }
    if (dataClassName == 'ConferenceMember') {
      return deserialize<_i25.ConferenceMember>(data['data']);
    }
    if (dataClassName == 'ConferenceParticipant') {
      return deserialize<_i26.ConferenceParticipant>(data['data']);
    }
    if (dataClassName == 'ConferenceScreenShare') {
      return deserialize<_i27.ConferenceScreenShare>(data['data']);
    }
    if (dataClassName == 'ConferenceState') {
      return deserialize<_i28.ConferenceState>(data['data']);
    }
    if (dataClassName == 'ConnectIssuedToken') {
      return deserialize<_i29.ConnectIssuedToken>(data['data']);
    }
    if (dataClassName == 'ConnectIssuedTokenResult') {
      return deserialize<_i30.ConnectIssuedTokenResult>(data['data']);
    }
    if (dataClassName == 'ConnectKeyAuditEvent') {
      return deserialize<_i31.ConnectKeyAuditEvent>(data['data']);
    }
    if (dataClassName == 'ConnectTenantStatus') {
      return deserialize<_i32.ConnectTenantStatus>(data['data']);
    }
    if (dataClassName == 'ContactBlock') {
      return deserialize<_i33.ContactBlock>(data['data']);
    }
    if (dataClassName == 'ContactCard') {
      return deserialize<_i34.ContactCard>(data['data']);
    }
    if (dataClassName == 'ContactCardInfo') {
      return deserialize<_i35.ContactCardInfo>(data['data']);
    }
    if (dataClassName == 'ContactLabel') {
      return deserialize<_i36.ContactLabel>(data['data']);
    }
    if (dataClassName == 'ContactLabelAssignment') {
      return deserialize<_i37.ContactLabelAssignment>(data['data']);
    }
    if (dataClassName == 'ContactLink') {
      return deserialize<_i38.ContactLink>(data['data']);
    }
    if (dataClassName == 'ContactMeta') {
      return deserialize<_i39.ContactMeta>(data['data']);
    }
    if (dataClassName == 'ContactProfileView') {
      return deserialize<_i40.ContactProfileView>(data['data']);
    }
    if (dataClassName == 'ContactRelation') {
      return deserialize<_i41.ContactRelation>(data['data']);
    }
    if (dataClassName == 'ContactRequest') {
      return deserialize<_i42.ContactRequest>(data['data']);
    }
    if (dataClassName == 'ContactRequestView') {
      return deserialize<_i43.ContactRequestView>(data['data']);
    }
    if (dataClassName == 'CrmAccessDenied') {
      return deserialize<_i44.CrmAccessDenied>(data['data']);
    }
    if (dataClassName == 'CrmActivityType') {
      return deserialize<_i45.CrmActivityType>(data['data']);
    }
    if (dataClassName == 'CrmActivityView') {
      return deserialize<_i46.CrmActivityView>(data['data']);
    }
    if (dataClassName == 'CrmActorKind') {
      return deserialize<_i47.CrmActorKind>(data['data']);
    }
    if (dataClassName == 'CrmBridgeNotConfigured') {
      return deserialize<_i48.CrmBridgeNotConfigured>(data['data']);
    }
    if (dataClassName == 'CrmChangeOperation') {
      return deserialize<_i49.CrmChangeOperation>(data['data']);
    }
    if (dataClassName == 'CrmChangeView') {
      return deserialize<_i50.CrmChangeView>(data['data']);
    }
    if (dataClassName == 'CrmChangesetStatus') {
      return deserialize<_i51.CrmChangesetStatus>(data['data']);
    }
    if (dataClassName == 'CrmChangesetView') {
      return deserialize<_i52.CrmChangesetView>(data['data']);
    }
    if (dataClassName == 'CrmCompanyDetails') {
      return deserialize<_i53.CrmCompanyDetails>(data['data']);
    }
    if (dataClassName == 'CrmCompanyKind') {
      return deserialize<_i54.CrmCompanyKind>(data['data']);
    }
    if (dataClassName == 'CrmCompanyStatus') {
      return deserialize<_i55.CrmCompanyStatus>(data['data']);
    }
    if (dataClassName == 'CrmCompanyView') {
      return deserialize<_i56.CrmCompanyView>(data['data']);
    }
    if (dataClassName == 'CrmConfirmationRequired') {
      return deserialize<_i57.CrmConfirmationRequired>(data['data']);
    }
    if (dataClassName == 'CrmContactView') {
      return deserialize<_i58.CrmContactView>(data['data']);
    }
    if (dataClassName == 'CrmDealPage') {
      return deserialize<_i59.CrmDealPage>(data['data']);
    }
    if (dataClassName == 'CrmDealView') {
      return deserialize<_i60.CrmDealView>(data['data']);
    }
    if (dataClassName == 'CrmDigest') {
      return deserialize<_i61.CrmDigest>(data['data']);
    }
    if (dataClassName == 'CrmDocumentKind') {
      return deserialize<_i62.CrmDocumentKind>(data['data']);
    }
    if (dataClassName == 'CrmDocumentView') {
      return deserialize<_i63.CrmDocumentView>(data['data']);
    }
    if (dataClassName == 'CrmEntityKind') {
      return deserialize<_i64.CrmEntityKind>(data['data']);
    }
    if (dataClassName == 'CrmInputInvalid') {
      return deserialize<_i65.CrmInputInvalid>(data['data']);
    }
    if (dataClassName == 'CrmMetricView') {
      return deserialize<_i66.CrmMetricView>(data['data']);
    }
    if (dataClassName == 'CrmNextStepState') {
      return deserialize<_i67.CrmNextStepState>(data['data']);
    }
    if (dataClassName == 'CrmPdBasis') {
      return deserialize<_i68.CrmPdBasis>(data['data']);
    }
    if (dataClassName == 'CrmPersonalGrantView') {
      return deserialize<_i69.CrmPersonalGrantView>(data['data']);
    }
    if (dataClassName == 'CrmPipelineInUse') {
      return deserialize<_i70.CrmPipelineInUse>(data['data']);
    }
    if (dataClassName == 'CrmPipelineInvalid') {
      return deserialize<_i71.CrmPipelineInvalid>(data['data']);
    }
    if (dataClassName == 'CrmProposal') {
      return deserialize<_i72.CrmProposal>(data['data']);
    }
    if (dataClassName == 'CrmProposalStale') {
      return deserialize<_i73.CrmProposalStale>(data['data']);
    }
    if (dataClassName == 'CrmSegmentRole') {
      return deserialize<_i74.CrmSegmentRole>(data['data']);
    }
    if (dataClassName == 'CrmStageCount') {
      return deserialize<_i75.CrmStageCount>(data['data']);
    }
    if (dataClassName == 'CrmStageInUse') {
      return deserialize<_i76.CrmStageInUse>(data['data']);
    }
    if (dataClassName == 'CrmStageKind') {
      return deserialize<_i77.CrmStageKind>(data['data']);
    }
    if (dataClassName == 'CrmStageOrderConflict') {
      return deserialize<_i78.CrmStageOrderConflict>(data['data']);
    }
    if (dataClassName == 'CrmUserView') {
      return deserialize<_i79.CrmUserView>(data['data']);
    }
    if (dataClassName == 'CrmVersionConflict') {
      return deserialize<_i80.CrmVersionConflict>(data['data']);
    }
    if (dataClassName == 'CrmVersionConflictItem') {
      return deserialize<_i81.CrmVersionConflictItem>(data['data']);
    }
    if (dataClassName == 'DeliveryJournalEntry') {
      return deserialize<_i82.DeliveryJournalEntry>(data['data']);
    }
    if (dataClassName == 'DeliveryJournalPage') {
      return deserialize<_i83.DeliveryJournalPage>(data['data']);
    }
    if (dataClassName == 'DeliveryPending') {
      return deserialize<_i84.DeliveryPending>(data['data']);
    }
    if (dataClassName == 'DeliveryRecipientState') {
      return deserialize<_i85.DeliveryRecipientState>(data['data']);
    }
    if (dataClassName == 'DeliveryRecipientStatus') {
      return deserialize<_i86.DeliveryRecipientStatus>(data['data']);
    }
    if (dataClassName == 'DeliverySilentPage') {
      return deserialize<_i87.DeliverySilentPage>(data['data']);
    }
    if (dataClassName == 'DeliverySilentRecipient') {
      return deserialize<_i88.DeliverySilentRecipient>(data['data']);
    }
    if (dataClassName == 'DeliveryUsage') {
      return deserialize<_i89.DeliveryUsage>(data['data']);
    }
    if (dataClassName == 'DeviceRegistration') {
      return deserialize<_i90.DeviceRegistration>(data['data']);
    }
    if (dataClassName == 'DeviceRegistrationRemoval') {
      return deserialize<_i91.DeviceRegistrationRemoval>(data['data']);
    }
    if (dataClassName == 'DeviceSessionInfo') {
      return deserialize<_i92.DeviceSessionInfo>(data['data']);
    }
    if (dataClassName == 'EmailAccount') {
      return deserialize<_i93.EmailAccount>(data['data']);
    }
    if (dataClassName == 'EmailSession') {
      return deserialize<_i94.EmailSession>(data['data']);
    }
    if (dataClassName == 'EmailVerificationCode') {
      return deserialize<_i95.EmailVerificationCode>(data['data']);
    }
    if (dataClassName == 'AttachmentRejectReason') {
      return deserialize<_i96.AttachmentRejectReason>(data['data']);
    }
    if (dataClassName == 'CallEventType') {
      return deserialize<_i97.CallEventType>(data['data']);
    }
    if (dataClassName == 'CallStatus') {
      return deserialize<_i98.CallStatus>(data['data']);
    }
    if (dataClassName == 'ContactLinkSource') {
      return deserialize<_i99.ContactLinkSource>(data['data']);
    }
    if (dataClassName == 'ContactRequestStatus') {
      return deserialize<_i100.ContactRequestStatus>(data['data']);
    }
    if (dataClassName == 'DevicePlatform') {
      return deserialize<_i101.DevicePlatform>(data['data']);
    }
    if (dataClassName == 'DeviceRemovalReason') {
      return deserialize<_i102.DeviceRemovalReason>(data['data']);
    }
    if (dataClassName == 'IdentityProvider') {
      return deserialize<_i103.IdentityProvider>(data['data']);
    }
    if (dataClassName == 'MessengerEventType') {
      return deserialize<_i104.MessengerEventType>(data['data']);
    }
    if (dataClassName == 'ParticipantKind') {
      return deserialize<_i105.ParticipantKind>(data['data']);
    }
    if (dataClassName == 'ProductNotificationStatus') {
      return deserialize<_i106.ProductNotificationStatus>(data['data']);
    }
    if (dataClassName == 'PushService') {
      return deserialize<_i107.PushService>(data['data']);
    }
    if (dataClassName == 'RoomMemberRole') {
      return deserialize<_i108.RoomMemberRole>(data['data']);
    }
    if (dataClassName == 'RoomOwnership') {
      return deserialize<_i109.RoomOwnership>(data['data']);
    }
    if (dataClassName == 'RoomState') {
      return deserialize<_i110.RoomState>(data['data']);
    }
    if (dataClassName == 'RoomType') {
      return deserialize<_i111.RoomType>(data['data']);
    }
    if (dataClassName == 'SupportTeamRole') {
      return deserialize<_i112.SupportTeamRole>(data['data']);
    }
    if (dataClassName == 'TeamKind') {
      return deserialize<_i113.TeamKind>(data['data']);
    }
    if (dataClassName == 'TeamMemberRole') {
      return deserialize<_i114.TeamMemberRole>(data['data']);
    }
    if (dataClassName == 'TenantHostingMode') {
      return deserialize<_i115.TenantHostingMode>(data['data']);
    }
    if (dataClassName == 'TrustTokenKind') {
      return deserialize<_i116.TrustTokenKind>(data['data']);
    }
    if (dataClassName == 'AdapterNotConfiguredException') {
      return deserialize<_i117.AdapterNotConfiguredException>(data['data']);
    }
    if (dataClassName == 'AmbiguousProductKeyException') {
      return deserialize<_i118.AmbiguousProductKeyException>(data['data']);
    }
    if (dataClassName == 'AttachmentAccessDeniedException') {
      return deserialize<_i119.AttachmentAccessDeniedException>(data['data']);
    }
    if (dataClassName == 'AttachmentRejectedException') {
      return deserialize<_i120.AttachmentRejectedException>(data['data']);
    }
    if (dataClassName == 'BotCapabilityException') {
      return deserialize<_i121.BotCapabilityException>(data['data']);
    }
    if (dataClassName == 'BotLimitExceededException') {
      return deserialize<_i122.BotLimitExceededException>(data['data']);
    }
    if (dataClassName == 'BotNotFoundException') {
      return deserialize<_i123.BotNotFoundException>(data['data']);
    }
    if (dataClassName == 'BotReadRestrictedException') {
      return deserialize<_i124.BotReadRestrictedException>(data['data']);
    }
    if (dataClassName == 'ConferenceFullException') {
      return deserialize<_i125.ConferenceFullException>(data['data']);
    }
    if (dataClassName == 'EmailAuthException') {
      return deserialize<_i126.EmailAuthException>(data['data']);
    }
    if (dataClassName == 'InsufficientPowerException') {
      return deserialize<_i127.InsufficientPowerException>(data['data']);
    }
    if (dataClassName == 'InvalidBotCommandsException') {
      return deserialize<_i128.InvalidBotCommandsException>(data['data']);
    }
    if (dataClassName == 'InvalidExternalKeyException') {
      return deserialize<_i129.InvalidExternalKeyException>(data['data']);
    }
    if (dataClassName == 'InvalidNotificationException') {
      return deserialize<_i130.InvalidNotificationException>(data['data']);
    }
    if (dataClassName == 'InvalidTokenException') {
      return deserialize<_i131.InvalidTokenException>(data['data']);
    }
    if (dataClassName == 'LastOwnerCannotDemoteException') {
      return deserialize<_i132.LastOwnerCannotDemoteException>(data['data']);
    }
    if (dataClassName == 'MessageBodyTooLargeException') {
      return deserialize<_i133.MessageBodyTooLargeException>(data['data']);
    }
    if (dataClassName == 'MessageDeletedException') {
      return deserialize<_i134.MessageDeletedException>(data['data']);
    }
    if (dataClassName == 'MessageNotEditableException') {
      return deserialize<_i135.MessageNotEditableException>(data['data']);
    }
    if (dataClassName == 'MessengerNotAuthenticatedException') {
      return deserialize<_i136.MessengerNotAuthenticatedException>(
        data['data'],
      );
    }
    if (dataClassName == 'NotObjectRoomException') {
      return deserialize<_i137.NotObjectRoomException>(data['data']);
    }
    if (dataClassName == 'NotSupportTeamMemberException') {
      return deserialize<_i138.NotSupportTeamMemberException>(data['data']);
    }
    if (dataClassName == 'NotSupportTeamOwnerException') {
      return deserialize<_i139.NotSupportTeamOwnerException>(data['data']);
    }
    if (dataClassName == 'NotificationInProgressException') {
      return deserialize<_i140.NotificationInProgressException>(data['data']);
    }
    if (dataClassName == 'OperatorEmailNotResolvedException') {
      return deserialize<_i141.OperatorEmailNotResolvedException>(data['data']);
    }
    if (dataClassName == 'PeerUnavailableException') {
      return deserialize<_i142.PeerUnavailableException>(data['data']);
    }
    if (dataClassName == 'ProbeTargetNotAllowedException') {
      return deserialize<_i143.ProbeTargetNotAllowedException>(data['data']);
    }
    if (dataClassName == 'ProductAlreadyExistsException') {
      return deserialize<_i144.ProductAlreadyExistsException>(data['data']);
    }
    if (dataClassName == 'ProductInUseException') {
      return deserialize<_i145.ProductInUseException>(data['data']);
    }
    if (dataClassName == 'ProductNotFoundException') {
      return deserialize<_i146.ProductNotFoundException>(data['data']);
    }
    if (dataClassName == 'ProductNotFoundForCallerException') {
      return deserialize<_i147.ProductNotFoundForCallerException>(data['data']);
    }
    if (dataClassName == 'RateLimitExceededException') {
      return deserialize<_i148.RateLimitExceededException>(data['data']);
    }
    if (dataClassName == 'RoomCapacityExceededException') {
      return deserialize<_i149.RoomCapacityExceededException>(data['data']);
    }
    if (dataClassName == 'RoomDissolvePartialException') {
      return deserialize<_i150.RoomDissolvePartialException>(data['data']);
    }
    if (dataClassName == 'RoomUnavailableException') {
      return deserialize<_i151.RoomUnavailableException>(data['data']);
    }
    if (dataClassName == 'ScreenShareBusyException') {
      return deserialize<_i152.ScreenShareBusyException>(data['data']);
    }
    if (dataClassName == 'StickerRejectedException') {
      return deserialize<_i153.StickerRejectedException>(data['data']);
    }
    if (dataClassName == 'TaskIntegrationNotConfiguredException') {
      return deserialize<_i154.TaskIntegrationNotConfiguredException>(
        data['data'],
      );
    }
    if (dataClassName == 'TeamAccessDeniedException') {
      return deserialize<_i155.TeamAccessDeniedException>(data['data']);
    }
    if (dataClassName == 'TeamPeerUnknownException') {
      return deserialize<_i156.TeamPeerUnknownException>(data['data']);
    }
    if (dataClassName == 'TenantAlreadyExistsException') {
      return deserialize<_i157.TenantAlreadyExistsException>(data['data']);
    }
    if (dataClassName == 'TenantNotFoundException') {
      return deserialize<_i158.TenantNotFoundException>(data['data']);
    }
    if (dataClassName == 'ThumbnailUnavailableException') {
      return deserialize<_i159.ThumbnailUnavailableException>(data['data']);
    }
    if (dataClassName == 'WebhookSubscriptionException') {
      return deserialize<_i160.WebhookSubscriptionException>(data['data']);
    }
    if (dataClassName == 'WriteBannedException') {
      return deserialize<_i161.WriteBannedException>(data['data']);
    }
    if (dataClassName == 'EscalationResult') {
      return deserialize<_i162.EscalationResult>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i163.Greeting>(data['data']);
    }
    if (dataClassName == 'IdentityMapping') {
      return deserialize<_i164.IdentityMapping>(data['data']);
    }
    if (dataClassName == 'IncomingWebhook') {
      return deserialize<_i165.IncomingWebhook>(data['data']);
    }
    if (dataClassName == 'IncomingWebhookCreated') {
      return deserialize<_i166.IncomingWebhookCreated>(data['data']);
    }
    if (dataClassName == 'LinkPreview') {
      return deserialize<_i167.LinkPreview>(data['data']);
    }
    if (dataClassName == 'LinkPreviewView') {
      return deserialize<_i168.LinkPreviewView>(data['data']);
    }
    if (dataClassName == 'MessageIndex') {
      return deserialize<_i169.MessageIndex>(data['data']);
    }
    if (dataClassName == 'MessengerAuthContext') {
      return deserialize<_i170.MessengerAuthContext>(data['data']);
    }
    if (dataClassName == 'MessengerEvent') {
      return deserialize<_i171.MessengerEvent>(data['data']);
    }
    if (dataClassName == 'MessengerMessage') {
      return deserialize<_i172.MessengerMessage>(data['data']);
    }
    if (dataClassName == 'MessengerMessageListPage') {
      return deserialize<_i173.MessengerMessageListPage>(data['data']);
    }
    if (dataClassName == 'MessengerSession') {
      return deserialize<_i174.MessengerSession>(data['data']);
    }
    if (dataClassName == 'MessengerSessionToken') {
      return deserialize<_i175.MessengerSessionToken>(data['data']);
    }
    if (dataClassName == 'MessengerUser') {
      return deserialize<_i176.MessengerUser>(data['data']);
    }
    if (dataClassName == 'NearbyConfirmResult') {
      return deserialize<_i177.NearbyConfirmResult>(data['data']);
    }
    if (dataClassName == 'NearbyConfirmation') {
      return deserialize<_i178.NearbyConfirmation>(data['data']);
    }
    if (dataClassName == 'NotificationSettings') {
      return deserialize<_i179.NotificationSettings>(data['data']);
    }
    if (dataClassName == 'PresenceConnState') {
      return deserialize<_i180.PresenceConnState>(data['data']);
    }
    if (dataClassName == 'PresenceInfo') {
      return deserialize<_i181.PresenceInfo>(data['data']);
    }
    if (dataClassName == 'PresenceState') {
      return deserialize<_i182.PresenceState>(data['data']);
    }
    if (dataClassName == 'PresenceWatchedIndex') {
      return deserialize<_i183.PresenceWatchedIndex>(data['data']);
    }
    if (dataClassName == 'PresenceWatchers') {
      return deserialize<_i184.PresenceWatchers>(data['data']);
    }
    if (dataClassName == 'Product') {
      return deserialize<_i185.Product>(data['data']);
    }
    if (dataClassName == 'ProductAdminView') {
      return deserialize<_i186.ProductAdminView>(data['data']);
    }
    if (dataClassName == 'ProductAnnouncementView') {
      return deserialize<_i187.ProductAnnouncementView>(data['data']);
    }
    if (dataClassName == 'ProductDeliveryHealth') {
      return deserialize<_i188.ProductDeliveryHealth>(data['data']);
    }
    if (dataClassName == 'ProductNotification') {
      return deserialize<_i189.ProductNotification>(data['data']);
    }
    if (dataClassName == 'ProductNotificationRecipientResult') {
      return deserialize<_i190.ProductNotificationRecipientResult>(
        data['data'],
      );
    }
    if (dataClassName == 'ProductNotificationSendResult') {
      return deserialize<_i191.ProductNotificationSendResult>(data['data']);
    }
    if (dataClassName == 'ProductObjectRoom') {
      return deserialize<_i192.ProductObjectRoom>(data['data']);
    }
    if (dataClassName == 'ProfileTranslation') {
      return deserialize<_i193.ProfileTranslation>(data['data']);
    }
    if (dataClassName == 'PulseAccessAuditEvent') {
      return deserialize<_i194.PulseAccessAuditEvent>(data['data']);
    }
    if (dataClassName == 'PulseAccessEntry') {
      return deserialize<_i195.PulseAccessEntry>(data['data']);
    }
    if (dataClassName == 'PulseAlertRule') {
      return deserialize<_i196.PulseAlertRule>(data['data']);
    }
    if (dataClassName == 'PulseEvent') {
      return deserialize<_i197.PulseEvent>(data['data']);
    }
    if (dataClassName == 'PulseExpiryReminder') {
      return deserialize<_i198.PulseExpiryReminder>(data['data']);
    }
    if (dataClassName == 'PulseFolder') {
      return deserialize<_i199.PulseFolder>(data['data']);
    }
    if (dataClassName == 'PulseFolderMembership') {
      return deserialize<_i200.PulseFolderMembership>(data['data']);
    }
    if (dataClassName == 'PulseIncident') {
      return deserialize<_i201.PulseIncident>(data['data']);
    }
    if (dataClassName == 'PulseMemberView') {
      return deserialize<_i202.PulseMemberView>(data['data']);
    }
    if (dataClassName == 'PulseMonitor') {
      return deserialize<_i203.PulseMonitor>(data['data']);
    }
    if (dataClassName == 'PulseMonitorCreated') {
      return deserialize<_i204.PulseMonitorCreated>(data['data']);
    }
    if (dataClassName == 'PulseMonitorMembership') {
      return deserialize<_i205.PulseMonitorMembership>(data['data']);
    }
    if (dataClassName == 'PulseProbeAllowlistEntry') {
      return deserialize<_i206.PulseProbeAllowlistEntry>(data['data']);
    }
    if (dataClassName == 'PulseTlsProbe') {
      return deserialize<_i207.PulseTlsProbe>(data['data']);
    }
    if (dataClassName == 'PulseValueThreshold') {
      return deserialize<_i208.PulseValueThreshold>(data['data']);
    }
    if (dataClassName == 'PushQueueMessage') {
      return deserialize<_i209.PushQueueMessage>(data['data']);
    }
    if (dataClassName == 'PushTestJob') {
      return deserialize<_i210.PushTestJob>(data['data']);
    }
    if (dataClassName == 'PushTestResult') {
      return deserialize<_i211.PushTestResult>(data['data']);
    }
    if (dataClassName == 'Room') {
      return deserialize<_i212.Room>(data['data']);
    }
    if (dataClassName == 'RoomBotCommands') {
      return deserialize<_i213.RoomBotCommands>(data['data']);
    }
    if (dataClassName == 'RoomDeliveryBackstop') {
      return deserialize<_i214.RoomDeliveryBackstop>(data['data']);
    }
    if (dataClassName == 'RoomDetails') {
      return deserialize<_i215.RoomDetails>(data['data']);
    }
    if (dataClassName == 'RoomListPage') {
      return deserialize<_i216.RoomListPage>(data['data']);
    }
    if (dataClassName == 'RoomMembership') {
      return deserialize<_i217.RoomMembership>(data['data']);
    }
    if (dataClassName == 'RoomParticipant') {
      return deserialize<_i218.RoomParticipant>(data['data']);
    }
    if (dataClassName == 'RoomSummary') {
      return deserialize<_i219.RoomSummary>(data['data']);
    }
    if (dataClassName == 'RoomTaskStats') {
      return deserialize<_i220.RoomTaskStats>(data['data']);
    }
    if (dataClassName == 'RoomTaskView') {
      return deserialize<_i221.RoomTaskView>(data['data']);
    }
    if (dataClassName == 'Sticker') {
      return deserialize<_i222.Sticker>(data['data']);
    }
    if (dataClassName == 'StickerPack') {
      return deserialize<_i223.StickerPack>(data['data']);
    }
    if (dataClassName == 'StickerPackView') {
      return deserialize<_i224.StickerPackView>(data['data']);
    }
    if (dataClassName == 'SupportTeam') {
      return deserialize<_i225.SupportTeam>(data['data']);
    }
    if (dataClassName == 'SupportTeamExclusion') {
      return deserialize<_i226.SupportTeamExclusion>(data['data']);
    }
    if (dataClassName == 'SupportTeamMember') {
      return deserialize<_i227.SupportTeamMember>(data['data']);
    }
    if (dataClassName == 'SupportTeamMemberView') {
      return deserialize<_i228.SupportTeamMemberView>(data['data']);
    }
    if (dataClassName == 'SupportTeamView') {
      return deserialize<_i229.SupportTeamView>(data['data']);
    }
    if (dataClassName == 'TaskLink') {
      return deserialize<_i230.TaskLink>(data['data']);
    }
    if (dataClassName == 'TaskManagerConfig') {
      return deserialize<_i231.TaskManagerConfig>(data['data']);
    }
    if (dataClassName == 'Team') {
      return deserialize<_i232.Team>(data['data']);
    }
    if (dataClassName == 'TeamMember') {
      return deserialize<_i233.TeamMember>(data['data']);
    }
    if (dataClassName == 'TeamMemberView') {
      return deserialize<_i234.TeamMemberView>(data['data']);
    }
    if (dataClassName == 'TeamView') {
      return deserialize<_i235.TeamView>(data['data']);
    }
    if (dataClassName == 'Tenant') {
      return deserialize<_i236.Tenant>(data['data']);
    }
    if (dataClassName == 'TenantSupportMember') {
      return deserialize<_i237.TenantSupportMember>(data['data']);
    }
    if (dataClassName == 'TenantSupportMemberView') {
      return deserialize<_i238.TenantSupportMemberView>(data['data']);
    }
    if (dataClassName == 'ThreadReadState') {
      return deserialize<_i239.ThreadReadState>(data['data']);
    }
    if (dataClassName == 'Ticket') {
      return deserialize<_i240.Ticket>(data['data']);
    }
    if (dataClassName == 'TicketEvent') {
      return deserialize<_i241.TicketEvent>(data['data']);
    }
    if (dataClassName == 'TicketView') {
      return deserialize<_i242.TicketView>(data['data']);
    }
    if (dataClassName == 'TrustRedeemResult') {
      return deserialize<_i243.TrustRedeemResult>(data['data']);
    }
    if (dataClassName == 'TrustToken') {
      return deserialize<_i244.TrustToken>(data['data']);
    }
    if (dataClassName == 'TrustTokenIssued') {
      return deserialize<_i245.TrustTokenIssued>(data['data']);
    }
    if (dataClassName == 'TurnCredentials') {
      return deserialize<_i246.TurnCredentials>(data['data']);
    }
    if (dataClassName == 'WebhookDelivery') {
      return deserialize<_i247.WebhookDelivery>(data['data']);
    }
    if (dataClassName == 'WebhookEventMessage') {
      return deserialize<_i248.WebhookEventMessage>(data['data']);
    }
    if (dataClassName == 'WebhookSubscription') {
      return deserialize<_i249.WebhookSubscription>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i306.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i307.Protocol().deserializeByClassName(data);
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
      return _i306.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i307.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
