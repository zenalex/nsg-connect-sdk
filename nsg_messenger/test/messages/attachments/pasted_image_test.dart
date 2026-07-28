/// **Вставка картинки из буфера обмена.**
///
/// Прод, 28.07: у 42 из 67 присланных `image/png` Synapse на каждый
/// запрос миниатюры отвечал 400. Все 42 — `clipboard-*.png`, и все они
/// на самом деле BMP («BM» в первых байтах): Windows кладёт в буфер DIB,
/// а композер подписывал байты `image/png` не глядя. Настоящие PNG (25)
/// и все JPEG (63) превью имели.
///
/// Защищаем главное свойство: то, что уходит на сервер, подписано тем,
/// чем является, — и формат, который дальше по конвейеру не тянут,
/// пережимается, а не переименовывается.
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/messages/attachments/pasted_image.dart';

/// Минимальный валидный BMP 2×2 (24bpp) — ровно тот случай, что лежит в
/// проде, только маленький.
Uint8List _bmp2x2() {
  const headerSize = 54;
  // 2 пикселя по 3 байта + 2 байта паддинга до границы 4 = 8 байт на ряд.
  const rowSize = 8;
  const pixelBytes = rowSize * 2;
  final b = BytesBuilder();
  final header = ByteData(headerSize);
  header.setUint8(0, 0x42); // 'B'
  header.setUint8(1, 0x4D); // 'M'
  header.setUint32(2, headerSize + pixelBytes, Endian.little); // размер
  header.setUint32(10, headerSize, Endian.little); // смещение пикселей
  header.setUint32(14, 40, Endian.little); // размер BITMAPINFOHEADER
  header.setInt32(18, 2, Endian.little); // ширина
  header.setInt32(22, 2, Endian.little); // высота
  header.setUint16(26, 1, Endian.little); // плоскости
  header.setUint16(28, 24, Endian.little); // бит на пиксель
  header.setUint32(34, pixelBytes, Endian.little); // размер данных
  b.add(header.buffer.asUint8List());
  for (var row = 0; row < 2; row++) {
    b.add(<int>[0x00, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0x00, 0x00]);
  }
  return b.toBytes();
}

Uint8List _png() => Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // сигнатура
  ...List<int>.filled(24, 0),
]);

Uint8List _jpeg() =>
    Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, ...List<int>.filled(24, 0)]);

Uint8List _webp() => Uint8List.fromList([
  0x52, 0x49, 0x46, 0x46, // RIFF
  0x00, 0x00, 0x00, 0x00, // размер (не важен)
  0x57, 0x45, 0x42, 0x50, // WEBP
  ...List<int>.filled(16, 0),
]);

void main() {
  group('sniffImageMime — смотрим на байты, а не на подпись', () {
    test('PNG', () => expect(sniffImageMime(_png()), 'image/png'));
    test('JPEG', () => expect(sniffImageMime(_jpeg()), 'image/jpeg'));
    test('WebP', () => expect(sniffImageMime(_webp()), 'image/webp'));
    test('GIF', () {
      expect(
        sniffImageMime(
          Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]),
        ),
        'image/gif',
      );
    });
    test('BMP — ровно тот случай из прода', () {
      expect(sniffImageMime(_bmp2x2()), 'image/bmp');
    });
    test('TIFF обоих порядков байт', () {
      expect(
        sniffImageMime(Uint8List.fromList([0x49, 0x49, 0x2A, 0x00, 0, 0])),
        'image/tiff',
      );
      expect(
        sniffImageMime(Uint8List.fromList([0x4D, 0x4D, 0x00, 0x2A, 0, 0])),
        'image/tiff',
      );
    });
    test('не картинка / обрезок — не выдумываем формат', () {
      expect(sniffImageMime(Uint8List.fromList([1, 2, 3])), isNull);
      expect(sniffImageMime(Uint8List(0)), isNull);
    });
  });

  group('pastedImageAttachment', () {
    test('BMP пережимается в PNG — иначе превью не будет никогда', () async {
      var calls = 0;
      final encoded = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 7, 7]);
      final picked = await pastedImageAttachment(
        _bmp2x2(),
        stampMs: 1700000000000,
        encodeToPng: (src) async {
          calls++;
          return encoded;
        },
      );
      expect(calls, 1);
      expect(picked.bytes, encoded);
      expect(picked.mimeType, 'image/png');
      expect(picked.originalFilename, 'clipboard-1700000000000.png');
    });

    test('настоящий PNG не трогаем — лишняя перекодировка только теряет '
        'время и качество', () async {
      var calls = 0;
      final src = _png();
      final picked = await pastedImageAttachment(
        src,
        stampMs: 1,
        encodeToPng: (_) async {
          calls++;
          return null;
        },
      );
      expect(calls, 0);
      expect(picked.bytes, same(src));
      expect(picked.mimeType, 'image/png');
    });

    test('JPEG из буфера подписывается JPEG-ом, а не PNG', () async {
      final picked = await pastedImageAttachment(
        _jpeg(),
        stampMs: 2,
        encodeToPng: (_) async => throw StateError('не должно зваться'),
      );
      expect(picked.mimeType, 'image/jpeg');
      expect(picked.originalFilename, 'clipboard-2.jpg');
    });

    test('перекодировать не вышло → подписываем честно, а не «png»', () async {
      // Сервер BMP принимает (`_imageMimes`), так что у него остаётся шанс
      // сделать превью самому. Соврать «png» — гарантированно его лишить.
      final picked = await pastedImageAttachment(
        _bmp2x2(),
        stampMs: 3,
        encodeToPng: (_) async => null,
      );
      expect(picked.mimeType, 'image/bmp');
      expect(picked.originalFilename, 'clipboard-3.bmp');
    });

    test('формат не опознан и не пережался → прежнее поведение', () async {
      // macOS и Linux отдают из буфера настоящий PNG, там всё работало и
      // до правки — регрессия недопустима.
      final picked = await pastedImageAttachment(
        Uint8List.fromList([1, 2, 3, 4]),
        stampMs: 4,
        encodeToPng: (_) async => null,
      );
      expect(picked.mimeType, 'image/png');
      expect(picked.originalFilename, 'clipboard-4.png');
    });
  });

  group('encodePngViaEngine — настоящий кодек, без подмен', () {
    // Инъекция кодировщика проверяет проводку, но не то, что движок
    // ВООБЩЕ умеет BMP. Если не умеет — вся правка бессмысленна.
    test('BMP из буфера превращается в настоящий PNG', () async {
      final png = await encodePngViaEngine(_bmp2x2());
      expect(png, isNotNull, reason: 'движок не разобрал BMP');
      expect(sniffImageMime(png!), 'image/png');
    });

    test('мусор вместо картинки → null, а не исключение наружу', () async {
      expect(await encodePngViaEngine(Uint8List.fromList([1, 2, 3])), isNull);
    });
  });
}
