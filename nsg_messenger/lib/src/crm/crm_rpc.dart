import 'dart:convert';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import 'crm_state.dart';
import '../messages/send_error_classifier.dart';

/// All network data comes from the generated EndpointCrm. Injecting an endpoint
/// also lets widget tests exercise the actual generated method signatures.
class CrmRpc {
  CrmRpc(this.endpoint, {this.authRetry = true});
  final EndpointCrm endpoint;
  final bool authRetry;
  Future<List<CrmSpaceInfo>> context() async {
    final cache = MessengerRuntime.instance.offlineCache;
    try {
      final json = await call(() => endpoint.getContext());
      final spaces = (jsonDecode(json) as List)
          .map((j) => CrmSpaceInfo.fromJson(j as Map))
          .toList();
      await cache?.putCrm('context', json);
      return spaces;
    } catch (e) {
      if (e is CrmAccessDenied) await cache?.removeCrm('context');
      if (isTransientSendError(e)) {
        final saved = await cache?.getCrm('context');
        if (saved != null) {
          try {
            return (jsonDecode(saved) as List)
                .map((j) => CrmSpaceInfo.fromJson(j as Map))
                .toList();
          } catch (_) {
            await cache?.removeCrm('context');
          }
        }
      }
      rethrow;
    }
  }

  Future<T> call<T>(Future<T> Function() action) => authRetry
      ? withAuthRetry(action, MessengerRuntime.instance.sessionManager)
      : action();

  Future<List<CrmPipelineInfo>> pipelines(int spaceId) async {
    final j =
        jsonDecode(await call(() => endpoint.listPipelines(spaceId))) as Map;
    return (j['pipelines'] as List)
        .map(
          (p) => CrmPipelineInfo.fromJson(Map<String, dynamic>.from(p as Map)),
        )
        .toList();
  }

  Future<CrmDealPage> deals(
    int spaceId, {
    String? cursor,
    int? stageId,
    int? ownerUserId,
    int? assigneeId,
    int? segmentId,
    bool overdue = false,
    DateTime? nextStepBefore,
    String? text,
  }) => call(
    () => endpoint.listDeals(
      spaceId,
      cursor: cursor,
      limit: 100,
      stageId: stageId,
      ownerUserId: ownerUserId,
      assigneeId: assigneeId,
      segmentId: segmentId,
      overdue: overdue,
      stale: false,
      nextStepBefore: nextStepBefore,
      text: text,
      sort: 'nextStepAt',
      descending: false,
    ),
  );

  Future<CrmDealView> deal(int id) => call(() => endpoint.getDeal(id));

  /// The existing messenger RPC authorizes CRM attachments on the server.
  /// Signed URLs are short-lived and must never be cached or logged.
  Future<AttachmentUrl> attachmentUrl(
    String mxcUrl, {
    bool thumbnail = false,
  }) => call(
    () => MessengerRuntime.instance.client.messenger.getAttachmentUrl(
      mxcUrl: mxcUrl,
      thumbnail: thumbnail,
    ),
  );
  Future<CrmCompanyDetails> company(int id) =>
      call(() => endpoint.getCompany(id));
  Future<List<CrmCompanyView>> companies(int spaceId, {int? cursor}) =>
      call(() => endpoint.listCompanies(spaceId, limit: 100, cursor: cursor));
  Future<List<CrmUserView>> assignableUsers(int space, int segment) =>
      call(() => endpoint.getAssignableUsers(space, segment));
  Future<List<CrmCompanyView>> searchCompanies(int space, String text) async {
    final result =
        jsonDecode(
              await call(
                () => endpoint.search(
                  space,
                  text,
                  limit: 100,
                  types: [CrmEntityKind.company],
                ),
              ),
            )
            as Map;
    return (result['companies'] as List)
        .map(
          (e) => CrmCompanyView.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<Map<String, dynamic>> proposalStatus(int id) async =>
      Map<String, dynamic>.from(
        jsonDecode(await call(() => endpoint.getProposalStatus(id))) as Map,
      );

  Future<CrmChangesetView> activity(Map<String, dynamic> payload, String key) =>
      call(
        () => endpoint.addActivity(
          payload['spaceId'] as int,
          jsonEncode(payload['fields']),
          idempotencyKey: key,
          nextStepJson: jsonEncode(payload['nextStep']),
          dealVersion: payload['dealVersion'] as int,
        ),
      );
}
