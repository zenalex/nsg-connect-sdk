import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../i18n/generated/nsg_l10n.dart';
import 'attachment_picker.dart';

/// Перетаскивание файлов из проводника в чат (просьба пользователей,
/// 2026-08-03).
///
/// **Зона броска — весь экран чата, а не композер.** Человек тащит файл в
/// окно, а не целится в узкую полоску над клавиатурой; попадание мимо
/// маленькой цели читается как «не работает». Поэтому цель ставит
/// `ChatScreen` вокруг всего тела, а композер лишь подписывается на неё
/// через [AttachmentDropSink].
///
/// Desktop и web (#222). На вебе `desktop_drop` сам гасит браузерную
/// обработку броска (иначе браузер открыл бы файл во вкладке) и отдаёт
/// файлы blob-ссылками — сборщик читает их тем же `XFile(path)`. На
/// мобильных перетаскивать неоткуда.
bool get attachmentDropSupported =>
    kIsWeb ||
    switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux => true,
      _ => false,
    };

/// Связь «цель броска → композер». Цель живёт в [ChatScreen], а решение, что
/// делать с файлами, принадлежит композеру: только он знает, сколько ещё
/// влезет в черновик, включён ли он и куда показывать снекбар.
///
/// Отдельный объект, а не `GlobalKey` на состояние композера: ключ открыл бы
/// наружу всё состояние ради одного колбэка, а composer пересоздаётся при
/// каждой перестройке ленты.
class AttachmentDropSink {
  /// Ставится композером на время его жизни. `null` — композера нет
  /// (экран ещё строится, чат только для чтения) → бросок молча
  /// игнорируется: показывать «не могу» на пустом месте незачем.
  /// Возвращает Future намеренно: приём файла — это чтение с диска, и без
  /// возможности его дождаться тест ловил бы черновик до того, как он
  /// наполнился, а цель броска не смогла бы отличить «принято» от «начато».
  Future<void> Function(List<AttachmentCandidate> files)? onFiles;

  bool get ready => onFiles != null;
}

/// Обёртка над телом чата: подсвечивает область при наведении файла и
/// передаёт брошенное в [sink].
class AttachmentDropTarget extends StatefulWidget {
  const AttachmentDropTarget({
    super.key,
    required this.sink,
    required this.child,
  });

  final AttachmentDropSink sink;
  final Widget child;

  @override
  State<AttachmentDropTarget> createState() => _AttachmentDropTargetState();
}

class _AttachmentDropTargetState extends State<AttachmentDropTarget> {
  bool _dragging = false;

  /// Метка на всём теле чата: по ней проверяем, что точка броска приходится
  /// именно на ЭТОТ экран (см. [_isHitAt]).
  final _hitKey = GlobalKey();

  /// #225: открытые чаты живут друг под другом (keep-alive в `IndexedStack`
  /// на телефоне-раскладке, `Offstage`-панели в десктопном воркспейсе). У
  /// невидимых та же геометрия, а `desktop_drop` проверяет лишь, что точка
  /// внутри границ цели, — поэтому брошенный файл попадал в черновики ВСЕХ
  /// открытых чатов. Hit-test честно учитывает видимость: скрытые экраны в
  /// него не попадают, а в раскладке «бок о бок» попадает только панель под
  /// курсором.
  bool _isHitAt(Offset globalPosition) {
    final target = _hitKey.currentContext?.findRenderObject();
    if (target == null || !mounted) return false;
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(
      result,
      globalPosition,
      View.of(context).viewId,
    );
    return result.path.any((e) => identical(e.target, target));
  }

  @override
  Widget build(BuildContext context) {
    if (!attachmentDropSupported) return widget.child;
    return DropTarget(
      onDragEntered: (detail) {
        // Подсветку показываем, даже когда композер не готов принять файлы:
        // человеку важно понять, что окно вообще реагирует на перетаскивание.
        // Отказ (если он случится) он увидит уже по факту броска.
        if (!_isHitAt(detail.globalPosition)) return;
        if (mounted) setState(() => _dragging = true);
      },
      onDragExited: (_) {
        if (mounted) setState(() => _dragging = false);
      },
      onDragDone: (detail) async {
        if (mounted) setState(() => _dragging = false);
        if (!_isHitAt(detail.globalPosition)) return;
        final handler = widget.sink.onFiles;
        if (handler == null) return;
        // Размер спрашиваем ЗДЕСЬ, до передачи в общий сборщик: тот отвергает
        // слишком большое ДО чтения байтов, и в этом весь смысл — иначе
        // брошенный на чат фильм сначала целиком приехал бы в память.
        final files = <AttachmentCandidate>[];
        for (final f in detail.files) {
          int size;
          try {
            size = await f.length();
          } catch (_) {
            // Файл исчез между броском и опросом. Пропускаем: сборщик всё
            // равно не смог бы его прочитать.
            continue;
          }
          files.add(
            AttachmentCandidate(name: f.name, size: size, path: f.path),
          );
        }
        if (files.isEmpty) return;
        await handler(files);
      },
      child: Stack(
        children: [
          // Прозрачная для касаний метка: попадает в hit-test, только когда
          // экран действительно на виду, и ничего не перехватывает.
          Listener(
            key: _hitKey,
            behavior: HitTestBehavior.translucent,
            child: widget.child,
          ),
          if (_dragging)
            Positioned.fill(
              child: IgnorePointer(
                child: _DropOverlay(ready: widget.sink.ready),
              ),
            ),
        ],
      ),
    );
  }
}

class _DropOverlay extends StatelessWidget {
  const _DropOverlay({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = NsgL10n.of(context);
    final color = ready ? theme.colorScheme.primary : theme.disabledColor;
    return Container(
      key: const Key('attachmentDropOverlay'),
      color: color.withValues(alpha: 0.10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.file_download_outlined, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                l.attachmentDropHint,
                style: theme.textTheme.titleMedium?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
