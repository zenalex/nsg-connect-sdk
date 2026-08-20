import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n_ru.dart';
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;

import '../test_helpers.dart';

/// **TASK83**: значок задачи на ИСХОДНОМ сообщении.
///
/// Проверяем: значок рисуется по данным задачи и цвету стадии; тап отдаёт
/// экрану корень треда + URL (маршрут «тред vs issue» — уже на экране); без
/// задачи или без обработчика значка нет; подпись стадии локализована.
void main() {
  setUpAll(registerTimeagoLocales);

  ChatMessage src({String? stage, String? root, String? url}) => ChatMessage(
    clientTxnId: 'txn-src',
    matrixEventId: 'src-event',
    senderMatrixUserId: '@user:localhost',
    senderMessengerUserId: 7,
    body: 'Кнопка отправки не работает',
    msgType: 'm.text',
    serverTimestamp: DateTime.utc(2026, 1, 1),
    status: ChatMessageStatus.sent,
    taskStage: stage,
    taskThreadRootEventId: root,
    taskUrl: url,
  );

  Widget bubble(
    ChatMessage m, {
    void Function(String?, String?, {String? taskKey, String? taskTitle})?
    onOpenTask,
    Locale locale = const Locale('en'),
  }) => wrapL10n(
    MessageBubble(
      message: m,
      isOwn: true,
      onRetry: (_) {},
      onOpenTask: onOpenTask,
    ),
    locale: locale,
  );

  Color badgeIconColor(WidgetTester tester) => tester
      .widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('taskBadge')),
          matching: find.byType(Icon),
        ),
      )
      .color!;

  group('taskStageColor (маппинг стадия→цвет)', () {
    final theme = ThemeData();
    test('активные стадии — фиксированные цвета', () {
      expect(taskStageColor('in_progress', theme), Colors.orange);
      expect(taskStageColor('accepted', theme), Colors.green);
      expect(taskStageColor('rejected', theme), Colors.redAccent);
    });
    test('new и null → нейтральный (onSurfaceVariant)', () {
      expect(taskStageColor('new', theme), theme.colorScheme.onSurfaceVariant);
      expect(taskStageColor(null, theme), theme.colorScheme.onSurfaceVariant);
      expect(
        taskStageColor('какая-то', theme),
        theme.colorScheme.onSurfaceVariant,
      );
    });

    // **issue #98**: два состояния, в которых работа СТОИТ.
    test('«ждёт ответа» не путается ни с работой, ни с отказом', () {
      // Янтарный сказал бы «делаем» (ровно наоборот), красный — «отказали».
      // Значок зовёт заявителя действовать, и выглядеть должен иначе обоих.
      final awaiting = taskStageColor('awaiting_user', theme);
      expect(awaiting, isNot(taskStageColor('in_progress', theme)));
      expect(awaiting, isNot(taskStageColor('rejected', theme)));
      expect(awaiting, isNot(theme.colorScheme.onSurfaceVariant));
    });

    test('«приостановлена» отличима от «заведена»', () {
      // Оба тихие, но «заведена» — ещё не начинали, а тут начали и отложили.
      final onHold = taskStageColor('on_hold', theme);
      expect(onHold, isNot(theme.colorScheme.onSurfaceVariant));
      expect(onHold, isNot(taskStageColor('awaiting_user', theme)));
    });
  });

  group('taskStageLabel (issue #98)', () {
    final l = NsgL10nRu();

    test('новые стадии подписаны сами, а не падают в «Заведена»', () {
      // Без своей ветки обе свалились бы в `_ =>` и показались «Заведена» —
      // той самой ложью, из-за которой завели #97.
      expect(taskStageLabel('awaiting_user', l), l.taskStageAwaitingUser);
      expect(taskStageLabel('on_hold', l), l.taskStageOnHold);
      expect(taskStageLabel('awaiting_user', l), isNot(l.taskStageCreated));
      expect(taskStageLabel('on_hold', l), isNot(l.taskStageInProgress));
    });
  });

  testWidgets('есть задача + обработчик → значок виден', (tester) async {
    await tester.pumpWidget(
      bubble(
        src(stage: 'in_progress', root: r'$anchor', url: 'https://x/1'),
        onOpenTask: (_, _, {taskKey, taskTitle}) {},
      ),
    );
    expect(find.byKey(const Key('taskBadge')), findsOneWidget);
  });

  testWidgets('цвет значка = цвет стадии (in_progress → orange)', (
    tester,
  ) async {
    await tester.pumpWidget(
      bubble(
        src(stage: 'in_progress', url: 'https://x/1'),
        onOpenTask: (_, _, {taskKey, taskTitle}) {},
      ),
    );
    expect(badgeIconColor(tester), Colors.orange);
  });

  testWidgets('accepted → green, rejected → redAccent', (tester) async {
    await tester.pumpWidget(
      bubble(
        src(stage: 'accepted', url: 'https://x/1'),
        onOpenTask: (_, _, {taskKey, taskTitle}) {},
      ),
    );
    expect(badgeIconColor(tester), Colors.green);

    await tester.pumpWidget(
      bubble(
        src(stage: 'rejected', url: 'https://x/1'),
        onOpenTask: (_, _, {taskKey, taskTitle}) {},
      ),
    );
    expect(badgeIconColor(tester), Colors.redAccent);
  });

  testWidgets('TaskLink без тикета (стадия null, есть url) → значок есть, '
      'цвет нейтральный', (tester) async {
    await tester.pumpWidget(
      bubble(
        src(stage: null, url: 'https://x/1'),
        onOpenTask: (_, _, {taskKey, taskTitle}) {},
      ),
    );
    expect(find.byKey(const Key('taskBadge')), findsOneWidget);
    // Нейтральный цвет = onSurfaceVariant активной темы.
    final ctx = tester.element(find.byType(MessageBubble));
    expect(badgeIconColor(tester), Theme.of(ctx).colorScheme.onSurfaceVariant);
  });

  testWidgets('тап с тредом → колбэк получает (корень, url)', (tester) async {
    String? gotRoot = 'unset';
    String? gotUrl = 'unset';
    await tester.pumpWidget(
      bubble(
        src(stage: 'in_progress', root: r'$anchor', url: 'https://x/42'),
        onOpenTask: (r, u, {taskKey, taskTitle}) {
          gotRoot = r;
          gotUrl = u;
        },
      ),
    );
    await tester.tap(find.byKey(const Key('taskBadge')));
    await tester.pump();
    expect(gotRoot, r'$anchor');
    expect(gotUrl, 'https://x/42');
  });

  testWidgets(
    'тап без треда → колбэк получает (null, url) — экран уйдёт в url',
    (tester) async {
      String? gotRoot = 'unset';
      String? gotUrl = 'unset';
      await tester.pumpWidget(
        bubble(
          src(stage: null, root: null, url: 'https://x/43'),
          onOpenTask: (r, u, {taskKey, taskTitle}) {
            gotRoot = r;
            gotUrl = u;
          },
        ),
      );
      await tester.tap(find.byKey(const Key('taskBadge')));
      await tester.pump();
      expect(gotRoot, isNull);
      expect(gotUrl, 'https://x/43');
    },
  );

  testWidgets('нет задачи → значка нет', (tester) async {
    await tester.pumpWidget(
      bubble(src(), onOpenTask: (_, _, {taskKey, taskTitle}) {}),
    );
    expect(find.byKey(const Key('taskBadge')), findsNothing);
  });

  testWidgets('есть задача, но обработчика нет → значка нет', (tester) async {
    await tester.pumpWidget(
      bubble(src(stage: 'in_progress', url: 'https://x/1')),
    );
    expect(find.byKey(const Key('taskBadge')), findsNothing);
  });

  testWidgets('подпись стадии локализована (ru): «Задача: В работе»', (
    tester,
  ) async {
    await tester.pumpWidget(
      bubble(
        src(stage: 'in_progress', url: 'https://x/1'),
        onOpenTask: (_, _, {taskKey, taskTitle}) {},
        locale: const Locale('ru'),
      ),
    );
    final tip = tester.widget<Tooltip>(
      find.ancestor(
        of: find.byKey(const Key('taskBadge')),
        matching: find.byType(Tooltip),
      ),
    );
    expect(tip.message, 'Задача: В работе');
  });

  // ── TASK88: подпись «Задача» у значка ──────────────────────────────────

  testWidgets('TASK88: подпись «Задача» рисуется рядом со значком (ru)', (
    tester,
  ) async {
    await tester.pumpWidget(
      bubble(
        src(stage: 'in_progress', url: 'https://x/1'),
        onOpenTask: (_, _, {taskKey, taskTitle}) {},
        locale: const Locale('ru'),
      ),
    );
    expect(find.byKey(const Key('taskBadgeLabel')), findsOneWidget);
    expect(find.text('Задача'), findsOneWidget);
  });

  testWidgets('TASK88: подпись «Task» на en', (tester) async {
    await tester.pumpWidget(
      bubble(
        src(stage: 'accepted', url: 'https://x/1'),
        onOpenTask: (_, _, {taskKey, taskTitle}) {},
      ),
    );
    expect(find.text('Task'), findsOneWidget);
  });

  testWidgets('TASK88: подпись в цвет стадии (accepted → green)', (
    tester,
  ) async {
    await tester.pumpWidget(
      bubble(
        src(stage: 'accepted', url: 'https://x/1'),
        onOpenTask: (_, _, {taskKey, taskTitle}) {},
      ),
    );
    final label = tester.widget<Text>(find.byKey(const Key('taskBadgeLabel')));
    expect(label.style?.color, Colors.green);
  });

  testWidgets('TASK88: нет задачи → подписи нет', (tester) async {
    await tester.pumpWidget(
      bubble(src(), onOpenTask: (_, _, {taskKey, taskTitle}) {}),
    );
    expect(find.byKey(const Key('taskBadgeLabel')), findsNothing);
  });
}
