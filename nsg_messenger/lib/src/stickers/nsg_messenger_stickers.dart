import 'dart:typed_data';

import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// **issue #151: пользовательские наборы стикеров** — публичный API SDK.
///
/// Тонкая обёртка над `client.sticker.*`, как [NsgMessengerIntegrations]:
/// каждый вызов под [withAuthRetry], session-manager резолвится лениво из
/// runtime (замыкания выполняются уже после `init()`).
///
/// **Кэша нет намеренно.** Наборы открывают редко и в двух местах — пикер и
/// экран управления, — а держать их в памяти значило бы отвечать на «я же
/// только что удалил стикер» старым списком. Пикер запрашивает при
/// открытии; это один вызов, который приносит наборы вместе с содержимым.
///
/// Сигнатуры вынесены в typedef-ы для подмены в тестах ([withRpcs]) — так
/// тесты не зависят ни от Serverpod-клиента, ни от singleton-рантайма.
typedef ListStickerPacksRpc = Future<List<StickerPackView>> Function();
typedef CreateStickerPackRpc =
    Future<StickerPack> Function({required String name});
typedef RenameStickerPackRpc =
    Future<StickerPack> Function({required int packId, required String name});
typedef DeleteStickerPackRpc = Future<void> Function({required int packId});
typedef AddStickerRpc =
    Future<Sticker> Function({
      required int packId,
      required ByteData bytes,
      required String mimeType,
      required String alias,
    });
typedef RemoveStickerRpc = Future<void> Function({required int stickerId});

class NsgMessengerStickers {
  NsgMessengerStickers._({
    required ListStickerPacksRpc listPacksRpc,
    required CreateStickerPackRpc createPackRpc,
    required RenameStickerPackRpc renamePackRpc,
    required DeleteStickerPackRpc deletePackRpc,
    required AddStickerRpc addStickerRpc,
    required RemoveStickerRpc removeStickerRpc,
  }) : _listPacksRpc = listPacksRpc,
       _createPackRpc = createPackRpc,
       _renamePackRpc = renamePackRpc,
       _deletePackRpc = deletePackRpc,
       _addStickerRpc = addStickerRpc,
       _removeStickerRpc = removeStickerRpc;

  final ListStickerPacksRpc _listPacksRpc;
  final CreateStickerPackRpc _createPackRpc;
  final RenameStickerPackRpc _renamePackRpc;
  final DeleteStickerPackRpc _deletePackRpc;
  final AddStickerRpc _addStickerRpc;
  final RemoveStickerRpc _removeStickerRpc;

  /// Production-фабрика.
  static NsgMessengerStickers attach({required Client client}) {
    MessengerSessionManager session() =>
        MessengerRuntime.instance.sessionManager;
    return NsgMessengerStickers._(
      listPacksRpc: () =>
          withAuthRetry(() => client.sticker.listMyPacks(), session()),
      createPackRpc: ({required String name}) =>
          withAuthRetry(() => client.sticker.createPack(name: name), session()),
      renamePackRpc: ({required int packId, required String name}) =>
          withAuthRetry(
            () => client.sticker.renamePack(packId: packId, name: name),
            session(),
          ),
      deletePackRpc: ({required int packId}) => withAuthRetry(
        () => client.sticker.deletePack(packId: packId),
        session(),
      ),
      addStickerRpc:
          ({
            required int packId,
            required ByteData bytes,
            required String mimeType,
            required String alias,
          }) => withAuthRetry(
            () => client.sticker.addSticker(
              packId: packId,
              bytes: bytes,
              mimeType: mimeType,
              alias: alias,
            ),
            session(),
          ),
      removeStickerRpc: ({required int stickerId}) => withAuthRetry(
        () => client.sticker.removeSticker(stickerId: stickerId),
        session(),
      ),
    );
  }

  /// Тест-фабрика: подменные вызовы вместо живого клиента.
  static NsgMessengerStickers withRpcs({
    required ListStickerPacksRpc listPacksRpc,
    CreateStickerPackRpc? createPackRpc,
    RenameStickerPackRpc? renamePackRpc,
    DeleteStickerPackRpc? deletePackRpc,
    AddStickerRpc? addStickerRpc,
    RemoveStickerRpc? removeStickerRpc,
  }) => NsgMessengerStickers._(
    listPacksRpc: listPacksRpc,
    createPackRpc:
        createPackRpc ?? ({required String name}) => throw UnimplementedError(),
    renamePackRpc:
        renamePackRpc ??
        ({required int packId, required String name}) =>
            throw UnimplementedError(),
    deletePackRpc:
        deletePackRpc ?? ({required int packId}) => throw UnimplementedError(),
    addStickerRpc:
        addStickerRpc ??
        ({
          required int packId,
          required ByteData bytes,
          required String mimeType,
          required String alias,
        }) => throw UnimplementedError(),
    removeStickerRpc:
        removeStickerRpc ??
        ({required int stickerId}) => throw UnimplementedError(),
  );

  /// Мои наборы вместе со стикерами — один вызов на открытие пикера.
  Future<List<StickerPackView>> listMyPacks() => _listPacksRpc();

  Future<StickerPack> createPack(String name) => _createPackRpc(name: name);

  Future<StickerPack> renamePack(int packId, String name) =>
      _renamePackRpc(packId: packId, name: name);

  Future<void> deletePack(int packId) => _deletePackRpc(packId: packId);

  /// Добавить картинку в набор. Отказ приезжает типизированным
  /// (`StickerRejectedException`) с готовым человеческим текстом — его и
  /// показывайте, не сочиняя свой.
  Future<Sticker> addSticker({
    required int packId,
    required ByteData bytes,
    required String mimeType,
    required String alias,
  }) => _addStickerRpc(
    packId: packId,
    bytes: bytes,
    mimeType: mimeType,
    alias: alias,
  );

  Future<void> removeSticker(int stickerId) =>
      _removeStickerRpc(stickerId: stickerId);
}
