import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../nsg_messenger.dart';
import '../messenger_runtime.dart';
import '../theme/nsg_messenger_theme.dart';
import 'crm_controller.dart';
import 'crm_rpc.dart';
import 'crm_state.dart';
import 'crm_format.dart';
import 'crm_components.dart';

Color crmDialogSurface(BuildContext context) =>
    Theme.of(context).extension<NsgMessageBubbleTokens>()?.bubbleInk ??
    Theme.of(context).colorScheme.surfaceContainer;

WidgetStateProperty<Color> crmChipColor(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  final ink = crmDialogSurface(context);
  return WidgetStateProperty.resolveWith(
    (states) => Color.alphaBlend(
      states.contains(WidgetState.selected)
          ? colors.primaryContainer
          : colors.surfaceContainerHigh,
      ink,
    ),
  );
}

void crmShowError(BuildContext context, Object error) {
  final l = NsgL10n.of(context);
  // Never expose server errors or payload values to logs/telemetry/UI.
  final message =
      error is CrmAccessDenied || error is AttachmentAccessDeniedException
      ? l.crmDenied
      : error is CrmVersionConflict || error is CrmProposalStale
      ? l.crmConflict
      : l.crmUnavailable;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<DateTime?> crmPickDate(BuildContext context, {DateTime? initial}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: (initial ?? DateTime.now()).toLocal(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime((initial ?? DateTime.now()).toLocal()),
  );
  return time == null
      ? null
      : DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

Future<void> crmReschedule(
  BuildContext context,
  CrmRpc rpc,
  CrmDealView deal, {
  required Future<void> Function() refresh,
}) async {
  final date = await crmPickDate(context, initial: deal.nextStepAt);
  if (date == null) return;
  try {
    await rpc.call(
      () => rpc.endpoint.setNextStep(
        deal.spaceId,
        deal.id,
        deal.version,
        nextStep: deal.nextStep,
        nextStepAt: date.toUtc(),
        pending: false,
        assigneeId: deal.nextStepAssigneeId,
        idempotencyKey: 'crm-ui:${const Uuid().v4()}',
      ),
    );
  } catch (e) {
    if (context.mounted) crmShowError(context, e);
  }
  await refresh();
}

Future<void> crmMoveStage(
  BuildContext context,
  CrmRpc rpc,
  CrmDealView deal,
  CrmStageInfo stage, {
  required Future<void> Function() refresh,
}) async {
  if (deal.stageId == stage.id) return;
  final l = NsgL10n.of(context);
  String? reason;
  if (stage.kind != CrmStageKind.open) {
    final input = TextEditingController();
    reason = await crmDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: crmDialogSurface(ctx),
        title: Text(l.crmCloseReason),
        content: TextField(
          controller: input,
          decoration: InputDecoration(labelText: l.crmCloseReason),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.crmCancel),
          ),
          FilledButton(
            onPressed: () {
              if (input.text.trim().isNotEmpty) {
                Navigator.pop(ctx, input.text.trim());
              }
            },
            child: Text(l.crmSave),
          ),
        ],
      ),
    );
    input.dispose();
    if (reason == null) return;
  } else {
    final accepted = await crmDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: crmDialogSurface(ctx),
        title: Text('${l.crmStage}: ${stage.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.crmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.crmYes),
          ),
        ],
      ),
    );
    if (accepted != true) return;
  }
  try {
    await rpc.call(
      () => rpc.endpoint.moveStage(
        deal.spaceId,
        deal.id,
        deal.version,
        stage.id,
        closeReason: reason,
        idempotencyKey: 'crm-ui:${const Uuid().v4()}',
      ),
    );
  } catch (e) {
    if (context.mounted) crmShowError(context, e);
  }
  await refresh();
}

Future<void> crmQuickActivity(
  BuildContext context,
  CrmController controller,
  CrmDealView deal, {
  int? agentRoomId,
}) async {
  final l = NsgL10n.of(context);
  final summary = TextEditingController();
  final next = TextEditingController();
  var kind = CrmActivityType.meeting;
  var when = DateTime.now();
  var due = DateTime.now().add(const Duration(days: 1));
  var saving = false;
  await crmBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: CrmGlassCard.paper(context),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            brightness: Brightness.light,
            onSurface: CrmGlassCard.ink(ctx),
            onSurfaceVariant: CrmGlassCard.ink(ctx).withValues(alpha: .7),
            surface: CrmGlassCard.paper(ctx),
          ),
          textTheme: Theme.of(ctx).textTheme.apply(
            bodyColor: CrmGlassCard.ink(ctx),
            displayColor: CrmGlassCard.ink(ctx),
          ),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: CrmGlassCard.ink(ctx)),
          child: CrmQuickSheetLayout(
            actions: Row(
              children: [
                if (agentRoomId != null)
                  SizedBox(
                    width: 56,
                    child: CrmPill(
                      inverse: true,
                      height: 56,
                      stretch: true,
                      radius: 18,
                      padding: 0,
                      tone: CrmPillTone.dark,
                      onPressed: saving
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              NsgMessenger.openRoom(context, agentRoomId);
                            },
                      child: Tooltip(
                        message: l.crmAgent,
                        child: const Icon(Icons.mic),
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: CrmPill(
                    height: 56,
                    stretch: true,
                    radius: 18,
                    tone: CrmPillTone.accent,
                    onPressed: saving
                        ? null
                        : () async {
                            if (summary.text.trim().isEmpty ||
                                next.text.trim().isEmpty) {
                              return;
                            }
                            if (deal.company == null) {
                              crmShowError(
                                ctx,
                                StateError('CRM parent unavailable'),
                              );
                              return;
                            }
                            set(() => saving = true);
                            try {
                              final queued = await controller.addActivity(
                                deal,
                                {
                                  'companyId': deal.company!.id,
                                  'dealId': deal.id,
                                  'type': kind.name,
                                  'occurredAt': when.toUtc().toIso8601String(),
                                  'summary': summary.text.trim(),
                                  'sourceJson': jsonEncode({'via': 'ui'}),
                                },
                                {
                                  'nextStep': next.text.trim(),
                                  'nextStepAt': due.toUtc().toIso8601String(),
                                  'nextStepPending': false,
                                  'nextStepAssigneeId':
                                      deal.nextStepAssigneeId ??
                                      deal.ownerUserId,
                                },
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      queued ? l.crmQueued : l.crmSaved,
                                    ),
                                  ),
                                );
                              }
                              await controller.load();
                            } catch (e) {
                              if (ctx.mounted) {
                                set(() => saving = false);
                                crmShowError(ctx, e);
                              }
                              if (e is CrmVersionConflict) {
                                await controller.load();
                              }
                            }
                          },
                    child: Text(l.crmSave),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: CrmGlassCard.ink(ctx).withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.crmActivity,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            [
                              deal.company?.name,
                              deal.title,
                            ].whereType<String>().join(' · '),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    CrmPill(
                      inverse: true,
                      tone: CrmPillTone.outline,
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l.crmCancel),
                    ),
                  ],
                ),
                CrmSectionHeader(l.crmWhatHappened),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (type, label) in [
                      (CrmActivityType.meeting, l.crmMeeting),
                      (CrmActivityType.call, l.crmCall),
                      (CrmActivityType.message, l.crmMessage),
                      (CrmActivityType.note, l.crmNote),
                    ])
                      CrmPill(
                        inverse: true,
                        height: 44,
                        tone: kind == type
                            ? CrmPillTone.dark
                            : CrmPillTone.glass,
                        onPressed: saving ? null : () => set(() => kind = type),
                        child: Text(label),
                      ),
                  ],
                ),
                CrmField(
                  label: l.crmWhen,
                  child: CrmPill(
                    inverse: true,
                    height: 46,
                    radius: 14,
                    stretch: true,
                    onPressed: saving
                        ? null
                        : () async {
                            final date = await crmPickDate(ctx, initial: when);
                            if (date != null) set(() => when = date);
                          },
                    child: Text(crmDate(ctx, when)),
                  ),
                ),
                CrmField(
                  label: l.crmOutcome,
                  child: TextField(
                    key: const ValueKey('crm-activity-outcome'),
                    controller: summary,
                    maxLines: 3,
                    decoration: InputDecoration(hintText: l.crmOutcome),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Expanded(
                      child: CrmField(
                        label: l.crmNextStep,
                        child: TextField(
                          key: const ValueKey('crm-activity-next-step'),
                          controller: next,
                          decoration: InputDecoration(hintText: l.crmNextStep),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 128,
                      child: CrmField(
                        label: l.crmDue,
                        child: CrmPill(
                          key: const ValueKey('crm-activity-due'),
                          inverse: true,
                          height: 46,
                          radius: 14,
                          stretch: true,
                          onPressed: saving
                              ? null
                              : () async {
                                  final date = await crmPickDate(
                                    ctx,
                                    initial: due,
                                  );
                                  if (date != null) set(() => due = date);
                                },
                          child: Text(crmDate(ctx, due)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  summary.dispose();
  next.dispose();
}

Future<void> crmCreateDeal(
  BuildContext context,
  CrmRpc rpc,
  CrmSpaceInfo space, {
  CrmCompanyView? company,
}) async {
  final l = NsgL10n.of(context);
  List<CrmPipelineInfo> pipelines;
  List<CrmCompanyView> companies;
  try {
    pipelines = (await rpc.pipelines(
      space.id,
    )).where((p) => p.stages.any((s) => s.kind == CrmStageKind.open)).toList();
    companies = company == null ? await rpc.companies(space.id) : [company];
  } catch (e) {
    if (context.mounted) crmShowError(context, e);
    return;
  }
  if (!context.mounted) return;
  if (pipelines.isEmpty || space.segments.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.crmNoOpenStages)));
    return;
  }
  if (companies.isEmpty) {
    final create = await crmDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: crmDialogSurface(ctx),
        title: Text(l.crmNoCompanies),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.crmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.crmNewCompany),
          ),
        ],
      ),
    );
    if (create == true && context.mounted) {
      final created = await crmCreateCompany(context, rpc, space);
      if (created != null && context.mounted) {
        await crmCreateDeal(context, rpc, space, company: created);
      }
    }
    return;
  }
  var selectedCompany = company ?? companies.first;
  var segmentId = space.segments.any((s) => s.id == selectedCompany.segmentId)
      ? selectedCompany.segmentId
      : space.segments.first.id;
  var pipeline = pipelines.first;
  var stage = pipeline.stages.firstWhere((s) => s.kind == CrmStageKind.open);
  var ownerId = MessengerRuntimeUserId.value;
  var users = <CrmUserView>[];
  bool canChooseOwner(int id) =>
      space.isAdmin ||
      space.segments.where((s) => s.id == id).firstOrNull?.role ==
          'crm_manager';
  try {
    if (canChooseOwner(segmentId)) {
      users = await rpc.assignableUsers(space.id, segmentId);
    }
  } catch (e) {
    if (context.mounted) crmShowError(context, e);
    return;
  }
  if (!context.mounted) return;
  if (users.isNotEmpty && !users.any((u) => u.id == ownerId)) {
    ownerId = users.first.id;
  }
  final title = TextEditingController(),
      amount = TextEditingController(),
      next = TextEditingController();
  final currency = TextEditingController(text: space.currency ?? 'RUB');
  var due = DateTime.now().add(const Duration(days: 1));
  var saving = false, loadingUsers = false;
  var generation = 0;
  await crmDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        backgroundColor: crmDialogSurface(ctx),
        title: Text(l.crmNewDeal),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.crmCompany),
                  subtitle: Text(selectedCompany.name),
                  trailing: const Icon(Icons.search),
                  onTap: saving
                      ? null
                      : () async {
                          final picked = await crmChooseCompany(
                            ctx,
                            rpc,
                            space.id,
                          );
                          if (picked != null && ctx.mounted) {
                            set(() => selectedCompany = picked);
                          }
                        },
                ),
                TextField(
                  controller: title,
                  decoration: InputDecoration(labelText: l.crmTitleField),
                ),
                CrmSelect<int>(
                  initialValue: segmentId,
                  decoration: InputDecoration(labelText: l.crmSegment),
                  items: space.segments
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (id) async {
                          if (id == null) return;
                          final request = ++generation;
                          set(() {
                            segmentId = id;
                            loadingUsers = true;
                            users = [];
                            ownerId = MessengerRuntimeUserId.value;
                          });
                          try {
                            final found = canChooseOwner(id)
                                ? await rpc.assignableUsers(space.id, id)
                                : <CrmUserView>[];
                            if (ctx.mounted && generation == request) {
                              set(() {
                                users = found;
                                loadingUsers = false;
                                if (found.isNotEmpty &&
                                    !found.any((u) => u.id == ownerId)) {
                                  ownerId = found.first.id;
                                }
                              });
                            }
                          } catch (e) {
                            if (ctx.mounted && generation == request) {
                              set(() => loadingUsers = false);
                              crmShowError(ctx, e);
                            }
                          }
                        },
                ),
                CrmSelect<int>(
                  initialValue: pipeline.id,
                  decoration: InputDecoration(labelText: l.crmPipeline),
                  items: pipelines
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (id) => set(() {
                          pipeline = pipelines.firstWhere((p) => p.id == id);
                          stage = pipeline.stages.firstWhere(
                            (s) => s.kind == CrmStageKind.open,
                          );
                        }),
                ),
                CrmSelect<int>(
                  key: ValueKey(pipeline.id),
                  initialValue: stage.id,
                  decoration: InputDecoration(labelText: l.crmStage),
                  items: pipeline.stages
                      .where((s) => s.kind == CrmStageKind.open)
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (id) => stage = pipeline.stages.firstWhere(
                          (s) => s.id == id,
                        ),
                ),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: l.crmAmount),
                ),
                TextField(
                  controller: currency,
                  decoration: InputDecoration(labelText: l.crmCurrency),
                ),
                if (canChooseOwner(segmentId))
                  CrmSelect<int>(
                    key: ValueKey('$segmentId:$loadingUsers'),
                    initialValue: users.any((u) => u.id == ownerId)
                        ? ownerId
                        : null,
                    decoration: InputDecoration(labelText: l.crmOwner),
                    items: users
                        .map(
                          (u) => DropdownMenuItem(
                            value: u.id,
                            child: Text(u.displayName ?? '—'),
                          ),
                        )
                        .toList(),
                    onChanged: saving || loadingUsers
                        ? null
                        : (id) {
                            if (id != null) ownerId = id;
                          },
                  ),
                TextField(
                  controller: next,
                  decoration: InputDecoration(labelText: l.crmNextStep),
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final d = await crmPickDate(ctx, initial: due);
                          if (d != null && ctx.mounted) set(() => due = d);
                        },
                  child: Text('${l.crmDue}: ${crmDate(ctx, due)}'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx),
            child: Text(l.crmCancel),
          ),
          FilledButton(
            onPressed:
                saving ||
                    loadingUsers ||
                    (canChooseOwner(segmentId) && users.isEmpty)
                ? null
                : () async {
                    if (title.text.trim().isEmpty || next.text.trim().isEmpty) {
                      return;
                    }
                    set(() => saving = true);
                    try {
                      await rpc.call(
                        () => rpc.endpoint.createDeal(
                          space.id,
                          jsonEncode({
                            'companyId': selectedCompany.id,
                            'segmentId': segmentId,
                            'pipelineId': pipeline.id,
                            'stageId': stage.id,
                            'title': title.text.trim(),
                            'ownerUserId': ownerId,
                            'amount': amount.text.isEmpty
                                ? null
                                : amount.text.replaceAll(',', '.'),
                            'currency': currency.text.trim(),
                            'nextStep': next.text.trim(),
                            'nextStepAt': due.toUtc().toIso8601String(),
                            'nextStepPending': false,
                          }),
                          idempotencyKey: 'crm-ui:${const Uuid().v4()}',
                        ),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (ctx.mounted) {
                        set(() => saving = false);
                        crmShowError(ctx, e);
                      }
                    }
                  },
            child: Text(l.crmSave),
          ),
        ],
      ),
    ),
  );
  ++generation;
  for (final c in [title, amount, currency, next]) {
    c.dispose();
  }
}

/// Search stays on the server; the initial page is not the whole catalog.
Future<CrmCompanyView?> crmChooseCompany(
  BuildContext context,
  CrmRpc rpc,
  int space,
) async {
  final search = TextEditingController();
  List<CrmCompanyView> rows;
  try {
    rows = await rpc.companies(space);
  } catch (e) {
    search.dispose();
    if (context.mounted) crmShowError(context, e);
    return null;
  }
  var busy = false;
  int? cursor = rows.length == 100 ? rows.last.id : null;
  var generation = 0;
  if (!context.mounted) {
    search.dispose();
    return null;
  }
  final result = await crmDialog<CrmCompanyView>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        backgroundColor: crmDialogSurface(ctx),
        title: Text(NsgL10n.of(ctx).crmChooseCompany),
        content: SizedBox(
          width: 440,
          height: 420,
          child: Column(
            children: [
              TextField(
                controller: search,
                decoration: InputDecoration(
                  labelText: NsgL10n.of(ctx).crmSearch,
                ),
                onChanged: (text) async {
                  final request = ++generation;
                  set(() => busy = true);
                  try {
                    final found = text.trim().isEmpty
                        ? await rpc.companies(space)
                        : await rpc.searchCompanies(space, text.trim());
                    if (ctx.mounted && generation == request) {
                      set(() {
                        rows = found;
                        busy = false;
                        cursor = text.trim().isEmpty && found.length == 100
                            ? found.last.id
                            : null;
                      });
                    }
                  } catch (e) {
                    if (ctx.mounted && generation == request) {
                      set(() => busy = false);
                      crmShowError(ctx, e);
                    }
                  }
                },
              ),
              if (busy) const LinearProgressIndicator(),
              Expanded(
                child: ListView(
                  children: [
                    for (final c in rows)
                      ListTile(
                        title: Text(c.name),
                        onTap: () => Navigator.pop(ctx, c),
                      ),
                  ],
                ),
              ),
              if (cursor != null)
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final request = ++generation, nextCursor = cursor;
                          set(() => busy = true);
                          try {
                            final page = await rpc.companies(
                              space,
                              cursor: nextCursor,
                            );
                            if (ctx.mounted && generation == request) {
                              set(() {
                                rows = [...rows, ...page];
                                busy = false;
                                cursor = page.length == 100
                                    ? page.last.id
                                    : null;
                              });
                            }
                          } catch (e) {
                            if (ctx.mounted && generation == request) {
                              set(() => busy = false);
                              crmShowError(ctx, e);
                            }
                          }
                        },
                  child: Text(NsgL10n.of(ctx).crmMore),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  ++generation;
  search.dispose();
  return result;
}

Future<CrmCompanyView?> crmCreateCompany(
  BuildContext context,
  CrmRpc rpc,
  CrmSpaceInfo space,
) async {
  final l = NsgL10n.of(context), name = TextEditingController();
  var segment = space.segments.first.id, saving = false;
  final id = await crmDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        backgroundColor: crmDialogSurface(ctx),
        title: Text(l.crmNewCompany),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: l.crmTitleField),
            ),
            CrmSelect<int>(
              initialValue: segment,
              items: space.segments
                  .map(
                    (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                  )
                  .toList(),
              decoration: InputDecoration(labelText: l.crmSegment),
              onChanged: (id) => segment = id!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx),
            child: Text(l.crmCancel),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    if (name.text.trim().isEmpty) return;
                    set(() => saving = true);
                    try {
                      final created = await rpc.call(
                        () => rpc.endpoint.createCompany(
                          space.id,
                          jsonEncode({
                            'name': name.text.trim(),
                            'segmentId': segment,
                            'kind': 'other',
                            'ownerUserId': MessengerRuntimeUserId.value,
                          }),
                          idempotencyKey: 'crm-ui:${const Uuid().v4()}',
                        ),
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx, created.items.first.entityId);
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        set(() => saving = false);
                        crmShowError(ctx, e);
                      }
                    }
                  },
            child: Text(l.crmSave),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  if (id == null) return null;
  try {
    return (await rpc.company(id)).company;
  } catch (e) {
    if (context.mounted) crmShowError(context, e);
    return null;
  }
}

// Resolve the authenticated sender only at the entry point, never from a form.
class MessengerRuntimeUserId {
  static int get value => MessengerRuntime.instance.session.messengerUserId;
}

Future<void> crmCreateContact(
  BuildContext context,
  CrmRpc rpc,
  CrmCompanyView company,
) async {
  final l = NsgL10n.of(context);
  final name = TextEditingController();
  var saving = false;
  await crmDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        backgroundColor: crmDialogSurface(ctx),
        title: Text(l.crmNewContact),
        content: TextField(
          controller: name,
          decoration: InputDecoration(labelText: l.crmTitleField),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx),
            child: Text(l.crmCancel),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    if (name.text.trim().isEmpty) return;
                    set(() => saving = true);
                    try {
                      await rpc.call(
                        () => rpc.endpoint.createContact(
                          company.spaceId,
                          jsonEncode({
                            'companyId': company.id,
                            'fullName': name.text.trim(),
                          }),
                          idempotencyKey: 'crm-ui:${const Uuid().v4()}',
                        ),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (ctx.mounted) {
                        set(() => saving = false);
                        crmShowError(ctx, e);
                      }
                    }
                  },
            child: Text(l.crmSave),
          ),
        ],
      ),
    ),
  );
  name.dispose();
}

/// Dispose form controllers only after the route has left the widget tree.
Future<T?> crmDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  final route = DialogRoute<T>(context: context, builder: builder);
  final value = await Navigator.of(context).push(route);
  await route.completed;
  return value;
}

Future<void> crmBottomSheet({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  Color? backgroundColor,
}) async {
  final route = ModalBottomSheetRoute<void>(
    builder: builder,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    clipBehavior: Clip.antiAlias,
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: Navigator.of(context).context,
    ),
  );
  await Navigator.of(context).push(route);
  await route.completed;
}
