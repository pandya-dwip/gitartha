// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reflection_dao.dart';

// ignore_for_file: type=lint
mixin _$ReflectionDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalChaptersTable get localChapters => attachedDatabase.localChapters;
  $LocalShlokasTable get localShlokas => attachedDatabase.localShlokas;
  $ReflectionsTable get reflections => attachedDatabase.reflections;
  ReflectionDaoManager get managers => ReflectionDaoManager(this);
}

class ReflectionDaoManager {
  final _$ReflectionDaoMixin _db;
  ReflectionDaoManager(this._db);
  $$LocalChaptersTableTableManager get localChapters =>
      $$LocalChaptersTableTableManager(_db.attachedDatabase, _db.localChapters);
  $$LocalShlokasTableTableManager get localShlokas =>
      $$LocalShlokasTableTableManager(_db.attachedDatabase, _db.localShlokas);
  $$ReflectionsTableTableManager get reflections =>
      $$ReflectionsTableTableManager(_db.attachedDatabase, _db.reflections);
}
