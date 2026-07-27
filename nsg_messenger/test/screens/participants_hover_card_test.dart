/// **issue #63**: состав группы по наведению мыши.
///
/// Что защищаем:
///   * карточка появляется по наведению и не появляется до него;
///   * при уходе курсора закрывается НЕ мгновенно — иначе до самой
///     карточки (между ней и подписью зазор) курсор не доедет и список
///     нельзя прокрутить;
///   * список с сервера обрезан (`participantsPreviewSize` = 30), а
///     `totalParticipants` настоящий — «и ещё N» обязателен, иначе «30 из
///     200» читается как враньё;
///   * пустой состав — якорь без всякой карточки.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/screens/participants_hover_card.dart';

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

  Future<TestGesture> hover(WidgetTester tester, Finder target) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(target));
    await tester.pumpAndSettle();
    return gesture;
  }

  testWidgets('до наведения карточки нет, после — состав виден', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ParticipantsHoverCard(
          participants: [_p(1, 'Пётр'), _p(2, 'Кэрол')],
          totalParticipants: 2,
          child: const Text('2 участника'),
        ),
      ),
    );
    expect(find.text('Пётр'), findsNothing);

    await hover(tester, find.text('2 участника'));
    expect(find.text('Пётр'), findsOneWidget);
    expect(find.text('Кэрол'), findsOneWidget);
  });

  testWidgets('уход курсора закрывает не мгновенно (иначе не доскроллить)', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ParticipantsHoverCard(
          participants: [_p(1, 'Пётр')],
          totalParticipants: 1,
          child: const Text('1 участник'),
        ),
      ),
    );
    final gesture = await hover(tester, find.text('1 участник'));
    expect(find.text('Пётр'), findsOneWidget);

    await gesture.moveTo(const Offset(5, 5)); // курсор ушёл с подписи
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.text('Пётр'),
      findsOneWidget,
      reason: 'в эти миллисекунды курсор как раз идёт к карточке',
    );

    await tester.pump(kHoverCloseDelay);
    await tester.pumpAndSettle();
    expect(find.text('Пётр'), findsNothing);
  });

  testWidgets('обрезанный сервером список честно показывает «и ещё N»', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ParticipantsHoverCard(
          participants: [_p(1, 'Пётр'), _p(2, 'Кэрол')],
          totalParticipants: 42, // сервер отдал превью, всего — 42
          child: const Text('42 участника'),
        ),
      ),
    );
    await hover(tester, find.text('42 участника'));
    expect(find.text('и ещё 40'), findsOneWidget);
  });

  testWidgets('состав не пришёл → якорь без карточки', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ParticipantsHoverCard(
          participants: [],
          totalParticipants: 3,
          child: Text('3 участника'),
        ),
      ),
    );
    await hover(tester, find.text('3 участника'));
    expect(find.byType(ListView), findsNothing);
  });
}
