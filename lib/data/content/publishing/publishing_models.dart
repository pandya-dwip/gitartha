import '../validators/validation_result.dart';

/// What publishing will do with one record.
enum ChangeKind {
  /// The record does not exist remotely.
  insert,

  /// The record exists, and its publishable content differs.
  update,

  /// The record exists with identical content. Nothing is sent.
  unchanged,

  /// The record is deliberately not published (reason given).
  skip,

  /// The record cannot be published (reason given). Any error-kind change
  /// stops a confirmed publish before the first write.
  error,
}

/// The four content tables, in dependency (publishing) order.
enum PublishTable {
  chapters('chapters'),
  contentSources('content_sources'),
  shlokas('shlokas'),
  shlokaSourceAttributions('shloka_source_attributions');

  const PublishTable(this.tableName);

  final String tableName;
}

/// Stable reason codes for skipped and failed records.
abstract final class PublishReason {
  /// The remote row is soft-deleted. Publishing never restores it.
  static const String remoteSoftDeleted = 'REMOTE_SOFT_DELETED';

  /// Another shloka id already occupies this (chapter, verse) slot.
  static const String verseSlotConflict = 'VERSE_SLOT_CONFLICT';

  /// The chapter exists remotely and differs, but `--verse` limits the
  /// scope to one verse, so the chapter is left as it is.
  static const String outsideVerseScope = 'OUTSIDE_VERSE_SCOPE';

  /// A record this one depends on is skipped or failed.
  static const String dependencySkipped = 'DEPENDENCY_SKIPPED';

  /// The attribution exists remotely but no longer in the files.
  /// Publishing never deletes, so it stays.
  static const String remoteOnlyAttribution = 'REMOTE_ONLY_ATTRIBUTION';

  /// A prerequisite write failed, so this write was not attempted.
  static const String prerequisiteFailed = 'PREREQUISITE_FAILED';

  /// The run stopped (permission, session, network…) before this write.
  static const String runStopped = 'RUN_STOPPED';
}

/// One record in the plan.
class PublishingChange {
  const PublishingChange({
    required this.table,
    required this.recordId,
    required this.contentKey,
    required this.kind,
    required this.row,
    this.chapterId,
    this.changedFields = const [],
    this.reason,
    this.message,
    this.contentHash,
  });

  final PublishTable table;

  /// Database id (chapter number or UUID).
  final Object recordId;

  /// Human-readable key from the content repository, e.g.
  /// `chapter_01_verse_041`, `chapter 1` or the source key.
  final String contentKey;
  final ChangeKind kind;

  /// The row that would be written (content columns only).
  final Map<String, Object?> row;

  /// The chapter a chapter, shloka or attribution belongs to.
  final int? chapterId;

  /// For updates: the columns whose values differ.
  final List<String> changedFields;
  final String? reason;
  final String? message;

  /// SHA-256 of the normalized publishable content.
  final String? contentHash;

  bool get isWrite => kind == ChangeKind.insert || kind == ChangeKind.update;

  Map<String, Object?> toJson() => {
    'table': table.tableName,
    'recordId': recordId,
    'contentKey': contentKey,
    'kind': kind.name,
    if (chapterId != null) 'chapterId': chapterId,
    if (changedFields.isNotEmpty) 'changedFields': changedFields,
    if (reason != null) 'reason': reason,
    if (message != null) 'message': message,
    if (contentHash != null) 'contentHash': contentHash,
  };
}

/// What a publish run covers.
class PublishingScope {
  const PublishingScope.all() : chapterId = null, verseNumber = null;

  const PublishingScope.chapter(int this.chapterId, {this.verseNumber});

  final int? chapterId;
  final int? verseNumber;

  bool get isAll => chapterId == null;

  Set<int>? get chapterIds => chapterId == null ? null : {chapterId!};

  String get description => isAll
      ? 'All chapters'
      : verseNumber == null
      ? 'Chapter $chapterId'
      : 'Chapter $chapterId, verse $verseNumber';

  Map<String, Object?> toJson() => {
    'all': isAll,
    if (chapterId != null) 'chapter': chapterId,
    if (verseNumber != null) 'verse': verseNumber,
  };
}

/// Everything publishing would do, computed before any write.
class PublishingPlan {
  PublishingPlan({
    required this.scope,
    required this.validation,
    required this.blockingIssues,
    required List<PublishingChange> changes,
  }) : changes = List.unmodifiable(changes);

  final PublishingScope scope;
  final ValidationResult validation;

  /// Validation errors that forbid publishing anything (in scope).
  final List<ValidationIssue> blockingIssues;
  final List<PublishingChange> changes;

  bool get isBlocked => blockingIssues.isNotEmpty;

  bool get hasErrors => changes.any((c) => c.kind == ChangeKind.error);

  /// Whether a confirmed publish may go ahead.
  bool get canPublish => !isBlocked && !hasErrors;

  List<PublishingChange> forTable(PublishTable table) =>
      changes.where((c) => c.table == table).toList();

  int count(PublishTable table, ChangeKind kind) =>
      changes.where((c) => c.table == table && c.kind == kind).length;

  List<PublishingChange> get writes => changes.where((c) => c.isWrite).toList();

  Map<String, Object?> toJson() => {
    'scope': scope.toJson(),
    'blockingIssues': [for (final i in blockingIssues) i.toJson()],
    'counts': {
      for (final t in PublishTable.values)
        t.tableName: {for (final k in ChangeKind.values) k.name: count(t, k)},
    },
    'changes': [
      for (final c in changes)
        if (c.kind != ChangeKind.unchanged) c.toJson(),
    ],
  };
}

/// Overall outcome of a publishing command.
enum PublishingStatus {
  success('success'),
  successWithWarnings('success_with_warnings'),
  partiallyCompleted('partially_completed'),
  failed('failed'),
  dryRun('dry_run');

  const PublishingStatus(this.jsonValue);

  final String jsonValue;
}

/// What happened to one planned write.
class WriteOutcome {
  const WriteOutcome(
    this.change, {
    required this.succeeded,
    this.reason,
    this.error,
  });

  final PublishingChange change;
  final bool succeeded;

  /// For writes that were not attempted (`PREREQUISITE_FAILED`,
  /// `RUN_STOPPED`).
  final String? reason;

  /// For failed writes: a safe error description.
  final String? error;

  bool get attempted => reason == null;

  Map<String, Object?> toJson() => {
    ...change.toJson(),
    'succeeded': succeeded,
    if (reason != null) 'notAttemptedReason': reason,
    if (error != null) 'error': error,
  };
}
