import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import 'chat_screen.dart';

/// Минимальный экран создания чата на TASK14: только direct chat по
/// числовому `messengerUserId`. Search-by-name + group-creation —
/// **TASK42** (требует серверного `searchUsers` endpoint, отдельный
/// scope).
///
/// На несуществующего peer-а или peer-а в другом tenant-е сервер
/// возвращает [PeerUnavailableException] (anti-enumeration, общий
/// shape для трёх случаев). UI показывает один и тот же snackbar
/// «пользователь недоступен».
class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final _ctl = TextEditingController();
  bool _busy = false;
  String? _localError;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final text = _ctl.text.trim();
    final id = int.tryParse(text);
    if (id == null || id <= 0) {
      setState(() => _localError = NsgL10n.of(context).createChatInvalidId);
      return;
    }
    setState(() {
      _busy = true;
      _localError = null;
    });
    try {
      final details = await MessengerRuntime.instance.rooms.createDirect(id);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => ChatScreen(roomId: details.id)),
      );
    } on PeerUnavailableException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(NsgL10n.of(context).createChatPeerUnavailable)),
      );
    } catch (e, st) {
      if (!mounted) return;
      // Гейт приватности ловится веткой выше — сюда долетает только
      // неожиданное, а пользователь при этом видит сырой текст исключения.
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'chat.action': 'createDirect'},
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(NsgL10n.of(context).commonNewChat)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              NsgL10n.of(context).createChatHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'messengerUserId',
                errorText: _localError,
                border: const OutlineInputBorder(),
              ),
              enabled: !_busy,
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _create,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chat),
              label: Text(NsgL10n.of(context).createChatSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
