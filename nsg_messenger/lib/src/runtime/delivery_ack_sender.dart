import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;

import 'app_visibility.dart';

/// Сигнатура `client.messenger.confirmDelivery` — тестам нужно подменять
/// без поднятия Serverpod.
typedef ConfirmDeliveryFn =
    Future<void> Function({required List<String> matrixEventIds});

/// **Клиентская половина доставки с подтверждением (issue #78).**
///
/// Сообщение пришло в живой стрим — и если приложение в этот момент
/// действительно перед человеком, клиент говорит серверу «принял». Пуш
/// тогда не уходит НИКУДА: ни на это устройство, ни на остальные — раз
/// человек сидит за одним из своих клиентов, будить его телефон незачем.
///
/// Не подтвердил никто за отведённое окно — человек недоступен, и сервер
/// шлёт пуш на все устройства. Поэтому цена ошибки несимметрична:
/// подтвердить лишнего — значит съесть уведомление, которое человек
/// ждал; не подтвердить лишнего — значит показать лишний баннер. Отсюда
/// строгое условие ниже.
///
/// **Что считается «перед человеком».** Только [AppLifecycleState.resumed]
/// — окно на переднем плане и в фокусе. Свёрнутое (`hidden`),
/// расфокусированное (`inactive`, человек ушёл в браузер) и фоновое
/// (`paused`) не подтверждают: приложение работает, но сообщение никто
/// не видит. Расфокусированный десктоп — самый частый случай, и именно
/// в нём уведомление на телефон нужно. Спрятанное в трей окно Flutter
/// активным считать продолжает — эту дыру закрывает [AppVisibility].
///
/// Подтверждения копятся и уходят пачкой: в живом чате события идут
/// очередями, и RPC на каждое — лишний трафик на ровном месте.
class DeliveryAckSender {
  DeliveryAckSender({
    required ConfirmDeliveryFn? confirmDelivery,
    Duration? debounce,
    AppLifecycleState Function()? lifecycleProbe,
    void Function(Object error, StackTrace stack)? onError,
  }) : _confirmDelivery = confirmDelivery,
       _debounce = debounce ?? defaultDebounce,
       _lifecycleProbe = lifecycleProbe,
       _onError = onError;

  /// Окно накопления. Десятые доли секунды человеку незаметны, а
  /// серверное окно подтверждения — секунды; при этом очередь из десятка
  /// событий схлопывается в один вызов.
  static const Duration defaultDebounce = Duration(milliseconds: 150);

  /// Больше за раз сервер и не примет (см. `confirmDelivery`).
  static const int maxBatch = 200;

  final ConfirmDeliveryFn? _confirmDelivery;
  final Duration _debounce;
  final AppLifecycleState Function()? _lifecycleProbe;
  final void Function(Object error, StackTrace stack)? _onError;

  final Set<String> _queue = <String>{};
  Timer? _timer;
  bool _disposed = false;

  /// Подтверждает ли клиент доставку прямо сейчас.
  ///
  /// Спрятанное в трей окно тоже НЕ подтверждает, хотя Flutter считает
  /// приложение активным (см. [AppVisibility]).
  bool get isActive {
    final probe = _lifecycleProbe;
    if (probe != null) return probe() == AppLifecycleState.resumed;
    return AppVisibility.isActive;
  }

  /// Сообщение принято живым клиентом. Подтверждение уйдёт пачкой через
  /// [defaultDebounce], если приложение перед человеком.
  void noteDelivered(String matrixEventId) {
    if (_disposed || matrixEventId.isEmpty) return;
    if (_confirmDelivery == null) return;
    // Проверяем состояние здесь, а не при отправке: важно, видел ли
    // человек сообщение в момент прихода. Успел свернуть окно за
    // следующие 150 мс — он его всё равно увидел.
    if (!isActive) return;
    _queue.add(matrixEventId);
    if (_queue.length >= maxBatch) {
      _flush();
      return;
    }
    _timer ??= Timer(_debounce, _flush);
  }

  /// Отправить накопленное немедленно (тесты; закрытие приложения).
  void flushNow() => _flush();

  void _flush() {
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty) return;
    final batch = _queue.toList(growable: false);
    _queue.clear();
    final fn = _confirmDelivery;
    if (fn == null) return;
    // Fire-and-forget: не дошло — сервер сочтёт человека недоступным и
    // пришлёт пуш. Это безопасная сторона ошибки, ретраить нечего.
    unawaited(
      fn(matrixEventIds: batch).catchError((Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('[DeliveryAckSender] confirmDelivery failed: $e');
        }
        _onError?.call(e, st);
      }),
    );
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _queue.clear();
  }
}
