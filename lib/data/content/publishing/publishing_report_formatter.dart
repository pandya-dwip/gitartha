import '../validators/validation_result.dart';
import 'publishing_models.dart';
import 'publishing_result.dart';

/// Plain-text rendering of validation, plans and results for the terminal.
abstract final class PublishingReportFormatter {
  static const String _rule = '========================================';
  static const String _line = '----------------------------------------';

  static String header({
    required String target,
    required PublishingScope scope,
    required String mode,
  }) =>
      '$_rule\n       GITARTHA CONTENT PUBLISHER\n$_rule\n\n'
      'Target: $target\nScope:  ${scope.description}\nMode:   $mode\n';

  static String validation(
    ValidationResult result, {
    required List<ValidationIssue> blocking,
    required int publishableVerses,
  }) {
    final b = StringBuffer()
      ..writeln()
      ..writeln('CONTENT VALIDATION (strict publishing rules)')
      ..writeln(_line)
      ..writeln(_row('Files discovered:', result.totalFiles))
      ..writeln(_row('Chapters parsed:', result.totalChapters))
      ..writeln(_row('Verses in files:', result.totalVerses))
      ..writeln(_row('Approved verses:', result.approvedVerses))
      ..writeln(_row('Publishable in scope:', publishableVerses))
      ..writeln(_row('Blocking errors:', blocking.length))
      ..writeln(
        _row(
          'Not-ready records:',
          result.errors.length - blocking.length,
          note: 'incomplete / not approved: left out, not published',
        ),
      )
      ..writeln(_row('Warnings:', result.warnings.length));
    if (blocking.isNotEmpty) {
      b
        ..writeln()
        ..writeln('Blocking errors (fix these before publishing):');
      for (final i in blocking) {
        b
          ..writeln('  [${i.code}] ${i.fileName}  ${i.jsonPath}')
          ..writeln('      ${i.message}');
      }
    }
    return b.toString();
  }

  static String plan(PublishingPlan plan) {
    final b = StringBuffer()
      ..writeln()
      ..writeln('PUBLISHING PREVIEW')
      ..writeln(_line);
    for (final (table, label) in [
      (PublishTable.chapters, 'Chapters'),
      (PublishTable.contentSources, 'Sources'),
      (PublishTable.shlokas, 'Shlokas'),
      (PublishTable.shlokaSourceAttributions, 'Attributions'),
    ]) {
      b
        ..writeln(
          _row('$label to insert:', plan.count(table, ChangeKind.insert)),
        )
        ..writeln(
          _row('$label to update:', plan.count(table, ChangeKind.update)),
        )
        ..writeln(
          _row('$label unchanged:', plan.count(table, ChangeKind.unchanged)),
        );
      final skipped = plan.count(table, ChangeKind.skip);
      final errors = plan.count(table, ChangeKind.error);
      if (skipped > 0) b.writeln(_row('$label skipped:', skipped));
      if (errors > 0) b.writeln(_row('$label with errors:', errors));
      b.writeln();
    }
    final detail = plan.changes.where((c) => c.kind != ChangeKind.unchanged);
    if (detail.isNotEmpty) {
      b.writeln('Changes:');
      for (final c in detail) {
        final fields = c.changedFields.isEmpty
            ? ''
            : ' (${c.changedFields.join(', ')})';
        final why = c.reason == null
            ? ''
            : '  [${c.reason}] ${c.message ?? ''}';
        b.writeln(
          '  ${c.kind.name.toUpperCase().padRight(9)} '
          '${c.table.tableName}  ${c.contentKey}$fields$why',
        );
      }
    }
    return b.toString();
  }

  static String result(PublishingResult r) {
    final b = StringBuffer()
      ..writeln()
      ..writeln(_rule)
      ..writeln('Status: ${r.status.jsonValue}')
      ..writeln('Operation: ${r.operationId}');
    if (r.stopMessage != null) b.writeln(r.stopMessage);
    if (!r.dryRun && r.outcomes.isNotEmpty) {
      b.writeln(
        'Writes: ${r.outcomes.where((o) => o.succeeded).length} succeeded, '
        '${r.failedWrites.length} failed or not attempted',
      );
      for (final o in r.failedWrites) {
        b.writeln(
          '  FAILED ${o.change.table.tableName} ${o.change.contentKey}: '
          '${o.error ?? o.reason}',
        );
      }
      if (r.status == PublishingStatus.partiallyCompleted) {
        b.writeln(
          'Partially completed. Re-running the same command is safe: '
          'finished records are reported as unchanged and the rest are '
          'retried.',
        );
      }
    }
    if (r.dryRun) b.writeln('No database changes were made.');
    b.writeln(_rule);
    return b.toString();
  }

  static String _row(String label, int value, {String? note}) =>
      '${label.padRight(28)}${value.toString().padLeft(5)}'
      '${note == null ? '' : '   ($note)'}';
}
