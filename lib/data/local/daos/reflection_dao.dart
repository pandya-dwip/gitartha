import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/reflections.dart';
import 'validation.dart';

part 'reflection_dao.g.dart';

/// Personal reflections (answers to reflection questions).
///
/// Every call to [addReflection] creates a new, separate entry. Answering the
/// same question again never overwrites an older answer. Only [updateReflection]
/// changes an existing entry, and only the one whose id it is given.
@DriftAccessor(tables: [Reflections])
class ReflectionDao extends DatabaseAccessor<AppDatabase>
    with _$ReflectionDaoMixin {
  ReflectionDao(super.attachedDatabase);

  /// Saves a new reflection on [shlokaId] and returns it.
  Future<Reflection> addReflection({
    required String shlokaId,
    required String answer,
  }) {
    final now = attachedDatabase.now();
    return into(reflections).insertReturning(
      ReflectionsCompanion.insert(
        id: attachedDatabase.newId(),
        shlokaId: shlokaId,
        answer: requireText(answer, 'answer'),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Replaces the text of reflection [id] and sets its `updated_at`.
  /// `created_at` is kept. Returns the updated row, or null if [id] does not
  /// exist.
  Future<Reflection?> updateReflection(String id, String answer) {
    requireText(answer, 'answer');
    return transaction(() async {
      final existing = await getReflection(id);
      if (existing == null) return null;
      final rows = await (update(reflections)..where((r) => r.id.equals(id)))
          .writeReturning(
            ReflectionsCompanion(
              answer: Value(answer),
              updatedAt: Value(
                notEarlierThan(attachedDatabase.now(), existing.createdAt),
              ),
            ),
          );
      return rows.single;
    });
  }

  /// Deletes only reflection [id]. Returns false if it did not exist.
  Future<bool> deleteReflection(String id) async =>
      await (delete(reflections)..where((r) => r.id.equals(id))).go() > 0;

  Future<Reflection?> getReflection(String id) =>
      (select(reflections)..where((r) => r.id.equals(id))).getSingleOrNull();

  SimpleSelectStatement<$ReflectionsTable, Reflection> _forShloka(
    String shlokaId,
  ) => select(reflections)
    ..where((r) => r.shlokaId.equals(shlokaId))
    ..orderBy([
      (r) => OrderingTerm.asc(r.createdAt),
      (r) => OrderingTerm.asc(r.rowId),
    ]);

  /// All reflections on [shlokaId], oldest first (chronological).
  Future<List<Reflection>> getReflectionsForShloka(String shlokaId) =>
      _forShloka(shlokaId).get();

  /// Emits [getReflectionsForShloka] again whenever it changes.
  Stream<List<Reflection>> watchReflectionsForShloka(String shlokaId) =>
      _forShloka(shlokaId).watch();

  /// The most recently written reflections across all shlokas, newest first.
  Future<List<Reflection>> getRecentReflections({int limit = 20}) =>
      (select(reflections)
            ..orderBy([
              (r) => OrderingTerm.desc(r.createdAt),
              (r) => OrderingTerm.desc(r.rowId),
            ])
            ..limit(limit))
          .get();
}
