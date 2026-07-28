/// **Локаль SDK доезжает в диалоги и шторки.**
///
/// Отчёт с отладки `titan_lk`: «pushed-роуты и модалки не обёрнуты в
/// MessengerThemeScope… `NsgL10n.of(context)` падает на null-check — в
/// release это пустой серый ErrorWidget вместо UI. Найдено на шторке
/// вложений». Обошли регистрацией `NsgL10n.delegate` в `MaterialApp`
/// хоста — но хост не обязан этого делать: локаль мессенджера забота SDK.
///
/// Механика: `showDialog` / `showModalBottomSheet` строят содержимое в
/// контексте НАВИГАТОРА, а не вызывающего виджета, поэтому
/// `Localizations.override` из scope до них не доезжал. Flutter при этом
/// переносит в маршрут все `InheritedTheme` вызывающего контекста — scope
/// кладёт туда свой маркер, и обёртка восстанавливается сама.
///
/// Хост здесь НАМЕРЕННО без `NsgL10n.delegate`: тест обязан падать ровно
/// там, где падало у интегратора.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/theme/messenger_theme_scope.dart';
import 'package:nsg_messenger/src/theme/nsg_messenger_theme.dart';

/// Хост без делегатов SDK — как у интегратора.
Widget _bareHost(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Кнопка, открывающая что-нибудь и читающая `NsgL10n` внутри.
class _Opener extends StatelessWidget {
  const _Opener({required this.open});

  /// `(context) => Future` — что именно открываем.
  final Future<void> Function(BuildContext context) open;

  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: () => open(context), child: const Text('открыть'));
}

/// Читает локализацию SDK — падает, если делегата в контексте нет.
class _NeedsL10n extends StatelessWidget {
  const _NeedsL10n();

  @override
  Widget build(BuildContext context) =>
      Text(NsgL10n.of(context).commonRetry, textDirection: TextDirection.ltr);
}

void main() {
  Widget scoped(Widget child) =>
      MessengerThemeScope(theme: const NsgMessengerTheme(), child: child);

  testWidgets('showModalBottomSheet: локализация SDK внутри есть', (
    tester,
  ) async {
    await tester.pumpWidget(
      _bareHost(
        scoped(
          _Opener(
            open: (ctx) => showModalBottomSheet<void>(
              context: ctx,
              builder: (_) => const _NeedsL10n(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('открыть'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'ровно тут был серый экран');
    expect(find.byType(_NeedsL10n), findsOneWidget);
  });

  testWidgets('showDialog: то же самое', (tester) async {
    await tester.pumpWidget(
      _bareHost(
        scoped(
          _Opener(
            open: (ctx) => showDialog<void>(
              context: ctx,
              builder: (_) => const Dialog(child: _NeedsL10n()),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('открыть'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(_NeedsL10n), findsOneWidget);
  });

  testWidgets('ВНЕ scope шторка по-прежнему без локализации SDK — значит '
      'работу делает именно scope, а не хост', (tester) async {
    // Контрольный опыт. Если бы делегат приезжал откуда-то ещё, тесты
    // выше проходили бы и без правки — и ничего не проверяли.
    await tester.pumpWidget(
      _bareHost(
        _Opener(
          open: (ctx) => showModalBottomSheet<void>(
            context: ctx,
            builder: (_) => const _NeedsL10n(),
          ),
        ),
      ),
    );
    await tester.tap(find.text('открыть'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNotNull);
  });

  testWidgets('вложенный диалог из шторки тоже сохраняет scope', (
    tester,
  ) async {
    // Шторка вложений открывает подтверждения и просмотрщики — цепочка
    // обязана держаться на любой глубине.
    await tester.pumpWidget(
      _bareHost(
        scoped(
          _Opener(
            open: (ctx) => showModalBottomSheet<void>(
              context: ctx,
              builder: (sheetCtx) => _Opener(
                open: (inner) => showDialog<void>(
                  context: inner,
                  builder: (_) => const Dialog(child: _NeedsL10n()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('открыть'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('открыть').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(_NeedsL10n), findsOneWidget);
  });
}
