import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messenger_runtime.dart';

/// Тесты раннего подключения трекера: `reportError` должен работать ДО
/// `init()` — иначе ошибки экрана входа уходят в никуда (был no-op).
class _CapturingReporter implements ErrorReporter {
  final List<Object> errors = [];
  @override
  void reportError(Object error, StackTrace? stack, {Map<String, String>? tags}) {
    errors.add(error);
  }
}

void main() {
  tearDown(() async {
    // Runtime — singleton; сбрасываем репортер между тестами, подсунув
    // «глотающий», чтобы состояние не протекало.
    NsgMessenger.configureErrorReporter(_NullReporter());
  });

  test('reportError доходит до трекера БЕЗ init() (pre-auth)', () {
    final reporter = _CapturingReporter();
    NsgMessenger.configureErrorReporter(reporter);

    MessengerRuntime.instance.reportError(StateError('login failed'), null);

    expect(reporter.errors, hasLength(1));
    expect(reporter.errors.single, isA<StateError>());
  });

  test('без подключённого репортера reportError — тихий no-op, не бросает', () {
    // Ставим null-репортер, затем убеждаемся, что вызов безопасен даже
    // если внутренний репортер бросит.
    NsgMessenger.configureErrorReporter(_ThrowingReporter());
    expect(
      () => MessengerRuntime.instance.reportError(StateError('x'), null),
      returnsNormally,
      reason: 'сбой трекера не должен ронять вызывающего',
    );
  });

  test('повторный configureErrorReporter заменяет предыдущий', () {
    final first = _CapturingReporter();
    final second = _CapturingReporter();
    NsgMessenger.configureErrorReporter(first);
    NsgMessenger.configureErrorReporter(second);

    MessengerRuntime.instance.reportError(StateError('e'), null);

    expect(first.errors, isEmpty);
    expect(second.errors, hasLength(1));
  });
}

class _NullReporter implements ErrorReporter {
  @override
  void reportError(Object error, StackTrace? stack, {Map<String, String>? tags}) {}
}

class _ThrowingReporter implements ErrorReporter {
  @override
  void reportError(Object error, StackTrace? stack, {Map<String, String>? tags}) {
    throw StateError('tracker down');
  }
}
