import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../contacts/nsg_messenger_contacts.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../widgets/nsg_avatar_image.dart';
import 'chat_screen.dart';

// Chatista Glass токены (сверены с people_screen / settings_screen).
const _bg = Color(0xFF1F1A15);
const _fg = Color(0xF5FFFCF8);
const _fgMuted = Color(0xB8FFFCF8);
const _fgDim = Color(0x80FFFCF8);
const _card = Color(0x14FFFFFF);
const _border = Color(0x1FFFFFFF);
const _onAccent = Color(0xFF1A0F1A);

/// **TASK52 итер.2 — входящие карточки-заявки** (message-requests).
///
/// Кто-то ВНЕ моих контактов, кого закрыл гейт «кто может мне писать»,
/// отправил заявку со своей визиткой. Здесь я вижу его публичные поля и
/// решаю: принять (→ взаимный контакт + direct-чат), отклонить (cooldown
/// отобьёт спам) или заблокировать (заявка гаснет молча).
///
/// Бейдж на входе (people_screen) подпитывается тем же
/// `contacts.incomingRequestCount`, что и этот список.
class ContactRequestsScreen extends StatefulWidget {
  const ContactRequestsScreen({super.key});

  @override
  State<ContactRequestsScreen> createState() => _ContactRequestsScreenState();
}

class _ContactRequestsScreenState extends State<ContactRequestsScreen> {
  NsgMessengerContacts get _contacts => MessengerRuntime.instance.contacts;

  List<ContactRequestView>? _items;
  Object? _error;
  // requestId, по которым сейчас идёт действие — для спиннера на карточке.
  final Set<int> _busy = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await _contacts.listIncomingRequests(force: true);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// Отправить в трекер ошибку действия над заявкой, которую увидел
  /// пользователь. Снек `requestActionFailed` один на accept/decline/block —
  /// без тега [action] в трекере эти пути неотличимы.
  void _reportActionFailed(Object e, StackTrace st, String action) {
    MessengerRuntime.instance.reportError(
      e,
      st,
      tags: {'request.action': action},
    );
  }

  Future<void> _accept(ContactRequestView r) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = NsgL10n.of(context);
    setState(() => _busy.add(r.requestId));
    try {
      final room = await _contacts.acceptContactRequest(r.requestId);
      if (!mounted) return;
      setState(() {
        _items?.removeWhere((e) => e.requestId == r.requestId);
        _busy.remove(r.requestId);
      });
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ChatScreen(roomId: room.id)),
      );
    } catch (e, st) {
      _reportActionFailed(e, st, 'accept');
      if (!mounted) return;
      setState(() => _busy.remove(r.requestId));
      messenger.showSnackBar(SnackBar(content: Text(l.requestActionFailed)));
    }
  }

  Future<void> _decline(ContactRequestView r) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = NsgL10n.of(context);
    setState(() => _busy.add(r.requestId));
    try {
      await _contacts.declineContactRequest(r.requestId);
      if (!mounted) return;
      setState(() {
        _items?.removeWhere((e) => e.requestId == r.requestId);
        _busy.remove(r.requestId);
      });
      messenger.showSnackBar(SnackBar(content: Text(l.requestDeclined)));
    } catch (e, st) {
      _reportActionFailed(e, st, 'decline');
      if (!mounted) return;
      setState(() => _busy.remove(r.requestId));
      messenger.showSnackBar(SnackBar(content: Text(l.requestActionFailed)));
    }
  }

  /// Заблокировать отправителя: [blockUser] + [declineContactRequest]
  /// (заявка исчезает, повтор невозможен — send «в никуда»).
  Future<void> _block(ContactRequestView r) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = NsgL10n.of(context);
    final name = r.displayName ?? r.username ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        title: Text(
          l.contactBlockConfirm(name),
          style: const TextStyle(color: _fg, fontSize: 17),
        ),
        content: Text(
          l.contactBlockBody,
          style: const TextStyle(color: _fgMuted, fontSize: 14, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(NsgL10n.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: Text(l.contactBlock),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy.add(r.requestId));
    try {
      await _contacts.blockUser(r.fromMessengerUserId);
      await _contacts.declineContactRequest(r.requestId);
      if (!mounted) return;
      setState(() {
        _items?.removeWhere((e) => e.requestId == r.requestId);
        _busy.remove(r.requestId);
      });
      messenger.showSnackBar(SnackBar(content: Text(l.contactBlocked)));
    } catch (e, st) {
      _reportActionFailed(e, st, 'block');
      if (!mounted) return;
      setState(() => _busy.remove(r.requestId));
      messenger.showSnackBar(SnackBar(content: Text(l.requestActionFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final items = _items;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          l.requestsTitle,
          style: const TextStyle(
            color: _fg,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _fgMuted),
      ),
      body: _error != null
          ? _ErrorRetry(message: l.requestsLoadFailed, onRetry: _load)
          : items == null
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? _EmptyState(title: l.requestsEmpty, hint: l.requestsEmptyHint)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => _RequestCard(
                  request: items[i],
                  busy: _busy.contains(items[i].requestId),
                  onAccept: () => _accept(items[i]),
                  onDecline: () => _decline(items[i]),
                  onBlock: () => _block(items[i]),
                ),
              ),
            ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    required this.onBlock,
  });

  final ContactRequestView request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final name = request.displayName ?? request.username ?? '—';
    final note = request.note?.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NsgAvatarImage(
                mxcUrl: request.avatarUrl,
                fallbackName: name,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: _fg,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (request.username != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${request.username}',
                        style: TextStyle(
                          color: accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      note?.isNotEmpty == true ? note! : l.requestWantsToConnect,
                      style: const TextStyle(
                        color: _fgMuted,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: _onAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      l.requestAccept,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _fgMuted,
                      side: const BorderSide(color: _border, width: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      l.requestDecline,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: l.contactBlock,
                  onPressed: onBlock,
                  icon: Icon(Icons.block, size: 20, color: Colors.red.shade400),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mail_outline, size: 44, color: _fgDim),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _fg,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _fgMuted, fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: _fgMuted, fontSize: 14)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(foregroundColor: _fg),
            child: Text(NsgL10n.of(context).commonRetry),
          ),
        ],
      ),
    );
  }
}
