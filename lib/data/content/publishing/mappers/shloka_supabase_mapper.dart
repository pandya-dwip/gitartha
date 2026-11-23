import '../../content_ids.dart';
import '../../models/shloka_content_model.dart';

/// Maps a verse to a row of Supabase `public.shlokas`.
///
/// * `id` is the deterministic UUID of the verse's content id
///   (`ContentIds.shloka`), the same id the local cache uses.
/// * `reference` is **not** sent: it is a generated column in Supabase
///   (`chapter_id || '.' || verse_number`).
/// * `hindi_meaning_note` is its own column, never merged into
///   `hindi_meaning`.
/// * Timestamps and `deleted_at` are not sent (see `ChapterSupabaseMapper`).
abstract final class ShlokaSupabaseMapper {
  static const String table = 'shlokas';

  static const List<String> contentColumns = [
    'id',
    'chapter_id',
    'verse_number',
    'index_title',
    'index_summary',
    'sanskrit_text',
    'transliteration',
    'hindi_meaning',
    'hindi_meaning_note',
    'english_meaning',
    'context',
    'life_lesson',
    'spiritual_meaning',
    'reflection_question',
  ];

  static const List<String> selectColumns = [
    ...contentColumns,
    'reference',
    'created_at',
    'updated_at',
    'deleted_at',
  ];

  static Map<String, Object?> toRow(int chapterId, ShlokaContentModel verse) =>
      {
        'id': ContentIds.shloka(verse.id),
        'chapter_id': chapterId,
        'verse_number': verse.verseNumber,
        'index_title': verse.indexTitle,
        'index_summary': verse.indexSummary,
        'sanskrit_text': verse.sanskritText,
        'transliteration': verse.transliteration,
        'hindi_meaning': verse.hindiMeaning,
        'hindi_meaning_note': verse.hindiMeaningNote,
        'english_meaning': verse.englishMeaning,
        'context': verse.context,
        'life_lesson': verse.lifeLesson,
        'spiritual_meaning': verse.spiritualMeaning,
        'reflection_question': verse.reflectionQuestion,
      };
}
