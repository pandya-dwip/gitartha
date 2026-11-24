import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/local_database_providers.dart';
import '../../../../data/local/repositories/local_database_repository.dart';

// Personal data: device-local only (SQLite). Nothing here talks to
// Supabase, and nothing in sync touches these tables.

// Per-verse providers are autoDispose: each holds a live database watch,
// so it must be released when no screen shows that verse (otherwise
// every verse ever opened keeps a query running for the whole session).

final isBookmarkedProvider = StreamProvider.autoDispose.family<bool, String>(
  (ref, shlokaId) =>
      ref.watch(localDatabaseRepositoryProvider).watchIsBookmarked(shlokaId),
);

/// Newest first.
final bookmarksProvider = StreamProvider<List<Bookmark>>(
  (ref) => ref.watch(localDatabaseRepositoryProvider).watchBookmarks(),
);

final progressProvider = StreamProvider.autoDispose
    .family<ReadingProgressEntry?, String>(
      (ref, shlokaId) =>
          ref.watch(localDatabaseRepositoryProvider).watchProgress(shlokaId),
    );

/// Oldest first (dated answers to this verse's reflection question).
final reflectionsForShlokaProvider = StreamProvider.autoDispose
    .family<List<Reflection>, String>(
      (ref, shlokaId) => ref
          .watch(localDatabaseRepositoryProvider)
          .watchReflectionsForShloka(shlokaId),
    );

/// Newest first.
final allReflectionsProvider = StreamProvider<List<Reflection>>(
  (ref) => ref.watch(localDatabaseRepositoryProvider).watchRecentReflections(),
);

final notesForShlokaProvider = StreamProvider.autoDispose
    .family<List<PersonalNote>, String>(
      (ref, shlokaId) => ref
          .watch(localDatabaseRepositoryProvider)
          .watchNotesForShloka(shlokaId),
    );

/// All notes, including free-standing ones; most recently edited first.
final allNotesProvider = StreamProvider<List<PersonalNote>>(
  (ref) => ref.watch(localDatabaseRepositoryProvider).watchAllNotes(),
);

/// The personal actions screens may take. Thin, but keeps the rules in one
/// place (e.g. what saving a reflection does to progress).
class PersonalActions {
  const PersonalActions(this._repo);

  final LocalDatabaseRepository _repo;

  /// Records a meaningful "opened" event (de-duplicated by the repository).
  /// Call on navigation to a verse, never from `build`.
  Future<void> openShloka(String shlokaId) =>
      _repo.recordShlokaOpened(shlokaId);

  Future<void> toggleBookmark(String shlokaId, {required bool bookmarked}) =>
      bookmarked ? _repo.removeBookmark(shlokaId) : _repo.addBookmark(shlokaId);

  /// Explicit progress (`read`, `studied`); never moves backwards.
  Future<void> mark(String shlokaId, ReadingStatus status) =>
      _repo.markShloka(shlokaId, status);

  /// A new, separate dated answer; also marks the verse `reflected`.
  Future<void> addReflection(String shlokaId, String answer) async {
    await _repo.addReflection(shlokaId: shlokaId, answer: answer.trim());
    await _repo.markShloka(shlokaId, ReadingStatus.reflected);
  }

  /// Edits that answer in place (no new record).
  Future<void> updateReflection(String id, String answer) =>
      _repo.updateReflection(id, answer.trim());

  Future<void> deleteReflection(String id) => _repo.deleteReflection(id);

  /// Creates a note ([noteId] null) or updates it. Blank titles are stored
  /// as no title.
  Future<void> saveNote({
    String? noteId,
    String? shlokaId,
    required String title,
    required String content,
  }) async {
    final t = title.trim().isEmpty ? null : title.trim();
    if (noteId == null) {
      await _repo.createNote(
        shlokaId: shlokaId,
        title: t,
        content: content.trim(),
      );
    } else {
      await _repo.updateNote(noteId, title: Value(t), content: content.trim());
    }
  }

  Future<void> deleteNote(String id) => _repo.deleteNote(id);
}

final personalActionsProvider = Provider<PersonalActions>(
  (ref) => PersonalActions(ref.watch(localDatabaseRepositoryProvider)),
);
