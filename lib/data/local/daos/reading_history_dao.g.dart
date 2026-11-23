// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_history_dao.dart';

// ignore_for_file: type=lint
mixin _$ReadingHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalChaptersTable get localChapters => attachedDatabase.localChapters;
  $LocalShlokasTable get localShlokas => attachedDatabase.localShlokas;
  $ReadingHistoryTable get readingHistory => attachedDatabase.readingHistory;
  ReadingHistoryDaoManager get managers => ReadingHistoryDaoManager(this);
}

class ReadingHistoryDaoManager {
  final _$ReadingHistoryDaoMixin _db;
  ReadingHistoryDaoManager(this._db);
  $$LocalChaptersTableTableManager get localChapters =>
      $$LocalChaptersTableTableManager(_db.attachedDatabase, _db.localChapters);
  $$LocalShlokasTableTableManager get localShlokas =>
      $$LocalShlokasTableTableManager(_db.attachedDatabase, _db.localShlokas);
  $$ReadingHistoryTableTableManager get readingHistory =>
      $$ReadingHistoryTableTableManager(
        _db.attachedDatabase,
        _db.readingHistory,
      );
}
