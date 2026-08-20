import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../pulse/nsg_messenger_pulse.dart';
import '../pulse/pulse_kinds.dart';
import '../session/auth_retry.dart' show isUnreachable;
import '../theme/overlay_surface.dart';
import '../utils/relative_time.dart';
import 'integrations_screen.dart' show CopyableField;
import 'pulse_allowlist_screen.dart';
import 'pulse_members_screen.dart';
import 'pulse_value_thresholds_screen.dart';
import '../widgets/nsg_modal_sheet.dart';

/// Ошибка действия Пульса, которую увидел пользователь → в трекер, ПЕРЕД
/// снеком. Тег [action] здесь не украшение: `pulseActionFailed` — ОДИН снек
/// на девять действий трёх экранов (папки, монитор, правила алертов), и без
/// тега отчёт сводится к «в Пульсе что-то упало».
///
/// Свободная функция, а не метод: `_snack` живёт в трёх разных State-классах,
/// и общий хелпер избавляет от трёх копий.
void _reportPulseActionFailed(Object e, StackTrace st, String action) {
  MessengerRuntime.instance.reportError(e, st, tags: {'pulse.action': action});
}

/// **TASK60 (Connect Pulse — heartbeat-мониторинг)**: дашборд мониторинга.
///
/// Грузит плоские списки папок+мониторов и строит дерево на клиенте
/// (`parentId`/`folderId`). Папки — [ExpansionTile] с roll-up-статусом
/// (worst-of поддерева, паузные мониторы исключены). Мониторы — строки со
/// статус-точкой и относительным временем последнего сигнала.
///
/// **Realtime**: пока экран смонтирован, подписан на
/// `NsgMessenger.pulse.statusStream()`; событие с `monitor != null`
/// точечно обновляет узел в локальном стейте (без refetch дерева). На ошибке
/// стрима — тихая переподписка с backoff (5 c); плюс pull-to-refresh.
///
/// **TASK79 — роль-модель.** Сервер отдаёт только доступные объекты и
/// отдельным списком ([NsgMessengerPulse.listMyAccess]) — эффективную роль
/// каллера на каждом из них. По ней прячем кнопки: `viewer` не видит
/// «Пересоздать токен»/«Пауза», не-`owner` — «Удалить» и управление
/// составом. Это подсказка интерфейсу, а не защита: сервер проверяет права
/// на каждом вызове сам.
///
/// Папка без роли — «путь»: она пришла только чтобы доступный монитор
/// внутри было где отрисовать, поэтому меню управления у неё нет.
///
/// State «нет доступа» остаётся для старых серверов: новый не-члену
/// вернёт пустое дерево, а не [MessengerNotAuthenticatedException].
/// Какой монитор показывать в правой панели после обновления списка.
///
/// Открытая карточка живёт дольше, чем список, из которого её открыли:
/// стрим и `_load` пересобирают мониторы, а монитор мог за это время
/// исчезнуть — удалили тут же или на другом устройстве. Тогда правая
/// панель обязана вернуться к дереву, а не показывать карточку того,
/// чего больше нет: с неё «Пауза» и «Пересоздать токен» уходили бы в
/// никуда, а человек не понимал бы почему.
///
/// Возвращаем СВЕЖИЙ объект, а не тот, что запомнили: имя и статус могли
/// измениться, и шапка карточки показывала бы старое.
PulseMonitor? resolveOpenMonitor(
  List<PulseMonitor> monitors,
  PulseMonitor? open,
) {
  if (open == null) return null;
  final id = open.id;
  if (id == null) return null;
  return monitors.where((m) => m.id == id).firstOrNull;
}

/// С какой ширины мониторинг раскладывается на две панели.
///
/// Тот же порог, что у списка чатов в Chatista: одна раскладка не должна
/// переключаться, пока другая ещё телефонная.
const double kPulseWideLayoutBreakpoint = 800;

/// Ширина левой колонки. Уже, чем у чатов: здесь только имена корневых
/// групп, без превью последнего сообщения.
const double kPulseSidebarWidth = 260;

class PulseScreen extends StatefulWidget {
  const PulseScreen({
    super.key,
    this.leading,
    this.sidebarFooter,
    @visibleForTesting this.pulseOverride,
  });

  /// Подмена фасада для тестов. В проде `null` — берём из runtime.
  ///
  /// Появился после ВТОРОЙ регрессии в этой раскладке подряд (пропавшая
  /// навигация, затем недостижимые действия папки). Обе — про то, чего на
  /// широком экране НЕТ, а такое ловится только живым виджетом: рантайм
  /// ради этого поднимать не будем.
  final NsgMessengerPulse? pulseOverride;

  /// Что показать слева в шапке. `null` — как было: маршрут, открытый
  /// поверх, сам рисует кнопку «назад».
  ///
  /// Нужен, когда экран стоит вкладкой верхнего уровня: возвращаться ему
  /// некуда, а место слева занимает навигация хоста. Виджет, а не флаг:
  /// SDK не знает, чем host рисует свою навигацию.
  final Widget? leading;

  /// Что показать под левой колонкой на широком экране.
  ///
  /// Тот же случай, что и [leading]: экран стоит вкладкой, и хозяйская
  /// навигация должна быть на виду. Жалоба владельца 09.08.2026 —
  /// «мониторинг гасит панель, не вернуться назад»: панель разделов живёт
  /// под списком чатов, а на этой вкладке списка нет, и человек оставался
  /// без единственной навигации, которую видел.
  ///
  /// На узкой раскладке не используется: там панель рисует сам хост
  /// поверх окна.
  final Widget? sidebarFooter;

  @override
  State<PulseScreen> createState() => _PulseScreenState();
}

class _PulseScreenState extends State<PulseScreen> {
  late final NsgMessengerPulse _pulse;

  /// Что выбрано в левой колонке широкой раскладки: корневая папка
  /// (`folderId`) или корневой монитор (`monitorId`). Оба null — ничего не
  /// выбрано, справа подсказка.
  int? _selectedFolderId;
  int? _selectedMonitorId;

  /// Монитор, открытый в правой панели широкой раскладки.
  ///
  /// Жалоба владельца 10.08.2026: «конкретный мониторинг опять
  /// разворачивается на весь экран… а для десктопа должен в правой части
  /// отображаться, левую не трогая». Карточка монитора была модальной
  /// шторкой — она накрывает окно целиком вместе с деревом слева и
  /// панелью разделов внизу.
  PulseMonitor? _detailMonitor;

  /// Раскладка на последнем кадре. Нужна вне `build`: по тапу на монитор
  /// решаем, открыть его в правой панели или шторкой, а `LayoutBuilder`
  /// туда не дотянуться.
  bool _isWide = false;

  List<PulseFolder> _folders = const [];
  List<PulseMonitor> _monitors = const [];

  /// Мои роли на объектах дерева (TASK79). Пустая карта = кнопок нет.
  PulseAccessMap _access = const PulseAccessMap.empty();

  /// Пробы по `monitorId` — только для подписей в списке. Карточка грузит
  /// свою пробу сама: там нужны свежие наблюдения, а не снимок дерева.
  Map<int, PulseTlsProbe> _probes = const {};

  bool _loading = true;
  bool _noAccess = false;
  Object? _error;

  StreamSubscription<PulseEvent>? _sub;
  Timer? _reconnectTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _pulse = widget.pulseOverride ?? MessengerRuntime.instance.pulse;
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _noAccess = false;
    });
    try {
      final results = await Future.wait<Object>([
        _pulse.listFolders(),
        _pulse.listMonitors(),
        // Роли грузим тем же заходом: дерево без них отрисовалось бы с
        // кнопками, которые сервер отклонит.
        _pulse.listMyAccess().catchError(
          // Старый сервер такого метода не знает — деградируем до дерева
          // без управления, а не до пустого экрана.
          (_) => const <PulseAccessEntry>[],
        ),
        // Пробы одним запросом: без них список подписывает пробу
        // heartbeat-текстом «сигналов ещё не было», и исправный монитор
        // читается как неработающий. Ходить за каждой отдельно нельзя —
        // это N+1 на отрисовку дерева.
        _pulse.listTlsProbes().catchError((_) => const <PulseTlsProbe>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _folders = results[0] as List<PulseFolder>;
        _monitors = results[1] as List<PulseMonitor>;
        _probes = {
          for (final p in results[3] as List<PulseTlsProbe>) p.monitorId: p,
        };
        _access = PulseAccessMap.fromEntries(
          results[2] as List<PulseAccessEntry>,
        );
        _loading = false;
      });
      // Realtime подписываем только после успешной загрузки (иначе стрим
      // тоже упадёт NotAuthenticated и заспамит backoff-петлю).
      _subscribe();
    } on MessengerNotAuthenticatedException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _noAccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  // ── Realtime ───────────────────────────────────────────────────────

  void _subscribe() {
    _sub?.cancel();
    _reconnectTimer?.cancel();
    _sub = _pulse.statusStream().listen(
      _onEvent,
      onError: (_) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
      cancelOnError: true,
    );
  }

  void _scheduleReconnect() {
    if (_disposed || _noAccess) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_disposed || !mounted) return;
      _subscribe();
    });
  }

  void _onEvent(PulseEvent event) {
    // **issue #142**: «твои права изменились» — единственное событие без
    // монитора, которое до нас доходит. Точечно обновлять нечего: могли
    // добавить целую папку, могли отобрать. Перечитываем дерево целиком.
    //
    // Раньше сигнала не было вовсе: при выдаче доступа человеку приходило
    // сообщение в чат, а список оставался прежним до обновления руками —
    // ровно это и сообщил владелец 13.08.2026.
    if (event.eventType == pulseEventAccessChanged) {
      if (mounted) unawaited(_load());
      return;
    }
    final m = event.monitor;
    if (m == null || m.id == null || !mounted) return;
    setState(() {
      final next = List<PulseMonitor>.of(_monitors);
      final idx = next.indexWhere((e) => e.id == m.id);
      if (idx >= 0) {
        next[idx] = m;
      } else {
        next.add(m);
      }
      _monitors = next;
    });
  }

  // ── Мутации ────────────────────────────────────────────────────────

  void _snack(String text) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addFolder({int? parentId}) async {
    final l = NsgL10n.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _NamePromptDialog(
        title: l.pulseNewFolder,
        hint: l.pulseFolderNameHint,
        confirm: l.pulseCreate,
      ),
    );
    if (name == null || !mounted) return;
    try {
      await _pulse.createFolder(name: name, parentId: parentId);
    } catch (e, st) {
      _reportPulseActionFailed(e, st, 'createFolder');
      _snack(l.pulseActionFailed);
      return;
    }
    await _load();
  }

  Future<void> _renameFolder(PulseFolder folder) async {
    final l = NsgL10n.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _NamePromptDialog(
        title: l.pulseRename,
        hint: l.pulseFolderNameHint,
        confirm: l.pulseRename,
        initial: folder.name,
      ),
    );
    if (name == null || !mounted) return;
    try {
      await _pulse.renameFolder(id: folder.id!, name: name);
    } catch (e, st) {
      _reportPulseActionFailed(e, st, 'renameFolder');
      _snack(l.pulseActionFailed);
      return;
    }
    await _load();
  }

  Future<void> _deleteFolder(PulseFolder folder) async {
    final l = NsgL10n.of(context);
    final ok = await _confirm(
      title: l.pulseDeleteFolderConfirmTitle,
      body: l.pulseDeleteFolderConfirmBody,
      confirm: l.pulseDelete,
    );
    if (ok != true || !mounted) return;
    try {
      await _pulse.deleteFolder(id: folder.id!);
    } catch (e, st) {
      // Сервер бросает ArgumentError на непустую папку — штатный отказ, не
      // репортим. Но catch тут сплошной: сеть/сервер тоже попадают сюда и
      // молча выдают себя за «папка не пуста». Вот их и репортим — иначе про
      // такую подмену никто не узнает.
      if (e is! ArgumentError) {
        _reportPulseActionFailed(e, st, 'deleteFolder');
      }
      _snack(l.pulseFolderNotEmpty);
      return;
    }
    await _load();
  }

  Future<void> _addMonitor({int? folderId}) async {
    final l = NsgL10n.of(context);
    final result = await showDialog<_NewMonitor>(
      context: context,
      builder: (ctx) =>
          _NewMonitorDialog(l: l, folders: _folders, initialFolderId: folderId),
    );
    if (result == null || !mounted) return;
    // **TASK94**: у пробы нет токена, а значит нет и диалога «скопируйте
    // URL». Показать его пустым было бы обещанием способа, которого нет.
    if (result.isProbe) {
      try {
        final probe = await _pulse.createTlsProbeMonitor(
          name: result.name,
          connectHost: result.connectHost,
          port: result.port,
          serverName: result.serverName,
          folderId: result.folderId,
          periodSeconds: result.periodSeconds,
          graceSeconds: result.graceSeconds,
          timeoutSeconds: result.timeoutSeconds,
          validationMode: result.validationMode,
          expectedThumbprint: result.expectedThumbprint,
          certificateSetKey: result.certificateSetKey,
          warnBeforeDays: result.warnBeforeDays,
          errorBeforeDays: result.errorBeforeDays,
        );
        // **MR2**: рубежи — общий слой, у него своя дверь. Отдельным
        // вызовом, а не полем создания монитора: он одинаково нужен и
        // мониторам, которые про сертификаты ничего не знают.
        if (result.thresholdDays != '30,14,7,1') {
          await _pulse.setExpiryThresholds(
            monitorId: probe.monitorId,
            thresholdDays: result.thresholdDays,
          );
        }
      } catch (e, st) {
        _reportPulseActionFailed(e, st, 'createTlsProbeMonitor');
        _snack(l.pulseActionFailed);
        return;
      }
      await _load();
      return;
    }
    PulseMonitorCreated created;
    try {
      created = await _pulse.createMonitor(
        name: result.name,
        folderId: result.folderId,
        periodSeconds: result.periodSeconds,
        graceSeconds: result.graceSeconds,
      );
    } catch (e, st) {
      _reportPulseActionFailed(e, st, 'createMonitor');
      _snack(l.pulseActionFailed);
      return;
    }
    if (!mounted) return;
    await _showBeatUrlDialog(created.beatUrl);
    await _load();
  }

  /// One-time диалог с beat-URL + готовым curl-сниппетом (токен виден один раз).
  Future<void> _showBeatUrlDialog(String beatUrl) {
    final l = NsgL10n.of(context);
    // Beat-роут принимает ТОЛЬКО POST (PulseBeatRoute methods: {Method.post}) —
    // без -X POST скопированный сниппет уходит GET-ом и молча не работает.
    final curl = 'curl -fsS -X POST $beatUrl';
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final caption = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        );
        return AlertDialog(
          title: Text(l.pulseBeatUrlLabel),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CopyableField(value: beatUrl, copiedMessage: l.pulseCopied),
                  const SizedBox(height: 12),
                  Text(l.pulseCurlHint, style: caption),
                  const SizedBox(height: 4),
                  CopyableField(value: curl, copiedMessage: l.pulseCopied),
                  const SizedBox(height: 8),
                  Text(l.pulseBeatUrlOnce, style: caption),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.commonOk),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String confirm,
  }) {
    final l = NsgL10n.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _openMonitorDetail(PulseMonitor monitor) async {
    // Широко — в правую панель, не трогая дерево слева: там человек
    // держит контекст, из которого пришёл, и оттуда же уходит на другой
    // монитор одним тапом.
    if (_isWide) {
      setState(() => _detailMonitor = monitor);
      return;
    }
    // **Issue #101**: через помощник, а не напрямую. Без ограничения высоты
    // шторка с длинным списком инцидентов дорастала до верха экрана, ручка
    // перетаскивания уезжала под остров, и закрыть диалог было нечем.
    await showNsgModalSheet<void>(
      context: context,
      builder: (ctx) => _MonitorDetailSheet(
        pulse: _pulse,
        monitor: monitor,
        role: _access.monitorRole(monitor.id),
        folders: _folders,
      ),
    );
    // Стрим уже мог обновить пауза/статус; для delete/rotate — перечитываем.
    if (mounted) await _load();
  }

  /// Закрыть карточку монитора в правой панели.
  ///
  /// Перечитываем по той же причине, что и после шторки: удаление и
  /// ротация токена стримом не приезжают.
  Future<void> _closeMonitorDetail() async {
    if (_detailMonitor == null) return;
    setState(() => _detailMonitor = null);
    await _load();
  }

  /// Экран участников объекта. `canManage` = я владелец: сервер отдаст
  /// список любому участнику, но менять состав может только `owner`.
  Future<void> _openMembers({
    int? folderId,
    int? monitorId,
    required String name,
    required bool canManage,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PulseMembersScreen(
          pulse: _pulse,
          folderId: folderId,
          monitorId: monitorId,
          title: name,
          canManage: canManage,
        ),
      ),
    );
    // Мог отдать владение или отозвать доступ себе — дерево перечитываем.
    if (mounted) await _load();
  }

  Future<void> _openAlerts({int? folderId, int? monitorId, String? scopeName}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PulseAlertsScreen(
          pulse: _pulse,
          scopeFolderId: folderId,
          scopeMonitorId: monitorId,
          scopeName: scopeName,
        ),
      ),
    );
  }

  // ── Дерево ─────────────────────────────────────────────────────────

  static int _statusRank(String status) {
    switch (status) {
      case 'down':
        return 4;
      case 'error':
        return 3;
      case 'warn':
        return 2;
      case 'late':
        return 1;
      default:
        return 0; // ok
    }
  }

  static Color _statusColor(BuildContext context, String? status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'ok':
        return Colors.green;
      case 'late':
        return Colors.amber;
      case 'warn':
        return Colors.orange;
      case 'error':
      case 'down':
        return scheme.error;
      default:
        // paused / пусто — нейтральный серый.
        return scheme.onSurface.withValues(alpha: 0.35);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: widget.leading,
        title: Text(l.pulseTitle),
        actions: [
          if (!_noAccess && _error == null)
            PopupMenuButton<_AddKind>(
              icon: const Icon(Icons.add),
              onSelected: (kind) {
                switch (kind) {
                  case _AddKind.folder:
                    _addFolder();
                  case _AddKind.monitor:
                    _addMonitor();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: _AddKind.folder,
                  child: _menuRow(
                    Icons.create_new_folder_outlined,
                    l.pulseAddFolder,
                  ),
                ),
                PopupMenuItem(
                  value: _AddKind.monitor,
                  child: _menuRow(
                    Icons.monitor_heart_outlined,
                    l.pulseAddMonitor,
                  ),
                ),
              ],
            ),
          // **TASK94 §2**: список разрешённых целей. Показываем всем, кто
          // видит мониторинг: править его может только супер-админ, но
          // прятать пункт по роли клиенту нечем — про роль он не знает.
          // Экран сам покажет «доступа нет», и это честнее исчезнувшей
          // кнопки, о которой не догадаешься спросить.
          if (!_noAccess && _error == null)
            IconButton(
              tooltip: l.pulseAllowlistTitle,
              icon: const Icon(Icons.shield_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PulseAllowlistScreen(pulse: _pulse),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, l),
    );
  }

  Widget _buildBody(BuildContext context, NsgL10n l) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_noAccess) {
      return _CenteredMessage(icon: Icons.lock_outline, text: l.pulseNoAccess);
    }
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            _CenteredMessage(
              icon: Icons.error_outline,
              // **issue #135**: недоступность называем словами. Прежде
              // человек читал `SocketException ... statusCode = -1` — это
              // сообщение не для него: сделать с ним он ничего не может, а
              // понять из него, что «связи нет», нельзя.
              //
              // Сюда же 502/503/504 (жалоба 16.08.2026): во время выкатки на
              // экран уезжала HTML-заглушка nginx целиком. Формально это
              // ответ сервера, но предметной причины в нём нет — за шлюзом
              // просто никого нет.
              text: isUnreachable(_error!)
                  ? l.pulseLoadFailedOffline
                  : l.pulseLoadFailed,
              // Техническую подробность оставляем ТОЛЬКО там, где она
              // называет предметную причину и помогает поддержке. У «сервер
              // недоступен» она не добавляет ничего.
              detail: isUnreachable(_error!) ? null : '$_error',
              action: FilledButton.tonalIcon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
                label: Text(l.commonRetry),
              ),
            ),
          ],
        ),
      );
    }

    // childFolders keyed by parentId (null = root), childMonitors by folderId.
    final childFolders = <int?, List<PulseFolder>>{};
    for (final f in _folders) {
      (childFolders[f.parentId] ??= []).add(f);
    }
    final childMonitors = <int?, List<PulseMonitor>>{};
    for (final m in _monitors) {
      (childMonitors[m.folderId] ??= []).add(m);
    }
    for (final list in childFolders.values) {
      list.sort((a, b) {
        final c = a.sortOrder.compareTo(b.sortOrder);
        return c != 0
            ? c
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }
    for (final list in childMonitors.values) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    final rootFolders = childFolders[null] ?? const [];
    final rootMonitors = childMonitors[null] ?? const [];
    final isEmpty = rootFolders.isEmpty && rootMonitors.isEmpty;

    if (isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            _CenteredMessage(
              icon: Icons.monitor_heart_outlined,
              text: l.pulseEmpty,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ширину узнаём здесь и запоминаем: по тапу на монитор надо
        // решить, куда его открыть, а туда LayoutBuilder не достаёт.
        final wide = constraints.maxWidth >= kPulseWideLayoutBreakpoint;
        if (wide != _isWide) {
          _isWide = wide;
          // Сузили окно с открытой карточкой — дерево должно вернуться на
          // весь экран, иначе правая панель осталась бы единственным, что
          // видно.
          if (!wide && _detailMonitor != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _detailMonitor = null);
            });
          }
        }
        if (!wide) {
          // Узко — одно дерево, как было: разворачиваемые папки.
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (final f in rootFolders)
                  _buildFolderTile(context, l, f, childFolders, childMonitors),
                for (final m in rootMonitors) _buildMonitorTile(context, l, m),
              ],
            ),
          );
        }
        return _wideLayout(
          context,
          l,
          rootFolders: rootFolders,
          rootMonitors: rootMonitors,
          childFolders: childFolders,
          childMonitors: childMonitors,
        );
      },
    );
  }

  /// Широкая раскладка: корневые группы слева, содержимое выбранной —
  /// справа.
  ///
  /// Предложение владельца 09.08.2026. До этого широкий экран показывал то
  /// же одноколоночное дерево, что и телефон: чтобы дойти до монитора в
  /// третьем уровне, приходилось разворачивать всю ветку, а половина окна
  /// пустовала.
  Widget _wideLayout(
    BuildContext context,
    NsgL10n l, {
    required List<PulseFolder> rootFolders,
    required List<PulseMonitor> rootMonitors,
    required Map<int?, List<PulseFolder>> childFolders,
    required Map<int?, List<PulseMonitor>> childMonitors,
  }) {
    final theme = Theme.of(context);
    // Выбранное могло исчезнуть между обновлениями (папку удалили на
    // другом устройстве) — тогда возвращаемся к подсказке, а не рисуем
    // пустую правую панель без объяснений.
    final selectedFolder = rootFolders
        .where((f) => f.id != null && f.id == _selectedFolderId)
        .firstOrNull;
    final selectedMonitor = rootMonitors
        .where((m) => m.id != null && m.id == _selectedMonitorId)
        .firstOrNull;
    // Открытый монитор мог исчезнуть (удалили тут же или на другом
    // устройстве) — тогда правая панель возвращается к дереву, а не
    // показывает карточку того, чего больше нет.
    final detail = resolveOpenMonitor(_monitors, _detailMonitor);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: kPulseSidebarWidth,
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (final f in rootFolders)
                        _rootRow(
                          context,
                          icon: Icons.folder_outlined,
                          label: f.name,
                          status: f.id == null
                              ? null
                              : _rollupStatus(
                                  f.id!,
                                  childFolders,
                                  childMonitors,
                                ),
                          selected: f.id != null && f.id == _selectedFolderId,
                          onTap: () => setState(() {
                            _selectedFolderId = f.id;
                            _selectedMonitorId = null;
                          }),
                        ),
                      for (final m in rootMonitors)
                        _rootRow(
                          context,
                          icon: Icons.monitor_heart_outlined,
                          label: m.name,
                          status: m.paused ? null : m.status,
                          selected: m.id != null && m.id == _selectedMonitorId,
                          onTap: () => setState(() {
                            _selectedMonitorId = m.id;
                            _selectedFolderId = null;
                          }),
                        ),
                    ],
                  ),
                ),
              ),
              ?widget.sidebarFooter,
            ],
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: theme.dividerColor.withValues(alpha: 0.4),
        ),
        Expanded(
          child: detail != null
              ? _detailPane(context, l, detail)
              : switch ((selectedFolder, selectedMonitor)) {
                  (final PulseFolder f, _) => Column(
                    key: ValueKey<int?>(f.id),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // **Шапка выбранной папки.** На широком экране корневая
                      // папка плиткой не рисуется, и без этой шапки все её
                      // действия — добавить монитор, участники, переименовать
                      // — оказывались недостижимы: доступ к папке нельзя было
                      // выдать вообще. Регрессия двухпанельной раскладки,
                      // найденная владельцем на живом десктопе.
                      _folderHeader(context, l, f),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            for (final sub
                                in childFolders[f.id] ?? const <PulseFolder>[])
                              _buildFolderTile(
                                context,
                                l,
                                sub,
                                childFolders,
                                childMonitors,
                              ),
                            for (final m
                                in childMonitors[f.id] ??
                                    const <PulseMonitor>[])
                              _buildMonitorTile(context, l, m),
                            if ((childFolders[f.id] ?? const []).isEmpty &&
                                (childMonitors[f.id] ?? const []).isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 96),
                                child: _CenteredMessage(
                                  icon: Icons.monitor_heart_outlined,
                                  text: l.pulseEmpty,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  (_, final PulseMonitor m) => ListView(
                    key: ValueKey<int?>(m.id),
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [_buildMonitorTile(context, l, m)],
                  ),
                  _ => _CenteredMessage(
                    icon: Icons.monitor_heart_outlined,
                    text: l.pulseTitle,
                  ),
                },
        ),
      ],
    );
  }

  /// Шапка правой панели для выбранной папки: имя, алерты и то же меню
  /// действий, что у вложенных папок.
  Widget _folderHeader(BuildContext context, NsgL10n l, PulseFolder folder) {
    final fid = folder.id;
    final canAdmin = _access.folderAtLeast(fid, PulseClientRoles.admin);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        children: [
          const Icon(Icons.folder_outlined, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (canAdmin)
            IconButton(
              tooltip: l.pulseAlerts,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.notifications_none, size: 20),
              onPressed: () =>
                  _openAlerts(folderId: fid, scopeName: folder.name),
            ),
          _folderMenu(context, l, folder),
        ],
      ),
    );
  }

  /// Правая панель с карточкой монитора.
  ///
  /// Та же карточка, что в шторке на телефоне, — с шапкой «назад» вместо
  /// ручки перетаскивания. Удаление здесь не должно звать `Navigator.pop`:
  /// поповать нечего, карточка не маршрут, а `pop` увёл бы человека с
  /// вкладки целиком.
  Widget _detailPane(BuildContext context, NsgL10n l, PulseMonitor monitor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l.commonBack,
              icon: const Icon(Icons.arrow_back),
              onPressed: () => unawaited(_closeMonitorDetail()),
            ),
            Expanded(
              child: Text(
                monitor.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: _MonitorDetailSheet(
            key: ValueKey<int?>(monitor.id),
            pulse: _pulse,
            monitor: monitor,
            role: _access.monitorRole(monitor.id),
            folders: _folders,
            onClose: () => unawaited(_closeMonitorDetail()),
          ),
        ),
      ],
    );
  }

  /// Строка корневого узла в левой колонке.
  Widget _rootRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String? status,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      selected: selected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.10),
      leading: _StatusDot(color: _statusColor(context, status)),
      title: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  /// Меню действий папки: добавить, переименовать, участники, удалить.
  ///
  /// Вынесено из плитки, потому что на широком экране КОРНЕВАЯ папка плиткой
  /// не рисуется вовсе — она выбирается в левой панели, а её содержимое
  /// показывается справа. Без общего меню все её действия (в том числе выдача
  /// доступа) на десктопе оказались недостижимы: регрессия двухпанельной
  /// раскладки, найденная владельцем.
  Widget _folderMenu(BuildContext context, NsgL10n l, PulseFolder folder) {
    final fid = folder.id;
    final canRead = _access.folderRole(fid) != null;
    if (!canRead) return const SizedBox.shrink();
    final canAdmin = _access.folderAtLeast(fid, PulseClientRoles.admin);
    final canOwn = _access.folderAtLeast(fid, PulseClientRoles.owner);
    return PopupMenuButton<_FolderAction>(
      onSelected: (action) {
        switch (action) {
          case _FolderAction.addMonitor:
            _addMonitor(folderId: fid);
          case _FolderAction.addFolder:
            _addFolder(parentId: fid);
          case _FolderAction.rename:
            _renameFolder(folder);
          case _FolderAction.members:
            _openMembers(folderId: fid, name: folder.name, canManage: canOwn);
          case _FolderAction.delete:
            _deleteFolder(folder);
        }
      },
      itemBuilder: (ctx) => [
        if (canAdmin) ...[
          PopupMenuItem(
            value: _FolderAction.addMonitor,
            child: _menuRow(Icons.monitor_heart_outlined, l.pulseAddMonitor),
          ),
          PopupMenuItem(
            value: _FolderAction.addFolder,
            child: _menuRow(Icons.create_new_folder_outlined, l.pulseAddFolder),
          ),
          PopupMenuItem(
            value: _FolderAction.rename,
            child: _menuRow(Icons.edit_outlined, l.pulseRename),
          ),
        ],
        PopupMenuItem(
          value: _FolderAction.members,
          child: _menuRow(Icons.people_outline, l.pulseMembers),
        ),
        if (canOwn)
          PopupMenuItem(
            value: _FolderAction.delete,
            child: _menuRow(
              Icons.delete_outline,
              l.pulseDelete,
              color: Theme.of(ctx).colorScheme.error,
            ),
          ),
      ],
    );
  }

  Widget _buildFolderTile(
    BuildContext context,
    NsgL10n l,
    PulseFolder folder,
    Map<int?, List<PulseFolder>> childFolders,
    Map<int?, List<PulseMonitor>> childMonitors,
  ) {
    final fid = folder.id;
    final rollup = fid == null
        ? null
        : _rollupStatus(fid, childFolders, childMonitors);
    final subFolders = childFolders[fid] ?? const [];
    final subMonitors = childMonitors[fid] ?? const [];
    // Роли нет — папка пришла лишь как путь к доступному монитору внутри.
    final canRead = _access.folderRole(fid) != null;
    final canAdmin = _access.folderAtLeast(fid, PulseClientRoles.admin);
    return ExpansionTile(
      key: PageStorageKey<String>('pulse-folder-${folder.id}'),
      leading: _StatusDot(color: _statusColor(context, rollup)),
      title: Row(
        children: [
          Expanded(
            child: Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (canAdmin)
            IconButton(
              tooltip: l.pulseAlerts,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.notifications_none, size: 20),
              onPressed: () =>
                  _openAlerts(folderId: fid, scopeName: folder.name),
            ),
          if (canRead) _folderMenu(context, l, folder),
        ],
      ),
      childrenPadding: const EdgeInsets.only(left: 16),
      children: [
        for (final f in subFolders)
          _buildFolderTile(context, l, f, childFolders, childMonitors),
        for (final m in subMonitors) _buildMonitorTile(context, l, m),
      ],
    );
  }

  Widget _buildMonitorTile(BuildContext context, NsgL10n l, PulseMonitor m) {
    final theme = Theme.of(context);
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final paused = m.paused;
    final dotColor = paused
        ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
        : _statusColor(context, m.status);

    // Подзаголовок: явный statusText, иначе «сигнал N назад».
    final String subtitle;
    final st = m.statusText;
    if (st != null && st.trim().isNotEmpty) {
      subtitle = st;
    } else if (PulseMonitorKinds.isProbe(m.kind)) {
      // **Срок — главное, что нужно видеть в списке.** Просьба владельца:
      // ради него мониторинг сертификатов и заводится, а ходить за ним в
      // карточку каждого монитора — значит не увидеть приближающийся срок
      // до тех пор, пока не откроешь именно тот монитор.
      final notAfter = _probes[m.id]?.lastNotAfter;
      // **У пробы beat-а нет и не будет.** Подписывать её «сигналов ещё не
      // было» — врать о работающем мониторе ровно тем способом, против
      // которого вся задача: человек видит исправную проверку и читает её
      // как мёртвую. Показываем время последней ПОПЫТКИ.
      final checkedAt = _probes[m.id]?.lastCheckAt;
      if (notAfter != null) {
        final left = notAfter.difference(DateTime.now().toUtc()).inDays;
        final d = notAfter.toLocal();
        final date =
            '${d.day.toString().padLeft(2, '0')}.'
            '${d.month.toString().padLeft(2, '0')}.${d.year}';
        subtitle = left < 0
            ? l.pulseCertExpiredShort
            : l.pulseCertLeftUntil(left, date);
      } else {
        subtitle = checkedAt == null
            ? l.pulseProbeNoChecks
            : l.pulseProbeCheckedAgo(
                formatRelativeTime(
                  checkedAt.toLocal(),
                  lang: lang,
                  shortEn: false,
                ),
              );
      }
    } else if (m.lastBeatAt != null) {
      subtitle = l.pulseLastSignal(
        formatRelativeTime(m.lastBeatAt!.toLocal(), lang: lang, shortEn: false),
      );
    } else {
      subtitle = l.pulseNoSignal;
    }

    // Бейдж down/late (только для активных мониторов).
    String? badge;
    if (!paused) {
      if (m.status == 'down') {
        badge = l.pulseBadgeDown;
      } else if (m.status == 'late') {
        badge = l.pulseBadgeLate;
      }
    }

    return ListTile(
      leading: paused
          ? Icon(
              Icons.pause_circle_outline,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            )
          : _StatusDot(color: dotColor),
      title: Row(
        children: [
          Flexible(
            child: Text(
              m.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: paused
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                    : null,
              ),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            _Badge(text: badge, color: dotColor),
          ],
          if (paused) ...[
            const SizedBox(width: 8),
            _Badge(
              text: l.pulsePaused,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ],
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => _openMonitorDetail(m),
    );
  }

  String? _rollupStatus(
    int folderId,
    Map<int?, List<PulseFolder>> childFolders,
    Map<int?, List<PulseMonitor>> childMonitors,
  ) {
    String? worst;
    int worstRank = -1;
    void visit(int fid) {
      for (final m in childMonitors[fid] ?? const <PulseMonitor>[]) {
        if (m.paused) continue;
        final r = _statusRank(m.status);
        if (r > worstRank) {
          worstRank = r;
          worst = m.status;
        }
      }
      for (final f in childFolders[fid] ?? const <PulseFolder>[]) {
        final id = f.id;
        if (id != null) visit(id);
      }
    }

    visit(folderId);
    return worst;
  }

  Widget _menuRow(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: color == null ? null : TextStyle(color: color)),
      ],
    );
  }
}

enum _AddKind { folder, monitor }

enum _FolderAction { addMonitor, addFolder, rename, members, delete }

// ─────────────────────────────────────────────────────────────────────
// Monitor detail sheet
// ─────────────────────────────────────────────────────────────────────

/// Detail-лист монитора: статус, период/допуск, последний сигнал, инциденты
/// (с «Взять в работу») и действия (пауза/возобновить, пересоздать токен,
/// алерты, удалить).
class _MonitorDetailSheet extends StatefulWidget {
  const _MonitorDetailSheet({
    super.key,
    required this.pulse,
    required this.monitor,
    this.folders = const [],
    required this.role,
    this.onClose,
  });

  /// Чем закрыть карточку после удаления монитора. `null` — карточка
  /// показана шторкой, и закрывает её `Navigator.pop`. На широком экране
  /// она не маршрут, и `pop` увёл бы человека со всей вкладки.
  final VoidCallback? onClose;

  final NsgMessengerPulse pulse;
  final PulseMonitor monitor;

  /// Куда можно перенести. Пустой список — переносить некуда, и действие
  /// не показывается: кнопка, открывающая пустой выбор, хуже её отсутствия.
  final List<PulseFolder> folders;

  /// Моя эффективная роль на этом мониторе (TASK79). null — роли нет;
  /// такой монитор в дереве вообще не появляется, но защищаемся и здесь.
  final String? role;

  @override
  State<_MonitorDetailSheet> createState() => _MonitorDetailSheetState();
}

class _MonitorDetailSheetState extends State<_MonitorDetailSheet> {
  late PulseMonitor _monitor;
  late Future<List<PulseIncident>> _incidentsFuture;
  bool _busy = false;

  /// **TASK94**: цель и последние наблюдения — только у монитора-пробы.
  /// `null` до первой загрузки и у heartbeat-мониторов.
  PulseTlsProbe? _probe;

  /// **MR2**: состояние рубежей напоминаний. Отдельная сущность и отдельная
  /// загрузка — слой общий, к пробе не привязан.
  PulseExpiryReminder? _reminder;

  bool get _isProbe => PulseMonitorKinds.isProbe(_monitor.kind);

  bool get _canAdmin =>
      PulseClientRoles.atLeast(widget.role, PulseClientRoles.admin);
  bool get _canOwn =>
      PulseClientRoles.atLeast(widget.role, PulseClientRoles.owner);

  @override
  void initState() {
    super.initState();
    _monitor = widget.monitor;
    _reloadIncidents();
    if (_isProbe) unawaited(_loadProbe());
  }

  /// Наблюдения пробы. Отказ гасим молча: карточка сертификата — это
  /// подробность, из-за которой не должна пропадать вся шторка монитора
  /// (статус, инциденты и кнопки в ней важнее).
  Future<void> _loadProbe() async {
    try {
      final probe = await widget.pulse.getTlsProbe(monitorId: _monitor.id!);
      final reminder = await widget.pulse.getExpiryReminder(
        monitorId: _monitor.id!,
      );
      if (!mounted) return;
      setState(() {
        _probe = probe;
        _reminder = reminder;
      });
    } catch (e, st) {
      _reportPulseActionFailed(e, st, 'getTlsProbe');
    }
  }

  /// Проверить прямо сейчас. Ответ приходит уже с новым наблюдением, но
  /// статус монитора обновляет сервер — его подхватит стрим дашборда.
  Future<void> _runProbeNow() async {
    final l = NsgL10n.of(context);
    setState(() => _busy = true);
    try {
      final probe = await widget.pulse.runProbeNow(monitorId: _monitor.id!);
      if (!mounted) return;
      setState(() => _probe = probe);
    } catch (e, st) {
      _reportPulseActionFailed(e, st, 'runProbeNow');
      _snack(l.pulseActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// **issue #108**: перевести пробу на другую цель.
  ///
  /// Не «настройки», а отдельное действие с предупреждением: наблюдения
  /// прежней цели сбрасываются, и человек должен понимать это ДО правки —
  /// зелёный монитор с тем же именем начнёт смотреть в другое место.
  Future<void> _editProbeTarget() async {
    final l = NsgL10n.of(context);
    final probe = _probe;
    if (probe == null) return;
    final result = await showDialog<({String host, int port, String sni})>(
      context: context,
      builder: (ctx) => _ProbeTargetDialog(l: l, probe: probe),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = await widget.pulse.updateProbeTarget(
        monitorId: _monitor.id!,
        connectHost: result.host,
        port: result.port,
        serverName: result.sni,
      );
      if (!mounted) return;
      setState(() => _probe = updated);
    } catch (e, st) {
      _reportPulseActionFailed(e, st, 'updateProbeTarget');
      _snack(l.pulseActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reloadIncidents() {
    _incidentsFuture = widget.pulse
        .listIncidents(monitorId: _monitor.id!)
        .catchError((_) => <PulseIncident>[]);
  }

  void _snack(String text) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _togglePause() async {
    final l = NsgL10n.of(context);
    setState(() => _busy = true);
    try {
      final updated = await widget.pulse.setPaused(
        id: _monitor.id!,
        paused: !_monitor.paused,
      );
      if (!mounted) return;
      setState(() => _monitor = updated);
    } catch (e, st) {
      _reportPulseActionFailed(e, st, 'togglePause');
      _snack(l.pulseActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rotate() async {
    final l = NsgL10n.of(context);
    setState(() => _busy = true);
    PulseMonitorCreated created;
    try {
      created = await widget.pulse.rotateToken(id: _monitor.id!);
    } catch (e, st) {
      _reportPulseActionFailed(e, st, 'rotateToken');
      _snack(l.pulseActionFailed);
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    setState(() {
      _monitor = created.monitor;
      _busy = false;
    });
    await _showBeatUrlDialog(created.beatUrl);
  }

  Future<void> _showBeatUrlDialog(String beatUrl) {
    final l = NsgL10n.of(context);
    // Beat-роут принимает ТОЛЬКО POST (PulseBeatRoute methods: {Method.post}) —
    // без -X POST скопированный сниппет уходит GET-ом и молча не работает.
    final curl = 'curl -fsS -X POST $beatUrl';
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final caption = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        );
        return AlertDialog(
          title: Text(l.pulseBeatUrlLabel),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CopyableField(value: beatUrl, copiedMessage: l.pulseCopied),
                  const SizedBox(height: 12),
                  Text(l.pulseCurlHint, style: caption),
                  const SizedBox(height: 4),
                  CopyableField(value: curl, copiedMessage: l.pulseCopied),
                  const SizedBox(height: 8),
                  Text(l.pulseBeatUrlOnce, style: caption),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.commonOk),
            ),
          ],
        );
      },
    );
  }

  /// Перенос монитора в папку (или в корень).
  ///
  /// Меняет круг видящих: роль на папке наследуется вниз. Поэтому действие
  /// только у владельца, а сервер вдобавок требует `admin` на папке-цели —
  /// иначе свой монитор можно было бы подложить в чужое дерево.
  Future<void> _move() async {
    final l = NsgL10n.of(context);
    final picked = await showDialog<({int? id, bool chosen})>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.pulseMoveMonitorTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop((id: null, chosen: true)),
            child: Text(l.pulseFolderRoot),
          ),
          for (final f in widget.folders)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop((id: f.id, chosen: true)),
              child: Text(f.name),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    if (picked.id == _monitor.folderId) return;

    setState(() => _busy = true);
    try {
      final updated = await widget.pulse.moveMonitor(
        id: _monitor.id!,
        folderId: picked.id,
      );
      if (!mounted) return;
      setState(() => _monitor = updated);
      // Дерево перестроилось: монитор теперь в другом месте, и карточка,
      // висящая поверх старого места, врала бы о раскладке.
      widget.onClose?.call();
    } catch (e, st) {
      _reportPulseActionFailed(e, st, 'moveMonitor');
      _snack(l.pulseActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l = NsgL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.pulseDeleteMonitorConfirmTitle),
        content: Text(l.pulseDeleteMonitorConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.pulseDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.pulse.deleteMonitor(id: _monitor.id!);
    } catch (e, st) {
      _reportPulseActionFailed(e, st, 'deleteMonitor');
      _snack(l.pulseActionFailed);
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    final close = widget.onClose;
    if (close != null) {
      close();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _ack(PulseIncident incident) async {
    final l = NsgL10n.of(context);
    try {
      await widget.pulse.ackIncident(incidentId: incident.id!);
    } catch (e, st) {
      // Инцидент не подтвердился — эскалация продолжит будить людей, а
      // причина до сих пор никуда не уходила.
      _reportPulseActionFailed(e, st, 'ackIncident');
      _snack(l.pulseActionFailed);
      return;
    }
    if (!mounted) return;
    setState(_reloadIncidents);
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final m = _monitor;

    final String lastSignal;
    if (m.lastBeatAt != null) {
      lastSignal = formatRelativeTime(
        m.lastBeatAt!.toLocal(),
        lang: lang,
        shortEn: false,
      );
    } else {
      lastSignal = l.pulseNoSignal;
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  m.paused
                      ? Icon(
                          Icons.pause_circle_outline,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        )
                      : _StatusDot(
                          color: _PulseScreenState._statusColor(
                            context,
                            m.status,
                          ),
                          size: 14,
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(m.name, style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Здесь показывается ТЕКУЩИЙ статус монитора, а не порог: у
              // монитора порога нет вовсе, он есть у правила оповещения.
              // Ключ `pulseMinSeverityLabel` приехал сюда из формы правила и
              // подписывал статус словами «минимальная важность» — строка
              // читалась как настройка, которой не существует.
              _DetailRow(
                label: l.pulseStatusLabel,
                value: m.paused ? l.pulsePaused : _severityLabel(l, m.status),
              ),
              _DetailRow(
                label: l.pulsePeriodLabel,
                value: l.pulseDetailPeriodGrace(
                  _periodLabel(l, m.periodSeconds),
                  m.graceSeconds,
                ),
              ),
              // У пробы beat-а нет: строка «последний сигнал» у неё всегда
              // пуста и читалась бы как поломка. Вместо неё — цель.
              if (_isProbe)
                _DetailRow(
                  label: l.pulseProbeTargetLabel,
                  value: _probe == null
                      ? '—'
                      : '${_probe!.connectHost}:${_probe!.port} · SNI '
                            '${_probe!.serverName}',
                )
              else
                _DetailRow(label: l.pulseLastSignalLabel, value: lastSignal),
              if (_isProbe) ...[
                const SizedBox(height: 12),
                _CertificateCard(l: l, probe: _probe, reminder: _reminder),
              ],
              const SizedBox(height: 12),

              // Действия. Прячем по роли: показать кнопку, которую сервер
              // отклонит, — худший способ объяснить, что прав нет.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_canAdmin) ...[
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _togglePause,
                      icon: Icon(
                        m.paused
                            ? Icons.play_circle_outline
                            : Icons.pause_circle_outline,
                        size: 18,
                      ),
                      label: Text(m.paused ? l.pulseResume : l.pulsePause),
                    ),
                    // Токена у пробы нет вовсе — пересоздавать нечего.
                    // Вместо этого ручной запуск проверки.
                    if (_isProbe)
                      OutlinedButton.icon(
                        onPressed: _busy || _monitor.paused
                            ? null
                            : _runProbeNow,
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text(l.pulseProbeRunNow),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _rotate,
                        icon: const Icon(Icons.autorenew, size: 18),
                        label: Text(l.pulseRotateToken),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _PulseAlertsScreen(
                            pulse: widget.pulse,
                            scopeMonitorId: m.id,
                            scopeName: m.name,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.notifications_none, size: 18),
                      label: Text(l.pulseAlerts),
                    ),
                  ],
                  // **issue #116**: числа приходят в beat, а решают пороги,
                  // и живут они у нас — менять границу можно, не трогая
                  // отправителя. У пробы чисел не бывает: она снимает
                  // сертификат, а не измерение.
                  if (_canAdmin && !_isProbe)
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PulseValueThresholdsScreen(
                            pulse: widget.pulse,
                            monitorId: m.id!,
                            monitorName: m.name,
                            lastValues: decodeMonitorValues(m.lastValuesJson),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.speed_outlined, size: 18),
                      label: Text(l.pulseValueThresholds),
                    ),
                  // **issue #108**: правка цели — право владельца, как и
                  // перенос: сменить предмет наблюдения не легче, чем
                  // сменить круг видящих.
                  if (_canOwn && _isProbe && _probe != null)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _editProbeTarget,
                      icon: const Icon(
                        Icons.edit_location_alt_outlined,
                        size: 18,
                      ),
                      label: Text(l.pulseProbeEditTarget),
                    ),
                  if (_canOwn && widget.folders.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _move,
                      icon: const Icon(Icons.drive_file_move_outline, size: 18),
                      label: Text(l.pulseMoveMonitor),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PulseMembersScreen(
                          pulse: widget.pulse,
                          monitorId: m.id,
                          title: m.name,
                          canManage: _canOwn,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.people_outline, size: 18),
                    label: Text(l.pulseMembers),
                  ),
                  if (_canOwn)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _delete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(l.pulseDelete),
                    ),
                ],
              ),
              if (!_canAdmin) ...[
                const SizedBox(height: 8),
                Text(
                  l.pulseReadOnlyHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(l.pulseIncidents, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              FutureBuilder<List<PulseIncident>>(
                future: _incidentsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final incidents = snap.data ?? const <PulseIncident>[];
                  if (incidents.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        l.pulseNoIncidents,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final inc in incidents)
                        _IncidentRow(
                          incident: inc,
                          lang: lang,
                          // Ack — обязательство «я разбираюсь»; наблюдателю
                          // его не предлагаем (сервер всё равно откажет).
                          onAck:
                              _canAdmin &&
                                  inc.resolvedAt == null &&
                                  inc.ackedAt == null
                              ? () => _ack(inc)
                              : null,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _severityLabel(NsgL10n l, String status) {
    switch (status) {
      case 'warn':
        return l.pulseSeverityWarn;
      case 'error':
        return l.pulseSeverityError;
      case 'down':
        return l.pulseSeverityDown;
      case 'late':
        return l.pulseBadgeLate;
      default:
        return status;
    }
  }
}

/// Маппинг periodSeconds → человекочитаемый label (совпадает с вариантами
/// picker-а; неизвестное значение → «N s»).
String _periodLabel(NsgL10n l, int seconds) {
  switch (seconds) {
    case 60:
      return l.pulsePeriod60s;
    case 300:
      return l.pulsePeriod5m;
    case 900:
      return l.pulsePeriod15m;
    case 1800:
      return l.pulsePeriod30m;
    case 3600:
      return l.pulsePeriod1h;
    case 86400:
      return l.pulsePeriod24h;
    default:
      return '$seconds s';
  }
}

class _IncidentRow extends StatelessWidget {
  const _IncidentRow({
    required this.incident,
    required this.lang,
    required this.onAck,
  });

  final PulseIncident incident;
  final String lang;
  final VoidCallback? onAck;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final String state;
    if (incident.resolvedAt != null) {
      state = l.pulseIncidentResolved;
    } else if (incident.ackedAt != null) {
      state = l.pulseIncidentAcked;
    } else {
      state = l.pulseIncidentOpen;
    }
    final when = formatRelativeTime(
      incident.openedAt.toLocal(),
      lang: lang,
      shortEn: false,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${incident.severity.toUpperCase()} · $state',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  when,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (onAck != null)
            FilledButton.tonal(onPressed: onAck, child: Text(l.pulseAck)),
        ],
      ),
    );
  }
}

/// **Карточка сертификата** (TASK94 §8): что реально стоит на порту.
///
/// Показывает НАБЛЮДЕНИЯ последней успешной проверки, а не то, что человек
/// вводил в форме: смысл пробы в расхождении между ними. Ни ключей, ни PEM,
/// ни путей на сервере здесь нет и быть не должно — граница задачи (§15
/// запроса).
class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.l, required this.probe, this.reminder});

  final NsgL10n l;
  final PulseTlsProbe? probe;

  /// **MR2**: состояние рубежей. `null` — слой ещё ничего не наблюдал.
  final PulseExpiryReminder? reminder;

  /// Дней до истечения. Вниз, как и на сервере: 13.5 суток — это 13.
  static int? daysLeft(DateTime? notAfter, DateTime now) {
    if (notAfter == null) return null;
    return notAfter.difference(now).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = probe;
    final border = Border.all(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
    );
    if (p == null || p.lastThumbprint == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          l.pulseCertNoData,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }
    final left = daysLeft(p.lastNotAfter, DateTime.now().toUtc());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.pulseCertificateTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (p.lastSubject != null)
            _DetailRow(label: l.pulseCertSubject, value: p.lastSubject!),
          if (p.lastSans != null)
            _DetailRow(label: l.pulseCertSans, value: p.lastSans!),
          if (p.lastIssuer != null)
            _DetailRow(label: l.pulseCertIssuer, value: p.lastIssuer!),
          if (p.lastNotAfter != null)
            _DetailRow(
              label: l.pulseCertValidUntil,
              value: _date(p.lastNotAfter!),
            ),
          if (left != null)
            _DetailRow(label: l.pulseCertDaysLeftLabel, value: '$left'),
          if (p.lastLatencyMs != null)
            _DetailRow(
              label: l.pulseCertLatency,
              value: '${p.lastLatencyMs} ms',
            ),
          // **MR2**: видно, какое напоминание уже ушло. Без этой строки
          // «почему не пришла карточка про 14 дней» выясняется только в
          // базе — а спросят об этом ровно в тот момент, когда счёт на дни.
          if (reminder != null)
            _DetailRow(
              label: l.pulseReminderLastLabel,
              value: reminder!.lastNotifiedThreshold == null
                  ? '${reminder!.thresholdDays} · ${l.pulseReminderNone}'
                  : '${reminder!.thresholdDays} · '
                        '${reminder!.lastNotifiedThreshold}',
            ),
          // Ошибку политики показываем и на зелёном мониторе: в режиме
          // доверия по отпечатку несовпавшее имя статуса не меняет, но знать
          // о нём надо ДО перевода службы на публичный УЦ.
          if (p.lastPolicyErrors != null)
            _DetailRow(label: l.pulseCertProblem, value: p.lastPolicyErrors!),
          if (p.lastCheckAt != null)
            _DetailRow(
              label: l.pulseCertLastCheck,
              value: _date(p.lastCheckAt!),
            ),
          // Последний УСПЕХ отдельно от последней попытки: по первому видно,
          // что воркер жив, по второму — когда сертификат был в порядке.
          if (p.lastSuccessAt != null)
            _DetailRow(
              label: l.pulseCertLastSuccess,
              value: _date(p.lastSuccessAt!),
            ),
          const SizedBox(height: 8),
          // Отпечаток целиком, с копированием: его сверяют посимвольно с
          // тем, что показывает сервер, и обрезанный тут бесполезен.
          Text(
            l.pulseCertThumbprint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SelectableText(
                  p.lastThumbprint!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                tooltip: l.pulseCopy,
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: p.lastThumbprint!),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.maybeOf(
                    context,
                  )?.showSnackBar(SnackBar(content: Text(l.pulseCopied)));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _date(DateTime d) {
    final u = d.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${u.year}-${two(u.month)}-${two(u.day)} '
        '${two(u.hour)}:${two(u.minute)} UTC';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// **issue #108**: диалог правки цели пробы.
///
/// Поля заполнены текущей целью — правят обычно одно из трёх (чаще всего
/// имя в SNI при переезде или адрес при смене узла). Предупреждение о
/// сбросе наблюдений стоит НАД полями, а не под кнопкой: прочитать его
/// нужно до правки, а не после.
class _ProbeTargetDialog extends StatefulWidget {
  const _ProbeTargetDialog({required this.l, required this.probe});

  final NsgL10n l;
  final PulseTlsProbe probe;

  @override
  State<_ProbeTargetDialog> createState() => _ProbeTargetDialogState();
}

class _ProbeTargetDialogState extends State<_ProbeTargetDialog> {
  late final TextEditingController _host = TextEditingController(
    text: widget.probe.connectHost,
  );
  late final TextEditingController _port = TextEditingController(
    text: '${widget.probe.port}',
  );
  late final TextEditingController _sni = TextEditingController(
    text: widget.probe.serverName,
  );

  @override
  void initState() {
    super.initState();
    for (final c in [_host, _port, _sni]) {
      c.addListener(_sync);
    }
  }

  void _sync() => setState(() {});

  @override
  void dispose() {
    for (final c in [_host, _port, _sni]) {
      c.removeListener(_sync);
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid {
    final p = int.tryParse(_port.text.trim());
    return _host.text.trim().isNotEmpty &&
        _sni.text.trim().isNotEmpty &&
        p != null &&
        p >= 1 &&
        p <= 65535;
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return AlertDialog(
      title: Text(l.pulseProbeEditTarget),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.pulseProbeEditTargetBody,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _host,
              decoration: InputDecoration(
                labelText: l.pulseProbeHost,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _port,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l.pulseProbePortLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sni,
              decoration: InputDecoration(
                labelText: l.pulseProbeSni,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.of(context).pop((
                  host: _host.text.trim(),
                  port: int.parse(_port.text.trim()),
                  sni: _sni.text.trim(),
                ))
              : null,
          child: Text(l.pulseProbeEditTarget),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Alerts (rules) screen
// ─────────────────────────────────────────────────────────────────────

/// Экран правил оповещения для scope (папка ИЛИ монитор). Показывает правила,
/// относящиеся к этому scope, и позволяет добавлять/удалять их.
class _PulseAlertsScreen extends StatefulWidget {
  const _PulseAlertsScreen({
    required this.pulse,
    this.scopeFolderId,
    this.scopeMonitorId,
    this.scopeName,
  });

  final NsgMessengerPulse pulse;
  final int? scopeFolderId;
  final int? scopeMonitorId;
  final String? scopeName;

  @override
  State<_PulseAlertsScreen> createState() => _PulseAlertsScreenState();
}

class _PulseAlertsScreenState extends State<_PulseAlertsScreen> {
  late Future<List<PulseAlertRule>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.pulse.listRules();
  }

  List<PulseAlertRule> _forScope(List<PulseAlertRule> all) {
    return all.where((r) {
      if (widget.scopeMonitorId != null) {
        return r.scopeMonitorId == widget.scopeMonitorId;
      }
      if (widget.scopeFolderId != null) {
        return r.scopeFolderId == widget.scopeFolderId;
      }
      return false;
    }).toList();
  }

  void _snack(String text) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addRule() async {
    final l = NsgL10n.of(context);
    final result = await showDialog<_NewRule>(
      context: context,
      builder: (ctx) => _NewRuleDialog(pulse: widget.pulse),
    );
    if (result == null || !mounted) return;
    try {
      await widget.pulse.createRule(
        scopeFolderId: widget.scopeFolderId,
        scopeMonitorId: widget.scopeMonitorId,
        roomId: result.roomId,
        minSeverity: result.minSeverity,
        escalateAfterMinutes: result.escalateAfterMinutes,
        level1UserIds: result.level1UserIds,
      );
    } catch (e, st) {
      // Правило алертов не создалось — мониторинг молча остаётся без
      // оповещения, что как раз тот случай, когда узнать надо нам, а не
      // пользователю.
      _reportPulseActionFailed(e, st, 'createRule');
      _snack(l.pulseActionFailed);
      return;
    }
    if (!mounted) return;
    setState(_reload);
  }

  Future<void> _deleteRule(PulseAlertRule rule) async {
    final l = NsgL10n.of(context);
    try {
      await widget.pulse.deleteRule(id: rule.id!);
    } catch (e, st) {
      _reportPulseActionFailed(e, st, 'deleteRule');
      _snack(l.pulseActionFailed);
      return;
    }
    if (!mounted) return;
    setState(_reload);
  }

  String _severityLabel(NsgL10n l, String severity) {
    switch (severity) {
      case 'warn':
        return l.pulseSeverityWarn;
      case 'error':
        return l.pulseSeverityError;
      case 'down':
        return l.pulseSeverityDown;
      default:
        return severity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final title = widget.scopeName == null
        ? l.pulseAlerts
        : '${l.pulseAlerts} · ${widget.scopeName}';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRule,
        icon: const Icon(Icons.add),
        label: Text(l.pulseAddRule),
      ),
      body: FutureBuilder<List<PulseAlertRule>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            if (snap.error is MessengerNotAuthenticatedException) {
              return _CenteredMessage(
                icon: Icons.lock_outline,
                text: l.pulseNoAccess,
              );
            }
            return _CenteredMessage(
              icon: Icons.error_outline,
              text: l.pulseLoadFailed,
              detail: '${snap.error}',
            );
          }
          final rules = _forScope(snap.data ?? const []);
          if (rules.isEmpty) {
            return _CenteredMessage(
              icon: Icons.notifications_off_outlined,
              text: l.pulseNoRules,
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              for (final r in rules)
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(
                    l.pulseRuleSummary(
                      _severityLabel(l, r.minSeverity),
                      '${r.roomId}',
                    ),
                  ),
                  subtitle: r.escalateAfterMinutes == null
                      ? null
                      : Text(
                          '${l.pulseEscalateAfterLabel}: '
                          '${r.escalateAfterMinutes}',
                        ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    tooltip: l.pulseDeleteRule,
                    onPressed: () => _deleteRule(r),
                  ),
                  onLongPress: () => _deleteRule(r),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Результат диалога создания правила.
class _NewRule {
  const _NewRule({
    required this.roomId,
    required this.minSeverity,
    this.escalateAfterMinutes,
    this.level1UserIds,
  });

  final int roomId;
  final String minSeverity;
  final int? escalateAfterMinutes;
  final String? level1UserIds;
}

/// Диалог создания правила: комната (dropdown из rooms.list()), min severity,
/// escalateAfterMinutes (опц.), level1 CSV MUID.
class _NewRuleDialog extends StatefulWidget {
  const _NewRuleDialog({required this.pulse});

  final NsgMessengerPulse pulse;

  @override
  State<_NewRuleDialog> createState() => _NewRuleDialogState();
}

class _NewRuleDialogState extends State<_NewRuleDialog> {
  late Future<List<RoomSummary>> _roomsFuture;
  int? _roomId;
  String _severity = 'warn';
  final _escalateCtl = TextEditingController();
  final _level1Ctl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _roomsFuture = MessengerRuntime.instance.rooms
        .list(limit: 100)
        .catchError((_) => <RoomSummary>[]);
  }

  @override
  void dispose() {
    _escalateCtl.dispose();
    _level1Ctl.dispose();
    super.dispose();
  }

  void _submit() {
    final roomId = _roomId;
    if (roomId == null) return;
    final esc = int.tryParse(_escalateCtl.text.trim());
    final lvl1 = _level1Ctl.text.trim();
    Navigator.of(context).pop(
      _NewRule(
        roomId: roomId,
        minSeverity: _severity,
        escalateAfterMinutes: esc,
        level1UserIds: lvl1.isEmpty ? null : lvl1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return AlertDialog(
      title: Text(l.pulseAddRule),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<RoomSummary>>(
              future: _roomsFuture,
              builder: (context, snap) {
                final rooms = snap.data ?? const <RoomSummary>[];
                return DropdownButtonFormField<int>(
                  initialValue: _roomId,
                  isExpanded: true,
                  // issue #43: без явного цвета меню выпадашки берёт canvasColor
                  // (= прозрачный surface в Glass-теме) и просвечивает диалог.
                  dropdownColor: kOverlaySurface,
                  decoration: InputDecoration(
                    labelText: l.pulseRoomLabel,
                    border: const OutlineInputBorder(),
                  ),
                  hint: Text(l.pulsePickRoom),
                  items: [
                    for (final r in rooms)
                      DropdownMenuItem<int>(
                        value: r.id,
                        child: Text(
                          r.name?.trim().isNotEmpty == true
                              ? r.name!
                              : '#${r.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _roomId = v),
                );
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              isExpanded: true,
              // issue #43: без явного цвета меню выпадашки берёт canvasColor
              // (= прозрачный surface в Glass-теме) и просвечивает диалог.
              dropdownColor: kOverlaySurface,
              decoration: InputDecoration(
                labelText: l.pulseMinSeverityLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'warn',
                  child: Text(l.pulseSeverityWarn),
                ),
                DropdownMenuItem(
                  value: 'error',
                  child: Text(l.pulseSeverityError),
                ),
                DropdownMenuItem(
                  value: 'down',
                  child: Text(l.pulseSeverityDown),
                ),
              ],
              onChanged: (v) => setState(() => _severity = v ?? 'warn'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _escalateCtl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l.pulseEscalateAfterLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _level1Ctl,
              decoration: InputDecoration(
                labelText: l.pulseLevel1Label,
                helperText: l.pulseLevel1Helper,
                helperMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: _roomId == null ? null : _submit,
          child: Text(l.pulseCreate),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// New monitor dialog
// ─────────────────────────────────────────────────────────────────────

class _NewMonitor {
  const _NewMonitor({
    required this.name,
    required this.folderId,
    required this.periodSeconds,
    required this.graceSeconds,
    this.kind = PulseMonitorKinds.heartbeat,
    this.connectHost = '',
    this.port = 443,
    this.serverName = '',
    this.timeoutSeconds = 10,
    this.validationMode = PulseValidationModes.publicPki,
    this.expectedThumbprint,
    this.warnBeforeDays = 30,
    this.errorBeforeDays = 14,
    this.thresholdDays = '30,14,7,1',
    this.certificateSetKey,
  });

  final String name;
  final int? folderId;
  final int periodSeconds;
  final int graceSeconds;

  /// **TASK94**: `heartbeat` — сервис стучится сам; `tlsProbe` — сервер сам
  /// ходит на цель и проверяет сертификат.
  final String kind;

  // Ниже — только для `tlsProbe`.
  final String connectHost;
  final int port;
  final String serverName;
  final int timeoutSeconds;
  final String validationMode;
  final String? expectedThumbprint;
  final int warnBeforeDays;
  final int errorBeforeDays;

  /// **MR2**: рубежи однократных напоминаний, CSV. Пусто — не напоминать.
  final String thresholdDays;

  /// **MR3**: ключ набора — общий у endpoint, обязанных отдавать один и тот
  /// же сертификат. `null` — проба сама по себе.
  final String? certificateSetKey;

  bool get isProbe => kind == PulseMonitorKinds.tlsProbe;
}

class _NewMonitorDialog extends StatefulWidget {
  const _NewMonitorDialog({
    required this.l,
    required this.folders,
    this.initialFolderId,
  });

  final NsgL10n l;
  final List<PulseFolder> folders;
  final int? initialFolderId;

  @override
  State<_NewMonitorDialog> createState() => _NewMonitorDialogState();
}

class _NewMonitorDialogState extends State<_NewMonitorDialog> {
  final _nameCtl = TextEditingController();
  final _graceCtl = TextEditingController(text: '120');
  final _hostCtl = TextEditingController();
  final _portCtl = TextEditingController(text: '443');
  final _sniCtl = TextEditingController();
  final _timeoutCtl = TextEditingController(text: '10');
  final _thumbCtl = TextEditingController();
  final _warnCtl = TextEditingController(text: '30');
  final _errorCtl = TextEditingController(text: '14');
  final _thresholdsCtl = TextEditingController(text: '30,14,7,1');
  final _setKeyCtl = TextEditingController();
  int? _folderId;
  int _periodSeconds = 300;
  bool _periodTouched = false;
  String _kind = PulseMonitorKinds.heartbeat;
  String _validation = PulseValidationModes.publicPki;

  @override
  void initState() {
    super.initState();
    _folderId = widget.initialFolderId;
    for (final c in [_nameCtl, _hostCtl, _sniCtl, _portCtl]) {
      c.addListener(_sync);
    }
  }

  void _sync() => setState(() {});

  @override
  void dispose() {
    for (final c in [_nameCtl, _hostCtl, _sniCtl, _portCtl]) {
      c.removeListener(_sync);
    }
    for (final c in [
      _nameCtl,
      _graceCtl,
      _hostCtl,
      _portCtl,
      _sniCtl,
      _timeoutCtl,
      _thumbCtl,
      _warnCtl,
      _errorCtl,
      _thresholdsCtl,
      _setKeyCtl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isProbe => _kind == PulseMonitorKinds.tlsProbe;

  bool get _valid {
    if (_nameCtl.text.trim().isEmpty) return false;
    if (!_isProbe) return true;
    final port = int.tryParse(_portCtl.text.trim());
    return _hostCtl.text.trim().isNotEmpty &&
        _sniCtl.text.trim().isNotEmpty &&
        port != null &&
        port >= 1 &&
        port <= 65535;
  }

  int _intOr(TextEditingController c, int fallback) =>
      int.tryParse(c.text.trim()) ?? fallback;

  void _submit() {
    if (!_valid) return;
    final grace = _intOr(_graceCtl, 120);
    final warn = _intOr(_warnCtl, 30);
    final err = _intOr(_errorCtl, 14);
    Navigator.of(context).pop(
      _NewMonitor(
        name: _nameCtl.text.trim(),
        folderId: _folderId,
        periodSeconds: _periodSeconds,
        graceSeconds: grace < 0 ? 0 : grace,
        kind: _kind,
        connectHost: _hostCtl.text.trim(),
        port: _intOr(_portCtl, 443),
        serverName: _sniCtl.text.trim(),
        timeoutSeconds: _intOr(_timeoutCtl, 10),
        validationMode: _validation,
        expectedThumbprint: _thumbCtl.text.trim().isEmpty
            ? null
            : _thumbCtl.text.trim(),
        thresholdDays: _thresholdsCtl.text.trim(),
        certificateSetKey: _setKeyCtl.text.trim().isEmpty
            ? null
            : _setKeyCtl.text.trim(),
        warnBeforeDays: warn,
        // Красный не может наступать позже жёлтого — иначе монитор прыгал бы
        // из зелёного сразу в красный, минуя предупреждение. Сервер это тоже
        // проверяет; здесь поправляем молча, чтобы человек не ловил отказ
        // формы из-за порядка, о котором его не предупреждали.
        errorBeforeDays: err > warn ? warn : err,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return AlertDialog(
      title: Text(l.pulseNewMonitor),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Род монитора — первым полем: от него зависит половина формы, и
            // переключать его после заполнения полей человеку неприятно.
            DropdownButtonFormField<String>(
              initialValue: _kind,
              isExpanded: true,
              dropdownColor: kOverlaySurface,
              decoration: InputDecoration(
                labelText: l.pulseKindLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: PulseMonitorKinds.heartbeat,
                  child: Text(
                    l.pulseKindHeartbeat,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: PulseMonitorKinds.tlsProbe,
                  child: Text(
                    l.pulseKindTlsProbe,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (v) => setState(() {
                _kind = v ?? PulseMonitorKinds.heartbeat;
                // Пробе сутки, heartbeat-у пять минут — но только пока
                // человек не выбрал период сам: молча переписать его выбор
                // при переключении рода хуже неудобного умолчания.
                if (!_periodTouched) {
                  _periodSeconds = _isProbe ? 86400 : 300;
                }
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtl,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l.pulseNameLabel,
                hintText: l.pulseMonitorNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _folderId,
              isExpanded: true,
              // issue #43: без явного цвета меню выпадашки берёт canvasColor
              // (= прозрачный surface в Glass-теме) и просвечивает диалог.
              dropdownColor: kOverlaySurface,
              decoration: InputDecoration(
                labelText: l.pulseParentFolderLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l.pulseFolderRoot),
                ),
                for (final f in widget.folders)
                  DropdownMenuItem<int?>(
                    value: f.id,
                    child: Text(
                      f.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _folderId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _periodSeconds,
              isExpanded: true,
              // issue #43: без явного цвета меню выпадашки берёт canvasColor
              // (= прозрачный surface в Glass-теме) и просвечивает диалог.
              dropdownColor: kOverlaySurface,
              decoration: InputDecoration(
                labelText: l.pulsePeriodLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 60, child: Text(l.pulsePeriod60s)),
                DropdownMenuItem(value: 300, child: Text(l.pulsePeriod5m)),
                DropdownMenuItem(value: 900, child: Text(l.pulsePeriod15m)),
                // 30 мин — шаг планировщиков «раз в полчаса» (Task Scheduler /
                // cron). Без этого пресета такие сервисы приходилось ставить на
                // «1 час», и пропущенный прогон подсвечивался только через час.
                DropdownMenuItem(value: 1800, child: Text(l.pulsePeriod30m)),
                DropdownMenuItem(value: 3600, child: Text(l.pulsePeriod1h)),
                DropdownMenuItem(value: 86400, child: Text(l.pulsePeriod24h)),
                // **TASK94**: неделя — для сертификатов. Они живут месяцами,
                // и рубежи напоминаний предупреждают за 30 дней; чаще
                // спрашивать нечего.
                DropdownMenuItem(value: 604800, child: Text(l.pulsePeriod7d)),
              ],
              onChanged: (v) => setState(() {
                _periodSeconds = v ?? 300;
                _periodTouched = true;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _graceCtl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l.pulseGraceLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_isProbe) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _hostCtl,
                      decoration: InputDecoration(
                        labelText: l.pulseProbeHostLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _portCtl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l.pulseProbePortLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sniCtl,
                decoration: InputDecoration(
                  labelText: l.pulseProbeSniLabel,
                  // Пояснение прямо в поле: отдельный SNI — самая непонятная
                  // часть формы, и без подсказки сюда вписывают тот же адрес,
                  // что и выше.
                  helperText: l.pulseProbeSniHelp,
                  helperMaxLines: 2,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _validation,
                isExpanded: true,
                dropdownColor: kOverlaySurface,
                decoration: InputDecoration(
                  labelText: l.pulseProbeValidationLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: PulseValidationModes.publicPki,
                    child: Text(l.pulseProbeValidationPublic),
                  ),
                  DropdownMenuItem(
                    value: PulseValidationModes.pinnedSelfSigned,
                    child: Text(l.pulseProbeValidationPinned),
                  ),
                ],
                onChanged: (v) => setState(
                  () => _validation = v ?? PulseValidationModes.publicPki,
                ),
              ),
              if (_validation == PulseValidationModes.pinnedSelfSigned) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _thumbCtl,
                  decoration: InputDecoration(
                    labelText: l.pulseProbeThumbprintLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _warnCtl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l.pulseProbeWarnDaysLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _errorCtl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l.pulseProbeErrorDaysLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _timeoutCtl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l.pulseProbeTimeoutLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // **MR2**: рубежи напоминаний. Отдельно от «жёлтый/красный за»
              // намеренно: те задают ЦВЕТ монитора, а это — однократные
              // карточки. Свалив их в одно поле, мы бы заставили выбирать
              // между «монитор жёлтый две недели» и «пять карточек подряд».
              TextField(
                controller: _thresholdsCtl,
                decoration: InputDecoration(
                  labelText: l.pulseReminderThresholdsLabel,
                  helperText: l.pulseReminderThresholdsHelp,
                  helperMaxLines: 2,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // **MR3**: один ключ у endpoint, которые обязаны отдавать один
              // сертификат. Пустое поле — проба сама по себе: набора из
              // одной пробы не бывает, сверять было бы не с чем.
              TextField(
                controller: _setKeyCtl,
                decoration: InputDecoration(
                  labelText: l.pulseProbeSetKeyLabel,
                  helperText: l.pulseProbeSetKeyHelp,
                  helperMaxLines: 2,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: _valid ? _submit : null,
          child: Text(l.pulseCreate),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Small shared bits
// ─────────────────────────────────────────────────────────────────────

/// Диалог ввода имени (создание/переименование папки). Возвращает trimmed имя
/// или null (отмена). Кнопка disabled при пустом вводе.
class _NamePromptDialog extends StatefulWidget {
  const _NamePromptDialog({
    required this.title,
    required this.hint,
    required this.confirm,
    this.initial,
  });

  final String title;
  final String hint;
  final String confirm;
  final String? initial;

  @override
  State<_NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<_NamePromptDialog> {
  late final TextEditingController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController(text: widget.initial ?? '')
      ..addListener(_sync);
  }

  void _sync() => setState(() {});

  @override
  void dispose() {
    _ctl.removeListener(_sync);
    _ctl.dispose();
    super.dispose();
  }

  bool get _valid => _ctl.text.trim().isNotEmpty;

  void _submit() {
    if (_valid) Navigator.of(context).pop(_ctl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctl,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l.pulseNameLabel,
          hintText: widget.hint,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: _valid ? (_) => _submit() : null,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: _valid ? _submit : null,
          child: Text(widget.confirm),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, this.size = 12});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.text,
    this.detail,
    this.action,
  });

  final IconData icon;
  final String text;
  final String? detail;

  /// **issue #135**: выход из тупика. Экран, показавший отказ без единой
  /// кнопки, оставляет человеку один способ продолжить — перезапустить
  /// приложение. Именно так и было 13.08.2026: «не открывался, сколько ни
  /// пробуй». `RefreshIndicator` под сообщением есть, но на десктопе жеста
  /// нет вовсе, а на телефоне о нём не догадываются, глядя на ошибку.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
