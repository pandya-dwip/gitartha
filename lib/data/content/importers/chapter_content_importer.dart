import 'package:drift/drift.dart' show Value;

import '../../local/database/app_database.dart';
import '../content_ids.dart';
import '../models/chapter_content_model.dart';
import '../models/content_enums.dart';
import '../models/shloka_content_model.dart';
import '../models/source_attribution_model.dart';
import '../models/source_content_model.dart';
import '../validators/validation_result.dart';
import 'import_result.dart';

/// Timestamp written as `created_at` / `updated_at` of every row imported
/// from the content repository.
///
/// The JSON files carry no timestamps. A fixed value makes re-imports
/// idempotent (unchanged content gives identical rows), marks the row as
/// "from the repository, no server revision", and is older than any real
/// Supabase timestamp, so content pulled from the server later always
/// supersedes it under the cache's never-go-backwards rule.
final DateTime contentRepositoryTimestamp = DateTime.utc(1970);

/// Maps validated content models to local cache rows and writes one chapter
/// (its row, eligible verses and their attributions) in a single
/// transaction.
///
/// Only the four shared-content tables are touched. Personal tables are
/// never read or written here, and no row is ever deleted except stale
/// attribution mappings.
class ChapterContentImporter {
  ChapterContentImporter(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // Mapping (pure)
  // ---------------------------------------------------------------------------

  /// The `local_chapters` row for [chapter]. With [includeDescriptions]
  /// false, only the names are stored. Missing names are stored as `''`,
  /// which only a draft import does.
  static LocalChapter chapterRow(
    ChapterMetadataModel chapter, {
    required bool includeDescriptions,
  }) => LocalChapter(
    id: chapter.id,
    sanskritName: chapter.sanskritName ?? '',
    hindiName: chapter.hindiName ?? '',
    englishName: chapter.englishName ?? '',
    introduction: includeDescriptions ? chapter.introduction : null,
    overview: includeDescriptions ? chapter.overview : null,
    centralTheme: includeDescriptions ? chapter.centralTheme : null,
    keyTopics: includeDescriptions && chapter.keyTopics.isNotEmpty
        ? chapter.keyTopics
        : null,
    summary: includeDescriptions ? chapter.summary : null,
    conclusion: includeDescriptions ? chapter.conclusion : null,
    createdAt: contentRepositoryTimestamp,
    updatedAt: contentRepositoryTimestamp,
  );

  /// The `local_shlokas` row for [verse] of chapter [chapterId]. The id is
  /// the deterministic UUID of the verse's content id. Every field is
  /// copied; `hindi_meaning_note` stays separate from `hindi_meaning`.
  static LocalShloka shlokaRow(int chapterId, ShlokaContentModel verse) =>
      LocalShloka(
        id: ContentIds.shloka(verse.id),
        chapterId: chapterId,
        verseNumber: verse.verseNumber,
        reference: verse.reference,
        indexTitle: verse.indexTitle,
        indexSummary: verse.indexSummary,
        sanskritText: verse.sanskritText,
        transliteration: verse.transliteration,
        hindiMeaning: verse.hindiMeaning,
        hindiMeaningNote: verse.hindiMeaningNote,
        englishMeaning: verse.englishMeaning,
        context: verse.context,
        lifeLesson: verse.lifeLesson,
        spiritualMeaning: verse.spiritualMeaning,
        reflectionQuestion: verse.reflectionQuestion,
        createdAt: contentRepositoryTimestamp,
        updatedAt: contentRepositoryTimestamp,
      );

  /// The `local_content_sources` row for [source].
  static LocalContentSource sourceRow(SourceContentModel source) =>
      LocalContentSource(
        id: ContentIds.source(source.id),
        name: source.name,
        author: source.author,
        sourceUrl: source.sourceUrl,
        license: source.license,
        attribution: source.attribution,
        createdAt: contentRepositoryTimestamp,
        updatedAt: contentRepositoryTimestamp,
      );

  /// The `local_shloka_source_attributions` row for one attribution of
  /// [verse]. Its id is deterministic, so re-imports find the same row.
  static LocalShlokaSourceAttribution attributionRow(
    ShlokaContentModel verse,
    SourceAttributionModel attribution,
  ) => LocalShlokaSourceAttribution(
    id: ContentIds.attribution(
      verse.id,
      attribution.sourceId,
      attribution.contentSection.jsonValue,
    ),
    shlokaId: ContentIds.shloka(verse.id),
    sourceId: ContentIds.source(attribution.sourceId),
    contentSection: attribution.contentSection.jsonValue,
    createdAt: contentRepositoryTimestamp,
  );

  /// Value equality for chapter rows. Drift's generated `==` compares the
  /// `key_topics` list by identity, so two equal lists would never match.
  static bool sameChapterRow(LocalChapter a, LocalChapter b) {
    final ta = a.keyTopics;
    final tb = b.keyTopics;
    final topicsEqual = ta == null || tb == null
        ? ta == tb
        : ta.length == tb.length &&
              [
                for (var i = 0; i < ta.length; i++) ta[i] == tb[i],
              ].every((e) => e);
    return topicsEqual &&
        a.copyWith(keyTopics: const Value(null)) ==
            b.copyWith(keyTopics: const Value(null));
  }

  // ---------------------------------------------------------------------------
  // Writing
  // ---------------------------------------------------------------------------

  /// Imports one chapter in a single transaction. If anything fails, the
  /// whole chapter is rolled back and the error is rethrown. Counts are
  /// applied to [result] only after the transaction commits.
  Future<void> importChapter({
    required ChapterValidation validation,
    required ImportMode mode,
    required Set<String> importableSourceKeys,
    required bool sourcesUsable,
    required ImportResult result,
  }) async {
    final model = validation.model!;
    final chapter = model.chapter;
    final fileName = validation.fileName;
    final chapterCounts = ImportCounts();
    final verseCounts = ImportCounts();
    final skipped = <SkippedRecord>[];
    final shlokaIds = <String, String>{};
    var attributionsInserted = 0;
    var attributionsDeleted = 0;

    final includeDescriptions = switch (mode) {
      ImportMode.draft => true,
      // README import gate: descriptions only once the metadata itself is
      // approved and complete. Missing verses don't affect the metadata.
      ImportMode.approved =>
        chapter.reviewStatus == ReviewStatus.approved && chapter.isComplete,
    };

    await _db.transaction(() async {
      // Chapter row.
      final target = chapterRow(
        chapter,
        includeDescriptions: includeDescriptions,
      );
      final existing = await _db.chapterDao.getChapter(
        chapter.id,
        includeDeleted: true,
      );
      if (existing == null) {
        await _db.chapterDao.upsertChapter(target);
        chapterCounts.inserted++;
      } else if (sameChapterRow(existing, target)) {
        chapterCounts.unchanged++;
      } else if (existing.updatedAt != contentRepositoryTimestamp) {
        chapterCounts.skipped++;
        skipped.add(
          SkippedRecord(
            recordType: 'chapter',
            recordId: '${chapter.id}',
            fileName: fileName,
            reason: ImportSkipReason.serverRecordPresent,
            message:
                'The cached chapter came from the server; repository '
                'content does not overwrite it.',
          ),
        );
      } else {
        await _db.chapterDao.upsertChapter(target);
        chapterCounts.updated++;
      }

      // Verses.
      for (var i = 0; i < model.verses.length; i++) {
        final verse = model.verses[i];
        final assessment = validation.verses[i];
        final eligible = switch (mode) {
          ImportMode.draft => !assessment.hasErrors,
          ImportMode.approved => assessment.isApproved,
        };
        if (!eligible) {
          verseCounts.skipped++;
          skipped.add(
            SkippedRecord(
              recordType: 'shloka',
              recordId: verse.id,
              fileName: fileName,
              reason: ImportSkipReason.validationFailed,
              message: mode == ImportMode.approved
                  ? '${verse.reference} is not eligible for approved import '
                        '(complete: ${assessment.isComplete}, status: '
                        '${assessment.reviewStatus.jsonValue}, errors: '
                        '${assessment.hasErrors}).'
                  : '${verse.reference} has validation errors.',
            ),
          );
          continue;
        }

        final row = shlokaRow(chapter.id, verse);
        final current = await _db.shlokaDao.getShloka(
          row.id,
          includeDeleted: true,
        );
        if (current == null) {
          final occupant = await _db.shlokaDao.getShlokaByVerse(
            chapter.id,
            verse.verseNumber,
            includeDeleted: true,
          );
          if (occupant != null) {
            verseCounts.skipped++;
            skipped.add(
              SkippedRecord(
                recordType: 'shloka',
                recordId: verse.id,
                fileName: fileName,
                reason: ImportSkipReason.verseSlotTaken,
                message:
                    '${verse.reference} is already cached under a '
                    'different id (${occupant.id}).',
              ),
            );
            continue;
          }
          await _db.shlokaDao.upsertShloka(row);
          verseCounts.inserted++;
        } else if (current == row) {
          verseCounts.unchanged++;
        } else if (current.updatedAt != contentRepositoryTimestamp) {
          verseCounts.skipped++;
          skipped.add(
            SkippedRecord(
              recordType: 'shloka',
              recordId: verse.id,
              fileName: fileName,
              reason: ImportSkipReason.serverRecordPresent,
              message:
                  '${verse.reference}: the cached verse came from the '
                  'server; repository content does not overwrite it.',
            ),
          );
          continue;
        } else {
          await _db.shlokaDao.upsertShloka(row);
          verseCounts.updated++;
        }
        shlokaIds[verse.id] = row.id;

        // Attributions: make the cached set match the file.
        if (!sourcesUsable) {
          if (verse.sourceAttributions.isNotEmpty) {
            skipped.add(
              SkippedRecord(
                recordType: 'attribution',
                recordId: verse.id,
                fileName: fileName,
                reason: ImportSkipReason.sourcesUnavailable,
                message:
                    '${verse.reference}: attributions kept unchanged '
                    'because sources.json is unusable.',
              ),
            );
          }
          continue;
        }
        // Only attributions to sources imported in this run (all of them
        // for an eligible verse; the filter just guards the foreign key).
        final desired = [
          for (final a in verse.sourceAttributions)
            if (importableSourceKeys.contains(a.sourceId))
              attributionRow(verse, a),
        ];
        final change = await _db.contentSourceDao.replaceAttributionsForShloka(
          row.id,
          desired,
        );
        attributionsInserted += change.inserted;
        attributionsDeleted += change.deleted;
      }
    });

    // Committed: publish the counts.
    _add(result.chapters, chapterCounts);
    _add(result.verses, verseCounts);
    result.skipped.addAll(skipped);
    result.shlokaIds.addAll(shlokaIds);
    result.attributionsInserted += attributionsInserted;
    result.attributionsDeleted += attributionsDeleted;
  }

  static void _add(ImportCounts into, ImportCounts from) {
    into
      ..inserted += from.inserted
      ..updated += from.updated
      ..unchanged += from.unchanged
      ..skipped += from.skipped
      ..failed += from.failed;
  }
}
