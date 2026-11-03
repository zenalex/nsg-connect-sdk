import 'package:flutter/foundation.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

import 'calls/call_controller.dart';
import 'calls/call_rpc.dart';
import 'calls/conference_call_controller.dart';
import 'calls/conference_call_state.dart';
import 'calls/conference_rpc.dart';
import 'calls/webrtc_adapter.dart';
import 'calls/webrtc_adapter_real.dart';

/// Opt-in entry point. Pass a fresh [feature] to each NsgMessenger.init.
class NsgMessengerCalls {
  NsgMessengerCalls._();

  static MessengerCallsFeature feature({WebRtcAdapter? webRtcAdapter}) =>
      _CallsFeature(webRtcAdapter);

  @visibleForTesting
  static MessengerCallsFeature debugFeature({CallController? callController}) =>
      _CallsFeature(null).._calls = callController;

  static _CallsFeature? get _installed {
    final feature = NsgMessenger.callsFeature;
    return feature is _CallsFeature ? feature : null;
  }

  static CallController? get callControllerOrNull => _installed?._calls;
  static ConferenceCallController? get conferenceCallsOrNull =>
      _installed?._conference;
  static CallController get callController =>
      callControllerOrNull ??
      (throw StateError('Calling is not installed or its session has ended.'));
  static ConferenceCallController get conferenceCalls =>
      conferenceCallsOrNull ??
      (throw StateError('Calling is not installed or its session has ended.'));

  static Future<void> startCall({
    required int roomId,
    int? peerMessengerUserId,
    String? peerDisplayName,
  }) => callController.startCall(
    roomId: roomId,
    peerMessengerUserId: peerMessengerUserId,
    peerDisplayName: peerDisplayName,
  );

  static Future<bool> fetchAndInjectCallInvite(String callId) async {
    final installed = _installed;
    final context = installed?._context;
    if (context == null) return false;
    final event = await context.authenticated(
      () => context.client.messenger.fetchCallInvite(callId: callId),
    );
    // A push lookup can finish after logout/account switch.
    if (event == null || !identical(installed, _installed)) return false;
    installed!._calls?.ingestFetchedInvite(event);
    return installed._calls != null;
  }
}

class _CallsFeature extends MessengerCallsFeature {
  _CallsFeature(this._adapterOverride);
  final WebRtcAdapter? _adapterOverride;
  MessengerCallsContext? _context;
  CallController? _calls;
  ConferenceCallController? _conference;
  bool _disposed = false;

  @override
  void attach(MessengerCallsContext context) {
    if (_context != null || _disposed) {
      throw StateError('Use a fresh calls feature for each session.');
    }
    _context = context;
    final adapter =
        _adapterOverride ?? RealWebRtcAdapter(reporter: context.reporter);
    final rpc = ClientCallRpc(context);
    _calls = CallController(
      rpc: rpc,
      webrtc: adapter,
      events: context.events,
      reporter: context.reporter,
    );
    _conference = ConferenceCallController(
      conferenceRpc: ClientConferenceRpc(context),
      callRpc: rpc,
      webrtc: adapter,
      events: context.events,
      selfMessengerUserId: context.selfMessengerUserId,
      reporter: context.reporter,
    );
    _calls!.addListener(notifyListeners);
    _conference!.addListener(notifyListeners);
  }

  @override
  bool get isBusy =>
      (_calls?.isBusy ?? false) || (_conference?.isBusy ?? false);

  @override
  Future<void> startCall({
    required int roomId,
    int? peerMessengerUserId,
    String? peerDisplayName,
  }) => _calls!.startCall(
    roomId: roomId,
    peerMessengerUserId: peerMessengerUserId,
    peerDisplayName: peerDisplayName,
  );

  @override
  Future<void> joinConference({required int roomId}) =>
      _conference!.join(roomId: roomId);

  @override
  Future<void> refreshRoomConference(int roomId) async =>
      _conference?.refreshRoomConference(roomId);

  @override
  int? conferenceMemberCount(int roomId) =>
      _conference?.liveConferenceInRoom(roomId)?.memberCount;

  @override
  bool isInConference(int roomId) => switch (_conference?.state) {
    ConferenceJoining(roomId: final id) ||
    ConferenceActive(roomId: final id) => id == roomId,
    _ => false,
  };

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final calls = _calls;
    final conference = _conference;
    _calls = null;
    _conference = null;
    _context = null;
    conference?.removeListener(notifyListeners);
    calls?.removeListener(notifyListeners);
    conference?.dispose();
    calls?.dispose();
    super.dispose();
  }
}
