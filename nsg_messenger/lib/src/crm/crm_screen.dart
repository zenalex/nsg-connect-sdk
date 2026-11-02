import 'package:flutter/gestures.dart';
import 'crm_format.dart';
import 'dart:async';
import '../outbox/outbox_item.dart';
import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../nsg_messenger.dart';
import 'crm_components.dart';
import 'crm_controller.dart';
import 'crm_rpc.dart';
import 'crm_state.dart';
import 'crm_detail_screen.dart';
import 'crm_forms.dart';

/// A host can embed this view as a tab or use NsgMessenger.openCrm.
class CrmScreen extends StatefulWidget {
  const CrmScreen({
    super.key,
    this.rpc,
    this.controller,
    this.space,
    this.userId,
    this.leading,
  });
  final CrmRpc? rpc;
  final CrmController? controller;
  final CrmSpaceInfo? space;
  final int? userId;
  final Widget? leading;
  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen> {
  CrmController? _controller;
  late CrmRpc _rpc;
  List<CrmSpaceInfo> _spaces = [];
  CrmSpaceInfo? _space;
  bool _denied = false;
  bool _failed = false;
  bool _bootstrapping = true;
  CrmViewMode _mode = CrmViewMode.steps;
  CrmStepFilter _filter = CrmStepFilter.today;
  int? _pipelineId;
  int? _stage;
  bool _closed = false;
  bool _list = false;
  @override
  void initState() {
    super.initState();
    _rpc = widget.rpc ?? CrmRpc(MessengerRuntime.instance.client.crm);
    if (widget.controller != null) {
      _bootstrapping = false;
      _space = widget.space;
      _controller = widget.controller!..addListener(_changed);
      unawaited(_controller!.load());
    } else {
      unawaited(_bootstrap());
    }
  }

  Future<void> _bootstrap() async {
    setState(() => _bootstrapping = true);
    try {
      final spaces = await _rpc.context();
      if (!mounted) return;
      setState(() {
        _spaces = spaces;
        _failed = false;
        _denied = false;
        _bootstrapping = false;
      });
      if (spaces.isNotEmpty) await _selectSpace(spaces.first);
    } catch (e) {
      if (mounted) {
        setState(() {
          _failed = true;
          _bootstrapping = false;
          _denied = e is CrmAccessDenied;
        });
      }
    }
  }

  Future<void> _selectSpace(CrmSpaceInfo space) async {
    _controller?.removeListener(_changed);
    _controller?.dispose();
    final rt = MessengerRuntime.instance;
    final controller = CrmController(
      rpc: _rpc,
      spaceId: space.id,
      userId: widget.userId ?? rt.session.messengerUserId,
      cache: rt.offlineCache,
      outbox: rt.outbox,
    );
    controller.addListener(_changed);
    setState(() {
      _space = space;
      _controller = controller;
      _stage = null;
      _pipelineId = null;
    });
    await controller.load();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_changed);
    if (widget.controller == null) _controller?.dispose();
    super.dispose();
  }

  Future<void> _agent() async {
    final roomId = _space?.agentRoomId;
    if (roomId != null) await NsgMessenger.openRoom(context, roomId);
  }

  Future<void> _detail(CrmDealView deal) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CrmDealScreen(
          id: deal.id,
          rpc: _rpc,
          space: _space,
          controller: _controller,
        ),
      ),
    );
    await _controller?.load();
  }

  void _modeChanged(CrmViewMode mode) {
    setState(() => _mode = mode);
    if (_controller != null && mode != CrmViewMode.companies) {
      _controller!.forSteps = mode == CrmViewMode.steps;
      _controller!.segmentId = null;
      _controller!.overdue = false;
      _controller!.text = null;
      unawaited(_controller!.load());
    }
  }

  Future<void> _create() async {
    if (_space == null) return;
    await crmCreateDeal(context, _rpc, _space!);
    await _controller?.load();
  }

  Future<void> _search() async {
    final input = TextEditingController(text: _controller?.text);
    final result = await crmDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(NsgL10n.of(ctx).crmSearch),
        content: TextField(
          controller: input,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          CrmPill(
            onPressed: () => Navigator.pop(ctx, input.text),
            child: Text(NsgL10n.of(ctx).crmSearch),
          ),
        ],
      ),
    );
    input.dispose();
    if (result != null) {
      _controller?.text = result.trim().isEmpty ? null : result.trim();
      await _controller?.load();
    }
  }

  Future<void> _segment() async {
    final l = NsgL10n.of(context);
    final picked = await crmDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.crmSegment),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, -1),
            child: Text(l.crmAll),
          ),
          for (final s in _space?.segments ?? <CrmSegmentInfo>[])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, s.id),
              child: Text(s.name),
            ),
        ],
      ),
    );
    if (picked != null) {
      _controller?.segmentId = picked == -1 ? null : picked;
      await _controller?.load();
    }
  }

  Widget _chooser<T>(
    T? selected,
    List<(T, String)> choices,
    ValueChanged<T> pick,
  ) => CrmPill(
    height: 34,
    child: Text(choices.where((p) => p.$1 == selected).firstOrNull?.$2 ?? '—'),
    onPressed: () async {
      final value = await crmDialog<T>(
        context: context,
        builder: (ctx) => SimpleDialog(
          children: [
            for (final p in choices)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, p.$1),
                child: Text(p.$2),
              ),
          ],
        ),
      );
      if (value != null) pick(value);
    },
  );

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final state = _controller?.state;
    final desktopPipeline =
        MediaQuery.sizeOf(context).width >= 1100 &&
        _mode == CrmViewMode.pipeline &&
        state is CrmReady;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () async {
            if (_controller == null) {
              await _bootstrap();
            } else {
              await _controller!.load();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if ((_controller?.expiredActivities ?? 0) > 0)
                MaterialBanner(
                  content: Text(
                    l.crmQueueExpired(_controller!.expiredActivities),
                  ),
                  actions: [
                    TextButton(
                      onPressed: _controller!.acknowledgeExpiredActivities,
                      child: Text(l.crmYes),
                    ),
                  ],
                ),
              if (!desktopPipeline)
                CrmScreenHeader(
                  accent: switch (_mode) {
                    CrmViewMode.steps => l.crmHeaderSteps,
                    CrmViewMode.pipeline => l.crmPipeline.toLowerCase(),
                    CrmViewMode.companies => l.crmCompanies.toLowerCase(),
                  },
                  subtitle: _mode == CrmViewMode.pipeline && state is CrmReady
                      ? '${state.pipelines.where((p) => p.id == _pipelineId).firstOrNull?.name ?? state.pipelines.firstOrNull?.name ?? ''} · ${l.crmSegment}: ${_space?.segments.where((s) => s.id == _controller?.segmentId).firstOrNull?.name ?? l.crmAll}'
                      : _space?.name ?? '',
                  leading: widget.leading,
                  actions: [
                    CrmCircleButton(
                      icon: Icons.search,
                      label: l.crmSearch,
                      onPressed: _search,
                    ),
                    CrmCircleButton(
                      icon: _mode == CrmViewMode.steps
                          ? Icons.filter_list
                          : Icons.add,
                      label: _mode == CrmViewMode.steps
                          ? l.crmSegment
                          : l.crmNewDeal,
                      accent: _mode != CrmViewMode.steps,
                      onPressed: _mode == CrmViewMode.steps
                          ? _segment
                          : _space?.canWrite == true
                          ? _create
                          : null,
                    ),
                  ],
                ),
              if (_spaces.length > 1)
                _chooser<int>(
                  _space?.id,
                  [for (final s in _spaces) (s.id, s.name)],
                  (id) => _selectSpace(_spaces.firstWhere((s) => s.id == id)),
                ),
              if (!desktopPipeline)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      for (final (mode, title) in [
                        (CrmViewMode.steps, l.crmSteps),
                        (CrmViewMode.pipeline, l.crmPipeline),
                        (CrmViewMode.companies, l.crmCompanies),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CrmPill(
                            tone: _mode == mode
                                ? CrmPillTone.white
                                : CrmPillTone.glass,
                            onPressed: () => _modeChanged(mode),
                            child: Text(title),
                          ),
                        ),
                    ],
                  ),
                ),
              for (final item
                  in _controller?.queuedActivities ?? <OutboxItem>[])
                CrmFlatRow(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: Text(
                    item.lastError == 'crm_version_conflict'
                        ? l.crmConflict
                        : item.status == OutboxStatus.failed
                        ? l.crmUnavailable
                        : l.crmQueued,
                  ),
                  trailing: CrmCircleButton(
                    icon: Icons.close,
                    label: l.crmCancel,
                    onPressed: () =>
                        _controller?.outbox?.discard(item.clientTxnId),
                  ),
                ),
              Expanded(
                child: _failed
                    ? CrmError(denied: _denied, retry: _bootstrap)
                    : _mode == CrmViewMode.companies && _space != null
                    ? CrmCompanies(rpc: _rpc, space: _space!)
                    : switch (state) {
                        CrmReady() => _ready(state),
                        CrmUnavailable() => CrmError(
                          denied: state.denied,
                          retry: () => _controller!.load(),
                        ),
                        _ =>
                          _spaces.isEmpty &&
                                  _controller == null &&
                                  !_failed &&
                                  !_bootstrapping
                              ? Center(child: Text(l.crmEmpty))
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                      },
              ),
              if (_space?.agentRoomId != null && !desktopPipeline)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width >= 1100
                        ? 360
                        : double.infinity,
                    height: 56,
                    child: CrmPill(
                      height: 56,
                      tone: CrmPillTone.accent,
                      onPressed: _agent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.mic),
                          const SizedBox(width: 10),
                          Text(l.crmAgent),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ready(CrmReady state) {
    final l = NsgL10n.of(context);
    if (_mode == CrmViewMode.steps) {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final week = DateTime(now.year, now.month, now.day + 7);
      // These are display buckets of the server-authorized result, never rights.
      List<CrmDealView> bucket(CrmStepFilter filter) => state.deals
          .where(
            (d) =>
                d.closedAt == null &&
                switch (filter) {
                  CrmStepFilter.pending => d.nextStepPending,
                  CrmStepFilter.overdue => d.nextStepAt?.isBefore(now) ?? false,
                  CrmStepFilter.today =>
                    d.nextStepAt != null &&
                        !d.nextStepAt!.isBefore(
                          DateTime(now.year, now.month, now.day),
                        ) &&
                        d.nextStepAt!.isBefore(tomorrow),
                  CrmStepFilter.week =>
                    d.nextStepAt != null &&
                        !d.nextStepAt!.isBefore(now) &&
                        d.nextStepAt!.isBefore(week),
                },
          )
          .toList();
      final deals = bucket(_filter);
      return Column(
        children: [
          if (state.offline) Text(l.crmOffline),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (final (f, label) in [
                  (CrmStepFilter.today, l.crmToday),
                  (CrmStepFilter.overdue, l.crmOverdue),
                  (CrmStepFilter.week, l.crmWeek),
                  (CrmStepFilter.pending, l.crmPending),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CrmPill(
                      tone: _filter == f
                          ? CrmPillTone.white
                          : CrmPillTone.glass,
                      child: Text('$label ${bucket(f).length}'),
                      onPressed: () => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          if (_filter != CrmStepFilter.today)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CrmSectionHeader(
                '${switch (_filter) {
                  CrmStepFilter.today => l.crmToday,
                  CrmStepFilter.overdue => l.crmOverdue,
                  CrmStepFilter.week => l.crmWeek,
                  CrmStepFilter.pending => l.crmPending,
                }} · ${deals.length}',
                alert: _filter == CrmStepFilter.overdue,
              ),
            ),
          Expanded(
            child: _filter == CrmStepFilter.today
                ? _todaySections(
                    bucket(CrmStepFilter.overdue),
                    bucket(
                      CrmStepFilter.today,
                    ).where((d) => !d.nextStepAt!.isBefore(now)).toList(),
                  )
                : _deals(deals, steps: true),
          ),
        ],
      );
    }
    final pipeline =
        state.pipelines.where((p) => p.id == _pipelineId).firstOrNull ??
        state.pipelines.firstOrNull;
    final stages =
        pipeline?.stages
            .where(
              (s) => _closed
                  ? s.kind != CrmStageKind.open
                  : s.kind == CrmStageKind.open,
            )
            .toList() ??
        [];
    final deals = state.deals
        .where((d) => d.pipelineId == pipeline?.id)
        .toList();
    final selected =
        stages.where((s) => s.id == _stage).firstOrNull ?? stages.firstOrNull;
    final desktop = MediaQuery.sizeOf(context).width >= 1100;
    final filters = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        spacing: 8,
        children: [
          if (desktop)
            CrmPill(
              onPressed: () => _modeChanged(CrmViewMode.companies),
              child: Text(l.crmCompanies),
            ),
          if (MediaQuery.sizeOf(context).width >= 1100)
            CrmSegmented(
              labels: [l.crmKanban, l.crmList, l.crmSteps],
              selected: _list ? 1 : 0,
              onSelected: (i) => i == 2
                  ? _modeChanged(CrmViewMode.steps)
                  : setState(() => _list = i == 1),
            ),
          if (state.pipelines.length > 1)
            _chooser<int>(
              pipeline?.id,
              [for (final p in state.pipelines) (p.id, p.name)],
              (id) => setState(() {
                _pipelineId = id;
                _stage = null;
              }),
            ),
          CrmPill(
            height: 34,
            tone: _controller!.mine ? CrmPillTone.white : CrmPillTone.glass,
            onPressed: () {
              _controller!.mine = !_controller!.mine;
              unawaited(_controller!.load());
            },
            child: Text(l.crmMine),
          ),
          CrmPill(
            height: 34,
            onPressed: _segment,
            child: Text(
              '${l.crmSegment}: ${_space?.segments.where((s) => s.id == _controller!.segmentId).firstOrNull?.name ?? l.crmAll}',
            ),
          ),
          CrmPill(
            height: 34,
            tone: CrmPillTone.alert,
            onPressed: () {
              _controller!.overdue = !_controller!.overdue;
              unawaited(_controller!.load());
            },
            child: Text(
              '${l.crmOverdue} ${state.deals.where((d) => d.nextStepAt?.isBefore(DateTime.now()) ?? false).length}',
            ),
          ),
          CrmPill(
            height: 34,
            tone: _closed ? CrmPillTone.white : CrmPillTone.glass,
            onPressed: () => setState(() {
              _closed = !_closed;
              _stage = null;
            }),
            child: Text(l.crmClosed),
          ),
          if (desktop)
            CrmPill(
              height: 42,
              tone: CrmPillTone.accent,
              onPressed: _space?.canWrite == true ? _create : null,
              child: Text(l.crmAddDeal),
            ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (desktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: CrmScreenHeader(
                  accent: l.crmPipeline.toLowerCase(),
                  subtitle:
                      '${pipeline?.name ?? ''} · ${deals.length} ${l.crmDeals.toLowerCase()} · ${crmTotalsText(context, deals.where((d) => d.closedAt == null))} ${l.crmOpenTotal}',
                  leading: widget.leading,
                ),
              ),
              Expanded(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: filters,
                ),
              ),
            ],
          )
        else
          filters,
        Expanded(
          child: LayoutBuilder(
            builder: (context, bounds) {
              if (bounds.maxWidth >= 1100 && !_list) {
                return CrmKanban(
                  stages: stages,
                  terminalStages:
                      pipeline?.stages
                          .where((s) => s.kind != CrmStageKind.open)
                          .toList() ??
                      [],
                  deals: deals,
                  onOpen: _detail,
                  onMove: (d, s) => crmMoveStage(
                    context,
                    _rpc,
                    d,
                    s,
                    refresh: () => _controller!.load(),
                  ),
                  canWrite: _space?.canWrite ?? false,
                );
              }
              return Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        for (final s in stages)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CrmPill(
                              radius: 16,
                              height: 56,
                              tone: s.id == selected?.id
                                  ? CrmPillTone.white
                                  : CrmPillTone.glass,
                              onPressed: () => setState(() => _stage = s.id),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(s.name),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${deals.where((d) => d.stageId == s.id).length} · ${crmTotalsText(context, deals.where((d) => d.stageId == s.id))}',
                                    style: const TextStyle(fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _deals(
                      deals.where((d) => d.stageId == selected?.id).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _todaySections(List<CrmDealView> overdue, List<CrmDealView> today) {
    final l = NsgL10n.of(context);
    if (overdue.isEmpty && today.isEmpty) {
      return Center(child: Text(l.crmEmpty));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        if (overdue.isNotEmpty) ...[
          CrmSectionHeader('${l.crmOverdue} · ${overdue.length}', alert: true),
          for (final deal in overdue) _dealTile(deal, steps: true),
        ],
        if (today.isNotEmpty) ...[
          CrmSectionHeader('${l.crmToday} · ${today.length}'),
          for (final deal in today) _dealTile(deal, steps: true),
        ],
      ],
    );
  }

  Widget _deals(List<CrmDealView> deals, {bool steps = false}) {
    if (deals.isEmpty) return Center(child: Text(NsgL10n.of(context).crmEmpty));
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: deals.length,
      itemBuilder: (_, i) => _dealTile(deals[i], steps: steps),
    );
  }

  Widget _dealTile(CrmDealView deal, {bool steps = false}) {
    final l = NsgL10n.of(context);
    return CrmDealTile(
      deal: deal,
      stepPriority: steps,
      segmentName: _space?.segments
          .where((s) => s.id == deal.segmentId)
          .firstOrNull
          ?.name,
      stageName:
          (_controller?.state is CrmReady
                  ? (_controller!.state as CrmReady).pipelines
                  : <CrmPipelineInfo>[])
              .expand((p) => p.stages)
              .where((s) => s.id == deal.stageId)
              .firstOrNull
              ?.name,
      onOpen: () => _detail(deal),
      actions: steps && _space?.canWriteSegment(deal.segmentId) == true
          ? Wrap(
              spacing: 8,
              children: [
                CrmPill(
                  height: 34,
                  onPressed: () => crmReschedule(
                    context,
                    _rpc,
                    deal,
                    refresh: () => _controller!.load(),
                  ),
                  child: Text(l.crmReschedule),
                ),
                CrmPill(
                  height: 34,
                  tone: CrmPillTone.accent,
                  onPressed: () => crmQuickActivity(
                    context,
                    _controller!,
                    deal,
                    agentRoomId: _space?.agentRoomId,
                  ),
                  child: Text(l.crmDoneShort),
                ),
              ],
            )
          : null,
    );
  }
}

class CrmError extends StatelessWidget {
  const CrmError({super.key, required this.retry, this.denied = false});
  final VoidCallback retry;
  final bool denied;
  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(denied ? l.crmDenied : l.crmUnavailable),
          TextButton(onPressed: retry, child: Text(l.commonRetry)),
        ],
      ),
    );
  }
}

class CrmPanel extends StatelessWidget {
  const CrmPanel({super.key, required this.child, this.emphasis = false});
  final Widget child;
  final bool emphasis;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: CrmGlassCard(inverse: emphasis, child: child),
  );
}

class CrmDealTile extends StatelessWidget {
  const CrmDealTile({
    super.key,
    required this.deal,
    required this.onOpen,
    this.actions,
    this.segmentName,
    this.stageName,
    this.stepPriority = false,
    this.compact = false,
  });
  final String? segmentName, stageName;
  final CrmDealView deal;
  final VoidCallback onOpen;
  final Widget? actions;
  final bool stepPriority;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context), theme = Theme.of(context);
    final overdue = deal.nextStepAt?.isBefore(DateTime.now()) ?? false;
    final step = deal.nextStep ?? l.crmPending;
    final owner =
        deal.nextStepAssigneeDisplayName ?? deal.ownerDisplayName ?? '—';
    final due = deal.nextStepAt == null
        ? l.crmPending
        : crmDate(context, deal.nextStepAt!, due: true);
    final money = crmMoney(context, deal.amount, deal.currency);
    final c = theme.colorScheme;
    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: CrmGlassCard(
          radius: 18,
          padding: const EdgeInsets.all(12),
          child: InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [deal.company?.name ?? '—', ?segmentName].join(' · '),
                  style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(step, style: const TextStyle(fontSize: 12.5, height: 1.3)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        due,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: overdue
                              ? crmAlertForeground(context)
                              : c.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      fit: FlexFit.tight,
                      child: Text(
                        money,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.primary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CrmGlassCard(
        alert: stepPriority && overdue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          stepPriority ? deal.company?.name ?? '—' : deal.title,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        fit: FlexFit.tight,
                        child: Text(
                          stepPriority ? due : money,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: stepPriority ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: stepPriority && overdue
                                ? crmAlertForeground(context)
                                : c.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (stepPriority) ...[
                    Text(
                      step,
                      style: const TextStyle(fontSize: 14, height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${stageName ?? '—'} · $owner',
                      style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
                    ),
                    Text(
                      money,
                      style: TextStyle(fontSize: 12, color: c.primary),
                    ),
                  ] else ...[
                    Text(
                      [deal.company?.name ?? '—', ?segmentName].join(' · '),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: c.onSurfaceVariant,
                      ),
                    ),
                    if (!compact) Divider(color: c.outlineVariant, height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            due,
                            style: TextStyle(
                              fontSize: 12,
                              color: overdue
                                  ? crmAlertForeground(context)
                                  : c.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: owner,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: c.surfaceContainerHigh,
                            foregroundColor: c.onSurface,
                            child: Text(
                              owner
                                  .split(' ')
                                  .where((s) => s.isNotEmpty)
                                  .take(2)
                                  .map((s) => s.characters.first)
                                  .join(),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (actions != null)
              Align(alignment: Alignment.centerRight, child: actions!),
          ],
        ),
      ),
    );
  }
}

String crmTotalsText(BuildContext context, Iterable<CrmDealView> deals) {
  final totals = crmStageTotals(deals);
  return totals.entries
      .map((e) => crmMoneyDecimal(context, e.value, e.key))
      .join(' · ');
}

class CrmKanban extends StatefulWidget {
  const CrmKanban({
    super.key,
    required this.stages,
    this.terminalStages = const [],
    required this.deals,
    required this.onOpen,
    required this.onMove,
    required this.canWrite,
  });
  final List<CrmStageInfo> stages;
  final List<CrmStageInfo> terminalStages;
  final List<CrmDealView> deals;
  final ValueChanged<CrmDealView> onOpen;
  final Future<void> Function(CrmDealView, CrmStageInfo) onMove;
  final bool canWrite;
  @override
  State<CrmKanban> createState() => _CrmKanbanState();
}

class _CrmKanbanState extends State<CrmKanban> {
  bool _dragging = false;
  void _endDrag() {
    if (mounted && _dragging) setState(() => _dragging = false);
  }

  @override
  void didUpdateWidget(CrmKanban oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deals != widget.deals || !widget.canWrite) _dragging = false;
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(child: _columns(context)),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text(
          NsgL10n.of(context).crmDragHint,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      if (_dragging)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final stage in widget.terminalStages)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DragTarget<CrmDealView>(
                    key: ValueKey('crm-drop-${stage.id}'),
                    onWillAcceptWithDetails: (d) =>
                        widget.canWrite && d.data.stageId != stage.id,
                    onAcceptWithDetails: (d) => widget.onMove(d.data, stage),
                    builder: (ctx, candidates, _) => Container(
                      width: 220,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: candidates.isEmpty
                            ? Theme.of(ctx).colorScheme.surfaceContainerHigh
                            : Theme.of(ctx).colorScheme.primaryContainer,
                        border: Border.all(
                          color: Theme.of(ctx).colorScheme.outline,
                        ),
                      ),
                      child: Text(
                        stage.name,
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
    ],
  );

  Widget _columns(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final stage in widget.stages)
            SizedBox(
              width: crmColumnWidth(bounds.maxWidth, widget.stages.length),
              height: bounds.maxHeight - 32,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: DragTarget<CrmDealView>(
                  key: ValueKey('crm-stage-${stage.id}'),
                  onWillAcceptWithDetails: (d) =>
                      widget.canWrite && d.data.stageId != stage.id,
                  onAcceptWithDetails: (d) => widget.onMove(d.data, stage),
                  builder: (_, candidates, _) => CrmPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${stage.name} · ${widget.deals.where((d) => d.stageId == stage.id).length}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Flexible(
                              fit: FlexFit.tight,
                              child: Text(
                                crmTotalsText(
                                  context,
                                  widget.deals.where(
                                    (d) => d.stageId == stage.id,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView(
                            children: [
                              for (final deal in widget.deals.where(
                                (d) => d.stageId == stage.id,
                              ))
                                CrmPointerDraggable<CrmDealView>(
                                  key: ValueKey('crm-drag-${deal.id}'),
                                  onDragStarted: () =>
                                      setState(() => _dragging = true),
                                  onDragEnd: (_) => _endDrag(),
                                  onDraggableCanceled: (_, _) => _endDrag(),
                                  data: deal,
                                  maxSimultaneousDrags: widget.canWrite ? 1 : 0,
                                  feedback: Material(
                                    child: SizedBox(
                                      width: 256,
                                      child: Text(deal.title),
                                    ),
                                  ),
                                  child: CrmDealTile(
                                    deal: deal,
                                    stageName: stage.name,
                                    compact: true,
                                    onOpen: () => widget.onOpen(deal),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Select the recognizer from the actual pointer, including hybrid desktops.
class CrmPointerDraggable<T extends Object> extends Draggable<T> {
  const CrmPointerDraggable({
    super.key,
    super.data,
    required super.child,
    required super.feedback,
    super.maxSimultaneousDrags,
    super.onDragStarted,
    super.onDragEnd,
    super.onDraggableCanceled,
  });
  @override
  MultiDragGestureRecognizer createRecognizer(
    GestureMultiDragStartCallback onStart,
  ) => _CrmPointerRecognizer(debugOwner: this)..onStart = onStart;
}

class _CrmPointerRecognizer extends MultiDragGestureRecognizer {
  _CrmPointerRecognizer({super.debugOwner});
  @override
  MultiDragPointerState createNewPointerState(PointerDownEvent event) =>
      event.kind == PointerDeviceKind.touch
      ? DelayedMultiDragGestureRecognizer(
          delay: kLongPressTimeout,
        ).createNewPointerState(event)
      : ImmediateMultiDragGestureRecognizer().createNewPointerState(event);
  @override
  String get debugDescription => 'crm pointer drag';
}
