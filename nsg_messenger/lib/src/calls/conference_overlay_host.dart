import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../messenger_session_state.dart';
import '../widgets/nsg_avatar_image.dart';
import 'conference_call_controller.dart';
import 'conference_call_state.dart';
import 'incoming_ringtone.dart';

/// **TASK51 итерация 1 (UI)**: глобальный хост оверлеев группового
/// (mesh) аудиозвонка — брат [CallOverlayHost] для конференций.
///
/// Host-app вставляет его в `MaterialApp.builder` рядом с 1:1-хостом
/// (Chatista: внутрь `CallOverlayHost`, чтобы при коллизии состояний
/// 1:1-оверлей рисовался ПОВЕРХ — входящий 1:1 виден даже из активной
/// конференции). Слушает [ConferenceCallController] (`ChangeNotifier`)
/// и по [ConferenceCallState] рисует поверх всего:
///
///   * [ConferenceIncomingRinging] → «Групповой звонок в {комната}» +
///     кто зовёт + accept/decline (рингтон — общий [IncomingRingtone]);
///   * [ConferenceJoining]         → «Соединение…»;
///   * [ConferenceActive]          → список участников с фазами пар
///     (connecting-спиннер / connected / failed «нет связи»), таймер,
///     mute/speaker/выход;
///   * [ConferenceCallEnded]       → только conferenceFull (снек с
///     лимитом) и micDenied (как 1:1); остальные причины — тихое
///     закрытие оверлея (спека UI-чанка, п.5).
///
/// Имена/аватары участников: у контроллера есть только messengerUserId —
/// хост best-effort подтягивает участников комнаты через
/// `rooms.get(roomId)` (тот же приём, что префетч визитки в 1:1-хосте);
/// не успело/упало → fallback-имя. Имя комнаты — [roomNameResolver]
/// (Chatista отдаёт свой кэш имён комнат) с fallback на те же details.
class ConferenceOverlayHost extends StatefulWidget {
  const ConferenceOverlayHost({
    super.key,
    required this.child,
    this.controller,
    this.roomNameResolver,
    this.endedToastDuration = const Duration(seconds: 3),
    this.enableRingtone = true,
    @visibleForTesting this.roomDetailsOverride,
  });

  /// Поддерево приложения (навигатор). Рисуется под оверлеем.
  final Widget child;

  /// Источник состояния. По умолчанию —
  /// `NsgMessenger.conferenceCalls` (`MessengerRuntime.instance.
  /// conferenceCallsOrNull`). В тестах — fake-контроллер.
  final ConferenceCallController? controller;

  /// Опциональный резолвер имени комнаты для заголовка «Групповой звонок
  /// в {комната}» (Chatista — кэш имён комнат). null/пусто → fallback на
  /// подтянутые RoomDetails, затем на генерик «Групповой звонок».
  final String? Function(int roomId)? roomNameResolver;

  /// Сколько показывать финальный toast (conferenceFull/micDenied).
  final Duration endedToastDuration;

  /// Рингтон входящего (общий с 1:1 [IncomingRingtone]). Тесты передают
  /// false, чтобы не дёргать платформенные каналы.
  final bool enableRingtone;

  /// Тестовая подмена RoomDetails (имя комнаты + участники для
  /// имён/аватаров) — в тестах runtime не инициализирован и боевой
  /// префетч скипается.
  final RoomDetails? roomDetailsOverride;

  @override
  State<ConferenceOverlayHost> createState() => _ConferenceOverlayHostState();
}

class _ConferenceOverlayHostState extends State<ConferenceOverlayHost> {
  ConferenceCallController? _attached;

  /// Подписка на session-state рантайма — тот же паттерн issue #47, что в
  /// 1:1-хосте: хост живёт выше всего перестраиваемого, после смены
  /// аккаунта его никто не rebuild-ит — переподцепляемся сами.
  StreamSubscription<MessengerSessionState>? _runtimeStateSub;

  Timer? _endedHideTimer;
  bool _endedHidden = false;

  final IncomingRingtone _ringtone = IncomingRingtone();

  /// Комната, для которой подтянуты детали (имя + участники), и сами
  /// данные. Однократно на комнату за конференцию; сбрасывается на idle.
  int? _roomInfoRoomId;
  RoomDetails? _roomDetails;

  ConferenceCallController? _resolveController() {
    final explicit = widget.controller;
    if (explicit != null) return explicit;
    return MessengerRuntime.instance.conferenceCallsOrNull;
  }

  void _syncSubscription() {
    final current = _resolveController();
    if (identical(current, _attached)) return;
    _attached?.removeListener(_onConferenceChanged);
    _attached = current;
    _attached?.addListener(_onConferenceChanged);
    _syncEndedHideTimer(_attached?.state);
    _syncRingtone(_attached?.state);
  }

  void _syncRingtone(ConferenceCallState? s) {
    if (!widget.enableRingtone) return;
    if (s is ConferenceIncomingRinging) {
      _ringtone.start();
    } else {
      _ringtone.stop();
    }
  }

  /// Показывать ли финальный toast для [reason]: только «конференция
  /// полна» и «нет микрофона» — остальные причины (localLeave,
  /// conferenceDied, displaced, failed) закрывают оверлей тихо (п.5).
  static bool _endedShowsToast(ConferenceEndReason reason) =>
      reason == ConferenceEndReason.conferenceFull ||
      reason == ConferenceEndReason.micDenied;

  void _syncEndedHideTimer(ConferenceCallState? s) {
    if (s is ConferenceCallEnded && _endedShowsToast(s.reason)) {
      if (_endedHideTimer != null || _endedHidden) return;
      _endedHideTimer = Timer(widget.endedToastDuration, () {
        if (!mounted) return;
        setState(() => _endedHidden = true);
      });
    } else {
      _endedHideTimer?.cancel();
      _endedHideTimer = null;
      _endedHidden = false;
    }
  }

  /// Best-effort подтянуть детали комнаты (имя + участники) для
  /// заголовка и плиток. Звонок НЕ ждёт: не успело — fallback-имена,
  /// setState дорисует, когда приедет. Ошибки глотаются.
  Future<void> _prefetchRoomInfo(int roomId) async {
    if (_roomInfoRoomId == roomId) return; // уже запрошено
    _roomInfoRoomId = roomId;
    final override = widget.roomDetailsOverride;
    if (override != null) {
      setState(() => _roomDetails = override);
      return;
    }
    try {
      final rt = MessengerRuntime.instance;
      if (!rt.isInitialized) return;
      final details = await rt.rooms
          .get(roomId)
          .timeout(const Duration(seconds: 3));
      if (!mounted || _roomInfoRoomId != roomId) return;
      setState(() => _roomDetails = details);
    } catch (_) {
      // Имена не в критическом пути звонка.
    }
  }

  void _onConferenceChanged() {
    if (!mounted) return;
    final s = _attached?.state;
    _syncEndedHideTimer(s);
    _syncRingtone(s);
    if (s is ConferenceCallIdle || s is ConferenceCallEnded || s == null) {
      // Конференции нет — забываем комнату (следующая подтянет заново;
      // details могли устареть — участники приходят/уходят). Префетч
      // живых фаз триггерится из build (см. [_scheduleRoomInfoPrefetch]).
      _roomInfoRoomId = null;
      _roomDetails = null;
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _runtimeStateSub = MessengerRuntime.instance.stateStream.listen((_) {
      if (!mounted) return;
      setState(() {}); // resync в build — единая точка.
    });
  }

  @override
  void dispose() {
    unawaited(_runtimeStateSub?.cancel());
    _runtimeStateSub = null;
    _endedHideTimer?.cancel();
    _ringtone.stop();
    _attached?.removeListener(_onConferenceChanged);
    super.dispose();
  }

  /// Триггер префетча деталей комнаты из build (а не из listener-а):
  /// покрывает и случай «контроллер уже в живой фазе к моменту монтажа»,
  /// когда listener на переход не сработает. Post-frame — setState из
  /// build запрещён.
  void _scheduleRoomInfoPrefetch(ConferenceCallState state) {
    final roomId = switch (state) {
      ConferenceIncomingRinging(:final roomId) => roomId,
      ConferenceJoining(:final roomId) => roomId,
      ConferenceActive(:final roomId) => roomId,
      _ => null,
    };
    if (roomId == null || _roomInfoRoomId == roomId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_prefetchRoomInfo(roomId));
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncSubscription();
    final state = _attached?.state ?? const ConferenceCallIdle();
    _scheduleRoomInfoPrefetch(state);
    final overlay = _buildOverlay(context, state);
    return Stack(
      children: [
        widget.child,
        if (overlay != null) Positioned.fill(child: overlay),
      ],
    );
  }

  Widget? _buildOverlay(BuildContext context, ConferenceCallState state) {
    // Во всех не-idle ветках контроллер гарантированно есть (idle — и
    // когда контроллер ещё null: `_attached?.state ?? Idle` в build).
    final c = _attached;
    if (c == null) return null;
    final l = NsgL10n.of(context);
    switch (state) {
      case ConferenceCallIdle():
        return null;
      case ConferenceIncomingRinging(
        :final roomId,
        :final callerMessengerUserId,
        :final memberCount,
      ):
        return _ConferenceOverlayScaffold(
          child: _ConferenceIncomingView(
            roomName: _resolveRoomName(roomId),
            callerName: callerMessengerUserId == null
                ? null
                : _resolveParticipantName(callerMessengerUserId),
            memberCount: memberCount,
            onAccept: () => unawaited(c.accept()),
            onDecline: c.decline,
          ),
        );
      case ConferenceJoining():
        return _ConferenceOverlayScaffold(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.callConnecting,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        );
      case ConferenceActive():
        return _ConferenceOverlayScaffold(
          child: _ConferenceActiveView(
            state: state,
            roomName: _resolveRoomName(state.roomId),
            nameOf: _resolveParticipantName,
            avatarOf: _resolveParticipantAvatar,
            onToggleMute: () => c.toggleMute(),
            onToggleSpeaker: () => c.toggleSpeaker(),
            onLeave: () => unawaited(c.leave()),
          ),
        );
      case ConferenceCallEnded(:final reason, :final maxParticipants):
        if (_endedHidden || !_endedShowsToast(reason)) return null;
        final text = switch (reason) {
          ConferenceEndReason.conferenceFull =>
            // Лимит по контракту заполнен всегда; 4 — серверный default
            // на сверхредкий случай отсутствия поля (не роняем UI).
            l.conferenceEndedFull(maxParticipants ?? 4),
          _ => l.callEndedMicDenied,
        };
        return _ConferenceOverlayScaffold(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.call_end, size: 48, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                text,
                key: const Key('conferenceEndedText'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        );
    }
  }

  /// Имя комнаты: host-resolver → подтянутые RoomDetails → null
  /// (view покажет генерик «Групповой звонок»).
  String? _resolveRoomName(int roomId) {
    final resolved = widget.roomNameResolver?.call(roomId);
    if (resolved != null && resolved.trim().isNotEmpty) {
      return resolved.trim();
    }
    final n = _roomDetails?.name?.trim();
    return (n != null && n.isNotEmpty) ? n : null;
  }

  RoomParticipant? _participantById(int messengerUserId) {
    final participants = _roomDetails?.participants;
    if (participants == null) return null;
    for (final p in participants) {
      if (p.messengerUserId == messengerUserId) return p;
    }
    return null;
  }

  String _resolveParticipantName(int messengerUserId) {
    final p = _participantById(messengerUserId);
    final name = p?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final username = p?.username?.trim();
    if (username != null && username.isNotEmpty) return username;
    return NsgL10n.of(context).callPeerFallback;
  }

  String? _resolveParticipantAvatar(int messengerUserId) =>
      _participantById(messengerUserId)?.avatarUrl;
}

/// Полупрозрачный full-screen контейнер (копия компоновки
/// 1:1-`_CallOverlayScaffold` без backdrop-визитки — у конференции её
/// нет; сквозь `black87` просвечивает host-фон).
class _ConferenceOverlayScaffold extends StatelessWidget {
  const _ConferenceOverlayScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(padding: const EdgeInsets.all(24), child: child),
          ),
        ),
      ),
    );
  }
}

class _ConferenceIncomingView extends StatelessWidget {
  const _ConferenceIncomingView({
    required this.roomName,
    required this.callerName,
    required this.memberCount,
    required this.onAccept,
    required this.onDecline,
  });

  final String? roomName;
  final String? callerName;
  final int memberCount;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final room = roomName;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          child: const Icon(Icons.groups, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          room == null ? l.conferenceTitle : l.conferenceIncomingTitle(room),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          // «Кто зовёт» + размер состава; состав мог ещё не доехать
          // (ринг стартовал с pairwise-invite) — тогда только генерик.
          [
            if (callerName != null) l.conferenceIncomingCaller(callerName!),
            if (memberCount > 0) l.conferenceMemberCount(memberCount),
          ].join(' · ').ifEmpty(l.callIncomingSubtitle),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ConferenceActionButton(
              key: const Key('conferenceIncomingDeclineButton'),
              icon: Icons.call_end,
              color: Colors.red,
              tooltip: l.callDecline,
              onPressed: onDecline,
            ),
            _ConferenceActionButton(
              key: const Key('conferenceIncomingAcceptButton'),
              icon: Icons.call,
              color: Colors.green,
              tooltip: l.callAccept,
              onPressed: onAccept,
            ),
          ],
        ),
      ],
    );
  }
}

extension on String {
  /// Пустая строка → [fallback] (join двух опциональных кусков выше).
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _ConferenceActiveView extends StatefulWidget {
  const _ConferenceActiveView({
    required this.state,
    required this.roomName,
    required this.nameOf,
    required this.avatarOf,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onLeave,
  });

  final ConferenceActive state;
  final String? roomName;
  final String Function(int messengerUserId) nameOf;
  final String? Function(int messengerUserId) avatarOf;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onLeave;

  @override
  State<_ConferenceActiveView> createState() => _ConferenceActiveViewState();
}

class _ConferenceActiveViewState extends State<_ConferenceActiveView> {
  // Таймер длительности — тот же приём, что 1:1 `_InCallView`: тик +1с
  // минимум, но не меньше wall-clock (фон коалесцирует тики — при
  // пробуждении «догоняем» реальное время).
  static const _tick = Duration(seconds: 1);
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _elapsed = _wallClockElapsed();
    _ticker = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      setState(() {
        final byTick = _elapsed + _tick;
        final byWall = _wallClockElapsed();
        _elapsed = byWall > byTick ? byWall : byTick;
      });
    });
  }

  Duration _wallClockElapsed() {
    final d = DateTime.now().difference(widget.state.startedAt);
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final s = widget.state;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.roomName ?? l.conferenceTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _fmt(_elapsed),
          key: const Key('conferenceTimer'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 24),
        // Список участников (N≤4 по серверному лимиту mesh — колонка,
        // сетка не нужна). Flexible+scroll — страховка малых экранов.
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final p in s.participants)
                  _ConferenceParticipantTile(
                    key: Key('conferenceParticipantTile_${p.messengerUserId}'),
                    participant: p,
                    name: widget.nameOf(p.messengerUserId),
                    avatarUrl: widget.avatarOf(p.messengerUserId),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ConferenceActionButton(
              key: const Key('conferenceMuteButton'),
              icon: s.muted ? Icons.mic_off : Icons.mic,
              color: s.muted ? Colors.orange : Colors.white24,
              tooltip: s.muted ? l.callUnmute : l.callMute,
              onPressed: widget.onToggleMute,
            ),
            _ConferenceActionButton(
              key: const Key('conferenceSpeakerButton'),
              icon: s.speakerOn ? Icons.volume_up : Icons.hearing,
              color: s.speakerOn ? Colors.white24 : Colors.white10,
              tooltip: s.speakerOn ? l.callSpeakerOff : l.callSpeakerOn,
              onPressed: widget.onToggleSpeaker,
            ),
            _ConferenceActionButton(
              key: const Key('conferenceLeaveButton'),
              icon: Icons.call_end,
              color: Colors.red,
              tooltip: l.callHangup,
              onPressed: widget.onLeave,
            ),
          ],
        ),
      ],
    );
  }
}

/// Плитка участника: аватар + имя (+«Вы») + индикатор фазы его пары:
/// connecting → спиннер, connected → «эквалайзер», failed → «нет связи».
class _ConferenceParticipantTile extends StatelessWidget {
  const _ConferenceParticipantTile({
    super.key,
    required this.participant,
    required this.name,
    required this.avatarUrl,
  });

  final ConferenceParticipantView participant;
  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final p = participant;
    final Widget status = switch (p.phase) {
      ConferencePairPhase.connecting => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white70,
        ),
      ),
      ConferencePairPhase.connected => const Icon(
        Icons.graphic_eq,
        size: 18,
        color: Colors.greenAccent,
      ),
      ConferencePairPhase.failed => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link_off, size: 18, color: Colors.orangeAccent),
          const SizedBox(width: 6),
          Text(
            l.conferencePairFailed,
            style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
          ),
        ],
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          NsgAvatarImage(mxcUrl: avatarUrl, fallbackName: name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              p.isSelf ? '$name (${l.conferenceYou})' : name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          status,
        ],
      ),
    );
  }
}

/// Круглая цветная кнопка действия (копия семантики 1:1-кнопки: без
/// `Tooltip` — хост живёт над навигатором, `Overlay`-предка нет, см.
/// комментарий в call_overlay_host.dart).
class _ConferenceActionButton extends StatelessWidget {
  const _ConferenceActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}
