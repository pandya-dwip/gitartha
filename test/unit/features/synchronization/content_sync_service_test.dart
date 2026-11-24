import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/local/daos/sync_metadata_dao.dart';
import 'package:gitartha/data/local/database/app_database.dart';
import 'package:gitartha/data/local/repositories/local_database_repository.dart';
import 'package:gitartha/features/synchronization/data/content_sync_service.dart';
import 'package:gitartha/features/synchronization/domain/sync_result.dart';

import '../../data/local/test_database.dart';
import 'fake_content_remote.dart';

void main() {
  late TestClock clock;
  late AppDatabase db;
  late LocalDatabaseRepository local;
  late FakeContentRemote remote;

  final s11 = FakeContentRemote.shlokaId(1, 1);
  final s12 = FakeContentRemote.shlokaId(1, 2);
  final s21 = FakeContentRemote.shlokaId(2, 1);

  ContentSyncService service({
    int pageSize = 500,
    Duration overlap = const Duration(minutes: 10),
  }) => ContentSyncService(
    database: db,
    remote: remote,
    config: SyncConfig(pageSize: pageSize, overlap: overlap),
  );

  Future<SyncResult> sync({int pageSize = 500, Duration? overlap}) => service(
    pageSize: pageSize,
    overlap: overlap ?? const Duration(minutes: 10),
  ).sync();

  /// Two chapters, two sources, three verses, two attributions.
  void seedRemote() {
    remote
      ..putChapter(1)
      ..putChapter(2)
      ..putSource(1, license: 'Public domain')
      ..putSource(2)
      ..putShloka(1, 1)
      ..putShloka(1, 2, hindiNote: null, lifeLesson: null)
      ..putShloka(2, 1)
      ..putAttribution(1, s11, 1, 'english_meaning')
      ..putAttribution(2, s12, 2, 'hindi_meaning');
  }

  /// Moves the server clock well past the overlap window, so the next
  /// incremental run only sees what is written afterwards.
  void later() =>
      remote.serverNow = remote.serverNow.add(const Duration(hours: 2));

  Future<String?> meta(String key) => db.syncMetadataDao.getValue(key);

  Future<Map<String, String>> checkpoint() async => {
    for (final e in await db.syncMetadataDao.getAll())
      if (e.key.startsWith('content_cursor.') ||
          e.key == SyncMetadataKeys.lastSuccessfulContentSyncAt ||
          e.key == SyncMetadataKeys.contentSyncProtocol)
        e.key: e.value,
  };

  Future<int> count(TableInfo<Table, dynamic> table) async {
    final n = countAll();
    return (await (db.selectOnly(table)..addColumns([n])).getSingle()).read(n)!;
  }

  Future<Map<String, int>> cacheCounts() async => {
    'chapters': await count(db.localChapters),
    'sources': await count(db.localContentSources),
    'shlokas': await count(db.localShlokas),
    'attributions': await count(db.localShlokaSourceAttributions),
  };

  /// Every personal table, row by row (JSON: deep equality).
  Future<Map<String, List<Map<String, dynamic>>>> personal() async => {
    'reflections': [
      for (final r in await db.select(db.reflections).get()) r.toJson(),
    ],
    'notes': [
      for (final r in await db.select(db.personalNotes).get()) r.toJson(),
    ],
    'bookmarks': [
      for (final r in await db.select(db.bookmarks).get()) r.toJson(),
    ],
    'progress': [
      for (final r in await db.select(db.readingProgress).get()) r.toJson(),
    ],
    'history': [
      for (final r in await db.select(db.readingHistory).get()) r.toJson(),
    ],
    'settings': [
      for (final r in await db.select(db.localSettings).get()) r.toJson(),
    ],
  };

  Future<void> seedPersonal(String shlokaId) async {
    await local.addReflection(shlokaId: shlokaId, answer: 'My answer');
    await local.createNote(
      shlokaId: shlokaId,
      title: 'Mine',
      content: 'A note',
    );
    await local.createNote(content: 'A note about nothing in particular');
    await local.addBookmark(shlokaId);
    await local.recordShlokaOpened(shlokaId);
    await local.markShloka(shlokaId, ReadingStatus.studied);
    await local.setSetting(LocalSettingKeys.themeMode, 'dark');
  }

  setUp(() {
    clock = TestClock();
    db = openTestDatabase(clock: clock);
    local = LocalDatabaseRepository(db);
    remote = FakeContentRemote();
  });
  tearDown(() => db.close());

  group('first sync', () {
    test(
      'downloads all four tables in dependency order, preserving every field',
      () async {
        seedRemote();
        final result = await sync();

        expect(result.status, SyncStatus.success);
        expect(result.isFullSync, isTrue);
        expect(result.changedLocalContent, isTrue);
        expect(result[SyncTable.chapters].inserted, 2);
        expect(result[SyncTable.contentSources].inserted, 2);
        expect(result[SyncTable.shlokas].inserted, 3);
        expect(result[SyncTable.attributions].inserted, 2);

        // Dependency order of the first request per table.
        final order = <SyncTable>[];
        for (final c in remote.calls) {
          if (!order.contains(c.table)) order.add(c.table);
        }
        expect(order, [
          SyncTable.chapters,
          SyncTable.contentSources,
          SyncTable.shlokas,
          SyncTable.attributions,
        ]);
        // A full sync has no lower bound (tombstones included).
        expect(remote.calls.first.since, isNull);

        final v11 = (await local.getShloka(s11))!;
        expect(v11.id, s11, reason: 'server id kept');
        expect(v11.chapterId, 1);
        expect(v11.reference, '1.1');
        expect(v11.hindiMeaningNote, 'TEST hindi meaning note');
        expect(v11.sanskritText, 'TEST sanskrit');
        expect(v11.transliteration, 'TEST transliteration');
        expect(v11.hindiMeaning, 'TEST hindi');
        expect(v11.englishMeaning, 'TEST english');
        expect(v11.context, 'TEST context');
        expect(v11.spiritualMeaning, 'TEST spiritual');
        expect(v11.reflectionQuestion, 'TEST question?');
        expect(
          v11.updatedAt,
          DateTime.parse(
            remote.rows[SyncTable.shlokas]![s11]!['updated_at'] as String,
          ),
        );

        final v12 = (await local.getShloka(s12))!;
        expect(v12.hindiMeaningNote, isNull, reason: 'null stays null');
        expect(v12.lifeLesson, isNull);

        final ch1 = (await local.getChapter(1))!;
        expect(ch1.keyTopics, ['TEST topic A', 'TEST topic B']);
        expect(ch1.introduction, isNull);
        expect(ch1.overview, 'TEST overview 1');

        final src = (await local.getContentSource(uuid(0x5001)))!;
        expect(src.license, 'Public domain');

        final attr = await local.getSourceAttributionsForShloka(s11);
        expect(attr.single.sourceId, src.id);
        expect(attr.single.contentSection, 'english_meaning');

        expect(await meta(SyncMetadataKeys.contentSyncState), 'success');
        expect(
          await meta(SyncMetadataKeys.lastSuccessfulContentSyncAt),
          isNotNull,
        );
        expect(
          await meta(SyncMetadataKeys.contentCursor('shlokas')),
          isNotNull,
        );
      },
    );

    test('includes tombstones, which stay out of reading queries', () async {
      seedRemote();
      remote.setDeleted(SyncTable.shlokas, s21);
      final result = await sync();

      expect(result[SyncTable.shlokas].softDeleted, 1);
      expect(await local.getShlokasForChapter(2), isEmpty);
      expect(
        (await local.getShloka(s21, includeDeleted: true))!.deletedAt,
        isNotNull,
      );
    });

    test('an empty remote database is a successful no-change sync', () async {
      final result = await sync();
      expect(result.status, SyncStatus.noChanges);
      expect(result.succeeded, isTrue);
      expect(await cacheCounts(), {
        'chapters': 0,
        'sources': 0,
        'shlokas': 0,
        'attributions': 0,
      });
      expect(
        await meta(SyncMetadataKeys.lastSuccessfulContentSyncAt),
        isNotNull,
      );
    });
  });

  group('incremental sync', () {
    test('no changes → noChanges, nothing rewritten', () async {
      seedRemote();
      await sync();
      final before = await cacheCounts();

      final result = await sync();
      expect(result.status, SyncStatus.noChanges);
      expect(result.isFullSync, isFalse);
      expect(result.changedLocalContent, isFalse);
      expect(await cacheCounts(), before);
      // Every table queried from (checkpoint − overlap), never from scratch.
      final second = remote.calls.skip(remote.calls.length - 4);
      expect(second.every((c) => c.since != null), isTrue);
    });

    test('downloads only rows changed since the checkpoint', () async {
      seedRemote();
      await sync();
      later();
      remote
        ..putChapter(2, english: 'TEST chapter two, revised')
        ..putShloka(1, 2, english: 'TEST revised', hindiNote: 'TEST new note')
        ..putShloka(2, 2);
      // Zero overlap shows the exact window: rows at or after each table's
      // checkpoint. (`>=` re-reads the checkpoint row itself, harmlessly.)
      final result = await sync(overlap: Duration.zero);

      expect(result.status, SyncStatus.success);
      expect(
        result[SyncTable.chapters],
        const TableSyncCounts(downloaded: 1, updated: 1),
      );
      expect(
        result[SyncTable.shlokas],
        const TableSyncCounts(downloaded: 3, inserted: 1, updated: 1),
        reason: 's12, s22 changed; s21 is the checkpoint row; s11 not read',
      );
      expect(result[SyncTable.contentSources].downloaded, 1);
      expect(result[SyncTable.contentSources].changed, isFalse);
      expect(
        (await local.getChapter(2))!.englishName,
        'TEST chapter two, revised',
      );
      final v12 = (await local.getShloka(s12))!;
      expect(v12.englishMeaning, 'TEST revised');
      expect(v12.hindiMeaningNote, 'TEST new note');
      expect((await local.getShlokasForChapter(2)).length, 2);
    });

    test(
      'the overlap window catches a late commit with an older timestamp',
      () async {
        seedRemote();
        await sync();
        final cursor = DateTime.parse(
          (await meta(SyncMetadataKeys.contentCursor('shlokas')))!,
        );

        // A transaction that started 2 minutes before the checkpoint but
        // committed after the last sync: its updated_at is older than rows
        // already seen.
        remote.putShloka(3, 1, at: cursor.subtract(const Duration(minutes: 2)));
        remote.putChapter(3, at: cursor.subtract(const Duration(minutes: 3)));

        final withoutOverlap = await sync(overlap: Duration.zero);
        expect(
          await local.getShloka(FakeContentRemote.shlokaId(3, 1)),
          isNull,
          reason: 'without overlap the row is missed',
        );
        expect(withoutOverlap.status, SyncStatus.noChanges);

        final withOverlap = await sync();
        expect(withOverlap[SyncTable.shlokas].inserted, 1);
        expect(
          await local.getShloka(FakeContentRemote.shlokaId(3, 1)),
          isNotNull,
        );
      },
    );

    test(
      'a stored checkpoint from another protocol version forces a full sync',
      () async {
        seedRemote();
        await sync();
        await db.syncMetadataDao.setValue(
          SyncMetadataKeys.contentSyncProtocol,
          '0',
        );
        final result = await sync();
        expect(result.isFullSync, isTrue);
        expect(result.status, SyncStatus.noChanges);
      },
    );
  });

  group('idempotency and pagination', () {
    test('repeated syncs never duplicate rows or change values', () async {
      seedRemote();
      await sync();
      final rows = await db.select(db.localShlokas).get();
      final before = [for (final r in rows) r.toJson()];
      final counts = await cacheCounts();

      for (var i = 0; i < 3; i++) {
        // Force full re-downloads too: the same rows applied again.
        await db.syncMetadataDao.deleteValue(
          SyncMetadataKeys.contentSyncProtocol,
        );
        final r = await sync();
        expect(r.status, SyncStatus.noChanges);
      }
      expect(await cacheCounts(), counts);
      expect([
        for (final r in await db.select(db.localShlokas).get()) r.toJson(),
      ], before);
    });

    test(
      'pages through equal timestamps by id, without gaps or repeats',
      () async {
        remote
          ..putChapter(1)
          ..freeze = true; // every verse gets the same updated_at
        for (var v = 1; v <= 25; v++) {
          remote.putShloka(1, v);
        }
        final result = await sync(pageSize: 4);

        expect(result[SyncTable.shlokas].downloaded, 25);
        expect(result[SyncTable.shlokas].inserted, 25);
        expect((await local.getShlokasForChapter(1)).length, 25);

        final pages = remote.calls
            .where((c) => c.table == SyncTable.shlokas)
            .toList();
        expect(pages.length, 8, reason: '7 pages of ≤4 rows + 1 empty page');
        // Keyset positions strictly increase (deterministic order).
        final ids = [for (final p in pages.skip(1)) p.after!.id as String];
        expect(ids, [...ids]..sort());
        expect(ids.toSet().length, ids.length);
      },
    );

    test(
      'a server row cap below the page size cannot truncate a table',
      () async {
        remote.putChapter(1);
        for (var v = 1; v <= 10; v++) {
          remote.putShloka(1, v);
        }
        remote.serverRowCap = 3;
        final result = await sync(pageSize: 500);
        expect(result[SyncTable.shlokas].inserted, 10);
      },
    );
  });

  group('tombstones and restoration', () {
    test(
      'soft delete hides the verse, keeps the row and personal data',
      () async {
        seedRemote();
        await sync();
        await seedPersonal(s11);
        final before = await personal();

        later();
        remote.setDeleted(SyncTable.shlokas, s11);
        final result = await sync();

        expect(result[SyncTable.shlokas].softDeleted, 1);
        expect(result.softDeletedTotal, 1);
        expect(await local.getShloka(s11), isNull);
        expect((await local.getShlokasForChapter(1)).map((s) => s.id), [s12]);
        expect(
          (await local.getShloka(s11, includeDeleted: true))!.deletedAt,
          isNotNull,
        );
        expect(await personal(), before);
        expect(await local.isBookmarked(s11), isTrue);
      },
    );

    test('restoration revives the same row, without duplicates', () async {
      seedRemote();
      remote.setDeleted(SyncTable.shlokas, s11);
      await sync();
      later();
      remote.setDeleted(SyncTable.shlokas, s11, restore: true);
      final result = await sync();

      expect(result[SyncTable.shlokas].restored, 1);
      expect((await local.getShloka(s11))!.deletedAt, isNull);
      expect(await count(db.localShlokas), 3);
    });

    test(
      'a deleted chapter hides its verses; sources soft-delete too',
      () async {
        seedRemote();
        await sync();
        later();
        remote
          ..setDeleted(SyncTable.chapters, 2)
          ..setDeleted(SyncTable.contentSources, uuid(0x5002));
        final result = await sync();

        expect(result.softDeletedTotal, 2);
        expect((await local.getChapters()).map((c) => c.id), [1]);
        expect(await local.getShlokasForChapter(2), isEmpty);
        expect((await local.getContentSources()).length, 1);
      },
    );
  });

  group('attributions', () {
    test(
      'new attributions arrive incrementally; re-downloads are harmless',
      () async {
        seedRemote();
        await sync();
        remote.putAttribution(3, s21, 1, 'context');
        final result = await sync(); // within overlap: a1, a2 re-downloaded too
        expect(result[SyncTable.attributions].inserted, 1);
        expect(result[SyncTable.attributions].downloaded, 3);
        expect(await count(db.localShlokaSourceAttributions), 3);
      },
    );

    test(
      'server-side deletions apply on a full sync only (documented limit)',
      () async {
        seedRemote();
        await sync();
        remote.deleteAttribution(2);

        await sync();
        expect(
          await count(db.localShlokaSourceAttributions),
          2,
          reason: 'incremental sync cannot see a physical delete',
        );

        await db.syncMetadataDao.deleteValue(
          SyncMetadataKeys.contentSyncProtocol,
        );
        final full = await sync();
        expect(full[SyncTable.attributions].removed, 1);
        expect(await local.getSourceAttributionsForShloka(s12), isEmpty);
        expect((await local.getSourceAttributionsForShloka(s11)).length, 1);
      },
    );
  });

  group('local rows', () {
    test(
      'locally imported rows: server versions replace them; local-only rows stay',
      () async {
        // Rows from the bundled JSON import carry the 1970 sentinel timestamp.
        final sentinel = DateTime.utc(1970);
        await local.cacheContent(
          chapters: [
            chapterFixture(1, updatedAt: sentinel),
            chapterFixture(5, updatedAt: sentinel),
          ],
          shlokas: [
            shlokaFixture(
              1,
              1,
              id: s11,
              updatedAt: sentinel,
              englishMeaning: 'TEST imported',
            ),
          ],
        );
        seedRemote();
        final result = await sync();

        expect(result[SyncTable.shlokas].updated, 1);
        expect((await local.getShloka(s11))!.englishMeaning, 'TEST english');
        expect(
          await local.getChapter(5),
          isNotNull,
          reason: 'never on the server: untouched',
        );
      },
    );

    test(
      'a verse slot held by another cached row is freed, not a permanent failure',
      () async {
        final stray = uuid(0xBEEF);
        await local.cacheContent(
          chapters: [chapterFixture(1, updatedAt: DateTime.utc(1970))],
          shlokas: [
            shlokaFixture(1, 2, id: stray, updatedAt: DateTime.utc(1970)),
          ],
        );
        await local.addReflection(shlokaId: stray, answer: 'Kept');
        seedRemote();
        final result = await sync();

        expect(result.succeeded, isTrue);
        expect((await local.getShlokaByVerse(1, 2))!.id, s12);
        final parked = (await local.getShloka(stray, includeDeleted: true))!;
        expect(parked.deletedAt, isNotNull);
        expect(parked.verseNumber, greaterThan(1000000));
        expect(
          (await local.getReflectionsForShloka(stray)).single.answer,
          'Kept',
        );
      },
    );
  });

  group('failures never advance the checkpoint', () {
    late Map<String, String> good;
    late Map<String, int> goodCounts;

    Future<void> succeedOnce() async {
      seedRemote();
      expect((await sync()).succeeded, isTrue);
      good = await checkpoint();
      goodCounts = await cacheCounts();
      later();
      remote
        ..putChapter(3)
        ..putShloka(3, 1)
        ..putShloka(1, 1, english: 'TEST changed');
    }

    Future<void> expectUnchanged() async {
      expect(await checkpoint(), good);
      expect(await cacheCounts(), goodCounts);
      expect((await local.getShloka(s11))!.englishMeaning, 'TEST english');
      expect(await meta(SyncMetadataKeys.contentSyncState), 'failed');
    }

    test('network failure before fetching', () async {
      await succeedOnce();
      remote.failOnCall = remote.calls.length + 1;
      final r = await sync();
      expect(r.status, SyncStatus.offline);
      expect(r.message, contains('Offline'));
      expect(await meta(SyncMetadataKeys.lastContentSyncError), 'offline');
      await expectUnchanged();
    });

    test('failure in the middle of pagination', () async {
      await succeedOnce();
      // Chapters page 1 succeeds, page 2 fails.
      remote.failOnCall = remote.calls.length + 2;
      final r = await sync(pageSize: 1);
      expect(r.succeeded, isFalse);
      expect(await local.getChapter(3), isNull, reason: 'page 1 not applied');
      await expectUnchanged();
    });

    test('failure while downloading a dependent table', () async {
      await succeedOnce();
      remote.failOnTable = SyncTable.attributions;
      remote.failWith = const SyncException(SyncFailureKind.serviceUnavailable);
      final r = await sync();
      expect(r.status, SyncStatus.failed);
      expect(r.failure, SyncFailureKind.serviceUnavailable);
      await expectUnchanged();
    });

    test('session expiry during the run', () async {
      await succeedOnce();
      remote.failOnTable = SyncTable.shlokas;
      remote.failWith = const SyncException(SyncFailureKind.unauthenticated);
      final r = await sync();
      expect(r.status, SyncStatus.unauthenticated);
      await expectUnchanged();
    });

    test('local transaction failure rolls back the whole batch', () async {
      await succeedOnce();
      // An attribution to a verse that does not exist violates a foreign key
      // in the middle of applying (after chapters and shlokas were written).
      remote.putAttribution(9, uuid(0xDEAD), 1, 'context');
      final r = await sync();
      expect(r.failure, SyncFailureKind.localDatabase);
      expect(await local.getChapter(3), isNull, reason: 'rolled back');
      await expectUnchanged();
    });

    test('malformed remote data is rejected before writing', () async {
      await succeedOnce();
      remote.rows[SyncTable.shlokas]![s11]!.remove('hindi_meaning_note');
      final r = await sync();
      expect(r.failure, SyncFailureKind.invalidRemoteData);
      await expectUnchanged();
    });

    test('cancellation (e.g. sign-out) applies nothing', () async {
      await succeedOnce();
      final start = remote.calls.length;
      final r = await service().sync(
        isCancelled: () => remote.calls.length > start + 1,
      );
      expect(r.failure, SyncFailureKind.cancelled);
      await expectUnchanged();
    });

    test('an interrupted run is simply retried next time', () async {
      await succeedOnce();
      remote.failOnCall = remote.calls.length + 3; // "app closed" mid-run
      expect((await sync()).succeeded, isFalse);
      remote.failOnCall = null;
      final retry = await sync();
      expect(retry.status, SyncStatus.success);
      expect(await local.getChapter(3), isNotNull);
      expect((await local.getShloka(s11))!.englishMeaning, 'TEST changed');
      expect(await meta(SyncMetadataKeys.contentSyncState), 'success');
      expect(await meta(SyncMetadataKeys.lastContentSyncError), isNull);
    });
  });

  test('concurrent calls share one run', () async {
    seedRemote();
    final svc = service();
    final a = svc.sync();
    final b = svc.sync();
    expect(svc.isRunning, isTrue);
    final results = await Future.wait([a, b]);
    expect(identical(results[0], results[1]), isTrue);
    expect(
      remote.calls.length,
      8,
      reason: 'one run: 4 tables × (data + empty page)',
    );
    expect(svc.isRunning, isFalse);
    expect(await count(db.localShlokas), 3);
  });

  test('personal data survives every kind of content change', () async {
    seedRemote();
    await sync();
    await seedPersonal(s11);
    await seedPersonal(s12);
    final before = await personal();
    expect(before.values.every((rows) => rows.isNotEmpty), isTrue);

    final scenarios = <String, void Function()>{
      'add a chapter': () => remote.putChapter(3),
      'update a chapter': () => remote.putChapter(1, english: 'TEST new name'),
      'add a shloka': () => remote.putShloka(3, 1),
      'update a shloka': () =>
          remote.putShloka(1, 1, english: 'TEST new meaning'),
      'soft-delete a shloka': () => remote.setDeleted(SyncTable.shlokas, s11),
      'restore a shloka': () =>
          remote.setDeleted(SyncTable.shlokas, s11, restore: true),
      'update a source': () => remote.putSource(1, name: 'TEST renamed'),
      'add an attribution': () => remote.putAttribution(5, s11, 2, 'context'),
    };
    for (final MapEntry(key: name, value: change) in scenarios.entries) {
      later();
      change();
      final r = await sync();
      expect(r.status, SyncStatus.success, reason: name);
      expect(await personal(), before, reason: name);
    }
    // And a full resync on top.
    await db.syncMetadataDao.deleteValue(SyncMetadataKeys.contentSyncProtocol);
    await sync();
    expect(await personal(), before);
  });
}
