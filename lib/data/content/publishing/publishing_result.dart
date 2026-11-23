import '../importers/import_result.dart';
import '../validators/validation_result.dart';
import 'publishing_models.dart';

/// Where a run stopped before writing, if it did.
enum PublishingStage {
  configuration,
  validation,
  authentication,
  authorization,
  remoteSchema,
  planning,
  confirmation,
}

/// The structured report of one publishing command. [toJson] is what the
/// `--save-report` option writes. It never contains passwords, tokens or
/// keys: only the project host, the user id and content identifiers.
class PublishingResult {
  PublishingResult({
    required this.operationId,
    required this.target,
    required this.scope,
    required this.dryRun,
    required this.startedAt,
  });

  final String operationId;

  /// The Supabase project host (never the key).
  final String target;
  final PublishingScope scope;
  final bool dryRun;
  final DateTime startedAt;
  DateTime? completedAt;

  String? userId;
  ValidationResult? validation;
  PublishingPlan? plan;
  List<SkippedRecord> rejectedByValidation = const [];
  List<WriteOutcome> outcomes = const [];

  /// Set when the run ended before writing.
  PublishingStage? stoppedAt;
  String? stopMessage;

  // ----- Derived -------------------------------------------------------------

  int _planned(PublishTable t, ChangeKind k) => plan?.count(t, k) ?? 0;

  int _written(PublishTable t, ChangeKind k) => outcomes
      .where((o) => o.succeeded && o.change.table == t && o.change.kind == k)
      .length;

  /// Inserted (or, for a dry run, to be inserted).
  int inserted(PublishTable t) =>
      dryRun ? _planned(t, ChangeKind.insert) : _written(t, ChangeKind.insert);

  int updated(PublishTable t) =>
      dryRun ? _planned(t, ChangeKind.update) : _written(t, ChangeKind.update);

  int unchanged(PublishTable t) => _planned(t, ChangeKind.unchanged);

  int get chaptersProcessed =>
      plan?.forTable(PublishTable.chapters).length ?? 0;
  int get shlokasProcessed => plan?.forTable(PublishTable.shlokas).length ?? 0;

  List<PublishingChange> get skippedChanges => [
    ...?plan?.changes.where((c) => c.kind == ChangeKind.skip),
  ];

  List<PublishingChange> get errorChanges => [
    ...?plan?.changes.where((c) => c.kind == ChangeKind.error),
  ];

  List<WriteOutcome> get failedWrites =>
      outcomes.where((o) => !o.succeeded).toList();

  int get recordsSkipped => skippedChanges.length + rejectedByValidation.length;
  int get recordsFailed => failedWrites.length + errorChanges.length;

  bool get hasWarnings =>
      recordsSkipped > 0 || (validation?.warnings.isNotEmpty ?? false);

  PublishingStatus get status {
    if (stoppedAt != null) return PublishingStatus.failed;
    if (dryRun) return PublishingStatus.dryRun;
    final succeeded = outcomes.where((o) => o.succeeded).length;
    if (failedWrites.isNotEmpty) {
      return succeeded > 0
          ? PublishingStatus.partiallyCompleted
          : PublishingStatus.failed;
    }
    return hasWarnings
        ? PublishingStatus.successWithWarnings
        : PublishingStatus.success;
  }

  Map<String, Object?> toJson() => {
    'operationId': operationId,
    'target': target,
    'scope': scope.toJson(),
    'mode': dryRun ? 'dry_run' : 'publish',
    'status': status.jsonValue,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'completedAt': completedAt?.toUtc().toIso8601String(),
    'userId': userId,
    if (stoppedAt != null)
      'stopped': {'stage': stoppedAt!.name, 'message': stopMessage},
    'chaptersProcessed': chaptersProcessed,
    'shlokasProcessed': shlokasProcessed,
    'counts': {
      for (final t in PublishTable.values)
        t.tableName: {
          'inserted': inserted(t),
          'updated': updated(t),
          'unchanged': unchanged(t),
          'skipped': _planned(t, ChangeKind.skip),
          'errors': _planned(t, ChangeKind.error),
          'failed': failedWrites.where((o) => o.change.table == t).length,
        },
    },
    'recordsSkipped': recordsSkipped,
    'recordsFailed': recordsFailed,
    'skipped': [
      for (final c in skippedChanges) c.toJson(),
      for (final r in rejectedByValidation) r.toJson(),
    ],
    'errors': [for (final c in errorChanges) c.toJson()],
    'failedWrites': [for (final o in failedWrites) o.toJson()],
    'writes': [
      for (final o in outcomes)
        if (o.succeeded) o.change.toJson(),
    ],
    'validationErrors': [
      for (final i in validation?.errors ?? const []) i.toJson(),
    ],
    'validationWarnings': [
      for (final i in validation?.warnings ?? const []) i.toJson(),
    ],
  };
}
