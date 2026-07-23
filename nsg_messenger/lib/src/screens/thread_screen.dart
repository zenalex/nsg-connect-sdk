import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messages/message_bubble.dart';
import '../messages/message_composer.dart';
import '../messages/messages_controller.dart';
import '../messages/messages_rpc.dart';
import '../messages/messages_state.dart';
import '../messenger_runtime.dart';

/// **TASK82**: экран ТРЕДА задачи — обсуждение вокруг якорного сообщения
/// «Задача создана». В нём живут системные события задачи, комментарии из
/// GitHub и реплики участников; отправленное здесь уходит комментарием в
/// issue (мост делает сервер по `threadId`).
///
/// **Почему отдельный лёгкий экран, а не форк [ChatScreen]**: чату нужны
/// presence, звонки, эскалации, пересылка, поиск, закрепления, рабочий
/// набор вкладок — всего этого у треда задачи нет и не будет (см.
/// «скоуп-аут» спеки). Форк пришлось бы чинить дважды на каждый баг.
/// Переиспользуем то, что реально общее: [MessagesController]
/// (параметризованный корнем треда), [MessageBubble] и [MessageComposer].
class ThreadScreen extends StatefulWidget {
  const ThreadScreen({
    super.key,
    required this.roomId,
    required this.threadRootEventId,
    this.title,
    this.statusLabel,
    @visibleForTesting this.controllerOverride,
  });

  final int roomId;

  /// Корень треда — якорное сообщение задачи.
  final String threadRootEventId;

  /// Тема задачи в шапке. `null` → общий заголовок «Обсуждение задачи»
  /// (у старых тикетов темы может не быть).
  final String? title;

  /// Статус тикета подзаголовком шапки («В работе» / «Принято» / …).
  /// `null` → подзаголовка нет.
  final String? statusLabel;

  /// Visible-for-testing: подмена контроллера на тестовый (in-memory rpc +
  /// шина событий), чтобы widget-тест не поднимал [MessengerRuntime].
  final MessagesController? controllerOverride;

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  late final MessagesController _controller;
  late final bool _ownsController;
  final ScrollController _scroll = ScrollController();

  /// Порог подгрузки OLDER-страницы от верха reversed-списка. Тред
  /// короткий, hardcode достаточно (в чате он тюнится через конфиг из-за
  /// длинной истории — здесь такой нужды нет).
  static const double _kLoadMoreThresholdPx = 200;

  @override
  void initState() {
    super.initState();
    final injected = widget.controllerOverride;
    if (injected != null) {
      _controller = injected;
      _ownsController = false;
    } else {
      final runtime = MessengerRuntime.instance;
      _controller = MessagesController(
        roomId: widget.roomId,
        rpc: ClientMessagesRpc(runtime.client),
        events: runtime.eventBus.events,
        selfMessengerUserId: runtime.session.messengerUserId,
        selfMatrixUserId: runtime.session.matrixUserId,
        // Тред-режим: история через listThreadMessages, отправка с
        // threadId, из шины принимаются только сообщения этого треда.
        // Кэш/outbox не передаём — они комнатные (см. MessagesController).
        threadRootEventId: widget.threadRootEventId,
      );
      _ownsController = true;
    }
    unawaited(_controller.init());
  }

  @override
  void dispose() {
    _scroll.dispose();
    // Чужой (инжектированный) контроллер не наш — его освобождает хозяин.
    if (_ownsController) unawaited(_controller.dispose());
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - _kLoadMoreThresholdPx) {
      unawaited(_controller.loadMore());
    }
    return false;
  }

  /// **TASK83**: тап по значку задачи на сообщении внутри треда. Исходное
  /// сообщение задачи в общем случае живёт в основной ленте, но может попасть
  /// и сюда — тогда: другой корень треда → открываем ТОТ тред; наш же корень →
  /// no-op (мы уже в нём); нет треда → issue-URL во внешнем браузере.
  void _openTask(String? threadRootEventId, String? url) {
    if (threadRootEventId != null &&
        threadRootEventId.isNotEmpty &&
        threadRootEventId != widget.threadRootEventId) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ThreadScreen(
            roomId: widget.roomId,
            threadRootEventId: threadRootEventId,
          ),
        ),
      );
      return;
    }
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    unawaited(_launchExternal(uri));
  }

  Future<void> _launchExternal(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // best-effort: невалидный URL / нет хендлера не должны ронять экран.
    }
  }

  Future<void> _send(
    String body, {
    List<int>? mentionedMessengerUserIds,
    String? albumId,
  }) async {
    final reply = _controller.replyTarget;
    await _controller.sendMessage(
      body: body,
      replyToMatrixEventId: reply?.matrixEventId,
      mentionedMessengerUserIds: mentionedMessengerUserIds,
      albumId: albumId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final status = widget.statusLabel;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title ?? l.threadScreenTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (status != null && status.isNotEmpty)
              Text(
                status,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<MessagesState>(
              valueListenable: _controller.stateListenable,
              builder: (context, state, _) => _ThreadBody(
                state: state,
                controller: _controller,
                scrollController: _scroll,
                onScroll: _onScroll,
                onOpenTask: _openTask,
              ),
            ),
          ),
          ValueListenableBuilder<MessagesState>(
            valueListenable: _controller.stateListenable,
            builder: (context, state, _) =>
                MessageComposer(onSend: _send, enabled: state is MessagesReady),
          ),
        ],
      ),
    );
  }
}

/// Лента треда: тот же [MessageBubble], что в чате, но без альбомной
/// мозаики, реакций и мультивыбора — в обсуждении задачи их нет (скоуп-аут
/// спеки). Ссылку «Обсуждение (N)» на якоре здесь НЕ рисуем: мы уже внутри
/// треда, и она открывала бы сама себя.
class _ThreadBody extends StatelessWidget {
  const _ThreadBody({
    required this.state,
    required this.controller,
    required this.scrollController,
    required this.onScroll,
    required this.onOpenTask,
  });

  final MessagesState state;
  final MessagesController controller;
  final ScrollController scrollController;
  final bool Function(ScrollNotification) onScroll;

  /// **TASK83**: тап по значку задачи на сообщении треда (корень треда, url).
  final void Function(String? threadRootEventId, String? url) onOpenTask;

  @override
  Widget build(BuildContext context) {
    final s = state;
    return switch (s) {
      MessagesLoading() => const Center(child: CircularProgressIndicator()),
      MessagesError(error: final e, lastKnown: final last) =>
        last == null ? Center(child: Text('$e')) : _list(context, last),
      MessagesReady() => _list(context, s),
    };
  }

  Widget _list(BuildContext context, MessagesReady ready) {
    final messages = ready.messages;
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            NsgL10n.of(context).threadScreenEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return Column(
      children: [
        if (ready.paginating) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: onScroll,
            child: ListView.builder(
              controller: scrollController,
              reverse: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final m = messages[i];
                final isOwn =
                    m.isPending ||
                    m.isFailed ||
                    m.senderMessengerUserId == controller.selfMessengerUserId;
                return MessageBubble(
                  message: m,
                  isOwn: isOwn,
                  onRetry: (failed) {
                    final txn = failed.clientTxnId;
                    if (txn != null) unawaited(controller.retry(txn));
                  },
                  thumbnailRpc:
                      ({required String mxcUrl, int? width, int? height}) =>
                          controller.downloadThumbnail(
                            mxcUrl: mxcUrl,
                            width: width,
                            height: height,
                          ),
                  fullSizeRpc: ({required String mxcUrl}) =>
                      controller.downloadFullSize(mxcUrl: mxcUrl),
                  findReplyTarget: controller.findByEventId,
                  // Подпись отправителя над каждым верхним сообщением серии:
                  // в треде задачи заведомо несколько участников (заявитель,
                  // оператор, бот моста), монолог читался бы неверно.
                  showSenderName:
                      !isOwn &&
                      (i == messages.length - 1 ||
                          messages[i + 1].senderMatrixUserId !=
                              m.senderMatrixUserId),
                  // **TASK83**: значок задачи и здесь (если исходное сообщение
                  // попало в тред) — тот же колбэк маршрутизации.
                  onOpenTask: onOpenTask,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
