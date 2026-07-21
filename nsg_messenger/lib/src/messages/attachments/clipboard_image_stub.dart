import 'attachment_picker.dart';

/// Non-web заглушка: вставка картинки из буфера — web-only фича
/// (на mobile/desktop attach-кнопка/галерея уже покрывают сценарий).
class ClipboardImageListener {
  void start(void Function(PickedAttachment picked) onImage) {}
  void stop() {}
}
