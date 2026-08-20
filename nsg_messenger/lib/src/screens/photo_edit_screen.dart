/// **Редактор фото перед отправкой** (issue #103): обрезка, поворот и кисть.
///
/// Запрос владельца со слов пользователей: «при вставке фото перед отправкой
/// тоже иметь возможность её отредактировать — обрезка, написать что-то,
/// подчеркнуть, типа так сделано в телеграме».
///
/// Просят не украшательство. Люди шлют скриншоты, и чаще всего надо **обвести
/// проблемное место**: до этого приходилось либо объяснять словами, либо
/// уходить редактировать во внешнюю программу и возвращаться.
///
/// **Правки необратимы**: отправляется плоская картинка, как в Телеграме.
/// Хранить слои значило бы завести свой формат и вечно его тащить — ради
/// возможности, которой почти не пользуются.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../i18n/generated/nsg_l10n.dart';
import 'avatar_crop_screen.dart' show mimeOfImageBytes;

/// Пометка поверх фото. Точки — в НОРМИРОВАННЫХ координатах картинки (0..1),
/// а не в координатах экрана.
///
/// Иначе пометка «уезжала» бы при любом изменении размера: поворот экрана,
/// открытие клавиатуры, другое устройство. Нормированные переживают всё, и
/// сведение в файл считается от них умножением на реальный размер.
@immutable
sealed class PhotoAnnotation {
  const PhotoAnnotation({required this.color});

  final Color color;
}

/// Свободная линия — ей обводят проблемное место.
@immutable
class BrushStroke extends PhotoAnnotation {
  const BrushStroke({
    required this.points,
    required super.color,
    required this.width,
  });

  final List<Offset> points;

  /// Толщина в долях МЕНЬШЕЙ стороны картинки — чтобы линия выглядела
  /// одинаково на маленьком скриншоте и на снимке с камеры.
  final double width;
}

/// Что рисует протяжка: стрелка или рамка.
enum ShapeKind { arrow, rect }

/// Чем человек размечает фото. Инструмент решает, что делает жест: кисть и
/// фигуры живут на протяжке, подпись — на тапе.
enum PhotoTool { brush, arrow, rect, text }

/// Стрелка или прямоугольник, заданные протяжкой из [from] в [to].
@immutable
class ShapeAnnotation extends PhotoAnnotation {
  const ShapeAnnotation({
    required this.kind,
    required this.from,
    required this.to,
    required super.color,
    required this.width,
  });

  final ShapeKind kind;
  final Offset from;
  final Offset to;
  final double width;
}

/// Подпись. [at] — левый верхний угол текста.
@immutable
class TextAnnotation extends PhotoAnnotation {
  const TextAnnotation({
    required this.text,
    required this.at,
    required super.color,
    required this.size,
  });

  final String text;
  final Offset at;

  /// Кегль в долях меньшей стороны — по той же причине, что и толщина кисти.
  final double size;
}

/// Результат редактирования: плоские байты и их настоящий тип.
class EditedPhoto {
  const EditedPhoto({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

/// Показать редактор. `null` — человек ушёл, ничего менять не надо.
Future<EditedPhoto?> showPhotoEditor(
  BuildContext context, {
  required Uint8List bytes,
}) => Navigator.of(context).push<EditedPhoto>(
  MaterialPageRoute<EditedPhoto>(
    fullscreenDialog: true,
    builder: (_) => PhotoEditScreen(bytes: bytes),
  ),
);

/// Прямоугольник, который занимает картинка внутри [box] при `BoxFit.contain`.
///
/// Вынесено чистой функцией: именно здесь живёт вся арифметика, из-за которой
/// штрих может лечь мимо. Проверять её надо без рендера.
Rect fittedImageRect({required Size image, required Size box}) {
  if (image.width <= 0 || image.height <= 0) return Offset.zero & box;
  final scale = math.min(box.width / image.width, box.height / image.height);
  final w = image.width * scale;
  final h = image.height * scale;
  return Rect.fromLTWH((box.width - w) / 2, (box.height - h) / 2, w, h);
}

/// Точка виджета → нормированная точка картинки (0..1).
///
/// `null` — палец вне картинки (в «полях» по краям). Рисовать там нечего, и
/// молча притягивать такую точку к краю нельзя: получилась бы линия вдоль
/// рамки, которую человек не проводил.
Offset? toImageSpace(Offset local, {required Size image, required Size box}) {
  final rect = fittedImageRect(image: image, box: box);
  if (rect.width <= 0 || rect.height <= 0) return null;
  if (!rect.contains(local)) return null;
  return Offset(
    (local.dx - rect.left) / rect.width,
    (local.dy - rect.top) / rect.height,
  );
}

/// Свести штрихи в картинку. Возвращает PNG.
///
/// PNG, а не исходный формат: поверх фото ложатся резкие цветные линии, и
/// JPEG размывает их артефактами именно там, куда человек показывает. Размер
/// при этом растёт, но подпись важнее байтов.
Future<Uint8List> flattenAnnotations({
  required ui.Image image,
  required List<PhotoAnnotation> annotations,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(image.width.toDouble(), image.height.toDouble());
  canvas.drawImage(image, Offset.zero, Paint());
  paintAnnotations(
    canvas,
    annotations: annotations,
    target: Offset.zero & size,
  );
  final picture = recorder.endRecording();
  final out = await picture.toImage(image.width, image.height);
  final data = await out.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  out.dispose();
  return data!.buffer.asUint8List();
}

/// Нарисовать пометки в [target]. Общая для экрана и для сведения — иначе
/// то, что человек видел, и то, что уехало в чат, разъезжаются.
void paintAnnotations(
  Canvas canvas, {
  required List<PhotoAnnotation> annotations,
  required Rect target,
}) {
  final minSide = math.min(target.width, target.height);
  Offset toCanvas(Offset p) => Offset(
    target.left + p.dx * target.width,
    target.top + p.dy * target.height,
  );

  for (final a in annotations) {
    switch (a) {
      case BrushStroke(:final points, :final color, :final width):
        if (points.isEmpty) continue;
        final paint = Paint()
          ..color = color
          ..strokeWidth = width * minSide
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;
        // Одиночный тап — точка, а не «ничего»: ей отмечают место.
        if (points.length == 1) {
          canvas.drawCircle(
            toCanvas(points.first),
            width * minSide / 2,
            Paint()..color = color,
          );
          continue;
        }
        final path = Path()
          ..moveTo(toCanvas(points.first).dx, toCanvas(points.first).dy);
        for (final p in points.skip(1)) {
          path.lineTo(toCanvas(p).dx, toCanvas(p).dy);
        }
        canvas.drawPath(path, paint);

      case ShapeAnnotation(
        :final kind,
        :final from,
        :final to,
        :final color,
        :final width,
      ):
        final paint = Paint()
          ..color = color
          ..strokeWidth = width * minSide
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;
        final a0 = toCanvas(from);
        final a1 = toCanvas(to);
        if (kind == ShapeKind.rect) {
          canvas.drawRect(Rect.fromPoints(a0, a1), paint);
          continue;
        }
        canvas.drawLine(a0, a1, paint);
        for (final p in arrowHead(
          from: a0,
          to: a1,
          size: width * minSide * 4,
        )) {
          canvas.drawLine(a1, p, paint);
        }

      case TextAnnotation(:final text, :final at, :final color, :final size):
        if (text.isEmpty) continue;
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: color,
              fontSize: size * minSide,
              fontWeight: FontWeight.w600,
              // Обводка контрастом: подпись читается и на светлом, и на
              // тёмном участке фото — иначе жёлтый текст на снегу пропадает.
              shadows: const [
                Shadow(blurRadius: 3, color: Colors.black54),
                Shadow(blurRadius: 6, color: Colors.black38),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: target.width);
        painter.paint(canvas, toCanvas(at));
    }
  }
}

/// Две точки «усов» стрелки в координатах ХОЛСТА.
///
/// Вынесено чистой функцией: геометрия наконечника — единственное здесь, что
/// можно посчитать неправильно незаметно (усы уедут вбок или вырастут длиннее
/// самой стрелки), и проверять её надо без рендера.
List<Offset> arrowHead({
  required Offset from,
  required Offset to,
  required double size,
}) {
  final dx = to.dx - from.dx;
  final dy = to.dy - from.dy;
  final len = math.sqrt(dx * dx + dy * dy);
  // Протяжка в одну точку — направления нет, наконечник рисовать нечем.
  if (len < 0.0001) return const [];
  final angle = math.atan2(dy, dx);
  // Наконечник не длиннее самой стрелки: у короткой протяжки он иначе
  // вылезал бы за её начало и выглядел кляксой.
  final side = math.min(size, len);
  const spread = math.pi / 7;
  return [
    Offset(
      to.dx - side * math.cos(angle - spread),
      to.dy - side * math.sin(angle - spread),
    ),
    Offset(
      to.dx - side * math.cos(angle + spread),
      to.dy - side * math.sin(angle + spread),
    ),
  ];
}

class PhotoEditScreen extends StatefulWidget {
  const PhotoEditScreen({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<PhotoEditScreen> createState() => _PhotoEditScreenState();
}

enum _Mode { draw, crop }

class _PhotoEditScreenState extends State<PhotoEditScreen> {
  static const _palette = <Color>[
    Color(0xFFE53935), // красный — им обводят чаще всего
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Colors.white,
    Colors.black,
  ];

  final _cropController = CropController();

  late Uint8List _image = widget.bytes;
  ui.Image? _decoded;

  final List<PhotoAnnotation> _strokes = [];
  List<Offset> _current = [];

  /// Текущий инструмент. Кисть по умолчанию: обвести место — самая частая
  /// нужда, остальное берут, когда её не хватило.
  PhotoTool _tool = PhotoTool.brush;

  /// Незавершённая протяжка стрелки/рамки: начало и текущий конец.
  Offset? _shapeFrom;
  Offset? _shapeTo;

  Color _color = _palette.first;

  /// Толщина в долях меньшей стороны. Пока не настраивается: чтобы обвести
  /// место на скриншоте, выбор толщины не нужен, а лишний ползунок — нужен
  /// как перегородка.
  final double _width = 0.012;

  /// Кегль подписи — тоже в долях меньшей стороны, по той же причине.
  final double _textSize = 0.06;
  _Mode _mode = _Mode.draw;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void dispose() {
    _decoded?.dispose();
    super.dispose();
  }

  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(_image);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _decoded?.dispose();
        _decoded = frame.image;
      });
    } on Object {
      // Не декодировалось — редактировать нечего. Экран останется пустым,
      // «Готово» вернёт исходник без изменений.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l.photoEditTitle),
        actions: [
          IconButton(
            key: const Key('photoEditModeToggle'),
            tooltip: _mode == _Mode.draw ? l.photoEditCrop : l.photoEditDraw,
            icon: Icon(_mode == _Mode.draw ? Icons.crop : Icons.brush),
            onPressed: _busy ? null : _toggleMode,
          ),
          if (_mode == _Mode.draw)
            IconButton(
              key: const Key('photoEditUndo'),
              tooltip: l.photoEditUndo,
              icon: const Icon(Icons.undo),
              // Отменять нечего — кнопка выключена, а не молча бездействует.
              onPressed: _strokes.isEmpty || _busy ? null : _undo,
            ),
          TextButton(
            key: const Key('photoEditDone'),
            onPressed: _busy ? null : _done,
            child: Text(l.photoEditDone),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _mode == _Mode.draw ? _drawArea() : _cropArea()),
          if (_mode == _Mode.draw) ...[_toolBar(l), _paletteBar()],
        ],
      ),
    );
  }

  Widget _cropArea() => Crop(
    image: _image,
    controller: _cropController,
    baseColor: Colors.black,
    interactive: true,
    onCropped: (result) {
      switch (result) {
        case CropSuccess(:final croppedImage):
          // Обрезка меняет систему координат, и старые штрихи легли бы
          // мимо. Сводим их В картинку ДО обрезки (см. [_toggleMode]),
          // поэтому здесь список уже пуст.
          setState(() => _image = croppedImage);
          _decode();
        case CropFailure():
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(NsgL10n.of(context).photoEditFailed)),
            );
          }
      }
      if (mounted) setState(() => _mode = _Mode.draw);
    },
  );

  Widget _drawArea() {
    final decoded = _decoded;
    if (decoded == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          key: const Key('photoEditCanvas'),
          onPanStart: (d) => _panStart(d.localPosition, imageSize, box),
          onPanUpdate: (d) => _panUpdate(d.localPosition, imageSize, box),
          onPanEnd: (_) => _panEnd(),
          onTapUp: (d) => _tap(d.localPosition, imageSize, box),
          child: CustomPaint(
            painter: _PhotoPainter(
              image: decoded,
              annotations: [..._strokes, ..._inProgress()],
            ),
            size: box,
          ),
        );
      },
    );
  }

  /// Выбор инструмента. Иконками, а не подписями: на телефоне ряд из
  /// четырёх слов не помещается, а иконки эти давно узнаваемы.
  Widget _toolBar(NsgL10n l) {
    final tools = <(PhotoTool, IconData, String)>[
      (PhotoTool.brush, Icons.brush, l.photoEditToolBrush),
      (PhotoTool.arrow, Icons.north_east, l.photoEditToolArrow),
      (PhotoTool.rect, Icons.crop_square, l.photoEditToolRect),
      (PhotoTool.text, Icons.title, l.photoEditToolText),
    ];
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (tool, icon, label) in tools)
            IconButton(
              key: Key('photoEditTool_${tool.name}'),
              tooltip: label,
              icon: Icon(icon),
              color: tool == _tool ? Colors.white : Colors.white38,
              onPressed: () => setState(() {
                _tool = tool;
                // Смена инструмента посреди протяжки бросает её: иначе
                // начатая кистью линия дорисовалась бы как стрелка.
                _current = [];
                _shapeFrom = null;
                _shapeTo = null;
              }),
            ),
        ],
      ),
    );
  }

  Widget _paletteBar() => Container(
    color: Colors.black,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final c in _palette)
          GestureDetector(
            key: Key('photoEditColor_${c.toARGB32()}'),
            onTap: () => setState(() => _color = c),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: c == _color ? Colors.white : Colors.white24,
                  width: c == _color ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    ),
  );

  /// Пометка, которую человек тянет прямо сейчас: рисуем её вместе с
  /// готовыми, иначе протяжка стрелки шла бы вслепую.
  List<PhotoAnnotation> _inProgress() {
    if (_current.isNotEmpty) {
      return [BrushStroke(points: _current, color: _color, width: _width)];
    }
    final from = _shapeFrom;
    final to = _shapeTo;
    if (from == null || to == null) return const [];
    return [
      ShapeAnnotation(
        kind: _tool == PhotoTool.rect ? ShapeKind.rect : ShapeKind.arrow,
        from: from,
        to: to,
        color: _color,
        width: _width,
      ),
    ];
  }

  void _panStart(Offset local, Size image, Size box) {
    final p = toImageSpace(local, image: image, box: box);
    if (p == null) return; // мимо картинки — не рисуем по полям
    setState(() {
      switch (_tool) {
        case PhotoTool.brush:
          _current = [p];
        case PhotoTool.arrow:
        case PhotoTool.rect:
          _shapeFrom = p;
          _shapeTo = p;
        case PhotoTool.text:
          break; // подпись ставится тапом, протяжка ей не нужна
      }
    });
  }

  void _panUpdate(Offset local, Size image, Size box) {
    final p = toImageSpace(local, image: image, box: box);
    if (p == null) return;
    setState(() {
      if (_current.isNotEmpty) {
        _current = [..._current, p];
      } else if (_shapeFrom != null) {
        _shapeTo = p;
      }
    });
  }

  void _panEnd() {
    setState(() {
      if (_current.isNotEmpty) {
        _strokes.add(
          BrushStroke(points: _current, color: _color, width: _width),
        );
        _current = [];
        return;
      }
      final from = _shapeFrom;
      final to = _shapeTo;
      _shapeFrom = null;
      _shapeTo = null;
      if (from == null || to == null) return;
      // Протяжка в точку — это промах, а не фигура нулевого размера.
      if ((from - to).distance < 0.01) return;
      _strokes.add(
        ShapeAnnotation(
          kind: _tool == PhotoTool.rect ? ShapeKind.rect : ShapeKind.arrow,
          from: from,
          to: to,
          color: _color,
          width: _width,
        ),
      );
    });
  }

  Future<void> _tap(Offset local, Size image, Size box) async {
    final p = toImageSpace(local, image: image, box: box);
    if (p == null) return;
    if (_tool != PhotoTool.text) {
      // Кистью одиночный тап ставит точку — ей отмечают место.
      if (_tool == PhotoTool.brush) {
        setState(() {
          _strokes.add(BrushStroke(points: [p], color: _color, width: _width));
        });
      }
      return;
    }
    final text = await _askText();
    if (text == null || text.isEmpty || !mounted) return;
    setState(() {
      _strokes.add(
        TextAnnotation(text: text, at: p, color: _color, size: _textSize),
      );
    });
  }

  Future<String?> _askText() {
    final l = NsgL10n.of(context);
    final ctl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.photoEditTextTitle),
        content: TextField(
          key: const Key('photoEditTextField'),
          controller: ctl,
          autofocus: true,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.commonCancel),
          ),
          TextButton(
            key: const Key('photoEditTextOk'),
            onPressed: () => Navigator.of(ctx).pop(ctl.text.trim()),
            child: Text(l.photoEditTextOk),
          ),
        ],
      ),
    );
  }

  void _undo() => setState(_strokes.removeLast);

  /// Переход в обрезку сводит уже нарисованное в саму картинку.
  ///
  /// Иначе после обрезки штрихи легли бы мимо: их координаты нормированы по
  /// СТАРОМУ кадру. Сведение делает картинку новым исходником — то же, что
  /// произошло бы при отправке, только раньше.
  Future<void> _toggleMode() async {
    if (_mode == _Mode.crop) {
      setState(() => _mode = _Mode.draw);
      return;
    }
    if (_strokes.isNotEmpty) {
      await _bake();
    }
    if (mounted) setState(() => _mode = _Mode.crop);
  }

  Future<void> _bake() async {
    final decoded = _decoded;
    if (decoded == null) return;
    setState(() => _busy = true);
    try {
      final flat = await flattenAnnotations(
        image: decoded,
        annotations: _strokes,
      );
      if (!mounted) return;
      setState(() {
        _image = flat;
        _strokes.clear();
      });
      await _decode();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _done() async {
    if (_strokes.isNotEmpty) await _bake();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(EditedPhoto(bytes: _image, mimeType: mimeOfImageBytes(_image)));
  }
}

class _PhotoPainter extends CustomPainter {
  const _PhotoPainter({required this.image, required this.annotations});

  final ui.Image image;
  final List<PhotoAnnotation> annotations;

  @override
  void paint(Canvas canvas, Size size) {
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final rect = fittedImageRect(image: imageSize, box: size);
    canvas.drawImageRect(
      image,
      Offset.zero & imageSize,
      rect,
      Paint()..filterQuality = FilterQuality.medium,
    );
    paintAnnotations(canvas, annotations: annotations, target: rect);
  }

  @override
  bool shouldRepaint(_PhotoPainter old) =>
      old.image != image || old.annotations != annotations;
}

/// Размеры картинки без полного декодирования — для превью и проверок.
({int width, int height})? imageDimensions(Uint8List bytes) {
  try {
    final d = img.decodeImage(bytes);
    if (d == null) return null;
    return (width: d.width, height: d.height);
  } on Object {
    // `decodeImage` на мусоре БРОСАЕТ (PSD-кандидат читает за буфер) —
    // та же ловушка, что в probeImage на сервере и в mimeOfImageBytes.
    return null;
  }
}
