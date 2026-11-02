import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart'
    show CrmAccessDenied;
import '../i18n/generated/nsg_l10n.dart';
import 'crm_room_controller.dart';
import 'crm_format.dart';
import 'crm_components.dart';

/// Styles the server text without reconstructing a diff from business objects.
class CrmProposalCard extends StatefulWidget {
  const CrmProposalCard({
    super.key,
    required this.proposalId,
    required this.body,
    required this.eventId,
    required this.readStatus,
    required this.reply,
    this.room,
    this.textColor,
  });
  final int proposalId;
  final String body;
  final String eventId;
  final Future<Map<String, dynamic>> Function(int) readStatus;
  final Future<void> Function(String, String) reply;
  final CrmRoomController? room;
  final Color? textColor;
  @override
  State<CrmProposalCard> createState() => _CrmProposalCardState();
}

class _CrmProposalCardState extends State<CrmProposalCard> {
  String? _status;
  DateTime? _expiresAt;
  int _generation = 0, _revision = 0;
  Timer? _debounce;
  bool _sending = false;
  bool _accessDenied = false;
  late CrmRoomController _room;
  late bool _ownsRoom;
  late CrmLiveRefresh _live;
  static const _final = {
    'applied',
    'rejected',
    'stale',
    'superseded',
    'expired',
  };
  @override
  void initState() {
    super.initState();
    _room = widget.room ?? CrmRoomController();
    _ownsRoom = widget.room == null;
    _revision = _room.revision;
    _room.addListener(_changed);
    _live = CrmLiveRefresh(_refresh);
    unawaited(_refresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _live.update(
      visible:
          TickerMode.valuesOf(context).enabled &&
          (ModalRoute.of(context)?.isCurrent ?? true),
    );
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    if (_revision != _room.revision) {
      _revision = _room.revision;
      if (!_final.contains(_status)) {
        _debounce?.cancel();
        _debounce = Timer(
          const Duration(milliseconds: 300),
          () => unawaited(_refresh()),
        );
      }
    }
  }

  @override
  void didUpdateWidget(CrmProposalCard old) {
    super.didUpdateWidget(old);
    if (old.room != widget.room) {
      _room.removeListener(_changed);
      if (_ownsRoom) _room.dispose();
      _room = widget.room ?? CrmRoomController();
      _ownsRoom = widget.room == null;
      _revision = _room.revision;
      _room.addListener(_changed);
    }
    if (old.proposalId != widget.proposalId || old.eventId != widget.eventId) {
      _debounce?.cancel();
      ++_generation;
      _expiresAt = null;
      _status = null;
      _accessDenied = false;
      _sending = false;
      _live.update(terminal: false);
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    final generation = ++_generation;
    try {
      final j = await widget.readStatus(widget.proposalId);
      if (mounted && generation == _generation) {
        setState(() {
          _accessDenied = false;
          _status = j['status'] as String?;
          _expiresAt = DateTime.tryParse(j['expiresAt']?.toString() ?? '');
        });
        if (_final.contains(_status)) _debounce?.cancel();
        _live.update(terminal: _final.contains(_status));
      }
    } on CrmAccessDenied {
      if (mounted && generation == _generation) {
        _debounce?.cancel();
        setState(() => _accessDenied = true);
        // Access may return after a room event or re-entry; do not poll a denial.
        _live.update(terminal: true);
      }
    } catch (_) {
      // Network failure must not forget a sent reply or a final status.
    }
  }

  Future<void> _reply(String text) async {
    if (_accessDenied ||
        _sending ||
        _status != 'proposed' ||
        !_room.beginReply(widget.proposalId)) {
      return;
    }
    final proposalId = widget.proposalId;
    final eventId = widget.eventId;
    final room = _room;
    setState(() => _sending = true);
    try {
      await widget.reply(text, eventId);
      if (mounted && widget.proposalId == proposalId && _room == room) {
        await _refresh();
      }
    } catch (_) {
      room.replyFailed(proposalId);
      if (mounted && widget.proposalId == proposalId && _room == room) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(NsgL10n.of(context).crmUnavailable)),
        );
      }
    } finally {
      if (mounted && widget.proposalId == proposalId && _room == room) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  void dispose() {
    ++_generation;
    _debounce?.cancel();
    _live.dispose();
    _room.removeListener(_changed);
    if (_ownsRoom) _room.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final ink = CrmGlassCard.ink(context);
    final lines = widget.body.split('\n');
    final status = _accessDenied
        ? l.crmDenied
        : switch (_status) {
            'proposed' => l.crmProposed,
            'applied' => l.crmApplied,
            'rejected' => l.crmRejected,
            'stale' => l.crmStale,
            'superseded' => l.crmSuperseded,
            'expired' => l.crmExpired,
            _ => l.crmUnavailable,
          };
    return CrmGlassCard(
      inverse: true,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: ink),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.crmProposalTitle(widget.proposalId).toUpperCase(),
              style: TextStyle(
                color: ink,
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final line in lines.take(lines.length - 1))
              _serverLine(line, ink),
            Divider(color: ink.withValues(alpha: .12)),
            // The renderer owns the final confirmation copy as well as the diff.
            _serverLine(lines.last, ink),
            if (!_accessDenied && _expiresAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l.crmExpiresAt(crmDate(context, _expiresAt!))),
              ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ink.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(status, style: TextStyle(color: ink, fontSize: 12)),
            ),
            if (!_accessDenied &&
                _status == 'proposed' &&
                _room.answered(widget.proposalId))
              Text(l.crmReplySent),
            if (!_accessDenied &&
                _status == 'proposed' &&
                !_room.answered(widget.proposalId))
              Wrap(
                spacing: 8,
                children: [
                  CrmPill(
                    inverse: true,
                    height: 44,
                    tone: CrmPillTone.dark,
                    onPressed: _sending ? null : () => _reply('да'),
                    child: Text(l.crmYes),
                  ),
                  CrmPill(
                    inverse: true,
                    height: 44,
                    tone: CrmPillTone.outline,
                    onPressed: _sending ? null : () => _reply('нет'),
                    child: Text(l.crmNo),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _serverLine(String line, Color ink) {
    final arrow = line.indexOf(' → '), colon = line.indexOf(': ');
    if (arrow < 0 || colon < 0 || colon >= arrow) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: SelectableText(
          line,
          style: TextStyle(
            color: ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              line.substring(0, colon),
              style: TextStyle(
                fontSize: 13.5,
                color: ink.withValues(alpha: .7),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText.rich(
              TextSpan(
                style: TextStyle(color: ink, fontSize: 13.5),
                children: _line(line).skip(1).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _line(String line) {
    final arrow = line.indexOf(' → ');
    final colon = line.indexOf(': ');
    if (arrow < 0 || colon < 0 || colon >= arrow) return [TextSpan(text: line)];
    return [
      TextSpan(text: line.substring(0, colon + 2)),
      TextSpan(
        text: line.substring(colon + 2, arrow),
        style: const TextStyle(decoration: TextDecoration.lineThrough),
      ),
      const TextSpan(text: ' → '),
      TextSpan(
        text: line.substring(arrow + 3),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ];
  }
}
