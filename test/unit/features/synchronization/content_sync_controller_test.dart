import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/local/database/app_database.dart';
import 'package:gitartha/data/local/local_database_providers.dart';
import 'package:gitartha/features/authentication/domain/entities/auth_failure.dart';
import 'package:gitartha/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:gitartha/features/authentication/presentation/providers/member_access_provider.dart';
import 'package:gitartha/features/synchronization/data/content_sync_service.dart';
import 'package:gitartha/features/synchronization/domain/sync_result.dart';
import 'package:gitartha/features/synchronization/presentation/providers/content_sync_provider.dart';

import '../../data/local/test_database.dart';
import '../authentication/fake_auth_repository.dart';
import 'fake_content_remote.dart';

void main() {
  late TestClock clock;
  late AppDatabase db;
  late FakeContentRemote remote;
  late ProviderContainer container;

  void start(FakeAuthRepository a, {bool withBackend = true}) {
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authRepositoryProvider.overrideWithValue(withBackend ? a : null),
        if (withBackend)
          contentRemoteDataSourceProvider.overrideWithValue(remote),
        syncConfigProvider.overrideWithValue(
          const SyncConfig(autoSyncMinInterval: Duration(minutes: 30)),
        ),
      ],
    );
    // As main() does: create the controller at startup.
    container.read(contentSyncProvider.notifier);
  }

  ContentSyncState state() => container.read(contentSyncProvider);
  ContentSyncController controller() =>
      container.read(contentSyncProvider.notifier);

  /// Waits for async work (auth stream, membership, Drift) to finish.
  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 400 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(done(), isTrue, reason: 'condition not reached');
  }

  Future<void> idle() =>
      Future<void>.delayed(const Duration(milliseconds: 100));

  setUp(() {
    clock = TestClock();
    db = openTestDatabase(clock: clock);
    remote = FakeContentRemote()
      ..putChapter(1)
      ..putShloka(1, 1)
      ..putShloka(1, 2);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  FakeAuthRepository member(bool editorAccess) => FakeAuthRepository(
    restoredUser: editorAccess ? editor : reader,
    members: {
      reader.id: membership(reader, isAccessible: false),
      editor.id: membership(editor, isAccessible: true),
    },
  );

  for (final isEditor in [false, true]) {
    test(
      '${isEditor ? 'editor' : 'read-only member'}: restored session syncs automatically',
      () async {
        start(member(isEditor));
        await until(() => state().status == SyncStatus.success);
        expect(
          container.read(authStatusProvider),
          isEditor ? AuthStatus.editor : AuthStatus.readOnly,
        );
        expect(state().lastSuccessfulSyncAt, isNotNull);
        expect(state().lastResult![SyncTable.shlokas].inserted, 2);
        expect((await db.shlokaDao.getShlokasForChapter(1)).length, 2);
      },
    );
  }

  test(
    'signed out: no network request; manual sync reports unauthenticated',
    () async {
      start(FakeAuthRepository());
      await idle();
      expect(remote.calls, isEmpty);
      final r = await controller().syncContentManually();
      expect(r.status, SyncStatus.unauthenticated);
      expect(remote.calls, isEmpty);
      expect(state().status, SyncStatus.unauthenticated);
    },
  );

  test('missing membership: no sync', () async {
    start(FakeAuthRepository(restoredUser: reader));
    await until(
      () => container.read(authStatusProvider) == AuthStatus.membershipMissing,
    );
    await idle();
    expect(remote.calls, isEmpty);
    expect(
      (await controller().syncContentManually()).status,
      SyncStatus.membershipUnavailable,
    );
    expect(remote.calls, isEmpty);
  });

  test('membership lookup error: no sync', () async {
    start(
      member(false)
        ..membershipFailure = const MembershipFailure(
          MembershipFailureKind.unavailable,
        ),
    );
    await until(
      () => container.read(authStatusProvider) == AuthStatus.membershipError,
    );
    await idle();
    expect(remote.calls, isEmpty);
  });

  test('no backend configured: offline, no crash', () async {
    start(FakeAuthRepository(), withBackend: false);
    final r = await controller().syncContentManually();
    expect(r.status, SyncStatus.offline);
  });

  test('signing in triggers a sync', () async {
    start(
      FakeAuthRepository(
        members: {reader.id: membership(reader, isAccessible: false)},
      ),
    );
    await idle();
    expect(remote.calls, isEmpty);
    await container
        .read(authControllerProvider.notifier)
        .signIn(email: reader.email!, password: 'pw-reader');
    await until(() => state().status == SyncStatus.success);
  });

  test(
    'automatic triggers respect the minimum interval; manual does not',
    () async {
      start(member(false));
      await until(() => state().status == SyncStatus.success);
      final afterFirst = remote.calls.length;

      clock.advance(const Duration(minutes: 10));
      await controller().onAppResumed();
      expect(remote.calls.length, afterFirst, reason: 'synced 10 minutes ago');

      clock.advance(const Duration(minutes: 25));
      await controller().onAppResumed();
      expect(remote.calls.length, greaterThan(afterFirst));
      final afterResume = remote.calls.length;

      final manual = await controller().syncContentManually();
      expect(manual.status, SyncStatus.noChanges);
      expect(remote.calls.length, greaterThan(afterResume));
    },
  );

  test('concurrent requests share one run', () async {
    remote.gate = Completer();
    start(member(false));
    await until(() => state().isRunning);
    final a = controller().syncContentManually();
    final b = controller().syncContentManually();
    await controller().onAppResumed(); // skipped: already running
    remote.gate!.complete();
    final results = await Future.wait([a, b]);
    expect(identical(results[0], results[1]), isTrue);
    // One run: chapters (data + empty page), sources (empty),
    // shlokas (data + empty), attributions (empty).
    expect(remote.calls.length, 6, reason: 'one run');
    expect(state().isRunning, isFalse);
  });

  test('signing out mid-sync cancels it; cache and data are kept', () async {
    // First, a completed sync to have a cache.
    start(member(false));
    await until(() => state().status == SyncStatus.success);
    remote.putChapter(2);
    clock.advance(const Duration(hours: 1));

    final before = remote.calls.length;
    remote.gate = Completer();
    final running = controller().syncContentManually();
    await until(() => remote.calls.length > before);
    await container.read(authControllerProvider.notifier).signOut();
    remote.gate!.complete();
    final r = await running;

    expect(r.failure, SyncFailureKind.cancelled);
    expect(state().status, SyncStatus.unauthenticated);
    expect(
      await db.chapterDao.getChapter(2),
      isNull,
      reason: 'nothing applied',
    );
    expect(
      (await db.shlokaDao.getShlokasForChapter(1)).length,
      2,
      reason: 'cache kept',
    );
  });

  test('SQLite-backed content providers refresh after a sync', () async {
    start(
      FakeAuthRepository(
        members: {reader.id: membership(reader, isAccessible: false)},
      ),
    );
    final chapters = <int>[];
    container.listen(localChaptersProvider, (_, next) {
      if (next.hasValue) chapters.add(next.value!.length);
    }, fireImmediately: true);
    final verses = container.listen(
      chapterProgressSummariesProvider,
      (_, _) {},
    );
    final chapterOne = container.listen(
      localShlokasForChapterProvider(1),
      (_, _) {},
    );
    await until(() => chapters.isNotEmpty);
    expect(
      chapters.last,
      0,
      reason: 'empty cache shown first, no network wait',
    );

    await container
        .read(authControllerProvider.notifier)
        .signIn(email: reader.email!, password: 'pw-reader');
    await until(() => state().status == SyncStatus.success);
    await until(() => chapters.last == 1);
    await until(() => chapterOne.read().value?.length == 2);
    expect(verses.read().value!.single.totalShlokas, 2);

    // An incremental change reaches the same providers.
    clock.advance(const Duration(hours: 1));
    remote.putShloka(1, 3);
    await controller().syncContentManually();
    await until(() => chapterOne.read().value?.length == 3);
    expect(verses.read().value!.single.totalShlokas, 3);
  });
}
