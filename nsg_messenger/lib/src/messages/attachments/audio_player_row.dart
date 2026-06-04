import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:path_provider/path_provider.dart';

import 'mxc_image_provider.dart';

/// **B-voice**: render `m.audio` attachment в bubble (voice message
/// playback). Play/pause button + linear progress + duration timeline.
///
/// Поведение:
///   * Idle (до first tap) — кнопка Icons.play_arrow + duration из
///     `attachment.durationMs` (если null — рендерим `--:--`).
///   * On tap play:
///     1. Если bytes ещё не загружены — `fullSizeRpc(mxcUrl)` →
///        записываем в temp file → `AudioPlayer.setFilePath`.
///        Spinner показывается во время download.
///        Bytes cache-ятся per-instance (повторное play не качает).
///     2. Once loaded — `player.play()`. Подписка на positionStream
///        обновляет progress bar.
///   * On tap pause во время play — `player.pause()`.
///   * On end-of-playback — auto-reset на position=0 (для replay).
///
/// **Disposal**: cancel listeners + dispose player в `dispose()`.
/// Temp file удаляется тоже (без блокировки на errors).
///
/// **Why temp file а не StreamAudioSource**: just_audio 0.9.x не имеет
/// готового BytesSource; StreamAudioSource требует subclass-а с
/// implementation of byte-range protocol. Temp file даёт cross-platform
/// поведение без bridge-кода — bytes пишутся один раз, файл живёт до
/// dispose-а.
class AudioPlayerRow extends StatefulWidget {
  const AudioPlayerRow({
    super.key,
    required this.attachment,
    required this.fullSizeRpc,
    required this.textColor,
  });

  final AttachmentRef attachment;
  final DownloadAttachmentRpc fullSizeRpc;
  final Color textColor;

  @override
  State<AudioPlayerRow> createState() => _AudioPlayerRowState();
}

class _AudioPlayerRowState extends State<AudioPlayerRow> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration?>? _durationSub;

  bool _loading = false;
  bool _loaded = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration? _totalDuration;
  File? _tempFile;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    final ms = widget.attachment.durationMs;
    if (ms != null && ms > 0) {
      _totalDuration = Duration(milliseconds: ms);
    }
    _positionSub = _player.positionStream.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _stateSub = _player.playerStateStream.listen((s) {
      if (!mounted) return;
      // ProcessingState.completed → playback кончился. Reset position
      // и stop — UI снова показывает play icon.
      if (s.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      } else {
        setState(() => _playing = s.playing);
      }
    });
    _durationSub = _player.durationStream.listen((d) {
      if (!mounted || d == null) return;
      setState(() => _totalDuration = d);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    // Best-effort cleanup temp file; не блокируем dispose на ошибке IO.
    final f = _tempFile;
    if (f != null) {
      f.delete().catchError((_) => f); // ignore errors
    }
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_loading) return;
    if (_loadError != null) {
      // Retry: чистим error, повторяем load.
      setState(() => _loadError = null);
    }
    if (!_loaded) {
      await _loadAndPlay();
      return;
    }
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _loadAndPlay() async {
    setState(() => _loading = true);
    try {
      final result = await widget.fullSizeRpc(mxcUrl: widget.attachment.mxcUrl);
      final bytes = result.bytes.buffer.asUint8List(
        result.bytes.offsetInBytes,
        result.bytes.lengthInBytes,
      );
      // Сохраняем в temp file — just_audio 0.9.x не имеет встроенного
      // BytesSource, file path работает на всех платформах.
      final dir = await getTemporaryDirectory();
      final ext = _extensionForMime(widget.attachment.mimeType);
      final f = File(
        '${dir.path}/nsg_voice_${DateTime.now().microsecondsSinceEpoch}$ext',
      );
      await f.writeAsBytes(bytes, flush: true);
      _tempFile = f;
      await _player.setFilePath(f.path);
      _loaded = true;
      if (!mounted) return;
      await _player.play();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _extensionForMime(String mime) {
    if (mime.contains('mp4') || mime.contains('m4a') || mime.contains('aac')) {
      return '.m4a';
    }
    if (mime.contains('mpeg')) return '.mp3';
    if (mime.contains('ogg')) return '.ogg';
    if (mime.contains('webm')) return '.webm';
    if (mime.contains('wav')) return '.wav';
    return '.bin';
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.textColor;
    final total = _totalDuration;
    final progress = (total != null && total.inMilliseconds > 0)
        ? (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final IconData icon;
    if (_loadError != null) {
      icon = Icons.refresh;
    } else if (_playing) {
      icon = Icons.pause;
    } else {
      icon = Icons.play_arrow;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: _loading
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accent.withValues(alpha: 0.85),
                      ),
                    )
                  : IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 28,
                      icon: Icon(icon, color: accent),
                      onPressed: _onTap,
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: accent.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDuration(_position)} / '
                    '${total != null ? _formatDuration(total) : "--:--"}',
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
