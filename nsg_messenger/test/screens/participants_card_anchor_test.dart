/// **issue #91**: состав группы по ТАПУ на подпись «N участников».
///
/// Раньше (issue #63) карточка открывалась по наведению мыши, и оператор на
/// это пожаловался: «отображается сразу при наведении мышки, страшно бесит».
/// Претензия по делу — карточка выскакивала, когда курсор просто шёл мимо к
/// другой кнопке.
///
/// Что защищаем:
///   * карточка появляется по тапу и НЕ появляется от наведения;
///   * закрывается повторным тапом и тапом мимо — у неё нет своей кнопки
///     закрытия, и открывший жест обязан её убирать;
///   * список с сервера обрезан (`participantsPreviewSize` = 30), а
///     `totalParticipants` настоящий — «и ещё N» обязателен, иначе «30 из
///     200» читается как враньё;
///   * пустой состав — якорь без всякой карточки;
///   * **issue #82**: фон карточки НЕПРОЗРАЧНЫЙ. В glass-темах
///     `canvasColor` прозрачный, и карточка без явного цвета показывала
///     сквозь себя переписку — читать состав было нельзя.
///   * **боевой тест, задача C1**: карточка РАЗМЕРОМ С СОДЕРЖИМОЕ, а не во
///     весь экран. Проверки выше все проходили и на сломанной вёрстке:
///     `find.text` находит имя одинаково — и в карточке 300×320, и в
///     растянутой на весь экран. Поэтому здесь меряем размер явно.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/screens/participants_card_anchor.dart';
import 'package:nsg_messenger/src/theme/overlay_surface.dart';

RoomParticipant _p(int id, String name) => RoomParticipant(
  messengerUserId: id,
  matrixUserId: '@u$id:t',
  displayName: name,
  role: RoomMemberRole.member,
  participantKind: ParticipantKind.user,
);

void main() {
  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: const [
      NsgL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );

  Future<void> open(WidgetTester tester, Finder target) async {
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('до наведения карточки нет, после — состав виден', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ParticipantsCardAnchor(
          participants: [_p(1, 'Пётр'), _p(2, 'Кэрол')],
          totalParticipants: 2,
          child: const Text('2 участника'),
        ),
      ),
    );
    expect(find.text('Пётр'), findsNothing);

    await open(tester, find.text('2 участника'));
    expect(find.text('Пётр'), findsOneWidget);
    expect(find.text('Кэрол'), findsOneWidget);
  });

  testWidgets('наведение мыши карточку НЕ открывает', (tester) async {
    // Суть заявки #91. Курсор проходит по подписи по дороге к другой кнопке
    // десятки раз за сеанс, и каждый раз выскакивала карточка.
    await tester.pumpWidget(
      wrap(
        ParticipantsCardAnchor(
          participants: [_p(1, 'Пётр')],
          totalParticipants: 1,
          child: const Text('1 участник'),
        ),
      ),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('1 участник')));
    await tester.pumpAndSettle();

    expect(find.text('Пётр'), findsNothing);
  });

  testWidgets('тап поверх открытой карточки закрывает', (tester) async {
    // Своей кнопки закрытия у карточки нет. Пока она открыта, экран перекрыт
    // барьером, поэтому закрывает ЛЮБОЙ тап — в том числе туда же, где была
    // подпись. Важно, что человек не остаётся с карточкой, от которой не
    // избавиться.
    await tester.pumpWidget(
      wrap(
        ParticipantsCardAnchor(
          participants: [_p(1, 'Пётр')],
          totalParticipants: 1,
          child: const Text('1 участник'),
        ),
      ),
    );
    await open(tester, find.text('1 участник'));
    expect(find.text('Пётр'), findsOneWidget);

    await tester.tap(find.text('1 участник'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Пётр'), findsNothing);
  });

  testWidgets('тап мимо карточки закрывает', (tester) async {
    await tester.pumpWidget(
      wrap(
        ParticipantsCardAnchor(
          participants: [_p(1, 'Пётр')],
          totalParticipants: 1,
          child: const Text('1 участник'),
        ),
      ),
    );
    await open(tester, find.text('1 участник'));
    expect(find.text('Пётр'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Пётр'), findsNothing);
  });

  testWidgets('обрезанный сервером список честно показывает «и ещё N»', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ParticipantsCardAnchor(
          participants: [_p(1, 'Пётр'), _p(2, 'Кэрол')],
          totalParticipants: 42, // сервер отдал превью, всего — 42
          child: const Text('42 участника'),
        ),
      ),
    );
    await open(tester, find.text('42 участника'));
    expect(find.text('и ещё 40'), findsOneWidget);
  });

  testWidgets('состав не пришёл → якорь без карточки', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ParticipantsCardAnchor(
          participants: [],
          totalParticipants: 3,
          child: Text('3 участника'),
        ),
      ),
    );
    await open(tester, find.text('3 участника'));
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('issue #82: фон карточки непрозрачный, а не сквозной', (
    tester,
  ) async {
    // Карточка ВСПЛЫВАЕТ над перепиской: с прозрачным фоном сквозь неё
    // читается текст под ней, и список превращается в «кашу».
    await tester.pumpWidget(
      wrap(
        ParticipantsCardAnchor(
          participants: [_p(1, 'Пётр')],
          totalParticipants: 1,
          child: const Text('3 участника'),
        ),
      ),
    );
    await open(tester, find.text('3 участника'));

    // Ищем именно карточку (elevation 8), а не Material от Scaffold —
    // ancestor-поиск даёт внешний, и тест проверял бы фон страницы.
    final card = tester.widget<Material>(
      find.byWidgetPredicate((w) => w is Material && w.elevation == 8),
    );
    expect(card.color, kOverlaySurface);
  });

  testWidgets('C1: карточка размером с содержимое, а не во весь экран', (
    tester,
  ) async {
    // Сервер отдаёт превью в 30 человек при 200 в комнате — самый длинный
    // список, какой карточка вообще может получить. Даже он обязан
    // остаться карточкой: иначе состав накрывает переписку целиком.
    await tester.pumpWidget(
      wrap(
        ParticipantsCardAnchor(
          participants: [for (var i = 1; i <= 30; i++) _p(i, 'Участник $i')],
          totalParticipants: 200,
          child: const Text('200 участников'),
        ),
      ),
    );
    await open(tester, find.text('200 участников'));

    final screen = tester.getSize(find.byType(MaterialApp));
    final size = tester.getSize(
      find.byWidgetPredicate((w) => w is Material && w.elevation == 8),
    );

    expect(size.width, lessThanOrEqualTo(300), reason: 'maxWidth карточки');
    expect(size.height, lessThanOrEqualTo(320), reason: 'maxHeight карточки');
    expect(
      size.width < screen.width && size.height < screen.height,
      isTrue,
      reason:
          'карточка растянулась на весь экран ($size при экране $screen) — '
          'ровно тот дефект, из-за которого она накрывала переписку',
    );
  });

  testWidgets('C1: у карточки есть видимая граница', (tester) async {
    // Половина жалобы с боевого теста — «почти не выделяющийся»: тень от
    // elevation на тёмном фоне не читается, и без контура панель выглядит
    // как текст поверх чата.
    await tester.pumpWidget(
      wrap(
        ParticipantsCardAnchor(
          participants: [_p(1, 'Пётр')],
          totalParticipants: 1,
          child: const Text('1 участник'),
        ),
      ),
    );
    await open(tester, find.text('1 участник'));

    final card = tester.widget<Material>(
      find.byWidgetPredicate((w) => w is Material && w.elevation == 8),
    );
    final shape = card.shape;
    expect(shape, isA<RoundedRectangleBorder>());
    final side = (shape! as RoundedRectangleBorder).side;
    expect(side.style, BorderStyle.solid);
    expect(side.color.a, greaterThan(0));
  });
}
