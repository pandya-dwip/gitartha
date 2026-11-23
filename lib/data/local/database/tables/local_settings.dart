import 'package:drift/drift.dart';

import '../converters.dart';

/// Device-local preferences (theme, font sizes and so on).
///
/// [value] is always JSON text, e.g. `"dark"`, `1.2`, `true` or
/// `{"a":1}`, so typed values round-trip exactly. Credentials and keys must
/// never be stored here; `SettingsDao` rejects keys that look like secrets.
class LocalSettings extends Table {
  TextColumn get key => text().check(key.length.isBiggerThanValue(0))();
  TextColumn get value => text()();
  TextColumn get updatedAt => text().map(const UtcTimestampConverter())();

  @override
  Set<Column<Object>> get primaryKey => {key};

  @override
  bool get isStrict => true;
}
