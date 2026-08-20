/// **Куда пробам разрешено ходить** (TASK94 §2, issue #108) — экран списка.
///
/// До него список правился только через API или прямо в базе: пилот завели
/// SQL-ом, и каждый следующий endpoint означал бы поход в psql. Пятнадцать
/// целей так не подключают.
///
/// Экран доступен только супер-админу платформы — так решает сервер, и
/// проверять это здесь второй раз нечем: клиент про роль не знает. Поэтому
/// отказ показывается как состояние экрана, а не прячется заранее: «кнопка
/// есть, но ничего не делает» хуже честного «доступа нет».
library;

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../pulse/nsg_messenger_pulse.dart';
import '../pulse/probe_allowlist_paste.dart';

class PulseAllowlistScreen extends StatefulWidget {
  const PulseAllowlistScreen({super.key, required this.pulse});

  final NsgMessengerPulse pulse;

  @override
  State<PulseAllowlistScreen> createState() => _PulseAllowlistScreenState();
}

class _PulseAllowlistScreenState extends State<PulseAllowlistScreen> {
  late Future<List<PulseProbeAllowlistEntry>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.pulse.listProbeAllowlist();
  }

  void _snack(String text) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _add() async {
    final l = NsgL10n.of(context);
    final entry = await showDialog<_NewEntry>(
      context: context,
      builder: (ctx) => _AllowlistEntryDialog(l: l),
    );
    if (entry == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.pulse.addProbeAllowlistEntry(
        address: entry.address,
        prefixLength: entry.prefixLength,
        port: entry.port,
        note: entry.note,
      );
      if (!mounted) return;
      setState(_reload);
    } on ProbeTargetNotAllowedException catch (e) {
      // Отдельная ветка: сервер отвергает адрес из запрещённого диапазона с
      // ПРИЧИНОЙ, и показать её — единственный способ объяснить человеку,
      // почему `127.0.0.1` не годится. Общее «действие не выполнено»
      // отправило бы его искать ошибку в своих руках.
      _snack(l.pulseAllowlistRejected(e.reason));
    } catch (_) {
      _snack(l.pulseActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// **issue #108**: список целей вставкой.
  ///
  /// Интегратор присылает полтора десятка пар `host:port` разом — по одной
  /// через форму это тринадцать раз по четыре поля, то есть способ
  /// ошибиться. Заводим каждую цель ОТДЕЛЬНЫМ штатным вызовом, а не пачкой:
  /// журнал доступа тогда содержит по записи на строку, ровно как при
  /// ручном вводе, и отказ по одной цели не отменяет остальные.
  Future<void> _paste() async {
    final l = NsgL10n.of(context);
    final input = await showDialog<({String text, String? note})>(
      context: context,
      builder: (ctx) => _AllowlistPasteDialog(l: l),
    );
    if (input == null || !mounted) return;
    final parsed = parseProbeAllowlistPaste(input.text);
    if (parsed.isEmpty) {
      _snack(l.pulseAllowlistPasteBad(parsed.rejected.length));
      return;
    }

    setState(() => _busy = true);
    var added = 0;
    var existing = 0;
    var failed = parsed.rejected.length;
    // Состав списка читаем ОДИН раз до цикла: спрашивать сервер перед
    // каждой строкой — тринадцать лишних запросов ради одной цифры в итоге.
    var known = <String>{};
    try {
      final before = await widget.pulse.listProbeAllowlist();
      known = {for (final e in before) '${e.address}:${e.port}'};
    } catch (_) {
      // Не смогли прочитать — не беда: итог просто назовёт всё добавленным.
    }
    try {
      for (final t in parsed.targets) {
        try {
          final had = known.contains(t.key);
          await widget.pulse.addProbeAllowlistEntry(
            address: t.address,
            prefixLength: t.prefixLength,
            port: t.port,
            note: input.note,
          );
          if (had) {
            existing++;
          } else {
            added++;
            known.add(t.key);
          }
        } catch (_) {
          // Одна отвергнутая цель не отменяет остальные: список от
          // заказчика почти всегда частично годен, и заставлять его
          // вычищать текст ради одной строки — лишний круг переписки.
          failed++;
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _reload();
        });
        _snack(l.pulseAllowlistPasteResult(added, existing, failed));
      }
    }
  }

  Future<void> _remove(PulseProbeAllowlistEntry entry) async {
    final l = NsgL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.pulseAllowlistRemove),
        // Говорим, ЧТО именно случится: мониторы не гаснут, они краснеют с
        // внятной причиной. Иначе удаление выглядит как «выключить
        // мониторинг», и его боятся делать.
        content: Text(l.pulseAllowlistRemoveBody),
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
      await widget.pulse.removeProbeAllowlistEntry(id: entry.id!);
      if (!mounted) return;
      setState(_reload);
    } catch (_) {
      _snack(l.pulseActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.pulseAllowlistTitle),
        actions: [
          IconButton(
            tooltip: l.pulseAllowlistPaste,
            icon: const Icon(Icons.playlist_add),
            onPressed: _busy ? null : _paste,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _add,
        icon: const Icon(Icons.add),
        label: Text(l.pulseAllowlistAdd),
      ),
      body: FutureBuilder<List<PulseProbeAllowlistEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            // Сюда попадает и «не супер-админ»: сервер отвечает одинаково на
            // «нет прав» и «не существует» (anti-enumeration), и гадать за
            // него мы не будем.
            return _centered(context, Icons.lock_outline, l.pulseNoAccess);
          }
          final items = snap.data ?? const <PulseProbeAllowlistEntry>[];
          if (items.isEmpty) {
            return _centered(
              context,
              Icons.shield_outlined,
              l.pulseAllowlistEmpty,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = items[i];
              final mask = e.prefixLength == null ? '' : '/${e.prefixLength}';
              return ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text('${e.address}$mask:${e.port}'),
                subtitle: e.note == null ? null : Text(e.note!),
                trailing: IconButton(
                  tooltip: l.pulseAllowlistRemove,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _busy ? null : () => _remove(e),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _centered(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// **issue #108**: диалог вставки списка целей.
///
/// Показывает разбор ДО отправки: сколько целей понято и сколько строк не
/// разобрано. Человек, вставивший чужой список, должен увидеть расхождение
/// со своим счётом здесь, а не выяснять его потом по журналу.
class _AllowlistPasteDialog extends StatefulWidget {
  const _AllowlistPasteDialog({required this.l});

  final NsgL10n l;

  @override
  State<_AllowlistPasteDialog> createState() => _AllowlistPasteDialogState();
}

class _AllowlistPasteDialogState extends State<_AllowlistPasteDialog> {
  final _textCtl = TextEditingController();
  final _noteCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textCtl.addListener(_sync);
  }

  void _sync() => setState(() {});

  @override
  void dispose() {
    _textCtl.removeListener(_sync);
    _textCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final parsed = parseProbeAllowlistPaste(_textCtl.text);
    return AlertDialog(
      title: Text(l.pulseAllowlistPaste),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textCtl,
              autofocus: true,
              minLines: 5,
              maxLines: 12,
              decoration: InputDecoration(
                hintText: l.pulseAllowlistPasteHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(l.pulseAllowlistPasteCount(parsed.targets.length)),
            if (parsed.rejected.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                l.pulseAllowlistPasteBad(parsed.rejected.length),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 4),
              // Показываем сами строки: человек ищет их глазами в своём
              // списке, и наш пересказ он там не найдёт.
              Text(
                parsed.rejected.take(5).join('\n'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtl,
              decoration: InputDecoration(
                labelText: l.pulseAllowlistNote,
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
          onPressed: parsed.targets.isEmpty
              ? null
              : () => Navigator.of(context).pop((
                  text: _textCtl.text,
                  note: _noteCtl.text.trim().isEmpty
                      ? null
                      : _noteCtl.text.trim(),
                )),
          child: Text(l.pulseCreate),
        ),
      ],
    );
  }
}

class _NewEntry {
  const _NewEntry({
    required this.address,
    required this.prefixLength,
    required this.port,
    required this.note,
  });

  final String address;
  final int? prefixLength;
  final int port;
  final String? note;
}

class _AllowlistEntryDialog extends StatefulWidget {
  const _AllowlistEntryDialog({required this.l});

  final NsgL10n l;

  @override
  State<_AllowlistEntryDialog> createState() => _AllowlistEntryDialogState();
}

class _AllowlistEntryDialogState extends State<_AllowlistEntryDialog> {
  final _addressCtl = TextEditingController();
  final _prefixCtl = TextEditingController();
  final _portCtl = TextEditingController(text: '443');
  final _noteCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addressCtl.addListener(_sync);
    _portCtl.addListener(_sync);
  }

  void _sync() => setState(() {});

  @override
  void dispose() {
    _addressCtl.removeListener(_sync);
    _portCtl.removeListener(_sync);
    for (final c in [_addressCtl, _prefixCtl, _portCtl, _noteCtl]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid {
    final port = int.tryParse(_portCtl.text.trim());
    return _addressCtl.text.trim().isNotEmpty &&
        port != null &&
        port >= 1 &&
        port <= 65535;
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return AlertDialog(
      title: Text(l.pulseAllowlistAdd),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _addressCtl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l.pulseAllowlistAddress,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _prefixCtl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l.pulseAllowlistPrefix,
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
            // Не украшение: через полгода решать, можно ли убрать строку,
            // будет человек, которого сейчас здесь нет.
            TextField(
              controller: _noteCtl,
              decoration: InputDecoration(
                labelText: l.pulseAllowlistNote,
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
              ? () => Navigator.of(context).pop(
                  _NewEntry(
                    address: _addressCtl.text.trim(),
                    prefixLength: int.tryParse(_prefixCtl.text.trim()),
                    port: int.parse(_portCtl.text.trim()),
                    note: _noteCtl.text.trim().isEmpty
                        ? null
                        : _noteCtl.text.trim(),
                  ),
                )
              : null,
          child: Text(l.pulseCreate),
        ),
      ],
    );
  }
}
