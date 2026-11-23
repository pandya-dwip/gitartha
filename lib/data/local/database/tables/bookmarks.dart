import 'package:drift/drift.dart';

import '../converters.dart';
import 'local_shlokas.dart';

/// Bookmarked shlokas. A shloka can be bookmarked at most once at a time:
/// [shlokaId] is unique, and removing a bookmark deletes its row.
@TableIndex(name: 'bookmarks_created_idx', columns: {#createdAt})
class Bookmarks extends Table {
  TextColumn get id => text().check(id.length.equals(36))();

  TextColumn get shlokaId => text().unique().references(
    LocalShlokas,
    #id,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get createdAt => text().map(const UtcTimestampConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  bool get isStrict => true;
}
