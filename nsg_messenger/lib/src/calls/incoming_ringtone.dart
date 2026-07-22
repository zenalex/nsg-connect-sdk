import 'dart:async';

import 'package:flutter/services.dart';

/// **TASK46 (UI) → извлечено в TASK51 (UI)**: простой MVP-рингтон
/// входящего звонка — периодический `SystemSound.alert` + вибро, без
/// аудио-файла.
///
/// Раньше жил приватно в `CallOverlayHost`; групповому оверлею
/// (`ConferenceOverlayHost`) нужен ТОТ ЖЕ рингтон — выносим в общий
/// хелпер, чтобы не форкать механику (единая громкость/период у 1:1 и
/// конференции — пользователь не должен отличать их по звуку).
///
/// Best-effort: платформенные каналы могут быть недоступны (тесты /
/// headless) — ошибки глотаются, UI звонка из-за звука не падает.
class IncomingRingtone {
  IncomingRingtone({this.tick = const Duration(seconds: 2)});

  /// Период повторения тона (первый — сразу при [start]).
  final Duration tick;

  Timer? _timer;

  /// Играет ли рингтон сейчас.
  bool get isRinging => _timer != null;

  /// Запустить (идемпотентно: если уже играет — no-op, чтобы каждый
  /// notifyListeners не перезапускал период с нуля).
  void start() {
    if (_timer != null) return;
    _playTick();
    _timer = Timer.periodic(tick, (_) => _playTick());
  }

  /// Остановить (идемпотентно).
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _playTick() {
    unawaited(SystemSound.play(SystemSoundType.alert).catchError((_) {}));
    unawaited(HapticFeedback.mediumImpact().catchError((_) {}));
  }
}
