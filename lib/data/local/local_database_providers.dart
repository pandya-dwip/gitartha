import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/app_database.dart';
import 'repositories/local_database_repository.dart';

/// The single [AppDatabase] for the app.
///
/// It is created on first read (which needs an initialized Flutter binding,
/// for `path_provider`) and closed when the owning
/// [ProviderContainer] is disposed. It is not auto-disposed, so the app never
/// opens a second connection to the same file. `main()` reads it eagerly and
/// awaits [AppDatabase.ensureInitialized] before the first frame.
///
/// Tests override it with an in-memory database:
///
/// ```dart
/// appDatabaseProvider.overrideWith((ref) {
///   final db = AppDatabase(NativeDatabase.memory());
///   ref.onDispose(db.close);
///   return db;
/// })
/// ```
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.persistent();
  ref.onDispose(db.close);
  return db;
});

/// The local data API for feature code. Use this, not [appDatabaseProvider],
/// outside the data layer.
final localDatabaseRepositoryProvider = Provider<LocalDatabaseRepository>(
  (ref) => LocalDatabaseRepository(ref.watch(appDatabaseProvider)),
);

// --- Cached scripture, read from SQLite -------------------------------------
//
// Reading features use these, never Supabase. They are Drift watch queries,
// so they re-emit by themselves whenever content sync commits new rows: the
// local database is the single source of truth for what is displayed.

/// Live (not soft-deleted) cached chapters, in chapter order.
final localChaptersProvider = StreamProvider<List<LocalChapter>>(
  (ref) => ref.watch(localDatabaseRepositoryProvider).watchChapters(),
);

/// Live cached shlokas of a chapter, in verse order.
final localShlokasForChapterProvider =
    StreamProvider.family<List<LocalShloka>, int>(
      (ref, chapterId) => ref
          .watch(localDatabaseRepositoryProvider)
          .watchShlokasForChapter(chapterId),
    );

/// Per-chapter live verse counts and reading progress.
final chapterProgressSummariesProvider =
    StreamProvider<List<ChapterProgressSummary>>(
      (ref) => ref
          .watch(localDatabaseRepositoryProvider)
          .watchChapterProgressSummaries(),
    );
