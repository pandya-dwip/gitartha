import 'package:drift/drift.dart';

import '../converters.dart';
import 'local_chapters.dart';

/// Cache of the shared `shlokas` table in Supabase.
///
/// [id] is the Supabase UUID, stored unchanged. Personal tables reference it,
/// so it must never be regenerated. Rows are never physically deleted: a
/// server tombstone sets [deletedAt], and personal data stays attached.
///
/// This table holds shared content only. Personal answers live in
/// `reflections`.
///
/// Indexes: the unique `(chapter_id, verse_number)` constraint also serves
/// chapter navigation and the `chapter_id` foreign key.
@TableIndex(name: 'local_shlokas_reference_idx', columns: {#reference})
@TableIndex(name: 'local_shlokas_updated_at_idx', columns: {#updatedAt, #id})
class LocalShlokas extends Table {
  TextColumn get id => text().check(id.length.equals(36))();

  IntColumn get chapterId =>
      integer().references(LocalChapters, #id, onDelete: KeyAction.restrict)();

  // Drift evaluates check() lazily; the self-reference is intended.
  IntColumn get verseNumber =>
      // ignore: recursive_getters
      integer().check(verseNumber.isBiggerThanValue(0))();

  /// `"<chapter>.<verse>"`, e.g. `1.41`. A table CHECK keeps it consistent
  /// with [chapterId] and [verseNumber], like Supabase's generated column.
  TextColumn get reference => text()();

  TextColumn get indexTitle => text().nullable()();
  TextColumn get indexSummary => text().nullable()();

  // Reading order.
  TextColumn get sanskritText => text().nullable()();
  TextColumn get transliteration => text().nullable()();
  TextColumn get hindiMeaning => text().nullable()();

  /// Optional note on the Hindi wording. Never merged into [hindiMeaning].
  TextColumn get hindiMeaningNote => text().nullable()();
  TextColumn get englishMeaning => text().nullable()();
  TextColumn get context => text().nullable()();
  TextColumn get lifeLesson => text().nullable()();
  TextColumn get spiritualMeaning => text().nullable()();
  TextColumn get reflectionQuestion => text().nullable()();

  TextColumn get createdAt => text().map(const UtcTimestampConverter())();
  TextColumn get updatedAt => text().map(const UtcTimestampConverter())();
  TextColumn get deletedAt =>
      text().map(const UtcTimestampConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {chapterId, verseNumber},
  ];

  @override
  List<String> get customConstraints => [
    "CHECK (reference = chapter_id || '.' || verse_number)",
  ];

  @override
  bool get isStrict => true;
}
