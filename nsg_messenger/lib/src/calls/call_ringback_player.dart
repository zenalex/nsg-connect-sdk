import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// **Ringback (обратный сигнал каллеру)**: стадия «гудка» исходящего звонка.
/// Overlay выбирает тон по [CallOutgoingRinging.reachedPeer]
/// (см. `call_ringback_player.dart` usage в `call_overlay_host.dart`).
enum CallRingbackTone {
  /// Стадия 1 «дозвон до сервера» — короткий двойной блип (invite ещё не
  /// доставлен). Ассет `ringback_connecting.wav`.
  connecting,

  /// Стадия 2 «звонит на устройстве» — классический ringback-гудок в петле
  /// (invite доставлен). Ассет `ringback_ringing.wav`.
  ringing,
}

/// Плеер ringback-тонов исходящего звонка. Вынесен за интерфейс, чтобы
/// overlay-тесты подменяли его fake-ом (реальный [JustAudioRingbackPlayer]
/// дёргает платформенные аудио-каналы — в unit/widget тестах не нужен).
///
/// Контракт: [play] зацикливает переданный тон (сменяя предыдущий), [stop]
/// глушит. Всё best-effort — ошибки платформы НЕ должны ронять UI звонка.
abstract class CallRingbackPlayer {
  /// Проиграть (в петле) [tone], сменив текущий. Идемпотентно для того же
  /// тона (повторный вызов с тем же значением — no-op).
  Future<void> play(CallRingbackTone tone);

  /// Заглушить ringback.
  Future<void> stop();

  /// Освободить ресурсы плеера.
  Future<void> dispose();
}

/// Продакшн-реализация [CallRingbackPlayer] поверх `just_audio` (уже в
/// зависимостях SDK — используется для воспроизведения голосовых сообщений).
///
/// Ассеты пакета грузятся по полному ключу `packages/nsg_messenger/...`
/// (так Flutter бандлит объявленные в pubspec ассеты пакета; host-app их
/// получает автоматически, отдельно объявлять не нужно). Петля —
/// `LoopMode.one`; тишина «вшита» в конец WAV → стык петли попадает в
/// тишину (без щелчка).
///
/// **Best-effort по платформам**: `just_audio` покрывает iOS/Android/web/
/// macOS — основные цели звонков. На платформах без backend (Windows/Linux
/// без desktop-плагина, как и текущее воспроизведение голосовых) вызовы
/// бросают — ловим и глушим, UI звонка не страдает.
class JustAudioRingbackPlayer implements CallRingbackPlayer {
  JustAudioRingbackPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  static const Map<CallRingbackTone, String> _assets = {
    CallRingbackTone.connecting:
        'packages/nsg_messenger/assets/audio/ringback_connecting.wav',
    CallRingbackTone.ringing:
        'packages/nsg_messenger/assets/audio/ringback_ringing.wav',
  };

  /// Громкость ringback — чуть тише полной (комфортно, не «в ухо»).
  static const double _volume = 0.6;

  CallRingbackTone? _current;
  bool _disposed = false;

  @override
  Future<void> play(CallRingbackTone tone) async {
    if (_disposed) return;
    if (_current == tone) return; // этот тон уже играет
    _current = tone;
    try {
      await _player.setAsset(_assets[tone]!);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(_volume);
      // НЕ await: при LoopMode.one play() не завершается (петля бесконечна).
      unawaited(_player.play());
    } catch (e) {
      if (kDebugMode) debugPrint('[Ringback] play($tone) failed: $e');
      // best-effort — платформа без backend / ассет недоступен.
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    if (_current == null) return;
    _current = null;
    try {
      await _player.stop();
    } catch (e) {
      if (kDebugMode) debugPrint('[Ringback] stop failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _player.dispose();
    } catch (_) {
      // Освобождение best-effort.
    }
  }
}
