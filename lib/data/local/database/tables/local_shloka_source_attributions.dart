import 'package:drift/drift.dart';

import '../converters.dart';
import 'local_content_sources.dart';
import 'local_shlokas.dart';

/// Cache of Supabase `shloka_source_attributions`: which source a section of
/// a verse came from. Added in schema version 2. Rows are immutable shared
/// content: a re-import inserts missing mappings and removes ones no longer
/// in the source. Personal data never references this table.
///
/// The unique `(shloka_id, source_id, content_section)` key also indexes
/// lookups by verse.
@DataClassName('LocalShlokaSourceAttribution')
@TableIndex(
  name: 'local_shloka_source_attributions_source_idx',
  columns: {#sourceId},
)
class LocalShlokaSourceAttributions extends Table {
  TextColumn get id => text().check(id.length.equals(36))();

  TextColumn get shlokaId =>
      text().references(LocalShlokas, #id, onDelete: KeyAction.restrict)();

  TextColumn get sourceId => text().references(
    LocalContentSources,
    #id,
    onDelete: KeyAction.restrict,
  )();

  /// One of the nine attributable verse fields.
  TextColumn get contentSection => text()();

  TextColumn get createdAt => text().map(const UtcTimestampConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {shlokaId, sourceId, contentSection},
  ];

  @override
  List<String> get customConstraints => [
    "CHECK (content_section IN ('sanskrit_text', 'transliteration', 'hindi_meaning', 'hindi_meaning_note', 'english_meaning', 'context', 'life_lesson', 'spiritual_meaning', 'reflection_question'))",
  ];

  @override
  bool get isStrict => true;
}
