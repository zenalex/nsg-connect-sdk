import 'crm_format.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

enum CrmViewMode { steps, pipeline, companies }

enum CrmStepFilter { today, overdue, week, pending }

class CrmSegmentInfo {
  const CrmSegmentInfo(
    this.id,
    this.name,
    this.role,
    this.canWrite,
    this.pdRead,
  );
  final int id;
  final String name;
  final String role;
  final bool canWrite;
  final bool pdRead;
  factory CrmSegmentInfo.fromJson(Map j) => CrmSegmentInfo(
    j['id'] as int,
    j['name'] as String,
    j['role'] as String,
    j['canWrite'] as bool,
    j['pdRead'] as bool,
  );
}

class CrmSpaceInfo {
  const CrmSpaceInfo(
    this.id,
    this.name,
    this.timezone,
    this.currency,
    this.isAdmin,
    this.segments,
    this.agentRoomId,
  );
  final int id;
  final String name;
  final String timezone;
  final String? currency;
  final bool isAdmin;
  final List<CrmSegmentInfo> segments;
  final int? agentRoomId;
  bool get canWrite => isAdmin || segments.any((s) => s.canWrite);
  bool canWriteSegment(int id) =>
      isAdmin ||
      (segments.where((s) => s.id == id).firstOrNull?.canWrite ?? false);
  factory CrmSpaceInfo.fromJson(Map j) => CrmSpaceInfo(
    j['spaceId'] as int,
    j['name'] as String,
    j['timezone'] as String,
    j['currency'] as String?,
    j['isAdmin'] as bool,
    (j['segments'] as List)
        .map((s) => CrmSegmentInfo.fromJson(s as Map))
        .toList(),
    j['agentRoomId'] as int?,
  );
}

/// Team-owned catalog; no stage names or ids are built into the UI.
class CrmStageInfo {
  const CrmStageInfo(this.id, this.name, this.kind, this.sortOrder);
  final int id;
  final String name;
  final CrmStageKind kind;
  final int sortOrder;
  factory CrmStageInfo.fromJson(Map<String, dynamic> j) => CrmStageInfo(
    j['id'] as int,
    j['name'] as String,
    CrmStageKind.values.byName(j['kind'] as String),
    j['sortOrder'] as int,
  );
}

class CrmPipelineInfo {
  const CrmPipelineInfo(this.id, this.name, this.stages);
  final int id;
  final String name;
  final List<CrmStageInfo> stages;
  factory CrmPipelineInfo.fromJson(Map<String, dynamic> j) => CrmPipelineInfo(
    j['id'] as int,
    j['name'] as String,
    (j['stages'] as List)
        .map((e) => CrmStageInfo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
  );
}

sealed class CrmState {
  const CrmState();
}

class CrmLoading extends CrmState {
  const CrmLoading();
}

class CrmUnavailable extends CrmState {
  const CrmUnavailable({this.denied = false, this.conflict = false});
  final bool denied;
  final bool conflict;
}

class CrmReady extends CrmState {
  const CrmReady({
    required this.deals,
    required this.pipelines,
    this.offline = false,
  });
  final List<CrmDealView> deals;
  final List<CrmPipelineInfo> pipelines;
  final bool offline;
}

/// Decimal amounts stay exact; currencies are never added to one another.
Map<String, CrmDecimal> crmStageTotals(Iterable<CrmDealView> deals) {
  final totals = <String, CrmDecimal>{};
  for (final d in deals) {
    if (d.closedAt != null || d.amount == null || d.currency == null) continue;
    final decimal = CrmDecimal.parse(d.amount!);
    if (decimal == null) continue;
    totals.update(d.currency!, (v) => v + decimal, ifAbsent: () => decimal);
  }
  return totals;
}
