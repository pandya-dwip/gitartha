import '../content_constants.dart';
import '../models/content_enums.dart';
import '../models/shloka_content_model.dart';
import '../models/source_content_model.dart';
import 'text_hygiene.dart';
import 'validation_result.dart';

/// Issues and verdicts for the verses of one chapter file.
class ShlokaValidationOutcome {
  const ShlokaValidationOutcome(this.issues, this.assessments);

  final List<ValidationIssue> issues;

  /// One per verse, in file order.
  final List<VerseAssessment> assessments;
}

/// Level 2 checks for verses: identity, uniqueness, ordering, attribution
/// references, completeness and review status.
///
/// Formats (id pattern, reference pattern, positive verse number, allowed
/// `content_section` values, no duplicate attribution entries) are enforced
/// by the JSON Schema. This checks that the values agree with each other and
/// with the rest of the repository.
class ShlokaValidator {
  const ShlokaValidator();

  /// [sources] are the valid sources by id, or null if `sources.json` could
  /// not be used (attribution references are then not checked).
  /// [seenShlokaIds] collects ids across all files, for global uniqueness.
  ShlokaValidationOutcome validate({
    required String fileName,
    required int chapterId,
    required List<ShlokaContentModel> verses,
    required Map<String, SourceContentModel>? sources,
    required ValidationMode mode,
    required Set<String> seenShlokaIds,
  }) {
    final allIssues = <ValidationIssue>[];
    final assessments = <VerseAssessment>[];
    final seenNumbers = <int>{};
    final expectedCount = GitaContent.expectedVerseCounts[chapterId];
    var previousNumber = 0;

    for (var i = 0; i < verses.length; i++) {
      final v = verses[i];
      final base = '\$.verses[$i]';
      final issues = <ValidationIssue>[];
      void add(
        String path,
        ValidationSeverity severity,
        String code,
        String message,
      ) => issues.add(
        ValidationIssue(
          fileName: fileName,
          jsonPath: path,
          severity: severity,
          code: code,
          message: '${v.reference}: $message',
          scope: IssueScope.verse,
          recordId: v.id,
        ),
      );
      const error = ValidationSeverity.error;

      // Identity and uniqueness.
      final expectedId = GitaContent.shlokaContentId(chapterId, v.verseNumber);
      if (v.id != expectedId) {
        add(
          '$base.id',
          error,
          ValidationCode.invalidShlokaId,
          'id "${v.id}" should be "$expectedId" (chapter_NN_verse_NNN).',
        );
      }
      final expectedRef = GitaContent.reference(chapterId, v.verseNumber);
      if (v.reference != expectedRef) {
        add(
          '$base.reference',
          error,
          ValidationCode.invalidReference,
          'reference should be "$expectedRef" (chapter $chapterId, verse '
              '${v.verseNumber}).',
        );
      }
      if (!seenNumbers.add(v.verseNumber)) {
        add(
          '$base.verse_number',
          error,
          ValidationCode.duplicateVerseNumber,
          'verse_number ${v.verseNumber} appears more than once in this chapter.',
        );
      }
      if (!seenShlokaIds.add(v.id)) {
        add(
          '$base.id',
          error,
          ValidationCode.duplicateShlokaId,
          'id "${v.id}" is used by more than one verse.',
        );
      }
      if (v.verseNumber <= previousNumber) {
        add(
          '$base.verse_number',
          error,
          ValidationCode.versesOutOfOrder,
          'verses must be in ascending verse_number order.',
        );
      }
      previousNumber = v.verseNumber;
      if (expectedCount != null && v.verseNumber > expectedCount) {
        add(
          '$base.verse_number',
          ValidationSeverity.warning,
          ValidationCode.verseNumberExceedsExpected,
          'verse ${v.verseNumber} exceeds the $expectedCount verses expected '
              'for chapter $chapterId in the 700-verse numbering. Check the '
              'chosen edition.',
        );
      }

      // Attributions.
      final attributed = <ContentSection>{};
      for (var a = 0; a < v.sourceAttributions.length; a++) {
        final attribution = v.sourceAttributions[a];
        final path = '$base.source_attributions[$a]';
        attributed.add(attribution.contentSection);
        if (sources != null && !sources.containsKey(attribution.sourceId)) {
          add(
            '$path.source_id',
            error,
            ValidationCode.unknownSourceId,
            'source "${attribution.sourceId}" is not in sources.json.',
          );
        }
        if (v.textOf(attribution.contentSection) == null) {
          add(
            '$path.content_section',
            error,
            ValidationCode.attributionForEmptySection,
            'attribution for "${attribution.contentSection.jsonValue}", which '
                'is empty.',
          );
        }
      }

      // Completeness and review status (content guidelines §12).
      final missing = v.missingRequiredFields;
      final status = v.reviewStatus;
      final checkClaims = mode != ValidationMode.structural;
      if (missing.isNotEmpty) {
        if (status == ReviewStatus.approved && checkClaims) {
          add(
            base,
            error,
            ValidationCode.incompleteContent,
            '"approved" but empty: ${missing.join(', ')}.',
          );
        } else if (completenessSeverity(mode) case final severity?) {
          add(
            base,
            severity,
            ValidationCode.incompleteContent,
            '${status == ReviewStatus.inReview ? '"in_review" but ' : ''}'
            'incomplete; empty: ${missing.join(', ')}.',
          );
        }
      }
      if (status == ReviewStatus.approved && checkClaims) {
        final unsourced = ShlokaContentModel.sectionsRequiringAttribution
            .where((s) => !attributed.contains(s))
            .map((s) => s.jsonValue)
            .toList();
        if (unsourced.isNotEmpty) {
          add(
            '$base.source_attributions',
            error,
            ValidationCode.missingAttribution,
            '"approved" but no source attribution for: ${unsourced.join(', ')}.',
          );
        }
        if (sources != null) {
          for (final attribution in v.sourceAttributions) {
            final source = sources[attribution.sourceId];
            if (source != null && !source.hasVerifiedLicense) {
              add(
                '$base.source_attributions',
                error,
                ValidationCode.unverifiedSourceLicense,
                '"approved" but source "${source.id}" has no verified licence.',
              );
            }
          }
        }
      }
      if (mode == ValidationMode.strict && status != ReviewStatus.approved) {
        add(
          '$base.review_status',
          error,
          ValidationCode.notApproved,
          'review_status is "${status.jsonValue}", not "approved".',
        );
      }

      issues.addAll(
        textHygieneIssues(
          fileName: fileName,
          basePath: base,
          fields: v.textFields,
          scope: IssueScope.verse,
          recordId: v.id,
        ),
      );

      allIssues.addAll(issues);
      assessments.add(
        VerseAssessment(
          contentId: v.id,
          verseNumber: v.verseNumber,
          reviewStatus: status,
          missingFields: missing,
          hasErrors: issues.any((i) => i.isError),
        ),
      );
    }
    return ShlokaValidationOutcome(allIssues, assessments);
  }
}
