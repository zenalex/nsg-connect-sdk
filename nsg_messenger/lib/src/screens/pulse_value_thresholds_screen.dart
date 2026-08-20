/// **Пороги по значению** (issue #116) — экран монитора.
///
/// Число, присланное в beat, само по себе бесполезно: любой хаб и любой
/// скрипт умеют посчитать свободное место или температуру, но не умеют
/// решать, когда это становится бедой. Решает платформа — и вот здесь
/// человек это решение и записывает.
///
/// Смысл того, что порог живёт у нас, а не в скрипте отправителя: менять
/// границу можно, не трогая отправителя, и она видна всем, а не спрятана в
/// чужом cron-задании.
library;

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../pulse/nsg_messenger_pulse.dart';

class PulseValueThresholdsScreen extends StatefulWidget {
  const PulseValueThresholdsScreen({
    super.key,
    required this.pulse,
    required this.monitorId,
    required this.monitorName,
    this.lastValues = const {},
  });

  final NsgMessengerPulse pulse;
  final int monitorId;
  final String monitorName;

  /// Последние присланные числа — чтобы имена не приходилось вспоминать по
  /// памяти: опечатка в имени даёт порог, который никогда не сработает.
  final Map<String, num> lastValues;

  @override
  State<PulseValueThresholdsScreen> createState() =>
      _PulseValueThresholdsScreenState();
}

class _PulseValueThresholdsScreenState
    extends State<PulseValueThresholdsScreen> {
  late Future<List<PulseValueThreshold>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.pulse.listValueThresholds(monitorId: widget.monitorId);
  }

  void _snack(String text) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _edit({PulseValueThreshold? existing, String? presetName}) async {
    final l = NsgL10n.of(context);
    final result = await showDialog<_ThresholdInput>(
      context: context,
      builder: (ctx) => _ThresholdDialog(
        l: l,
        existing: existing,
        presetName: presetName,
        knownNames: widget.lastValues.keys.toList(),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.pulse.setValueThreshold(
        monitorId: widget.monitorId,
        name: result.name,
        warnBelow: result.warnBelow,
        errorBelow: result.errorBelow,
        warnAbove: result.warnAbove,
        errorAbove: result.errorAbove,
      );
      if (!mounted) return;
      setState(_reload);
    } catch (_) {
      // Сервер отвергает бессмысленные границы (красный раньше жёлтого,
      // ни одной границы вовсе). Показываем отказ, а не делаем вид.
      _snack(l.pulseActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(PulseValueThreshold t) async {
    final l = NsgL10n.of(context);
    setState(() => _busy = true);
    try {
      await widget.pulse.removeValueThreshold(
        monitorId: widget.monitorId,
        name: t.name,
      );
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
      appBar: AppBar(title: Text(l.pulseValueThresholds)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : () => _edit(),
        icon: const Icon(Icons.add),
        label: Text(l.pulseValueThresholdAdd),
      ),
      body: FutureBuilder<List<PulseValueThreshold>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final thresholds = snap.data ?? const <PulseValueThreshold>[];
          final byName = {for (final t in thresholds) t.name: t};
          // Показываем ОБЪЕДИНЕНИЕ присланных чисел и заведённых порогов:
          // число без порога — приглашение его завести, порог без числа —
          // сигнал, что имя, возможно, написано с ошибкой.
          final names = <String>{
            ...widget.lastValues.keys,
            ...byName.keys,
          }.toList()..sort();

          if (names.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l.pulseValuesEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: names.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final name = names[i];
              final t = byName[name];
              final value = widget.lastValues[name];
              return ListTile(
                title: Text(name),
                subtitle: Text(
                  t == null ? l.pulseValueNoThreshold : _describe(t, l),
                ),
                trailing: value == null
                    ? null
                    : Text(
                        '$value',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                onTap: _busy
                    ? null
                    : () => _edit(existing: t, presetName: name),
                onLongPress: t == null || _busy ? null : () => _remove(t),
              );
            },
          );
        },
      ),
    );
  }

  String _describe(PulseValueThreshold t, NsgL10n l) {
    final parts = <String>[
      if (t.errorBelow != null) '${l.pulseValueErrorBelow} ${t.errorBelow}',
      if (t.warnBelow != null) '${l.pulseValueWarnBelow} ${t.warnBelow}',
      if (t.warnAbove != null) '${l.pulseValueWarnAbove} ${t.warnAbove}',
      if (t.errorAbove != null) '${l.pulseValueErrorAbove} ${t.errorAbove}',
    ];
    return parts.join(' · ');
  }
}

class _ThresholdInput {
  const _ThresholdInput({
    required this.name,
    this.warnBelow,
    this.errorBelow,
    this.warnAbove,
    this.errorAbove,
  });

  final String name;
  final double? warnBelow;
  final double? errorBelow;
  final double? warnAbove;
  final double? errorAbove;
}

class _ThresholdDialog extends StatefulWidget {
  const _ThresholdDialog({
    required this.l,
    required this.knownNames,
    this.existing,
    this.presetName,
  });

  final NsgL10n l;
  final List<String> knownNames;
  final PulseValueThreshold? existing;
  final String? presetName;

  @override
  State<_ThresholdDialog> createState() => _ThresholdDialogState();
}

class _ThresholdDialogState extends State<_ThresholdDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? widget.presetName ?? '',
  );
  late final TextEditingController _warnBelow = _num(widget.existing?.warnBelow);
  late final TextEditingController _errorBelow = _num(
    widget.existing?.errorBelow,
  );
  late final TextEditingController _warnAbove = _num(widget.existing?.warnAbove);
  late final TextEditingController _errorAbove = _num(
    widget.existing?.errorAbove,
  );

  TextEditingController _num(double? v) =>
      TextEditingController(text: v == null ? '' : '$v');

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _warnBelow, _errorBelow, _warnAbove, _errorAbove]) {
      c.addListener(_sync);
    }
  }

  void _sync() => setState(() {});

  @override
  void dispose() {
    for (final c in [_name, _warnBelow, _errorBelow, _warnAbove, _errorAbove]) {
      c.removeListener(_sync);
      c.dispose();
    }
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    return t.isEmpty ? null : double.tryParse(t);
  }

  /// Хотя бы одна граница обязательна: порог без границ — правило, которое
  /// никогда не сработает, а на экране выглядит настроенным.
  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      (_parse(_warnBelow) != null ||
          _parse(_errorBelow) != null ||
          _parse(_warnAbove) != null ||
          _parse(_errorAbove) != null);

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return AlertDialog(
      title: Text(l.pulseValueThresholds),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.pulseValueThresholdHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              enabled: widget.existing == null,
              autofocus: widget.existing == null,
              decoration: InputDecoration(
                labelText: l.pulseValueName,
                border: const OutlineInputBorder(),
              ),
            ),
            if (widget.existing == null && widget.knownNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              // Присланные имена подсказкой: опечатка даёт порог, который
              // никогда не сработает, и понять это можно будет нескоро.
              Wrap(
                spacing: 6,
                children: [
                  for (final n in widget.knownNames)
                    ActionChip(
                      label: Text(n),
                      onPressed: () => _name.text = n,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _field(_errorBelow, l.pulseValueErrorBelow),
            _field(_warnBelow, l.pulseValueWarnBelow),
            _field(_warnAbove, l.pulseValueWarnAbove),
            _field(_errorAbove, l.pulseValueErrorAbove),
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
                  _ThresholdInput(
                    name: _name.text.trim(),
                    warnBelow: _parse(_warnBelow),
                    errorBelow: _parse(_errorBelow),
                    warnAbove: _parse(_warnAbove),
                    errorAbove: _parse(_errorAbove),
                  ),
                )
              : null,
          child: Text(l.pulseCreate),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}
