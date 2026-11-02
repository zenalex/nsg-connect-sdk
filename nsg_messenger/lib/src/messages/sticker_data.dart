import 'package:flutter/foundation.dart' show immutable;

/// **issue #151**: стикер, приехавший в сыром Matrix-content-е сообщения под
/// ключом `nsg.sticker`. Сообщение при этом имеет
/// `msgType == 'nsg.sticker'`, а человекочитаемый запасной текст — в `body`
/// (`:cat:`).
///
/// **Почему свой msgType, а не `m.sticker`.** В Matrix `m.sticker` — это
/// отдельный ТИП СОБЫТИЯ, а не msgtype внутри `m.room.message`; весь наш
/// путь отправки, разбора `/sync` и хранения построен вокруг
/// `m.room.message`, и новый тип события означал бы ветку в каждом из трёх
/// слоёв. Свой msgType ложится в уже существующий механизм: точно так же
/// сделана статус-карточка (`nsg.status_card`), и лента переключает вид
/// одной веткой.
///
/// Цена решения известна: чужие Matrix-клиенты покажут `body`, то есть
/// `:cat:` текстом. Совместимость, если понадобится, добавляется поверх —
/// тем же mxc вторым событием, ничего не переписывая.
///
/// Формат:
/// ```json
/// {"id": 34, "alias": "cat", "packId": 12}
/// ```
///
/// Сама картинка едет обычным вложением (`attachment`) — стикер это та же
/// картинка, только маленькая и с именем.
@immutable
class StickerData {
  const StickerData({required this.alias, this.id, this.packId});

  /// Идентификатор стикера в наборе отправителя. Нужен, чтобы повторить
  /// отправку упавшего пузыря: сервер принимает только id, а из имени и
  /// набора его не восстановить. `null` — сообщение от старой сборки,
  /// которая id не присылала: рисованию это не мешает, повтор просто не
  /// сработает.
  final int? id;

  /// Короткое имя (`cat`), без двоеточий. Показывается как подпись при
  /// недоступной картинке и участвует в поиске по ленте.
  final String alias;

  /// Из какого набора. `null` — набор удалён или сообщение приехало от
  /// клиента, который его не прислал: рисовать стикер это не мешает.
  final int? packId;

  /// Разобрать из сырого content-а. `null` — ключа нет или он не объект.
  ///
  /// Толерантно к битому: стикер без имени не бывает, но и ронять из-за
  /// него ленту нельзя — вернём `null`, и сообщение отрисуется как обычное
  /// вложение.
  static StickerData? tryParse(Map<String, dynamic>? content) {
    final raw = content?['nsg.sticker'];
    if (raw is! Map) return null;
    final alias = raw['alias'];
    if (alias is! String || alias.trim().isEmpty) return null;
    final packId = raw['packId'];
    final id = raw['id'];
    return StickerData(
      alias: alias.trim(),
      id: id is int ? id : null,
      packId: packId is int ? packId : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StickerData &&
      other.alias == alias &&
      other.id == id &&
      other.packId == packId;

  @override
  int get hashCode => Object.hash(alias, id, packId);

  @override
  String toString() =>
      'StickerData(:$alias:${packId == null ? '' : ' #$packId'})';
}

/// Ключ, под которым стикер едет в content-е, и значение `msgType`.
///
/// Одной константой на клиент и сервер быть не может (разные пакеты),
/// поэтому держим рядом с разбором: разъедутся — стикер молча станет
/// обычной картинкой, и заметят это не сразу.
const String kStickerMsgType = 'nsg.sticker';
const String kStickerContentKey = 'nsg.sticker';
