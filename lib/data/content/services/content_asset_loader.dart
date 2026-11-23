import '../content_constants.dart';

/// Where the content repository is read from. The pipeline only ever reads.
///
/// Implementations:
///  * `AssetBundleContentSource`: the bundled Flutter assets (app, widget
///    tests);
///  * `FileSystemContentSource`: the files on disk (`dart run` CLI, tests);
///  * in tests, in-memory fixtures.
///
/// This interface and everything in the validation pipeline are pure Dart,
/// so the CLI can run them without Flutter.
abstract interface class ContentSource {
  /// Human-readable location, for reports.
  String get description;

  /// File names present in `chapters/`, e.g. `chapter_01.json`.
  Future<List<String>> listChapterFiles();

  /// Raw text of `chapters/<fileName>`. Throws [ContentLoadException].
  Future<String> readChapterFile(String fileName);

  /// Raw text of `sources/sources.json`. Throws [ContentLoadException].
  Future<String> readSourcesFile();

  /// Raw text of `schema/<fileName>`. Throws [ContentLoadException].
  Future<String> readSchemaFile(String fileName);
}

/// A content file could not be found or read.
class ContentLoadException implements Exception {
  const ContentLoadException(this.fileName, this.message, {this.cause});

  final String fileName;
  final String message;
  final Object? cause;

  @override
  String toString() =>
      'ContentLoadException($fileName): $message'
      '${cause == null ? '' : ' (cause: $cause)'}';
}

/// One loaded file.
class LoadedContentFile {
  const LoadedContentFile(this.fileName, this.text);

  final String fileName;
  final String text;
}

/// Result of loading all chapter files: what loaded, what is missing, what
/// failed, and what does not belong.
class ChapterFilesLoadResult {
  const ChapterFilesLoadResult({
    required this.files,
    required this.missing,
    required this.failures,
    required this.unexpected,
  });

  /// Loaded files, in chapter order.
  final List<LoadedContentFile> files;

  /// Expected file names that do not exist.
  final List<String> missing;

  /// Files that exist but could not be read.
  final List<ContentLoadException> failures;

  /// Files in `chapters/` that are not `chapter_01.json` … `chapter_18.json`.
  final List<String> unexpected;

  bool get isComplete => missing.isEmpty && failures.isEmpty;
}

/// Loads chapter files, the sources file and the schemas from a
/// [ContentSource], reporting missing files clearly.
class ContentAssetLoader {
  const ContentAssetLoader(this.source);

  final ContentSource source;

  /// Loads one chapter file. Throws [ContentLoadException] if it is missing
  /// or unreadable.
  Future<LoadedContentFile> loadChapter(int chapterId) async {
    if (chapterId < 1 || chapterId > GitaContent.chapterCount) {
      throw ContentLoadException(
        'chapter $chapterId',
        'chapter numbers run from 1 to ${GitaContent.chapterCount}',
      );
    }
    final fileName = GitaContent.chapterFileName(chapterId);
    final available = await source.listChapterFiles();
    if (!available.contains(fileName)) {
      throw ContentLoadException(
        fileName,
        'file not found in ${source.description}',
      );
    }
    return LoadedContentFile(fileName, await source.readChapterFile(fileName));
  }

  /// Loads the given chapters (default: all 18). Missing and unreadable
  /// files are reported in the result, not thrown.
  Future<ChapterFilesLoadResult> loadChapters({
    Iterable<int>? chapterIds,
  }) async {
    final ids =
        (chapterIds ?? [for (var n = 1; n <= GitaContent.chapterCount; n++) n])
            .toSet()
            .toList()
          ..sort();
    final available = (await source.listChapterFiles()).toSet();
    final files = <LoadedContentFile>[];
    final missing = <String>[];
    final failures = <ContentLoadException>[];
    for (final id in ids) {
      final fileName = GitaContent.chapterFileName(id);
      if (!available.contains(fileName)) {
        missing.add(fileName);
        continue;
      }
      try {
        files.add(
          LoadedContentFile(fileName, await source.readChapterFile(fileName)),
        );
      } on ContentLoadException catch (e) {
        failures.add(e);
      }
    }
    final unexpected = chapterIds == null
        ? (available
              .where((f) => GitaContent.chapterIdFromFileName(f) == null)
              .toList()
            ..sort())
        : <String>[];
    return ChapterFilesLoadResult(
      files: files,
      missing: missing,
      failures: failures,
      unexpected: unexpected,
    );
  }

  /// Loads `sources/sources.json`. Throws [ContentLoadException].
  Future<LoadedContentFile> loadSources() async => LoadedContentFile(
    GitaContent.sourcesFileName,
    await source.readSourcesFile(),
  );

  /// Loads a schema file. Throws [ContentLoadException].
  Future<String> loadSchema(String fileName) => source.readSchemaFile(fileName);
}
