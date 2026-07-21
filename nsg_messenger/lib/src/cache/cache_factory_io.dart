import 'dart:io' show Platform;

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// **TASK47 iter1**: io-вариант резолва фабрики кэш-БД (mobile + desktop).
///
/// Выбирается conditional-import-ом, когда `dart:io` доступен. Desktop
/// (Windows/Linux/macOS) — sqflite_common_ffi (нативный sqlite3); mobile
/// (Android/iOS) — дефолтная фабрика sqflite (platform channel).
DatabaseFactory? resolveCacheDatabaseFactory() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return sqflite.databaseFactory;
}
