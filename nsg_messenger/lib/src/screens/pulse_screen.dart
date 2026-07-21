import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../pulse/nsg_messenger_pulse.dart';
import '../theme/overlay_surface.dart';
import '../utils/relative_time.dart';
import 'integrations_screen.dart' show CopyableField;

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
/// Все эндпоинты gate-ятся server-side (PULSE_ADMIN_EMAILS). Не-админ получает
/// [MessengerNotAuthenticatedException] → показываем дружелюбный state «нет
/// доступа». Пункт входа виден всем — сервер гейтит по факту.
class PulseScreen extends StatefulWidget {
  const PulseScreen({super.key});

  @override
  State<PulseScreen> createState() => _PulseScreenState();
}

class _PulseScreenState extends State<PulseScreen> {
  late final NsgMessengerPulse _pulse;

  List<PulseFolder> _folders = const [];
  List<PulseMonitor> _monitors = const [];

  bool _loading = true;
  bool _noAccess = false;
  Object? _error;

  StreamSubscription<PulseEvent>? _sub;
  Timer? _reconnectTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _pulse = MessengerRuntime.instance.pulse;
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
      ]);
      if (!mounted) return;
      setState(() {
        _folders = results[0] as List<PulseFolder>;
        _monitors = results[1] as List<PulseMonitor>;
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
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(text)),
    );
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
      builder: (ctx) => _NewMonitorDialog(
        l: l,
        folders: _folders,
        initialFolderId: folderId,
      ),
    );
    if (result == null || !mounted) return;
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
    final curl = 'curl -fsS $beatUrl';
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _MonitorDetailSheet(pulse: _pulse, monitor: monitor),
    );
    // Стрим уже мог обновить пауза/статус; для delete/rotate — перечитываем.
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
                  child: _menuRow(Icons.create_new_folder_outlined, l.pulseAddFolder),
                ),
                PopupMenuItem(
                  value: _AddKind.monitor,
                  child: _menuRow(Icons.monitor_heart_outlined, l.pulseAddMonitor),
                ),
              ],
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
      return _CenteredMessage(
        icon: Icons.lock_outline,
        text: l.pulseNoAccess,
      );
    }
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            _CenteredMessage(
              icon: Icons.error_outline,
              text: l.pulseLoadFailed,
              detail: '$_error',
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
        return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }
    for (final list in childMonitors.values) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    final rootFolders = childFolders[null] ?? const [];
    final rootMonitors = childMonitors[null] ?? const [];
    final isEmpty = rootFolders.isEmpty && rootMonitors.isEmpty;

    return RefreshIndicator(
      onRefresh: _load,
      child: isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                _CenteredMessage(
                  icon: Icons.monitor_heart_outlined,
                  text: l.pulseEmpty,
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (final f in rootFolders)
                  _buildFolderTile(context, l, f, childFolders, childMonitors),
                for (final m in rootMonitors)
                  _buildMonitorTile(context, l, m),
              ],
            ),
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
          IconButton(
            tooltip: l.pulseAlerts,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.notifications_none, size: 20),
            onPressed: () => _openAlerts(folderId: fid, scopeName: folder.name),
          ),
          PopupMenuButton<_FolderAction>(
            onSelected: (action) {
              switch (action) {
                case _FolderAction.addMonitor:
                  _addMonitor(folderId: fid);
                case _FolderAction.addFolder:
                  _addFolder(parentId: fid);
                case _FolderAction.rename:
                  _renameFolder(folder);
                case _FolderAction.delete:
                  _deleteFolder(folder);
              }
            },
            itemBuilder: (ctx) => [
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
              PopupMenuItem(
                value: _FolderAction.delete,
                child: _menuRow(
                  Icons.delete_outline,
                  l.pulseDelete,
                  color: Theme.of(ctx).colorScheme.error,
                ),
              ),
            ],
          ),
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

enum _FolderAction { addMonitor, addFolder, rename, delete }

// ─────────────────────────────────────────────────────────────────────
// Monitor detail sheet
// ─────────────────────────────────────────────────────────────────────

/// Detail-лист монитора: статус, период/допуск, последний сигнал, инциденты
/// (с «Взять в работу») и действия (пауза/возобновить, пересоздать токен,
/// алерты, удалить).
class _MonitorDetailSheet extends StatefulWidget {
  const _MonitorDetailSheet({required this.pulse, required this.monitor});

  final NsgMessengerPulse pulse;
  final PulseMonitor monitor;

  @override
  State<_MonitorDetailSheet> createState() => _MonitorDetailSheetState();
}

class _MonitorDetailSheetState extends State<_MonitorDetailSheet> {
  late PulseMonitor _monitor;
  late Future<List<PulseIncident>> _incidentsFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _monitor = widget.monitor;
    _reloadIncidents();
  }

  void _reloadIncidents() {
    _incidentsFuture = widget.pulse
        .listIncidents(monitorId: _monitor.id!)
        .catchError((_) => <PulseIncident>[]);
  }

  void _snack(String text) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(text)),
    );
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
    final curl = 'curl -fsS $beatUrl';
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
    if (mounted) Navigator.of(context).pop();
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
                    child: Text(
                      m.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: l.pulseMinSeverityLabel,
                value: m.paused ? l.pulsePaused : _severityLabel(l, m.status),
              ),
              _DetailRow(
                label: l.pulsePeriodLabel,
                value: l.pulseDetailPeriodGrace(
                  _periodLabel(l, m.periodSeconds),
                  m.graceSeconds,
                ),
              ),
              _DetailRow(label: l.pulseLastSignalLabel, value: lastSignal),
              const SizedBox(height: 12),

              // Действия.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
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
                          onAck: inc.resolvedAt == null && inc.ackedAt == null
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
            FilledButton.tonal(
              onPressed: onAck,
              child: Text(l.pulseAck),
            ),
        ],
      ),
    );
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
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
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
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(text)),
    );
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
                      : Text('${l.pulseEscalateAfterLabel}: '
                          '${r.escalateAfterMinutes}'),
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
                DropdownMenuItem(value: 'warn', child: Text(l.pulseSeverityWarn)),
                DropdownMenuItem(
                  value: 'error',
                  child: Text(l.pulseSeverityError),
                ),
                DropdownMenuItem(value: 'down', child: Text(l.pulseSeverityDown)),
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
  });

  final String name;
  final int? folderId;
  final int periodSeconds;
  final int graceSeconds;
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
  int? _folderId;
  int _periodSeconds = 300;

  @override
  void initState() {
    super.initState();
    _folderId = widget.initialFolderId;
    _nameCtl.addListener(_sync);
  }

  void _sync() => setState(() {});

  @override
  void dispose() {
    _nameCtl.removeListener(_sync);
    _nameCtl.dispose();
    _graceCtl.dispose();
    super.dispose();
  }

  bool get _valid => _nameCtl.text.trim().isNotEmpty;

  void _submit() {
    if (!_valid) return;
    final grace = int.tryParse(_graceCtl.text.trim()) ?? 120;
    Navigator.of(context).pop(
      _NewMonitor(
        name: _nameCtl.text.trim(),
        folderId: _folderId,
        periodSeconds: _periodSeconds,
        graceSeconds: grace < 0 ? 0 : grace,
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
                DropdownMenuItem(value: 3600, child: Text(l.pulsePeriod1h)),
                DropdownMenuItem(value: 86400, child: Text(l.pulsePeriod24h)),
              ],
              onChanged: (v) => setState(() => _periodSeconds = v ?? 300),
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
    _ctl = TextEditingController(text: widget.initial ?? '')..addListener(_sync);
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
  });

  final IconData icon;
  final String text;
  final String? detail;

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
          ],
        ),
      ),
    );
  }
}
