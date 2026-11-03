library;

export 'src/calls/call_controller.dart' show CallController, IdGenerator;
export 'src/calls/call_overlay_host.dart' show CallOverlayHost, CallPeerRef;
export 'src/calls/call_ringback_player.dart'
    show CallRingbackPlayer, CallRingbackTone, JustAudioRingbackPlayer;
export 'src/calls/call_rpc.dart' show CallRpc, ClientCallRpc;
export 'src/calls/call_state.dart'
    show
        CallState,
        CallIdle,
        CallOutgoingRinging,
        CallIncomingRinging,
        CallConnecting,
        CallConnected,
        CallEnded,
        CallEndReason;
export 'src/calls/conference_call_controller.dart'
    show
        ConferenceCallController,
        ConferenceRoomInfo,
        ConferencePairCallId,
        kConferenceCallIdPrefix,
        kConferenceHeartbeatInterval;
export 'src/calls/conference_call_state.dart'
    show
        ConferenceCallState,
        ConferenceCallIdle,
        ConferenceIncomingRinging,
        ConferenceJoining,
        ConferenceActive,
        ConferenceCallEnded,
        ConferenceEndReason,
        ConferenceParticipantView,
        ConferencePairPhase;
export 'src/calls/conference_overlay_host.dart' show ConferenceOverlayHost;
export 'src/calls/conference_rpc.dart' show ConferenceRpc, ClientConferenceRpc;
export 'src/calls/webrtc_adapter.dart'
    show
        WebRtcAdapter,
        RtcPeerConnection,
        RtcMediaStream,
        MediaAudioTrack,
        RtcSdp,
        RtcIce,
        SdpType,
        RtcConnState,
        MicPermissionDeniedException,
        // **TASK80**: типы демонстрации экрана. Без них host-app физически не
        // может реализовать WebRtcAdapter — интерфейс требует то, чего не
        // видно снаружи пакета (поймано тестом Chatista, где свой фейк
        // адаптера перестал компилироваться).
        MediaVideoTrack,
        RtcVideoSender,
        RtcVideoRenderer,
        ScreenShareCaps,
        ScreenShareSource,
        ScreenSharePermissionDeniedException;
export 'src/nsg_messenger_calls.dart';
