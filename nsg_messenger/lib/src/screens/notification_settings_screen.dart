import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../settings/nsg_messenger_settings.dart';

/// **TASK20-Phase2 Chunk 4**: simple screen с toggle для message preview.
/// Reachable from host-app's settings (host-app сам встроит navigation
/// — например, `SettingsScreen` → ListTile → push этот route).
///
/// Optimistic UI pattern: toggle мгновенно меняет state, RPC летит в
/// фоне; на failure → revert + snackbar.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
    @visibleForTesting this.settingsOverride,
  });

  /// Visible-for-testing — позволяет widget-тестам подменить
  /// `MessengerRuntime.instance.notificationSettings` на in-memory
  /// fake.
  final NsgMessengerSettings? settingsOverride;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late final NsgMessengerSettings _settings;
  Future<NotificationSettings>? _future;
  bool? _localShowPreview;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _settings =
        widget.settingsOverride ??
        MessengerRuntime.instance.notificationSettings;
    _future = _load();
  }

  Future<NotificationSettings> _load() async {
    final s = await _settings.get();
    if (mounted) {
      setState(() => _localShowPreview = s.showMessagePreview);
    }
    return s;
  }

  Future<void> _toggle(bool newValue) async {
    if (_saving) return;
    final prev = _localShowPreview ?? true;
    setState(() {
      _localShowPreview = newValue;
      _saving = true;
    });
    try {
      await _settings.set(showMessagePreview: newValue);
      if (mounted) setState(() => _saving = false);
    } catch (_) {
      if (!mounted) return;
      // Revert + snackbar.
      setState(() {
        _localShowPreview = prev;
        _saving = false;
      });
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(NsgL10n.of(context).notificationSettingsSaveFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.notificationSettingsTitle)),
      body: FutureBuilder<NotificationSettings>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _localShowPreview == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && _localShowPreview == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }
          final showPreview = _localShowPreview ?? true;
          return ListView(
            children: [
              SwitchListTile(
                title: Text(l.notificationSettingsPreviewTitle),
                subtitle: Text(l.notificationSettingsPreviewSubtitle),
                value: showPreview,
                onChanged: _saving ? null : _toggle,
              ),
            ],
          );
        },
      ),
    );
  }
}
