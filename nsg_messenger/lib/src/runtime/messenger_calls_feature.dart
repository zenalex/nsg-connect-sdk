import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../auth_token_provider.dart';

/// Session resources supplied only to an explicitly installed calls module.
/// Core messaging does not import a calls implementation or a media plugin.
class MessengerCallsContext {
  const MessengerCallsContext({
    required this.client,
    required this.events,
    required this.selfMessengerUserId,
    required this.authenticated,
    this.reporter,
  });

  final Client client;
  final Stream<MessengerEvent> events;
  final int Function() selfMessengerUserId;
  final Future<T> Function<T>(Future<T> Function() request) authenticated;
  final ErrorReporter? reporter;
}

/// Optional calling capability. Its implementation owns controllers and media;
/// the runtime owns its session lifetime and disposes it before transport.
abstract class MessengerCallsFeature extends ChangeNotifier {
  void attach(MessengerCallsContext context);
  bool get isBusy;
  Future<void> startCall({
    required int roomId,
    int? peerMessengerUserId,
    String? peerDisplayName,
  });
  Future<void> joinConference({required int roomId});
  Future<void> refreshRoomConference(int roomId);
  int? conferenceMemberCount(int roomId);
  bool isInConference(int roomId);
}
