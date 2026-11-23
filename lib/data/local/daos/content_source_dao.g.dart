// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_source_dao.dart';

// ignore_for_file: type=lint
mixin _$ContentSourceDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalContentSourcesTable get localContentSources =>
      attachedDatabase.localContentSources;
  $LocalChaptersTable get localChapters => attachedDatabase.localChapters;
  $LocalShlokasTable get localShlokas => attachedDatabase.localShlokas;
  $LocalShlokaSourceAttributionsTable get localShlokaSourceAttributions =>
      attachedDatabase.localShlokaSourceAttributions;
  ContentSourceDaoManager get managers => ContentSourceDaoManager(this);
}

class ContentSourceDaoManager {
  final _$ContentSourceDaoMixin _db;
  ContentSourceDaoManager(this._db);
  $$LocalContentSourcesTableTableManager get localContentSources =>
      $$LocalContentSourcesTableTableManager(
        _db.attachedDatabase,
        _db.localContentSources,
      );
  $$LocalChaptersTableTableManager get localChapters =>
      $$LocalChaptersTableTableManager(_db.attachedDatabase, _db.localChapters);
  $$LocalShlokasTableTableManager get localShlokas =>
      $$LocalShlokasTableTableManager(_db.attachedDatabase, _db.localShlokas);
  $$LocalShlokaSourceAttributionsTableTableManager
  get localShlokaSourceAttributions =>
      $$LocalShlokaSourceAttributionsTableTableManager(
        _db.attachedDatabase,
        _db.localShlokaSourceAttributions,
      );
}
