import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../runtime/active_room.dart';
import '../runtime/app_visibility.dart';
import '../theme/highlight_surface.dart';
import '../theme/nsg_messenger_theme.dart' show NsgMessageBubbleTokens;
import '../widgets/nsg_avatar_image.dart';

/// Данные, нужные плашке. Отдельным интерфейсом — чтобы тест не поднимал
/// рантайм целиком ради проверки правил показа.
abstract class MessageBannerSource {
  Stream<MessengerEvent> get events;

  /// Кто мы — свои сообщения не показываем.
  int? get selfMessengerUserId;

  /// Комната сообщения: имя, заглушена ли, тип (в группе нужен автор).
  Future<RoomSummary?> room(int roomId);

  /// Показывать ли текст сообщения (настройка «превью в уведомлениях»).
  Future<bool> showPreview();
}

/// Боевой источник — рантайм SDK.
class RuntimeMessageBannerSource implements MessageBannerSource {
  const RuntimeMessageBannerSource();

  @override
  Stream<MessengerEvent> get events =>
      MessengerRuntime.instance.eventBus.events;

  @override
  int? get selfMessengerUserId {
    try {
      return MessengerRuntime.instance.currentMessengerUserId;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RoomSummary?> room(int roomId) async {
    try {
      final rooms = await MessengerRuntime.instance.rooms.list();
      for (final r in rooms) {
        if (r.id == roomId) return r;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<bool> showPreview() async {
    try {
      final settings = await MessengerRuntime.instance.notificationSettings
          .get();
      return settings.showMessagePreview;
    } catch (_) {
      // Не смогли прочитать — молчим о содержимом. Показать лишнего
      // хуже, чем показать меньше.
      return false;
    }
  }
}

/// **Плашка о новом сообщении поверх приложения (issue #79).**
///
/// Закрывает единственную дыру, оставшуюся после перехода на
/// подтверждения доставки (#78): пока человек сидит в приложении, пуш
/// подавляется намеренно — он подтвердил приём, — но сообщение в ДРУГОМ
/// чате при этом не подавало ни звука, только счётчик в списке.
///
/// Разделение между тремя способами оповестить получилось без нахлёста:
///
///   * приложение активно (это окно в фокусе) → плашка отсюда;
///   * десктоп, окно не в фокусе → системный тост host-приложения;
///   * приложение неактивно → пуш с сервера.
///
/// Поэтому показ жёстко привязан к [AppLifecycleState.resumed]: в
/// остальных состояниях сработает кто-то другой, и человек получил бы два
/// уведомления об одном сообщении.
///
/// Host-app оборачивает навигатор (`MaterialApp.builder`), как и хостом
/// оверлеев звонка.
class MessageBannerHost extends StatefulWidget {
  const MessageBannerHost({
    super.key,
    required this.child,
    this.onOpenRoom,
    this.source = const RuntimeMessageBannerSource(),
    this.visibleFor = const Duration(seconds: 4),
    this.lifecycleProbe,
    this.isEnabled,
  });

  /// Поддерево приложения (навигатор). Рисуется под плашкой.
  final Widget child;

  /// Тап по плашке. Host-app обычно подставляет тот же вход, что и тап по
  /// уведомлению, — тогда чат откроется одинаково, откуда бы человек ни
  /// пришёл. `null` — плашка просто закроется.
  final void Function(int roomId, {String? eventId})? onOpenRoom;

  final MessageBannerSource source;

  /// Сколько плашка висит, если её не трогают.
  final Duration visibleFor;

  /// Подмена состояния приложения в тестах.
  final AppLifecycleState Function()? lifecycleProbe;

  /// Выключатель для host-app — например «не беспокоить».
  ///
  /// Спрашивается в момент прихода сообщения, а не при сборке дерева:
  /// «не беспокоить до утра» истекает само по часам, и захваченное
  /// однажды значение продолжало бы глушить плашки после истечения.
  final bool Function()? isEnabled;

  @override
  State<MessageBannerHost> createState() => _MessageBannerHostState();
}

class _MessageBannerHostState extends State<MessageBannerHost> {
  StreamSubscription<MessengerEvent>? _sub;
  Timer? _hideTimer;
  _BannerData? _shown;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(covariant MessageBannerHost old) {
    super.didUpdateWidget(old);
    if (old.source != widget.source) {
      _sub?.cancel();
      _listen();
    }
  }

  void _listen() {
    try {
      _sub = widget.source.events.listen(
        (e) => unawaited(_onEvent(e)),
        // Разрывы стрима — забота шины; плашке достаточно не падать.
        onError: (_) {},
      );
    } catch (_) {
      // Рантайм не поднят (тесты host-app без SDK) — живём без плашек.
    }
  }

  /// Приложение перед человеком. Спрятанное в трей окно сюда не
  /// попадает, хотя Flutter считает его активным (см. [AppVisibility]).
  bool get _appIsActive {
    final probe = widget.lifecycleProbe;
    if (probe != null) return probe() == AppLifecycleState.resumed;
    return AppVisibility.isActive;
  }

  Future<void> _onEvent(MessengerEvent e) async {
    if (!(widget.isEnabled?.call() ?? true)) return;
    if (e.eventType != MessengerEventType.messageCreated) return;
    final m = e.message;
    if (m == null) return;
    // Не активны — сработает пуш или системный тост, плашка была бы
    // вторым уведомлением об одном сообщении.
    if (!_appIsActive) return;
    final self = widget.source.selfMessengerUserId;
    if (self != null && m.senderMessengerUserId == self) return;
    // Этот чат открыт — сообщение и так появилось на глазах.
    if (m.roomId == ActiveRoom.current) return;

    final room = await widget.source.room(m.roomId);
    if (room != null && room.muted && !_mentionsMe(m, self)) return;
    if (!mounted) return;

    final l10n = NsgL10n.of(context);
    final preview = await widget.source.showPreview();
    if (!mounted) return;

    var body = preview ? m.body.trim() : l10n.inAppBannerNewMessage;
    if (body.isEmpty) body = l10n.inAppBannerAttachment;
    // В группе важно, КТО написал: имени комнаты для этого мало.
    final author = m.senderDisplayName;
    if (preview && author != null && author.isNotEmpty && !_isDirect(room)) {
      body = '$author: $body';
    }

    _show(
      _BannerData(
        roomId: m.roomId,
        eventId: m.matrixEventId,
        title: room?.name ?? author ?? l10n.inAppBannerNewMessage,
        body: body,
        avatarUrl: room?.avatarUrl,
      ),
    );
  }

  static bool _isDirect(RoomSummary? room) =>
      room != null && room.roomType == RoomType.direct;

  /// Упоминание пробивает заглушенный чат — то же правило, что у пуша:
  /// человек просил не беспокоить чатом, но не собой.
  static bool _mentionsMe(MessengerMessage m, int? self) {
    if (m.mentionedRoom) return true;
    if (self == null) return false;
    return m.mentionedMessengerUserIds?.contains(self) ?? false;
  }

  void _show(_BannerData data) {
    setState(() => _shown = data);
    _hideTimer?.cancel();
    // Следующее сообщение заменяет предыдущее и продлевает показ:
    // очередь плашек человек всё равно не прочитает, а список чатов
    // уже мигает счётчиками.
    _hideTimer = Timer(widget.visibleFor, _hide);
  }

  void _hide() {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (!mounted) return;
    setState(() => _shown = null);
  }

  void _open(_BannerData data) {
    _hide();
    widget.onOpenRoom?.call(data.roomId, eventId: data.eventId);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _shown;
    return Stack(
      children: [
        widget.child,
        if (data != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _Banner(
                key: ValueKey('${data.roomId}:${data.eventId}'),
                data: data,
                onTap: () => _open(data),
                onDismiss: _hide,
              ),
            ),
          ),
      ],
    );
  }
}

class _BannerData {
  const _BannerData({
    required this.roomId,
    required this.eventId,
    required this.title,
    required this.body,
    this.avatarUrl,
  });

  final int roomId;
  final String eventId;
  final String title;
  final String body;
  final String? avatarUrl;
}

class _Banner extends StatefulWidget {
  const _Banner({
    super.key,
    required this.data,
    required this.onTap,
    required this.onDismiss,
  });

  final _BannerData data;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Стеклянные темы делают `surface` полностью прозрачным, и плашка на
    // обоях была бы нечитаемой. Тот же приём, что у найденного поиском:
    // подмешиваем «чернила» пузыря и получаем непрозрачную подложку.
    final plate = inkedSurface(
      highlightSurface(colors.surface, theme.brightness),
      theme.extension<NsgMessageBubbleTokens>()?.bubbleInk,
    );
    final onPlate = colors.onSurface;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Center(
          // На десктопе плашка во всю ширину окна выглядит объявлением;
          // держим её узкой, как в мессенджерах.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Dismissible(
              key: const ValueKey('nsg-message-banner'),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismiss(),
              child: Material(
                color: plate,
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        NsgAvatarImage(
                          mxcUrl: widget.data.avatarUrl,
                          fallbackName: widget.data.title,
                          size: 36,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.data.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: onPlate,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                widget.data.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: onHighlight(onPlate, secondary: true),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
