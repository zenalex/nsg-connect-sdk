import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/push/push_token_status.dart';
import 'package:nsg_messenger/src/widgets/push_status_notice.dart';

import '../test_helpers.dart';

/// **Issue #86**: приложение перестаёт молчать о неполученном пуш-токене.
///
/// Проверяем две вещи, ради которых всё и делалось:
///   1. причина называется РАЗНАЯ — «разрешение не выдано» и «токен не
///      пришёл» лечатся по-разному, и подсказка не по адресу бесполезна;
///   2. назойливости нет — сознательно отказавшегося от уведомлений
///      баннер над списком чатов не преследует.
void main() {
  const noticeKey = Key('pushStatusNotice');
  const bannerKey = Key('pushStatusBanner');

  setUp(PushStatusBanner.resetDismissal);

  Widget notice(PushTokenStatus status, {VoidCallback? onOpenSettings}) =>
      wrapL10n(
        PushStatusNotice(
          onOpenSettings: onOpenSettings,
          initialStatusOverride: status,
          statusOverride: const Stream<PushTokenStatus>.empty(),
        ),
        locale: const Locale('ru'),
      );

  Widget banner(PushTokenStatus status, {VoidCallback? onOpenSettings}) =>
      wrapL10n(
        PushStatusBanner(
          onOpenSettings: onOpenSettings,
          initialStatusOverride: status,
          statusOverride: const Stream<PushTokenStatus>.empty(),
        ),
        locale: const Locale('ru'),
      );

  group('PushStatusNotice — карточка в настройках уведомлений', () {
    testWidgets('ready → карточки нет (подтверждать исправность незачем)', (
      tester,
    ) async {
      await tester.pumpWidget(notice(PushTokenStatus.ready));
      expect(find.byKey(noticeKey), findsNothing);
    });

    testWidgets('pending → карточки нет (вердикта ещё нет, пугать рано)', (
      tester,
    ) async {
      await tester.pumpWidget(notice(PushTokenStatus.pending));
      expect(find.byKey(noticeKey), findsNothing);
    });

    testWidgets('unsupported → карточки нет (десктоп: чинить нечего)', (
      tester,
    ) async {
      await tester.pumpWidget(notice(PushTokenStatus.unsupported));
      expect(find.byKey(noticeKey), findsNothing);
    });

    testWidgets('permissionDenied → причина про разрешение', (tester) async {
      await tester.pumpWidget(notice(PushTokenStatus.permissionDenied));
      expect(find.byKey(noticeKey), findsOneWidget);
      expect(find.textContaining('не разрешено показывать'), findsOneWidget);
      expect(
        find.textContaining('5223'),
        findsNothing,
        reason: 'про сеть тут говорить нельзя — дело в разрешении',
      );
    });

    testWidgets('tokenUnavailable → причина про сеть, а не про разрешение', (
      tester,
    ) async {
      await tester.pumpWidget(notice(PushTokenStatus.tokenUnavailable));
      expect(find.byKey(noticeKey), findsOneWidget);
      expect(find.textContaining('5223'), findsOneWidget);
      expect(
        find.textContaining('не разрешено показывать'),
        findsNothing,
        reason: 'разрешение уже выдано — просить его повторно бессмысленно',
      );
    });

    testWidgets('кнопка «Открыть настройки» зовёт колбэк host-app', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        notice(PushTokenStatus.permissionDenied, onOpenSettings: () => taps++),
      );
      await tester.tap(find.byKey(const Key('pushStatusOpenSettings')));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('без колбэка кнопки нет, но причина остаётся', (tester) async {
      await tester.pumpWidget(notice(PushTokenStatus.permissionDenied));
      expect(find.byKey(const Key('pushStatusOpenSettings')), findsNothing);
      expect(find.byKey(noticeKey), findsOneWidget);
    });
  });

  group('PushStatusBanner — полоса над списком чатов', () {
    testWidgets(
      'tokenUnavailable → баннер виден: человек разрешил уведомления и '
      'не получает их, узнать об этом больше неоткуда',
      (tester) async {
        await tester.pumpWidget(banner(PushTokenStatus.tokenUnavailable));
        expect(find.byKey(bannerKey), findsOneWidget);
      },
    );

    testWidgets(
      'permissionDenied → баннера НЕТ: отказ осознанный, преследовать им '
      'человека нельзя (факт остаётся в настройках уведомлений)',
      (tester) async {
        await tester.pumpWidget(banner(PushTokenStatus.permissionDenied));
        expect(find.byKey(bannerKey), findsNothing);
      },
    );

    testWidgets('ready → баннера нет', (tester) async {
      await tester.pumpWidget(banner(PushTokenStatus.ready));
      expect(find.byKey(bannerKey), findsNothing);
    });

    testWidgets('крестик убирает баннер', (tester) async {
      await tester.pumpWidget(banner(PushTokenStatus.tokenUnavailable));
      expect(find.byKey(bannerKey), findsOneWidget);
      await tester.tap(find.byKey(const Key('pushStatusBannerDismiss')));
      await tester.pump();
      expect(find.byKey(bannerKey), findsNothing);
    });

    testWidgets(
      'скрытый крестиком баннер не возвращается при пересоздании виджета '
      '(уход со списка чатов и обратно)',
      (tester) async {
        await tester.pumpWidget(banner(PushTokenStatus.tokenUnavailable));
        await tester.tap(find.byKey(const Key('pushStatusBannerDismiss')));
        await tester.pump();

        // Полностью новый экземпляр виджета — как после возврата на экран.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(banner(PushTokenStatus.tokenUnavailable));
        expect(find.byKey(bannerKey), findsNothing);
      },
    );

    testWidgets('тап по баннеру ведёт в системные настройки', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        banner(PushTokenStatus.tokenUnavailable, onOpenSettings: () => taps++),
      );
      await tester.tap(find.byKey(bannerKey));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('статус приходит потоком: pending → tokenUnavailable', (
      tester,
    ) async {
      final ctrl = StreamController<PushTokenStatus>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(
        wrapL10n(
          PushStatusBanner(
            initialStatusOverride: PushTokenStatus.pending,
            statusOverride: ctrl.stream,
          ),
          locale: const Locale('ru'),
        ),
      );
      expect(find.byKey(bannerKey), findsNothing);

      ctrl.add(PushTokenStatus.tokenUnavailable);
      await tester.pumpAndSettle();
      expect(find.byKey(bannerKey), findsOneWidget);

      // Токен всё-таки доехал — баннер обязан уйти сам.
      ctrl.add(PushTokenStatus.ready);
      await tester.pumpAndSettle();
      expect(find.byKey(bannerKey), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
