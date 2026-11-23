import 'package:drift/drift.dart';

import '../converters.dart';

/// Cache of the shared `chapters` table in Supabase.
///
/// `id` is the chapter number (1–18), exactly as in Supabase. Timestamps are
/// copied from the server, never generated locally, so they can be compared
/// with server values during sync. Rows are never physically deleted. A server
/// tombstone sets [deletedAt].
@TableIndex(name: 'local_chapters_updated_at_idx', columns: {#updatedAt, #id})
class LocalChapters extends Table {
  // Drift evaluates check() lazily; the self-reference is intended.
  // ignore: recursive_getters
  IntColumn get id => integer().check(id.isBetweenValues(1, 18))();

  TextColumn get sanskritName => text()();
  TextColumn get hindiName => text()();
  TextColumn get englishName => text()();

  TextColumn get introduction => text().nullable()();
  TextColumn get overview => text().nullable()();
  TextColumn get centralTheme => text().nullable()();

  /// JSON array of strings, e.g. `["Duty","Grief"]`.
  TextColumn get keyTopics =>
      text().map(const StringListConverter()).nullable()();

  TextColumn get summary => text().nullable()();
  TextColumn get conclusion => text().nullable()();

  TextColumn get createdAt => text().map(const UtcTimestampConverter())();
  TextColumn get updatedAt => text().map(const UtcTimestampConverter())();
  TextColumn get deletedAt =>
      text().map(const UtcTimestampConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  bool get isStrict => true;
}
