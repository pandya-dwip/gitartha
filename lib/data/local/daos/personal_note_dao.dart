import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/personal_notes.dart';
import 'like_pattern.dart';
import 'validation.dart';

part 'personal_note_dao.g.dart';

/// Personal notes, attached to a shloka or free-standing.
@DriftAccessor(tables: [PersonalNotes])
class PersonalNoteDao extends DatabaseAccessor<AppDatabase>
    with _$PersonalNoteDaoMixin {
  PersonalNoteDao(super.attachedDatabase);

  /// Creates a note. Pass no [shlokaId] for a note that isn't about a
  /// particular verse. A blank [title] is stored as null.
  Future<PersonalNote> createNote({
    String? shlokaId,
    String? title,
    required String content,
  }) {
    final now = attachedDatabase.now();
    return into(personalNotes).insertReturning(
      PersonalNotesCompanion.insert(
        id: attachedDatabase.newId(),
        shlokaId: Value(shlokaId),
        title: Value(blankToNull(title)),
        content: requireText(content, 'content'),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Updates note [id]. Only the fields that are passed change. Pass
  /// `title: const Value(null)` to clear the title. Returns null if [id]
  /// does not exist.
  Future<PersonalNote?> updateNote(
    String id, {
    Value<String?> title = const Value.absent(),
    String? content,
  }) {
    if (content != null) requireText(content, 'content');
    return transaction(() async {
      final existing = await getNote(id);
      if (existing == null) return null;
      final rows = await (update(personalNotes)..where((n) => n.id.equals(id)))
          .writeReturning(
            PersonalNotesCompanion(
              title: title.present ? Value(blankToNull(title.value)) : title,
              content: content == null ? const Value.absent() : Value(content),
              updatedAt: Value(
                notEarlierThan(attachedDatabase.now(), existing.createdAt),
              ),
            ),
          );
      return rows.single;
    });
  }

  /// Deletes only note [id]. Returns false if it did not exist.
  Future<bool> deleteNote(String id) async =>
      await (delete(personalNotes)..where((n) => n.id.equals(id))).go() > 0;

  Future<PersonalNote?> getNote(String id) =>
      (select(personalNotes)..where((n) => n.id.equals(id))).getSingleOrNull();

  SimpleSelectStatement<$PersonalNotesTable, PersonalNote> _forShloka(
    String shlokaId,
  ) => select(personalNotes)
    ..where((n) => n.shlokaId.equals(shlokaId))
    ..orderBy(_newestFirst);

  /// Notes on [shlokaId], most recently edited first.
  Future<List<PersonalNote>> getNotesForShloka(String shlokaId) =>
      _forShloka(shlokaId).get();

  Stream<List<PersonalNote>> watchNotesForShloka(String shlokaId) =>
      _forShloka(shlokaId).watch();

  /// All notes, including free-standing ones, most recently edited first.
  Future<List<PersonalNote>> getAllNotes() =>
      (select(personalNotes)..orderBy(_newestFirst)).get();

  /// Notes whose title or content contains [query].
  Future<List<PersonalNote>> searchNotes(String query) {
    final term = query.trim();
    if (term.isEmpty) return Future.value(const []);
    final pattern = containsPattern(term);
    return (select(personalNotes)
          ..where(
            (n) =>
                n.title.like(pattern, escapeChar: likeEscapeChar) |
                n.content.like(pattern, escapeChar: likeEscapeChar),
          )
          ..orderBy(_newestFirst))
        .get();
  }

  static final List<OrderingTerm Function($PersonalNotesTable)> _newestFirst = [
    (n) => OrderingTerm.desc(n.updatedAt),
    (n) => OrderingTerm.desc(n.rowId),
  ];
}
