import '../content_constants.dart';
import '../models/chapter_content_model.dart';
import '../models/content_enums.dart';
import 'text_hygiene.dart';
import 'validation_result.dart';

/// Level 2 checks for a chapter file's identity and metadata.
///
/// Range and type checks (id 1–18, `key_topics` is an array of non-empty
/// strings) are done by the JSON Schema. This adds what the schema cannot
/// express. Duplicate chapter ids across files are checked by
/// `ContentValidationService`, which sees every file.
class ChapterValidator {
  const ChapterValidator();

  List<ValidationIssue> validate({
    required String fileName,
    required int expectedChapterId,
    required ChapterContentModel model,
    required ValidationMode mode,
  }) {
    final chapter = model.chapter;
    final issues = <ValidationIssue>[];
    ValidationIssue issue(
      String path,
      ValidationSeverity severity,
      String code,
      String message, {
      IssueScope scope = IssueScope.chapterMetadata,
    }) => ValidationIssue(
      fileName: fileName,
      jsonPath: path,
      severity: severity,
      code: code,
      message: message,
      scope: scope,
    );

    if (chapter.id != expectedChapterId) {
      issues.add(
        issue(
          r'$.chapter.id',
          ValidationSeverity.error,
          ValidationCode.chapterIdFilenameMismatch,
          'chapter.id is ${chapter.id}, but the file name says chapter '
              '$expectedChapterId.',
          scope: IssueScope.file,
        ),
      );
    }

    // Completeness and review status of the metadata (guidelines §12).
    final missing = chapter.missingRequiredFields;
    final severity = completenessSeverity(mode);
    if (missing.isNotEmpty) {
      if (chapter.reviewStatus == ReviewStatus.approved &&
          mode != ValidationMode.structural) {
        issues.add(
          issue(
            r'$.chapter',
            ValidationSeverity.error,
            ValidationCode.incompleteContent,
            'Chapter is "approved" but these fields are empty: '
                '${missing.join(', ')}.',
          ),
        );
      } else if (severity != null) {
        issues.add(
          issue(
            r'$.chapter',
            severity,
            ValidationCode.incompleteContent,
            'Chapter metadata is incomplete; empty: ${missing.join(', ')}.',
          ),
        );
      }
    }
    if (mode == ValidationMode.strict &&
        chapter.reviewStatus != ReviewStatus.approved) {
      issues.add(
        issue(
          r'$.chapter.review_status',
          ValidationSeverity.error,
          ValidationCode.notApproved,
          'Chapter metadata is "${chapter.reviewStatus.jsonValue}", not '
              '"approved".',
        ),
      );
    }

    // Verse coverage.
    final expected = GitaContent.expectedVerseCounts[expectedChapterId];
    if (expected != null) {
      final present = {for (final v in model.verses) v.verseNumber};
      final missingCount = [
        for (var n = 1; n <= expected; n++)
          if (!present.contains(n)) n,
      ].length;
      if (missingCount > 0) {
        issues.add(
          issue(
            r'$.verses',
            mode == ValidationMode.strict
                ? ValidationSeverity.error
                : ValidationSeverity.info,
            ValidationCode.missingVerses,
            model.verses.isEmpty
                ? 'No verses yet (0 of $expected).'
                : '$missingCount of $expected verses are not in the file yet.',
          ),
        );
      }
    }

    issues.addAll(
      textHygieneIssues(
        fileName: fileName,
        basePath: r'$.chapter',
        fields: {
          'sanskrit_name': chapter.sanskritName,
          'hindi_name': chapter.hindiName,
          'english_name': chapter.englishName,
          'introduction': chapter.introduction,
          'overview': chapter.overview,
          'central_theme': chapter.centralTheme,
          'summary': chapter.summary,
          'conclusion': chapter.conclusion,
        },
        scope: IssueScope.chapterMetadata,
      ),
    );
    return issues;
  }
}
