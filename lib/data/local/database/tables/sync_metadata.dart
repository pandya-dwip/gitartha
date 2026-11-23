import 'package:drift/drift.dart';

import '../converters.dart';

/// Local bookkeeping for the future content-sync milestone, e.g. the last
/// successful sync time or per-table cursors. This milestone has no sync;
/// the table only exists so the schema does not need a migration for it.
@DataClassName('SyncMetadataEntry')
class SyncMetadata extends Table {
  TextColumn get key => text().check(key.length.isBiggerThanValue(0))();
  TextColumn get value => text()();
  TextColumn get updatedAt => text().map(const UtcTimestampConverter())();

  @override
  Set<Column<Object>> get primaryKey => {key};

  @override
  bool get isStrict => true;
}
