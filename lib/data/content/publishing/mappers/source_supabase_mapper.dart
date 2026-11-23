import '../../content_ids.dart';
import '../../models/source_content_model.dart';

/// Maps a source to a row of Supabase `public.content_sources`. The id is
/// `ContentIds.source(<source key>)`. Nothing is invented: empty fields are
/// published as null.
abstract final class SourceSupabaseMapper {
  static const String table = 'content_sources';

  static const List<String> contentColumns = [
    'id',
    'name',
    'author',
    'source_url',
    'license',
    'attribution',
  ];

  static const List<String> selectColumns = [
    ...contentColumns,
    'created_at',
    'updated_at',
    'deleted_at',
  ];

  static Map<String, Object?> toRow(SourceContentModel source) => {
    'id': ContentIds.source(source.id),
    'name': source.name,
    'author': source.author,
    'source_url': source.sourceUrl,
    'license': source.license,
    'attribution': source.attribution,
  };
}
