import 'package:drift/drift.dart';

import '../converters.dart';
import 'local_shlokas.dart';

/// How far the user has gone with a shloka. The levels are ordered, and the
/// current status only moves forward (see `ReadingProgressDao`).
///
/// Opening a shloka gives [opened] and nothing more. [read], [studied] and
/// [reflected] are only ever set by an explicit action. Bookmarks are not
/// a status; they live in their own table.
enum ReadingStatus implements SqlEnum {
  opened('opened', 0),
  read('read', 1),
  studied('studied', 2),
  reflected('reflected', 3);

  const ReadingStatus(this.sqlValue, this.rank);

  @override
  final String sqlValue;

  /// Position in the progression. A higher rank is further along.
  final int rank;
}

/// One progress record per shloka (unique [shlokaId]).
@DataClassName('ReadingProgressEntry')
class ReadingProgress extends Table {
  TextColumn get id => text().check(id.length.equals(36))();

  TextColumn get shlokaId => text().unique().references(
    LocalShlokas,
    #id,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get status =>
      text().map(const SqlEnumConverter<ReadingStatus>(ReadingStatus.values))();

  TextColumn get firstOpenedAt => text().map(const UtcTimestampConverter())();
  TextColumn get lastOpenedAt => text().map(const UtcTimestampConverter())();
  TextColumn get studiedAt =>
      text().map(const UtcTimestampConverter()).nullable()();
  TextColumn get reflectedAt =>
      text().map(const UtcTimestampConverter()).nullable()();
  TextColumn get updatedAt => text().map(const UtcTimestampConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (status IN ('opened', 'read', 'studied', 'reflected'))",
    'CHECK (last_opened_at >= first_opened_at)',
  ];

  @override
  bool get isStrict => true;
}
