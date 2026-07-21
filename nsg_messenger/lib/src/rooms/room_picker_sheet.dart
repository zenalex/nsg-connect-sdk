import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import 'room_summary_tile.dart';

/// **Переиспользуемое ядро «выбор чата»** (bottom-sheet со списком комнат +
/// поиском). Общая база для внутренней пересылки (`showForwardPicker`,
/// TASK-forward) и share-in «Куда отправить?» (TASK49 §3). Логика списка/
/// поиска НЕ дублируется — оба фичи зовут этот пикер (см. TASK49: «переиспуёт
/// forward-picker core»).
///
/// Чистый селектор: сам НЕ выполняет действие — возвращает выбранную
/// [RoomSummary] через `Navigator.pop`, `null` если лист закрыли. Заголовок
/// / плейсхолдер / тексты пустого-состояния и ошибки передаются вызывающей
/// стороной (у неё есть локализованные строки под свой сценарий).
///
/// [roomsLoader] по умолчанию тянет `MessengerRuntime.instance.rooms.list`
/// (сортировка по активности — `lastMessageAt`, cursor v2 из TASK42); тест
/// подменяет его in-memory списком.
Future<RoomSummary?> showRoomPicker({
  required BuildContext context,
  required String title,
  required String searchHint,
  required String emptyText,
  required String errorText,
  Future<List<RoomSummary>> Function()? roomsLoader,
  Set<int> disabledRoomIds = const <int>{},
  String? disabledBadge,
}) {
  final loader =
      roomsLoader ?? () => MessengerRuntime.instance.rooms.list(limit: 100);
  return showModalBottomSheet<RoomSummary>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) => _RoomPickerBody(
      loader: loader,
      title: title,
      searchHint: searchHint,
      emptyText: emptyText,
      errorText: errorText,
      disabledRoomIds: disabledRoomIds,
      disabledBadge: disabledBadge,
    ),
  );
}

/// **F1** — тот же пикер в режиме МУЛЬТИВЫБОРА: чекбоксы у строк + кнопка
/// «[confirmLabel]» внизу (лейбл зависит от числа выбранных). Возвращает
/// список выбранных комнат (непустой) или `null`, если лист закрыли без
/// подтверждения. Ядро списка/поиска общее с [showRoomPicker].
Future<List<RoomSummary>?> showMultiRoomPicker({
  required BuildContext context,
  required String title,
  required String searchHint,
  required String emptyText,
  required String errorText,
  required String Function(int count) confirmLabel,
  Future<List<RoomSummary>> Function()? roomsLoader,
}) {
  final loader =
      roomsLoader ?? () => MessengerRuntime.instance.rooms.list(limit: 100);
  return showModalBottomSheet<List<RoomSummary>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) => _RoomPickerBody(
      loader: loader,
      title: title,
      searchHint: searchHint,
      emptyText: emptyText,
      errorText: errorText,
      multiSelect: true,
      confirmLabel: confirmLabel,
    ),
  );
}

class _RoomPickerBody extends StatefulWidget {
  const _RoomPickerBody({
    required this.loader,
    required this.title,
    required this.searchHint,
    required this.emptyText,
    required this.errorText,
    this.multiSelect = false,
    this.confirmLabel,
    this.disabledRoomIds = const <int>{},
    this.disabledBadge,
  });

  final Future<List<RoomSummary>> Function() loader;
  final String title;
  final String searchHint;
  final String emptyText;
  final String errorText;

  /// **issue #50 follow-up**: комнаты, которые ПОКАЗЫВАЮТСЯ, но не
  /// выбираются (например, бот уже добавлен). Показываем, а не прячем:
  /// исчезнувшая из списка комната читается как баг пикера, а строка с
  /// бейджем [disabledBadge] отвечает на вопрос «а почему нельзя» сама.
  final Set<int> disabledRoomIds;

  /// Текст-бейдж у отключённых строк (обязателен по смыслу, если
  /// [disabledRoomIds] непуст).
  final String? disabledBadge;

  /// **F1**: режим мультивыбора (чекбоксы + кнопка подтверждения).
  final bool multiSelect;

  /// **F1**: лейбл кнопки подтверждения по числу выбранных (напр.
  /// «Переслать (3)»). Обязателен при [multiSelect].
  final String Function(int count)? confirmLabel;

  @override
  State<_RoomPickerBody> createState() => _RoomPickerBodyState();
}

class _RoomPickerBodyState extends State<_RoomPickerBody> {
  late final Future<List<RoomSummary>> _future;
  final TextEditingController _search = TextEditingController();
  String _query = '';

  /// **F1**: выбранные комнаты (id → RoomSummary), сохраняем сам объект,
  /// чтобы вернуть его вызывающей стороне без повторного поиска.
  final Map<int, RoomSummary> _selected = <int, RoomSummary>{};

  void _toggle(RoomSummary room) {
    setState(() {
      if (_selected.remove(room.id) == null) _selected[room.id] = room;
    });
  }

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
    _search.addListener(_syncQuery);
  }

  void _syncQuery() {
    final q = _search.text.trim().toLowerCase();
    if (q != _query) setState(() => _query = q);
  }

  @override
  void dispose() {
    _search.removeListener(_syncQuery);
    _search.dispose();
    super.dispose();
  }

  List<RoomSummary> _filter(List<RoomSummary> rooms) {
    if (_query.isEmpty) return rooms;
    return rooms
        .where((r) => (r.name ?? '').toLowerCase().contains(_query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    // Ограничиваем высоту листа ~85% экрана; внутренний список скроллится.
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                autofocus: false,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: widget.searchHint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Flexible(
              child: FutureBuilder<List<RoomSummary>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return _EmptyOrError(text: widget.errorText);
                  }
                  final rooms = _filter(snapshot.data ?? const <RoomSummary>[]);
                  if (rooms.isEmpty) {
                    return _EmptyOrError(text: widget.emptyText);
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: rooms.length,
                    itemBuilder: (_, i) {
                      final room = rooms[i];
                      final disabled = widget.disabledRoomIds.contains(
                        room.id,
                      );
                      if (disabled) {
                        // Приглушённая нетапаемая строка + бейдж-причина.
                        return Opacity(
                          opacity: 0.5,
                          child: Row(
                            children: [
                              Expanded(
                                child: IgnorePointer(
                                  child: RoomSummaryTile(room: room),
                                ),
                              ),
                              if (widget.disabledBadge != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Text(
                                    widget.disabledBadge!,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }
                      if (!widget.multiSelect) {
                        return RoomSummaryTile(
                          room: room,
                          onTap: () => Navigator.of(context).pop(room),
                        );
                      }
                      // **F1**: строка-чекбокс. IgnorePointer гасит InkWell
                      // самой плитки — тап по всей строке тогглит выбор.
                      final selected = _selected.containsKey(room.id);
                      return InkWell(
                        onTap: () => _toggle(room),
                        child: Row(
                          children: [
                            Checkbox(
                              value: selected,
                              onChanged: (_) => _toggle(room),
                            ),
                            Expanded(
                              child: IgnorePointer(
                                child: RoomSummaryTile(room: room),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (widget.multiSelect)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.of(
                            context,
                          ).pop(_selected.values.toList(growable: false)),
                    child: Text(widget.confirmLabel!(_selected.length)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrError extends StatelessWidget {
  const _EmptyOrError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
