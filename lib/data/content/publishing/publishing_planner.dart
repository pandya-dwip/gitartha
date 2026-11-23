import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../content_constants.dart';
import '../importers/import_result.dart';
import '../selection/content_selection.dart';
import '../validators/validation_result.dart';
import 'mappers/attribution_supabase_mapper.dart';
import 'mappers/chapter_supabase_mapper.dart';
import 'mappers/shloka_supabase_mapper.dart';
import 'mappers/source_supabase_mapper.dart';
import 'publishing_models.dart';
import 'remote_content_store.dart';

/// Validation codes that exclude a record from publishing without blocking
/// the run. They describe content that is not ready yet (incomplete, not
/// approved, not sourced), which approved selection simply leaves out.
/// Every other error is structural and blocks publishing.
const Set<String> readinessCodes = {
  ValidationCode.incompleteContent,
  ValidationCode.notApproved,
  ValidationCode.missingVerses,
  ValidationCode.missingAttribution,
  ValidationCode.unverifiedSourceLicense,
};

/// Validation errors that forbid publishing within [scope]: structural
/// errors in the chapter files in scope, in `sources.json`, or in the
/// schemas (all files when the scope is every chapter).
List<ValidationIssue> blockingIssues(
  ValidationResult validation,
  PublishingScope scope,
) {
  bool inScope(String fileName) =>
      scope.isAll ||
      fileName == GitaContent.chapterFileName(scope.chapterId!) ||
      fileName == GitaContent.sourcesFileName ||
      fileName.endsWith('.schema.json');
  return [
    for (final issue in validation.errors)
      if (!readinessCodes.contains(issue.code) && inScope(issue.fileName))
        issue,
  ];
}

/// Builds a [PublishingPlan]: the approved content in scope, compared with
/// what Supabase currently holds. Reads only; never writes.
class PublishingPlanner {
  const PublishingPlanner();

  Future<PublishingPlan> plan({
    required ContentValidationReport report,
    required PublishingScope scope,
    required RemoteContentStore store,
  }) async {
    final blocking = blockingIssues(report.result, scope);
    if (blocking.isNotEmpty) {
      return PublishingPlan(
        scope: scope,
        validation: report.result,
        blockingIssues: blocking,
        changes: const [],
      );
    }

    final selection = const ContentSelector().select(
      report,
      mode: ImportMode.approved,
      chapterIds: scope.chapterIds,
      verseNumber: scope.verseNumber,
    );

    // ----- Desired rows ------------------------------------------------------
    final chapterRows = {
      for (final c in selection.chapters)
        c.chapter.id: ChapterSupabaseMapper.toRow(
          c.chapter,
          includeDescriptions: c.includeDescriptions,
        ),
    };
    final verseRows = <String, Map<String, Object?>>{}; // uuid -> row
    final verseKeys = <String, String>{}; // uuid -> content id
    final verseChapter = <String, int>{};
    final attributionRows = <String, List<Map<String, Object?>>>{};
    final referencedSourceKeys = <String>{};
    for (final c in selection.chapters) {
      for (final v in c.verses) {
        final row = ShlokaSupabaseMapper.toRow(c.chapter.id, v.verse);
        final id = row['id']! as String;
        verseRows[id] = row;
        verseKeys[id] = v.verse.id;
        verseChapter[id] = c.chapter.id;
        final seen = <String>{};
        attributionRows[id] = [
          for (final a in v.verse.sourceAttributions)
            if (seen.add(
              AttributionSupabaseMapper.naturalKey(
                AttributionSupabaseMapper.toRow(v.verse, a),
              ),
            ))
              AttributionSupabaseMapper.toRow(v.verse, a),
        ];
        referencedSourceKeys.addAll(
          v.verse.sourceAttributions.map((a) => a.sourceId),
        );
      }
    }
    // Chapter/verse scope: only the sources those verses need.
    final sources = [
      for (final s in selection.sources)
        if (scope.isAll || referencedSourceKeys.contains(s.id)) s,
    ];
    final sourceRows = {
      for (final s in sources)
        SourceSupabaseMapper.toRow(s)['id']! as String: (
          key: s.id,
          row: SourceSupabaseMapper.toRow(s),
        ),
    };

    // ----- Remote state (reads only) ----------------------------------------
    final remoteChapters = _byId(
      await store.fetchByIds(
        ChapterSupabaseMapper.table,
        chapterRows.keys.toList(),
        ChapterSupabaseMapper.selectColumns,
      ),
    );
    final remoteSources = _byId(
      await store.fetchByIds(
        SourceSupabaseMapper.table,
        sourceRows.keys.toList(),
        SourceSupabaseMapper.selectColumns,
      ),
    );
    final remoteShlokas = _byId(
      await store.fetchByIds(
        ShlokaSupabaseMapper.table,
        verseRows.keys.toList(),
        ShlokaSupabaseMapper.selectColumns,
      ),
    );
    final slots = <String, String>{}; // "chapter.verse" -> remote shloka id
    for (final s in await store.fetchShlokaSlots(chapterRows.keys.toList())) {
      slots['${s['chapter_id']}.${s['verse_number']}'] = s['id']! as String;
    }
    final remoteAttributions = await store.fetchAttributions(
      verseRows.keys.toList(),
    );

    // ----- Classification ----------------------------------------------------
    final changes = <PublishingChange>[];

    final chapterKinds = <int, ChangeKind>{};
    for (final MapEntry(key: id, value: row) in chapterRows.entries) {
      final change = _classify(
        table: PublishTable.chapters,
        recordId: id,
        contentKey: 'chapter $id',
        chapterId: id,
        row: row,
        remote: remoteChapters['$id'],
        columns: ChapterSupabaseMapper.contentColumns,
        updateBlockedReason: scope.verseNumber != null
            ? PublishReason.outsideVerseScope
            : null,
      );
      chapterKinds[id] = change.kind;
      changes.add(change);
    }

    final sourceKinds = <String, ChangeKind>{};
    for (final MapEntry(key: id, value: entry) in sourceRows.entries) {
      final change = _classify(
        table: PublishTable.contentSources,
        recordId: id,
        contentKey: entry.key,
        row: entry.row,
        remote: remoteSources[id],
        columns: SourceSupabaseMapper.contentColumns,
      );
      sourceKinds[entry.key] = change.kind;
      changes.add(change);
    }

    final verseKinds = <String, ChangeKind>{};
    for (final MapEntry(key: id, value: row) in verseRows.entries) {
      final chapterId = verseChapter[id]!;
      final chapterKind = chapterKinds[chapterId]!;
      final slotOwner = slots['$chapterId.${row['verse_number']}'];
      final hash = _hash({
        ...row,
        'attributions': [
          for (final a in attributionRows[id]!)
            AttributionSupabaseMapper.naturalKey(a),
        ]..sort(),
      });
      PublishingChange change;
      if (chapterKind == ChangeKind.skip &&
          remoteChapters['$chapterId']?['deleted_at'] != null) {
        change = PublishingChange(
          table: PublishTable.shlokas,
          recordId: id,
          contentKey: verseKeys[id]!,
          chapterId: chapterId,
          kind: ChangeKind.skip,
          row: row,
          reason: PublishReason.dependencySkipped,
          message: 'Chapter $chapterId is soft-deleted remotely.',
          contentHash: hash,
        );
      } else if (slotOwner != null && slotOwner != id) {
        change = PublishingChange(
          table: PublishTable.shlokas,
          recordId: id,
          contentKey: verseKeys[id]!,
          chapterId: chapterId,
          kind: ChangeKind.error,
          row: row,
          reason: PublishReason.verseSlotConflict,
          message:
              'Verse $chapterId.${row['verse_number']} already exists '
              'remotely with a different id ($slotOwner). Resolve this in '
              'Supabase before publishing.',
          contentHash: hash,
        );
      } else {
        change = _classify(
          table: PublishTable.shlokas,
          recordId: id,
          contentKey: verseKeys[id]!,
          chapterId: chapterId,
          row: row,
          remote: remoteShlokas[id],
          columns: ShlokaSupabaseMapper.contentColumns,
          hash: hash,
        );
      }
      verseKinds[id] = change.kind;
      changes.add(change);
    }

    // Attributions: insert the missing ones; never delete remote extras.
    final remoteKeys = {
      for (final a in remoteAttributions)
        AttributionSupabaseMapper.naturalKey(a): a,
    };
    final desiredKeys = <String>{};
    final sourceKeyById = {
      for (final e in sourceRows.entries) e.key: e.value.key,
    };
    for (final MapEntry(key: shlokaId, value: rows)
        in attributionRows.entries) {
      for (final row in rows) {
        final key = AttributionSupabaseMapper.naturalKey(row);
        desiredKeys.add(key);
        final sourceKey = sourceKeyById[row['source_id']];
        final verseKind = verseKinds[shlokaId]!;
        final sourceKind = sourceKey == null ? null : sourceKinds[sourceKey];
        final blocked =
            verseKind == ChangeKind.skip ||
            verseKind == ChangeKind.error ||
            sourceKind == null ||
            sourceKind == ChangeKind.skip ||
            sourceKind == ChangeKind.error;
        changes.add(
          PublishingChange(
            table: PublishTable.shlokaSourceAttributions,
            recordId: row['id']!,
            contentKey:
                '${verseKeys[shlokaId]} ${sourceKey ?? row['source_id']} '
                '${row['content_section']}',
            chapterId: verseChapter[shlokaId],
            row: row,
            kind: blocked
                ? ChangeKind.skip
                : remoteKeys.containsKey(key)
                ? ChangeKind.unchanged
                : ChangeKind.insert,
            reason: blocked ? PublishReason.dependencySkipped : null,
            message: blocked
                ? 'Its shloka or source is not being published.'
                : null,
          ),
        );
      }
    }
    for (final MapEntry(:key, value: remote) in remoteKeys.entries) {
      if (desiredKeys.contains(key)) continue;
      changes.add(
        PublishingChange(
          table: PublishTable.shlokaSourceAttributions,
          recordId: remote['id']!,
          contentKey: key,
          kind: ChangeKind.skip,
          row: remote,
          reason: PublishReason.remoteOnlyAttribution,
          message:
              'Exists in Supabase but not in the content files. '
              'Publishing never deletes, so it is left as it is.',
        ),
      );
    }

    return PublishingPlan(
      scope: scope,
      validation: report.result,
      blockingIssues: const [],
      changes: changes,
    );
  }

  PublishingChange _classify({
    required PublishTable table,
    required Object recordId,
    required String contentKey,
    required Map<String, Object?> row,
    required Map<String, Object?>? remote,
    required List<String> columns,
    int? chapterId,
    String? updateBlockedReason,
    String? hash,
  }) {
    final contentHash = hash ?? _hash(row);
    PublishingChange make(
      ChangeKind kind, {
      List<String> changed = const [],
      String? reason,
      String? message,
    }) => PublishingChange(
      table: table,
      recordId: recordId,
      contentKey: contentKey,
      chapterId: chapterId,
      kind: kind,
      row: row,
      changedFields: changed,
      reason: reason,
      message: message,
      contentHash: contentHash,
    );

    if (remote == null) return make(ChangeKind.insert);
    if (remote['deleted_at'] != null) {
      return make(
        ChangeKind.skip,
        reason: PublishReason.remoteSoftDeleted,
        message:
            'Soft-deleted in Supabase. Publishing never restores '
            'records; restoring is a separate, explicit operation.',
      );
    }
    final changed = [
      for (final column in columns)
        if (_normalize(row[column]) != _normalize(remote[column])) column,
    ];
    if (changed.isEmpty) return make(ChangeKind.unchanged);
    if (updateBlockedReason != null) {
      return make(
        ChangeKind.skip,
        changed: changed,
        reason: updateBlockedReason,
        message:
            'Differs remotely (${changed.join(', ')}), but --verse '
            'limits this run to one verse.',
      );
    }
    return make(ChangeKind.update, changed: changed);
  }

  static Map<String, Map<String, Object?>> _byId(
    List<Map<String, Object?>> rows,
  ) => {for (final r in rows) '${r['id']}': r};

  /// Canonical JSON of a value, for comparison: lists keep their order,
  /// numbers compare by value, and timestamps are never part of the input.
  static String _normalize(Object? value) => jsonEncode(_canonical(value));

  static Object? _canonical(Object? value) => switch (value) {
    final List<Object?> list => [for (final v in list) _canonical(v)],
    final Map<Object?, Object?> map => {
      for (final k in (map.keys.map((k) => '$k').toList()..sort()))
        k: _canonical(map[k]),
    },
    final num n when n == n.truncate() => n.toInt(),
    _ => value,
  };

  static String _hash(Map<String, Object?> row) =>
      sha256.convert(utf8.encode(_normalize(row))).toString();
}
