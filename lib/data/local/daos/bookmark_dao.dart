import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/bookmarks.dart';

part 'bookmark_dao.g.dart';

/// Bookmarked shlokas. One bookmark per shloka at a time.
@DriftAccessor(tables: [Bookmarks])
class BookmarkDao extends DatabaseAccessor<AppDatabase>
    with _$BookmarkDaoMixin {
  BookmarkDao(super.attachedDatabase);

  /// Bookmarks [shlokaId] and returns the bookmark. If it is already
  /// bookmarked, the existing bookmark is returned unchanged; there is never
  /// a duplicate.
  Future<Bookmark> addBookmark(String shlokaId) => transaction(() async {
    await into(bookmarks).insert(
      BookmarksCompanion.insert(
        id: attachedDatabase.newId(),
        shlokaId: shlokaId,
        createdAt: attachedDatabase.now(),
      ),
      onConflict: DoNothing(target: [bookmarks.shlokaId]),
    );
    return (await getBookmark(shlokaId))!;
  });

  /// Removes the bookmark on [shlokaId]. Returns false if there was none.
  Future<bool> removeBookmark(String shlokaId) async =>
      await (delete(
        bookmarks,
      )..where((b) => b.shlokaId.equals(shlokaId))).go() >
      0;

  Future<Bookmark?> getBookmark(String shlokaId) => (select(
    bookmarks,
  )..where((b) => b.shlokaId.equals(shlokaId))).getSingleOrNull();

  Future<bool> isBookmarked(String shlokaId) async =>
      await getBookmark(shlokaId) != null;

  Stream<bool> watchIsBookmarked(String shlokaId) =>
      (select(bookmarks)..where((b) => b.shlokaId.equals(shlokaId)))
          .watchSingleOrNull()
          .map((b) => b != null);

  SimpleSelectStatement<$BookmarksTable, Bookmark> _newestFirst() =>
      select(bookmarks)..orderBy([
        (b) => OrderingTerm.desc(b.createdAt),
        (b) => OrderingTerm.desc(b.rowId),
      ]);

  /// All bookmarks, newest first.
  Future<List<Bookmark>> getBookmarks() => _newestFirst().get();

  Stream<List<Bookmark>> watchBookmarks() => _newestFirst().watch();
}
