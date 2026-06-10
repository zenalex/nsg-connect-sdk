import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messenger_runtime.dart';

/// **TASK20 followup (a)**: тесты lifecycle observer-а на уровне
/// [MessengerRuntime].
///
/// Runtime is a singleton — между тестами обязательно делаем
/// `NsgMessenger.dispose()` (см. [tearDown]).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    try {
      await NsgMessenger.dispose();
    } catch (_) {}
  });

  test(
    'didChangeAppLifecycleState без init — no-op (bus == null, не crash-ит)',
    () {
      // Sanity-check: runtime singleton без init.
      expect(
        () => MessengerRuntime.instance.didChangeAppLifecycleState(
          AppLifecycleState.resumed,
        ),
        returnsNormally,
      );
    },
  );

  test('после initDemo + resumed lifecycle: bus.forceReconnect триггерится '
      '(connectionState остаётся healthy, без crash-а)', () async {
    await NsgMessenger.initDemo(rooms: const []);
    final initial = MessengerRuntime.instance.connectionState;
    expect(initial, MessengerConnectionState.healthy);

    // Demo-bus использует replay-stream без error-ов; resumed просто
    // дёрнет bus.onAppLifecycleChanged + bus.forceReconnect, оба
    // должны отработать без exception-ов.
    expect(
      () => MessengerRuntime.instance.didChangeAppLifecycleState(
        AppLifecycleState.resumed,
      ),
      returnsNormally,
    );

    // Pump pending microtasks — forceReconnect внутри cancels prev sub
    // + re-subscribes. State не меняется (никаких error-ов), но и не
    // throw-ит.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(
      MessengerRuntime.instance.connectionState,
      MessengerConnectionState.healthy,
    );
  });

  test(
    'paused lifecycle: forwards to bus.onAppLifecycleChanged без crash-а',
    () async {
      await NsgMessenger.initDemo(rooms: const []);
      expect(
        () => MessengerRuntime.instance.didChangeAppLifecycleState(
          AppLifecycleState.paused,
        ),
        returnsNormally,
      );
      // resume назад чтобы tearDown с чистым state.
      MessengerRuntime.instance.didChangeAppLifecycleState(
        AppLifecycleState.resumed,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    },
  );
}
