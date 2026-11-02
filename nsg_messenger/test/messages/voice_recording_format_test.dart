import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/messages/voice_recording_format.dart';
import 'package:record/record.dart';

void main() {
  test('web recording never requests a native temporary path', () async {
    const format = VoiceRecordingFormat(isWeb: true);
    final path = await format.recordingPath(
      () => throw StateError('No path_provider in a browser'),
    );
    expect(path, isEmpty);
    expect(format.config.encoder, AudioEncoder.opus);
    expect(format.mimeType, 'audio/webm');
    expect(format.extension, 'webm');
  });

  test(
    'native recording keeps its AAC file path and attachment format',
    () async {
      const format = VoiceRecordingFormat(isWeb: false);
      var requests = 0;
      final path = await format.recordingPath(() async {
        requests++;
        return '/tmp/nsg_voice_123.m4a';
      });
      expect(requests, 1);
      expect(path, '/tmp/nsg_voice_123.m4a');
      expect(format.config.encoder, const RecordConfig().encoder);
      expect(format.mimeType, 'audio/mp4');
      expect(format.extension, 'm4a');
    },
  );
}
