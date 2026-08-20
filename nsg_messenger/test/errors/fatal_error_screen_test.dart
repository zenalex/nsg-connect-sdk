/// **Экран смертельной ошибки** — issue #134.
///
/// Приложение падало при построении первого кадра, и человек видел серый
/// прямоугольник без единого слова — ни надписи, ни кнопки, ни намёка на
/// отказ. Телеметрия при этом сработала: отказ был тихим не для нас, а для
/// пользователя.
///
/// Главная проверка здесь — **самодостаточность**. Сегодняшний отказ и был
/// отказом локализации (#133), поэтому экран, читающий надписи из
/// `Localizations`, показал бы второй серый экран поверх первого. Тесты
/// поднимают его БЕЗ `MaterialApp`, без темы и без локализаций — как оно и
/// будет в момент беды.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/errors/fatal_error_screen.dart';

FlutterErrorDetails _details([Object? error]) => FlutterErrorDetails(
  exception:
      error ??
      NoSuchMethodError.withInvocation(null, Invocation.method(#f, [])),
  library: 'widgets library',
  stack: StackTrace.fromString('#0 first\n#1 second\n#2 third'),
);

void main() {
  testWidgets('строится БЕЗ MaterialApp, темы и локализаций', (t) async {
    // Ровно то, что требует заявка. Отказ, ради которого экран заводится,
    // был отказом локализации — зависимость от неё сделала бы экран
    // бесполезным именно тогда, когда он нужен.
    await t.pumpWidget(
      NsgFatalErrorScreen(details: _details(), onReload: () {}),
    );

    expect(find.text('Приложение не смогло запуститься'), findsOneWidget);
    expect(find.text('Перезагрузить'), findsOneWidget);
    expect(find.text('Скопировать подробности'), findsOneWidget);
    // Само по себе то, что pumpWidget не уронил тест, и есть доказательство
    // самодостаточности: flutter_test валит прогон на любом исключении при
    // построении, а над экраном здесь нет ничего.
  });

  testWidgets('показывает ТИП ошибки, но не стек', (t) async {
    // Стек человеку показывать нельзя — его и прятали, отключая красный
    // экран. А тип в отчёте бесценен: «серый экран» и «NoSuchMethodError
    // при запуске» — две разные заявки, и вторая решается сразу.
    await t.pumpWidget(NsgFatalErrorScreen(details: _details()));

    expect(find.textContaining('NoSuchMethodError'), findsOneWidget);
    expect(find.textContaining('#0 first'), findsNothing);
  });

  testWidgets('без способа перезагрузки кнопки перезагрузки НЕТ', (t) async {
    // Кнопка, которая ничего не делает, хуже её отсутствия: она обещает
    // выход и не даёт его.
    await t.pumpWidget(NsgFatalErrorScreen(details: _details()));

    expect(find.text('Перезагрузить'), findsNothing);
    expect(find.text('Скопировать подробности'), findsOneWidget);
  });

  testWidgets('перезагрузка действительно зовётся', (t) async {
    var reloads = 0;
    await t.pumpWidget(
      NsgFatalErrorScreen(details: _details(), onReload: () => reloads++),
    );
    await t.tap(find.text('Перезагрузить'));
    await t.pump();
    expect(reloads, 1);
  });

  testWidgets('копирование кладёт подробности в буфер и говорит об этом', (
    t,
  ) async {
    // «Скопировать» без подтверждения оставляет человека гадать, сработало
    // ли, — а он в этот момент и так в растерянности.
    String? copied;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await t.pumpWidget(NsgFatalErrorScreen(details: _details()));
    await t.tap(find.text('Скопировать подробности'));
    await t.pumpAndSettle();

    expect(copied, isNotNull);
    expect(copied, contains('NoSuchMethodError'));
    expect(
      copied,
      contains('#0 first'),
      reason: 'в буфер стек класть можно — человек копирует его НАМ',
    );
    expect(find.text('Скопировано'), findsOneWidget);
  });

  group('строка причины', () {
    test('тип не повторяется дважды, но и не теряется', () {
      // Заявка просит показать ТИП ошибки: «серый экран» и
      // «NoSuchMethodError при запуске» — две разные заявки, и вторая
      // решается сразу. Поэтому тип есть всегда.
      //
      // Убираем только БУКВАЛЬНОЕ удвоение: у части исключений `toString()`
      // сам начинается с имени типа, и приписка спереди дала бы
      // «NoSuchMethodError: NoSuchMethodError: …».
      final noSuchMethod = fatalErrorSummary(_details());
      expect(noSuchMethod, contains('NoSuchMethodError'));
      expect(noSuchMethod, isNot(contains('NoSuchMethodError: NoSuchMethod')));

      // А вот `StateError` печатается как «Bad state: …» — здесь тип
      // впереди НУЖЕН, иначе из строки не понять, что это за ошибка.
      final stateError = fatalErrorSummary(_details(StateError('нет данных')));
      expect(stateError, 'StateError: Bad state: нет данных');
    });

    test('длинное сообщение обрезается — экран не должен уезжать', () {
      final s = fatalErrorSummary(_details(StateError('x' * 500)));
      expect(s.length, lessThan(260));
      expect(s, endsWith('…'));
    });

    test('многострочное сообщение сводится к первой строке', () {
      // Иначе на экране оказался бы кусок стека — то, что мы и прячем.
      final s = fatalErrorSummary(_details(StateError('первая\nвторая')));
      expect(s, isNot(contains('вторая')));
    });
  });

  group('установка обработчика', () {
    tearDown(() => ErrorWidget.builder = _defaultBuilder);

    test('в debug по умолчанию НЕ подменяем', () {
      // Красный экран Flutter со стеком полезнее разработчику; наш — для
      // человека. Подменять оба значило бы отнять диагностику у одного,
      // ничего не дав другому. Тесты идут в debug, так что проверяем прямо.
      expect(kReleaseMode, isFalse, reason: 'проверка рассчитана на debug');
      final before = ErrorWidget.builder;
      installNsgErrorWidget(onReload: () {});
      expect(identical(ErrorWidget.builder, before), isTrue);
    });

    test('по явной просьбе подменяем и в debug', () {
      final before = ErrorWidget.builder;
      installNsgErrorWidget(onReload: () {}, alsoInDebug: true);
      expect(identical(ErrorWidget.builder, before), isFalse);
    });
  });
  _guardTests();
}

final ErrorWidgetBuilder _defaultBuilder = ErrorWidget.builder;

/// **Сторож повторного входа** — issue #145.
///
/// Первая редакция этого экрана подвесила Windows-сборку намертво.
/// `ErrorWidget.builder` зовётся из `inflateWidget`; наш экран — не лист, и
/// если ошибка случилась уже на глубине, его построение доедает стек и
/// бросает `StackOverflowError`, который снова ловит `inflateWidget` и снова
/// зовёт нас. В дампе: 21 456 кадров Dart, стек съеден на 899,7 КБ из 904,
/// повторяющийся блок ровно в 21 кадр. Обработчик ошибки стал её источником.
void _guardTests() {
  group('сторож повторного входа (issue #145)', () {
    tearDown(() {
      resetFatalScreenGuard();
      ErrorWidget.builder = _defaultBuilder;
    });

    test('пока экран строится, повторный вызов отдаёт лист', () {
      // Ровно тот цикл из дампа: `inflateWidget` ловит отказ, зовёт
      // `ErrorWidget.builder`, тот строит наш экран, экран доедает стек и
      // бросает — и всё повторяется. Сторож обязан разорвать это здесь.
      //
      // Настоящий флаг живёт ровно на время `build`, поэтому состояние
      // выставляется явно: подстроить отказ ВНУТРИ построения нечем —
      // дерево экрана фиксировано и своих детей не принимает.
      installNsgErrorWidget(onReload: () {}, alsoInDebug: true);
      final builder = ErrorWidget.builder;

      expect(builder(_details()), isA<NsgFatalErrorScreen>());

      debugSetFatalScreenBuilding(true);
      expect(
        builder(_details()),
        isNot(isA<NsgFatalErrorScreen>()),
        reason: 'второй экран внутри первого — это и есть рекурсия',
      );
    });

    test('после трёх подряд переходим на лист', () {
      // Ошибки могут идти не вложенно, а подряд — по соседним виджетам.
      // Вложенности нет, а работа та же, поэтому нужен и счётчик.
      installNsgErrorWidget(onReload: () {}, alsoInDebug: true);
      final builder = ErrorWidget.builder;
      for (var i = 0; i < 3; i++) {
        expect(builder(_details()), isA<NsgFatalErrorScreen>());
      }
      expect(
        builder(_details()),
        isNot(isA<NsgFatalErrorScreen>()),
        reason: 'четвёртый подряд обязан быть безопасным листом',
      );
    });

    test('сброс возвращает человеку внятный экран', () {
      // Иначе три давних ошибки за сессию навсегда лишили бы его сообщения.
      installNsgErrorWidget(onReload: () {}, alsoInDebug: true);
      final builder = ErrorWidget.builder;
      for (var i = 0; i < 4; i++) {
        builder(_details());
      }
      resetFatalScreenGuard();
      expect(builder(_details()), isA<NsgFatalErrorScreen>());
    });
  });
}
