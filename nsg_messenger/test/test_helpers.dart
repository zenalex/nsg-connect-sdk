import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';

/// Test helper для widget-тестов с `NsgL10n` (TASK22 Chunk 1).
///
/// Drop-in замена для inline `MaterialApp + Localizations.override` —
/// раньше тесты обходились без `flutter_localizations`, потому что
/// `t(context, ru, en)` использовал только `Localizations.maybeLocaleOf
/// (context)?.languageCode`. После миграции на ARB-generated `NsgL10n`
/// тесты должны передавать `NsgL10n.delegate` через `localizationsDelegates`.
///
/// Использование:
/// ```dart
/// await tester.pumpWidget(
///   wrapL10n(MyWidget(), locale: const Locale('ru')),
/// );
/// ```
///
/// `GlobalMaterialLocalizations.delegate` нужен для не-EN locale +
/// Material widgets (например, `TextField` рендерит RU-локализованный
/// keyboard label). Без него на `locale='ru'` Flutter throws
/// `No MaterialLocalizations found`.
Widget wrapL10n(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      NsgL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(body: child),
  );
}
