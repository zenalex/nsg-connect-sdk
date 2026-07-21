import 'package:sqflite_common/sqlite_api.dart';

/// **TASK47 iter1**: web/fallback-вариант резолва фабрики кэш-БД.
///
/// Выбирается conditional-import-ом, когда `dart:io` НЕдоступен (web). На
/// web дисковый кэш в iter1 отключён (нужен sqlite-wasm worker — §6):
/// возвращаем `null`, и [MessengerCacheStore.openForUser] отдаёт `null` →
/// host работает без диска (in-memory + индикация оффлайна).
DatabaseFactory? resolveCacheDatabaseFactory() => null;
