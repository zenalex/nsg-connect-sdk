import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../support/my_tickets_controller.dart';
import '../support/my_tickets_rpc.dart';
import '../support/my_tickets_state.dart';
import 'chat_screen.dart';

/// **TASK57 фаза 1 + issue #19**: экран «Мои обращения» — список обращений
/// пользователя с гранулярным статусом жизненного цикла (Новое / В работе /
/// Принято / Отклонено), резолюцией и ссылкой на GitHub issue (если заведён).
/// Тап по строке открывает support-чат обращения ([ChatScreen]). Открывается
/// через `NsgMessenger.openMyTickets(context)`.
class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({
    super.key,
    @visibleForTesting this.rpcOverride,
    @visibleForTesting this.onOpenRoom,
  });

  /// Visible-for-testing — подмена RPC без Serverpod-клиента.
  final MyTicketsRpc? rpcOverride;

  /// Visible-for-testing — подмена навигации в чат.
  final void Function(BuildContext context, int roomId)? onOpenRoom;

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  late final MyTicketsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MyTicketsController(
      rpc:
          widget.rpcOverride ??
          ClientMyTicketsRpc(MessengerRuntime.instance.client),
    );
    unawaited(_controller.init());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openRoom(int roomId) async {
    final opener = widget.onOpenRoom;
    if (opener != null) {
      opener(context, roomId);
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(roomId: roomId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои обращения')),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final state = _controller.state;
          return switch (state) {
            MyTicketsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            MyTicketsUnavailable() => _ErrorView(onRetry: _controller.refresh),
            MyTicketsReady(:final tickets) =>
              tickets.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _controller.refresh,
                      child: ListView.separated(
                        itemCount: tickets.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) => _TicketTile(
                          ticket: tickets[i],
                          onTap: () => _openRoom(tickets[i].roomId),
                        ),
                      ),
                    ),
          };
        },
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket, required this.onTap});

  final TicketView ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stage = _stageStyle(ticket.stage);
    return ListTile(
      key: Key('ticketTile_${ticket.id}'),
      leading: CircleAvatar(child: Icon(_kindIcon(ticket.kind))),
      title: Text(_titleFor(ticket)),
      subtitle: ticket.lastEventPreview == null
          ? null
          : Text(
              ticket.lastEventPreview!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: _StatusBadge(text: stage.label, color: stage.color),
      onTap: onTap,
    );
  }

  static IconData _kindIcon(String kind) => switch (kind) {
    'bug' => Icons.bug_report_outlined,
    'idea' => Icons.lightbulb_outline,
    _ => Icons.support_agent_outlined,
  };

  /// **issue #19**: подпись + цвет бейджа гранулярного статуса обращения.
  /// `new` → Новое, `in_progress` → В работе, `accepted` → Принято,
  /// `rejected` → Отклонено. Неизвестное значение → «Новое» (безопасный
  /// дефолт для forward-compat).
  static ({String label, Color color}) _stageStyle(String stage) =>
      switch (stage) {
        'in_progress' => (label: 'В работе', color: Colors.orange),
        'accepted' => (label: 'Принято', color: Colors.green),
        'rejected' => (label: 'Отклонено', color: Colors.redAccent),
        _ => (label: 'Новое', color: Colors.blue),
      };

  static String _titleFor(TicketView t) {
    final kind = switch (t.kind) {
      'bug' => 'Ошибка',
      'idea' => 'Идея',
      _ => 'Поддержка',
    };
    return t.externalTaskKey != null ? '$kind · ${t.externalTaskKey}' : kind;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Обращений пока нет.\nНапишите в поддержку из профиля.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Не удалось загрузить обращения'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}
