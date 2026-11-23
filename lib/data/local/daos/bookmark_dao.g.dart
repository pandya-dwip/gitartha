// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_dao.dart';

// ignore_for_file: type=lint
mixin _$BookmarkDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalChaptersTable get localChapters => attachedDatabase.localChapters;
  $LocalShlokasTable get localShlokas => attachedDatabase.localShlokas;
  $BookmarksTable get bookmarks => attachedDatabase.bookmarks;
  BookmarkDaoManager get managers => BookmarkDaoManager(this);
}

class BookmarkDaoManager {
  final _$BookmarkDaoMixin _db;
  BookmarkDaoManager(this._db);
  $$LocalChaptersTableTableManager get localChapters =>
      $$LocalChaptersTableTableManager(_db.attachedDatabase, _db.localChapters);
  $$LocalShlokasTableTableManager get localShlokas =>
      $$LocalShlokasTableTableManager(_db.attachedDatabase, _db.localShlokas);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db.attachedDatabase, _db.bookmarks);
}
