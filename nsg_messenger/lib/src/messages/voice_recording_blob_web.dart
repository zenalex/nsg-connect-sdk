import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<Uint8List> readVoiceRecordingBlob(String url) async {
  if (!url.startsWith('blob:')) {
    throw ArgumentError('Expected a local voice recording blob URL');
  }
  final response = await web.window.fetch(url.toJS).toDart;
  if (!response.ok) throw StateError('Could not read voice recording blob');
  return (await response.arrayBuffer().toDart).toDart.asUint8List();
}

void releaseVoiceRecordingBlob(String url) {
  if (url.startsWith('blob:')) web.URL.revokeObjectURL(url);
}
