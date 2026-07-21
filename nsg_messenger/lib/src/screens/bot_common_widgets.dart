import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../admin/nsg_messenger_bots_admin.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../utils/relative_time.dart';
import 'integrations_screen.dart' show CopyableField;

/// **Issue #49**: общие бот-виджеты для админки ([BotsAdminScreen],
/// TASK36) и пользовательского экрана «Мои боты» ([MyBotsScreen]).
/// Извлечены из приватных виджетов админки, а не скопированы: у обоих
/// экранов одинаковые инварианты (токен виден ОДИН раз в момент выдачи;
/// бот без грантов — почти всегда опечатка; журнал с человекочитаемыми
/// действиями), и копипаста разъехалась бы на первом же изменении.

/// Показать access-токен ОДИН раз (после создания/ротации). В списках
/// ботов токена нет намеренно — экран не должен быть местом, где
/// credential подсматривают через плечо.
Future<void> showBotTokenDialog(BuildContext context, String token) {
  final l = NsgL10n.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        title: Text(l.botsAdminTokenTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CopyableField(
                value: token,
                copiedMessage: l.integrationsCopiedGeneric,
              ),
              const SizedBox(height: 8),
              Text(
                l.botsAdminTokenOnce,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
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

/// Confirm-диалог ротации токена. `true` — подтверждено. Текст
/// предупреждает о простое бота — это самое важное следствие ротации.
Future<bool> confirmBotTokenRotation(BuildContext context) async {
  final l = NsgL10n.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.botsAdminRotateConfirmTitle),
      content: Text(l.botsAdminRotateConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.botsAdminRotateToken),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Результат [BotCreateDialog]: имя, email владельца (null, когда поле
/// не показывалось — myBots-путь, там владелец всегда caller), гранты и
/// видимость в поиске.
class BotCreateRequest {
  const BotCreateRequest({
    required this.name,
    required this.ownerEmail,
    required this.capabilities,
    required this.discoverable,
  });

  final String name;
  final String? ownerEmail;
  final List<String> capabilities;
  final bool discoverable;
}

/// Диалог создания бота: имя (+ email владельца в админке) + чекбоксы
/// capabilities (+ переключатель видимости в myBots). «Создать» disabled,
/// пока обязательные поля пусты или не выбран ни один грант (бот без
/// грантов умеет только слушать — почти всегда это опечатка; нужен именно
/// такой — выбирается `read_only` явно).
class BotCreateDialog extends StatefulWidget {
  const BotCreateDialog({
    super.key,
    required this.l,
    this.askOwnerEmail = true,
    this.showDiscoverable = false,
  });

  final NsgL10n l;

  /// Админка спрашивает email владельца (заводит ботов «за других»);
  /// в myBots владелец всегда caller — поле скрыто.
  final bool askOwnerEmail;

  /// myBots показывает переключатель «Виден в поиске» (дефолт ВЫКЛ —
  /// публичность бота: осознанный выбор владельца, issue #49).
  final bool showDiscoverable;

  @override
  State<BotCreateDialog> createState() => _BotCreateDialogState();
}

class _BotCreateDialogState extends State<BotCreateDialog> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _emailCtl;
  final Set<String> _caps = {NsgMessengerBotsAdmin.capSendMessages};
  bool _discoverable = false;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController()..addListener(_sync);
    _emailCtl = TextEditingController()..addListener(_sync);
  }

  void _sync() => setState(() {});

  @override
  void dispose() {
    _nameCtl.removeListener(_sync);
    _emailCtl.removeListener(_sync);
    _nameCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  bool get _nameValid => _nameCtl.text.trim().isNotEmpty;

  /// Не полноценная валидация email — только защита от очевидной опечатки
  /// (поле идёт в аудит как «кто отвечает за бота», сервер его не проверяет).
  bool get _emailValid {
    if (!widget.askOwnerEmail) return true;
    final email = _emailCtl.text.trim();
    return email.contains('@') &&
        !email.startsWith('@') &&
        !email.endsWith('@');
  }

  bool get _valid => _nameValid && _emailValid && _caps.isNotEmpty;

  String _capLabel(NsgL10n l, String cap) => switch (cap) {
    NsgMessengerBotsAdmin.capReadOnly => l.botsAdminCapReadOnly,
    NsgMessengerBotsAdmin.capSendMessages => l.botsAdminCapSendMessages,
    NsgMessengerBotsAdmin.capManageRoom => l.botsAdminCapManageRoom,
    NsgMessengerBotsAdmin.capWebhookTarget => l.botsAdminCapWebhookTarget,
    _ => cap,
  };

  void _submit() {
    if (!_valid) return;
    Navigator.of(context).pop(
      BotCreateRequest(
        name: _nameCtl.text.trim(),
        ownerEmail: widget.askOwnerEmail ? _emailCtl.text.trim() : null,
        capabilities: NsgMessengerBotsAdmin.kAllCapabilities
            .where(_caps.contains)
            .toList(),
        discoverable: _discoverable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return AlertDialog(
      title: Text(l.botsAdminCreate),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtl,
                autofocus: true,
                textInputAction: widget.askOwnerEmail
                    ? TextInputAction.next
                    : TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l.botsAdminNameLabel,
                  hintText: l.botsAdminNameHint,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: widget.askOwnerEmail ? null : (_) => _submit(),
              ),
              if (widget.askOwnerEmail) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l.botsAdminOwnerEmailLabel,
                    hintText: l.botsAdminOwnerEmailHint,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                l.botsAdminCapabilitiesLabel,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              for (final cap in NsgMessengerBotsAdmin.kAllCapabilities)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _caps.contains(cap),
                  title: Text(_capLabel(l, cap)),
                  subtitle: Text(
                    cap,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onChanged: (on) => setState(() {
                    if (on == true) {
                      _caps.add(cap);
                    } else {
                      _caps.remove(cap);
                    }
                  }),
                ),
              if (widget.showDiscoverable)
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _discoverable,
                  title: Text(l.myBotsDiscoverable),
                  subtitle: Text(
                    l.myBotsDiscoverableSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onChanged: (on) => setState(() => _discoverable = on),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: _valid ? _submit : null,
          child: Text(l.integrationsCreate),
        ),
      ],
    );
  }
}

/// Журнал бота: кто завёл/ротировал/выключал, куда добавляли/откуда
/// отзывали, смены видимости + отказы гейта. Read-only. Loader вместо
/// прямой зависимости от админ-обвязки — myBots грузит журнал своим
/// ownership-gated RPC.
class BotAuditSheet extends StatefulWidget {
  const BotAuditSheet({
    super.key,
    required this.botName,
    required this.loader,
  });

  final String botName;
  final Future<List<BotAuditEvent>> Function() loader;

  @override
  State<BotAuditSheet> createState() => _BotAuditSheetState();
}

class _BotAuditSheetState extends State<BotAuditSheet> {
  late final Future<List<BotAuditEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  /// Человекочитаемое название действия. Неизвестное (журнал старше
  /// клиента) показываем как есть — лучше сырой `action`, чем пустая
  /// строка.
  String _actionLabel(NsgL10n l, String action) => switch (action) {
    'created' => l.botsAdminAuditCreated,
    'token_rotated' => l.botsAdminAuditTokenRotated,
    'enabled' => l.botsAdminAuditEnabled,
    'disabled' => l.botsAdminAuditDisabled,
    'added_to_room' => l.botsAdminAuditAddedToRoom,
    'capability_denied' => l.botsAdminAuditCapabilityDenied,
    // Issue #49: отзыв из комнаты и смены видимости.
    'removed_from_room' => l.botsAdminAuditRemovedFromRoom,
    'discoverable_enabled' => l.botsAdminAuditDiscoverableOn,
    'discoverable_disabled' => l.botsAdminAuditDiscoverableOff,
    _ => action,
  };

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l.botsAdminAuditTitle(widget.botName),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: FutureBuilder<List<BotAuditEvent>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(child: Text(l.botsAdminLoadFailed)),
                    );
                  }
                  final events = snap.data ?? const <BotAuditEvent>[];
                  if (events.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(l.botsAdminAuditEmpty)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: events.length,
                    itemBuilder: (context, i) {
                      final e = events[i];
                      // Инициатор без email — либо сам бот (отказ гейта),
                      // либо платформа (боты-подпорки Pulse/webhook-ов
                      // заводятся системой). Разные вещи — не сваливаем
                      // их в один ярлык.
                      final actor =
                          e.actorEmail ??
                          (e.action == 'capability_denied'
                              ? l.botsAdminAuditActorBot
                              : l.botsAdminAuditActorSystem);
                      final when = formatRelativeTime(
                        e.createdAt.toLocal(),
                        lang: lang,
                        shortEn: false,
                      );
                      final denied = e.action == 'capability_denied';
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          denied ? Icons.block : Icons.check_circle_outline,
                          size: 20,
                          color: denied
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                        title: Text(_actionLabel(l, e.action)),
                        subtitle: Text(
                          e.details == null
                              ? '$actor · $when'
                              : '$actor · $when\n${e.details}',
                        ),
                        isThreeLine: e.details != null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
