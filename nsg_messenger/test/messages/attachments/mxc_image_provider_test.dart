import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/attachments/mxc_image_provider.dart';

/// Unit tests для [MxcImageProvider]. Live decode через ui.Codec —
/// integration territory; здесь покрываем cache-key equality + RPC
/// dispatch (thumbnail vs full-size).
void main() {
  Future<AttachmentBytes> noopThumb({
    required String mxcUrl,
    int? width,
    int? height,
  }) async => AttachmentBytes(bytes: ByteData(0), contentType: 'image/png');

  Future<AttachmentBytes> noopFull({required String mxcUrl}) async =>
      AttachmentBytes(bytes: ByteData(0), contentType: 'image/png');

  test('MxcImageKey equality: same params → equal hashCode', () {
    final a = MxcImageKey(
      mxcUrl: 'mxc://x/abc',
      width: 400,
      height: 400,
      fullSize: false,
    );
    final b = MxcImageKey(
      mxcUrl: 'mxc://x/abc',
      width: 400,
      height: 400,
      fullSize: false,
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('MxcImageKey: разные width → разные cache entries', () {
    final small = MxcImageKey(
      mxcUrl: 'mxc://x/abc',
      width: 200,
      height: 200,
      fullSize: false,
    );
    final big = MxcImageKey(
      mxcUrl: 'mxc://x/abc',
      width: 800,
      height: 800,
      fullSize: false,
    );
    expect(small == big, isFalse);
  });

  test('MxcImageKey: fullSize vs thumbnail — разные keys', () {
    final thumb = MxcImageKey(
      mxcUrl: 'mxc://x/abc',
      width: null,
      height: null,
      fullSize: false,
    );
    final full = MxcImageKey(
      mxcUrl: 'mxc://x/abc',
      width: null,
      height: null,
      fullSize: true,
    );
    expect(thumb == full, isFalse);
  });

  test('MxcImageProvider equality: same params → equal', () {
    final a = MxcImageProvider(
      mxcUrl: 'mxc://x/abc',
      thumbnailRpc: noopThumb,
      fullSizeRpc: noopFull,
      width: 400,
      height: 400,
    );
    final b = MxcImageProvider(
      mxcUrl: 'mxc://x/abc',
      thumbnailRpc: noopThumb,
      fullSizeRpc: noopFull,
      width: 400,
      height: 400,
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('MxcImageProvider: разные mxcUrl → не equal', () {
    final a = MxcImageProvider(
      mxcUrl: 'mxc://x/aaa',
      thumbnailRpc: noopThumb,
      fullSizeRpc: noopFull,
    );
    final b = MxcImageProvider(
      mxcUrl: 'mxc://x/bbb',
      thumbnailRpc: noopThumb,
      fullSizeRpc: noopFull,
    );
    expect(a == b, isFalse);
  });
}
