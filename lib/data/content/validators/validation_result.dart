import '../content_constants.dart';
import '../models/chapter_content_model.dart';
import '../models/content_enums.dart';
import '../models/source_content_model.dart';

/// How strictly the content is judged. Derived from the content guidelines
/// (§12) and the JSON Schema. See docs/content/CONTENT_VALIDATION.md.
enum ValidationMode {
  /// Schema, identifiers, references and consistency only. Completeness is
  /// counted but not reported per record.
  structural,

  /// [structural], plus incomplete content reported as warnings. Status
  /// claims are checked: an `approved` verse must really be complete and
  /// sourced. The default for authoring.
  draft,

  /// For publishing and approved import. Every chapter's metadata and every
  /// verse must be complete **and** `approved`, with required attributions
  /// to sources with a verified licence. Chapters must contain all their
  /// verses. Shortfalls are errors.
  strict;

  static ValidationMode parse(String value) => ValidationMode.values.firstWhere(
    (m) => m.name == value,
    orElse: () => throw FormatException(
      'Unknown validation mode "$value" (use structural, draft or strict)',
    ),
  );
}

enum ValidationSeverity { error, warning, info }

/// Stable issue codes. Never rename one: tools and docs refer to them.
abstract final class ValidationCode {
  // Files and loading
  static const String missingFile = 'MISSING_FILE';
  static const String unexpectedFile = 'UNEXPECTED_FILE';
  static const String assetLoadFailed = 'ASSET_LOAD_FAILED';
  static const String invalidEncoding = 'INVALID_ENCODING';
  static const String invalidJson = 'INVALID_JSON';
  static const String schemaValidationFailed = 'SCHEMA_VALIDATION_FAILED';
  static const String parseFailed = 'PARSE_FAILED';
  static const String sourcesUnavailable = 'SOURCES_UNAVAILABLE';

  // Chapters
  static const String invalidChapterId = 'INVALID_CHAPTER_ID';
  static const String chapterIdFilenameMismatch =
      'CHAPTER_ID_FILENAME_MISMATCH';
  static const String duplicateChapterId = 'DUPLICATE_CHAPTER_ID';
  static const String missingVerses = 'MISSING_VERSES';

  // Verses
  static const String invalidVerseNumber = 'INVALID_VERSE_NUMBER';
  static const String duplicateVerseNumber = 'DUPLICATE_VERSE_NUMBER';
  static const String versesOutOfOrder = 'VERSES_OUT_OF_ORDER';
  static const String verseNumberExceedsExpected =
      'VERSE_NUMBER_EXCEEDS_EXPECTED';
  static const String invalidReference = 'INVALID_REFERENCE';
  static const String invalidShlokaId = 'INVALID_SHLOKA_ID';
  static const String duplicateShlokaId = 'DUPLICATE_SHLOKA_ID';

  // Sources and attributions
  static const String duplicateSourceId = 'DUPLICATE_SOURCE_ID';
  static const String missingSourceName = 'MISSING_SOURCE_NAME';
  static const String unknownSourceId = 'UNKNOWN_SOURCE_ID';
  static const String invalidContentSection = 'INVALID_CONTENT_SECTION';
  static const String duplicateAttribution = 'DUPLICATE_ATTRIBUTION';
  static const String attributionForEmptySection =
      'ATTRIBUTION_FOR_EMPTY_SECTION';
  static const String missingAttribution = 'MISSING_ATTRIBUTION';
  static const String unverifiedSourceLicense = 'UNVERIFIED_SOURCE_LICENSE';

  // Completeness and review
  static const String incompleteContent = 'INCOMPLETE_CONTENT';
  static const String notApproved = 'NOT_APPROVED';

  // Text hygiene
  static const String placeholderText = 'PLACEHOLDER_TEXT';
  static const String carriageReturn = 'CARRIAGE_RETURN';
}

/// What an issue is about. It decides how much an error blocks at import:
/// a [file] error blocks the whole file, a [chapterMetadata] error only the
/// chapter's descriptive fields, a [verse] error only that verse.
enum IssueScope { repository, file, chapterMetadata, verse, source }

class ValidationIssue {
  const ValidationIssue({
    required this.fileName,
    required this.jsonPath,
    required this.severity,
    required this.code,
    required this.message,
    this.scope = IssueScope.file,
    this.recordId,
  });

  final String fileName;

  /// JSONPath-style location, e.g. `$.verses[0].hindi_meaning`.
  final String jsonPath;
  final ValidationSeverity severity;
  final String code;
  final String message;
  final IssueScope scope;

  /// Verse content id or source id this issue belongs to, when relevant.
  final String? recordId;

  bool get isError => severity == ValidationSeverity.error;

  Map<String, Object?> toJson() => {
    'fileName': fileName,
    'jsonPath': jsonPath,
    'severity': severity.name,
    'code': code,
    'message': message,
    'scope': scope.name,
    if (recordId != null) 'recordId': recordId,
  };

  @override
  String toString() =>
      '${severity.name.toUpperCase()} $code $fileName $jsonPath: $message';
}

/// The validation verdict for one verse.
class VerseAssessment {
  const VerseAssessment({
    required this.contentId,
    required this.verseNumber,
    required this.reviewStatus,
    required this.missingFields,
    required this.hasErrors,
  });

  final String contentId;
  final int verseNumber;
  final ReviewStatus reviewStatus;
  final List<String> missingFields;

  /// Whether any error (in the validation mode used) concerns this verse.
  final bool hasErrors;

  bool get isComplete => missingFields.isEmpty;

  /// Complete, approved and error-free: eligible for approved import.
  bool get isApproved =>
      isComplete && reviewStatus == ReviewStatus.approved && !hasErrors;
}

/// The validation verdict for one chapter file.
class ChapterValidation {
  const ChapterValidation({
    required this.fileName,
    required this.expectedChapterId,
    required this.model,
    required this.fileHasErrors,
    required this.metadataHasErrors,
    required this.verses,
  });

  final String fileName;

  /// The chapter number implied by the file name.
  final int expectedChapterId;

  /// The parsed content, or null if the file could not be read, decoded,
  /// schema-validated or parsed.
  final ChapterContentModel? model;

  /// Errors that make the whole file unusable (structure, identity).
  final bool fileHasErrors;

  /// Errors about the chapter metadata only.
  final bool metadataHasErrors;

  final List<VerseAssessment> verses;

  bool get isUsable => model != null && !fileHasErrors;

  /// Metadata complete and approved, and every expected verse present and
  /// approved.
  bool get isPublicationReady {
    final m = model;
    if (m == null || fileHasErrors || metadataHasErrors) return false;
    final count = GitaContent.expectedVerseCounts[m.chapter.id];
    final approvedNumbers = {
      for (final v in verses)
        if (v.isApproved) v.verseNumber,
    };
    return m.chapter.isComplete &&
        m.chapter.reviewStatus == ReviewStatus.approved &&
        count != null &&
        approvedNumbers.length == count &&
        approvedNumbers.every((n) => n >= 1 && n <= count);
  }
}

/// Everything a validation run found.
class ValidationResult {
  ValidationResult({
    required this.mode,
    required this.sourceDescription,
    required this.totalFiles,
    required this.validFiles,
    required this.totalChapters,
    required this.totalVerses,
    required this.completeVerses,
    required this.approvedVerses,
    required this.publicationReadyChapters,
    required List<ValidationIssue> issues,
  }) : issues = List.unmodifiable(issues);

  final ValidationMode mode;
  final String sourceDescription;

  /// Chapter files plus the sources file.
  final int totalFiles;
  final int validFiles;
  final int totalChapters;
  final int totalVerses;
  final int completeVerses;
  final int approvedVerses;
  final int publicationReadyChapters;
  final List<ValidationIssue> issues;

  int get invalidFiles => totalFiles - validFiles;
  int get incompleteVerses => totalVerses - completeVerses;

  List<ValidationIssue> get errors =>
      issues.where((i) => i.severity == ValidationSeverity.error).toList();
  List<ValidationIssue> get warnings =>
      issues.where((i) => i.severity == ValidationSeverity.warning).toList();
  List<ValidationIssue> get informationalMessages =>
      issues.where((i) => i.severity == ValidationSeverity.info).toList();

  /// True when there are no errors in this [mode].
  bool get isValid => errors.isEmpty;

  Map<String, Object?> toJson() => {
    'isValid': isValid,
    'mode': mode.name,
    'source': sourceDescription,
    'totalFiles': totalFiles,
    'validFiles': validFiles,
    'invalidFiles': invalidFiles,
    'totalChapters': totalChapters,
    'totalVerses': totalVerses,
    'completeVerses': completeVerses,
    'incompleteVerses': incompleteVerses,
    'approvedVerses': approvedVerses,
    'publicationReadyChapters': publicationReadyChapters,
    'errors': [for (final i in errors) i.toJson()],
    'warnings': [for (final i in warnings) i.toJson()],
    'informationalMessages': [
      for (final i in informationalMessages) i.toJson(),
    ],
  };

  /// A readable multi-line report for the console.
  String toReport({bool includeInfo = false}) {
    final b = StringBuffer()
      ..writeln('Gitartha content validation: $sourceDescription')
      ..writeln('Mode: ${mode.name}')
      ..writeln(
        'Files: $totalFiles ($validFiles valid, $invalidFiles invalid) · '
        'chapters: $totalChapters · publication-ready: $publicationReadyChapters',
      )
      ..writeln(
        'Verses: $totalVerses of ${GitaContent.expectedTotalVerses} '
        '($completeVerses complete, $incompleteVerses incomplete, '
        '$approvedVerses approved)',
      );
    void section(String title, List<ValidationIssue> items) {
      if (items.isEmpty) return;
      b
        ..writeln()
        ..writeln('$title (${items.length}):');
      for (final i in items) {
        b
          ..writeln('  [${i.code}] ${i.fileName}  ${i.jsonPath}')
          ..writeln('      ${i.message}');
      }
    }

    if (includeInfo) section('Info', informationalMessages);
    section('Warnings', warnings);
    section('Errors', errors);
    b
      ..writeln()
      ..writeln(
        isValid
            ? 'RESULT: VALID in ${mode.name} mode '
                  '(${warnings.length} warning(s)).'
            : 'RESULT: INVALID in ${mode.name} mode — '
                  '${errors.length} error(s).',
      );
    return b.toString();
  }
}

/// A validation run's result plus the parsed content, for the importer.
class ContentValidationReport {
  const ContentValidationReport({
    required this.result,
    required this.chapters,
    required this.sources,
    required this.sourcesUsable,
  });

  final ValidationResult result;
  final List<ChapterValidation> chapters;

  /// Valid sources by id (empty if `sources.json` is unusable).
  final Map<String, SourceContentModel> sources;
  final bool sourcesUsable;
}
