import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/content/content_ids.dart';
import 'package:gitartha/data/content/importers/import_result.dart';
import 'package:gitartha/data/content/publishing/publishing_executor.dart';
import 'package:gitartha/data/content/publishing/publishing_models.dart';
import 'package:gitartha/data/content/publishing/publishing_result.dart';
import 'package:gitartha/data/content/publishing/remote_content_store.dart';
import 'package:gitartha/data/content/selection/content_selection.dart';

import '../content_fixtures.dart';
import 'fake_remote_store.dart';
import 'publishing_fixtures.dart';

void main() {
  late FakeRemoteStore remote;

  setUp(() => remote = newRemote());

  Future<List<WriteOutcome>> run(PublishingPlan plan) =>
      const PublishingExecutor().execute(plan, remote);

  PublishingResult resultOf(PublishingPlan plan, List<WriteOutcome> outcomes) =>
      PublishingResult(
          operationId: 'test',
          target: remote.targetDescription,
          scope: plan.scope,
          dryRun: false,
          startedAt: DateTime.utc(2026),
        )
        ..plan = plan
        ..validation = plan.validation
        ..outcomes = outcomes;

  test(
    'writes in dependency order: chapters, sources, shlokas, attributions',
    () async {
      final plan = await planAgainst(
        repository({1: approvedChapterOne()}),
        remote,
      );
      final outcomes = await run(plan);

      expect(outcomes.every((o) => o.succeeded), isTrue);
      expect(remote.writes.map((w) => w.split(' ').take(2).join(' ')), [
        'upsert chapters',
        'upsert content_sources',
        'upsert shlokas',
        'insert attributions',
      ]);
      expect(remote.count('chapters'), 1);
      expect(remote.count('shlokas'), 3);
      expect(remote.count('shloka_source_attributions'), 9);
      expect(
        remote.tables['shlokas']![ContentIds.shloka(
          'chapter_01_verse_001',
        )]!['reference'],
        '1.1',
      );
    },
  );

  test('repeated publishing creates no duplicates and sends nothing', () async {
    final source = repository({1: approvedChapterOne()});
    await run(await planAgainst(source, remote));
    final writesAfterFirst = remote.writes.length;

    for (var i = 0; i < 3; i++) {
      final plan = await planAgainst(source, remote);
      expect(plan.writes, isEmpty);
      expect(await run(plan), isEmpty);
    }
    expect(remote.writes.length, writesAfterFirst);
    expect(remote.count('shlokas'), 3);
    expect(remote.count('shloka_source_attributions'), 9);
  });

  test(
    'an update keeps created_at and sends only the changed record',
    () async {
      await run(
        await planAgainst(repository({1: approvedChapterOne()}), remote),
      );
      final id = ContentIds.shloka('chapter_01_verse_002');
      final before = Map.of(remote.tables['shlokas']![id]!);

      final plan = await planAgainst(
        repository({
          1: approvedChapterOne([
            approvedVerse(1, 1),
            approvedVerse(1, 2, englishMeaning: 'TEST revised'),
            approvedVerse(1, 3),
          ]),
        }),
        remote,
      );
      expect(plan.writes.map((c) => c.recordId), [id]);
      await run(plan);

      final after = remote.tables['shlokas']![id]!;
      expect(after['english_meaning'], 'TEST revised');
      expect(after['created_at'], before['created_at']);
      expect(after['updated_at'], isNot(before['updated_at']));
      // The other verses were not touched (their updated_at is unchanged).
      final untouched =
          remote.tables['shlokas']![ContentIds.shloka('chapter_01_verse_001')]!;
      expect(untouched['updated_at'], isNot(after['updated_at']));
    },
  );

  test('a failed prerequisite stops its dependents; others continue', () async {
    remote.failWrite = (table, rows) =>
        table == 'chapters' && rows.first['id'] == 1
        ? const RemoteStoreException(
            RemoteErrorKind.foreignKeyViolation,
            'simulated',
            code: '23503',
          )
        : null;
    final plan = await planAgainst(
      repository({
        1: approvedChapterOne(),
        2: chapterFile(chapterMeta(2, complete: true, status: 'approved'), [
          approvedVerse(2, 1),
        ]),
      }),
      remote,
    );
    final outcomes = await run(plan);

    final failed = outcomes.where((o) => !o.succeeded).toList();
    expect(failed.first.change.contentKey, 'chapter 1');
    expect(failed.first.error, contains('foreignKeyViolation'));
    expect(
      failed
          .where(
            (o) =>
                o.change.chapterId == 1 &&
                o.change.table != PublishTable.chapters,
          )
          .every((o) => o.reason == PublishReason.prerequisiteFailed),
      isTrue,
    );
    // Chapter 2 was independent and was published.
    expect(remote.tables['chapters']!.keys, ['2']);
    expect(remote.count('shlokas'), 1);

    final result = resultOf(plan, outcomes);
    expect(result.status, PublishingStatus.partiallyCompleted);
    expect(result.recordsFailed, failed.length);
  });

  test('a partial failure can be retried safely', () async {
    final source = repository({1: approvedChapterOne()});
    remote.failWrite = (table, rows) => table == 'shloka_source_attributions'
        ? const RemoteStoreException(RemoteErrorKind.network, 'offline')
        : null;
    final first = await run(await planAgainst(source, remote));
    expect(first.where((o) => !o.succeeded), hasLength(9));
    expect(remote.count('shlokas'), 3);
    expect(remote.count('shloka_source_attributions'), 0);

    remote.failWrite = null;
    final retry = await planAgainst(source, remote);
    expect(retry.writes.map((c) => c.table).toSet(), {
      PublishTable.shlokaSourceAttributions,
    });
    await run(retry);
    expect(remote.count('shlokas'), 3);
    expect(remote.count('shloka_source_attributions'), 9);
  });

  test(
    'an RLS rejection stops the run; nothing further is attempted',
    () async {
      final plan = await planAgainst(
        repository({1: approvedChapterOne()}),
        remote,
      );
      remote.members[editorId] = false; // permission revoked after the check

      final outcomes = await run(plan);
      expect(outcomes.first.error, contains('permissionDenied'));
      // Everything after the rejection was not attempted (stopped, or blocked
      // by the failed chapter insert).
      expect(outcomes.skip(1).every((o) => !o.attempted), isTrue);
      expect(
        outcomes.map((o) => o.reason).toSet(),
        containsAll([
          PublishReason.runStopped,
          PublishReason.prerequisiteFailed,
        ]),
      );
      expect(remote.writes, hasLength(1)); // only the rejected request
      expect(remote.count('chapters'), 0);
      expect(resultOf(plan, outcomes).status, PublishingStatus.failed);
    },
  );

  test('content missing from the files is never deleted', () async {
    await run(await planAgainst(repository({1: approvedChapterOne()}), remote));

    final plan = await planAgainst(
      repository({
        1: approvedChapterOne([approvedVerse(1, 1)]),
      }),
      remote,
    );
    expect(plan.writes, isEmpty);
    await run(plan);
    expect(remote.count('shlokas'), 3);
    expect(
      remote.tables['shlokas']!.values.every((s) => s['deleted_at'] == null),
      isTrue,
    );
  });

  test('soft-deleted rows stay soft-deleted', () async {
    final source = repository({1: approvedChapterOne()});
    await run(await planAgainst(source, remote));
    final id = ContentIds.shloka('chapter_01_verse_003');
    remote.tables['shlokas']![id]!['deleted_at'] = '2026-03-01T00:00:00Z';

    await run(await planAgainst(source, remote));
    expect(
      remote.tables['shlokas']![id]!['deleted_at'],
      '2026-03-01T00:00:00Z',
    );
  });

  test(
    'status: success, or success_with_warnings when records were left out',
    () async {
      final clean = await planAgainst(
        repository({1: approvedChapterOne()}),
        remote,
      );
      expect(
        resultOf(clean, await run(clean)).status,
        PublishingStatus.success,
      );

      final source = repository({
        1: approvedChapterOne([
          approvedVerse(1, 1),
          verse(1, 2),
        ]), // 1.2 is a draft
      });
      final plan = await planAgainst(source, newRemote());
      final selection = const ContentSelector().select(
        await strictReport(source),
        mode: ImportMode.approved,
      );
      final result = resultOf(plan, const [])
        ..rejectedByValidation = selection.rejected;
      expect(
        selection.rejected.map((r) => r.recordId),
        contains('chapter_01_verse_002'),
      );
      expect(result.status, PublishingStatus.successWithWarnings);
    },
  );
}
