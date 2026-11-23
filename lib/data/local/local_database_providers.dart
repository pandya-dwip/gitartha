import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/app_database.dart';
import 'repositories/local_database_repository.dart';

/// The single [AppDatabase] for the app.
///
/// It is created on first read (which needs an initialized Flutter binding,
/// for `path_provider`) and closed when the owning
/// [ProviderContainer] is disposed. It is not auto-disposed, so the app never
/// opens a second connection to the same file. `main()` reads it eagerly and
/// awaits [AppDatabase.ensureInitialized] before the first frame.
///
/// Tests override it with an in-memory database:
///
/// ```dart
/// appDatabaseProvider.overrideWith((ref) {
///   final db = AppDatabase(NativeDatabase.memory());
///   ref.onDispose(db.close);
///   return db;
/// })
/// ```
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.persistent();
  ref.onDispose(db.close);
  return db;
});

/// The local data API for feature code. Use this, not [appDatabaseProvider],
/// outside the data layer.
final localDatabaseRepositoryProvider = Provider<LocalDatabaseRepository>(
  (ref) => LocalDatabaseRepository(ref.watch(appDatabaseProvider)),
);
