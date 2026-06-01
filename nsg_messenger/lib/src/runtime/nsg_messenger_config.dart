import 'package:flutter/foundation.dart';

/// **TASK22-Phase2 Chunk 1-B**: runtime-tunable behavior knobs for SDK
/// widgets (scroll thresholds, pagination sizes, etc).
///
/// Different axis from [NsgMessengerTheme] — config = behavior, theme =
/// visual styling. Host-app may want default scroll behavior + custom
/// theme, or vice versa.
///
/// Storage: singleton on [MessengerRuntime.instance.config], populated
/// at `NsgMessenger.init(config: ...)`. Init-time set, runtime read-only.
/// Customer who wants to change config dynamically — re-init runtime
/// (rare; for MVP overkill).
@immutable
class NsgMessengerConfig {
  const NsgMessengerConfig({
    this.scrollThresholds = const NsgScrollThresholds(),
  });

  final NsgScrollThresholds scrollThresholds;

  /// Default config — values that work reasonably on phone / tablet /
  /// web without customization.
  static const NsgMessengerConfig fallback = NsgMessengerConfig();
}

/// Pagination prefetch thresholds — расстояние в пикселях до edge'а
/// scroll-view, при котором SDK триггерит fetch-next-page.
///
/// Меньшее значение = меньше prefetch overhead но видимая jank-пауза
/// в конце списка. Большее = плавнее scroll, больше network.
///
/// **Tuning hints для host-app**:
///   * Маленькие экраны (phone) — оставить default 200.
///   * Tablet / desktop с длинным viewport — поднять до 400-600
///     (раньше начинать prefetch, чтобы успеть к моменту когда user
///     долистает).
///   * Slow network — увеличить, даже на phone.
@immutable
class NsgScrollThresholds {
  const NsgScrollThresholds({
    this.chatLoadMorePx = 200,
    this.chatsListLoadMorePx = 200,
  });

  /// ChatScreen — расстояние до bottom-edge (DESC scroll) для load-older.
  final double chatLoadMorePx;

  /// ChatsListScreen — расстояние до bottom-edge для load-more rooms.
  final double chatsListLoadMorePx;
}
