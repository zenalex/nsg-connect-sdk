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
  String get attachActionSheetTitle => 'Attach';

  @override
  String get attachActionCamera => 'Camera';

  @override
  String get attachActionGallery => 'Gallery';

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
  String composerReplyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get composerCancelReply => 'Cancel reply';

  @override
  String get composerEditing => 'Editing';

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
  String get notificationSettingsSaveFailed =>
      'Couldn\'t save settings — try again';

  @override
  String get connectionStateHealthy => 'Connected';

  @override
  String get connectionStateReconnecting => 'Reconnecting…';

  @override
  String get connectionStateDisconnected => 'Connection lost';
}
