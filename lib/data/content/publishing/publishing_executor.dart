import 'publishing_models.dart';
import 'remote_content_store.dart';

/// Carries out the writes of a [PublishingPlan], in dependency order:
///
/// 1. `chapters` (one request per chapter)
/// 2. `content_sources` (one request per source)
/// 3. `shlokas` (one request per chapter)
/// 4. `shloka_source_attributions` (one request per chapter; insert-only)
///
/// Each request is one SQL statement, so atomic on its own. The run as a
/// whole is **not** atomic, because several HTTP requests never are.
/// Instead:
///  * a failed prerequisite (a chapter, source or shloka batch) means its
///    dependents are not attempted (`PREREQUISITE_FAILED`);
///  * errors that make further requests pointless (permission, session,
///    network, rate limit, schema) stop the run (`RUN_STOPPED`);
///  * every write is an idempotent upsert or insert-ignore on deterministic
///    ids, so re-running after a partial failure is safe and completes the
///    rest.
///
/// Only `insert` and `update` changes are written. Unchanged, skipped and
/// error records are never sent. Nothing is ever deleted.
class PublishingExecutor {
  const PublishingExecutor();

  Future<List<WriteOutcome>> execute(
    PublishingPlan plan,
    RemoteContentStore store,
  ) async {
    if (!plan.canPublish) {
      throw StateError(
        'This plan cannot be published (blocked or has errors).',
      );
    }
    final outcomes = <WriteOutcome>[];
    final failedChapters = <int>{};
    final failedSources = <Object>{};
    final failedShlokas = <Object>{};
    var stopped = false;

    void notAttempted(Iterable<PublishingChange> changes, String reason) {
      for (final c in changes) {
        outcomes.add(WriteOutcome(c, succeeded: false, reason: reason));
      }
    }

    Future<bool> send(
      List<PublishingChange> batch,
      Future<void> Function() request,
    ) async {
      if (stopped) {
        notAttempted(batch, PublishReason.runStopped);
        return false;
      }
      try {
        await request();
        for (final c in batch) {
          outcomes.add(WriteOutcome(c, succeeded: true));
        }
        return true;
      } on RemoteStoreException catch (e) {
        for (final c in batch) {
          outcomes.add(WriteOutcome(c, succeeded: false, error: e.toString()));
        }
        if (e.kind.stopsRun) stopped = true;
        return false;
      } on Object catch (e) {
        for (final c in batch) {
          outcomes.add(
            WriteOutcome(
              c,
              succeeded: false,
              error: 'Unexpected ${e.runtimeType} while writing.',
            ),
          );
        }
        stopped = true;
        return false;
      }
    }

    List<PublishingChange> writesOf(PublishTable table) =>
        plan.forTable(table).where((c) => c.isWrite).toList();

    // 1. Chapters.
    for (final change in writesOf(PublishTable.chapters)) {
      final ok = await send([
        change,
      ], () => store.upsert(PublishTable.chapters.tableName, [change.row]));
      // Only a failed insert leaves dependents without their parent row.
      if (!ok && change.kind == ChangeKind.insert) {
        failedChapters.add(change.recordId as int);
      }
    }

    // 2. Sources.
    for (final change in writesOf(PublishTable.contentSources)) {
      final ok = await send(
        [change],
        () => store.upsert(PublishTable.contentSources.tableName, [change.row]),
      );
      if (!ok && change.kind == ChangeKind.insert) {
        failedSources.add(change.recordId);
      }
    }

    // 3. Shlokas, one batch per chapter.
    for (final batch in _byChapter(writesOf(PublishTable.shlokas))) {
      if (failedChapters.contains(batch.first.chapterId)) {
        notAttempted(batch, PublishReason.prerequisiteFailed);
        failedShlokas.addAll(
          batch
              .where((c) => c.kind == ChangeKind.insert)
              .map((c) => c.recordId),
        );
        continue;
      }
      final ok = await send(
        batch,
        () => store.upsert(PublishTable.shlokas.tableName, [
          for (final c in batch) c.row,
        ]),
      );
      if (!ok) {
        failedShlokas.addAll(
          batch
              .where((c) => c.kind == ChangeKind.insert)
              .map((c) => c.recordId),
        );
      }
    }

    // 4. Attributions, one batch per chapter, without failed prerequisites.
    for (final batch in _byChapter(
      writesOf(PublishTable.shlokaSourceAttributions),
    )) {
      final blocked = batch
          .where(
            (c) =>
                failedShlokas.contains(c.row['shloka_id']) ||
                failedSources.contains(c.row['source_id']),
          )
          .toList();
      notAttempted(blocked, PublishReason.prerequisiteFailed);
      final ready = batch.where((c) => !blocked.contains(c)).toList();
      if (ready.isEmpty) continue;
      await send(
        ready,
        () => store.insertAttributions([for (final c in ready) c.row]),
      );
    }

    return outcomes;
  }

  static List<List<PublishingChange>> _byChapter(
    List<PublishingChange> changes,
  ) {
    final groups = <int?, List<PublishingChange>>{};
    for (final c in changes) {
      (groups[c.chapterId] ??= []).add(c);
    }
    return groups.values.toList();
  }
}
