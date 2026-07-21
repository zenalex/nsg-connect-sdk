import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/rooms/folder_row.dart';

import '../test_helpers.dart';

/// TASK44 фаза 1.5: widget-тесты строки-папки [FolderRow]:
///   * имя продукта (displayName / fallback на ключ / generic);
///   * превью самого свежего чата в subtitle; fallback на число чатов;
///   * unread-бейдж при unread>0;
///   * тап зовёт onTap (drill-in).
void main() {
  ChatFolder productFolder({
    int id = 10,
    String? name = 'Титан',
    String? key,
    int unread = 0,
    int rooms = 2,
    String? preview,
    DateTime? at,
  }) => ChatFolder(
    kind: ChatFolderKind.product,
    productId: id,
    productDisplayName: name,
    productKey: key,
    unreadCount: unread,
    roomCount: rooms,
    lastMessagePreview: preview,
    lastMessageAt: at,
  );

  testWidgets('рендерит имя продукта + превью самого свежего чата', (t) async {
    await t.pumpWidget(
      wrapL10n(
        FolderRow(
          folder: productFolder(name: 'Титан', preview: 'привет'),
          onTap: () {},
        ),
        locale: const Locale('ru'),
      ),
    );
    expect(find.text('Титан'), findsOneWidget);
    expect(find.text('привет'), findsOneWidget);
  });

  testWidgets('нет превью → subtitle показывает число чатов', (t) async {
    await t.pumpWidget(
      wrapL10n(
        FolderRow(folder: productFolder(rooms: 3), onTap: () {}),
        locale: const Locale('ru'),
      ),
    );
    // chatsListFolderRoomCount(3) → «3 чата» (ru plural).
    expect(find.textContaining('3'), findsWidgets);
  });

  testWidgets('fallback имени: productKey когда displayName == null', (
    t,
  ) async {
    await t.pumpWidget(
      wrapL10n(
        FolderRow(
          folder: productFolder(name: null, key: 'titan_control'),
          onTap: () {},
        ),
        locale: const Locale('ru'),
      ),
    );
    expect(find.text('titan_control'), findsOneWidget);
  });

  testWidgets('unread-бейдж показан при unread>0', (t) async {
    await t.pumpWidget(
      wrapL10n(
        FolderRow(folder: productFolder(unread: 7), onTap: () {}),
        locale: const Locale('ru'),
      ),
    );
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('тап зовёт onTap (drill-in)', (t) async {
    var tapped = false;
    await t.pumpWidget(
      wrapL10n(
        FolderRow(folder: productFolder(), onTap: () => tapped = true),
        locale: const Locale('ru'),
      ),
    );
    await t.tap(find.text('Титан'));
    expect(tapped, isTrue);
  });
}
