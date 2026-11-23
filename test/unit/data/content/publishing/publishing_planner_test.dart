import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/content/content_constants.dart';
import 'package:gitartha/data/content/content_ids.dart';
import 'package:gitartha/data/content/importers/chapter_content_importer.dart';
import 'package:gitartha/data/content/models/shloka_content_model.dart';
import 'package:gitartha/data/content/publishing/mappers/shloka_supabase_mapper.dart';
import 'package:gitartha/data/content/publishing/publishing_executor.dart';
import 'package:gitartha/data/content/publishing/publishing_models.dart';

import '../content_fixtures.dart';
import 'fake_remote_store.dart';
import 'publishing_fixtures.dart';

void main() {
  late FakeRemoteStore remote;

  setUp(() => remote = newRemote());

  List<ChangeKind> kinds(PublishingPlan plan, PublishTable table) =>
      plan.forTable(table).map((c) => c.kind).toList();

  Future<void> publish(PublishingPlan plan) async {
    final outcomes = await const PublishingExecutor().execute(plan, remote);
    expect(outcomes.every((o) => o.succeeded), isTrue);
  }

  group('change detection', () {
    test('new content is planned as inserts with deterministic ids', () async {
      final plan = await planAgainst(
        repository({1: approvedChapterOne()}),
        remote,
      );
      expect(plan.canPublish, isTrue);
      expect(kinds(plan, PublishTable.chapters), [ChangeKind.insert]);
      expect(kinds(plan, PublishTable.contentSources), [ChangeKind.insert]);
      expect(
        kinds(plan, PublishTable.shlokas),
        List.filled(3, ChangeKind.insert),
      );
      expect(
        kinds(plan, PublishTable.shlokaSourceAttributions),
        List.filled(9, ChangeKind.insert),
      );

      final shloka = plan.forTable(PublishTable.shlokas).first;
      expect(shloka.recordId, ContentIds.shloka('chapter_01_verse_001'));
      expect(shloka.contentKey, 'chapter_01_verse_001');
      // Only content columns: no generated reference, no timestamps.
      expect(shloka.row.keys, ShlokaSupabaseMapper.contentColumns);
      expect(shloka.row['hindi_meaning_note'], 'TEST wording note');
      expect(shloka.row['hindi_meaning'], 'TEST हिन्दी अर्थ');
      expect(shloka.contentHash, hasLength(64));
    });

    test('identical content is unchanged and produces no writes', () async {
      final source = repository({1: approvedChapterOne()});
      await publish(await planAgainst(source, remote));

      // The database bumped its own timestamps; they are not compared.
      final again = await planAgainst(source, remote);
      expect(again.writes, isEmpty);
      expect(kinds(again, PublishTable.chapters), [ChangeKind.unchanged]);
      expect(
        kinds(again, PublishTable.shlokas),
        List.filled(3, ChangeKind.unchanged),
      );
      expect(
        kinds(again, PublishTable.shlokaSourceAttributions),
        List.filled(9, ChangeKind.unchanged),
      );
    });

    test('a changed chapter is an update naming the changed fields', () async {
      await publish(
        await planAgainst(repository({1: approvedChapterOne()}), remote),
      );
      final edited = approvedChapterOne();
      (edited['chapter']! as Map)['overview'] = 'TEST revised overview';
      (edited['chapter']! as Map)['key_topics'] = ['TEST topic A'];

      final plan = await planAgainst(repository({1: edited}), remote);
      final chapter = plan.forTable(PublishTable.chapters).single;
      expect(chapter.kind, ChangeKind.update);
      expect(chapter.changedFields, ['overview', 'key_topics']);
      expect(plan.writes, [chapter]);
    });

    test('a changed shloka, and a changed Hindi wording note alone', () async {
      await publish(
        await planAgainst(repository({1: approvedChapterOne()}), remote),
      );
      final verses = [for (var v = 1; v <= 3; v++) approvedVerse(1, v)];
      verses[0]['english_meaning'] = 'TEST revised meaning';
      verses[1]['hindi_meaning_note'] = 'TEST revised wording note';

      final plan = await planAgainst(
        repository({1: approvedChapterOne(verses)}),
        remote,
      );
      final shlokas = plan.forTable(PublishTable.shlokas);
      expect(shlokas[0].changedFields, ['english_meaning']);
      expect(shlokas[1].changedFields, ['hindi_meaning_note']);
      expect(shlokas[2].kind, ChangeKind.unchanged);
    });

    test(
      'a new attribution is inserted; a removed one is never deleted',
      () async {
        await publish(
          await planAgainst(repository({1: approvedChapterOne()}), remote),
        );
        final verses = [for (var v = 1; v <= 3; v++) approvedVerse(1, v)];
        verses[0]['source_attributions'] = [
          ...requiredAttributions(),
          {'source_id': testSourceId, 'content_section': 'hindi_meaning_note'},
        ];
        final plan = await planAgainst(
          repository({1: approvedChapterOne(verses)}),
          remote,
        );
        final attributionInserts = plan
            .forTable(PublishTable.shlokaSourceAttributions)
            .where((c) => c.kind == ChangeKind.insert)
            .toList();
        expect(
          attributionInserts.single.row['content_section'],
          'hindi_meaning_note',
        );
        // The shloka's own row is unchanged; its content hash is not.
        final first = plan.forTable(PublishTable.shlokas).first;
        expect(first.kind, ChangeKind.unchanged);
      },
    );

    test('remote-only attributions are reported, never deleted', () async {
      final source = repository({1: approvedChapterOne()});
      await publish(await planAgainst(source, remote));
      final shlokaId = ContentIds.shloka('chapter_01_verse_001');
      remote.seed('shloka_source_attributions', {
        'id': '00000000-0000-4000-8000-0000000000ff',
        'shloka_id': shlokaId,
        'source_id': ContentIds.source(testSourceId),
        'content_section': 'context',
      });

      final plan = await planAgainst(source, remote);
      final extra = plan
          .forTable(PublishTable.shlokaSourceAttributions)
          .singleWhere((c) => c.reason == PublishReason.remoteOnlyAttribution);
      expect(extra.kind, ChangeKind.skip);
      expect(plan.writes, isEmpty);
    });

    test('soft-deleted remote rows are skipped, never restored', () async {
      final source = repository({1: approvedChapterOne()});
      await publish(await planAgainst(source, remote));
      final id = ContentIds.shloka('chapter_01_verse_002');
      remote.tables['shlokas']![id]!['deleted_at'] = '2026-02-01T00:00:00Z';
      remote.tables['shlokas']![id]!['english_meaning'] = 'TEST old text';

      final plan = await planAgainst(source, remote);
      final skipped = plan
          .forTable(PublishTable.shlokas)
          .singleWhere((c) => c.recordId == id);
      expect(skipped.kind, ChangeKind.skip);
      expect(skipped.reason, PublishReason.remoteSoftDeleted);
      expect(plan.writes, isEmpty);
      // Its attributions are left alone as well.
      expect(
        plan
            .forTable(PublishTable.shlokaSourceAttributions)
            .where((c) => c.row['shloka_id'] == id)
            .every((c) => c.kind != ChangeKind.insert),
        isTrue,
      );
    });

    test('a soft-deleted chapter skips its verses too', () async {
      final source = repository({1: approvedChapterOne()});
      await publish(await planAgainst(source, remote));
      remote.tables['chapters']!['1']!['deleted_at'] = '2026-02-01T00:00:00Z';
      final edited = approvedChapterOne([
        for (var v = 1; v <= 3; v++)
          approvedVerse(1, v, englishMeaning: 'TEST new'),
      ]);

      final plan = await planAgainst(repository({1: edited}), remote);
      expect(kinds(plan, PublishTable.chapters), [ChangeKind.skip]);
      expect(plan.forTable(PublishTable.shlokas).map((c) => c.reason).toSet(), {
        PublishReason.dependencySkipped,
      });
      expect(plan.writes, isEmpty);
    });

    test(
      'a verse slot owned by another id is an error that blocks publishing',
      () async {
        remote.seed('chapters', {'id': 1, 'sanskrit_name': 'x'});
        remote.seed('shlokas', {
          'id': '00000000-0000-4000-8000-0000000000aa',
          'chapter_id': 1,
          'verse_number': 2,
        });
        final plan = await planAgainst(
          repository({1: approvedChapterOne()}),
          remote,
        );
        final conflict = plan
            .forTable(PublishTable.shlokas)
            .singleWhere((c) => c.kind == ChangeKind.error);
        expect(conflict.reason, PublishReason.verseSlotConflict);
        expect(plan.canPublish, isFalse);
        expect(
          () => const PublishingExecutor().execute(plan, remote),
          throwsStateError,
        );
      },
    );

    test('structural errors block the plan before any remote read', () async {
      final plan = await planAgainst(
        repository({
          1: approvedChapterOne([approvedVerse(1, 1), approvedVerse(1, 1)]),
        }),
        remote,
      );
      expect(plan.isBlocked, isTrue);
      expect(plan.changes, isEmpty);
      expect(remote.log.where((l) => l.startsWith('read ')), isEmpty);
    });

    test('only complete, approved, sourced content is planned', () async {
      final plan = await planAgainst(
        repository({
          1: approvedChapterOne([
            approvedVerse(1, 1),
            verse(1, 2), // complete but draft
            verse(1, 3, status: 'approved', blank: {'context'}),
          ]),
          2: chapterFile(chapterMeta(2), [approvedVerse(2, 1)]), // no names
        }),
        remote,
      );
      expect(plan.forTable(PublishTable.chapters).map((c) => c.recordId), [1]);
      expect(plan.forTable(PublishTable.shlokas).map((c) => c.contentKey), [
        'chapter_01_verse_001',
      ]);
    });

    test('unapproved chapter metadata publishes names only', () async {
      final plan = await planAgainst(
        repository({
          1: chapterFile(chapterMeta(1, named: true), [approvedVerse(1, 1)]),
        }),
        remote,
      );
      final row = plan.forTable(PublishTable.chapters).single.row;
      expect(row['english_name'], 'TEST english name 1');
      expect(row['overview'], isNull);
      expect(row['key_topics'], isNull);
    });
  });

  group('scope', () {
    test('a chapter scope touches only that chapter and its sources', () async {
      final plan = await planAgainst(
        repository({
          1: approvedChapterOne(),
          2: chapterFile(chapterMeta(2, complete: true, status: 'approved'), [
            approvedVerse(2, 1),
          ]),
        }, sources: sourcesFixture(includeUnlicensed: true)),
        remote,
        scope: const PublishingScope.chapter(2),
      );
      expect(plan.forTable(PublishTable.chapters).map((c) => c.recordId), [2]);
      expect(
        plan.forTable(PublishTable.contentSources).map((c) => c.contentKey),
        [testSourceId], // the unlicensed source is never published
      );
    });

    test(
      '--verse publishes one verse and leaves a differing chapter alone',
      () async {
        await publish(
          await planAgainst(repository({1: approvedChapterOne()}), remote),
        );
        final edited = approvedChapterOne([
          approvedVerse(1, 1, englishMeaning: 'TEST new 1'),
          approvedVerse(1, 2, englishMeaning: 'TEST new 2'),
          approvedVerse(1, 3),
        ]);
        (edited['chapter']! as Map)['overview'] = 'TEST revised overview';

        final plan = await planAgainst(
          repository({1: edited}),
          remote,
          scope: const PublishingScope.chapter(1, verseNumber: 2),
        );
        expect(plan.forTable(PublishTable.shlokas).map((c) => c.contentKey), [
          'chapter_01_verse_002',
        ]);
        final chapter = plan.forTable(PublishTable.chapters).single;
        expect(chapter.kind, ChangeKind.skip);
        expect(chapter.reason, PublishReason.outsideVerseScope);
        expect(plan.writes.map((c) => c.contentKey), ['chapter_01_verse_002']);
      },
    );
  });

  group('identifier mapping', () {
    test('an id that is already a UUID is preserved', () {
      const uuid = '3f2a9c1e-7b4d-4e8a-9c0b-1d2e3f4a5b6c';
      expect(ContentIds.shloka(uuid), uuid);
      expect(ContentIds.source(uuid), uuid);
    });

    test('readable ids map deterministically and without collisions', () {
      final ids = {
        for (var c = 1; c <= 18; c++)
          for (var v = 1; v <= GitaContent.expectedVerseCounts[c]!; v++)
            ContentIds.shloka(GitaContent.shlokaContentId(c, v)),
      };
      expect(ids, hasLength(700));
      expect(
        ContentIds.shloka('chapter_01_verse_041'),
        '8c555087-1c57-50db-9632-7bbd1e10a472',
      );
      expect(ContentIds.source(testSourceId), ContentIds.source(testSourceId));
      expect(ids.contains(ContentIds.source(testSourceId)), isFalse);
    });

    test('the publisher and the local importer use the same ids', () {
      final verse = ShlokaContentModel.fromJson(verse_(1, 41));
      expect(
        ShlokaSupabaseMapper.toRow(1, verse)['id'],
        ChapterContentImporter.shlokaRow(1, verse).id,
      );
    });
  });
}

Map<String, dynamic> verse_(int c, int v) =>
    verse(c, v).cast<String, dynamic>();
