import 'package:drift/drift.dart';

import '../converters.dart';
import 'local_shlokas.dart';

/// The user's personal answers to a shloka's reflection question.
///
/// A shloka can have any number of reflections, so there is deliberately no
/// unique constraint on [shlokaId]. Each answer is its own dated entry, and
/// a new answer never overwrites an older one. Stored only on this device
/// and never synchronized.
@TableIndex(
  name: 'reflections_shloka_created_idx',
  columns: {#shlokaId, #createdAt},
)
@TableIndex(name: 'reflections_created_idx', columns: {#createdAt})
class Reflections extends Table {
  TextColumn get id => text().check(id.length.equals(36))();

  /// RESTRICT: cached scripture is never physically deleted, so this only
  /// ever blocks a mistake that would orphan or destroy personal data.
  TextColumn get shlokaId =>
      text().references(LocalShlokas, #id, onDelete: KeyAction.restrict)();

  TextColumn get answer => text()();

  TextColumn get createdAt => text().map(const UtcTimestampConverter())();
  TextColumn get updatedAt => text().map(const UtcTimestampConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (length(trim(answer, ' ' || char(9) || char(10) || char(13))) > 0)",
    'CHECK (updated_at >= created_at)',
  ];

  @override
  bool get isStrict => true;
}
