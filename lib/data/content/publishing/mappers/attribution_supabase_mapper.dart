import '../../content_ids.dart';
import '../../models/shloka_content_model.dart';
import '../../models/source_attribution_model.dart';

/// Maps one attribution to a row of Supabase
/// `public.shloka_source_attributions`.
///
/// Attribution rows are immutable in Supabase (editors may insert and delete
/// them, but not update them). Publishing therefore only **inserts** missing
/// mappings, ignoring duplicates, and never deletes. The id is the
/// deterministic `ContentIds.attribution(...)`.
abstract final class AttributionSupabaseMapper {
  static const String table = 'shloka_source_attributions';

  /// The unique key used as the conflict target.
  static const String conflictTarget = 'shloka_id,source_id,content_section';

  static const List<String> contentColumns = [
    'id',
    'shloka_id',
    'source_id',
    'content_section',
  ];

  static const List<String> selectColumns = [...contentColumns, 'created_at'];

  static Map<String, Object?> toRow(
    ShlokaContentModel verse,
    SourceAttributionModel attribution,
  ) => {
    'id': ContentIds.attribution(
      verse.id,
      attribution.sourceId,
      attribution.contentSection.jsonValue,
    ),
    'shloka_id': ContentIds.shloka(verse.id),
    'source_id': ContentIds.source(attribution.sourceId),
    'content_section': attribution.contentSection.jsonValue,
  };

  /// The natural key of a row (for de-duplication and comparison).
  static String naturalKey(Map<String, Object?> row) =>
      '${row['shloka_id']}|${row['source_id']}|${row['content_section']}';
}
