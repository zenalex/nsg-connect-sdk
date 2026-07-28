import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../admin/nsg_messenger_platform_admin.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../utils/relative_time.dart';
import 'integrations_screen.dart' show CopyableField;

/// **TASK78 п.3 (админка секретов тенантов)**: экран платформенного
/// управления issued-token-режимом tenant-ов — то, что раньше делалось
/// SQL-ом + env + рестартом прода.
///
/// Виден только тем, чей email в серверном `PLATFORM_ADMIN_EMAILS`:
/// хост-приложение прячет вход по `NsgMessenger.platformAdmin
/// .isPlatformAdmin()`, но это лишь UX — авторизацию решает сервер на
/// каждом методе.
///
/// Состав: список тенантов со статусами (включён/выключен, секрет задан,
/// grace-окно прежнего секрета) + ⋯-меню:
///   * **Включить и сгенерировать секрет** / **Ротировать секрет** (диалог
///     grace в минутах) — результат-секрет `cst_…` показывается РОВНО ОДИН
///     РАЗ (сервер хранит только sha256), диалог не закрывается тапом мимо;
///   * **Выключить** — kill-switch с confirm (обнуляет ОБА хэша, продукт
///     сразу теряет доступ);
///   * **Журнал** — аудит операций с ключами (ConnectKeyAuditEvent).
///
/// Секрет живёт только в локальной переменной на время показа диалога —
/// в состояние экрана и в логи не попадает.
class PlatformAdminScreen extends StatefulWidget {
  const PlatformAdminScreen({
    super.key,
    @visibleForTesting this.adminOverride,
  });

  /// Visible-for-testing — позволяет widget-тестам подменить
  /// `MessengerRuntime.instance.platformAdmin` на in-memory fake.
  final NsgMessengerPlatformAdmin? adminOverride;

  @override
  State<PlatformAdminScreen> createState() => _PlatformAdminScreenState();
}

class _PlatformAdminScreenState extends State<PlatformAdminScreen> {
  late final NsgMessengerPlatformAdmin _admin;
  late Future<List<ConnectTenantStatus>> _tenantsFuture;

  /// Продукты по ключу тенанта. Грузим ЛЕНИВО, при раскрытии узла:
  /// тенантов может быть много, а состав продуктов нужен не у каждого.
  final Map<String, List<ProductAdminView>> _products = {};
  final Set<String> _productsLoading = {};

  Future<void> _loadProducts(String tenantKey) async {
    if (_productsLoading.contains(tenantKey)) return;
    _productsLoading.add(tenantKey);
    final list = await _admin.listProducts(tenantExternalKey: tenantKey);
    _productsLoading.remove(tenantKey);
    if (!mounted) return;
    setState(() => _products[tenantKey] = list);
  }

  @override
  void initState() {
    super.initState();
    _admin = widget.adminOverride ?? MessengerRuntime.instance.platformAdmin;
    _tenantsFuture = _admin.listTenants();
  }

  Future<void> _refresh() async {
    setState(() {
      _tenantsFuture = _admin.listTenants();
    });
    await _tenantsFuture;
  }

  /// Ключ tenant-а для RPC. Nullable в DTO только ради обратной
  /// совместимости wire-формата — сервер этого экрана его всегда шлёт.
  String _keyOf(ConnectTenantStatus t) => t.tenantExternalKey ?? '';

  Future<void> _enableAndGenerate(ConnectTenantStatus t) async {
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final String secret;
    try {
      secret = await _admin.enableAndGenerate(tenantExternalKey: _keyOf(t));
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l.platformAdminActionFailed)),
      );
      return;
    }
    if (!mounted) return;
    await _showSecretDialog(secret);
    await _refresh();
  }

  Future<void> _rotate(ConnectTenantStatus t) async {
    final l = NsgL10n.of(context);
    final graceMinutes = await showDialog<int>(
      context: context,
      builder: (ctx) => _RotateDialog(l: l),
    );
    if (graceMinutes == null || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final String secret;
    try {
      secret = await _admin.rotateSecret(
        tenantExternalKey: _keyOf(t),
        graceMinutes: graceMinutes,
      );
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l.platformAdminActionFailed)),
      );
      return;
    }
    if (!mounted) return;
    await _showSecretDialog(secret);
    await _refresh();
  }

  /// Одноразовый показ секрета. `barrierDismissible: false` — случайный
  /// тап мимо диалога терял бы секрет безвозвратно (повторно сервер его
  /// не отдаст); закрыть можно только явной кнопкой.
  Future<void> _showSecretDialog(String secret) {
    final l = NsgL10n.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: Text(l.platformAdminSecretTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CopyableField(
                  value: secret,
                  copiedMessage: l.integrationsCopiedGeneric,
                ),
                const SizedBox(height: 8),
                Text(
                  l.platformAdminSecretOnce,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
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

  /// Форма «ключ + название». Общая для тенанта и продукта: поля те же,
  /// различается только заголовок и что делаем с результатом.
  ///
  /// Контроллеры полей принадлежат САМОМУ диалогу ([_KeyNameDialog]), а не
  /// этому методу: освобождать их сразу после `await showDialog` нельзя —
  /// маршрут в этот момент ещё анимируется прочь и продолжает строить свои
  /// поля («Tried to build dirty widget in the wrong build scope»).
  Future<({String key, String name})?> _askKeyAndName(String title) async {
    final result = await showDialog<({String key, String name})>(
      context: context,
      builder: (ctx) => _KeyNameDialog(title: title),
    );
    if (result == null || result.key.isEmpty || result.name.isEmpty) {
      return null;
    }
    return result;
  }

  /// Завести команду поддержки продукта, назначив владельца по email.
  ///
  /// Владелец — обязательно человек, который УЖЕ входил в мессенджер:
  /// email резолвится в существующего пользователя (с фолбэком в тенант
  /// операторов `nsg`), а не заводит учётку. Поэтому отказ «email не
  /// резолвится» — отдельный текст: это не опечатка в форме, а «человек
  /// ещё ни разу не заходил».
  Future<void> _provisionSupportTeam(
    String tenantKey,
    ProductAdminView product,
  ) async {
    final l = NsgL10n.of(context);
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => _OwnerEmailDialog(product: product),
    );
    if (email == null || email.isEmpty || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _admin.provisionSupportTeam(
        tenantExternalKey: tenantKey,
        productExternalKey: product.externalKey,
        ownerEmail: email,
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            e is OperatorEmailNotResolvedException
                ? l.platformAdminOwnerNotFound(e.email)
                : l.platformAdminActionFailed,
          ),
        ),
      );
      return;
    }
    messenger?.showSnackBar(SnackBar(content: Text(l.platformAdminCreated)));
    _products.remove(tenantKey);
    await _loadProducts(tenantKey);
  }

  Future<void> _createTenant() async {
    final l = NsgL10n.of(context);
    final input = await _askKeyAndName(l.platformAdminCreateTenant);
    if (input == null || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _admin.createTenant(externalKey: input.key, name: input.name);
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(_createError(l, e))));
      return;
    }
    messenger?.showSnackBar(SnackBar(content: Text(l.platformAdminCreated)));
    await _refresh();
  }

  Future<void> _createProduct() async {
    final l = NsgL10n.of(context);
    // Продукт живёт ВНУТРИ тенанта, поэтому сначала спрашиваем, в каком.
    final tenants = await _tenantsFuture;
    if (!mounted) return;
    final tenantKey = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.platformAdminCreateProduct),
        children: [
          for (final t in tenants)
            if (t.tenantExternalKey != null)
              SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(t.tenantExternalKey),
                child: Text(
                  '${t.tenantName ?? ''} (${t.tenantExternalKey})'.trim(),
                ),
              ),
        ],
      ),
    );
    if (tenantKey == null || !mounted) return;
    final input = await _askKeyAndName(l.platformAdminCreateProduct);
    if (input == null || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _admin.createProduct(
        tenantExternalKey: tenantKey,
        externalKey: input.key,
        displayName: input.name,
      );
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(_createError(l, e))));
      return;
    }
    messenger?.showSnackBar(SnackBar(content: Text(l.platformAdminCreated)));
  }

  /// Строки продуктов тенанта в раскрытом узле.
  List<Widget> _productRows(String tenantKey) {
    final l = NsgL10n.of(context);
    final list = _products[tenantKey];
    if (list == null) {
      return const [
        Padding(
          padding: EdgeInsets.all(12),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ];
    }
    if (list.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            l.platformAdminNoProducts,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ];
    }
    return [
      for (final p in list)
        ListTile(
          dense: true,
          leading: const Icon(Icons.widgets_outlined, size: 20),
          title: Text('${p.displayName} (${p.externalKey})'),
          subtitle: Text(
            p.hasSupportTeam
                ? l.platformAdminSupportTeamSize(p.supportTeamSize)
                : l.platformAdminNoSupportTeam,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: TextButton(
            onPressed: () => _provisionSupportTeam(tenantKey, p),
            child: Text(
              p.hasSupportTeam
                  ? l.platformAdminSetOwner
                  : l.platformAdminCreateSupportTeam,
            ),
          ),
        ),
    ];
  }

  /// Причина отказа словами: «ключ не годится» и «занято» — разные
  /// проблемы, и делать с ними надо разное.
  String _createError(NsgL10n l, Object e) {
    if (e is InvalidExternalKeyException) return l.platformAdminKeyInvalid;
    if (e is TenantAlreadyExistsException ||
        e is ProductAlreadyExistsException) {
      return l.platformAdminAlreadyExists;
    }
    return l.platformAdminActionFailed;
  }

  Future<void> _disable(ConnectTenantStatus t) async {
    final l = NsgL10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.platformAdminDisableConfirmTitle),
        content: Text(l.platformAdminDisableConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.platformAdminDisable),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _admin.disable(tenantExternalKey: _keyOf(t));
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l.platformAdminActionFailed)),
      );
      return;
    }
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _showAudit(ConnectTenantStatus t) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TenantAuditSheet(
        tenantName: t.tenantName ?? _keyOf(t),
        loader: () => _admin.listAuditEvents(tenantExternalKey: _keyOf(t)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.platformAdminTitle),
        actions: [
          // Провижн из UI. Раньше tenant и продукт заводились ТОЛЬКО
          // SQL-ом на проде, а этот экран умел лишь включать issued-token
          // у уже существующего тенанта — подключить новый продукт без
          // доступа к прод-базе было нечем.
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            onSelected: (v) => v == 'tenant'
                ? _createTenant()
                : _createProduct(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'tenant',
                child: Text(l.platformAdminCreateTenant),
              ),
              PopupMenuItem(
                value: 'product',
                child: Text(l.platformAdminCreateProduct),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ConnectTenantStatus>>(
          future: _tenantsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Ошибок здесь не бывает: listTenants деградирует любой сбой
            // в пустой список (см. NsgMessengerPlatformAdmin.listTenants),
            // поэтому empty-state объясняет и «нет тенантов», и «нет
            // доступа/старый сервер».
            final tenants = snap.data ?? const <ConnectTenantStatus>[];
            if (tenants.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                    child: Center(
                      child: Text(
                        l.platformAdminEmpty,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: tenants.length,
              itemBuilder: (context, i) {
                final key = _keyOf(tenants[i]);
                return _TenantTile(
                  status: tenants[i],
                  onEnableGenerate: () => _enableAndGenerate(tenants[i]),
                  onRotate: () => _rotate(tenants[i]),
                  onDisable: () => _disable(tenants[i]),
                  onShowAudit: () => _showAudit(tenants[i]),
                  onExpansionChanged: (open) {
                    if (open && !_products.containsKey(key)) {
                      _loadProducts(key);
                    }
                  },
                  products: _productRows(key),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Один tenant в списке: имя (+ externalKey), строка статуса (включён /
/// секрет / grace), ⋯-меню действий. Секрет здесь не показывается никогда
/// — он виден только в момент выдачи.
class _TenantTile extends StatelessWidget {
  const _TenantTile({
    required this.status,
    required this.onEnableGenerate,
    required this.onRotate,
    required this.onDisable,
    required this.onShowAudit,
    required this.products,
    required this.onExpansionChanged,
  });

  /// Содержимое раскрытого узла: продукты тенанта (или заглушка).
  final List<Widget> products;

  /// Раскрытие грузит продукты лениво: тенантов может быть много, а
  /// список продуктов нужен не для каждого.
  final ValueChanged<bool> onExpansionChanged;

  final ConnectTenantStatus status;
  final VoidCallback onEnableGenerate;
  final VoidCallback onRotate;
  final VoidCallback onDisable;
  final VoidCallback onShowAudit;

  /// «до 21.07 14:05» — локальное время окончания grace. Абсолютное, не
  /// относительное: админ сверяет его с дедлайном выкатки конфига продукта.
  static String _formatUntil(DateTime utc) {
    final d = utc.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final dimmed = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final enabled = status.enabled;
    final graceUntil = status.graceActiveUntil;
    final name = status.tenantName ?? status.tenantExternalKey ?? '?';

    final statusLine = [
      enabled ? l.platformAdminStatusEnabled : l.platformAdminStatusDisabled,
      status.hasSecret ? l.platformAdminSecretSet : l.platformAdminSecretMissing,
    ].join(' · ');

    // Дерево «тенант → продукт → команда поддержки»: продукты раньше не
    // показывались ВООБЩЕ — завести можно было, увидеть нет, и понять,
    // у какого продукта есть поддержка, было негде.
    return ExpansionTile(
      onExpansionChanged: onExpansionChanged,
      childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        enabled ? Icons.vpn_key_outlined : Icons.key_off_outlined,
        color: enabled
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(
            status.tenantExternalKey ?? '',
            style: theme.textTheme.labelSmall?.copyWith(
              color: dimmed,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(statusLine, style: theme.textTheme.bodySmall),
          if (graceUntil != null)
            Text(
              l.platformAdminGraceUntil(_formatUntil(graceUntil)),
              style: theme.textTheme.bodySmall?.copyWith(color: dimmed),
            ),
        ],
      ),
      trailing: PopupMenuButton<_TenantAction>(
        onSelected: (action) {
          switch (action) {
            case _TenantAction.enableGenerate:
              onEnableGenerate();
            case _TenantAction.rotate:
              onRotate();
            case _TenantAction.disable:
              onDisable();
            case _TenantAction.audit:
              onShowAudit();
          }
        },
        itemBuilder: (ctx) => [
          // Включённому tenant-у с секретом предлагаем ротацию, а не
          // повторное «включить» (сервер и так превратил бы его в
          // ротацию — но меню не должно врать о том, что произойдёт).
          if (enabled && status.hasSecret)
            PopupMenuItem(
              value: _TenantAction.rotate,
              child: _menuRow(Icons.autorenew, l.platformAdminRotate),
            )
          else
            PopupMenuItem(
              value: _TenantAction.enableGenerate,
              child: _menuRow(
                Icons.vpn_key_outlined,
                l.platformAdminEnableGenerate,
              ),
            ),
          if (enabled)
            PopupMenuItem(
              value: _TenantAction.disable,
              child: _menuRow(Icons.key_off_outlined, l.platformAdminDisable),
            ),
          PopupMenuItem(
            value: _TenantAction.audit,
            child: _menuRow(Icons.history, l.platformAdminAudit),
          ),
        ],
      ),
      children: products,
    );
  }

  Widget _menuRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        // Flexible: «Включить и сгенерировать секрет» длиннее ширины
        // попап-меню — без него Row переполняется.
        Flexible(child: Text(label)),
      ],
    );
  }
}

enum _TenantAction { enableGenerate, rotate, disable, audit }

/// Диалог ротации: grace-период в минутах (дефолт 5, максимум 1440 —
/// сервер всё равно обрежет, клиентская проверка только гасит опечатки).
/// Возвращает выбранные минуты либо null (отмена).
class _RotateDialog extends StatefulWidget {
  const _RotateDialog({required this.l});

  final NsgL10n l;

  @override
  State<_RotateDialog> createState() => _RotateDialogState();
}

class _RotateDialogState extends State<_RotateDialog> {
  final TextEditingController _graceCtl = TextEditingController(
    text: '${NsgMessengerPlatformAdmin.kDefaultGraceMinutes}',
  );

  @override
  void initState() {
    super.initState();
    _graceCtl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _graceCtl.dispose();
    super.dispose();
  }

  int? get _minutes {
    final v = int.tryParse(_graceCtl.text.trim());
    if (v == null ||
        v < 0 ||
        v > NsgMessengerPlatformAdmin.kMaxGraceMinutes) {
      return null;
    }
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final minutes = _minutes;
    return AlertDialog(
      title: Text(l.platformAdminRotateTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.platformAdminRotateBody),
          const SizedBox(height: 12),
          TextField(
            controller: _graceCtl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l.platformAdminGraceLabel(
                NsgMessengerPlatformAdmin.kMaxGraceMinutes,
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: minutes == null
              ? null
              : () => Navigator.of(context).pop(minutes),
          child: Text(l.platformAdminRotate),
        ),
      ],
    );
  }
}

/// Журнал операций с ключами tenant-а: кто включил/ротировал/отзывал и
/// когда. Read-only; секретов не содержит по контракту сервера.
class _TenantAuditSheet extends StatefulWidget {
  const _TenantAuditSheet({required this.tenantName, required this.loader});

  final String tenantName;
  final Future<List<ConnectKeyAuditEvent>> Function() loader;

  @override
  State<_TenantAuditSheet> createState() => _TenantAuditSheetState();
}

class _TenantAuditSheetState extends State<_TenantAuditSheet> {
  late final Future<List<ConnectKeyAuditEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  /// Человекочитаемое название действия. Неизвестное (журнал новее
  /// клиента) показываем как есть — лучше сырой `action`, чем пустота.
  String _actionLabel(NsgL10n l, String action) => switch (action) {
    'enabled_and_generated' => l.platformAdminAuditEnabledGenerated,
    'secret_rotated' => l.platformAdminAuditRotated,
    'disabled' => l.platformAdminAuditDisabled,
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
                l.platformAdminAuditTitle(widget.tenantName),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: FutureBuilder<List<ConnectKeyAuditEvent>>(
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
                      child: Center(child: Text(l.platformAdminActionFailed)),
                    );
                  }
                  final events = snap.data ?? const <ConnectKeyAuditEvent>[];
                  if (events.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(l.platformAdminAuditEmpty)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: events.length,
                    itemBuilder: (context, i) {
                      final e = events[i];
                      // Инициатор без email — платформа/скрипт (например,
                      // включение миграционным сидером), не человек.
                      final actor = e.actorEmail ?? l.botsAdminAuditActorSystem;
                      final when = formatRelativeTime(
                        e.createdAt.toLocal(),
                        lang: lang,
                        shortEn: false,
                      );
                      final killSwitch = e.action == 'disabled';
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          killSwitch
                              ? Icons.key_off_outlined
                              : Icons.vpn_key_outlined,
                          size: 20,
                          color: killSwitch
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


/// Диалог «ключ + название» для провижна tenant-а/продукта.
///
/// Отдельный StatefulWidget именно ради владения контроллерами: они живут
/// ровно столько, сколько живёт маршрут диалога.
class _KeyNameDialog extends StatefulWidget {
  const _KeyNameDialog({required this.title});

  final String title;

  @override
  State<_KeyNameDialog> createState() => _KeyNameDialogState();
}

class _KeyNameDialogState extends State<_KeyNameDialog> {
  final _key = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _key.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _key,
            autofocus: true,
            decoration: InputDecoration(labelText: l.platformAdminKeyLabel),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l.platformAdminNameLabel),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            (key: _key.text.trim(), name: _name.text.trim()),
          ),
          child: Text(l.platformAdminCreateAction),
        ),
      ],
    );
  }
}


/// Диалог «email владельца команды поддержки».
///
/// Контроллер принадлежит диалогу — см. [_KeyNameDialog] о том, почему
/// освобождать его сразу после `await showDialog` нельзя.
class _OwnerEmailDialog extends StatefulWidget {
  const _OwnerEmailDialog({required this.product});

  final ProductAdminView product;

  @override
  State<_OwnerEmailDialog> createState() => _OwnerEmailDialogState();
}

class _OwnerEmailDialogState extends State<_OwnerEmailDialog> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return AlertDialog(
      title: Text(
        widget.product.hasSupportTeam
            ? l.platformAdminSetOwner
            : l.platformAdminCreateSupportTeam,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.product.displayName} (${widget.product.externalKey})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _email,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l.platformAdminOwnerEmailLabel,
              helperText: l.platformAdminOwnerEmailHint,
              helperMaxLines: 3,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_email.text.trim()),
          child: Text(l.platformAdminCreateAction),
        ),
      ],
    );
  }
}
