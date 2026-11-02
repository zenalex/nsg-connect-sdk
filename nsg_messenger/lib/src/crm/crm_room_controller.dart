import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';

/// Room-owned state survives recycling of message bubbles.
class CrmRoomController extends ChangeNotifier {
  final Set<int> _answered = {};
  int revision = 0;
  bool answered(int id) => _answered.contains(id);
  bool beginReply(int id) {
    if (!_answered.add(id)) return false;
    notifyListeners();
    return true;
  }

  void replyFailed(int id) {
    _answered.remove(id);
    notifyListeners();
  }

  /// Ordinary chat traffic does not invalidate CRM views.
  void messageChanged(ByteData? content) {
    if (content == null) return;
    try {
      final data = jsonDecode(
        utf8.decode(
          content.buffer.asUint8List(
            content.offsetInBytes,
            content.lengthInBytes,
          ),
        ),
      );
      if (data is Map &&
          (data['app.nsg.crm_event'] is Map ||
              data['app.nsg.crm_proposal'] is Map)) {
        roomChanged();
      }
    } catch (_) {
      // Invalid message content cannot trigger a CRM refresh.
    }
  }

  void roomChanged() {
    revision++;
    notifyListeners();
  }
}

/// Events are primary; a rare fallback runs only on a visible foreground route.
class CrmLiveRefresh with WidgetsBindingObserver {
  CrmLiveRefresh(this.refresh) {
    WidgetsBinding.instance.addObserver(this);
  }
  final Future<void> Function() refresh;
  Timer? _timer;
  bool _visible = false;
  bool _terminal = false;
  bool get _foreground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  void update({bool? visible, bool? terminal}) {
    _visible = visible ?? _visible;
    _terminal = terminal ?? _terminal;
    _timer?.cancel();
    _timer = _visible && _foreground && !_terminal
        ? Timer.periodic(
            const Duration(minutes: 2),
            (_) => unawaited(refresh()),
          )
        : null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    update();
    if (state == AppLifecycleState.resumed && _visible && !_terminal) {
      unawaited(refresh());
    }
  }

  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
