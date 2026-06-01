import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../rooms/nsg_messenger_rooms.dart';
import '../widgets/nsg_avatar_image.dart';

/// **B16-extension**: добавление одного или нескольких участников в
/// существующую group-комнату.
///
/// UX:
///   * Default-список «Знакомые» (participants всех моих комнат, distinct).
///     Подгружается через [NsgMessengerRooms.listKnownContacts] в
///     `initState`.
///   * Search-поле — при ≥ 2 символах переключается на `searchUsers`
///     (debounce 300ms).
///   * Multi-select: tap toggle-ит выбор; выбранные собираются в chip-row
///     сверху.
///   * Bottom-button «Добавить» enabled когда ≥ 1 selected; зовёт
///     [NsgMessengerRooms.inviteToRoom] последовательно для каждого
///     id-а. На ошибку — snackbar + UI остаётся на экране, чтобы юзер мог
///     ретрайнуть. На success — pop с `true`, host вызывает rooms
///     `invalidate(roomId)` (уже делается в inviteToRoom internals).
class AddMembersToGroupScreen extends StatefulWidget {
  const AddMembersToGroupScreen({
    super.key,
    required this.roomId,
    @visibleForTesting this.roomsOverride,
  });

  final int roomId;
  final NsgMessengerRooms? roomsOverride;

  @override
  State<AddMembersToGroupScreen> createState() =>
      _AddMembersToGroupScreenState();
}

class _AddMembersToGroupScreenState extends State<AddMembersToGroupScreen> {
  late final NsgMessengerRooms _rooms;
  final _queryCtrl = TextEditingController();
  Timer? _debounce;
  bool _busy = false;
  String? _error;
  List<RoomParticipant> _searchResults = const [];
  bool _searched = false;

  List<RoomParticipant> _contacts = const [];
  bool _contactsLoading = true;

  /// Кого уже исключаем из default-списка — текущие members комнаты
  /// (resolve через `rooms.get(roomId).participants`). Без этого юзер
  /// видит «знакомых», уже состоящих в этой группе.
  Set<int> _existingMemberIds = const <int>{};

  final Map<int, RoomParticipant> _selected = <int, RoomParticipant>{};

  bool get _showingContacts => _queryCtrl.text.trim().length < 2;

  List<RoomParticipant> get _visibleList {
    final base = _showingContacts ? _contacts : _searchResults;
    if (_existingMemberIds.isEmpty) return base;
    return base
        .where((p) => !_existingMemberIds.contains(p.messengerUserId))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _rooms = widget.roomsOverride ?? MessengerRuntime.instance.rooms;
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final results = await Future.wait([
        _rooms.listKnownContacts(),
        _rooms.get(widget.roomId),
      ]);
      if (!mounted) return;
      final contacts = results[0] as List<RoomParticipant>;
      final details = results[1] as RoomDetails;
      setState(() {
        _contacts = contacts;
        _existingMemberIds =
            details.participants.map((p) => p.messengerUserId).toSet();
        _contactsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contactsLoading = false;
        _error = '$e';
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() {});
    if (value.trim().length < 2) {
      setState(() {
        _searchResults = const [];
        _searched = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), _runSearch);
  }

  Future<void> _runSearch() async {
    final q = _queryCtrl.text.trim();
    if (q.length < 2) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final list = await _rooms.searchUsers(query: q);
      if (!mounted) return;
      setState(() {
        _searchResults = list;
        _searched = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggle(RoomParticipant u) {
    setState(() {
      if (_selected.containsKey(u.messengerUserId)) {
        _selected.remove(u.messengerUserId);
      } else {
        _selected[u.messengerUserId] = u;
      }
    });
  }

  Future<void> _invite() async {
    if (_selected.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    var added = 0;
    String? lastError;
    for (final user in _selected.values.toList()) {
      try {
        await _rooms.inviteToRoom(
          roomId: widget.roomId,
          targetMessengerUserId: user.messengerUserId,
        );
        added++;
      } catch (e) {
        lastError = '$e';
        if (kDebugMode) {
          debugPrint(
            '[AddMembersToGroupScreen] invite failed user=${user.messengerUserId} '
            'err=$e',
          );
        }
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (lastError != null && added == 0) {
      setState(() => _error = lastError);
      return;
    }
    Navigator.of(context).pop(true);
    if (lastError != null) {
      // частичный успех — info-snackbar.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Добавлено $added, ошибка: $lastError')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить участников')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _queryCtrl,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Email или ник',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: _busy
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final u in _selected.values)
                    InputChip(
                      label: Text(u.displayName ?? u.matrixUserId),
                      onDeleted: () => _toggle(u),
                    ),
                ],
              ),
            ),
          if (_showingContacts && _visibleList.isNotEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ЗНАКОМЫЕ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _showingContacts && _contactsLoading
                ? const Center(child: CircularProgressIndicator())
                : _visibleList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _showingContacts
                                ? 'Нет доступных контактов — введи поиск.'
                                : (_searched
                                    ? 'Никого не нашлось.'
                                    : ''),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _visibleList.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final u = _visibleList[i];
                          final selected =
                              _selected.containsKey(u.messengerUserId);
                          return ListTile(
                            leading: NsgAvatarImage(
                              mxcUrl: u.avatarUrl,
                              fallbackName: u.displayName ?? u.matrixUserId,
                              size: 40,
                            ),
                            title: Text(
                              u.displayName ?? u.matrixUserId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              u.matrixUserId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              color: selected
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                            onTap: () => _toggle(u),
                          );
                        },
                      ),
          ),
          if (_error != null)
            Container(
              color: theme.colorScheme.errorContainer,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Text(
                _error!,
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontSize: 13,
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: FilledButton(
                onPressed:
                    (_selected.isNotEmpty && !_busy) ? _invite : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  _selected.isEmpty
                      ? 'Выберите участников'
                      : 'Добавить (${_selected.length})',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
