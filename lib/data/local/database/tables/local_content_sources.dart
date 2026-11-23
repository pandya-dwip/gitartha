import 'package:drift/drift.dart';

import '../converters.dart';

/// Cache of Supabase `content_sources`: translations, editions and
/// commentaries with their licence and required credit text. Added in
/// schema version 2, so that verse attributions can be kept and shown
/// offline.
///
/// [id] is the source's UUID. For content imported from the JSON repository
/// it is the deterministic `ContentIds.source(<source key>)`, which the
/// future Supabase import will use too.
@TableIndex(
  name: 'local_content_sources_updated_at_idx',
  columns: {#updatedAt, #id},
)
class LocalContentSources extends Table {
  TextColumn get id => text().check(id.length.equals(36))();
  TextColumn get name => text()();
  TextColumn get author => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get license => text().nullable()();
  TextColumn get attribution => text().nullable()();

  TextColumn get createdAt => text().map(const UtcTimestampConverter())();
  TextColumn get updatedAt => text().map(const UtcTimestampConverter())();
  TextColumn get deletedAt =>
      text().map(const UtcTimestampConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  bool get isStrict => true;
}
