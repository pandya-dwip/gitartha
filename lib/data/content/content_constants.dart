/// Fixed facts about the Bhagavad Gita content repository
/// (`assets/data/bhagavad_gita/`). Pure Dart: shared by the app, the tests
/// and the `tool/validate_gita_content.dart` CLI.
abstract final class GitaContent {
  /// Repository root, relative to the project root and as an asset key prefix.
  static const String rootPath = 'assets/data/bhagavad_gita';

  static const String chaptersDir = 'chapters';
  static const String sourcesFileName = 'sources.json';
  static const String sourcesPath = 'sources/$sourcesFileName';
  static const String chapterSchemaFileName = 'chapter.schema.json';
  static const String sourcesSchemaFileName = 'sources.schema.json';

  static const int chapterCount = 18;

  /// `chapter_01.json` … `chapter_18.json`.
  static String chapterFileName(int chapterId) =>
      'chapter_${chapterId.toString().padLeft(2, '0')}.json';

  static final RegExp chapterFileNamePattern = RegExp(
    r'^chapter_(0[1-9]|1[0-8])\.json$',
  );

  /// The chapter number implied by [fileName], or null if it does not
  /// follow the naming convention.
  static int? chapterIdFromFileName(String fileName) {
    final match = chapterFileNamePattern.firstMatch(fileName);
    return match == null ? null : int.parse(match.group(1)!);
  }

  /// The stable content id of a verse, e.g. `chapter_01_verse_041`.
  static String shlokaContentId(int chapterId, int verseNumber) =>
      'chapter_${chapterId.toString().padLeft(2, '0')}_verse_'
      '${verseNumber.toString().padLeft(3, '0')}';

  /// `"<chapter>.<verse>"`, e.g. `1.41`.
  static String reference(int chapterId, int verseNumber) =>
      '$chapterId.$verseNumber';

  /// Verse counts in the widely used 700-verse numbering (Chapter 13 = 34).
  /// Confirm against the edition chosen for Gitartha (see the content
  /// README) before relying on them for publication decisions.
  static const Map<int, int> expectedVerseCounts = {
    1: 47, 2: 72, 3: 43, 4: 42, 5: 29, 6: 47, 7: 30, 8: 28, 9: 34, //
    10: 42, 11: 55, 12: 20, 13: 34, 14: 27, 15: 20, 16: 24, 17: 28, 18: 78,
  };

  static int get expectedTotalVerses =>
      expectedVerseCounts.values.fold(0, (a, b) => a + b);
}
