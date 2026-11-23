import 'package:drift/drift.dart';

import '../converters.dart';
import 'local_shlokas.dart';
import 'reading_progress.dart';

/// A reading activity recorded in `reading_history`.
enum ReadingActivity implements SqlEnum {
  opened('opened'),
  markedRead('marked_read'),
  markedStudied('marked_studied'),
  markedReflected('marked_reflected');

  const ReadingActivity(this.sqlValue);

  @override
  final String sqlValue;

  /// The activity logged when a shloka is explicitly marked with [status].
  static ReadingActivity forStatus(ReadingStatus status) => switch (status) {
    ReadingStatus.opened => ReadingActivity.opened,
    ReadingStatus.read => ReadingActivity.markedRead,
    ReadingStatus.studied => ReadingActivity.markedStudied,
    ReadingStatus.reflected => ReadingActivity.markedReflected,
  };
}

/// Append-only log of reading activity. Many rows per shloka. Rows are never
/// updated.
@DataClassName('ReadingHistoryEntry')
@TableIndex(
  name: 'reading_history_shloka_occurred_idx',
  columns: {#shlokaId, #occurredAt},
)
@TableIndex(name: 'reading_history_occurred_idx', columns: {#occurredAt})
class ReadingHistory extends Table {
  TextColumn get id => text().check(id.length.equals(36))();

  TextColumn get shlokaId =>
      text().references(LocalShlokas, #id, onDelete: KeyAction.restrict)();

  TextColumn get action => text().map(
    const SqlEnumConverter<ReadingActivity>(ReadingActivity.values),
  )();

  TextColumn get occurredAt => text().map(const UtcTimestampConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    // `action` is an SQL keyword, so it is quoted.
    "CHECK (\"action\" IN ('opened', 'marked_read', 'marked_studied', 'marked_reflected'))",
  ];

  @override
  bool get isStrict => true;
}
