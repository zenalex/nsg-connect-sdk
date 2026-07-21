// Вставка картинки из буфера обмена (Ctrl+V) в composer. Реализация
// платформо-зависимая:
//   * web (js_interop) → clipboard_image_web.dart — слушает `paste` на
//     document, достаёт image-blob, отдаёт как PickedAttachment;
//   * прочее → clipboard_image_stub.dart — no-op (на mobile/desktop
//     image_picker/attach уже покрывает; paste из буфера — web-фича).
export 'clipboard_image_stub.dart'
    if (dart.library.js_interop) 'clipboard_image_web.dart';
