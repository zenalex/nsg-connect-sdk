/// **TASK92**: откуда клиент берёт байты вложения.
///
/// Два пути и один выбор между ними:
///
/// * **Прямо из S3** по временной ссылке — для вложений, загруженных после
///   TASK92. Ни сервер, ни Synapse в передаче не участвуют.
/// * **Байтами через сервер** (`downloadAttachment`) — для всего, что
///   лежит в media-store Synapse, и как запасной путь, если до хранилища
///   не достучаться.
///
/// Запасной путь здесь не перестраховка. Клиент может сидеть в сети, где
/// наш API доступен, а MinIO — нет (корпоративный периметр, белый список
/// адресов). Без отката такой клиент потерял бы вложения целиком, причём
/// молча; с откатом он просто работает медленнее.
library;

import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messages_rpc.dart';

/// Лежит ли вложение в S3 — по виду идентификатора.
///
/// Синтетический mxc S3-вложения выглядит как `mxc://server/s3_<hex>`;
/// префикс проставляет сервер на загрузке. У Synapse media id — 24 буквы
/// латиницей без подчёркиваний и цифр, так что пересечься эти множества
/// не могут.
///
/// Ошибка распознавания здесь не опасна: в обе стороны она означает лишь
/// выбор более медленного пути, а права на вложение проверяет сервер
/// независимо от того, как клиент за ним пришёл.
bool isStorageBackedMxc(String mxcUrl) {
  const scheme = 'mxc://';
  if (!mxcUrl.startsWith(scheme)) return false;
  final slash = mxcUrl.indexOf('/', scheme.length);
  if (slash < 0) return false;
  return mxcUrl.startsWith('s3_', slash + 1);
}

/// Скачать полное вложение через сервер (старый путь).
typedef DownloadBytesFn =
    Future<AttachmentBytes> Function({required String mxcUrl});

/// Скачать превью через сервер (старый путь).
typedef DownloadThumbnailFn =
    Future<AttachmentBytes> Function({
      required String mxcUrl,
      int? width,
      int? height,
    });

/// Достаёт байты вложения тем путём, который для него уместен.
///
/// Зависимости — замыканиями, а не целым [MessagesRpc]: тот интерфейс на
/// четыре десятка методов, и тест транспорта не должен реализовывать их
/// все ради двух. Тот же приём, что у `MessageBubble` с download-RPC.
class AttachmentTransport {
  AttachmentTransport({
    required DownloadBytesFn downloadBytes,
    required DownloadThumbnailFn downloadThumbnail,
    AttachmentUrlRpc? urlRpc,
    http.Client? httpClient,
  }) : _downloadBytes = downloadBytes,
       _downloadThumbnail = downloadThumbnail,
       _urlRpc = urlRpc,
       _http = httpClient ?? http.Client();

  final DownloadBytesFn _downloadBytes;
  final DownloadThumbnailFn _downloadThumbnail;

  /// `null` — реализация не умеет выдавать ссылки; всё идёт через сервер.
  final AttachmentUrlRpc? _urlRpc;
  final http.Client _http;

  /// Полноразмерное вложение.
  Future<AttachmentBytes> full({required String mxcUrl}) =>
      _fetch(mxcUrl: mxcUrl, thumbnail: false);

  /// Превью. `width`/`height` относятся только к старому пути: у
  /// S3-вложения превью одно, сделанное на загрузке.
  Future<AttachmentBytes> thumbnail({
    required String mxcUrl,
    int? width,
    int? height,
  }) => _fetch(mxcUrl: mxcUrl, thumbnail: true, width: width, height: height);

  Future<AttachmentBytes> _fetch({
    required String mxcUrl,
    required bool thumbnail,
    int? width,
    int? height,
  }) async {
    final urlRpc = _urlRpc;
    if (urlRpc != null && isStorageBackedMxc(mxcUrl)) {
      try {
        return await _fetchFromStorage(
          rpc: urlRpc,
          mxcUrl: mxcUrl,
          thumbnail: thumbnail,
        );
      } on ThumbnailUnavailableException {
        // «Превью нет» — штатный исход (документы, видео). Через сервер
        // ответ будет ровно такой же, ходить туда незачем.
        rethrow;
      } on AttachmentAccessDeniedException {
        // Отказ в доступе — тоже окончательный ответ, а не сбой связи.
        rethrow;
      } on Object {
        // Хранилище недоступно — идём через сервер. Молчим: для человека
        // это просто «загрузилось», а не повод для красной строки.
      }
    }
    return _fetchViaServer(
      mxcUrl: mxcUrl,
      thumbnail: thumbnail,
      width: width,
      height: height,
    );
  }

  Future<AttachmentBytes> _fetchFromStorage({
    required AttachmentUrlRpc rpc,
    required String mxcUrl,
    required bool thumbnail,
  }) async {
    final link = await rpc.getAttachmentUrl(
      mxcUrl: mxcUrl,
      thumbnail: thumbnail,
    );
    final resp = await _http.get(Uri.parse(link.url));
    if (resp.statusCode != 200) {
      throw StateError(
        'хранилище ответило ${resp.statusCode} на ссылку для $mxcUrl',
      );
    }
    return AttachmentBytes(
      bytes: ByteData.sublistView(Uint8List.fromList(resp.bodyBytes)),
      // Тип берём у нашего сервера, а не из ответа хранилища: он знает
      // исходный MIME, а хранилище могло бы отдать octet-stream.
      contentType: link.contentType,
    );
  }

  Future<AttachmentBytes> _fetchViaServer({
    required String mxcUrl,
    required bool thumbnail,
    int? width,
    int? height,
  }) => thumbnail
      ? _downloadThumbnail(mxcUrl: mxcUrl, width: width, height: height)
      : _downloadBytes(mxcUrl: mxcUrl);
}
