import 'package:record/record.dart';

/// Browser recorders return a blob URL; native recorders need a temporary file.
class VoiceRecordingFormat {
  const VoiceRecordingFormat({required this.isWeb});

  final bool isWeb;

  RecordConfig get config => isWeb
      ? const RecordConfig(encoder: AudioEncoder.opus)
      : const RecordConfig();

  String get mimeType => isWeb ? 'audio/webm' : 'audio/mp4';
  String get extension => isWeb ? 'webm' : 'm4a';

  /// Keep the native path provider lazy: it is unavailable in a browser.
  Future<String> recordingPath(Future<String> Function() nativePath) async =>
      isWeb ? '' : await nativePath();
}
