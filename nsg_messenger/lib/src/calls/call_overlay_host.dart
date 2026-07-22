import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../contact_card/contact_card_view.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../messenger_session_state.dart';
import 'call_controller.dart';
import 'call_ringback_player.dart';
import 'call_state.dart';
import 'incoming_ringtone.dart';

/// **TASK46 (UI)**: глобальный хост оверлеев голосового звонка 1:1.
///
/// Оборачивает поддерево навигации (host-app вставляет его в
/// `MaterialApp.builder`, над навигатором), слушает [CallController]
/// (`ChangeNotifier`) и по [CallState] рисует поверх всего:
///
///   * [CallOutgoingRinging] → «Звоним {peer}…» + отмена (hangup);
///   * [CallIncomingRinging] → «{caller} звонит» + accept / decline;
///   * [CallConnecting]      → «Соединение…»;
///   * [CallConnected]       → in-call панель: имя, тикающий таймер,
///                             mute-toggle, hangup (аудио играет само —
///                             flutter_webrtc audio track);
///   * [CallEnded]           → короткий toast, затем скрытие.
///
/// Входящий звонок ловится на ЛЮБОМ экране — [CallController] подписан
/// на event bus с момента `init()`, а хост живёт в корне навигации.
///
/// Material-версия (переиспользуема любым host-app). Chatista-glass
/// оборачивает её в свой `MaterialApp.builder` поверх glass-фона —
/// оверлей полупрозрачный (`Colors.black87`), сквозь него просвечивает
/// glass-обои. По умолчанию хост биндится к `NsgMessenger.callController`
/// (`MessengerRuntime.instance.calls`); в тестах передаётся [controller]
/// (fake).
class CallOverlayHost extends StatefulWidget {
  const CallOverlayHost({
    super.key,
    required this.child,
    this.controller,
    this.peerNameResolver,
    this.endedToastDuration = const Duration(seconds: 3),
    this.enableRingtone = true,
    this.ringbackPlayer,
  });

  /// Поддерево приложения (навигатор). Рисуется под оверлеем.
  final Widget child;

  /// Источник состояния звонка. По умолчанию —
  /// `NsgMessenger.callController` (`MessengerRuntime.instance.calls`).
  /// В тестах — fake `CallController`.
  final CallController? controller;

  /// Опциональный резолвер отображаемого имени собеседника по
  /// `messengerUserId` (исходящий) / Matrix user id (входящий). Host-app
  /// может подставить имя из своего roster-а; если null или вернул null —
  /// показываем fallback («Собеседник» / localpart Matrix id).
  final String? Function(CallPeerRef ref)? peerNameResolver;

  /// Сколько показывать финальный toast перед скрытием оверлея.
  final Duration endedToastDuration;

  /// **TASK46 (UI, п5)**: проигрывать простой рингтон-тон
  /// (`SystemSound.alert`) + вибро (`HapticFeedback`) на входящем звонке
  /// И ringback-«гудки» на исходящем (см. [ringbackPlayer]). Тесты передают
  /// `false`, чтобы не дёргать платформенные каналы.
  final bool enableRingtone;

  /// **Ringback**: плеер обратного сигнала исходящего звонка. По умолчанию
  /// (`null`) хост лениво создаёт [JustAudioRingbackPlayer], когда впервые
  /// нужно проиграть тон, и сам его освобождает. Тесты инжектят fake, чтобы
  /// проверить маппинг состояние→тон без платформенных аудио-каналов.
  /// Игнорируется, если [enableRingtone] == false.
  final CallRingbackPlayer? ringbackPlayer;

  @override
  State<CallOverlayHost> createState() => _CallOverlayHostState();
}

/// Ссылка на собеседника для [CallOverlayHost.peerNameResolver].
/// Либо `messengerUserId` (исходящий — из [CallOutgoingRinging]), либо
/// Matrix user id (входящий — из [CallIncomingRinging]). [roomId] — id
/// direct-комнаты звонка: host-app может резолвить имя ТАК ЖЕ, как в
/// списке чатов (имя direct-комнаты = имя собеседника), не завися от
/// matrix-id → это самый надёжный путь (совпадает с чатом).
class CallPeerRef {
  const CallPeerRef({this.messengerUserId, this.matrixUserId, this.roomId});

  final int? messengerUserId;
  final String? matrixUserId;
  final int? roomId;
}

class _CallOverlayHostState extends State<CallOverlayHost> {
  /// Контроллер, на который сейчас подписаны. null, если ещё не
  /// доступен (runtime не проинициализирован — экран логина Chatista
  /// рендерится ДО `NsgMessenger.init`). Переустанавливается в [build].
  CallController? _attached;

  /// **issue #47**: подписка на session-state рантайма. Хост живёт в
  /// `MaterialApp.builder` — ВЫШЕ всего, что перестраивается при смене
  /// аккаунта, поэтому rebuild после reinit ему никто не гарантирует.
  /// Без этой подписки оверлей мог остаться отцепленным от нового
  /// [CallController] → входящие звонки после смены аккаунта молча
  /// не показывались бы. Стрим живёт на singleton-е (переживает
  /// dispose/init рантайма), так что одна подписка на всю жизнь виджета.
  StreamSubscription<MessengerSessionState>? _runtimeStateSub;

  /// Разрешить контроллер: явный [CallOverlayHost.controller] или
  /// глобальный `MessengerRuntime.instance.callsOrNull`. Возвращает
  /// null, если контроллера сейчас нет — runtime не инициализирован ЛИБО
  /// **issue #47**: мы в окне teardown/reinit смены аккаунта (там
  /// isInitialized ещё/уже true, а `calls` уже бросает StateError —
  /// поэтому именно [MessengerRuntime.callsOrNull], а не гейт по
  /// isInitialized). Тогда оверлей просто не рисуется — пере-резолв
  /// случится на следующем rebuild-е или событии [_runtimeStateSub].
  CallController? _resolveController() {
    final explicit = widget.controller;
    if (explicit != null) return explicit;
    return MessengerRuntime.instance.callsOrNull;
  }

  /// Таймер, гасящий оверлей после [CallEnded] (через
  /// [CallOverlayHost.endedToastDuration]). Пока он взведён — показываем
  /// финальный toast; по истечении — скрываем даже если контроллер ещё
  /// в [CallEnded] (следующий звонок вернёт его в idle).
  Timer? _endedHideTimer;
  bool _endedHidden = false;

  /// Рингтон входящего: пока состояние — [CallIncomingRinging], периодически
  /// проигрываем alert-тон + вибро (общий с групповым оверлеем хелпер —
  /// TASK51 вынес механику в [IncomingRingtone]).
  final IncomingRingtone _ringtone = IncomingRingtone();

  /// **Ringback**: плеер обратного сигнала исходящего звонка. Лениво
  /// создаётся при первом тоне (или инжектится [CallOverlayHost.ringbackPlayer]).
  CallRingbackPlayer? _ringback;

  /// Владеем ли мы [_ringback] (сами создали → сами и dispose-им). Для
  /// инжектнутого плеера — false (его освобождает тот, кто передал).
  bool _ownsRingback = false;

  /// Последний запрошенный ringback-тон (`null` = заглушено). Дедуп, чтобы
  /// не дёргать плеер на каждый notifyListeners с тем же тоном.
  CallRingbackTone? _ringbackTone;

  /// **TASK52 итер.1**: визитка звонящего для фуллскрин-фона входящего.
  /// Префетч с жёстким таймаутом — звонок НЕ ждёт визитку; не успела /
  /// нет / отключено настройкой → обычный вид. [_incomingCardCallId]
  /// защищает от гонки двух звонков подряд.
  ContactCardInfo? _incomingCard;
  String? _incomingCardCallId;

  /// Префетч визитки звонящего: настройка смотрящего (showCardsOnCall) →
  /// peer из кэша комнат (directPeerMessengerUserId) → prefetch карточки.
  /// Все шаги best-effort с таймаутом; ошибки глотаются.
  Future<void> _prefetchIncomingCard(CallIncomingRinging s) async {
    if (_incomingCardCallId == s.callId) return; // уже запрошено
    _incomingCardCallId = s.callId;
    _incomingCard = null;
    try {
      final rt = MessengerRuntime.instance;
      if (!rt.isInitialized) return;
      final settings = await rt.notificationSettings
          .get()
          .timeout(const Duration(milliseconds: 800));
      if (settings.showCardsOnCall == false) return;
      final rooms = await rt.rooms
          .list()
          .timeout(const Duration(milliseconds: 900));
      RoomSummary? room;
      for (final r in rooms) {
        if (r.id == s.roomId) {
          room = r;
          break;
        }
      }
      final peerId = room?.directPeerMessengerUserId;
      if (peerId == null) return;
      final card = await rt.contactCards.prefetch(peerId);
      if (!mounted || card == null) return;
      final current = _attached?.state;
      if (current is CallIncomingRinging && current.callId == s.callId) {
        setState(() => _incomingCard = card);
      }
    } catch (_) {
      // Визитка не в критическом пути звонка.
    }
  }

  /// Синхронизировать подписку с актуальным контроллером. Вызывается из
  /// [build] — при первом появлении контроллера (после init) или его
  /// смене (host передал другой). Идемпотентно.
  void _syncSubscription() {
    final current = _resolveController();
    if (identical(current, _attached)) return;
    _attached?.removeListener(_onCallChanged);
    _attached = current;
    _attached?.addListener(_onCallChanged);
    // Контроллер мог УЖЕ быть в CallEnded к моменту подписки (напр.
    // host смонтировал host сразу после завершения звонка) — тогда
    // listener на переход не сработает, поэтому синхронизируем таймеры
    // по текущему состоянию сразу.
    _syncEndedHideTimer(_attached?.state);
    _syncRingtone(_attached?.state);
    _syncRingback(_attached?.state);
  }

  /// Запустить/остановить рингтон по состоянию. В [CallIncomingRinging] —
  /// проигрываем тон+вибро сразу и далее каждые 2с; в любом другом —
  /// глушим. No-op, если [CallOverlayHost.enableRingtone] == false.
  void _syncRingtone(CallState? s) {
    if (!widget.enableRingtone) return;
    if (s is CallIncomingRinging) {
      _ringtone.start(); // идемпотентно — повторный вызов не перезапускает
    } else {
      _ringtone.stop();
    }
  }

  /// **Ringback (обратный сигнал каллеру)**: по [CallOutgoingRinging]
  /// проигрываем «гудок» одной из двух стадий, в любом другом состоянии —
  /// глушим (answer→`CallConnecting`, `CallConnected`, `CallEnded`).
  ///
  ///   * `reachedPeer=false` → [CallRingbackTone.connecting] (дозвон до сервера);
  ///   * `reachedPeer=true`  → [CallRingbackTone.ringing] (звонит на устройстве).
  ///
  /// No-op при [CallOverlayHost.enableRingtone] == false (тесты overlay).
  /// Дедупим по [_ringbackTone], чтобы не пере-запускать петлю на каждый
  /// notifyListeners. Плеер создаётся лениво — только когда реально нужен тон.
  void _syncRingback(CallState? s) {
    if (!widget.enableRingtone) return;
    final CallRingbackTone? desired = switch (s) {
      CallOutgoingRinging(:final reachedPeer) =>
        reachedPeer ? CallRingbackTone.ringing : CallRingbackTone.connecting,
      _ => null,
    };
    if (desired == _ringbackTone) return; // тон не менялся
    _ringbackTone = desired;
    final player = _resolveRingback();
    if (player == null) return;
    if (desired == null) {
      unawaited(player.stop());
    } else {
      unawaited(player.play(desired));
    }
  }

  /// Разрешить плеер ringback: инжектнутый [CallOverlayHost.ringbackPlayer]
  /// или лениво созданный [JustAudioRingbackPlayer]. Создаётся при первой
  /// надобности (не на idle) — чтобы не поднимать аудио-плеер зря.
  CallRingbackPlayer? _resolveRingback() {
    final existing = _ringback;
    if (existing != null) return existing;
    final injected = widget.ringbackPlayer;
    if (injected != null) {
      _ownsRingback = false;
      return _ringback = injected;
    }
    _ownsRingback = true;
    return _ringback = JustAudioRingbackPlayer();
  }

  /// Взвести/сбросить таймер скрытия финального toast-а по состоянию.
  /// В [CallEnded] — показываем toast и через [endedToastDuration]
  /// скрываем; в любом другом — отменяем отложенное скрытие.
  void _syncEndedHideTimer(CallState? s) {
    if (s is CallEnded) {
      if (_endedHideTimer != null || _endedHidden) return; // уже взведён
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

  void _onCallChanged() {
    if (!mounted) return;
    final s = _attached?.state;
    _syncEndedHideTimer(s);
    _syncRingtone(s);
    _syncRingback(s);
    if (s is CallIncomingRinging) {
      unawaited(_prefetchIncomingCard(s));
    } else if (s is! CallConnecting && s is! CallConnected) {
      // Звонок закончился/нет — сбрасываем фон (карточку держим до
      // connected включительно: переход accept не мигает фоном).
      _incomingCard = null;
      _incomingCardCallId = null;
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // **issue #47**: пере-резолв контроллера по жизненному циклу рантайма.
    // Любое событие session-state (dispose эмитит `uninitialised`, init
    // нового аккаунта — `refreshing`/`active` УЖЕ ПОСЛЕ создания
    // CallController) → перечитываем контроллер в build. Так оверлей
    // заново цепляется к новому рантайму, даже если сверху его никто
    // не перестроил. При явном [CallOverlayHost.controller] (тесты)
    // _syncSubscription идемпотентно оставит его же — подписка безвредна.
    _runtimeStateSub = MessengerRuntime.instance.stateStream.listen((_) {
      if (!mounted) return;
      // Сам resync — в build (единая точка): setState достаточно.
      setState(() {});
    });
  }

  @override
  void dispose() {
    unawaited(_runtimeStateSub?.cancel());
    _runtimeStateSub = null;
    _endedHideTimer?.cancel();
    _ringtone.stop();
    // Освобождаем плеер ringback только если сами его создали (инжектнутый
    // fake освобождает тот, кто передал).
    if (_ownsRingback) unawaited(_ringback?.dispose());
    // ВАЖНО: removeListener на уже dispose-нутом контроллере (рантайм
    // умер раньше нас) безопасен — ChangeNotifier это разрешает.
    _attached?.removeListener(_onCallChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncSubscription();
    final state = _attached?.state ?? const CallIdle();
    final overlay = _buildOverlay(context, state);
    return Stack(
      children: [
        widget.child,
        if (overlay != null) Positioned.fill(child: overlay),
      ],
    );
  }

  Widget? _buildOverlay(BuildContext context, CallState state) {
    // Во всех не-idle ветках контроллер гарантированно есть (idle —
    // и когда контроллер ещё null: _attached?.state ?? CallIdle()).
    final c = _attached;
    switch (state) {
      case CallIdle():
        return null;
      case CallOutgoingRinging(
        :final peerMessengerUserId,
        :final roomId,
        :final peerDisplayName,
      ):
        return _CallOverlayScaffold(
          child: _OutgoingCallView(
            // Имя, переданное инициатором (из participants чата), —
            // приоритетнее host-resolver/кэша: «звоним <имя>».
            peerName:
                (peerDisplayName != null && peerDisplayName.trim().isNotEmpty)
                ? peerDisplayName.trim()
                : _resolvePeerName(
                    CallPeerRef(
                      messengerUserId: peerMessengerUserId,
                      roomId: roomId,
                    ),
                  ),
            onHangup: c!.hangup,
          ),
        );
      case CallIncomingRinging(:final callerMatrixUserId, :final roomId):
        return _CallOverlayScaffold(
          // **TASK52**: визитка звонящего фоном (если префетчилась).
          backdrop: _incomingCard == null
              ? null
              : ContactCardBackdrop(card: _incomingCard!),
          child: _IncomingCallView(
            callerName: _resolvePeerName(
              CallPeerRef(matrixUserId: callerMatrixUserId, roomId: roomId),
            ),
            onAccept: c!.accept,
            onDecline: c.decline,
          ),
        );
      case CallConnecting():
        return _CallOverlayScaffold(child: const _ConnectingCallView());
      case CallConnected(:final startedAt, :final muted, :final speakerOn):
        return _CallOverlayScaffold(
          child: _InCallView(
            startedAt: startedAt,
            muted: muted,
            speakerOn: speakerOn,
            onToggleMute: c!.toggleMute,
            onToggleSpeaker: c.toggleSpeaker,
            onHangup: c.hangup,
          ),
        );
      case CallEnded(:final reason):
        if (_endedHidden) return null;
        return _CallOverlayScaffold(child: _EndedCallView(reason: reason));
    }
  }

  /// Резолв отображаемого имени: сперва host-resolver, затем fallback.
  /// Для Matrix id fallback — localpart (`@bob:home` → `bob`).
  String _resolvePeerName(CallPeerRef ref) {
    final resolved = widget.peerNameResolver?.call(ref);
    if (resolved != null && resolved.trim().isNotEmpty) return resolved.trim();
    final mxid = ref.matrixUserId;
    if (mxid != null && mxid.startsWith('@')) {
      final localpart = mxid.substring(1).split(':').first;
      if (localpart.isNotEmpty) return localpart;
    }
    return NsgL10n.of(context).callPeerFallback;
  }
}

/// Полупрозрачный full-screen контейнер оверлея. Сквозь `black87`
/// просвечивает host-фон (glass-обои Chatista / обычный фон titan).
/// **TASK52**: опциональный [backdrop] — фуллскрин-фон (визитка
/// звонящего) ПОД контентом; когда задан, чёрная подложка не нужна.
class _CallOverlayScaffold extends StatelessWidget {
  const _CallOverlayScaffold({required this.child, this.backdrop});

  final Widget child;
  final Widget? backdrop;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backdrop == null ? Colors.black87 : Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ?backdrop,
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Крупная круглая иконка-«аватар» звонка (placeholder — конкретный
/// аватар собеседника требует host-resolver, на MVP имя достаточно).
class _CallAvatar extends StatelessWidget {
  const _CallAvatar({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
      ),
      child: Icon(icon, size: 48, color: Colors.white),
    );
  }
}

class _OutgoingCallView extends StatelessWidget {
  const _OutgoingCallView({required this.peerName, required this.onHangup});

  final String peerName;
  final VoidCallback onHangup;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _CallAvatar(icon: Icons.person),
        const SizedBox(height: 24),
        Text(
          l.callOutgoingTitle(peerName),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 48),
        _CallActionButton(
          key: const Key('callOutgoingHangupButton'),
          icon: Icons.call_end,
          color: Colors.red,
          tooltip: l.callHangup,
          onPressed: onHangup,
        ),
      ],
    );
  }
}

class _IncomingCallView extends StatelessWidget {
  const _IncomingCallView({
    required this.callerName,
    required this.onAccept,
    required this.onDecline,
  });

  final String callerName;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _CallAvatar(icon: Icons.person),
        const SizedBox(height: 24),
        Text(
          l.callIncomingTitle(callerName),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.callIncomingSubtitle,
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
            _CallActionButton(
              key: const Key('callIncomingDeclineButton'),
              icon: Icons.call_end,
              color: Colors.red,
              tooltip: l.callDecline,
              onPressed: onDecline,
            ),
            _CallActionButton(
              key: const Key('callIncomingAcceptButton'),
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

class _ConnectingCallView extends StatelessWidget {
  const _ConnectingCallView();

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _CallAvatar(icon: Icons.person),
        const SizedBox(height: 24),
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          l.callConnecting,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ],
    );
  }
}

class _InCallView extends StatefulWidget {
  const _InCallView({
    required this.startedAt,
    required this.muted,
    required this.speakerOn,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onHangup,
  });

  final DateTime startedAt;
  final bool muted;
  final bool speakerOn;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onHangup;

  @override
  State<_InCallView> createState() => _InCallViewState();
}

class _InCallViewState extends State<_InCallView> {
  static const _tick = Duration(seconds: 1);
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _elapsed = _wallClockElapsed();
    _ticker = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      // Каждый тик — +1с как минимум (тестируемо под fake-clock), но не
      // меньше wall-clock-разницы: если приложение висело в фоне и тики
      // коалесцировались, при пробуждении таймер «догоняет» реальное
      // время (production-корректность длинных звонков).
      setState(() {
        final byTick = _elapsed + _tick;
        final byWall = _wallClockElapsed();
        _elapsed = byWall > byTick ? byWall : byTick;
      });
    });
  }

  Duration _wallClockElapsed() {
    final d = DateTime.now().difference(widget.startedAt);
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _CallAvatar(icon: Icons.person),
        const SizedBox(height: 24),
        Text(
          _fmt(_elapsed),
          key: const Key('callTimer'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CallActionButton(
              key: const Key('callMuteButton'),
              icon: widget.muted ? Icons.mic_off : Icons.mic,
              color: widget.muted ? Colors.orange : Colors.white24,
              tooltip: widget.muted ? l.callUnmute : l.callMute,
              onPressed: widget.onToggleMute,
            ),
            _CallActionButton(
              key: const Key('callSpeakerButton'),
              icon: widget.speakerOn ? Icons.volume_up : Icons.hearing,
              color: widget.speakerOn ? Colors.white24 : Colors.white10,
              tooltip: widget.speakerOn ? l.callSpeakerOff : l.callSpeakerOn,
              onPressed: widget.onToggleSpeaker,
            ),
            _CallActionButton(
              key: const Key('callInCallHangupButton'),
              icon: Icons.call_end,
              color: Colors.red,
              tooltip: l.callHangup,
              onPressed: widget.onHangup,
            ),
          ],
        ),
      ],
    );
  }
}

class _EndedCallView extends StatelessWidget {
  const _EndedCallView({required this.reason});

  final CallEndReason reason;

  String _text(NsgL10n l) {
    switch (reason) {
      case CallEndReason.declined:
        return l.callEndedDeclined;
      case CallEndReason.micDenied:
        return l.callEndedMicDenied;
      case CallEndReason.failed:
        return l.callEndedFailed;
      case CallEndReason.peerUnavailable:
        // **issue #5**: собеседник недоступен. Переиспользуем существующую
        // строку «Пользователь недоступен» (та же, что в create-chat-гейте)
        // — отдельный l10n-ключ не заводим.
        return l.createChatPeerUnavailable;
      case CallEndReason.localHangup:
      case CallEndReason.remoteHangup:
      case CallEndReason.timeout:
      case CallEndReason.glareLost:
      // Ответили на другом устройстве — свой оверлей просто гасим обычным
      // «Звонок завершён» (отдельная строка не нужна, l10n не трогаем).
      case CallEndReason.answeredElsewhere:
        return l.callEndedGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.call_end, size: 48, color: Colors.white70),
        const SizedBox(height: 16),
        Text(
          _text(l),
          key: const Key('callEndedText'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ],
    );
  }
}

/// Круглая цветная кнопка действия звонка (accept/decline/hangup/mute).
class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
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
    // ВАЖНО: не `Tooltip` — хост оверлея живёт в `MaterialApp.builder`,
    // ВЫШЕ навигатора приложения, поэтому над ним нет `Overlay`-предка, а
    // `Tooltip` требует `Overlay.of(context)` и роняет рендер входящего
    // звонка («No Overlay widget found»). `Semantics` даёт ту же
    // доступную подпись без зависимости от `Overlay`.
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
