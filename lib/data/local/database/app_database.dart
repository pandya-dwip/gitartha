import 'package:drift/drift.dart';

import '../../../core/errors/local_database_exception.dart';
import '../../../core/utils/uuid.dart';
import '../daos/bookmark_dao.dart';
import '../daos/chapter_dao.dart';
import '../daos/personal_note_dao.dart';
import '../daos/reading_history_dao.dart';
import '../daos/reading_progress_dao.dart';
import '../daos/reflection_dao.dart';
import '../daos/settings_dao.dart';
import '../daos/shloka_dao.dart';
import '../daos/sync_metadata_dao.dart';
import 'converters.dart';
import 'database_connection.dart';
import 'tables/bookmarks.dart';
import 'tables/local_chapters.dart';
import 'tables/local_settings.dart';
import 'tables/local_shlokas.dart';
import 'tables/personal_notes.dart';
import 'tables/reading_history.dart';
import 'tables/reading_progress.dart';
import 'tables/reflections.dart';
import 'tables/sync_metadata.dart';

part 'app_database.g.dart';

/// Returns the current time. Injected so tests can control time.
typedef Clock = DateTime Function();

/// Returns a new unique id for a record created on the device.
typedef IdGenerator = String Function();

DateTime _systemUtcNow() => DateTime.now().toUtc();

/// Gitartha's on-device SQLite database.
///
/// It holds two kinds of data:
///  * **cache:** `local_chapters`, `local_shlokas` and `sync_metadata`, a
///    copy of shared scripture from Supabase;
///  * **personal:** reflections, notes, bookmarks, reading progress and
///    history, and settings. These exist only on this device and are never
///    synchronized.
///
/// Create exactly one instance per app run (see `appDatabaseProvider`) and
/// [close] it when done.
@DriftDatabase(
  tables: [
    LocalChapters,
    LocalShlokas,
    Reflections,
    PersonalNotes,
    Bookmarks,
    ReadingProgress,
    ReadingHistory,
    LocalSettings,
    SyncMetadata,
  ],
  daos: [
    ChapterDao,
    ShlokaDao,
    ReflectionDao,
    PersonalNoteDao,
    BookmarkDao,
    ReadingProgressDao,
    ReadingHistoryDao,
    SettingsDao,
    SyncMetadataDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens a database on [executor]. Tests pass `NativeDatabase.memory()`.
  AppDatabase(super.executor, {Clock? clock, IdGenerator? idGenerator})
    : _clock = clock ?? _systemUtcNow,
      _idGenerator = idGenerator ?? generateUuidV4;

  /// The persistent on-device database (`gitartha.sqlite`).
  factory AppDatabase.persistent() => AppDatabase(openPersistentConnection());

  final Clock _clock;
  final IdGenerator _idGenerator;

  /// The current time, in UTC.
  DateTime now() => _clock().toUtc();

  /// A new id for a record created on the device.
  String newId() => _idGenerator();

  /// Bump this when the schema changes, and add a migration step for it.
  static const int currentSchemaVersion = 1;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from > to) {
        // Opening a newer database with an older app. Refuse rather than
        // risk damaging personal data the newer schema wrote.
        throw LocalDatabaseException(
          'The on-device database has schema version $from, but this app '
          'only understands up to version $to. Update the app.',
        );
      }
      // Version 1 is the first schema, so there is nothing to upgrade from
      // yet. When the schema changes:
      //   1. bump currentSchemaVersion;
      //   2. run `dart run drift_dev make-migrations`;
      //   3. implement the generated `stepByStep` steps here. Never drop
      //      or recreate tables that hold personal data.
      throw LocalDatabaseException(
        'No migration is defined from schema version $from to $to.',
      );
    },
    beforeOpen: (details) async {
      // SQLite enforces foreign keys only when asked to, on every connection.
      await customStatement('PRAGMA foreign_keys = ON');
      final row = await customSelect('PRAGMA foreign_keys').getSingle();
      if (row.read<int>('foreign_keys') != 1) {
        throw const LocalDatabaseException(
          'SQLite refused to enable foreign key enforcement.',
        );
      }
    },
  );

  /// Opens the database and runs pending migrations now, instead of on the
  /// first query, so that startup fails with a clear error.
  Future<void> ensureInitialized() async {
    try {
      await customSelect('SELECT 1').get();
    } on LocalDatabaseException {
      rethrow;
    } on Object catch (error) {
      throw LocalDatabaseException(
        'Could not open the on-device database.',
        cause: error,
      );
    }
  }
}
