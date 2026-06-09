import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/settings/nsg_messenger_settings.dart';

/// **TASK20-Phase2 Chunk 4**: tests для in-memory cache в
/// [NsgMessengerSettings] — TTL hit/miss + set update + invalidate.
void main() {
  group('NsgMessengerSettings', () {
    test('get(): cache miss → RPC fired; second call cache hit', () async {
      var rpcCalls = 0;
      final settings = NsgMessengerSettings.attachWithRpcs(
        getRpc: () async {
          rpcCalls++;
          return NotificationSettings(showMessagePreview: true);
        },
        setRpc: ({required bool showMessagePreview, bool? sendReadReceipts}) async {},
      );
      final first = await settings.get();
      expect(first.showMessagePreview, isTrue);
      expect(rpcCalls, 1);
      final second = await settings.get();
      expect(second.showMessagePreview, isTrue);
      expect(rpcCalls, 1, reason: 'cache hit — no extra RPC');
    });

    test('set(): RPC fired + cache updated immediately', () async {
      var setRpcCalls = 0;
      bool? setValue;
      final settings = NsgMessengerSettings.attachWithRpcs(
        getRpc: () async => NotificationSettings(showMessagePreview: true),
        setRpc: ({required bool showMessagePreview, bool? sendReadReceipts}) async {
          setRpcCalls++;
          setValue = showMessagePreview;
        },
      );
      await settings.set(showMessagePreview: false);
      expect(setRpcCalls, 1);
      expect(setValue, isFalse);
      // Cache after set — без extra RPC.
      final after = await settings.get();
      expect(after.showMessagePreview, isFalse);
    });

    test('B11: set(sendReadReceipts) прокидывается в RPC + кэш', () async {
      bool? setShow;
      bool? setReceipts;
      final settings = NsgMessengerSettings.attachWithRpcs(
        getRpc: () async => NotificationSettings(
          showMessagePreview: true,
          sendReadReceipts: true,
        ),
        setRpc: ({required bool showMessagePreview, bool? sendReadReceipts}) async {
          setShow = showMessagePreview;
          setReceipts = sendReadReceipts;
        },
      );
      await settings.set(showMessagePreview: true, sendReadReceipts: false);
      expect(setShow, isTrue);
      expect(setReceipts, isFalse);
      final after = await settings.get();
      expect(after.sendReadReceipts, isFalse, reason: 'кэш обновлён');
    });

    test('invalidate(): следующий get() дёрнет RPC', () async {
      var rpcCalls = 0;
      final settings = NsgMessengerSettings.attachWithRpcs(
        getRpc: () async {
          rpcCalls++;
          return NotificationSettings(showMessagePreview: true);
        },
        setRpc: ({required bool showMessagePreview, bool? sendReadReceipts}) async {},
      );
      await settings.get();
      await settings.get();
      expect(rpcCalls, 1);
      settings.invalidate();
      await settings.get();
      expect(rpcCalls, 2);
    });

    test('set() throw → cache не модифицируется', () async {
      final settings = NsgMessengerSettings.attachWithRpcs(
        getRpc: () async => NotificationSettings(showMessagePreview: true),
        setRpc: ({required bool showMessagePreview, bool? sendReadReceipts}) async =>
            throw StateError('network down'),
      );
      await settings.get(); // populate cache
      await expectLater(
        settings.set(showMessagePreview: false),
        throwsA(isA<StateError>()),
      );
      // Cache всё ещё true (старое значение).
      final after = await settings.get();
      expect(after.showMessagePreview, isTrue);
    });
  });
}
