import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/local/daos/settings_dao.dart';
import 'package:gitartha/data/local/database/app_database.dart';
import 'package:gitartha/data/local/database/tables/reading_progress.dart';
import 'package:gitartha/data/local/local_database_providers.dart';
import 'package:gitartha/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:gitartha/features/authentication/presentation/providers/member_access_provider.dart';

import '../../data/local/test_database.dart';
import 'fake_auth_repository.dart';

/// Mandatory: signing out (or losing the session) must never delete the
/// on-device scripture cache or any personal data.
void main() {
  late AppDatabase db;
  late FakeAuthRepository repo;
  late ProviderContainer container;

  /// Every local table, row by row. Compared as JSON: Drift data classes
  /// compare list columns (key_topics) by identity.
  Future<Map<String, List<Map<String, dynamic>>>> snapshot() async => {
    'local_chapters': (await db.select(db.localChapters).get())
        .map((r) => r.toJson())
        .toList(),
    'local_shlokas': (await db.select(db.localShlokas).get())
        .map((r) => r.toJson())
        .toList(),
    'reflections': (await db.select(db.reflections).get())
        .map((r) => r.toJson())
        .toList(),
    'personal_notes': (await db.select(db.personalNotes).get())
        .map((r) => r.toJson())
        .toList(),
    'bookmarks': (await db.select(db.bookmarks).get())
        .map((r) => r.toJson())
        .toList(),
    'reading_progress': (await db.select(db.readingProgress).get())
        .map((r) => r.toJson())
        .toList(),
    'reading_history': (await db.select(db.readingHistory).get())
        .map((r) => r.toJson())
        .toList(),
    'local_settings': (await db.select(db.localSettings).get())
        .map((r) => r.toJson())
        .toList(),
    'sync_metadata': (await db.select(db.syncMetadata).get())
        .map((r) => r.toJson())
        .toList(),
  };

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() async {
    db = openTestDatabase();
    repo = FakeAuthRepository(
      restoredUser: editor,
      members: {
        editor.id: membership(editor, isAccessible: true),
        reader.id: membership(reader, isAccessible: false),
      },
    );
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    container.listen(authStatusProvider, (_, _) {});

    final local = container.read(localDatabaseRepositoryProvider);
    final shlokas = await seedChapter(db, 2);
    final id = shlokas.first.id;
    await local.addReflection(shlokaId: id, answer: 'My answer');
    await local.createNote(shlokaId: id, title: 'Mine', content: 'A note');
    await local.addBookmark(id);
    await local.recordShlokaOpened(id);
    await local.markShloka(id, ReadingStatus.studied);
    await local.setSetting(LocalSettingKeys.themeMode, 'dark');
    await db.syncMetadataDao.setValue('shlokas.last_pulled_at', '2026-01-01');
    await settle();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('every local table is populated before the test', () async {
    final before = await snapshot();
    expect(
      before.values.every((rows) => rows.isNotEmpty),
      isTrue,
      reason: '$before',
    );
  });

  test('logout keeps all local data', () async {
    final before = await snapshot();
    await container.read(authControllerProvider.notifier).signOut();
    await settle();
    expect(container.read(authStatusProvider), AuthStatus.signedOut);
    expect(await snapshot(), before);
  });

  test(
    'session expiry, membership loss and switching users keep it too',
    () async {
      final before = await snapshot();
      final auth = container.read(authControllerProvider.notifier);

      repo.expireSession();
      await settle();
      await auth.signIn(email: reader.email!, password: 'pw-reader');
      await settle();
      repo.members.remove(reader.id);
      container.invalidate(memberAccessProvider);
      await settle();
      expect(container.read(authStatusProvider), AuthStatus.membershipMissing);
      await auth.signOut();
      await settle();

      expect(await snapshot(), before);
    },
  );
}
