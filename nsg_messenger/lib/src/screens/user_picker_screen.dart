/// **Выбор человека из мессенджера** — общий пикер.
///
/// Жалоба владельца: «зачем мне вбивать email, если нужен пользователь
/// chatista?». Справедливо: email — это способ сослаться на человека
/// ИЗВНЕ, а внутри мессенджера человек уже есть, и выбирать его надо из
/// списка.
///
/// Сначала показываем знакомых (участники общих комнат), с двух символов
/// — поиск по всем пользователям тенанта. Тот же источник людей, что у
/// «Добавить участников» в группу: второй, расходящийся список — верный
/// способ получить «этого человека видно там, но не видно тут».
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../theme/overlay_surface.dart';
import '../widgets/nsg_avatar_image.dart';

/// Открыть пикер и вернуть выбранного человека (или `null`).
Future<RoomParticipant?> pickMessengerUser(
  BuildContext context, {
  String? title,
  String? searchHint,
}) {
  return Navigator.of(context).push<RoomParticipant>(
    MaterialPageRoute<RoomParticipant>(
      builder: (_) => UserPickerScreen(title: title, searchHint: searchHint),
    ),
  );
}

/// Выбор пользователя тенанта: знакомые контакты + поиск с дебаунсом.
/// Тот же путь, что у «Добавить участников» в группу — переиспользуем
/// `rooms.listKnownContacts()`/`rooms.searchUsers()`, чтобы не заводить
/// второй, расходящийся источник людей.
class UserPickerScreen extends StatefulWidget {
  const UserPickerScreen({super.key, this.title, this.searchHint});

  /// Заголовок экрана. По умолчанию — общий «Выбрать человека».
  final String? title;

  /// Подсказка поля поиска.
  final String? searchHint;

  @override
  State<UserPickerScreen> createState() => UserPickerScreenState();
}

class UserPickerScreenState extends State<UserPickerScreen> {
  final _queryCtrl = TextEditingController();
  Timer? _debounce;

  List<RoomParticipant> _contacts = const [];
  List<RoomParticipant> _results = const [];
  bool _loading = true;
  bool _searched = false;

  bool get _showingContacts => _queryCtrl.text.trim().length < 2;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await MessengerRuntime.instance.rooms
          .listKnownContacts();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } catch (_) {
      // Контакты — удобство, не обязательное условие: поиск работает и без них.
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() {});
    if (value.trim().length < 2) {
      setState(() {
        _results = const [];
        _searched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), _runSearch);
  }

  Future<void> _runSearch() async {
    final q = _queryCtrl.text.trim();
    if (q.length < 2) return;
    setState(() => _loading = true);
    try {
      final found = await MessengerRuntime.instance.rooms.searchUsers(query: q);
      if (!mounted) return;
      setState(() {
        _results = found;
        _searched = true;
        _loading = false;
      });
    } catch (e, st) {
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'userPicker.action': 'searchUsers'},
      );
      if (mounted) {
        setState(() {
          _results = const [];
          _searched = true;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final list = _showingContacts ? _contacts : _results;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? l.pulsePickMember)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _queryCtrl,
              autofocus: true,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: widget.searchHint ?? l.pulseMemberSearchHint,
                border: const OutlineInputBorder(),
                fillColor: kOverlaySurface,
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _searched || _showingContacts
                            ? l.pulseMemberSearchEmpty
                            : '',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final u = list[i];
                      final name = u.displayName?.trim().isNotEmpty == true
                          ? u.displayName!
                          : u.matrixUserId;
                      return ListTile(
                        leading: NsgAvatarImage(
                          mxcUrl: u.avatarUrl,
                          fallbackName: name,
                          size: 40,
                        ),
                        title: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          u.username != null && u.username!.isNotEmpty
                              ? '@${u.username}'
                              : u.matrixUserId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () => Navigator.of(context).pop(u),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
