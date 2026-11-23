import '../../local/database/app_database.dart';
import '../services/content_asset_loader.dart';
import '../selection/content_selection.dart';
import '../services/content_validation_service.dart';
import '../validators/validation_result.dart';
import 'chapter_content_importer.dart';
import 'import_result.dart';

/// The controlled import pipeline:
///
/// content source → validation (draft or strict) → eligible records →
/// local Drift cache → [ImportResult].
///
/// Nothing calls this automatically. It is invoked explicitly by a test, a
/// developer tool or a future initialization flow.
///
/// Guarantees:
///  * **Idempotent.** Deterministic ids and content comparison mean that
///    importing the same files again changes nothing and reports every
///    record as unchanged.
///  * **Atomic per chapter.** Each chapter (row, verses and attributions) is
///    one transaction. A failure rolls that chapter back, is reported with
///    the transaction that failed, and does not stop other chapters.
///  * **Personal data is never touched.** Only the shared-content cache
///    tables are written, nothing cascades, and no verse is ever deleted.
class ContentImportService {
  ContentImportService({
    required ContentSource source,
    required AppDatabase database,
    ContentValidationService? validationService,
  }) : _db = database,
       _validation = validationService ?? ContentValidationService(source),
       _chapterImporter = ChapterContentImporter(database);

  final AppDatabase _db;
  final ContentValidationService _validation;
  final ChapterContentImporter _chapterImporter;

  /// Validates and imports [chapterIds] (default: all 18) in [mode].
  Future<ImportResult> importContent({
    required ImportMode mode,
    Iterable<int>? chapterIds,
  }) async {
    final result = ImportResult(mode: mode, startedAt: _db.now());
    final report = await _validation.validate(
      mode: mode.validationMode,
      chapterIds: chapterIds,
    );
    result
      ..validation = report.result
      ..totalFilesDiscovered = report.result.totalFiles;

    final repositoryBroken = report.result.errors.any(
      (e) =>
          e.scope == IssueScope.repository &&
          e.code == ValidationCode.assetLoadFailed &&
          e.fileName.endsWith('.schema.json'),
    );
    if (repositoryBroken) {
      result.completedAt = _db.now();
      return result;
    }

    // Which records may be written is decided once, by the same selector
    // the Supabase publisher uses.
    final selection = const ContentSelector().select(report, mode: mode);
    result.skipped.addAll(selection.rejected);
    result.chapters.skipped += selection.rejectedChapters;
    result.verses.skipped += selection.rejectedVerses;
    result.sources.skipped += selection.rejectedSources;
    for (final chapter in report.chapters) {
      result.chaptersProcessed++;
      result.versesProcessed += chapter.model?.verses.length ?? 0;
    }

    final importableSourceKeys = await _importSources(selection, result);

    for (final selected in selection.chapters) {
      try {
        await _chapterImporter.importChapter(
          selected: selected,
          importableSourceKeys: importableSourceKeys,
          sourcesUsable: selection.sourcesUsable,
          result: result,
        );
      } on Object catch (error) {
        // The chapter's transaction was rolled back: nothing of it was
        // written. Report it and carry on with the other chapters.
        result.chapters.failed++;
        result.verses.failed += selected.verses.length;
        result.failures.add(
          ImportFailure(
            transaction: 'chapter ${selected.chapter.id}',
            fileName: selected.fileName,
            error: error.toString(),
          ),
        );
      }
    }

    result.completedAt = _db.now();
    return result;
  }

  /// Imports the selected sources in one transaction. Returns the keys of
  /// the sources now available for attributions.
  Future<Set<String>> _importSources(
    ContentSelection selection,
    ImportResult result,
  ) async {
    if (!selection.sourcesUsable) return const {};
    final selected = <String>{};
    final counts = ImportCounts();
    final skipped = <SkippedRecord>[];
    try {
      await _db.transaction(() async {
        for (final source in selection.sources) {
          final row = ChapterContentImporter.sourceRow(source);
          final existing = await _db.contentSourceDao.getSource(row.id);
          if (existing == null) {
            await _db.contentSourceDao.upsertSource(row);
            counts.inserted++;
          } else if (existing == row) {
            counts.unchanged++;
          } else if (existing.updatedAt != contentRepositoryTimestamp) {
            counts.skipped++;
            skipped.add(
              SkippedRecord(
                recordType: 'source',
                recordId: source.id,
                fileName: 'sources.json',
                reason: ImportSkipReason.serverRecordPresent,
                message: 'The cached source came from the server.',
              ),
            );
            selected.add(source.id); // still usable for attributions
            continue;
          } else {
            await _db.contentSourceDao.upsertSource(row);
            counts.updated++;
          }
          selected.add(source.id);
        }
      });
    } on Object catch (error) {
      result.sources.failed += selection.sources.length;
      result.failures.add(
        ImportFailure(
          transaction: 'sources',
          fileName: 'sources.json',
          error: error.toString(),
        ),
      );
      return const {};
    }
    final into = result.sources;
    into
      ..inserted += counts.inserted
      ..updated += counts.updated
      ..unchanged += counts.unchanged
      ..skipped += counts.skipped;
    result.skipped.addAll(skipped);
    return selected;
  }
}
