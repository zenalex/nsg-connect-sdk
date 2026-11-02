import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import '../cache/messenger_cache_store.dart';
import '../messages/send_error_classifier.dart';
import '../outbox/outbox_sender.dart';
import '../outbox/outbox_item.dart';
import 'crm_rpc.dart';
import 'crm_state.dart';

class CrmController extends ChangeNotifier {
  CrmController({
    required this.rpc,
    required this.spaceId,
    required this.userId,
    this.cache,
    this.outbox,
  }) {
    _queueSubscription = cache?.outboxRoomChanges.listen((roomId) {
      if (roomId == 0) unawaited(_refreshQueue());
    });
    unawaited(_refreshQueue());
  }
  final CrmRpc rpc;
  final int spaceId;
  final int userId;
  final MessengerCacheStore? cache;
  final OutboxSender? outbox;
  StreamSubscription<int>? _queueSubscription;
  List<OutboxItem> queuedActivities = [];
  int expiredActivities = 0;
  Future<void> acknowledgeExpiredActivities() async {
    await cache?.removeCrm('expiredActivities:$spaceId');
    if (_disposed) return;
    expiredActivities = 0;
    notifyListeners();
  }

  Future<void> _refreshQueue() async {
    if (_disposed) return;
    List<OutboxItem> rows;
    try {
      rows = await cache?.allOutbox() ?? <OutboxItem>[];
      expiredActivities =
          int.tryParse(
            await cache?.getCrm('expiredActivities:$spaceId') ?? '',
          ) ??
          0;
    } catch (_) {
      return;
    } // Account switching may close the old cache.
    if (_disposed) return;
    final previous = queuedActivities;
    queuedActivities = rows.where((item) {
      if (item.kind != OutboxKind.crmActivity) return false;
      try {
        return (jsonDecode(item.body) as Map)['spaceId'] == spaceId;
      } catch (_) {
        return false;
      }
    }).toList();
    notifyListeners();
    if (previous.isNotEmpty &&
        (queuedActivities.length < previous.length ||
            queuedActivities.any(
              (item) => item.lastError == 'crm_version_conflict',
            ))) {
      unawaited(load());
    }
  }

  CrmState state = const CrmLoading();
  bool _disposed = false;
  int _generation = 0;
  int? stageId;
  int? segmentId;
  bool mine = true;
  bool forSteps = true;
  bool overdue = false;
  String? text;
  String get _cacheKey => 'steps:$spaceId:$userId';

  Future<void> load() async {
    final generation = ++_generation;
    try {
      final items = <CrmDealView>[];
      String? cursor;
      final seen = <String>{};
      do {
        final page = await rpc.deals(
          spaceId,
          cursor: cursor,
          stageId: stageId,
          segmentId: segmentId,
          assigneeId: forSteps ? userId : null,
          ownerUserId: !forSteps && mine ? userId : null,
          overdue: overdue,
          text: text,
        );
        if (generation != _generation || _disposed) return;
        items.addAll(page.items);
        cursor = page.nextCursor;
        if (items.length > 10000) throw StateError("CRM result limit exceeded");
        if (cursor != null && !seen.add(cursor)) {
          throw StateError('Invalid cursor');
        }
      } while (cursor != null);
      final pipelines = await rpc.pipelines(spaceId);
      final ready = CrmReady(deals: items, pipelines: pipelines);
      if (generation != _generation || _disposed) return;
      _emit(ready);
      if (forSteps && stageId == null && segmentId == null && text == null) {
        await cache?.putCrm(
          _cacheKey,
          jsonEncode({
            'deals': ready.deals.map((e) => crmCacheDeal(e)).toList(),
            'pipelines': pipelines
                .map(
                  (p) => {
                    'id': p.id,
                    'name': p.name,
                    'stages': p.stages
                        .map(
                          (t) => {
                            'id': t.id,
                            'name': t.name,
                            'kind': t.kind.name,
                            'sortOrder': t.sortOrder,
                          },
                        )
                        .toList(),
                  },
                )
                .toList(),
          }),
        );
      }
    } catch (e) {
      if (generation != _generation || _disposed) return;
      if (e is CrmAccessDenied) {
        await cache?.removeCrm(_cacheKey);
        _emit(const CrmUnavailable(denied: true));
      } else if (isTransientSendError(e) &&
          forSteps &&
          stageId == null &&
          segmentId == null &&
          text == null) {
        final cached = await cache?.getCrm(_cacheKey);
        if (generation != _generation || _disposed) return;
        if (cached != null) {
          try {
            final j = jsonDecode(cached) as Map;
            _emit(
              CrmReady(
                offline: true,
                deals: (j['deals'] as List)
                    .map(
                      (e) => CrmDealView.fromJson(
                        Map<String, dynamic>.from(e as Map),
                      ),
                    )
                    .toList(),
                pipelines: (j['pipelines'] as List)
                    .map(
                      (e) => CrmPipelineInfo.fromJson(
                        Map<String, dynamic>.from(e as Map),
                      ),
                    )
                    .toList(),
              ),
            );
            return;
          } catch (_) {
            await cache?.removeCrm(_cacheKey);
          }
        }
        _emit(const CrmUnavailable());
      } else {
        _emit(const CrmUnavailable());
      }
    }
  }

  Future<bool> addActivity(
    CrmDealView deal,
    Map<String, dynamic> fields,
    Map<String, dynamic> nextStep,
  ) async {
    final payload = {
      'spaceId': deal.spaceId,
      'dealVersion': deal.version,
      'fields': fields,
      'nextStep': nextStep,
    };
    final key = 'crm-ui:${const Uuid().v4()}';
    try {
      await rpc.activity(payload, key);
      return false;
    } catch (e) {
      if (!isTransientSendError(e) || outbox == null) rethrow;
      await outbox!.enqueueCrmActivity(key: key, payload: jsonEncode(payload));
      return true;
    }
  }

  void _emit(CrmState next) {
    if (_disposed) return;
    state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_queueSubscription?.cancel());
    ++_generation;
    super.dispose();
  }
}

/// Local cache deliberately excludes contact PD, including free-form notes.
/// It never becomes a second source of authorization.
Map<String, dynamic> crmCacheDeal(CrmDealView deal) => {
  ...deal.toJson(),
  'contacts': <Object>[],
  'activities': <Object>[],
  'documents': <Object>[],
  if (deal.company != null)
    'company': {...deal.company!.toJson(), 'notes': null},
};
