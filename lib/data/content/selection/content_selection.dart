import '../importers/import_result.dart';
import '../models/chapter_content_model.dart';
import '../models/content_enums.dart';
import '../models/shloka_content_model.dart';
import '../models/source_content_model.dart';
import '../validators/validation_result.dart';

/// A verse chosen for writing, with its validation verdict.
class SelectedVerse {
  const SelectedVerse(this.verse, this.assessment);

  final ShlokaContentModel verse;
  final VerseAssessment assessment;
}

/// A chapter chosen for writing.
class SelectedChapter {
  const SelectedChapter({
    required this.validation,
    required this.includeDescriptions,
    required this.verses,
  });

  final ChapterValidation validation;

  /// Whether the descriptive metadata may be written (draft: always;
  /// approved: only when the metadata itself is approved and complete).
  final bool includeDescriptions;

  /// The chapter's eligible verses, in file order.
  final List<SelectedVerse> verses;

  ChapterContentModel get model => validation.model!;
  ChapterMetadataModel get chapter => model.chapter;
  String get fileName => validation.fileName;
}

/// What may be written to a database (local cache or Supabase), decided
/// purely from validation. Database-specific checks (server rows,
/// conflicts) come later, in the importer or the publishing planner.
class ContentSelection {
  const ContentSelection({
    required this.mode,
    required this.chapters,
    required this.sources,
    required this.rejected,
    required this.rejectedChapters,
    required this.rejectedVerses,
    required this.rejectedSources,
    required this.sourcesUsable,
  });

  final ImportMode mode;
  final List<SelectedChapter> chapters;

  /// Sources that may be written (draft: all valid; approved: licensed).
  final List<SourceContentModel> sources;

  /// Why records were left out.
  final List<SkippedRecord> rejected;
  final int rejectedChapters;
  final int rejectedVerses;
  final int rejectedSources;

  /// False if `sources.json` was unusable (attributions can't be written).
  final bool sourcesUsable;

  Set<String> get sourceKeys => {for (final s in sources) s.id};
}

/// The single definition of "eligible content", shared by the local import
/// (Milestone 3) and the Supabase publisher (Milestone 3.1).
///
/// | Record  | draft                     | approved                                                |
/// |---------|---------------------------|---------------------------------------------------------|
/// | chapter | file usable               | file usable **and** all three names present             |
/// | details | always                    | metadata `approved` and complete                        |
/// | verse   | no errors                 | complete, `approved`, sourced, error-free (strict)      |
/// | source  | every valid source        | only sources with a verified licence                    |
class ContentSelector {
  const ContentSelector();

  /// Selects from [report], which must come from validation in
  /// `mode.validationMode`. [chapterIds] limits the chapters; [verseNumber]
  /// (with a single chapter) limits the verses. Records outside the scope
  /// are neither selected nor reported as rejected.
  ContentSelection select(
    ContentValidationReport report, {
    required ImportMode mode,
    Set<int>? chapterIds,
    int? verseNumber,
  }) {
    final rejected = <SkippedRecord>[];
    final chapters = <SelectedChapter>[];
    var rejectedChapters = 0;
    var rejectedVerses = 0;

    for (final validation in report.chapters) {
      if (chapterIds != null &&
          !chapterIds.contains(validation.expectedChapterId)) {
        continue;
      }
      final model = validation.model;
      final inScope = [
        for (var i = 0; i < (model?.verses.length ?? 0); i++)
          if (verseNumber == null ||
              model!.verses[i].verseNumber == verseNumber)
            i,
      ];

      if (!validation.isUsable) {
        rejectedChapters++;
        rejectedVerses += inScope.length;
        rejected.add(
          SkippedRecord(
            recordType: 'chapter',
            recordId: '${validation.expectedChapterId}',
            fileName: validation.fileName,
            reason: ImportSkipReason.fileInvalid,
            message:
                'The file failed validation and was not used. See the '
                'validation errors.',
          ),
        );
        continue;
      }
      final chapter = model!.chapter;
      if (mode == ImportMode.approved && !chapter.hasAllNames) {
        rejectedChapters++;
        rejectedVerses += inScope.length;
        rejected.add(
          SkippedRecord(
            recordType: 'chapter',
            recordId: '${chapter.id}',
            fileName: validation.fileName,
            reason: ImportSkipReason.chapterNamesMissing,
            message:
                'Chapter ${chapter.id} has no names yet, so neither it '
                'nor its ${inScope.length} verse(s) can be written.',
          ),
        );
        continue;
      }

      final verses = <SelectedVerse>[];
      for (final i in inScope) {
        final verse = model.verses[i];
        final assessment = validation.verses[i];
        final eligible = switch (mode) {
          ImportMode.draft => !assessment.hasErrors,
          ImportMode.approved => assessment.isApproved,
        };
        if (eligible) {
          verses.add(SelectedVerse(verse, assessment));
        } else {
          rejectedVerses++;
          rejected.add(
            SkippedRecord(
              recordType: 'shloka',
              recordId: verse.id,
              fileName: validation.fileName,
              reason: ImportSkipReason.validationFailed,
              message: mode == ImportMode.approved
                  ? '${verse.reference} is not eligible (complete: '
                        '${assessment.isComplete}, status: '
                        '${assessment.reviewStatus.jsonValue}, errors: '
                        '${assessment.hasErrors}).'
                  : '${verse.reference} has validation errors.',
            ),
          );
        }
      }

      chapters.add(
        SelectedChapter(
          validation: validation,
          includeDescriptions: switch (mode) {
            ImportMode.draft => true,
            // Missing verses don't affect the metadata's own approval.
            ImportMode.approved =>
              chapter.reviewStatus == ReviewStatus.approved &&
                  chapter.isComplete,
          },
          verses: verses,
        ),
      );
    }

    final sources = <SourceContentModel>[];
    var rejectedSources = 0;
    if (report.sourcesUsable) {
      for (final source in report.sources.values) {
        if (mode == ImportMode.approved && !source.hasVerifiedLicense) {
          rejectedSources++;
          rejected.add(
            SkippedRecord(
              recordType: 'source',
              recordId: source.id,
              fileName: 'sources.json',
              reason: ImportSkipReason.unverifiedSource,
              message: 'Source "${source.id}" has no verified licence.',
            ),
          );
        } else {
          sources.add(source);
        }
      }
    }

    return ContentSelection(
      mode: mode,
      chapters: chapters,
      sources: sources,
      rejected: rejected,
      rejectedChapters: rejectedChapters,
      rejectedVerses: rejectedVerses,
      rejectedSources: rejectedSources,
      sourcesUsable: report.sourcesUsable,
    );
  }
}
