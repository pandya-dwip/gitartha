// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shloka_dao.dart';

// ignore_for_file: type=lint
mixin _$ShlokaDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalChaptersTable get localChapters => attachedDatabase.localChapters;
  $LocalShlokasTable get localShlokas => attachedDatabase.localShlokas;
  ShlokaDaoManager get managers => ShlokaDaoManager(this);
}

class ShlokaDaoManager {
  final _$ShlokaDaoMixin _db;
  ShlokaDaoManager(this._db);
  $$LocalChaptersTableTableManager get localChapters =>
      $$LocalChaptersTableTableManager(_db.attachedDatabase, _db.localChapters);
  $$LocalShlokasTableTableManager get localShlokas =>
      $$LocalShlokasTableTableManager(_db.attachedDatabase, _db.localShlokas);
}
