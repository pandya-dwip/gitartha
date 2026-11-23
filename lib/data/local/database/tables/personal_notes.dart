import 'package:drift/drift.dart';

import '../converters.dart';
import 'local_shlokas.dart';

/// The user's private notes, either about a shloka or free-standing
/// ([shlokaId] is null). Any number of notes per shloka. Never synchronized.
@TableIndex(
  name: 'personal_notes_shloka_updated_idx',
  columns: {#shlokaId, #updatedAt},
)
@TableIndex(name: 'personal_notes_updated_idx', columns: {#updatedAt})
class PersonalNotes extends Table {
  TextColumn get id => text().check(id.length.equals(36))();

  TextColumn get shlokaId => text().nullable().references(
    LocalShlokas,
    #id,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get title => text().nullable()();
  TextColumn get content => text()();

  TextColumn get createdAt => text().map(const UtcTimestampConverter())();
  TextColumn get updatedAt => text().map(const UtcTimestampConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (length(trim(content, ' ' || char(9) || char(10) || char(13))) > 0)",
    "CHECK (title IS NULL OR length(trim(title, ' ' || char(9) || char(10) || char(13))) > 0)",
    'CHECK (updated_at >= created_at)',
  ];

  @override
  bool get isStrict => true;
}
