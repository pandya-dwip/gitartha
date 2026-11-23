import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/local/database/app_database.dart';

import 'matchers.dart';
import 'test_database.dart';

void main() {
  late TestClock clock;
  late AppDatabase db;
  late List<LocalShloka> verses;

  setUp(() async {
    clock = TestClock();
    db = openTestDatabase(clock: clock);
    verses = await seedChapter(db, 1, verses: 3);
  });
  tearDown(() => db.close());

  group('reflections', () {
    test(
      'a shloka can have many reflections; a new one never overwrites',
      () async {
        final shlokaId = verses.first.id;
        final first = await db.reflectionDao.addReflection(
          shlokaId: shlokaId,
          answer: 'First answer',
        );
        clock.advance(const Duration(days: 180));
        final second = await db.reflectionDao.addReflection(
          shlokaId: shlokaId,
          answer: 'Six months later',
        );

        expect(second.id, isNot(first.id));
        final all = await db.reflectionDao.getReflectionsForShloka(shlokaId);
        expect(all.map((r) => r.answer), ['First answer', 'Six months later']);
        expect(all.first, first); // untouched
        expect(all.last.createdAt, DateTime.utc(2026, 6, 30, 9));
      },
    );

    test('editing updates only that entry and its updated_at', () async {
      final shlokaId = verses.first.id;
      final a = await db.reflectionDao.addReflection(
        shlokaId: shlokaId,
        answer: 'Original',
      );
      final b = await db.reflectionDao.addReflection(
        shlokaId: shlokaId,
        answer: 'Other',
      );
      clock.advance(const Duration(hours: 2));

      final edited = await db.reflectionDao.updateReflection(a.id, 'Revised');

      expect(edited!.answer, 'Revised');
      expect(edited.createdAt, a.createdAt);
      expect(edited.updatedAt, a.createdAt.add(const Duration(hours: 2)));
      expect(await db.reflectionDao.getReflection(b.id), b);
      expect(
        await db.reflectionDao.updateReflection(testUuid(404), 'x'),
        isNull,
      );
    });

    test('are returned chronologically, ties in insertion order', () async {
      final shlokaId = verses.first.id;
      for (final text in ['one', 'two', 'three']) {
        await db.reflectionDao.addReflection(shlokaId: shlokaId, answer: text);
      }
      clock.advance(const Duration(minutes: 1));
      await db.reflectionDao.addReflection(shlokaId: shlokaId, answer: 'four');

      final answers = (await db.reflectionDao.getReflectionsForShloka(
        shlokaId,
      )).map((r) => r.answer);
      expect(answers, ['one', 'two', 'three', 'four']);

      final recent = await db.reflectionDao.getRecentReflections(limit: 2);
      expect(recent.map((r) => r.answer), ['four', 'three']);
    });

    test('deleting one reflection keeps the others', () async {
      final shlokaId = verses.first.id;
      final a = await db.reflectionDao.addReflection(
        shlokaId: shlokaId,
        answer: 'Keep me',
      );
      final b = await db.reflectionDao.addReflection(
        shlokaId: shlokaId,
        answer: 'Delete me',
      );

      expect(await db.reflectionDao.deleteReflection(b.id), isTrue);
      expect(await db.reflectionDao.deleteReflection(b.id), isFalse);
      expect(await db.reflectionDao.getReflectionsForShloka(shlokaId), [a]);
    });

    test('blank answers are rejected, in Dart and in SQL', () async {
      expect(
        () => db.reflectionDao.addReflection(
          shlokaId: verses.first.id,
          answer: ' \n\t ',
        ),
        throwsArgumentError,
      );
      await expectLater(
        db
            .into(db.reflections)
            .insert(
              ReflectionsCompanion.insert(
                id: testUuid(1),
                shlokaId: verses.first.id,
                answer: '\n ',
                createdAt: clock(),
                updatedAt: clock(),
              ),
            ),
        throwsCheckError,
      );
    });

    test('a device clock moving backwards cannot break updated_at', () async {
      final r = await db.reflectionDao.addReflection(
        shlokaId: verses.first.id,
        answer: 'x',
      );
      clock.advance(const Duration(days: -3));
      final edited = await db.reflectionDao.updateReflection(r.id, 'y');
      expect(edited!.updatedAt, r.createdAt);
    });

    test('watchReflectionsForShloka emits updates', () async {
      final shlokaId = verses.first.id;
      final counts = db.reflectionDao
          .watchReflectionsForShloka(shlokaId)
          .map((l) => l.length);
      final expectation = expectLater(counts, emitsInOrder([0, 1]));
      await pumpEventQueue();
      await db.reflectionDao.addReflection(shlokaId: shlokaId, answer: 'a');
      await expectation;
    });
  });

  group('personal notes', () {
    test('many notes per shloka, and notes without a shloka', () async {
      final shlokaId = verses.first.id;
      await db.personalNoteDao.createNote(shlokaId: shlokaId, content: 'n1');
      clock.advance(const Duration(seconds: 1));
      await db.personalNoteDao.createNote(
        shlokaId: shlokaId,
        title: 'Titled',
        content: 'n2',
      );
      final general = await db.personalNoteDao.createNote(
        title: '   ',
        content: 'A general thought',
      );

      expect(general.shlokaId, isNull);
      expect(general.title, isNull); // blank title stored as null
      final forShloka = await db.personalNoteDao.getNotesForShloka(shlokaId);
      expect(forShloka.map((n) => n.content), ['n2', 'n1']);
      expect(await db.personalNoteDao.getAllNotes(), hasLength(3));
    });

    test('edit and delete individual notes', () async {
      final a = await db.personalNoteDao.createNote(
        shlokaId: verses.first.id,
        title: 'Old title',
        content: 'Old content',
      );
      final b = await db.personalNoteDao.createNote(content: 'Other');
      clock.advance(const Duration(minutes: 5));

      final renamed = await db.personalNoteDao.updateNote(
        a.id,
        title: const Value('New title'),
      );
      expect(renamed!.title, 'New title');
      expect(renamed.content, 'Old content');
      expect(renamed.updatedAt, isNot(a.updatedAt));

      final cleared = await db.personalNoteDao.updateNote(
        a.id,
        title: const Value(null),
        content: 'New content',
      );
      expect(cleared!.title, isNull);
      expect(cleared.content, 'New content');
      expect(cleared.createdAt, a.createdAt);

      expect(await db.personalNoteDao.deleteNote(a.id), isTrue);
      expect(await db.personalNoteDao.getAllNotes(), [b]);
      expect(
        () => db.personalNoteDao.updateNote(b.id, content: ''),
        throwsArgumentError,
      );
    });

    test('search looks at title and content', () async {
      await db.personalNoteDao.createNote(title: 'Morning', content: 'calm');
      await db.personalNoteDao.createNote(content: 'Felt calm today');
      await db.personalNoteDao.createNote(content: 'Something else');

      expect(await db.personalNoteDao.searchNotes('calm'), hasLength(2));
      expect(await db.personalNoteDao.searchNotes('morning'), hasLength(1));
      expect(await db.personalNoteDao.searchNotes('_'), isEmpty);
    });

    test(
      'notes must point at a cached shloka if they point anywhere',
      () async {
        await expectLater(
          db.personalNoteDao.createNote(shlokaId: testUuid(404), content: 'x'),
          throwsForeignKeyError,
        );
      },
    );
  });

  group('bookmarks', () {
    test('add, check and remove', () async {
      final id = verses.first.id;
      expect(await db.bookmarkDao.isBookmarked(id), isFalse);

      final bookmark = await db.bookmarkDao.addBookmark(id);
      expect(bookmark.shlokaId, id);
      expect(await db.bookmarkDao.isBookmarked(id), isTrue);

      expect(await db.bookmarkDao.removeBookmark(id), isTrue);
      expect(await db.bookmarkDao.isBookmarked(id), isFalse);
      expect(await db.bookmarkDao.removeBookmark(id), isFalse);
    });

    test('a shloka cannot be bookmarked twice', () async {
      final id = verses.first.id;
      final first = await db.bookmarkDao.addBookmark(id);
      clock.advance(const Duration(minutes: 1));
      final again = await db.bookmarkDao.addBookmark(id);

      expect(again, first);
      expect(await db.bookmarkDao.getBookmarks(), hasLength(1));
      await expectLater(
        db
            .into(db.bookmarks)
            .insert(
              BookmarksCompanion.insert(
                id: testUuid(77),
                shlokaId: id,
                createdAt: clock(),
              ),
            ),
        throwsUniqueError,
      );
    });

    test('are listed newest first', () async {
      for (final shloka in verses) {
        await db.bookmarkDao.addBookmark(shloka.id);
        clock.advance(const Duration(minutes: 1));
      }
      final ordered = await db.bookmarkDao.getBookmarks();
      expect(ordered.map((b) => b.shlokaId), verses.reversed.map((s) => s.id));
    });
  });
}
