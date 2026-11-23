import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// File name (without extension) of the on-device database.
///
/// `drift_flutter` stores it as `gitartha.sqlite` in the app's documents
/// directory (`getApplicationDocumentsDirectory()`), which persists across
/// app restarts and updates. It is removed only when the app is uninstalled
/// or its data is cleared.
const String localDatabaseName = 'gitartha';

/// Opens the persistent database file. The file location is resolved through
/// `path_provider` as soon as this is called, so it needs an initialized
/// Flutter binding. Migrations run on the first query or on
/// `AppDatabase.ensureInitialized()`.
///
/// [native] is only for tests, which point it at a temporary directory. The
/// app uses the platform defaults.
QueryExecutor openPersistentConnection({DriftNativeOptions? native}) =>
    driftDatabase(name: localDatabaseName, native: native);
