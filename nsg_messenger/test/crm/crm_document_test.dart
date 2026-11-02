import 'package:nsg_messenger/src/crm/crm_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/crm/crm_detail_screen.dart';
import 'package:nsg_messenger/src/crm/crm_rpc.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'crm_screens_test.dart' show FakeCrm, host;

class FileRpc extends CrmRpc {
  FileRpc() : super(FakeCrm(), authRetry: false);
  final calls = <(String, bool)>[];
  Object? error;
  @override
  Future<AttachmentUrl> attachmentUrl(
    String mxcUrl, {
    bool thumbnail = false,
  }) async {
    calls.add((mxcUrl, thumbnail));
    if (error != null) throw error!;
    return AttachmentUrl(
      url: 'https://files.test/temporary',
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      contentType: 'application/pdf',
    );
  }
}

class Launcher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  @override
  LinkDelegate? get linkDelegate => null;
  final urls = <String>[];
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(url);
    return true;
  }
}

CrmDocumentView document({String? url, String? mimeType = 'application/pdf'}) =>
    CrmDocumentView(
      id: 1,
      segmentId: 1,
      version: 1,
      kind: CrmDocumentKind.other,
      title: 'Тестовый документ',
      url: url,
      mxcUrl: url == null ? 'mxc://test/file' : null,
      mimeType: mimeType,
      originalFilename: 'fixture.pdf',
      sizeBytes: 3,
    );
void main() {
  late UrlLauncherPlatform previous;
  late Launcher launcher;
  setUp(() {
    previous = UrlLauncherPlatform.instance;
    launcher = Launcher();
    UrlLauncherPlatform.instance = launcher;
  });
  tearDown(() => UrlLauncherPlatform.instance = previous);
  for (final url in [
    'javascript:alert(1)',
    'file:///tmp/test',
    'data:text/html,test',
    'chatista://crm/deal/1',
  ]) {
    testWidgets('unsupported document URL is visible text only: $url', (
      t,
    ) async {
      final rpc = FileRpc();
      await t.pumpWidget(
        host(
          CrmDocumentTile(
            document: document(url: url).copyWith(originalFilename: null),
            rpc: rpc,
          ),
        ),
      );
      expect(find.text(url), findsOneWidget);
      expect(t.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
      expect(t.widget<CrmFlatRow>(find.byType(CrmFlatRow)).onTap, isNull);
      expect(launcher.urls, isEmpty);
      expect(rpc.calls, isEmpty);
    });
  }
  testWidgets(
    'file open obtains current authorized URL; link does not call attachment RPC',
    (t) async {
      final rpc = FileRpc();
      await t.pumpWidget(host(CrmDocumentTile(document: document(), rpc: rpc)));
      await t.tap(find.byIcon(Icons.open_in_new));
      await t.pumpAndSettle();
      expect(rpc.calls, [('mxc://test/file', false)]);
      expect(launcher.urls, ['https://files.test/temporary']);
      await t.pumpWidget(
        host(
          CrmDocumentTile(
            document: document(url: 'https://example.test/document'),
            rpc: rpc,
          ),
        ),
      );
      await t.tap(find.byIcon(Icons.open_in_new));
      await t.pumpAndSettle();
      expect(rpc.calls, hasLength(1));
      expect(launcher.urls.last, 'https://example.test/document');
    },
  );
  testWidgets('denial does not launch or expose attachment identifiers', (
    t,
  ) async {
    final rpc = FileRpc()
      ..error = AttachmentAccessDeniedException(mxcUrl: 'mxc://test/file');
    await t.pumpWidget(host(CrmDocumentTile(document: document(), rpc: rpc)));
    await t.tap(find.byIcon(Icons.open_in_new));
    await t.pumpAndSettle();
    expect(launcher.urls, isEmpty);
    expect(find.textContaining('mxc://'), findsNothing);
    expect(find.text('Нет доступа'), findsOneWidget);
  });
  testWidgets(
    'image requests optional thumbnail; unavailable preview is harmless',
    (t) async {
      final rpc = FileRpc()
        ..error = ThumbnailUnavailableException(
          mxcUrl: 'mxc://test/file',
          reason: 'none',
        );
      await t.pumpWidget(
        host(
          CrmDocumentTile(
            document: document(mimeType: 'image/png'),
            rpc: rpc,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(rpc.calls, [('mxc://test/file', true)]);
      expect(t.takeException(), isNull);
    },
  );
}
