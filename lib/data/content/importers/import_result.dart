import '../validators/validation_result.dart';

/// How content is imported into the local database.
enum ImportMode {
  /// Local development and testing. Accepts structurally valid but
  /// incomplete content (validated in `draft` mode). Never marks anything
  /// verified.
  draft(ValidationMode.draft),

  /// Only content that passes `strict` validation: complete, `approved`
  /// verses with verified sources. The presence of text alone never makes a
  /// verse eligible.
  approved(ValidationMode.strict);

  const ImportMode(this.validationMode);

  final ValidationMode validationMode;
}

enum ImportStatus {
  /// Validation passed in the mode used, and every record was imported or
  /// was already up to date.
  succeeded,

  /// Nothing failed, but some records were rejected by validation or
  /// skipped. See [ImportResult.skipped].
  completedWithRejections,

  /// A database transaction failed, or validation found errors that made
  /// files unusable. See [ImportResult.failures].
  failed,
}

/// Inserted / updated / unchanged / skipped / failed counts for one kind of
/// record.
class ImportCounts {
  int inserted = 0;
  int updated = 0;
  int unchanged = 0;
  int skipped = 0;
  int failed = 0;

  int get processed => inserted + updated + unchanged + skipped + failed;

  Map<String, int> toJson() => {
    'inserted': inserted,
    'updated': updated,
    'unchanged': unchanged,
    'skipped': skipped,
    'failed': failed,
  };

  @override
  String toString() =>
      '$inserted inserted, $updated updated, $unchanged unchanged, '
      '$skipped skipped, $failed failed';
}

/// Stable reason codes for skipped records.
abstract final class ImportSkipReason {
  /// The file failed validation in a way that makes it unusable.
  static const String fileInvalid = 'FILE_INVALID';

  /// The record has validation errors in the mode used (for approved
  /// import: it is incomplete, not approved or not properly sourced).
  static const String validationFailed = 'VALIDATION_FAILED';

  /// Approved import: the chapter has no names yet, so neither it nor its
  /// verses can be stored (names are required by the database).
  static const String chapterNamesMissing = 'CHAPTER_NAMES_MISSING';

  /// The cached row came from the server. Repository content never
  /// overwrites server content.
  static const String serverRecordPresent = 'SERVER_RECORD_PRESENT';

  /// Another verse (different id) already occupies this chapter/verse slot.
  static const String verseSlotTaken = 'VERSE_SLOT_TAKEN';

  /// Approved import: the source has no verified licence.
  static const String unverifiedSource = 'UNVERIFIED_SOURCE';

  /// `sources.json` was unusable, so attributions could not be stored.
  static const String sourcesUnavailable = 'SOURCES_UNAVAILABLE';
}

class SkippedRecord {
  const SkippedRecord({
    required this.recordType,
    required this.recordId,
    required this.fileName,
    required this.reason,
    required this.message,
  });

  /// `chapter`, `shloka`, `source` or `attribution`.
  final String recordType;
  final String recordId;
  final String fileName;
  final String reason;
  final String message;

  Map<String, Object?> toJson() => {
    'recordType': recordType,
    'recordId': recordId,
    'fileName': fileName,
    'reason': reason,
    'message': message,
  };
}

/// A database transaction that failed and was rolled back.
class ImportFailure {
  const ImportFailure({
    required this.transaction,
    required this.fileName,
    required this.error,
  });

  /// Which transaction: `sources` or `chapter <N>`.
  final String transaction;
  final String fileName;
  final String error;

  Map<String, Object?> toJson() => {
    'transaction': transaction,
    'fileName': fileName,
    'error': error,
  };
}

/// The outcome of one import run. Serializable with [toJson].
class ImportResult {
  ImportResult({required this.mode, required this.startedAt});

  final ImportMode mode;
  final DateTime startedAt;
  DateTime? completedAt;

  int totalFilesDiscovered = 0;
  int chaptersProcessed = 0;
  int versesProcessed = 0;

  final ImportCounts chapters = ImportCounts();
  final ImportCounts verses = ImportCounts();
  final ImportCounts sources = ImportCounts();
  int attributionsInserted = 0;
  int attributionsDeleted = 0;

  final List<SkippedRecord> skipped = [];
  final List<ImportFailure> failures = [];

  /// The validation run the import was based on.
  ValidationResult? validation;

  /// Content ids → database UUIDs of the verses imported in this run.
  final Map<String, String> shlokaIds = {};

  List<ValidationIssue> get validationErrors => validation?.errors ?? const [];
  List<ValidationIssue> get validationWarnings =>
      validation?.warnings ?? const [];

  int get recordsSkipped => skipped.length;
  int get recordsFailed => chapters.failed + verses.failed + sources.failed;

  ImportStatus get status {
    final unusable =
        validation == null ||
        validationErrors.any(
          (e) => e.scope == IssueScope.repository || e.scope == IssueScope.file,
        );
    if (failures.isNotEmpty || unusable) return ImportStatus.failed;
    if (validationErrors.isNotEmpty || skipped.isNotEmpty) {
      return ImportStatus.completedWithRejections;
    }
    return ImportStatus.succeeded;
  }

  /// True only when validation passed and nothing was skipped or failed.
  bool get isSuccess => status == ImportStatus.succeeded;

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'status': status.name,
    'isSuccess': isSuccess,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'completedAt': completedAt?.toUtc().toIso8601String(),
    'totalFilesDiscovered': totalFilesDiscovered,
    'chaptersProcessed': chaptersProcessed,
    'versesProcessed': versesProcessed,
    'chapters': chapters.toJson(),
    'verses': verses.toJson(),
    'sources': sources.toJson(),
    'attributions': {
      'inserted': attributionsInserted,
      'deleted': attributionsDeleted,
    },
    'recordsSkipped': recordsSkipped,
    'recordsFailed': recordsFailed,
    'skipped': [for (final s in skipped) s.toJson()],
    'failures': [for (final f in failures) f.toJson()],
    'validationErrors': [for (final e in validationErrors) e.toJson()],
    'validationWarnings': [for (final w in validationWarnings) w.toJson()],
  };

  /// A readable summary for the console.
  String toReport() {
    final b = StringBuffer()
      ..writeln('Gitartha content import (${mode.name} mode): ${status.name}')
      ..writeln(
        'Files: $totalFilesDiscovered · chapters processed: $chaptersProcessed '
        '· verses processed: $versesProcessed',
      )
      ..writeln('Chapters: $chapters')
      ..writeln('Verses:   $verses')
      ..writeln('Sources:  $sources')
      ..writeln(
        'Attributions: $attributionsInserted inserted, '
        '$attributionsDeleted deleted',
      )
      ..writeln(
        'Validation: ${validationErrors.length} error(s), '
        '${validationWarnings.length} warning(s)',
      );
    if (skipped.isNotEmpty) {
      b.writeln('Skipped (${skipped.length}):');
      for (final s in skipped) {
        b.writeln(
          '  [${s.reason}] ${s.recordType} ${s.recordId}: ${s.message}',
        );
      }
    }
    if (failures.isNotEmpty) {
      b.writeln('Failed transactions (${failures.length}):');
      for (final f in failures) {
        b.writeln('  ${f.transaction} (${f.fileName}): ${f.error}');
      }
    }
    return b.toString();
  }
}
