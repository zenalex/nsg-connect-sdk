// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'nsg_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class NsgL10nEn extends NsgL10n {
  NsgL10nEn([String locale = 'en']) : super(locale);

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonNewChat => 'New chat';

  @override
  String get commonConnectionLost => 'Connection lost — showing cache';

  @override
  String get chatsListTitle => 'Chats';

  @override
  String get chatsListEmpty => 'No chats yet';

  @override
  String get chatsListLoadFailed => 'Failed to load chats';

  @override
  String get createChatInvalidId => 'Enter numeric messengerUserId';

  @override
  String get createChatPeerUnavailable => 'User unavailable';

  @override
  String get createChatHelp =>
      'Direct chat by messengerUserId. Name search — TASK42.';

  @override
  String get createChatSubmit => 'Create direct chat';

  @override
  String get chatScreenEmpty => 'No messages yet — write the first one';

  @override
  String get chatScreenLoadFailed => 'Failed to load messages';

  @override
  String get chatScreenSendHint => 'Message…';

  @override
  String get chatScreenSendTooltip => 'Send';

  @override
  String get roomSummaryNoName => '(no name)';

  @override
  String get roomSummaryNoMessages => 'No messages';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get roomActionSheetTitle => 'Chat actions';

  @override
  String get roomActionMute => 'Mute';

  @override
  String get roomActionUnmute => 'Unmute';

  @override
  String get roomActionMuteFor1Hour => '1 hour';

  @override
  String get roomActionMuteFor8Hours => '8 hours';

  @override
  String get roomActionMuteFor1Day => '1 day';

  @override
  String get roomActionMuteFor1Week => '1 week';

  @override
  String get roomActionMuteForever => 'Forever';

  @override
  String get roomActionMuteUntilTitle => 'Mute until';

  @override
  String get roomActionArchive => 'Archive';

  @override
  String get roomActionUnarchive => 'Unarchive';

  @override
  String get roomActionDismissSupport => 'Close (until reply)';

  @override
  String get roomActionLeave => 'Leave chat';

  @override
  String get roomActionLeaveConfirmTitle => 'Leave chat?';

  @override
  String get roomActionLeaveConfirmBody =>
      'You will be removed from the conversation. Other participants will see that you left.';

  @override
  String get roomActionFailedSnack => 'Action failed — try again';

  @override
  String get chatsListFilterMenuTooltip => 'Filter';

  @override
  String get chatsListFilterActive => 'Active';

  @override
  String get chatsListFilterArchived => 'Archived';

  @override
  String get chatsListFilterAll => 'All';

  @override
  String get chatsListSearchTooltip => 'Search';

  @override
  String get chatsListSearchHint => 'Search chats…';

  @override
  String get chatsListSearchClearTooltip => 'Clear';

  @override
  String get chatsListSearchEmpty => 'No matches';

  @override
  String get chatsListProductFilterTooltip => 'Product';

  @override
  String get chatsListProductFilterAll => 'All products';

  @override
  String get chatsListFolderAll => 'All';

  @override
  String get chatsListFolderPersonal => 'Personal';

  @override
  String chatsListFolderProductFallback(int productId) {
    return 'Product $productId';
  }

  @override
  String chatsListFolderRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chats',
      one: '$count chat',
    );
    return '$_temp0';
  }

  @override
  String get chatsListFolderSupportSection => 'Support';

  @override
  String get chatsListFolderOtherSection => 'Chats';

  @override
  String get chatsListFolderSupport => 'Support';

  @override
  String get chatsListFolderCustom => 'Folder';

  @override
  String get savedChatsTitle => 'Saved';

  @override
  String get savedChatsCreateAction => 'New section';

  @override
  String get savedChatsCreateHint => 'Section name';

  @override
  String get savedChatsEmpty =>
      'Send yourself notes, files and links — they sync across all your devices.';

  @override
  String savedChatsLimitReached(int limit) {
    return 'Section limit reached ($limit). Delete an unused one first.';
  }

  @override
  String get savedChatsNameTaken => 'A section with this name already exists.';

  @override
  String get autoCleanupTitle => 'Auto-delete messages';

  @override
  String get autoCleanupHint => 'Pinned messages are never deleted';

  @override
  String get autoCleanupOff => 'Never';

  @override
  String autoCleanupAfterDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'After $days days',
      one: 'After $days day',
    );
    return '$_temp0';
  }

  @override
  String get attachActionSheetTitle => 'Attach';

  @override
  String get attachActionCamera => 'Camera';

  @override
  String get attachActionGallery => 'Gallery';

  @override
  String get attachActionImage => 'Image';

  @override
  String get attachActionFile => 'File';

  @override
  String attachFileTooLarge(String names) {
    return 'Too large (limit 50 MB), not attached: $names';
  }

  @override
  String get attachUploadFailed => 'Upload failed — try again';

  @override
  String get attachUnnamedFallback => 'Unnamed file';

  @override
  String get attachTooltip => 'Attach file';

  @override
  String get voiceRecordTooltip => 'Hold to record';

  @override
  String get voiceRecordingHint => 'Recording…';

  @override
  String get voiceRecordTooShort => 'Recording too short';

  @override
  String get voiceRecordPermissionDenied => 'Microphone permission denied';

  @override
  String get voiceRecordError => 'Recording failed';

  @override
  String get messageActionSheetTitle => 'Message';

  @override
  String get messageActionEdit => 'Edit';

  @override
  String get messageActionDelete => 'Delete';

  @override
  String get messageActionCopy => 'Copy';

  @override
  String get messageActionEditDialogTitle => 'Edit message';

  @override
  String get messageActionEditSave => 'Save';

  @override
  String get messageActionDeleteConfirmTitle => 'Delete message?';

  @override
  String get messageActionDeleteConfirmBody =>
      'This action cannot be undone. The message will be removed for everyone in the chat.';

  @override
  String get messageEditFailed => 'Edit failed — try again';

  @override
  String get messageDeleteFailed => 'Delete failed — try again';

  @override
  String get messageDeletedPlaceholder => 'Message deleted';

  @override
  String get messageEditedBadge => 'edited';

  @override
  String get messageShowMore => 'Show more';

  @override
  String get messageCopiedSnack => 'Copied';

  @override
  String get messageActionReply => 'Reply';

  @override
  String get messageActionReplyWithMention => 'Reply with mention';

  @override
  String get mentionParticipantAction => 'Mention';

  @override
  String get emojiPickerTitle => 'Choose a reaction';

  @override
  String get emojiCategorySmileys => 'Smileys & emotion';

  @override
  String get emojiCategoryGestures => 'Gestures & people';

  @override
  String get emojiCategoryHearts => 'Hearts & symbols';

  @override
  String get emojiCategoryAnimals => 'Animals & nature';

  @override
  String get emojiCategoryFood => 'Food & drink';

  @override
  String get emojiCategoryActivity => 'Activity & objects';

  @override
  String get emojiCategorySymbols => 'Symbols';

  @override
  String get messageActionCreateTask => 'Create task';

  @override
  String taskCreatedSnack(String taskKey) {
    return 'Task $taskKey created';
  }

  @override
  String get taskCreateFailed => 'Couldn\'t create task';

  @override
  String get taskIntegrationDisabled => 'Task integration is not configured';

  @override
  String composerReplyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get composerCancelReply => 'Cancel reply';

  @override
  String get composerEditing => 'Editing';

  @override
  String get composerEditingAlbum => 'Editing album';

  @override
  String get composerFormatBold => 'Bold';

  @override
  String get composerFormatItalic => 'Italic';

  @override
  String get composerCancelEdit => 'Cancel edit';

  @override
  String get messageComposerSaveTooltip => 'Save';

  @override
  String typingSingle(String name) {
    return '$name is typing…';
  }

  @override
  String typingPair(String name1, String name2) {
    return '$name1 and $name2 are typing…';
  }

  @override
  String get roomRenameTitle => 'Rename chat';

  @override
  String get roomRenameHint => 'New chat name';

  @override
  String get roomRenameSave => 'Save';

  @override
  String get roomRenameCancel => 'Cancel';

  @override
  String get roomRenameFailed =>
      'Couldn\'t rename the chat — try again or check your role';

  @override
  String get readReceiptsSheetTitle => 'Seen by';

  @override
  String get readReceiptsSectionRead => 'Read';

  @override
  String get readReceiptsSectionUnread => 'Not read';

  @override
  String readReceiptsLargeGroupHint(int count, int total) {
    return 'Detailed read list is only available for groups of up to 25 members. $count of $total have read.';
  }

  @override
  String get readReceiptsNobodyRead => 'No one has read yet';

  @override
  String readReceiptsCountLabel(int count) {
    return '$count';
  }

  @override
  String get groupDissolveAction => 'Delete group';

  @override
  String groupDissolveConfirmTitle(String name) {
    return 'Delete group «$name»?';
  }

  @override
  String get groupDissolveConfirmBody =>
      'All members will be removed and the chat will close. This cannot be undone.';

  @override
  String get groupDissolveProgress => 'Deleting group…';

  @override
  String groupDissolveFailed(int kicked, int total) {
    return 'Couldn\'t fully delete — try again. Members removed: $kicked of $total.';
  }

  @override
  String get groupDissolveSuccess => 'Group deleted';

  @override
  String typingManyCount(int count) {
    return '$count people are typing…';
  }

  @override
  String get replyChipUnavailable => 'Original message unavailable';

  @override
  String get mentionTypeaheadEmpty => 'No matches';

  @override
  String mentionTypeaheadShowingHeader(int shown, int total) {
    return 'Showing $shown of $total';
  }

  @override
  String get roleBadgeOwner => 'Owner';

  @override
  String get roleBadgeAdmin => 'Admin';

  @override
  String get roomAdminKickAction => 'Kick from room';

  @override
  String get roomAdminBanAction => 'Ban from room';

  @override
  String get roomAdminPromoteAction => 'Promote to admin';

  @override
  String get roomAdminPromoteOwnerAction => 'Promote to owner';

  @override
  String get roomAdminDemoteAction => 'Demote to member';

  @override
  String roomAdminKickConfirmTitle(String name) {
    return 'Kick $name?';
  }

  @override
  String roomAdminKickConfirmBody(String name) {
    return '$name can be re-invited later.';
  }

  @override
  String roomAdminBanConfirmTitle(String name) {
    return 'Ban $name?';
  }

  @override
  String roomAdminBanConfirmBody(String name) {
    return '$name cannot rejoin until unbanned.';
  }

  @override
  String get roomAdminLastOwnerError =>
      'Cannot demote the last owner. Promote another member first.';

  @override
  String get roomAdminInsufficientPowerError =>
      'You don\'t have permission to perform this action.';

  @override
  String get roomAdminGenericError => 'Action failed — try again.';

  @override
  String get bannedUsersTitle => 'Banned users';

  @override
  String get bannedUsersEmpty => 'No banned users';

  @override
  String get bannedUsersUnbanAction => 'Unban';

  @override
  String get bannedUsersUnbanSuccess =>
      'Unbanned — invite them again if needed';

  @override
  String get bannedUsersReinviteAction => 'Re-invite';

  @override
  String get bannedUsersReinviteSuccess => 'Invitation sent';

  @override
  String get participantsTitle => 'Participants';

  @override
  String get participantsBannedMenuItem => 'Banned users';

  @override
  String get notificationSettingsTitle => 'Notifications';

  @override
  String get notificationSettingsPreviewTitle => 'Show message preview';

  @override
  String get notificationSettingsPreviewSubtitle =>
      'Display sender and message text on the lock screen. Turn off to hide content.';

  @override
  String get notificationSettingsReadReceiptsTitle => 'Send read receipts';

  @override
  String get notificationSettingsReadReceiptsSubtitle =>
      'Others see when you\'ve read their messages. Turn off to read privately.';

  @override
  String get notificationSettingsSaveFailed =>
      'Couldn\'t save settings — try again';

  @override
  String get settingsPrivacySectionTitle => 'Privacy';

  @override
  String get notificationSettingsDiscoverableTitle => 'Findable in search';

  @override
  String get notificationSettingsDiscoverableSubtitle =>
      'Others can find you by name or email. Turn off to hide from search.';

  @override
  String get connectionStateHealthy => 'Connected';

  @override
  String get connectionStateReconnecting => 'Reconnecting…';

  @override
  String get connectionStateDisconnected => 'Connection lost';

  @override
  String get supportTeamTitle => 'Support team';

  @override
  String get supportTeamEmpty => 'No team members yet';

  @override
  String get supportTeamAddHint => 'Add operator by email';

  @override
  String get supportTeamAddAction => 'Add';

  @override
  String get supportTeamRemoveAction => 'Remove';

  @override
  String get supportTeamTierEscalation => 'Escalation';

  @override
  String get supportTeamMakeEscalation => 'Make senior (escalation)';

  @override
  String get supportTeamMakeFrontline => 'Move back to front line';

  @override
  String get supportTeamMakeOwner => 'Make admin';

  @override
  String get supportTeamRevokeOwner => 'Revoke admin';

  @override
  String get supportTeamTimeoutLabel => 'Auto-escalation timeout';

  @override
  String get supportTeamMinutesShort => 'min';

  @override
  String get supportTeamRoleOwner => 'Owner';

  @override
  String get supportTeamRoleMember => 'Operator';

  @override
  String get supportTeamBotBadge => 'Bot';

  @override
  String get supportTeamUnavailable => 'Support team is not available';

  @override
  String get supportTeamActionFailed => 'Action failed — please try again';

  @override
  String get escalateToDevelopersAction => 'Contact developers';

  @override
  String get escalateToDevelopersDone => 'NSG team connected';

  @override
  String get escalateToDevelopersFailed =>
      'Failed to connect the team — please try again';

  @override
  String get escalateSupportAction => 'Call senior operator';

  @override
  String get escalateSupportDone => 'Senior operator connected';

  @override
  String get escalateSupportFailed => 'Escalation failed — please try again';

  @override
  String get escalateSupportNoop =>
      'No one to escalate — no higher tier or already here';

  @override
  String objectRoomsCatalogTitle(String product) {
    return 'Object chats — $product';
  }

  @override
  String get objectRoomsCatalogEmpty => 'No object chats yet';

  @override
  String get objectRoomsCatalogUnavailable => 'Catalog is not available';

  @override
  String get objectRoomsCatalogJoinFailed =>
      'Failed to join the chat — please try again';

  @override
  String get objectRoomsCatalogMemberBadge => 'Joined';

  @override
  String get objectRoomsCatalogLeaveAction => 'Leave chat';

  @override
  String get objectRoomsCatalogLeaveDone => 'You left the chat';

  @override
  String get objectRoomsCatalogEntry => 'Object chats';

  @override
  String get callStartTooltip => 'Call';

  @override
  String get callAlreadyActive => 'A call is already in progress';

  @override
  String callOutgoingTitle(String peer) {
    return 'Calling $peer…';
  }

  @override
  String callIncomingTitle(String caller) {
    return '$caller is calling';
  }

  @override
  String get callIncomingSubtitle => 'Incoming call';

  @override
  String get callConnecting => 'Connecting…';

  @override
  String get callAccept => 'Accept';

  @override
  String get callDecline => 'Decline';

  @override
  String get callHangup => 'Hang up';

  @override
  String get callMute => 'Mute';

  @override
  String get callUnmute => 'Unmute';

  @override
  String get callSpeakerOn => 'Speaker on';

  @override
  String get callSpeakerOff => 'Speaker off';

  @override
  String get callPeerFallback => 'Contact';

  @override
  String get callEndedGeneric => 'Call ended';

  @override
  String get callEndedDeclined => 'Call declined';

  @override
  String get callEndedMicDenied => 'Allow microphone access';

  @override
  String get callEndedFailed => 'Call error';

  @override
  String get messageActionForward => 'Forward';

  @override
  String get messageActionPin => 'Pin';

  @override
  String get messageActionUnpin => 'Unpin';

  @override
  String get pinnedMessagesTitle => 'Pinned message';

  @override
  String get messagePinnedSnack => 'Message pinned';

  @override
  String get messageUnpinnedSnack => 'Message unpinned';

  @override
  String get pinMessageFailed => 'Failed to pin message';

  @override
  String get unpinMessageFailed => 'Failed to unpin message';

  @override
  String get pinNotAllowed => 'Only admins can pin messages here';

  @override
  String get messageActionSelect => 'Select';

  @override
  String selectedCountTitle(int count) {
    return '$count selected';
  }

  @override
  String get messageActionShare => 'Share';

  @override
  String get forwardPickerTitle => 'Forward to…';

  @override
  String get forwardSearchHint => 'Search chats';

  @override
  String get forwardNoRooms => 'No chats to forward to';

  @override
  String get forwardedSnack => 'Forwarded';

  @override
  String forwardMultiButton(int count) {
    return 'Forward ($count)';
  }

  @override
  String forwardedToChatsSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Forwarded to $count chats',
      one: 'Forwarded to $count chat',
    );
    return '$_temp0';
  }

  @override
  String get forwardOpenChat => 'Open';

  @override
  String get forwardFailed => 'Couldn\'t forward — try again';

  @override
  String get shareFailed => 'Couldn\'t share — try again';

  @override
  String get messageActionCopyImage => 'Copy image';

  @override
  String get imageCopiedSnack => 'Image copied to clipboard';

  @override
  String get imageCopyFailed => 'Couldn\'t copy the image';

  @override
  String get sharePickerTitle => 'Send to…';

  @override
  String shareConfirmTitle(String name) {
    return 'Send to $name?';
  }

  @override
  String shareConfirmFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '$count file',
    );
    return '$_temp0';
  }

  @override
  String get shareSend => 'Send';

  @override
  String shareProgress(int current, int total) {
    return 'Sending $current of $total…';
  }

  @override
  String get shareSent => 'Sent';

  @override
  String get shareQueued => 'Added to send queue';

  @override
  String get shareSomeFailed => 'Some items couldn\'t be sent';

  @override
  String shareFileTooLarge(String names) {
    return 'Too large to send: $names';
  }

  @override
  String get shareBusy => 'Sending is still in progress';

  @override
  String messageForwardedFrom(String name) {
    return 'Forwarded from $name';
  }

  @override
  String get forwardSourceUnavailable => 'Source chat is unavailable';

  @override
  String get commonOk => 'OK';

  @override
  String get statusCardOpenLink => 'Open';

  @override
  String get integrationsTitle => 'Integrations';

  @override
  String get integrationsAutopostsSection => 'Autoposts';

  @override
  String get integrationsBotsSection => 'Bots';

  @override
  String get integrationsAddAutopost => 'Add autopost';

  @override
  String get integrationsEmpty => 'No autoposts yet';

  @override
  String get integrationsLoadFailed => 'Failed to load integrations';

  @override
  String get integrationsNameLabel => 'Name';

  @override
  String get integrationsNameHint => 'e.g. CI · Deploy';

  @override
  String get integrationsCreate => 'Create';

  @override
  String get integrationsWebhookUrlLabel => 'Webhook URL';

  @override
  String get integrationsWebhookUrlOnce =>
      'Copy this URL now — the token is shown only once.';

  @override
  String get integrationsCopied => 'URL copied';

  @override
  String get integrationsCopy => 'Copy';

  @override
  String get integrationsTestPost => 'Test post';

  @override
  String get integrationsRotateToken => 'Regenerate token';

  @override
  String get integrationsEnable => 'Enable';

  @override
  String get integrationsDisable => 'Disable';

  @override
  String get integrationsDelete => 'Delete';

  @override
  String get integrationsDeleteConfirmTitle => 'Delete autopost?';

  @override
  String get integrationsDeleteConfirmBody =>
      'The webhook will stop working and its URL will be revoked.';

  @override
  String get integrationsDisabledBadge => 'disabled';

  @override
  String integrationsLastPost(String when) {
    return 'last post $when';
  }

  @override
  String get integrationsNeverPosted => 'no posts yet';

  @override
  String get integrationsTestPostSent => 'Test post sent';

  @override
  String get integrationsActionFailed => 'Action failed — try again';

  @override
  String get integrationsCopiedGeneric => 'Copied';

  @override
  String get integrationsAddBot => 'Add bot';

  @override
  String get integrationsBotsEmpty => 'No bots yet';

  @override
  String get integrationsBotNameHint => 'e.g. Deploy Bot';

  @override
  String get integrationsBotWebhookUrlLabel => 'Webhook URL';

  @override
  String get integrationsBotWebhookUrlHint => 'https://example.com/webhook';

  @override
  String get integrationsBotWebhookUrlInvalid => 'Enter a valid https:// URL';

  @override
  String get integrationsBotCredentialsTitle => 'Bot credentials';

  @override
  String get integrationsBotCredentialsOnce =>
      'These secrets are shown only once — copy them now.';

  @override
  String get integrationsBotTokenLabel => 'Bot token';

  @override
  String get integrationsBotSecretLabel => 'Webhook secret';

  @override
  String get integrationsApiBaseLabel => 'API base';

  @override
  String get integrationsRoomIdLabel => 'Room ID';

  @override
  String get integrationsBotUserIdLabel => 'Bot user id';

  @override
  String get integrationsBotUserIdCaption =>
      'Use it to filter out the bot\'s own echoed messages.';

  @override
  String get integrationsEventsLabel => 'Events';

  @override
  String get integrationsBotHandoffHint =>
      'Hand these credentials to your developer together with a link to the documentation.';

  @override
  String get integrationsRotateSecret => 'Regenerate secret';

  @override
  String get integrationsBotDeleteConfirmTitle => 'Delete bot?';

  @override
  String get integrationsBotDeleteConfirmBody =>
      'The bot will be removed from the room and its webhook subscription deleted.';

  @override
  String get botsAdminTitle => 'Bots';

  @override
  String get botsAdminEmpty =>
      'No bots yet. A bot is a program that posts to chats with its own token.';

  @override
  String get botsAdminLoadFailed => 'Failed to load bots';

  @override
  String get botsAdminActionFailed => 'Action failed — try again';

  @override
  String get botsAdminCreate => 'Add bot';

  @override
  String get botsAdminNameLabel => 'Name';

  @override
  String get botsAdminNameHint => 'Deploy notifier';

  @override
  String get botsAdminOwnerEmailLabel => 'Owner email';

  @override
  String get botsAdminOwnerEmailHint => 'owner@company.com';

  @override
  String get botsAdminCapabilitiesLabel => 'What the bot is allowed to do';

  @override
  String get botsAdminCapReadOnly => 'Read only';

  @override
  String get botsAdminCapSendMessages => 'Send messages';

  @override
  String get botsAdminCapManageRoom => 'Manage chats';

  @override
  String get botsAdminCapWebhookTarget => 'Receive webhooks';

  @override
  String get botsAdminNoCapabilities => 'no capabilities';

  @override
  String get botsAdminTokenTitle => 'Bot access token';

  @override
  String get botsAdminTokenOnce =>
      'Shown once. Save it now — if lost, the only way back is to rotate the token.';

  @override
  String get botsAdminRotateToken => 'Rotate token';

  @override
  String get botsAdminRotateConfirmTitle => 'Rotate token?';

  @override
  String get botsAdminRotateConfirmBody =>
      'The current token stops working immediately. The bot will go silent until its program is updated with the new token. The bot itself, its chats and its history are kept.';

  @override
  String get botsAdminEnable => 'Enable';

  @override
  String get botsAdminDisable => 'Disable';

  @override
  String get botsAdminDisabledBadge => 'disabled';

  @override
  String get botsAdminAddToRoom => 'Add to chat';

  @override
  String get botsAdminAddToRoomTitle => 'Choose a chat';

  @override
  String get botsAdminAddedToRoom => 'Bot added to the chat';

  @override
  String get botsAdminAlreadyInRoom => 'Already added';

  @override
  String get botsAdminNoRooms => 'No chats available';

  @override
  String get botsAdminAudit => 'Audit log';

  @override
  String botsAdminAuditTitle(String name) {
    return 'Audit log — $name';
  }

  @override
  String get botsAdminAuditEmpty => 'No events yet';

  @override
  String get botsAdminAuditActorBot => 'the bot itself';

  @override
  String get botsAdminAuditActorSystem => 'system';

  @override
  String get botsAdminAuditCreated => 'Bot created';

  @override
  String get botsAdminAuditTokenRotated => 'Token rotated';

  @override
  String get botsAdminAuditEnabled => 'Enabled';

  @override
  String get botsAdminAuditDisabled => 'Disabled';

  @override
  String get botsAdminAuditAddedToRoom => 'Added to a chat';

  @override
  String get botsAdminAuditCapabilityDenied => 'Action denied';

  @override
  String get botsAdminAuditRemovedFromRoom => 'Removed from a chat';

  @override
  String get botsAdminAuditDiscoverableOn => 'Made visible in search';

  @override
  String get botsAdminAuditDiscoverableOff => 'Hidden from search';

  @override
  String get platformAdminTitle => 'Platform';

  @override
  String get platformAdminEmpty =>
      'No tenants — or no access. The list is served only to platform admins.';

  @override
  String get platformAdminActionFailed => 'Action failed — try again';

  @override
  String get platformAdminStatusEnabled => 'enabled';

  @override
  String get platformAdminStatusDisabled => 'disabled';

  @override
  String get platformAdminSecretSet => 'secret set';

  @override
  String get platformAdminSecretMissing => 'no secret';

  @override
  String platformAdminGraceUntil(String until) {
    return 'previous secret valid until $until';
  }

  @override
  String get platformAdminEnableGenerate => 'Enable & generate secret';

  @override
  String get platformAdminRotate => 'Rotate secret';

  @override
  String get platformAdminRotateTitle => 'Rotate secret?';

  @override
  String get platformAdminRotateBody =>
      'A new secret will be issued. The old one keeps working for the grace period below, then dies.';

  @override
  String platformAdminGraceLabel(int max) {
    return 'Grace, minutes (max $max)';
  }

  @override
  String get platformAdminSecretTitle => 'Tenant service secret';

  @override
  String get platformAdminSecretOnce =>
      'The secret is shown ONCE. The server stores only its hash — if lost, the only way back is rotation.';

  @override
  String get platformAdminDisable => 'Disable';

  @override
  String get platformAdminDisableConfirmTitle => 'Disable issued-token mode?';

  @override
  String get platformAdminDisableConfirmBody =>
      'Kill-switch: both secret hashes are wiped and the product loses access immediately. Re-enabling issues a brand-new secret.';

  @override
  String get platformAdminAudit => 'Audit log';

  @override
  String platformAdminAuditTitle(String name) {
    return 'Audit — $name';
  }

  @override
  String get platformAdminAuditEmpty => 'No events yet';

  @override
  String get platformAdminAuditEnabledGenerated => 'Enabled, secret generated';

  @override
  String get platformAdminAuditRotated => 'Secret rotated';

  @override
  String get platformAdminAuditDisabled => 'Disabled';

  @override
  String get myBotsTitle => 'My bots';

  @override
  String get myBotsEmpty =>
      'No bots yet. A bot is a program that posts to chats under its own account using an access token: deploy notifications, reminders, integrations. Create one, add it to your chats — or make it public so others can find it in search.';

  @override
  String get myBotsDiscoverable => 'Visible in search';

  @override
  String get myBotsDiscoverableSubtitle =>
      'Anyone can find the bot and add it to their chats';

  @override
  String get myBotsPublicBadge => 'in search';

  @override
  String get myBotsMakeDiscoverable => 'Show in search';

  @override
  String get myBotsMakeHidden => 'Hide from search';

  @override
  String get myBotsRooms => 'Bot\'s chats';

  @override
  String myBotsRoomsTitle(String name) {
    return 'Chats — $name';
  }

  @override
  String get myBotsRoomsEmpty => 'The bot is not in any chats yet';

  @override
  String get myBotsRevoke => 'Remove';

  @override
  String get myBotsRevokeConfirmTitle => 'Remove bot from this chat?';

  @override
  String get myBotsRevokeConfirmBody =>
      'The bot will leave the chat. Its messages stay; the bot can be added back later.';

  @override
  String get myBotsRevoked => 'Bot removed from the chat';

  @override
  String myBotsLimitReached(int limit) {
    return 'Bot limit reached ($limit). Rotate a token or reuse an existing bot instead of creating a new one.';
  }

  @override
  String get pulseTitle => 'Monitoring';

  @override
  String get pulseNoAccess => 'You don\'t have access to monitoring.';

  @override
  String get pulseEmpty => 'No monitors yet';

  @override
  String get pulseLoadFailed => 'Failed to load monitoring';

  @override
  String get pulseActionFailed => 'Action failed — try again';

  @override
  String get pulseAddFolder => 'Folder';

  @override
  String get pulseAddMonitor => 'Monitor';

  @override
  String get pulseNewFolder => 'New folder';

  @override
  String get pulseNewMonitor => 'New monitor';

  @override
  String get pulseNameLabel => 'Name';

  @override
  String get pulseFolderNameHint => 'e.g. Production';

  @override
  String get pulseMonitorNameHint => 'e.g. Nightly backup';

  @override
  String get pulseCreate => 'Create';

  @override
  String get pulseRename => 'Rename';

  @override
  String get pulseParentFolderLabel => 'Folder';

  @override
  String get pulseFolderRoot => 'Root';

  @override
  String get pulsePeriodLabel => 'Period';

  @override
  String get pulseGraceLabel => 'Grace period (sec)';

  @override
  String get pulsePeriod60s => '60 sec';

  @override
  String get pulsePeriod5m => '5 min';

  @override
  String get pulsePeriod15m => '15 min';

  @override
  String get pulsePeriod1h => '1 hour';

  @override
  String get pulsePeriod24h => '24 hours';

  @override
  String pulseLastSignal(String when) {
    return 'signal $when';
  }

  @override
  String get pulseNoSignal => 'no signal yet';

  @override
  String get pulseBadgeLate => 'late';

  @override
  String get pulseBadgeDown => 'down';

  @override
  String get pulsePaused => 'paused';

  @override
  String pulseDetailPeriodGrace(String period, int grace) {
    return 'Period $period · grace ${grace}s';
  }

  @override
  String get pulseLastSignalLabel => 'Last signal';

  @override
  String get pulseIncidents => 'Incidents';

  @override
  String get pulseNoIncidents => 'No incidents';

  @override
  String get pulseAck => 'Take';

  @override
  String get pulseIncidentOpen => 'open';

  @override
  String get pulseIncidentResolved => 'resolved';

  @override
  String get pulseIncidentAcked => 'in progress';

  @override
  String get pulsePause => 'Pause';

  @override
  String get pulseResume => 'Resume';

  @override
  String get pulseRotateToken => 'Regenerate token';

  @override
  String get pulseDelete => 'Delete';

  @override
  String get pulseDeleteMonitorConfirmTitle => 'Delete monitor?';

  @override
  String get pulseDeleteMonitorConfirmBody =>
      'The monitor and its beat token will stop working and its history will be removed.';

  @override
  String get pulseDeleteFolderConfirmTitle => 'Delete folder?';

  @override
  String get pulseDeleteFolderConfirmBody =>
      'Only empty folders can be deleted.';

  @override
  String get pulseFolderNotEmpty => 'Folder is not empty';

  @override
  String get pulseBeatUrlLabel => 'Beat URL';

  @override
  String get pulseBeatUrlOnce =>
      'Copy this now — the token is shown only once.';

  @override
  String get pulseCurlHint => 'Ready-to-use snippet:';

  @override
  String get pulseCopy => 'Copy';

  @override
  String get pulseCopied => 'Copied';

  @override
  String get pulseAlerts => 'Alerts';

  @override
  String get pulseAddRule => 'Add rule';

  @override
  String get pulseNoRules => 'No alert rules';

  @override
  String get pulseRoomLabel => 'Room';

  @override
  String get pulsePickRoom => 'Pick a room';

  @override
  String get pulseMinSeverityLabel => 'Minimum severity';

  @override
  String get pulseSeverityWarn => 'Warning';

  @override
  String get pulseSeverityError => 'Error';

  @override
  String get pulseSeverityDown => 'Down';

  @override
  String get pulseEscalateAfterLabel => 'Escalate after (min)';

  @override
  String get pulseLevel1Label => 'Responsible (MUID)';

  @override
  String get pulseLevel1Helper =>
      'Comma-separated messenger user ids to DM on escalation.';

  @override
  String pulseRuleSummary(String severity, String room) {
    return '≥ $severity → room $room';
  }

  @override
  String get pulseDeleteRule => 'Delete rule';

  @override
  String get contactTitle => 'Contact';

  @override
  String get contactCustomNameLabel => 'Custom name';

  @override
  String get contactCustomNameHelper =>
      'Only you see it — in the chat list and participants';

  @override
  String get contactNoteLabel => 'Note';

  @override
  String get contactNoteHelper => 'Private note about this contact';

  @override
  String get contactSave => 'Save';

  @override
  String get contactSaved => 'Saved';

  @override
  String get contactSaveFailed => 'Failed to save';

  @override
  String get contactLabelsTitle => 'Labels';

  @override
  String get contactNewLabel => 'New label';

  @override
  String get contactNewLabelHint => 'E.g.: office, Moscow…';

  @override
  String get contactCreate => 'Create';

  @override
  String get contactCreateLabelFailed => 'Failed to create label';

  @override
  String contactRenameLabelMenu(Object name) {
    return 'Rename “$name”';
  }

  @override
  String get contactRenameLabelTitle => 'Rename label';

  @override
  String get contactDeleteLabel => 'Delete label';

  @override
  String contactDeleteLabelConfirm(Object name) {
    return 'Delete label “$name”?';
  }

  @override
  String get contactDeleteLabelBody =>
      'The label will be removed from all contacts.';

  @override
  String get contactDelete => 'Delete';

  @override
  String get contactRenameFailed => 'Failed to rename';

  @override
  String get contactDeleteLabelFailed => 'Failed to delete label';

  @override
  String get contactLoadFailed => 'Failed to load contact';

  @override
  String get contactBlock => 'Block';

  @override
  String get contactUnblock => 'Unblock';

  @override
  String get contactBlocked => 'Blocked';

  @override
  String contactBlockConfirm(Object name) {
    return 'Block $name?';
  }

  @override
  String get contactBlockBody =>
      'They won\'t be able to message you, and you both stop getting notifications from each other. You can undo this later.';

  @override
  String get contactBlockFailed => 'Failed to block';

  @override
  String get contactUnblockFailed => 'Failed to unblock';

  @override
  String get contactUnblocked => 'Unblocked';

  @override
  String get contactAddedToContacts => 'Added to contacts';

  @override
  String get contactRequestOfferTitle => 'Can\'t message directly';

  @override
  String contactRequestOfferBody(Object name) {
    return '$name limited who can message them. Send a request with your card — they decide whether to reply.';
  }

  @override
  String get contactRequestSend => 'Send request';

  @override
  String get contactRequestSent => 'Request sent';

  @override
  String get contactRequestSendFailed => 'Couldn\'t send the request';

  @override
  String get contactRequestCooldown =>
      'You recently sent a request — try again later';

  @override
  String get requestsTitle => 'Message requests';

  @override
  String get requestsEmpty => 'No requests';

  @override
  String get requestsEmptyHint =>
      'When someone who isn\'t in your contacts wants to message you, their request shows up here.';

  @override
  String get requestsLoadFailed => 'Failed to load requests';

  @override
  String get requestWantsToConnect => 'wants to connect';

  @override
  String get requestAccept => 'Accept';

  @override
  String get requestDecline => 'Decline';

  @override
  String get requestDeclined => 'Request declined';

  @override
  String get requestActionFailed => 'Action failed';

  @override
  String get contactSaveToContacts => 'Save to contacts';

  @override
  String get contactShareMyCard => 'Share my card';

  @override
  String get contactShareCardFailed => 'Couldn\'t share the card';

  @override
  String get chatIntroConnected => 'You\'re now connected — say hello 👋';

  @override
  String get peopleTitle => 'People';

  @override
  String get peopleAll => 'All';

  @override
  String get peopleEmpty => 'No contacts yet';

  @override
  String get peopleEmptyLabel =>
      'No one with this label yet — assign labels from a contact\'s profile';

  @override
  String get peopleLoadFailed => 'Failed to load';

  @override
  String folderPickerTitle(Object name) {
    return 'Folders for “$name”';
  }

  @override
  String get folderPickerEmpty =>
      'No folders yet — create the first one and this chat will be added to it. One chat can be in several folders.';

  @override
  String get folderNewRow => 'New folder…';

  @override
  String get folderNewTitle => 'New folder';

  @override
  String get folderNameHint => 'Folder name';

  @override
  String get folderCreateFailed => 'Failed to create folder';

  @override
  String folderRenameMenu(Object name) {
    return 'Rename “$name”';
  }

  @override
  String get folderRenameTitle => 'Rename folder';

  @override
  String get folderDelete => 'Delete folder';

  @override
  String folderDeleteConfirm(Object name) {
    return 'Delete folder “$name”?';
  }

  @override
  String get folderDeleteBody =>
      'Chats will remain — only the folder is deleted.';

  @override
  String get folderChangeFailed => 'Failed to update folder';

  @override
  String get folderDeleteFailed => 'Failed to delete folder';

  @override
  String get peopleSearchHint => 'Search by name or @username';

  @override
  String peopleCount(Object count) {
    return 'Contacts · $count';
  }

  @override
  String get peopleNotFound => 'Nothing found';

  @override
  String get peopleWrite => 'Message';

  @override
  String get peopleProfile => 'Contact profile';

  @override
  String folderChatCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chats',
      one: '$count chat',
      zero: 'empty',
    );
    return '$_temp0';
  }

  @override
  String get folderDone => 'Done';

  @override
  String folderDoneN(Object count) {
    return 'Done · $count';
  }

  @override
  String get folderOk => 'OK';

  @override
  String get folderPickerHeader => 'Add to folder';

  @override
  String get lastSeenJustNow => 'last seen just now';

  @override
  String lastSeenMinutes(Object count) {
    return 'last seen $count min ago';
  }

  @override
  String lastSeenToday(Object time) {
    return 'last seen today at $time';
  }

  @override
  String lastSeenYesterday(Object time) {
    return 'last seen yesterday at $time';
  }

  @override
  String lastSeenDate(Object date) {
    return 'last seen $date';
  }

  @override
  String get lastSeenOnline => 'online';

  @override
  String get cardEditorTitle => 'My card';

  @override
  String get cardSectionStyle => 'Style';

  @override
  String get cardSectionFields => 'About you';

  @override
  String get cardTemplatePhoto => 'Photo';

  @override
  String get cardTemplateGradient => 'Gradient';

  @override
  String get cardTemplateMonogram => 'Monogram';

  @override
  String get cardFontClassic => 'Classic';

  @override
  String get cardFontBold => 'Bold';

  @override
  String get cardFontAiry => 'Airy';

  @override
  String get cardFontMono => 'Mono';

  @override
  String get cardColorAuto => 'Auto';

  @override
  String get cardPickPhoto => 'Choose photo';

  @override
  String get cardPhotoUploadFailed => 'Failed to upload photo';

  @override
  String get cardAboutLabel => 'About';

  @override
  String get cardJobTitleLabel => 'Job title';

  @override
  String get cardCompanyLabel => 'Company';

  @override
  String get cardPhoneLabel => 'Phone';

  @override
  String get cardEmailLabel => 'Email';

  @override
  String get cardWebsiteLabel => 'Website';

  @override
  String get cardVisibilityEveryone => 'Visible to everyone';

  @override
  String get cardVisibilityContacts => 'Contacts only';

  @override
  String get cardVisibilityHint =>
      'Fields with a lock are visible only to your contacts (people you share a chat with)';

  @override
  String get cardSaved => 'Card saved';

  @override
  String get cardSaveFailed => 'Failed to save card';

  @override
  String get cardDelete => 'Delete card';

  @override
  String get cardDeleteConfirmTitle => 'Delete card?';

  @override
  String get cardDeleteConfirmBody =>
      'The design and “about you” fields will be removed. This cannot be undone.';

  @override
  String get cardHiddenFieldsNote => 'The full card is visible to contacts';

  @override
  String get settingsWhoCanMessageTitle => 'Only contacts can message me';

  @override
  String get settingsWhoCanMessageSubtitle =>
      'Only people you already share a chat with can start a new chat with you';

  @override
  String get settingsShowCardsOnCallTitle => 'Cards on call screen';

  @override
  String get settingsShowCardsOnCallSubtitle =>
      'Show the caller\'s card full-screen on incoming calls';

  @override
  String get settingsPresenceVisibleTitle => 'Show when I\'m online';

  @override
  String get settingsPresenceVisibleSubtitle =>
      'Peers can see “online” and “last seen…”. If you turn this off, you won\'t see others\' status either';

  @override
  String peopleSelectedCount(int count) {
    return 'Selected: $count';
  }

  @override
  String get peopleAssignLabelAction => 'Label';

  @override
  String peopleBatchLabelTitle(int count) {
    return 'Assign label · $count';
  }

  @override
  String get profileLangBase => 'Primary';

  @override
  String get profileLangAdd => '+ Language';

  @override
  String get profileLangAddTitle => 'Add profile language';

  @override
  String profileLangHelper(String locale) {
    return 'People using $locale will see these fields. Empty fields fall back to the English or primary version.';
  }

  @override
  String profileLangSaved(String locale) {
    return '$locale version saved';
  }

  @override
  String get roomCustomNameAction => 'Custom chat name';

  @override
  String get roomCustomNameHint =>
      'Visible only to you — others see the regular name';

  @override
  String get roomCustomNameReset => 'Reset';

  @override
  String get roomAdminWriteBanAction => 'Forbid writing';

  @override
  String get roomAdminWriteUnbanAction => 'Allow writing';

  @override
  String get roomAdminWriteBanDurationTitle => 'Forbid writing for…';

  @override
  String get roomAdminWriteBanHour => '1 hour';

  @override
  String get roomAdminWriteBanDay => '1 day';

  @override
  String get roomAdminWriteBanWeek => '7 days';

  @override
  String get roomAdminWriteBanForever => 'Forever';

  @override
  String roomAdminWriteBannedUntil(String until) {
    return 'Forbidden until $until';
  }

  @override
  String get writeBannedForeverSnack =>
      'An admin has forbidden you from writing in this chat';

  @override
  String writeBannedUntilSnack(String until) {
    return 'You cannot write in this chat until $until';
  }
}
