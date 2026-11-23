// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_progress_dao.dart';

// ignore_for_file: type=lint
mixin _$ReadingProgressDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalChaptersTable get localChapters => attachedDatabase.localChapters;
  $LocalShlokasTable get localShlokas => attachedDatabase.localShlokas;
  $ReadingProgressTable get readingProgress => attachedDatabase.readingProgress;
  ReadingProgressDaoManager get managers => ReadingProgressDaoManager(this);
}

class ReadingProgressDaoManager {
  final _$ReadingProgressDaoMixin _db;
  ReadingProgressDaoManager(this._db);
  $$LocalChaptersTableTableManager get localChapters =>
      $$LocalChaptersTableTableManager(_db.attachedDatabase, _db.localChapters);
  $$LocalShlokasTableTableManager get localShlokas =>
      $$LocalShlokasTableTableManager(_db.attachedDatabase, _db.localShlokas);
  $$ReadingProgressTableTableManager get readingProgress =>
      $$ReadingProgressTableTableManager(
        _db.attachedDatabase,
        _db.readingProgress,
      );
}
