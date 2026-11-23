// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_note_dao.dart';

// ignore_for_file: type=lint
mixin _$PersonalNoteDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalChaptersTable get localChapters => attachedDatabase.localChapters;
  $LocalShlokasTable get localShlokas => attachedDatabase.localShlokas;
  $PersonalNotesTable get personalNotes => attachedDatabase.personalNotes;
  PersonalNoteDaoManager get managers => PersonalNoteDaoManager(this);
}

class PersonalNoteDaoManager {
  final _$PersonalNoteDaoMixin _db;
  PersonalNoteDaoManager(this._db);
  $$LocalChaptersTableTableManager get localChapters =>
      $$LocalChaptersTableTableManager(_db.attachedDatabase, _db.localChapters);
  $$LocalShlokasTableTableManager get localShlokas =>
      $$LocalShlokasTableTableManager(_db.attachedDatabase, _db.localShlokas);
  $$PersonalNotesTableTableManager get personalNotes =>
      $$PersonalNotesTableTableManager(_db.attachedDatabase, _db.personalNotes);
}
