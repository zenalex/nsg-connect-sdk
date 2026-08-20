import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messages/message_bubble.dart' show taskStageColor, taskStageLabel;
import '../messenger_runtime.dart';
import '../support/my_tasks_controller.dart';
import '../support/my_tasks_rpc.dart';
import '../support/my_tasks_state.dart';
import '../support/room_tasks_controller.dart';
import '../widgets/unread_pill.dart';
import 'chat_screen.dart';
import 'thread_screen.dart';

/// **TASK84 итерация 1**: экран «Задачи» — задачи из ВСЕХ моих активных комнат
/// (роль «участник» = член комнаты). Две вкладки:
///   * **Все** (`all`) — задачи всех моих комнат;
///   * **Я инициатор** (`initiator`) — только заведённые мной.
/// Отдельно от «Мои обращения» ([MyTicketsScreen], роль «заявитель»); оба входа
/// живут в профиле. Строка — стиль «Мои обращения» + значок стадии палитры
/// TASK83 ([taskStageColor]/[taskStageLabel]); тап открывает СРАЗУ тред задачи
/// ([TicketView.threadRootEventId], TASK82), а если треда нет — комнату.
/// Открывается через `NsgMessenger.openTasks(context)`.
class TasksScreen extends StatefulWidget {
  const TasksScreen({
    super.key,
    this.roomId,
    this.roomTitle,
    @visibleForTesting this.rpcOverride,
    @visibleForTesting this.onOpenRoom,
    @visibleForTesting this.onOpenThread,
  });

  /// **TASK88**: если задан — экран показывает задачи ТОЛЬКО этой комнаты
  /// (тап по иконке задач в шапке чата), одним списком без вкладок. null →
  /// обычный режим «все мои задачи» (две вкладки Все/Я инициатор).
  final int? roomId;

  /// **TASK88**: имя комнаты для заголовка «Задачи: <комната>» в
  /// room-scoped-режиме. null → падаем на общий заголовок «Задачи».
  final String? roomTitle;

  /// Visible-for-testing — подмена RPC без Serverpod-клиента.
  final MyTasksRpc? rpcOverride;

  /// Visible-for-testing — подмена навигации в чат.
  final void Function(BuildContext context, int roomId)? onOpenRoom;

  /// Visible-for-testing — подмена навигации в тред задачи.
  final void Function(BuildContext context, TicketView task)? onOpenThread;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late final MyTasksRpc _rpc;

  @override
  void initState() {
    super.initState();
    _rpc =
        widget.rpcOverride ??
        ClientMyTasksRpc(MessengerRuntime.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    // **TASK88** room-scoped: задачи одной комнаты — один список без вкладок
    // (фильтр `all`, но в рамках комнаты), заголовок «Задачи: <комната>».
    final roomId = widget.roomId;
    if (roomId != null) {
      final title = widget.roomTitle;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            (title != null && title.trim().isNotEmpty)
                ? l.tasksScreenTitleForRoom(title)
                : l.tasksScreenTitle,
          ),
        ),
        body: _RoomTasksTab(
          key: const Key('tasksTab_room'),
          rpc: _rpc,
          roomId: roomId,
          emptyText: l.tasksEmptyAll,
          onOpenRoom: widget.onOpenRoom,
        ),
      );
    }
    // Две вкладки живут в одном экране (DefaultTabController — без ручного
    // TabController/жизненного цикла). Каждая вкладка ([_TasksTab]) — свой
    // контроллер под свой фильтр, инициализируется лениво при первом показе.
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.tasksScreenTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l.tasksTabAll),
              Tab(text: l.tasksTabInitiator),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TasksTab(
              key: const Key('tasksTab_all'),
              rpc: _rpc,
              filter: tasksFilterAll,
              emptyText: l.tasksEmptyAll,
              onOpenRoom: widget.onOpenRoom,
              onOpenThread: widget.onOpenThread,
            ),
            _TasksTab(
              key: const Key('tasksTab_initiator'),
              rpc: _rpc,
              filter: tasksFilterInitiator,
              emptyText: l.tasksEmptyInitiator,
              onOpenRoom: widget.onOpenRoom,
              onOpenThread: widget.onOpenThread,
            ),
          ],
        ),
      ),
    );
  }
}

/// Одна вкладка списка задач под свой [filter]. Отдельный StatefulWidget —
/// чтобы контроллер (и его RPC-вызов с нужным фильтром) поднимался ЛЕНИВО при
/// первом показе вкладки: пока не переключились на «Я инициатор», её выборка
/// не грузится (и тест видит, что переключение зовёт именно свой фильтр).
class _TasksTab extends StatefulWidget {
  const _TasksTab({
    super.key,
    required this.rpc,
    required this.filter,
    required this.emptyText,
    this.onOpenRoom,
    this.onOpenThread,
  });

  final MyTasksRpc rpc;
  final String filter;

  final String emptyText;
  final void Function(BuildContext context, int roomId)? onOpenRoom;
  final void Function(BuildContext context, TicketView task)? onOpenThread;

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab>
    with AutomaticKeepAliveClientMixin {
  late final MyTasksController _controller;

  // Держим состояние вкладки при переключении (не перегружаем каждый раз).
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // **TASK90**: комнатный режим уехал в [_RoomTasksTab] — здесь только
    // «все мои задачи» под свой фильтр, без сужения по комнате.
    _controller = MyTasksController(rpc: widget.rpc, filter: widget.filter);
    unawaited(_controller.init());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// TASK82: тред задачи, если он есть; иначе — комната целиком (нет задачи /
  /// старый тикет, у которого якорь появится лениво при первом GitHub-событии).
  Future<void> _openTask(TicketView task) async {
    final root = task.threadRootEventId;
    if (root == null || root.isEmpty) {
      await _openRoom(task.roomId);
      return;
    }
    final opener = widget.onOpenThread;
    if (opener != null) {
      opener(context, task);
      return;
    }
    final l = NsgL10n.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ThreadScreen(
          roomId: task.roomId,
          threadRootEventId: root,
          title: task.title,
          taskKey: task.externalTaskKey,
          statusLabel: taskStageLabel(task.stage, l),
        ),
      ),
    );
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
    super.build(context); // AutomaticKeepAliveClientMixin
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return switch (state) {
          MyTasksLoading() => const Center(child: CircularProgressIndicator()),
          MyTasksUnavailable() => _ErrorView(onRetry: _controller.refresh),
          MyTasksReady(:final tasks) =>
            tasks.isEmpty
                ? _EmptyView(text: widget.emptyText)
                : RefreshIndicator(
                    onRefresh: _controller.refresh,
                    child: ListView.separated(
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) => _TaskTile(
                        task: tasks[i],
                        onTap: () => _openTask(tasks[i]),
                      ),
                    ),
                  ),
        };
      },
    );
  }
}

/// **TASK90**: список задач ОДНОЙ комнаты. Отдельная вкладка от [_TasksTab],
/// потому что строка другой природы: там обращение (`TicketView`), здесь
/// задача (`RoomTaskView`). Прежде комнатный список брали из обращений, а у
/// support-комнаты обращение одно — отсюда «в шапке 10, внутри одна».
class _RoomTasksTab extends StatefulWidget {
  const _RoomTasksTab({
    super.key,
    required this.rpc,
    required this.roomId,
    required this.emptyText,
    this.onOpenRoom,
  });

  final MyTasksRpc rpc;
  final int roomId;
  final String emptyText;
  final void Function(BuildContext context, int roomId)? onOpenRoom;

  @override
  State<_RoomTasksTab> createState() => _RoomTasksTabState();
}

class _RoomTasksTabState extends State<_RoomTasksTab> {
  late final RoomTasksController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RoomTasksController(rpc: widget.rpc, roomId: widget.roomId);
    unawaited(_controller.init());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Строка ведёт в ТРЕД задачи: обсуждение шло там, и именно туда приезжают
  /// комментарии из трекера. Якорь у задачи есть всегда (это сообщение,
  /// которым её завели), поэтому отката на «просто комната» здесь не нужно —
  /// в отличие от «Моих обращений», где тикет бывает без треда.
  Future<void> _openTask(RoomTaskView task) async {
    final l = NsgL10n.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ThreadScreen(
          roomId: task.roomId,
          threadRootEventId: task.anchorEventId,
          // Номер отдельным полем: раньше он подставлялся ВМЕСТО названия и
          // тогда дублировался бы в подзаголовке.
          title: task.title,
          taskKey: task.externalTaskKey,
          statusLabel: taskStageLabel(task.stage, l),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return switch (state) {
          RoomTasksLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          RoomTasksUnavailable() => _ErrorView(onRetry: _controller.refresh),
          RoomTasksReady(:final tasks) =>
            tasks.isEmpty
                ? _EmptyView(text: widget.emptyText)
                : RefreshIndicator(
                    onRefresh: _controller.refresh,
                    child: ListView.separated(
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) => _RoomTaskTile(
                        task: tasks[i],
                        onTap: () => _openTask(tasks[i]),
                      ),
                    ),
                  ),
        };
      },
    );
  }
}

/// Строка задачи комнаты: заголовок (или ключ, если заголовка нет) + ключ
/// подписью + значок стадии. Стиль тот же, что у [_TaskTile].
class _RoomTaskTile extends StatelessWidget {
  const _RoomTaskTile({required this.task, required this.onTap});

  final RoomTaskView task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final title = task.title;
    final hasTitle = title != null && title.trim().isNotEmpty;
    return ListTile(
      key: Key('roomTaskTile_${task.id}'),
      leading: const CircleAvatar(child: Icon(Icons.checklist)),
      // Без заголовка (задачи, заведённые до TASK90) показываем ключ — строка
      // обязана быть, иначе список разойдётся с бейджем в шапке.
      title: Text(hasTitle ? title : (task.externalTaskKey ?? l.taskLabel)),
      subtitle: hasTitle && task.externalTaskKey != null
          ? Text(task.externalTaskKey!)
          : null,
      trailing: UnreadThenStage(
        unreadCount: task.unreadCount,
        stage: _StageBadge(
          text: taskStageLabel(task.stage, l),
          color: taskStageColor(task.stage, theme),
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Строка задачи: тема (имя комнаты) + превью последнего события + значок
/// стадии цветом палитры TASK83. Стиль зеркалит `_TicketTile` «Мои обращения».
class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onTap});

  final TicketView task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    return ListTile(
      key: Key('taskTile_${task.id}'),
      leading: CircleAvatar(child: Icon(_kindIcon(task.kind))),
      title: Text(_titleFor(task, l)),
      subtitle: task.lastEventPreview == null
          ? null
          : Text(
              task.lastEventPreview!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: UnreadThenStage(
        unreadCount: task.unreadCount,
        stage: _StageBadge(
          text: taskStageLabel(task.stage, l),
          color: taskStageColor(task.stage, theme),
        ),
      ),
      onTap: onTap,
    );
  }

  static IconData _kindIcon(String kind) => switch (kind) {
    'bug' => Icons.bug_report_outlined,
    'idea' => Icons.lightbulb_outline,
    _ => Icons.support_agent_outlined,
  };

  /// Тема строки = имя комнаты ([TicketView.title]); если его нет (комната без
  /// имени) — падаем на ключ задачи, а затем на заголовок экрана.
  static String _titleFor(TicketView t, NsgL10n l) {
    final title = t.title;
    if (title != null && title.trim().isNotEmpty) return title;
    return t.externalTaskKey ?? l.tasksScreenTitle;
  }
}

/// Значок стадии — тот же вид, что бейдж «Мои обращения», но цвет из палитры
/// TASK83 (нейтральный «заведена» для `new`/неизвестного, а не синий).
class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.text, required this.color});

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
  const _EmptyView({required this.text});

  final String text;

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
              Icons.assignment_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              text,
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
    final l = NsgL10n.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.tasksLoadError),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(l.commonRetry)),
        ],
      ),
    );
  }
}
