import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/local/database/app_database.dart';

import 'generated/schema.dart';

/// Migration tests, built on Drift's schema snapshots in `drift_schemas/`.
///
/// When the schema changes:
///   1. bump `AppDatabase.currentSchemaVersion`;
///   2. run `dart run drift_dev make-migrations` (exports the new snapshot,
///      generates `stepByStep` and an upgrade test template here);
///   3. implement the migration and keep these tests green.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('the current tables match the exported v1 schema snapshot', () async {
    // Start from the exported v1 snapshot and open it with today's app code.
    // This fails if the table definitions were changed without bumping the
    // schema version and exporting a new snapshot.
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);
  });

  test(
    'a fresh install (onCreate) produces exactly the defined schema',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.validateDatabaseSchema();
    },
  );
}
