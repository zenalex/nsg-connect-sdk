import 'crm_room_controller.dart';
import 'crm_format.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import '../nsg_messenger.dart';
import '../i18n/generated/nsg_l10n.dart';
import 'crm_rpc.dart';
import 'crm_state.dart';
import 'crm_forms.dart';

class CrmDealBanner extends StatefulWidget {
  const CrmDealBanner({
    super.key,
    required this.dealId,
    required this.rpc,
    this.room,
  });
  final int dealId;
  final CrmRpc rpc;
  final CrmRoomController? room;
  @override
  State<CrmDealBanner> createState() => _CrmDealBannerState();
}

class _CrmDealBannerState extends State<CrmDealBanner> {
  CrmDealView? _deal;
  String? _stage;
  int _revision = 0;
  Timer? _debounce;
  final Map<int, Future<List<CrmPipelineInfo>>> _pipelines = {};
  final Map<int, DateTime> _catalogReadAt = {};
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _revision = widget.room?.revision ?? 0;
    widget.room?.addListener(_changed);
  }

  void _changed() {
    final revision = widget.room?.revision ?? 0;
    if (_revision == revision) return;
    _revision = revision;
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_load()),
    );
  }

  Future<List<CrmPipelineInfo>> _catalog(int spaceId) async {
    try {
      final readAt = _catalogReadAt[spaceId];
      if (readAt != null &&
          DateTime.now().difference(readAt) > const Duration(minutes: 5)) {
        _pipelines.remove(spaceId);
      }
      return await _pipelines.putIfAbsent(spaceId, () {
        _catalogReadAt[spaceId] = DateTime.now();
        return widget.rpc.pipelines(spaceId);
      });
    } catch (_) {
      _pipelines.remove(spaceId);
      rethrow;
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    try {
      final deal = await widget.rpc.deal(widget.dealId);
      var pipelines = await _catalog(deal.spaceId);
      if (!pipelines.expand((p) => p.stages).any((s) => s.id == deal.stageId)) {
        _pipelines.remove(deal.spaceId);
        pipelines = await _catalog(deal.spaceId);
      }
      final stage = pipelines
          .expand((p) => p.stages)
          .where((s) => s.id == deal.stageId)
          .firstOrNull;
      if (mounted && generation == _generation) {
        setState(() {
          _deal = deal;
          _stage = stage?.name;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _deal = null;
          _stage = null;
        });
      }
    }
  }

  @override
  void didUpdateWidget(CrmDealBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room != widget.room) {
      oldWidget.room?.removeListener(_changed);
      widget.room?.addListener(_changed);
      _revision = widget.room?.revision ?? 0;
    }
    if (oldWidget.rpc != widget.rpc) _pipelines.clear();
    if (oldWidget.dealId != widget.dealId || oldWidget.rpc != widget.rpc) {
      _deal = null;
      _stage = null;
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    ++_generation;
    _debounce?.cancel();
    widget.room?.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = _deal;
    if (d == null) return const SizedBox.shrink();
    return ListTile(
      dense: true,
      minVerticalPadding: 12,
      title: Text(
        '${_stage ?? '—'} · ${d.nextStep ?? NsgL10n.of(context).crmPending}',
      ),
      subtitle: Text(
        d.nextStepAt == null ? '—' : crmDate(context, d.nextStepAt!, due: true),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        try {
          await NsgMessenger.openDeal(context, d.id);
        } catch (e) {
          if (context.mounted) crmShowError(context, e);
        }
      },
    );
  }
}
