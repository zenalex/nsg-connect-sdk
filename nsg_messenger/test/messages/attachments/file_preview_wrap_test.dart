import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/attachments/file_actions.dart';
import 'package:nsg_messenger/src/messages/attachments/file_preview_screen.dart';

import '../../test_helpers.dart';

/// **Issue #89**: «при открытии текстового файла, если окно сжато, текст не
/// переносится и обрезается».
///
/// Обрезанная по краю строка выглядит как потерянная — что её видно боковой
/// прокруткой, догадаться неоткуда. Поэтому обычный текст переносим, а
/// формат с осмысленным выравниванием (таблицы, логи, код — решение #69)
/// оставляем на горизонтальной прокрутке. И то и другое — лишь дефолт:
/// решает человек кнопкой в шапке.

/// Одна длинная строка без пробелов-переносов: в узком окне она обязана
/// либо переноситься, либо уезжать в горизонтальный скролл — третьего нет.
const _longLine =
    'lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod '
    'tempor incididunt ut labore et dolore magna aliqua ut enim ad minim';

AttachmentRef _att(String filename) => AttachmentRef(
  mxcUrl: 'mxc://t/abc',
  originalFilename: filename,
  mimeType: 'text/plain',
  sizeBytes: _longLine.length,
);

FileActions _actions() => FileActions(
  loadBytes: (_) async => Uint8List.fromList(utf8.encode(_longLine)),
);

/// Есть ли ВНУТРИ поддерева горизонтальный скролл — то есть уехал ли текст
/// вбок вместо переноса.
bool _hasHorizontalScroll(WidgetTester tester) => tester
    .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
    .any((s) => s.scrollDirection == Axis.horizontal);

void main() {
  Future<void> pumpPreview(WidgetTester tester, String filename) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      wrapL10n(
        FilePreviewScreen(attachment: _att(filename), actions: _actions()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('дефолт по формату', () {
    test('простая заметка переносится', () {
      expect(wrapsLinesByDefault('notes.txt'), isTrue);
    });

    test('неизвестное расширение — тоже простой текст', () {
      // Файл приехал по mime `text/*` без знакомого суффикса.
      expect(wrapsLinesByDefault('readme'), isTrue);
      expect(wrapsLinesByDefault('dump.whatever'), isTrue);
    });

    test('форматы с осмысленным выравниванием — НЕ переносятся', () {
      // Перенос ломает таблицы и отступы — решение issue #69.
      for (final f in [
        'a.csv',
        'b.md',
        'c.log',
        'd.json',
        'e.dart',
        'f.yaml',
      ]) {
        expect(wrapsLinesByDefault(f), isFalse, reason: f);
      }
    });

    test('регистр расширения не важен', () {
      expect(wrapsLinesByDefault('TABLE.CSV'), isFalse);
      expect(wrapsLinesByDefault('NOTES.TXT'), isTrue);
    });
  });

  testWidgets('.txt в узком окне: текст переносится, а не уезжает вбок', (
    tester,
  ) async {
    await pumpPreview(tester, 'notes.txt');

    expect(
      _hasHorizontalScroll(tester),
      isFalse,
      reason: 'обычная заметка обязана переноситься по ширине окна',
    );
    // Перенос реален: высота текста больше одной строки.
    final size = tester.getSize(find.byType(SelectableText));
    expect(size.height, greaterThan(20), reason: 'строка так и осталась одной');
  });

  testWidgets('.csv в узком окне: выравнивание сохраняем (скролл вбок)', (
    tester,
  ) async {
    await pumpPreview(tester, 'table.csv');
    expect(
      _hasHorizontalScroll(tester),
      isTrue,
      reason: 'перенос сломал бы таблицу — тут прокрутка, а не перенос',
    );
  });

  testWidgets('кнопка в шапке переключает режим в обе стороны', (tester) async {
    await pumpPreview(tester, 'table.csv');
    expect(_hasHorizontalScroll(tester), isTrue);

    // Дефолт — только дефолт: человек всегда может решить иначе.
    await tester.tap(find.byKey(const Key('filePreviewWrapToggle')));
    await tester.pumpAndSettle();
    expect(
      _hasHorizontalScroll(tester),
      isFalse,
      reason: 'нажали «переносить» — перенос обязан включиться',
    );

    await tester.tap(find.byKey(const Key('filePreviewWrapToggle')));
    await tester.pumpAndSettle();
    expect(
      _hasHorizontalScroll(tester),
      isTrue,
      reason: 'и обратно — иначе переключатель односторонний',
    );
  });
}
