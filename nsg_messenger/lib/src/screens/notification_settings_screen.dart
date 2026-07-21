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
  bool? _localSendReceipts; // **B11**
  bool? _localDiscoverable; // **Settings**: приватность — найти в поиске.
  // **TASK52**: приватность — direct только от контактов; визитки на звонке.
  bool? _localContactsOnly;
  bool? _localShowCards;
  // **TASK55 итер.3**: показывать ли мой last seen/online (инверсия
  // presenceHidden; взаимность — скрыл, значит не видишь чужой).
  bool? _localPresenceVisible;
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
      setState(() {
        _localShowPreview = s.showMessagePreview;
        _localSendReceipts = s.sendReadReceipts ?? true;
        // Default discoverable=true (legacy users без значения видимы в
        // поиске — соответствует поведению до приватности).
        _localDiscoverable = s.discoverable ?? true;
        _localContactsOnly = s.whoCanMessageMe == 'contacts';
        _localShowCards = s.showCardsOnCall ?? true;
        _localPresenceVisible = !(s.presenceHidden ?? false);
      });
    }
    return s;
  }

  /// Отправить в трекер ошибку сохранения настройки, которую увидел
  /// пользователь. Все шесть тумблеров показывают ОДИН снек
  /// `notificationSettingsSaveFailed` — без тега [field] в трекере они
  /// неотличимы; [field] = имя поля в `_settings.set`.
  ///
  /// Терять это особенно дёшево: тумблер оптимистичный и на ошибке
  /// отщёлкивает назад, так что внешне «просто не сработало» — а среди полей
  /// есть приватность (discoverable / whoCanMessageMe / presenceHidden).
  void _reportSaveFailed(Object e, StackTrace st, String field) {
    MessengerRuntime.instance.reportError(
      e,
      st,
      tags: {'settings.field': field},
    );
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
    } catch (e, st) {
      _reportSaveFailed(e, st, 'showMessagePreview');
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

  /// **B11**: toggle «отправлять read-receipts». Optimistic + revert,
  /// как [_toggle]. showMessagePreview передаём текущим (set требует его).
  Future<void> _toggleReadReceipts(bool newValue) async {
    if (_saving) return;
    final prev = _localSendReceipts ?? true;
    setState(() {
      _localSendReceipts = newValue;
      _saving = true;
    });
    try {
      await _settings.set(
        showMessagePreview: _localShowPreview ?? true,
        sendReadReceipts: newValue,
      );
      if (mounted) setState(() => _saving = false);
    } catch (e, st) {
      _reportSaveFailed(e, st, 'sendReadReceipts');
      if (!mounted) return;
      setState(() {
        _localSendReceipts = prev;
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

  /// **Settings**: toggle «находить меня в поиске» (privacy.discoverable).
  /// Optimistic + revert, как [_toggle]. showMessagePreview передаём
  /// текущим (set требует его).
  Future<void> _toggleDiscoverable(bool newValue) async {
    if (_saving) return;
    final prev = _localDiscoverable ?? true;
    setState(() {
      _localDiscoverable = newValue;
      _saving = true;
    });
    try {
      await _settings.set(
        showMessagePreview: _localShowPreview ?? true,
        discoverable: newValue,
      );
      if (mounted) setState(() => _saving = false);
    } catch (e, st) {
      _reportSaveFailed(e, st, 'discoverable');
      if (!mounted) return;
      setState(() {
        _localDiscoverable = prev;
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

  /// **TASK52**: toggle «писать могут только контакты»
  /// (whoCanMessageMe everyone↔contacts). Optimistic + revert.
  Future<void> _toggleContactsOnly(bool newValue) async {
    if (_saving) return;
    final prev = _localContactsOnly ?? false;
    setState(() {
      _localContactsOnly = newValue;
      _saving = true;
    });
    try {
      await _settings.set(
        showMessagePreview: _localShowPreview ?? true,
        whoCanMessageMe: newValue ? 'contacts' : 'everyone',
      );
      if (mounted) setState(() => _saving = false);
    } catch (e, st) {
      _reportSaveFailed(e, st, 'whoCanMessageMe');
      if (!mounted) return;
      setState(() {
        _localContactsOnly = prev;
        _saving = false;
      });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(NsgL10n.of(context).notificationSettingsSaveFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// **TASK52**: toggle «визитки на экране звонка». Optimistic + revert.
  Future<void> _toggleShowCards(bool newValue) async {
    if (_saving) return;
    final prev = _localShowCards ?? true;
    setState(() {
      _localShowCards = newValue;
      _saving = true;
    });
    try {
      await _settings.set(
        showMessagePreview: _localShowPreview ?? true,
        showCardsOnCall: newValue,
      );
      if (mounted) setState(() => _saving = false);
    } catch (e, st) {
      _reportSaveFailed(e, st, 'showCardsOnCall');
      if (!mounted) return;
      setState(() {
        _localShowCards = prev;
        _saving = false;
      });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(NsgL10n.of(context).notificationSettingsSaveFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// **TASK55 итер.3**: toggle «показывать, когда я в сети» (инверсия
  /// presenceHidden). Optimistic + revert.
  Future<void> _togglePresenceVisible(bool newValue) async {
    if (_saving) return;
    final prev = _localPresenceVisible ?? true;
    setState(() {
      _localPresenceVisible = newValue;
      _saving = true;
    });
    try {
      await _settings.set(
        showMessagePreview: _localShowPreview ?? true,
        presenceHidden: !newValue,
      );
      if (mounted) setState(() => _saving = false);
    } catch (e, st) {
      _reportSaveFailed(e, st, 'presenceHidden');
      if (!mounted) return;
      setState(() {
        _localPresenceVisible = prev;
        _saving = false;
      });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
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
          final sendReceipts = _localSendReceipts ?? true;
          final discoverable = _localDiscoverable ?? true;
          return ListView(
            children: [
              SwitchListTile(
                title: Text(l.notificationSettingsPreviewTitle),
                subtitle: Text(l.notificationSettingsPreviewSubtitle),
                value: showPreview,
                onChanged: _saving ? null : _toggle,
              ),
              SwitchListTile(
                title: Text(l.notificationSettingsReadReceiptsTitle),
                subtitle: Text(l.notificationSettingsReadReceiptsSubtitle),
                value: sendReceipts,
                onChanged: _saving ? null : _toggleReadReceipts,
              ),
              _SectionHeader(text: l.settingsPrivacySectionTitle),
              SwitchListTile(
                title: Text(l.notificationSettingsDiscoverableTitle),
                subtitle: Text(l.notificationSettingsDiscoverableSubtitle),
                value: discoverable,
                onChanged: _saving ? null : _toggleDiscoverable,
              ),
              SwitchListTile(
                key: const Key('whoCanMessageMeToggle'),
                title: Text(l.settingsWhoCanMessageTitle),
                subtitle: Text(l.settingsWhoCanMessageSubtitle),
                value: _localContactsOnly ?? false,
                onChanged: _saving ? null : _toggleContactsOnly,
              ),
              SwitchListTile(
                key: const Key('showCardsOnCallToggle'),
                title: Text(l.settingsShowCardsOnCallTitle),
                subtitle: Text(l.settingsShowCardsOnCallSubtitle),
                value: _localShowCards ?? true,
                onChanged: _saving ? null : _toggleShowCards,
              ),
              SwitchListTile(
                key: const Key('presenceVisibleToggle'),
                title: Text(l.settingsPresenceVisibleTitle),
                subtitle: Text(l.settingsPresenceVisibleSubtitle),
                value: _localPresenceVisible ?? true,
                onChanged: _saving ? null : _togglePresenceVisible,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Subheader-полоска между секциями (например, «Приватность»).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
