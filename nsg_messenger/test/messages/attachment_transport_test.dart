import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_transport.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';

/// TASK92: выбор пути за вложением. Здесь решается, пойдёт ли клиент в S3
/// сам или попросит байты у сервера, — и что будет, когда до хранилища не
/// достучаться.
void main() {
  AttachmentBytes serverBytes(String marker) => AttachmentBytes(
    bytes: ByteData.sublistView(Uint8List.fromList(utf8.encode(marker))),
    contentType: 'application/from-server',
  );

  String textOf(AttachmentBytes b) => utf8.decode(b.bytes.buffer.asUint8List());

  group('isStorageBackedMxc', () {
    test('узнаёт синтетический mxc S3-вложения', () {
      expect(isStorageBackedMxc('mxc://chatista.me/s3_a1b2c3'), isTrue);
    });

    test('обычный Synapse-идентификатор не путает', () {
      // У Synapse media id — латиница без подчёркиваний; пересечься эти
      // множества не могут.
      expect(isStorageBackedMxc('mxc://chatista.me/AbCdEfGhIjKl'), isFalse);
    });

    test('мусор не ломает разбор', () {
      expect(isStorageBackedMxc(''), isFalse);
      expect(isStorageBackedMxc('https://example.org/s3_x'), isFalse);
      expect(isStorageBackedMxc('mxc://nohost'), isFalse);
      // `s3_` в имени сервера, а не в идентификаторе.
      expect(isStorageBackedMxc('mxc://s3_server/AbCd'), isFalse);
    });
  });

  group('AttachmentTransport', () {
    test('вложение из S3 качается напрямую, минуя сервер', () async {
      var serverCalls = 0;
      final transport = AttachmentTransport(
        downloadBytes: ({required String mxcUrl}) async {
          serverCalls++;
          return serverBytes('через сервер');
        },
        downloadThumbnail:
            ({required String mxcUrl, int? width, int? height}) async {
              serverCalls++;
              return serverBytes('через сервер');
            },
        urlRpc: _FakeUrlRpc(url: 'https://storage.example/obj?sig=1'),
        httpClient: MockClient(
          (req) async => req.url.toString().startsWith('https://storage.')
              ? http.Response.bytes(utf8.encode('из хранилища'), 200)
              : http.Response.bytes(utf8.encode('чужой адрес'), 404),
        ),
      );

      final got = await transport.full(mxcUrl: 'mxc://chatista.me/s3_abc');
      expect(textOf(got), 'из хранилища');
      expect(serverCalls, 0, reason: 'сервер не должен был участвовать');
      // Тип берём у своего сервера: хранилище могло бы отдать
      // octet-stream, а исходный MIME знаем мы.
      expect(got.contentType, 'image/png');
    });

    test('старое вложение идёт через сервер, ссылок не спрашивая', () async {
      final rpc = _FakeUrlRpc(url: 'https://storage.example/obj');
      final transport = AttachmentTransport(
        downloadBytes: ({required String mxcUrl}) async =>
            serverBytes('через сервер'),
        downloadThumbnail:
            ({required String mxcUrl, int? width, int? height}) async =>
                serverBytes('через сервер'),
        urlRpc: rpc,
        httpClient: MockClient(
          (_) async =>
              http.Response.bytes(utf8.encode('не должно быть запроса'), 200),
        ),
      );

      final got = await transport.full(mxcUrl: 'mxc://chatista.me/AbCdEf');
      expect(textOf(got), 'через сервер');
      expect(rpc.calls, 0);
    });

    test('без умения выдавать ссылки — тоже через сервер', () async {
      // Так ведут себя тестовые двойники и любая старая реализация.
      final transport = AttachmentTransport(
        downloadBytes: ({required String mxcUrl}) async =>
            serverBytes('через сервер'),
        downloadThumbnail:
            ({required String mxcUrl, int? width, int? height}) async =>
                serverBytes('через сервер'),
        urlRpc: null,
        httpClient: MockClient(
          (_) async => http.Response.bytes(utf8.encode('нет'), 500),
        ),
      );
      final got = await transport.full(mxcUrl: 'mxc://chatista.me/s3_abc');
      expect(textOf(got), 'через сервер');
    });

    test(
      'хранилище недоступно — откат на сервер, а не пустая картинка',
      () async {
        // Клиент может сидеть в сети, где наш API доступен, а MinIO нет.
        // Без отката он потерял бы вложения молча.
        final transport = AttachmentTransport(
          downloadBytes: ({required String mxcUrl}) async =>
              serverBytes('через сервер'),
          downloadThumbnail:
              ({required String mxcUrl, int? width, int? height}) async =>
                  serverBytes('через сервер'),
          urlRpc: _FakeUrlRpc(url: 'https://storage.example/obj'),
          httpClient: MockClient((_) async => throw const SocketishError()),
        );
        final got = await transport.full(mxcUrl: 'mxc://chatista.me/s3_abc');
        expect(textOf(got), 'через сервер');
      },
    );

    test('не-200 от хранилища — тоже откат', () async {
      final transport = AttachmentTransport(
        downloadBytes: ({required String mxcUrl}) async =>
            serverBytes('через сервер'),
        downloadThumbnail:
            ({required String mxcUrl, int? width, int? height}) async =>
                serverBytes('через сервер'),
        urlRpc: _FakeUrlRpc(url: 'https://storage.example/obj'),
        httpClient: MockClient(
          (_) async => http.Response.bytes(utf8.encode('протухло'), 403),
        ),
      );
      final got = await transport.full(mxcUrl: 'mxc://chatista.me/s3_abc');
      expect(textOf(got), 'через сервер');
    });

    test('отказ в доступе НЕ откатывается на сервер', () async {
      // Это окончательный ответ, а не сбой связи: повтор через сервер
      // дал бы тот же отказ, только на секунду позже.
      var serverCalls = 0;
      final transport = AttachmentTransport(
        downloadBytes: ({required String mxcUrl}) async {
          serverCalls++;
          return serverBytes('через сервер');
        },
        downloadThumbnail:
            ({required String mxcUrl, int? width, int? height}) async {
              serverCalls++;
              return serverBytes('через сервер');
            },
        urlRpc: _FakeUrlRpc(
          throwing: AttachmentAccessDeniedException(
            mxcUrl: 'mxc://chatista.me/s3_abc',
          ),
        ),
        httpClient: MockClient((_) async => http.Response('', 200)),
      );

      await expectLater(
        transport.full(mxcUrl: 'mxc://chatista.me/s3_abc'),
        throwsA(isA<AttachmentAccessDeniedException>()),
      );
      expect(serverCalls, 0);
    });

    test('«превью нет» НЕ откатывается на сервер', () async {
      // Штатный исход для документов и видео; через сервер ответ будет
      // ровно такой же.
      var serverCalls = 0;
      final transport = AttachmentTransport(
        downloadBytes: ({required String mxcUrl}) async =>
            serverBytes('через сервер'),
        downloadThumbnail:
            ({required String mxcUrl, int? width, int? height}) async {
              serverCalls++;
              return serverBytes('через сервер');
            },
        urlRpc: _FakeUrlRpc(
          throwing: ThumbnailUnavailableException(
            mxcUrl: 'mxc://chatista.me/s3_abc',
            reason: 'нет превью',
          ),
        ),
        httpClient: MockClient((_) async => http.Response('', 200)),
      );

      await expectLater(
        transport.thumbnail(mxcUrl: 'mxc://chatista.me/s3_abc'),
        throwsA(isA<ThumbnailUnavailableException>()),
      );
      expect(serverCalls, 0);
    });

    test('превью из S3 спрашивается именно как превью', () async {
      final rpc = _FakeUrlRpc(url: 'https://storage.example/thumb');
      final transport = AttachmentTransport(
        downloadBytes: ({required String mxcUrl}) async =>
            serverBytes('через сервер'),
        downloadThumbnail:
            ({required String mxcUrl, int? width, int? height}) async =>
                serverBytes('через сервер'),
        urlRpc: rpc,
        httpClient: MockClient(
          (_) async => http.Response.bytes(utf8.encode('превью'), 200),
        ),
      );
      await transport.thumbnail(mxcUrl: 'mxc://chatista.me/s3_abc');
      // Иначе в пузырь поехал бы полноразмерный файл — ровно то, от чего
      // превью и спасает.
      expect(rpc.lastThumbnail, isTrue);
    });
  });
}

class _FakeUrlRpc implements AttachmentUrlRpc {
  _FakeUrlRpc({this.url, this.throwing});

  final String? url;
  final Object? throwing;
  int calls = 0;
  bool? lastThumbnail;

  @override
  Future<AttachmentUrl> getAttachmentUrl({
    required String mxcUrl,
    bool thumbnail = false,
  }) async {
    calls++;
    lastThumbnail = thumbnail;
    if (throwing != null) throw throwing!;
    return AttachmentUrl(
      url: url!,
      expiresAt: DateTime.utc(2026, 8, 7, 12, 15),
      contentType: 'image/png',
    );
  }
}

/// Обрыв связи с хранилищем. Свой тип, чтобы не тащить `dart:io` в тест,
/// который иначе не зависит от платформы.
class SocketishError implements Exception {
  const SocketishError();
}
