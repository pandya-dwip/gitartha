import '../../../data/local/database/app_database.dart';
import '../domain/sync_result.dart';

/// Converts Supabase rows into the existing Drift cache rows.
///
/// Strict: a missing required field or a wrong type throws
/// [SyncException] (`invalidRemoteData`), so a malformed response aborts the
/// run instead of writing half-empty scripture. Nullable fields are copied
/// as-is (null stays null; nothing is dropped). Ids are the server's ids,
/// never regenerated.
abstract final class RemoteRowMapper {
  static LocalChapter chapter(Map<String, dynamic> r) => _guard(
    'chapters',
    () => LocalChapter(
      id: _int(r, 'id'),
      sanskritName: _str(r, 'sanskrit_name'),
      hindiName: _str(r, 'hindi_name'),
      englishName: _str(r, 'english_name'),
      introduction: _strOrNull(r, 'introduction'),
      overview: _strOrNull(r, 'overview'),
      centralTheme: _strOrNull(r, 'central_theme'),
      keyTopics: _strListOrNull(r, 'key_topics'),
      summary: _strOrNull(r, 'summary'),
      conclusion: _strOrNull(r, 'conclusion'),
      createdAt: _ts(r, 'created_at'),
      updatedAt: _ts(r, 'updated_at'),
      deletedAt: _tsOrNull(r, 'deleted_at'),
    ),
  );

  static LocalContentSource source(Map<String, dynamic> r) => _guard(
    'content_sources',
    () => LocalContentSource(
      id: _str(r, 'id'),
      name: _str(r, 'name'),
      author: _strOrNull(r, 'author'),
      sourceUrl: _strOrNull(r, 'source_url'),
      license: _strOrNull(r, 'license'),
      attribution: _strOrNull(r, 'attribution'),
      createdAt: _ts(r, 'created_at'),
      updatedAt: _ts(r, 'updated_at'),
      deletedAt: _tsOrNull(r, 'deleted_at'),
    ),
  );

  static LocalShloka shloka(Map<String, dynamic> r) => _guard('shlokas', () {
    final chapterId = _int(r, 'chapter_id');
    final verseNumber = _int(r, 'verse_number');
    return LocalShloka(
      id: _str(r, 'id'),
      chapterId: chapterId,
      verseNumber: verseNumber,
      // Generated on the server; derived the same way locally.
      reference: '$chapterId.$verseNumber',
      indexTitle: _strOrNull(r, 'index_title'),
      indexSummary: _strOrNull(r, 'index_summary'),
      sanskritText: _strOrNull(r, 'sanskrit_text'),
      transliteration: _strOrNull(r, 'transliteration'),
      hindiMeaning: _strOrNull(r, 'hindi_meaning'),
      hindiMeaningNote: _strOrNull(r, 'hindi_meaning_note'),
      englishMeaning: _strOrNull(r, 'english_meaning'),
      context: _strOrNull(r, 'context'),
      lifeLesson: _strOrNull(r, 'life_lesson'),
      spiritualMeaning: _strOrNull(r, 'spiritual_meaning'),
      reflectionQuestion: _strOrNull(r, 'reflection_question'),
      createdAt: _ts(r, 'created_at'),
      updatedAt: _ts(r, 'updated_at'),
      deletedAt: _tsOrNull(r, 'deleted_at'),
    );
  });

  static LocalShlokaSourceAttribution attribution(Map<String, dynamic> r) =>
      _guard(
        'shloka_source_attributions',
        () => LocalShlokaSourceAttribution(
          id: _str(r, 'id'),
          shlokaId: _str(r, 'shloka_id'),
          sourceId: _str(r, 'source_id'),
          contentSection: _str(r, 'content_section'),
          createdAt: _ts(r, 'created_at'),
        ),
      );

  static T _guard<T>(String table, T Function() parse) {
    try {
      return parse();
    } on FormatException catch (e) {
      throw SyncException(
        SyncFailureKind.invalidRemoteData,
        '$table: ${e.message}',
      );
    }
  }

  static Object? _field(Map<String, dynamic> r, String key) {
    if (!r.containsKey(key)) throw FormatException('missing "$key"');
    return r[key];
  }

  static String _str(Map<String, dynamic> r, String key) {
    final v = _field(r, key);
    if (v is String) return v;
    throw FormatException('"$key" must be text');
  }

  static String? _strOrNull(Map<String, dynamic> r, String key) {
    final v = _field(r, key);
    if (v == null || v is String) return v as String?;
    throw FormatException('"$key" must be text or null');
  }

  static int _int(Map<String, dynamic> r, String key) {
    final v = _field(r, key);
    if (v is int) return v;
    throw FormatException('"$key" must be an integer');
  }

  static List<String>? _strListOrNull(Map<String, dynamic> r, String key) {
    final v = _field(r, key);
    if (v == null) return null;
    if (v is List && v.every((e) => e is String)) {
      return List<String>.unmodifiable(v.cast<String>());
    }
    throw FormatException('"$key" must be a list of text');
  }

  static DateTime _ts(Map<String, dynamic> r, String key) =>
      DateTime.parse(_str(r, key)).toUtc();

  static DateTime? _tsOrNull(Map<String, dynamic> r, String key) {
    final v = _strOrNull(r, key);
    return v == null ? null : DateTime.parse(v).toUtc();
  }
}
