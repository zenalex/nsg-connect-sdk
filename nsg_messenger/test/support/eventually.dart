import 'package:flutter_test/flutter_test.dart';

/// Wait for an observable async transition, with a bounded failure deadline.
/// A loaded CI host need not schedule a chain of timers within 120 ms.
Future<void> eventually(bool Function() condition) async {
  final elapsed = Stopwatch()..start();
  while (!condition() && elapsed.elapsed < const Duration(seconds: 3)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(
    condition(),
    isTrue,
    reason: 'Async transition did not complete within 3 seconds',
  );
}
