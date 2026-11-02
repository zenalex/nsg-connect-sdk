/// **issue #168 — повторный тап по выбору фото отменял первый.**
///
/// `image_picker` отвечает `PlatformException(multiple_request)`, когда
/// новый запрос приходит, пока предыдущий не завершён, и при этом отменяет
/// ЗАКОННЫЙ первый. Прежний код считал это провалом: сообщал об ошибке и
/// возвращал пустой результат, а лист закрывался ни с чем. Снаружи это
/// выглядело как «нажал приложить фото — всё схлопнулось», и человек
/// описывал это как падение приложения.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_picker.dart';

/// Платформа, которая ведёт себя как настоящий `image_picker` при
/// повторном запросе: отвечает `multiple_request`.
class _BusyPickerPlatform extends ImagePickerPlatform {
  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    throw PlatformException(
      code: 'multiple_request',
      message: 'Cancelled by a second request',
    );
  }

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    throw PlatformException(
      code: 'multiple_request',
      message: 'Cancelled by a second request',
    );
  }
}

/// Платформа, которая падает по-настоящему — для проверки, что мы НЕ
/// приняли всякую ошибку за «выбор уже идёт».
class _BrokenPickerPlatform extends ImagePickerPlatform {
  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    throw PlatformException(code: 'photo_access_denied', message: 'нет прав');
  }

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    throw PlatformException(code: 'photo_access_denied', message: 'нет прав');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetPickInFlightForTesting);
  tearDown(resetPickInFlightForTesting);

  group('распознавание «выбор уже идёт»', () {
    test('multiple_request — это занятость, а не провал', () {
      expect(
        isConcurrentPickError(
          PlatformException(
            code: 'multiple_request',
            message: 'Cancelled by a second request',
          ),
        ),
        isTrue,
      );
    });

    test('прочие отказы платформы занятостью НЕ считаются', () {
      // Иначе мы бы молча проглатывали отказ в правах и оставляли человека
      // с открытым листом, который «не работает» без объяснений.
      expect(
        isConcurrentPickError(PlatformException(code: 'photo_access_denied')),
        isFalse,
      );
      expect(isConcurrentPickError(StateError('что-то другое')), isFalse);
    });
  });

  group('галерея', () {
    test(
      'занятость бросает ConcurrentPickException, а не пустой список',
      () async {
        // Пустой список означал бы «человек ничего не выбрал» — и лист
        // закрылся бы. Разница между этими двумя случаями и есть суть #168.
        ImagePickerPlatform.instance = _BusyPickerPlatform();
        await expectLater(
          pickImagesAttachment(ImagePicker(), limit: 5),
          throwsA(isA<ConcurrentPickException>()),
        );
      },
    );

    test('настоящий отказ по-прежнему даёт пустой список', () async {
      ImagePickerPlatform.instance = _BrokenPickerPlatform();
      expect(await pickImagesAttachment(ImagePicker(), limit: 5), isEmpty);
    });
  });

  group('камера', () {
    test('занятость бросает ConcurrentPickException, а не null', () async {
      ImagePickerPlatform.instance = _BusyPickerPlatform();
      await expectLater(
        pickImageAttachment(ImagePicker(), ImageSource.camera),
        throwsA(isA<ConcurrentPickException>()),
      );
    });

    test('настоящий отказ по-прежнему даёт null', () async {
      ImagePickerPlatform.instance = _BrokenPickerPlatform();
      expect(
        await pickImageAttachment(ImagePicker(), ImageSource.camera),
        isNull,
      );
    });
  });

  group('признак занятости', () {
    test('после завершения выбора сбрасывается', () async {
      // Иначе первая же ошибка запирала бы выбор до перезапуска
      // приложения — лечение было бы хуже болезни.
      ImagePickerPlatform.instance = _BrokenPickerPlatform();
      await pickImagesAttachment(ImagePicker(), limit: 5);
      expect(isPickInFlight, isFalse);
    });

    test('сбрасывается и когда бросили занятостью', () async {
      ImagePickerPlatform.instance = _BusyPickerPlatform();
      try {
        await pickImagesAttachment(ImagePicker(), limit: 5);
      } on ConcurrentPickException {
        // ожидаемо
      }
      expect(isPickInFlight, isFalse);
    });
  });
}
