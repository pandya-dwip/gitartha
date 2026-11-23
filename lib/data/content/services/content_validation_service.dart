import '../content_constants.dart';
import '../models/source_content_model.dart';
import '../parsers/chapter_json_parser.dart';
import '../parsers/source_json_parser.dart';
import '../validators/chapter_validator.dart';
import '../validators/json_schema_validator.dart';
import '../validators/shloka_validator.dart';
import '../validators/source_validator.dart';
import '../validators/validation_result.dart';
import 'content_asset_loader.dart';

/// Runs the whole validation pipeline over a [ContentSource]:
///
/// load → JSON → JSON Schema → typed model → semantic checks → completeness.
///
/// Read-only and independent of the database. It never modifies files. The
/// returned report carries the parsed models, so the importer does not parse
/// or validate a second time.
class ContentValidationService {
  ContentValidationService(
    this.source, {
    this.chapterValidator = const ChapterValidator(),
    this.shlokaValidator = const ShlokaValidator(),
    this.sourceValidator = const SourceValidator(),
  });

  final ContentSource source;
  final ChapterValidator chapterValidator;
  final ShlokaValidator shlokaValidator;
  final SourceValidator sourceValidator;

  /// Validates [chapterIds] (default: all 18) and `sources.json` in [mode].
  Future<ContentValidationReport> validate({
    ValidationMode mode = ValidationMode.draft,
    Iterable<int>? chapterIds,
  }) async {
    final loader = ContentAssetLoader(source);
    final issues = <ValidationIssue>[];

    // Schemas. Without them nothing else can be judged.
    final JsonSchemaValidator chapterSchema;
    final JsonSchemaValidator sourcesSchema;
    try {
      chapterSchema = JsonSchemaValidator.fromSchemaText(
        await loader.loadSchema(GitaContent.chapterSchemaFileName),
        schemaName: GitaContent.chapterSchemaFileName,
      );
      sourcesSchema = JsonSchemaValidator.fromSchemaText(
        await loader.loadSchema(GitaContent.sourcesSchemaFileName),
        schemaName: GitaContent.sourcesSchemaFileName,
      );
    } on Object catch (e) {
      issues.add(
        _repositoryIssue(
          e is ContentLoadException ? e.fileName : 'schema',
          ValidationCode.assetLoadFailed,
          'Cannot load the JSON Schemas: $e',
        ),
      );
      return _report(mode, issues, const [], const {}, false, totalFiles: 0);
    }

    // Sources.
    var sourcesUsable = false;
    var sourcesById = <String, SourceContentModel>{};
    try {
      final file = await loader.loadSources();
      final parsed = SourceJsonParser(
        sourcesSchema,
      ).parse(file.text, fileName: file.fileName);
      issues.addAll(parsed.issues);
      if (parsed.value case final model?) {
        final outcome = sourceValidator.validate(
          fileName: file.fileName,
          model: model,
          mode: mode,
        );
        issues.addAll(outcome.issues);
        sourcesById = outcome.sourcesById;
        sourcesUsable = true;
      }
    } on ContentLoadException catch (e) {
      issues.add(
        _repositoryIssue(e.fileName, ValidationCode.assetLoadFailed, e.message),
      );
    }
    if (!sourcesUsable) {
      issues.add(
        const ValidationIssue(
          fileName: GitaContent.sourcesFileName,
          jsonPath: r'$',
          severity: ValidationSeverity.warning,
          code: ValidationCode.sourcesUnavailable,
          message:
              'sources.json could not be used, so verse source_id '
              'references were not checked.',
          scope: IssueScope.repository,
        ),
      );
    }

    // Chapter files.
    final load = await loader.loadChapters(chapterIds: chapterIds);
    for (final name in load.missing) {
      issues.add(
        _repositoryIssue(
          name,
          ValidationCode.missingFile,
          'Chapter file not found in ${source.description}.',
        ),
      );
    }
    for (final failure in load.failures) {
      issues.add(
        _repositoryIssue(
          failure.fileName,
          ValidationCode.assetLoadFailed,
          failure.message,
        ),
      );
    }
    for (final name in load.unexpected) {
      issues.add(
        _repositoryIssue(
          name,
          ValidationCode.unexpectedFile,
          'Only chapter_01.json … chapter_18.json belong in chapters/.',
        ),
      );
    }

    final parser = ChapterJsonParser(chapterSchema);
    final seenChapterIds = <int, String>{};
    final seenShlokaIds = <String>{};
    final chapters = <ChapterValidation>[];
    for (final file in load.files) {
      final expectedId = GitaContent.chapterIdFromFileName(file.fileName)!;
      final fileIssues = <ValidationIssue>[];
      final parsed = parser.parse(file.text, fileName: file.fileName);
      fileIssues.addAll(parsed.issues);
      final model = parsed.value;
      var assessments = const <VerseAssessment>[];

      if (model != null) {
        fileIssues.addAll(
          chapterValidator.validate(
            fileName: file.fileName,
            expectedChapterId: expectedId,
            model: model,
            mode: mode,
          ),
        );
        final previous = seenChapterIds[model.chapter.id];
        if (previous != null) {
          fileIssues.add(
            ValidationIssue(
              fileName: file.fileName,
              jsonPath: r'$.chapter.id',
              severity: ValidationSeverity.error,
              code: ValidationCode.duplicateChapterId,
              message:
                  'Chapter id ${model.chapter.id} is also used by '
                  '$previous.',
            ),
          );
        } else {
          seenChapterIds[model.chapter.id] = file.fileName;
        }
        final verseOutcome = shlokaValidator.validate(
          fileName: file.fileName,
          chapterId: model.chapter.id,
          verses: model.verses,
          sources: sourcesUsable ? sourcesById : null,
          mode: mode,
          seenShlokaIds: seenShlokaIds,
        );
        fileIssues.addAll(verseOutcome.issues);
        assessments = verseOutcome.assessments;
      }

      issues.addAll(fileIssues);
      bool hasError(IssueScope scope) =>
          fileIssues.any((i) => i.isError && i.scope == scope);
      chapters.add(
        ChapterValidation(
          fileName: file.fileName,
          expectedChapterId: expectedId,
          model: model,
          fileHasErrors: model == null || hasError(IssueScope.file),
          metadataHasErrors: hasError(IssueScope.chapterMetadata),
          verses: assessments,
        ),
      );
    }

    return _report(
      mode,
      issues,
      chapters,
      sourcesById,
      sourcesUsable,
      totalFiles:
          load.files.length + load.missing.length + load.failures.length + 1,
    );
  }

  ContentValidationReport _report(
    ValidationMode mode,
    List<ValidationIssue> issues,
    List<ChapterValidation> chapters,
    Map<String, SourceContentModel> sources,
    bool sourcesUsable, {
    required int totalFiles,
  }) {
    final filesWithErrors = {
      for (final i in issues)
        if (i.isError) i.fileName,
    };
    final verses = [for (final c in chapters) ...c.verses];
    final result = ValidationResult(
      mode: mode,
      sourceDescription: source.description,
      totalFiles: totalFiles,
      validFiles: (totalFiles - filesWithErrors.length).clamp(0, totalFiles),
      totalChapters: chapters.where((c) => c.model != null).length,
      totalVerses: verses.length,
      completeVerses: verses.where((v) => v.isComplete).length,
      approvedVerses: verses.where((v) => v.isApproved).length,
      publicationReadyChapters: chapters
          .where((c) => c.isPublicationReady)
          .length,
      issues: issues,
    );
    return ContentValidationReport(
      result: result,
      chapters: chapters,
      sources: sources,
      sourcesUsable: sourcesUsable,
    );
  }

  ValidationIssue _repositoryIssue(
    String fileName,
    String code,
    String message,
  ) => ValidationIssue(
    fileName: fileName,
    jsonPath: r'$',
    severity: ValidationSeverity.error,
    code: code,
    message: message,
    scope: IssueScope.repository,
  );
}
