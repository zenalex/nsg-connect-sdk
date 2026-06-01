import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

/// **TASK22-Phase2 Chunk 1-B**: unit tests для [NsgMessengerConfig] +
/// [NsgScrollThresholds]. Проверяем дефолты и custom-конструкцию.
void main() {
  group('NsgMessengerConfig.fallback', () {
    test('exposes default scroll thresholds (200/200)', () {
      const cfg = NsgMessengerConfig.fallback;
      expect(cfg.scrollThresholds.chatLoadMorePx, 200);
      expect(cfg.scrollThresholds.chatsListLoadMorePx, 200);
    });
  });

  group('NsgScrollThresholds', () {
    test('default constructor uses 200/200', () {
      const t = NsgScrollThresholds();
      expect(t.chatLoadMorePx, 200);
      expect(t.chatsListLoadMorePx, 200);
    });

    test('partial override keeps other field at default', () {
      const t = NsgScrollThresholds(chatLoadMorePx: 400);
      expect(t.chatLoadMorePx, 400);
      expect(t.chatsListLoadMorePx, 200);
    });
  });

  group('NsgMessengerConfig custom', () {
    test('host-app может передать кастомные thresholds', () {
      const cfg = NsgMessengerConfig(
        scrollThresholds: NsgScrollThresholds(
          chatLoadMorePx: 600,
          chatsListLoadMorePx: 350,
        ),
      );
      expect(cfg.scrollThresholds.chatLoadMorePx, 600);
      expect(cfg.scrollThresholds.chatsListLoadMorePx, 350);
    });
  });
}
