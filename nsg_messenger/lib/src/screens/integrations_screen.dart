import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../integrations/nsg_messenger_integrations.dart';
import '../messenger_runtime.dart';
import '../utils/relative_time.dart';

/// **TASK58 (incoming webhooks / автопост статусов)**: экран управления
/// входящими webhook-ами (автопостами) комнаты. Открывается из настроек
/// группы (owner/admin) — ListTile «Интеграции».
///
/// Содержит две секции:
///   * **Автопосты** (TASK58) — список webhook-ов (имя, «последний пост» по
///     `lastPostedAt`, состояние enabled, ⋯-меню: пересоздать токен / вкл-
///     выкл / тестовый пост / удалить); «+ добавить автопост» спрашивает имя,
///     зовёт `createWebhook`, показывает URL (`<hooksBaseUrl>/<token>`) с
///     кнопкой копирования (токен виден один раз).
///   * **Боты** (TASK59) — self-service бот-интеграции: список
///     `BotIntegrationView` (имя + webhook-URL + события, ⋯-меню: пересоздать
///     секрет / вкл-выкл / удалить); «＋ Добавить бота» спрашивает имя +
///     webhook-URL, зовёт `createBotIntegration`, показывает one-time диалог
///     учётных данных (bot-токен / webhook-секрет / apiBase / roomId /
///     messengerUserId / события).
///
/// Server enforces authorization (owner/admin); экран доступен только из
/// admin-ветки настроек группы — client-side гейт там же.
class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key, required this.roomId});

  final int roomId;

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  late final NsgMessengerIntegrations _integrations;
  late final String _hooksBaseUrl;
  late Future<List<IncomingWebhook>> _webhooksFuture;
  late Future<List<BotIntegrationView>> _botsFuture;

  @override
  void initState() {
    super.initState();
    _integrations = MessengerRuntime.instance.integrations;
    _hooksBaseUrl = MessengerRuntime.instance.hooksBaseUrl;
    _webhooksFuture = _integrations.listWebhooks(roomId: widget.roomId);
    _botsFuture = _integrations.listBotIntegrations(roomId: widget.roomId);
  }

  Future<void> _refresh() async {
    setState(() {
      _webhooksFuture = _integrations.listWebhooks(roomId: widget.roomId);
    });
    await _webhooksFuture;
  }

  Future<void> _refreshBots() async {
    setState(() {
      _botsFuture = _integrations.listBotIntegrations(roomId: widget.roomId);
    });
    await _botsFuture;
  }

  Future<void> _refreshAll() async {
    setState(() {
      _webhooksFuture = _integrations.listWebhooks(roomId: widget.roomId);
      _botsFuture = _integrations.listBotIntegrations(roomId: widget.roomId);
    });
    await Future.wait<void>([_webhooksFuture, _botsFuture]);
  }

  /// Отправить в трекер ошибку действия, которую увидел пользователь.
  ///
  /// Если ошибку показали пользователю — её обязан видеть и трекер, иначе
  /// баг остаётся невидимым (так прятался `MessengerNotAuthenticatedException`
  /// под снеком сохранения визитки). Снек здесь один на все действия, поэтому
  /// различать их можно только тегом [action].
  void _reportActionFailed(Object e, StackTrace st, String action) {
    MessengerRuntime.instance.reportError(
      e,
      st,
      tags: {'integrations.action': action},
    );
  }

  /// Собрать отображаемый webhook-URL из base + публичного токена.
  String _webhookUrl(String token) {
    final base = _hooksBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/$token';
  }

  Future<void> _addAutopost() async {
    final l = NsgL10n.of(context);
    final name = await _promptName(context, l);
    if (name == null || name.trim().isEmpty || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    IncomingWebhookCreated created;
    try {
      created = await _integrations.createWebhook(
        roomId: widget.roomId,
        name: name.trim(),
      );
    } catch (e, st) {
      // Все девять действий экрана показывают ОДИН снек
      // `integrationsActionFailed` — без тега в трекере они неотличимы друг
      // от друга. `integrations.action` = имя RPC, за которым пришла ошибка.
      _reportActionFailed(e, st, 'createWebhook');
      messenger?.showSnackBar(
        SnackBar(content: Text(l.integrationsActionFailed)),
      );
      return;
    }
    if (!mounted) return;
    await _showWebhookUrlDialog(created.token);
    await _refresh();
  }

  Future<void> _rotate(IncomingWebhook w) async {
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    IncomingWebhookCreated created;
    try {
      created = await _integrations.rotateToken(id: w.id!);
    } catch (e, st) {
      _reportActionFailed(e, st, 'rotateToken');
      messenger?.showSnackBar(
        SnackBar(content: Text(l.integrationsActionFailed)),
      );
      return;
    }
    if (!mounted) return;
    await _showWebhookUrlDialog(created.token);
    await _refresh();
  }

  Future<void> _toggleEnabled(IncomingWebhook w) async {
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _integrations.setEnabled(id: w.id!, enabled: !w.enabled);
    } catch (e, st) {
      _reportActionFailed(e, st, 'setEnabled');
      messenger?.showSnackBar(
        SnackBar(content: Text(l.integrationsActionFailed)),
      );
      return;
    }
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _testPost(IncomingWebhook w) async {
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _integrations.testPost(id: w.id!);
    } catch (e, st) {
      _reportActionFailed(e, st, 'testPost');
      messenger?.showSnackBar(
        SnackBar(content: Text(l.integrationsActionFailed)),
      );
      return;
    }
    messenger?.showSnackBar(
      SnackBar(content: Text(l.integrationsTestPostSent)),
    );
  }

  Future<void> _delete(IncomingWebhook w) async {
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.integrationsDeleteConfirmTitle),
        content: Text(l.integrationsDeleteConfirmBody),
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
            child: Text(l.integrationsDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _integrations.deleteWebhook(id: w.id!);
    } catch (e, st) {
      _reportActionFailed(e, st, 'deleteWebhook');
      messenger?.showSnackBar(
        SnackBar(content: Text(l.integrationsActionFailed)),
      );
      return;
    }
    if (!mounted) return;
    await _refresh();
  }

  /// Диалог ввода имени нового автопоста. Save disabled при trim-empty.
  Future<String?> _promptName(BuildContext context, NsgL10n l) {
    return showDialog<String?>(
      context: context,
      builder: (ctx) => _NamePromptDialog(l: l),
    );
  }

  /// Показать webhook-URL один раз (после создания/ротации) с кнопкой копир.
  Future<void> _showWebhookUrlDialog(String token) {
    final l = NsgL10n.of(context);
    final url = _webhookUrl(token);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.integrationsWebhookUrlLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CopyableField(value: url),
            const SizedBox(height: 8),
            Text(
              l.integrationsWebhookUrlOnce,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.commonOk),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // TASK59 — self-service бот-интеграции (секция «Боты»)
  // ───────────────────────────────────────────────────────────────────

  Future<void> _addBot() async {
    final l = NsgL10n.of(context);
    final result = await showDialog<_AddBotResult>(
      context: context,
      builder: (ctx) => _AddBotDialog(l: l),
    );
    if (result == null || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    BotIntegrationCreated created;
    try {
      created = await _integrations.createBotIntegration(
        roomId: widget.roomId,
        name: result.name,
        webhookUrl: result.webhookUrl,
      );
    } catch (e, st) {
      _reportActionFailed(e, st, 'createBotIntegration');
      messenger?.showSnackBar(
        SnackBar(content: Text(l.integrationsActionFailed)),
      );
      return;
    }
    if (!mounted) return;
    await _showBotCredentialsDialog(created);
    await _refreshBots();
  }

  Future<void> _rotateSecret(BotIntegrationView bot) async {
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    BotIntegrationCreated created;
    try {
      created = await _integrations.rotateWebhookSecret(botId: bot.botId);
    } catch (e, st) {
      _reportActionFailed(e, st, 'rotateWebhookSecret');
      messenger?.showSnackBar(
        SnackBar(content: Text(l.integrationsActionFailed)),
      );
      return;
    }
    if (!mounted) return;
    await _showBotCredentialsDialog(created);
    await _refreshBots();
  }

  Future<void> _toggleBotEnabled(BotIntegrationView bot) async {
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    // «Выключен», если выключен бот ИЛИ подписка → тумблер включает оба.
    final enable = !(bot.botEnabled && bot.subscriptionEnabled);
    try {
      await _integrations.setBotIntegrationEnabled(
        botId: bot.botId,
        enabled: enable,
      );
    } catch (e, st) {
      _reportActionFailed(e, st, 'setBotIntegrationEnabled');
      messenger?.showSnackBar(
        SnackBar(content: Text(l.integrationsActionFailed)),
      );
      return;
    }
    if (!mounted) return;
    await _refreshBots();
  }

  Future<void> _deleteBot(BotIntegrationView bot) async {
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.integrationsBotDeleteConfirmTitle),
        content: Text(l.integrationsBotDeleteConfirmBody),
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
            child: Text(l.integrationsDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _integrations.deleteBotIntegration(botId: bot.botId);
    } catch (e, st) {
      _reportActionFailed(e, st, 'deleteBotIntegration');
      messenger?.showSnackBar(
        SnackBar(content: Text(l.integrationsActionFailed)),
      );
      return;
    }
    if (!mounted) return;
    await _refreshBots();
  }

  /// Показать учётные данные бота ОДИН РАЗ (после создания/ротации): токен,
  /// секрет, apiBase, roomId, messengerUserId, события — каждое с кнопкой
  /// копирования. Скроллируемый диалог (несколько полей).
  Future<void> _showBotCredentialsDialog(BotIntegrationCreated created) {
    final l = NsgL10n.of(context);
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final caption = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        );
        return AlertDialog(
          title: Text(l.integrationsBotCredentialsTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.integrationsBotCredentialsOnce, style: caption),
                  const SizedBox(height: 12),
                  _CredField(
                    label: l.integrationsBotTokenLabel,
                    value: created.bot.accessToken,
                  ),
                  _CredField(
                    label: l.integrationsBotSecretLabel,
                    value: created.subscription.secret,
                  ),
                  _CredField(
                    label: l.integrationsApiBaseLabel,
                    value: created.apiBase,
                  ),
                  _CredField(
                    label: l.integrationsRoomIdLabel,
                    value: '${widget.roomId}',
                  ),
                  _CredField(
                    label: l.integrationsBotUserIdLabel,
                    value: '${created.bot.messengerUserId}',
                    caption: l.integrationsBotUserIdCaption,
                  ),
                  _CredField(
                    label: l.integrationsEventsLabel,
                    value: created.subscription.eventTypes,
                  ),
                  const SizedBox(height: 8),
                  Text(l.integrationsBotHandoffHint, style: caption),
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

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.integrationsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAutopost,
        icon: const Icon(Icons.add),
        label: Text(l.integrationsAddAutopost),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildAutopostsSection(context, l),
            const SizedBox(height: 8),
            _buildBotsSection(context, l),
          ],
        ),
      ),
    );
  }

  /// Заголовок секции (primary-цвет) + опциональный trailing-виджет (напр.
  /// кнопка «＋ Добавить бота»).
  Widget _sectionHeader(
    BuildContext context,
    String title, {
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
      child: Center(
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _sectionError(BuildContext context, NsgL10n l, Object error) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Text(l.integrationsLoadFailed),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutopostsSection(BuildContext context, NsgL10n l) {
    return FutureBuilder<List<IncomingWebhook>>(
      future: _webhooksFuture,
      builder: (context, snap) {
        Widget child;
        if (snap.connectionState == ConnectionState.waiting) {
          child = const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snap.hasError) {
          child = _sectionError(context, l, snap.error!);
        } else {
          final webhooks = snap.data ?? const <IncomingWebhook>[];
          child = webhooks.isEmpty
              ? _emptyState(context, l.integrationsEmpty)
              : Column(
                  children: [
                    for (final w in webhooks)
                      _WebhookTile(
                        webhook: w,
                        onRotate: () => _rotate(w),
                        onToggleEnabled: () => _toggleEnabled(w),
                        onTestPost: () => _testPost(w),
                        onDelete: () => _delete(w),
                      ),
                  ],
                );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(context, l.integrationsAutopostsSection),
            child,
          ],
        );
      },
    );
  }

  Widget _buildBotsSection(BuildContext context, NsgL10n l) {
    return FutureBuilder<List<BotIntegrationView>>(
      future: _botsFuture,
      builder: (context, snap) {
        Widget child;
        if (snap.connectionState == ConnectionState.waiting) {
          child = const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snap.hasError) {
          child = _sectionError(context, l, snap.error!);
        } else {
          final bots = snap.data ?? const <BotIntegrationView>[];
          child = bots.isEmpty
              ? _emptyState(context, l.integrationsBotsEmpty)
              : Column(
                  children: [
                    for (final b in bots)
                      _BotTile(
                        bot: b,
                        onRotateSecret: () => _rotateSecret(b),
                        onToggleEnabled: () => _toggleBotEnabled(b),
                        onDelete: () => _deleteBot(b),
                      ),
                  ],
                );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(
              context,
              l.integrationsBotsSection,
              trailing: TextButton.icon(
                onPressed: _addBot,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l.integrationsAddBot),
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}

/// Один webhook в списке: имя (+ бейдж «выключен»), подзаголовок «последний
/// пост …», ⋯-меню действий.
class _WebhookTile extends StatelessWidget {
  const _WebhookTile({
    required this.webhook,
    required this.onRotate,
    required this.onToggleEnabled,
    required this.onTestPost,
    required this.onDelete,
  });

  final IncomingWebhook webhook;
  final VoidCallback onRotate;
  final VoidCallback onToggleEnabled;
  final VoidCallback onTestPost;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final lastPosted = webhook.lastPostedAt;
    final subtitle = lastPosted == null
        ? l.integrationsNeverPosted
        : l.integrationsLastPost(
            formatRelativeTime(
              lastPosted.toLocal(),
              lang: lang,
              shortEn: false,
            ),
          );
    return ListTile(
      leading: Icon(
        Icons.webhook,
        color: webhook.enabled
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              webhook.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: webhook.enabled
                    ? null
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          if (!webhook.enabled) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l.integrationsDisabledBadge,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(subtitle),
      trailing: PopupMenuButton<_WebhookAction>(
        onSelected: (action) {
          switch (action) {
            case _WebhookAction.testPost:
              onTestPost();
            case _WebhookAction.rotate:
              onRotate();
            case _WebhookAction.toggleEnabled:
              onToggleEnabled();
            case _WebhookAction.delete:
              onDelete();
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: _WebhookAction.testPost,
            child: _menuRow(Icons.send_outlined, l.integrationsTestPost),
          ),
          PopupMenuItem(
            value: _WebhookAction.rotate,
            child: _menuRow(Icons.autorenew, l.integrationsRotateToken),
          ),
          PopupMenuItem(
            value: _WebhookAction.toggleEnabled,
            child: _menuRow(
              webhook.enabled
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              webhook.enabled ? l.integrationsDisable : l.integrationsEnable,
            ),
          ),
          PopupMenuItem(
            value: _WebhookAction.delete,
            child: _menuRow(
              Icons.delete_outline,
              l.integrationsDelete,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
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

enum _WebhookAction { testPost, rotate, toggleEnabled, delete }

/// Поле со значением + кнопка «Копировать» (clipboard + snackbar).
/// Паттерн copy-to-clipboard заимствован из `message_action_sheet.dart`.
/// [copiedMessage] — текст snackbar-а после копирования; по умолчанию
/// `integrationsCopied` («URL copied» — для webhook-URL). Секция «Боты»
/// передаёт `integrationsCopiedGeneric` («Copied» — токен/секрет/id).
class CopyableField extends StatelessWidget {
  const CopyableField({super.key, required this.value, this.copiedMessage});

  final String value;
  final String? copiedMessage;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              value,
              maxLines: 2,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
          IconButton(
            tooltip: l.integrationsCopy,
            icon: const Icon(Icons.copy_outlined, size: 20),
            onPressed: () async {
              final messenger = ScaffoldMessenger.maybeOf(context);
              await Clipboard.setData(ClipboardData(text: value));
              messenger?.showSnackBar(
                SnackBar(
                  content: Text(copiedMessage ?? l.integrationsCopied),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// TASK59: одно именованное поле учётных данных бота — label (+ опциональный
/// caption) над [CopyableField]. Snackbar показывает generic «Copied».
class _CredField extends StatelessWidget {
  const _CredField({required this.label, required this.value, this.caption});

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          CopyableField(value: value, copiedMessage: l.integrationsCopiedGeneric),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// TASK59: один бот в списке секции «Боты». Имя (+ бейдж «выключен», если бот
/// ИЛИ его подписка выключены), подзаголовок = webhook-URL + события,
/// ⋯-меню: пересоздать секрет / вкл-выкл / удалить.
class _BotTile extends StatelessWidget {
  const _BotTile({
    required this.bot,
    required this.onRotateSecret,
    required this.onToggleEnabled,
    required this.onDelete,
  });

  final BotIntegrationView bot;
  final VoidCallback onRotateSecret;
  final VoidCallback onToggleEnabled;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final active = bot.botEnabled && bot.subscriptionEnabled;
    return ListTile(
      isThreeLine: true,
      leading: Icon(
        Icons.smart_toy_outlined,
        color: active
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              bot.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active
                    ? null
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          if (!active) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l.integrationsDisabledBadge,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bot.webhookUrl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          Text(
            bot.eventTypes,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      trailing: PopupMenuButton<_BotAction>(
        onSelected: (action) {
          switch (action) {
            case _BotAction.rotateSecret:
              onRotateSecret();
            case _BotAction.toggleEnabled:
              onToggleEnabled();
            case _BotAction.delete:
              onDelete();
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: _BotAction.rotateSecret,
            child: _botMenuRow(Icons.autorenew, l.integrationsRotateSecret),
          ),
          PopupMenuItem(
            value: _BotAction.toggleEnabled,
            child: _botMenuRow(
              active
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              active ? l.integrationsDisable : l.integrationsEnable,
            ),
          ),
          PopupMenuItem(
            value: _BotAction.delete,
            child: _botMenuRow(
              Icons.delete_outline,
              l.integrationsDelete,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _botMenuRow(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: color == null ? null : TextStyle(color: color)),
      ],
    );
  }
}

enum _BotAction { rotateSecret, toggleEnabled, delete }

/// TASK59: результат диалога создания бота — имя + webhook-URL (оба
/// провалидированы: non-empty, URL начинается с https://).
class _AddBotResult {
  const _AddBotResult({required this.name, required this.webhookUrl});

  final String name;
  final String webhookUrl;
}

/// TASK59: диалог создания бот-интеграции — поле имени + поле webhook-URL.
/// «Создать» disabled, пока имя пустое или URL не начинается с https://.
class _AddBotDialog extends StatefulWidget {
  const _AddBotDialog({required this.l});

  final NsgL10n l;

  @override
  State<_AddBotDialog> createState() => _AddBotDialogState();
}

class _AddBotDialogState extends State<_AddBotDialog> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _urlCtl;
  bool _showUrlError = false;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController()..addListener(_sync);
    _urlCtl = TextEditingController()..addListener(_sync);
  }

  void _sync() => setState(() {});

  @override
  void dispose() {
    _nameCtl.removeListener(_sync);
    _urlCtl.removeListener(_sync);
    _nameCtl.dispose();
    _urlCtl.dispose();
    super.dispose();
  }

  bool get _nameValid => _nameCtl.text.trim().isNotEmpty;

  bool get _urlValid {
    final url = _urlCtl.text.trim();
    return url.startsWith('https://') && url.length > 'https://'.length;
  }

  void _submit() {
    if (!_nameValid || !_urlValid) {
      setState(() => _showUrlError = !_urlValid);
      return;
    }
    Navigator.of(context).pop(
      _AddBotResult(
        name: _nameCtl.text.trim(),
        webhookUrl: _urlCtl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return AlertDialog(
      title: Text(l.integrationsAddBot),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtl,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l.integrationsNameLabel,
                hintText: l.integrationsBotNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlCtl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l.integrationsBotWebhookUrlLabel,
                hintText: l.integrationsBotWebhookUrlHint,
                border: const OutlineInputBorder(),
                errorText: _showUrlError && !_urlValid
                    ? l.integrationsBotWebhookUrlInvalid
                    : null,
              ),
              onSubmitted: (_) => _submit(),
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
          onPressed: _nameValid && _urlValid ? _submit : null,
          child: Text(l.integrationsCreate),
        ),
      ],
    );
  }
}

/// Диалог ввода имени нового автопоста. Кнопка «Создать» disabled при
/// trim-empty (server-side тоже валидирует).
class _NamePromptDialog extends StatefulWidget {
  const _NamePromptDialog({required this.l});

  final NsgL10n l;

  @override
  State<_NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<_NamePromptDialog> {
  late final TextEditingController _ctl;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController();
    _ctl.addListener(_sync);
  }

  void _sync() {
    final has = _ctl.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    _ctl.removeListener(_sync);
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return AlertDialog(
      title: Text(l.integrationsAddAutopost),
      content: TextField(
        controller: _ctl,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l.integrationsNameLabel,
          hintText: l.integrationsNameHint,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: _hasText
            ? (_) => Navigator.of(context).pop(_ctl.text.trim())
            : null,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: _hasText
              ? () => Navigator.of(context).pop(_ctl.text.trim())
              : null,
          child: Text(l.integrationsCreate),
        ),
      ],
    );
  }
}
