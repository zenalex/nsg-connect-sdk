import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../rooms/room_picker_sheet.dart';

/// **Пересылка (forward)** — bottom-sheet выбора целевого чата.
///
/// Тонкая обёртка над переиспользуемым ядром [showRoomPicker] (список +
/// поиск + сортировка по активности). То же ядро использует share-in
/// «Куда отправить?» (TASK49) — логика пикера НЕ дублируется.
///
/// Чистый селектор: сам НЕ пересылает — возвращает выбранную [RoomSummary]
/// через `Navigator.pop`, а сам forward (+ snackbar) делает вызывающая
/// сторона (action-sheet сообщения). [roomsLoader] по умолчанию тянет
/// `MessengerRuntime.instance.rooms.list`, тест подменяет его in-memory
/// списком.
///
/// Возвращает выбранную комнату или `null`, если юзер закрыл лист.
Future<RoomSummary?> showForwardPicker({
  required BuildContext context,
  Future<List<RoomSummary>> Function()? roomsLoader,
}) {
  final l = NsgL10n.of(context);
  return showRoomPicker(
    context: context,
    title: l.forwardPickerTitle,
    searchHint: l.forwardSearchHint,
    emptyText: l.forwardNoRooms,
    errorText: l.forwardFailed,
    roomsLoader: roomsLoader,
  );
}

/// **F1** — тот же forward-пикер в режиме мультивыбора: можно выбрать
/// НЕСКОЛЬКО целевых чатов (чекбоксы) и переслать сразу во все. Возвращает
/// список выбранных комнат (непустой) или `null`, если лист закрыли.
Future<List<RoomSummary>?> showForwardPickerMulti({
  required BuildContext context,
  Future<List<RoomSummary>> Function()? roomsLoader,
}) {
  final l = NsgL10n.of(context);
  return showMultiRoomPicker(
    context: context,
    title: l.forwardPickerTitle,
    searchHint: l.forwardSearchHint,
    emptyText: l.forwardNoRooms,
    errorText: l.forwardFailed,
    confirmLabel: l.forwardMultiButton,
    roomsLoader: roomsLoader,
  );
}
