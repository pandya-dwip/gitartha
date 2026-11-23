import 'package:drift/drift.dart' show Value;

export 'package:drift/drift.dart' show Value;

import '../daos/reading_progress_dao.dart';
import '../database/app_database.dart';
import '../database/tables/reading_history.dart';
import '../database/tables/reading_progress.dart';

export '../daos/reading_progress_dao.dart' show ChapterProgressSummary;
export '../daos/settings_dao.dart' show LocalSettingKeys;
export '../database/app_database.dart'
    show
        Bookmark,
        LocalChapter,
        LocalContentSource,
        LocalShloka,
        LocalShlokaSourceAttribution,
        PersonalNote,
        ReadingHistoryEntry,
        ReadingProgressEntry,
        Reflection;
export '../database/tables/reading_history.dart' show ReadingActivity;
export '../database/tables/reading_progress.dart' show ReadingStatus;

/// The app's single entry point to on-device data.
///
/// Feature code (providers, later domain repositories) talks to this class
/// and never to Drift tables or DAOs directly. It delegates to the DAOs and
/// adds the operations that span several tables, each in one transaction.
///
/// Everything here is local. Nothing is sent to Supabase, and personal data
/// (reflections, notes, bookmarks, progress, history, settings) never will be.
///
/// Errors are not swallowed. Invalid input throws [ArgumentError], and
/// constraint violations surface as the underlying SQLite exception.
class LocalDatabaseRepository {
  LocalDatabaseRepository(this._db);

  final AppDatabase _db;

  /// Openings of the same shloka closer together than this are logged once
  /// in reading history (progress `last_opened_at` is still updated), so that
  /// re-entering a screen or a rebuild can't flood the log.
  static const Duration openedHistoryDedupWindow = Duration(minutes: 1);

  // ---------------------------------------------------------------------------
  // Scripture (cached shared content)
  // ---------------------------------------------------------------------------

  Future<List<LocalChapter>> getChapters() => _db.chapterDao.getChapters();

  Stream<List<LocalChapter>> watchChapters() => _db.chapterDao.watchChapters();

  Future<LocalChapter?> getChapter(int chapterId) =>
      _db.chapterDao.getChapter(chapterId);

  Future<List<LocalShloka>> getShlokasForChapter(int chapterId) =>
      _db.shlokaDao.getShlokasForChapter(chapterId);

  Stream<List<LocalShloka>> watchShlokasForChapter(int chapterId) =>
      _db.shlokaDao.watchShlokasForChapter(chapterId);

  /// A live shloka by its id. With [includeDeleted], also returns a retired
  /// shloka, for example to show the verse behind an old reflection.
  Future<LocalShloka?> getShloka(
    String shlokaId, {
    bool includeDeleted = false,
  }) => _db.shlokaDao.getShloka(shlokaId, includeDeleted: includeDeleted);

  Future<LocalShloka?> getShlokaByVerse(int chapterId, int verseNumber) =>
      _db.shlokaDao.getShlokaByVerse(chapterId, verseNumber);

  Future<List<LocalShloka>> searchShlokas(String query, {int limit = 50}) =>
      _db.shlokaDao.searchShlokas(query, limit: limit);

  /// Writes content received from Supabase into the cache, chapters first,
  /// all in one transaction. Rows keep their server ids and timestamps, and
  /// an older version never overwrites a newer one. Personal data is never
  /// touched. Used by the future sync milestone.
  Future<void> cacheContent({
    Iterable<LocalChapter> chapters = const [],
    Iterable<LocalShloka> shlokas = const [],
  }) => _db.transaction(() async {
    await _db.chapterDao.upsertChapters(chapters);
    await _db.shlokaDao.upsertShlokas(shlokas);
  });

  /// Live content sources (translations, editions, commentaries), by name.
  Future<List<LocalContentSource>> getContentSources() =>
      _db.contentSourceDao.getSources();

  Future<LocalContentSource?> getContentSource(String sourceId) =>
      _db.contentSourceDao.getSource(sourceId);

  /// Which sources each section of [shlokaId] came from, for attribution
  /// display.
  Future<List<LocalShlokaSourceAttribution>> getSourceAttributionsForShloka(
    String shlokaId,
  ) => _db.contentSourceDao.getAttributionsForShloka(shlokaId);

  // ---------------------------------------------------------------------------
  // Reflections
  // ---------------------------------------------------------------------------

  /// Saves a new, separate reflection. Older reflections are never changed.
  Future<Reflection> addReflection({
    required String shlokaId,
    required String answer,
  }) => _db.reflectionDao.addReflection(shlokaId: shlokaId, answer: answer);

  Future<Reflection?> updateReflection(String reflectionId, String answer) =>
      _db.reflectionDao.updateReflection(reflectionId, answer);

  Future<bool> deleteReflection(String reflectionId) =>
      _db.reflectionDao.deleteReflection(reflectionId);

  Future<Reflection?> getReflection(String reflectionId) =>
      _db.reflectionDao.getReflection(reflectionId);

  /// Oldest first.
  Future<List<Reflection>> getReflectionsForShloka(String shlokaId) =>
      _db.reflectionDao.getReflectionsForShloka(shlokaId);

  Stream<List<Reflection>> watchReflectionsForShloka(String shlokaId) =>
      _db.reflectionDao.watchReflectionsForShloka(shlokaId);

  /// Newest first.
  Future<List<Reflection>> getRecentReflections({int limit = 20}) =>
      _db.reflectionDao.getRecentReflections(limit: limit);

  // ---------------------------------------------------------------------------
  // Personal notes
  // ---------------------------------------------------------------------------

  Future<PersonalNote> createNote({
    String? shlokaId,
    String? title,
    required String content,
  }) => _db.personalNoteDao.createNote(
    shlokaId: shlokaId,
    title: title,
    content: content,
  );

  /// Only the given fields change. `title: const Value(null)` clears it.
  Future<PersonalNote?> updateNote(
    String noteId, {
    Value<String?> title = const Value.absent(),
    String? content,
  }) => _db.personalNoteDao.updateNote(noteId, title: title, content: content);

  Future<bool> deleteNote(String noteId) =>
      _db.personalNoteDao.deleteNote(noteId);

  Future<PersonalNote?> getNote(String noteId) =>
      _db.personalNoteDao.getNote(noteId);

  Future<List<PersonalNote>> getNotesForShloka(String shlokaId) =>
      _db.personalNoteDao.getNotesForShloka(shlokaId);

  Stream<List<PersonalNote>> watchNotesForShloka(String shlokaId) =>
      _db.personalNoteDao.watchNotesForShloka(shlokaId);

  Future<List<PersonalNote>> getAllNotes() => _db.personalNoteDao.getAllNotes();

  Future<List<PersonalNote>> searchNotes(String query) =>
      _db.personalNoteDao.searchNotes(query);

  // ---------------------------------------------------------------------------
  // Bookmarks
  // ---------------------------------------------------------------------------

  /// Idempotent: bookmarking twice keeps the single existing bookmark.
  Future<Bookmark> addBookmark(String shlokaId) =>
      _db.bookmarkDao.addBookmark(shlokaId);

  Future<bool> removeBookmark(String shlokaId) =>
      _db.bookmarkDao.removeBookmark(shlokaId);

  Future<bool> isBookmarked(String shlokaId) =>
      _db.bookmarkDao.isBookmarked(shlokaId);

  Stream<bool> watchIsBookmarked(String shlokaId) =>
      _db.bookmarkDao.watchIsBookmarked(shlokaId);

  /// Newest first.
  Future<List<Bookmark>> getBookmarks() => _db.bookmarkDao.getBookmarks();

  Stream<List<Bookmark>> watchBookmarks() => _db.bookmarkDao.watchBookmarks();

  // ---------------------------------------------------------------------------
  // Reading progress and history
  // ---------------------------------------------------------------------------

  /// Call once when the user opens a shloka (on navigation, not in `build`).
  ///
  /// Creates or updates its progress record (`opened`, `last_opened_at`)
  /// and logs an `opened` activity, unless one was logged for this shloka
  /// within [openedHistoryDedupWindow]. Never marks the shloka read or
  /// studied.
  Future<ReadingProgressEntry> recordShlokaOpened(String shlokaId) =>
      _db.transaction(() async {
        final progress = await _db.readingProgressDao.recordOpening(shlokaId);
        final last = await _db.readingHistoryDao.getLatestActivity(
          shlokaId,
          ReadingActivity.opened,
        );
        final now = _db.now();
        if (last == null ||
            now.difference(last.occurredAt) >= openedHistoryDedupWindow) {
          await _db.readingHistoryDao.recordActivity(
            shlokaId,
            ReadingActivity.opened,
            occurredAt: now,
          );
        }
        return progress;
      });

  /// Explicitly marks a shloka `read`, `studied` or `reflected` and logs the
  /// matching activity, in one transaction. The status never moves
  /// backwards (see `ReadingProgressDao`). Saving a reflection does **not**
  /// call this automatically; the caller decides.
  Future<ReadingProgressEntry> markShloka(
    String shlokaId,
    ReadingStatus status,
  ) => _db.transaction(() async {
    final progress = await _db.readingProgressDao.updateStatus(
      shlokaId,
      status,
    );
    await _db.readingHistoryDao.recordActivity(
      shlokaId,
      ReadingActivity.forStatus(status),
      occurredAt: progress.updatedAt,
    );
    return progress;
  });

  Future<ReadingProgressEntry?> getProgress(String shlokaId) =>
      _db.readingProgressDao.getProgress(shlokaId);

  Stream<ReadingProgressEntry?> watchProgress(String shlokaId) =>
      _db.readingProgressDao.watchProgress(shlokaId);

  Future<List<ReadingProgressEntry>> getAllProgress() =>
      _db.readingProgressDao.getAllProgress();

  Future<List<ChapterProgressSummary>> getChapterProgressSummaries() =>
      _db.readingProgressDao.getChapterProgressSummaries();

  Stream<List<ChapterProgressSummary>> watchChapterProgressSummaries() =>
      _db.readingProgressDao.watchChapterProgressSummaries();

  Future<List<ReadingHistoryEntry>> getRecentHistory({int limit = 50}) =>
      _db.readingHistoryDao.getRecentHistory(limit: limit);

  Future<List<ReadingHistoryEntry>> getHistoryForShloka(String shlokaId) =>
      _db.readingHistoryDao.getHistoryForShloka(shlokaId);

  /// `from <= occurred_at < to`, oldest first.
  Future<List<ReadingHistoryEntry>> getHistoryBetween(
    DateTime from,
    DateTime to,
  ) => _db.readingHistoryDao.getHistoryBetween(from, to);

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  Future<void> setSetting(String key, Object? value) =>
      _db.settingsDao.setValue(key, value);

  Future<Object?> getSetting(String key) => _db.settingsDao.getValue(key);

  Stream<Object?> watchSetting(String key) => _db.settingsDao.watchValue(key);

  Future<bool> deleteSetting(String key) => _db.settingsDao.deleteValue(key);

  Future<Map<String, Object?>> getAllSettings() => _db.settingsDao.getAll();

  Future<String?> getStringSetting(String key) =>
      _db.settingsDao.getString(key);

  Future<bool?> getBoolSetting(String key) => _db.settingsDao.getBool(key);

  Future<int?> getIntSetting(String key) => _db.settingsDao.getInt(key);

  Future<double?> getDoubleSetting(String key) =>
      _db.settingsDao.getDouble(key);
}
