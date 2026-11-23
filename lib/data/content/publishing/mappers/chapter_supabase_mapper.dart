import '../../models/chapter_content_model.dart';

/// Maps a chapter to a row of Supabase `public.chapters`.
///
/// Only content columns are sent. `created_at` and `updated_at` are
/// maintained by the database trigger (`set_row_timestamps`), and
/// `deleted_at` is never sent, so publishing can neither back-date a row
/// nor undo a soft delete.
abstract final class ChapterSupabaseMapper {
  static const String table = 'chapters';

  /// Columns that publishing writes and compares.
  static const List<String> contentColumns = [
    'id',
    'sanskrit_name',
    'hindi_name',
    'english_name',
    'introduction',
    'overview',
    'central_theme',
    'key_topics',
    'summary',
    'conclusion',
  ];

  /// Columns read back for comparison.
  static const List<String> selectColumns = [
    ...contentColumns,
    'created_at',
    'updated_at',
    'deleted_at',
  ];

  /// The row for [chapter]. With [includeDescriptions] false (approved
  /// publishing of unapproved metadata), the descriptive fields are null.
  static Map<String, Object?> toRow(
    ChapterMetadataModel chapter, {
    required bool includeDescriptions,
  }) => {
    'id': chapter.id,
    'sanskrit_name': chapter.sanskritName,
    'hindi_name': chapter.hindiName,
    'english_name': chapter.englishName,
    'introduction': includeDescriptions ? chapter.introduction : null,
    'overview': includeDescriptions ? chapter.overview : null,
    'central_theme': includeDescriptions ? chapter.centralTheme : null,
    'key_topics': includeDescriptions && chapter.keyTopics.isNotEmpty
        ? List<String>.of(chapter.keyTopics)
        : null,
    'summary': includeDescriptions ? chapter.summary : null,
    'conclusion': includeDescriptions ? chapter.conclusion : null,
  };
}
