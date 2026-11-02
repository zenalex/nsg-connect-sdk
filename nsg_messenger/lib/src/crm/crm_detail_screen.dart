import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../messages/send_error_classifier.dart';
import '../nsg_messenger.dart';
import 'crm_controller.dart';
import 'crm_components.dart';
import 'crm_forms.dart';
import 'crm_format.dart';
import 'crm_rpc.dart';
import 'crm_screen.dart';
import 'crm_state.dart';

class CrmDealScreen extends StatefulWidget {
  const CrmDealScreen({
    super.key,
    required this.id,
    required this.rpc,
    this.space,
    this.controller,
  });
  final int id;
  final CrmRpc rpc;
  final CrmSpaceInfo? space;
  final CrmController? controller;
  @override
  State<CrmDealScreen> createState() => _CrmDealScreenState();
}

class _CrmDealScreenState extends State<CrmDealScreen> {
  CrmSpaceInfo? _space;
  CrmController? _ownController;
  CrmDealView? _deal;
  List<CrmPipelineInfo> _pipelines = [];
  bool _failed = false;
  bool _denied = false;
  bool _offline = false;
  bool _allActivities = false;
  @override
  void initState() {
    super.initState();
    _space = widget.space;
    unawaited(_load());
  }

  Future<void> _load() async {
    final cache = MessengerRuntime.instance.offlineCache;
    try {
      final deal = await widget.rpc.deal(widget.id);
      final pipelines = await widget.rpc.pipelines(deal.spaceId);
      _space ??= (await widget.rpc.context())
          .where((s) => s.id == deal.spaceId)
          .firstOrNull;
      _ensureController(deal);
      if (!mounted) return;
      setState(() {
        _deal = deal;
        _pipelines = pipelines;
        _failed = false;
        _offline = false;
      });
      await cache?.putCrm('deal:${widget.id}', jsonEncode(crmCacheDeal(deal)));
    } catch (e) {
      if (e is CrmAccessDenied) await cache?.removeCrm('deal:${widget.id}');
      if (isTransientSendError(e)) {
        final saved = await cache?.getCrm('deal:${widget.id}');
        if (saved != null && mounted) {
          try {
            final deal = CrmDealView.fromJson(
              jsonDecode(saved) as Map<String, dynamic>,
            );
            _space ??= (await widget.rpc.context())
                .where((s) => s.id == deal.spaceId)
                .firstOrNull;
            _ensureController(deal);
            if (!mounted) return;
            setState(() {
              _deal = deal;
              _offline = true;
              _failed = false;
            });
            return;
          } catch (_) {
            await cache?.removeCrm('deal:${widget.id}');
          }
        }
      }
      if (mounted) {
        setState(() {
          _deal = null;
          _failed = true;
          _denied = e is CrmAccessDenied;
        });
      }
    }
  }

  void _ensureController(CrmDealView deal) {
    if (widget.controller != null || _ownController != null) return;
    final rt = MessengerRuntime.instance;
    var userId = deal.ownerUserId;
    try {
      userId = rt.session.messengerUserId;
    } catch (_) {
      /* Injected endpoint tests. */
    }
    _ownController = CrmController(
      rpc: widget.rpc,
      spaceId: deal.spaceId,
      userId: userId,
      cache: rt.offlineCache,
      outbox: rt.outbox,
    );
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final deal = _deal;
    final pipeline = _pipelines
        .where((p) => p.id == deal?.pipelineId)
        .firstOrNull;
    final stage = pipeline?.stages
        .where((s) => s.id == deal?.stageId)
        .firstOrNull;
    final writable =
        _space?.isAdmin == true ||
        (_space?.segments
                .where((s) => s.id == deal?.segmentId)
                .firstOrNull
                ?.canWrite ??
            false);
    final controller = widget.controller ?? _ownController;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _failed
            ? CrmError(denied: _denied, retry: _load)
            : deal == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CrmCircleButton(
                        icon: Icons.chevron_left,
                        label: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      CrmPill(
                        onPressed: () async {
                          try {
                            final roomId = await widget.rpc.call(
                              () => widget.rpc.endpoint.getOrCreateDealRoom(
                                deal.id,
                              ),
                            );
                            if (context.mounted) {
                              await NsgMessenger.openRoom(context, roomId);
                            }
                          } catch (e) {
                            if (context.mounted) crmShowError(context, e);
                          }
                        },
                        child: Text(l.crmDealChat),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_offline) Text(l.crmOffline),
                  if (deal.company != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CrmCompanyScreen(
                              id: deal.company!.id,
                              rpc: widget.rpc,
                              space: _space,
                            ),
                          ),
                        ),
                        child: Text(
                          [
                            deal.company!.name,
                            ?deal.company!.region,
                          ].join(' · '),
                        ),
                      ),
                    ),
                  Text(
                    deal.title,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${l.crmAmount} '),
                        TextSpan(
                          text: crmMoney(context, deal.amount, deal.currency),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' · ${l.crmLead} '),
                        TextSpan(
                          text: deal.ownerDisplayName ?? '—',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CrmPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${l.crmStage} · ${pipeline?.name ?? '—'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              l.crmStageAge(
                                DateTime.now()
                                    .difference(deal.stageChangedAt)
                                    .inDays
                                    .clamp(0, 99999),
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (pipeline != null)
                          CrmStageBar(
                            count: pipeline.stages.length,
                            current: pipeline.stages.indexWhere(
                              (s) => s.id == deal.stageId,
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stage?.name ?? '—',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (writable && pipeline != null)
                              CrmPill(
                                height: 36,
                                onPressed: () async {
                                  final selected =
                                      await crmDialog<CrmStageInfo>(
                                        context: context,
                                        builder: (ctx) => SimpleDialog(
                                          backgroundColor: crmDialogSurface(
                                            ctx,
                                          ),
                                          title: Text(l.crmChangeStage),
                                          children: [
                                            for (final s in pipeline.stages)
                                              SimpleDialogOption(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, s),
                                                child: Text(s.name),
                                              ),
                                          ],
                                        ),
                                      );
                                  if (selected != null && context.mounted) {
                                    await crmMoveStage(
                                      context,
                                      widget.rpc,
                                      deal,
                                      selected,
                                      refresh: _load,
                                    );
                                  }
                                },
                                child: Text(l.crmChangeStage),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  CrmPanel(
                    emphasis: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CrmSectionHeader(
                          l.crmNextStep,
                          trailing: Flexible(
                            fit: FlexFit.tight,
                            child: Text(
                              deal.nextStepAt == null
                                  ? l.crmPending
                                  : crmDate(
                                      context,
                                      deal.nextStepAt!,
                                      due: true,
                                    ),
                              textAlign: TextAlign.right,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          deal.nextStep ?? l.crmPending,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${l.crmAssignee} — ${deal.nextStepAssigneeDisplayName ?? deal.ownerDisplayName ?? '—'}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        if (writable)
                          Row(
                            spacing: 8,
                            children: [
                              Expanded(
                                child: CrmPill(
                                  inverse: true,
                                  stretch: true,
                                  height: 44,
                                  padding: 8,
                                  tone: CrmPillTone.dark,
                                  onPressed: controller == null
                                      ? null
                                      : () async {
                                          await crmQuickActivity(
                                            context,
                                            controller,
                                            deal,
                                            agentRoomId: _space?.agentRoomId,
                                          );
                                          await _load();
                                        },
                                  child: Text(l.crmDone),
                                ),
                              ),
                              Expanded(
                                child: CrmPill(
                                  inverse: true,
                                  stretch: true,
                                  height: 44,
                                  padding: 8,
                                  tone: CrmPillTone.outline,
                                  onPressed: () => crmReschedule(
                                    context,
                                    widget.rpc,
                                    deal,
                                    refresh: _load,
                                  ),
                                  child: Text(l.crmReschedule),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  CrmPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CrmSectionHeader('Futbolista', uppercase: false),
                        Row(
                          children: [
                            for (final label in [
                              l.crmTournaments,
                              l.crmMatches,
                              l.crmPlayers,
                            ])
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '—',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      label,
                                      style: const TextStyle(fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l.crmAggregatesOnly,
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  CrmPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CrmSectionHeader(
                          '${l.crmContacts} · ${deal.contacts.length}',
                          uppercase: false,
                        ),
                        for (final contact in deal.contacts)
                          CrmContactTile(contact: contact),
                      ],
                    ),
                  ),
                  CrmPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CrmSectionHeader(
                          l.crmActivities,
                          uppercase: false,
                          trailing: CrmPill(
                            height: 34,
                            onPressed: !writable || controller == null
                                ? null
                                : () async {
                                    await crmQuickActivity(
                                      context,
                                      controller,
                                      deal,
                                      agentRoomId: _space?.agentRoomId,
                                    );
                                    await _load();
                                  },
                            child: Text('+ ${l.crmActivity}'),
                          ),
                        ),
                        for (final activity
                            in (_allActivities
                                ? crmRecentActivities(deal.activities)
                                : crmRecentActivities(deal.activities).take(5)))
                          CrmActivityRow(activity: activity),
                      ],
                    ),
                  ),
                  if (deal.activities.length > 5 && !_allActivities)
                    TextButton(
                      onPressed: () => setState(() => _allActivities = true),
                      child: Text(l.crmAll),
                    ),
                  CrmPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CrmSectionHeader(
                          '${l.crmDocuments} · ${deal.documents.length}',
                          uppercase: false,
                        ),
                        for (final document in deal.documents)
                          CrmDocumentTile(document: document, rpc: widget.rpc),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class CrmDocumentTile extends StatefulWidget {
  const CrmDocumentTile({super.key, required this.document, required this.rpc});
  final CrmDocumentView document;
  final CrmRpc rpc;
  @override
  State<CrmDocumentTile> createState() => _CrmDocumentTileState();
}

class _CrmDocumentTileState extends State<CrmDocumentTile> {
  bool _opening = false;
  Future<String?>? _thumbnail;
  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(CrmDocumentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.mxcUrl != widget.document.mxcUrl ||
        oldWidget.rpc != widget.rpc) {
      _loadThumbnail();
    }
  }

  void _loadThumbnail() {
    final d = widget.document;
    _thumbnail = d.mxcUrl != null && (d.mimeType?.startsWith('image/') ?? false)
        ? _preview(d.mxcUrl!)
        : null;
  }

  Future<String?> _preview(String mxcUrl) async {
    try {
      return (await widget.rpc.attachmentUrl(mxcUrl, thumbnail: true)).url;
    } catch (_) {
      return null;
    }
  }

  Future<void> _open() async {
    setState(() => _opening = true);
    try {
      final document = widget.document;
      final url =
          document.url ??
          (await widget.rpc.attachmentUrl(document.mxcUrl!)).url;
      if (mounted && crmWebUri(url) != null) await launchUrl(crmWebUri(url)!);
    } catch (e) {
      if (mounted) crmShowError(context, e);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.document;
    return CrmFlatRow(
      leading: _thumbnail == null
          ? const Icon(Icons.description_outlined)
          : FutureBuilder<String?>(
              future: _thumbnail,
              builder: (context, snapshot) => snapshot.data == null
                  ? const Icon(Icons.image_outlined)
                  : Image.network(
                      snapshot.data!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) =>
                          const Icon(Icons.image_outlined),
                    ),
            ),
      title: Text(d.title),
      subtitle: d.originalFilename != null
          ? Text(d.originalFilename!)
          : d.url == null
          ? null
          : SelectableText(d.url!),
      trailing: IconButton(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),

        tooltip: NsgL10n.of(context).crmOpenDocument,
        onPressed: _opening || (crmWebUri(d.url) == null && d.mxcUrl == null)
            ? null
            : _open,
        icon: _opening
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.open_in_new),
      ),
      onTap: _opening || (crmWebUri(d.url) == null && d.mxcUrl == null)
          ? null
          : _open,
    );
  }
}

class CrmActivityRow extends StatelessWidget {
  const CrmActivityRow({super.key, required this.activity});
  final CrmActivityView activity;
  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context), c = Theme.of(context).colorScheme;
    final type = crmActivityType(l, activity.type);
    final by = [
      activity.onBehalfOfDisplayName ?? activity.authorDisplayName ?? '—',
      if (activity.actorKind == CrmActorKind.agent) l.crmThroughAgent,
    ].join(' · ');
    return CrmFlatRow(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        child: Text(
          type.characters.first,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              type,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            crmDate(context, activity.occurredAt),
            style: TextStyle(fontSize: 11.5, color: c.onSurfaceVariant),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activity.summary,
            style: const TextStyle(fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 3),
          Text(by, style: TextStyle(fontSize: 11.5, color: c.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class CrmContactTile extends StatelessWidget {
  const CrmContactTile({
    super.key,
    required this.contact,
    this.company = false,
  });
  final bool company;
  final CrmContactView contact;
  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    if (contact.pdRedacted) return CrmFlatRow(title: Text(l.crmPdHidden));
    return CrmFlatRow(
      title: Text(contact.fullName ?? '—'),
      subtitle: Text(
        [
          if (contact.position != null) contact.position!,
          if (company && contact.phone != null) l.crmPhonePresent,
          if (company && contact.email != null) l.crmEmailPresent,
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (contact.phone != null)
            CrmCircleButton(
              label: l.crmCall,
              icon: Icons.call,
              onPressed: () =>
                  launchUrl(Uri(scheme: 'tel', path: contact.phone)),
            ),
          if (contact.email != null)
            CrmCircleButton(
              label: l.crmMessage,
              icon: Icons.mail_outline,
              onPressed: () =>
                  launchUrl(Uri(scheme: 'mailto', path: contact.email)),
            ),
        ],
      ),
    );
  }
}

class CrmCompanyScreen extends StatefulWidget {
  const CrmCompanyScreen({
    super.key,
    required this.id,
    required this.rpc,
    this.space,
  });
  final int id;
  final CrmRpc rpc;
  final CrmSpaceInfo? space;
  @override
  State<CrmCompanyScreen> createState() => _CrmCompanyScreenState();
}

class _CrmCompanyScreenState extends State<CrmCompanyScreen> {
  CrmSpaceInfo? _space;
  CrmCompanyDetails? _details;
  bool _offline = false;
  bool _failed = false;
  bool _denied = false;
  @override
  void initState() {
    super.initState();
    _space = widget.space;
    unawaited(_load());
  }

  Future<void> _load() async {
    final cache = MessengerRuntime.instance.offlineCache;
    try {
      final details = await widget.rpc.company(widget.id);
      _space ??= (await widget.rpc.context())
          .where((s) => s.id == details.company.spaceId)
          .firstOrNull;
      if (!mounted) return;
      setState(() {
        _details = details;
        _failed = false;
        _offline = false;
      });
      await cache?.putCrm(
        'company:${widget.id}',
        jsonEncode({
          ...details.toJson(),
          'contacts': <Object>[],
          'activities': <Object>[],
          'documents': <Object>[],
          'company': {...details.company.toJson(), 'notes': null},
          'deals': details.deals.map(crmCacheDeal).toList(),
        }),
      );
    } catch (e) {
      if (e is CrmAccessDenied) await cache?.removeCrm('company:${widget.id}');
      if (isTransientSendError(e)) {
        final saved = await cache?.getCrm('company:${widget.id}');
        if (saved != null && mounted) {
          try {
            final details = CrmCompanyDetails.fromJson(
              jsonDecode(saved) as Map<String, dynamic>,
            );
            _space ??= (await widget.rpc.context())
                .where((s) => s.id == details.company.spaceId)
                .firstOrNull;
            if (!mounted) return;
            setState(() {
              _details = details;
              _offline = true;
              _failed = false;
            });
            return;
          } catch (_) {
            await cache?.removeCrm('company:${widget.id}');
          }
        }
      }
      if (mounted) {
        setState(() {
          _details = null;
          _failed = true;
          _denied = e is CrmAccessDenied;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final details = _details;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _failed
            ? CrmError(denied: _denied, retry: _load)
            : details == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CrmCircleButton(
                        icon: Icons.chevron_left,
                        label: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      if (_space?.canWrite == true)
                        CrmPill(
                          height: 44,
                          tone: CrmPillTone.accent,
                          onPressed: () => crmCreateDeal(
                            context,
                            widget.rpc,
                            _space!,
                            company: details.company,
                          ),
                          child: Text(l.crmAddDeal),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final label in [
                        crmCompanyKind(l, details.company.kind),
                        details.company.region ??
                            _space?.segments
                                .where((s) => s.id == details.company.segmentId)
                                .firstOrNull
                                ?.name ??
                            '—',
                        crmCompanyStatus(l, details.company.status),
                      ])
                        CrmPill(height: 26, child: Text(label)),
                    ],
                  ),
                  if (_offline) Text(l.crmOffline),
                  Text(
                    details.company.name,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    [
                      l.crmLead,
                      details.deals
                              .where(
                                (d) =>
                                    d.ownerUserId ==
                                    details.company.ownerUserId,
                              )
                              .firstOrNull
                              ?.ownerDisplayName ??
                          '—',
                      if (details.company.website != null)
                        '· ${details.company.website}',
                    ].join(' '),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CrmPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CrmSectionHeader(
                          'Futbolista',
                          uppercase: false,
                          trailing: CrmPill(
                            height: 30,
                            padding: 10,
                            tone: CrmPillTone.outline,
                            child: Text(
                              l.crmLinkOrganizer,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        Text(
                          l.crmFutbolistaNotice,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  CrmPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CrmSectionHeader(
                          '${l.crmDeals} · ${details.deals.length}',
                          uppercase: false,
                        ),
                        for (final deal in details.deals)
                          CrmGlassCard(
                            radius: 16,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            child: CrmFlatRow(
                              title: Text(
                                deal.title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                deal.nextStepAt == null
                                    ? l.crmPending
                                    : crmDate(
                                        context,
                                        deal.nextStepAt!,
                                        due: true,
                                      ),
                              ),
                              trailing: Text(
                                crmMoney(context, deal.amount, deal.currency),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => CrmDealScreen(
                                    id: deal.id,
                                    rpc: widget.rpc,
                                    space: _space,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  CrmPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CrmSectionHeader(
                          '${l.crmContacts} · ${details.contacts.length}',
                          uppercase: false,
                          trailing:
                              _space?.canWriteSegment(
                                    details.company.segmentId,
                                  ) ==
                                  true
                              ? CrmPill(
                                  height: 30,
                                  tone: CrmPillTone.outline,
                                  onPressed: () async {
                                    await crmCreateContact(
                                      context,
                                      widget.rpc,
                                      details.company,
                                    );
                                    await _load();
                                  },
                                  child: Text(l.crmAddContact),
                                )
                              : null,
                        ),
                        for (final contact in details.contacts)
                          CrmContactTile(contact: contact, company: true),
                        Text(
                          l.crmPdNotice,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CrmPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.crmNotes),
                        Text(details.company.notes ?? '—'),
                      ],
                    ),
                  ),
                  CrmPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CrmSectionHeader(
                          l.crmLatestActivities,
                          uppercase: false,
                        ),
                        for (final activity in details.activities)
                          CrmActivityRow(activity: activity),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class CrmCompanies extends StatefulWidget {
  const CrmCompanies({super.key, required this.rpc, required this.space});
  final CrmRpc rpc;
  final CrmSpaceInfo space;
  @override
  State<CrmCompanies> createState() => _CrmCompaniesState();
}

class _CrmCompaniesState extends State<CrmCompanies> {
  List<CrmCompanyView> _companies = [];
  Object? _error;
  bool _loading = true;
  bool _more = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(CrmCompanies old) {
    super.didUpdateWidget(old);
    if (old.space.id != widget.space.id) unawaited(_load());
  }

  Future<void> _load({bool more = false}) async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.rpc.companies(
        widget.space.id,
        cursor: more ? _companies.last.id : null,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _companies = [if (more) ..._companies, ...page];
        _more = page.length == 100;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = e;
        _companies = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return CrmError(denied: _error is CrmAccessDenied, retry: _load);
    }
    if (_loading && _companies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_companies.isEmpty) {
      return Center(child: Text(NsgL10n.of(context).crmEmpty));
    }
    return ListView(
      children: [
        for (final company in _companies)
          CrmFlatRow(
            title: Text(company.name),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CrmCompanyScreen(
                  id: company.id,
                  rpc: widget.rpc,
                  space: widget.space,
                ),
              ),
            ),
          ),
        if (_more)
          TextButton(
            onPressed: _loading ? null : () => _load(more: true),
            child: Text(NsgL10n.of(context).crmMore),
          ),
      ],
    );
  }
}

String crmCompanyKind(NsgL10n l, CrmCompanyKind kind) => switch (kind) {
  CrmCompanyKind.organizer => l.crmOrganizer,
  CrmCompanyKind.arena => l.crmArena,
  CrmCompanyKind.club => l.crmClub,
  CrmCompanyKind.federation => l.crmFederation,
  CrmCompanyKind.contest => l.crmContest,
  CrmCompanyKind.sponsor => l.crmSponsor,
  CrmCompanyKind.media => l.crmMedia,
  CrmCompanyKind.foreign_partner => l.crmForeignPartner,
  CrmCompanyKind.other => l.crmOther,
};
String crmCompanyStatus(NsgL10n l, CrmCompanyStatus status) => switch (status) {
  CrmCompanyStatus.active => l.crmActive,
  CrmCompanyStatus.paused => l.crmPaused,
  CrmCompanyStatus.closed => l.crmClosedCompany,
};
String crmActivityType(NsgL10n l, CrmActivityType type) => switch (type) {
  CrmActivityType.meeting => l.crmMeeting,
  CrmActivityType.call => l.crmCall,
  CrmActivityType.message => l.crmMessage,
  CrmActivityType.note => l.crmNote,
  CrmActivityType.email => l.crmMessage,
  CrmActivityType.stage_change => l.crmStage,
  CrmActivityType.next_step_change => l.crmNextStep,
  CrmActivityType.document => l.crmDocuments,
  CrmActivityType.system => l.crmActivities,
};

/// Link documents only launch ordinary web URLs.
Uri? crmWebUri(String? text) {
  final uri = text == null ? null : Uri.tryParse(text);
  return uri != null &&
          (uri.scheme == "http" || uri.scheme == "https") &&
          uri.host.isNotEmpty
      ? uri
      : null;
}

List<CrmActivityView> crmRecentActivities(List<CrmActivityView> rows) =>
    [...rows]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
