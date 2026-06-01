import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../test_helpers.dart';

/// Widget-тесты для [RoomSummaryTile]: рендер базовых полей,
/// initials fallback при отсутствии avatarUrl, mute icon, unread badge,
/// relative-time formatting через timeago, onTap callback.
void main() {
  setUpAll(() {
    timeago.setLocaleMessages('ru', timeago.RuMessages());
  });

  RoomSummary summary({
    int id = 1,
    String? name = 'Alice Smith',
    String? avatarUrl,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int unreadCount = 0,
    bool muted = false,
  }) => RoomSummary(
    id: id,
    name: name,
    avatarUrl: avatarUrl,
    lastMessagePreview: lastMessagePreview,
    lastMessageAt: lastMessageAt,
    unreadCount: unreadCount,
    archived: false,
    muted: muted,
    roomType: RoomType.direct,
  );

  // TASK22 Chunk 1: единый wrap-helper с `flutter_localizations`
  // delegates (NsgL10n + Material global delegates). Старый паттерн
  // `Localizations.override` без delegates ломался для не-EN locale +
  // Material widgets — теперь не актуален.
  Widget wrap(Widget child, {Locale locale = const Locale('en')}) =>
      wrapL10n(child, locale: locale);

  testWidgets('рендерит name и lastMessagePreview', (t) async {
    await t.pumpWidget(
      wrap(
        RoomSummaryTile(
          room: summary(name: 'Alice', lastMessagePreview: 'Hi there'),
        ),
      ),
    );
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Hi there'), findsOneWidget);
  });

  testWidgets('initials fallback без avatarUrl', (t) async {
    await t.pumpWidget(
      wrap(
        RoomSummaryTile(room: summary(name: 'Alice Smith', avatarUrl: null)),
      ),
    );
    // Initials = first letter of first + first letter of last word.
    expect(find.text('AS'), findsOneWidget);
  });

  testWidgets('initials для одного слова', (t) async {
    await t.pumpWidget(wrap(RoomSummaryTile(room: summary(name: 'Alice'))));
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('initials "?" для null имени', (t) async {
    await t.pumpWidget(wrap(RoomSummaryTile(room: summary(name: null))));
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('null lastMessagePreview → fallback i18n EN', (t) async {
    await t.pumpWidget(
      wrap(RoomSummaryTile(room: summary(lastMessagePreview: null))),
    );
    expect(find.text('No messages'), findsOneWidget);
  });

  testWidgets('null lastMessagePreview → fallback i18n RU', (t) async {
    await t.pumpWidget(
      wrap(
        RoomSummaryTile(room: summary(lastMessagePreview: null)),
        locale: const Locale('ru'),
      ),
    );
    expect(find.text('Нет сообщений'), findsOneWidget);
  });

  testWidgets('mute icon при muted=true', (t) async {
    await t.pumpWidget(wrap(RoomSummaryTile(room: summary(muted: true))));
    expect(find.byIcon(Icons.notifications_off), findsOneWidget);
  });

  testWidgets('unread badge показывается при unreadCount>0', (t) async {
    await t.pumpWidget(wrap(RoomSummaryTile(room: summary(unreadCount: 7))));
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('unread badge "99+" при > 99', (t) async {
    await t.pumpWidget(wrap(RoomSummaryTile(room: summary(unreadCount: 150))));
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('unread badge не показывается при 0', (t) async {
    await t.pumpWidget(wrap(RoomSummaryTile(room: summary(unreadCount: 0))));
    expect(find.text('0'), findsNothing);
  });

  testWidgets('relative time через timeago — EN', (t) async {
    final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5));
    await t.pumpWidget(
      wrap(RoomSummaryTile(room: summary(lastMessageAt: fiveMinAgo))),
    );
    // timeago EN для 5 минут назад: "5 minutes ago".
    expect(find.textContaining('5 minutes'), findsOneWidget);
  });

  testWidgets('relative time через timeago — RU', (t) async {
    final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5));
    await t.pumpWidget(
      wrap(
        RoomSummaryTile(room: summary(lastMessageAt: fiveMinAgo)),
        locale: const Locale('ru'),
      ),
    );
    // timeago RU для 5 минут назад: "5 минут назад".
    expect(find.textContaining('5 минут'), findsOneWidget);
  });

  testWidgets('onTap callback срабатывает', (t) async {
    var tapped = false;
    await t.pumpWidget(
      wrap(RoomSummaryTile(room: summary(), onTap: () => tapped = true)),
    );
    await t.tap(find.byType(ListTile));
    expect(tapped, isTrue);
  });

  // ---------------------------------------------------------------
  // TASK22 Phase2 Chunk 1: NsgRoomTileTokens integration tests —
  // verify host-app override propagates через Theme extension.
  // ---------------------------------------------------------------
  group('NsgRoomTileTokens integration', () {
    /// Wrap RoomSummaryTile с custom ThemeData.extensions — без
    /// MessengerThemeScope (прямой ThemeData test API).
    Widget wrapWithTokens(Widget child, NsgRoomTileTokens tokens) {
      return MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          NsgL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: NsgL10n.supportedLocales,
        theme: ThemeData(extensions: [tokens]),
        home: Scaffold(body: child),
      );
    }

    testWidgets('avatarSize override → CircleAvatar.radius', (t) async {
      const customSize = 60.0;
      const tokens = NsgRoomTileTokens(
        avatarSize: customSize,
        unreadBadgeSize: 20,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleSubtitleSpacing: 4,
      );
      await t.pumpWidget(
        wrapWithTokens(
          RoomSummaryTile(room: summary(name: 'Alice', avatarUrl: null)),
          tokens,
        ),
      );
      // Initials path → CircleAvatar(radius: customSize/2).
      final avatar = t.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.radius, customSize / 2);
    });

    testWidgets('contentPadding override → ListTile.contentPadding', (t) async {
      const customPadding = EdgeInsets.all(24);
      const tokens = NsgRoomTileTokens(
        avatarSize: 44,
        unreadBadgeSize: 20,
        contentPadding: customPadding,
        titleSubtitleSpacing: 4,
      );
      await t.pumpWidget(
        wrapWithTokens(RoomSummaryTile(room: summary(name: 'Alice')), tokens),
      );
      final tile = t.widget<ListTile>(find.byType(ListTile));
      expect(tile.contentPadding, customPadding);
    });

    testWidgets('fallback используется когда extension отсутствует', (t) async {
      // wrapL10n не задаёт extensions — RoomSummaryTile должен взять
      // NsgRoomTileTokens.fallback.
      await t.pumpWidget(
        wrap(RoomSummaryTile(room: summary(name: 'Alice', avatarUrl: null))),
      );
      final avatar = t.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.radius, NsgRoomTileTokens.fallback.avatarSize / 2);
      final tile = t.widget<ListTile>(find.byType(ListTile));
      expect(tile.contentPadding, NsgRoomTileTokens.fallback.contentPadding);
    });
  });
}
