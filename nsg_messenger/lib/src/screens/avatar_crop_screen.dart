/// **Обрезка аватара перед загрузкой** (issue #102).
///
/// Запрос владельца: «при работе с аватарами хотелось бы стандартный
/// мини-редактор иметь (обрезки, положения, что там обычно)».
///
/// До этого редактора не было вовсе: выбранная картинка уходила на сервер как
/// есть и обрезалась по центру автоматически — у горизонтального фото в круг
/// попадала середина, а лицо съезжало за край. Поправить было нечем, только
/// переснять и надеяться.
///
/// **Почему не `image_cropper`.** Он объявляет в своём `pubspec.yaml` только
/// `android`, `ios` и `web`, а Chatista собирается ещё под **windows и
/// macos** — на десктопе экран просто не открылся бы. `crop_your_image` —
/// чистый Dart (зависит лишь от `flutter` и `image`) и работает везде.
library;

import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../i18n/generated/nsg_l10n.dart';

/// Результат обрезки: байты и их НАСТОЯЩИЙ тип.
///
/// Тип отдаём вместе с байтами, а не оставляем вызывающему угадывать по имени
/// исходного файла. `crop_your_image` сохраняет входной формат (jpeg→jpeg,
/// png→png), но поворот внутри экрана перекодирует кадр в PNG — то есть тип
/// на выходе может не совпасть с тем, что человек выбрал. Угадывание по имени
/// дало бы `image/jpeg` для PNG-байтов.
class CroppedAvatar {
  const CroppedAvatar({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

/// Показать редактор и вернуть обрезанное. `null` — человек отказался.
///
/// Возвращает байты, а не файл: вызывающий (`uploadUserAvatar`) уже работает
/// с байтами, и промежуточный файл был бы лишней сущностью, которую пришлось
/// бы за собой убирать.
Future<CroppedAvatar?> showAvatarCropper(
  BuildContext context, {
  required Uint8List bytes,
}) => Navigator.of(context).push<CroppedAvatar>(
  MaterialPageRoute<CroppedAvatar>(
    fullscreenDialog: true,
    builder: (_) => AvatarCropScreen(bytes: bytes),
  ),
);

class AvatarCropScreen extends StatefulWidget {
  const AvatarCropScreen({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final _controller = CropController();

  /// Текущее изображение: меняется поворотом. Исходник не трогаем — «отмена»
  /// обязана возвращать ровно то, что человек выбрал.
  late Uint8List _image = widget.bytes;

  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l.avatarCropTitle),
        actions: [
          IconButton(
            key: const Key('avatarCropRotate'),
            tooltip: l.avatarCropRotate,
            icon: const Icon(Icons.rotate_right),
            onPressed: _busy ? null : _rotate,
          ),
          TextButton(
            key: const Key('avatarCropDone'),
            onPressed: _busy ? null : () => _controller.crop(),
            child: Text(l.avatarCropDone),
          ),
        ],
      ),
      body: Crop(
        image: _image,
        controller: _controller,
        // Квадрат: аватар везде показывается в круге, вписанном в квадрат.
        aspectRatio: 1,
        // Круглая рамка — чтобы человек видел РЕЗУЛЬТАТ, а не абстрактный
        // квадрат: в круге по краям срезается заметно больше, чем кажется.
        withCircleUi: true,
        // Двигать и масштабировать саму картинку под неподвижной рамкой.
        // Это и есть «положение» из запроса; без него остаётся только
        // тянуть рамку, а к краям большого фото её не дотащить.
        interactive: true,
        fixCropRect: true,
        baseColor: Colors.black,
        onStatusChanged: (s) {
          final busy = s == CropStatus.cropping;
          if (busy != _busy && mounted) setState(() => _busy = busy);
        },
        onCropped: _onCropped,
      ),
    );
  }

  /// **Обрезаем квадратом, а не кругом** (`crop()`, не `cropCircle()`).
  ///
  /// `cropCircle` вернул бы PNG с прозрачными углами. В круглой аватарке
  /// разницы не видно, но то же изображение показывается и прямоугольником —
  /// в карточке контакта, в шапке чата, — и там прозрачные углы выглядят
  /// браком. Круг остаётся формой показа, а не формой файла.
  void _onCropped(CropResult result) {
    if (!mounted) return;
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.of(context).pop(
          CroppedAvatar(
            bytes: croppedImage,
            mimeType: mimeOfImageBytes(croppedImage),
          ),
        );
      case CropFailure():
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(NsgL10n.of(context).avatarCropFailed)),
        );
    }
  }

  /// Поворот на 90° по часовой.
  ///
  /// Считаем на месте пакетом `image`: снимок с телефона приезжает лежащим
  /// достаточно часто, а гонять его на сервер и обратно ради поворота —
  /// несоразмерно. Кадр в аватарке маленький (`maxWidth/maxHeight` у пикера
  /// 1024), так что декод-поворот-кодирование укладывается в десятки
  /// миллисекунд и подвисания не даёт.
  Future<void> _rotate() async {
    setState(() => _busy = true);
    try {
      final decoded = img.decodeImage(_image);
      if (decoded == null) {
        // Не декодировалось — поворачивать нечем. Молчим: обрезать
        // по-прежнему можно, а падать из-за необязательной кнопки незачем.
        return;
      }
      final rotated = img.copyRotate(decoded, angle: 90);
      final next = Uint8List.fromList(img.encodePng(rotated));
      if (!mounted) return;
      setState(() => _image = next);
      _controller.image = next;
    } on Object {
      // Битый файл человек вправе выбрать; кнопка поворота не повод падать.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// MIME по СОДЕРЖИМОМУ, а не по имени файла.
///
/// Имя врёт в двух местах сразу: пикер отдаёт временный файл со своим
/// расширением, а поворот в редакторе перекодирует кадр в PNG независимо от
/// исходного формата. Сервер же по типу выбирает и лимит размера, и ветку
/// обработки — соврать тут значит получить отказ на ровном месте.
///
/// Неизвестный формат → `image/png`: это то, во что кодирует и сам
/// `crop_your_image`, когда не распознал вход.
String mimeOfImageBytes(Uint8List bytes) {
  // `findFormatForData` на мусорных байтах не возвращает «неизвестно», а
  // БРОСАЕТ: подбирая декодер, он даёт каждому кандидату прочитать заголовок,
  // и PSD-кандидат читает за границу короткого буфера (RangeError). Та же
  // ловушка, что у `AttachmentService.probeImage` на сервере.
  final img.ImageFormat format;
  try {
    format = img.findFormatForData(bytes);
  } on Object {
    return 'image/png';
  }
  return switch (format) {
    img.ImageFormat.jpg => 'image/jpeg',
    img.ImageFormat.png => 'image/png',
    img.ImageFormat.webp => 'image/webp',
    img.ImageFormat.bmp => 'image/bmp',
    img.ImageFormat.gif => 'image/gif',
    _ => 'image/png',
  };
}
