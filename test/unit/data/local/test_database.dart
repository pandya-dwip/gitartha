import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:gitartha/data/local/database/app_database.dart';

/// A controllable clock for tests. Starts at 2026-01-01 09:00 UTC.
class TestClock {
  DateTime current = DateTime.utc(2026, 1, 1, 9);

  DateTime call() => current;

  void advance(Duration by) => current = current.add(by);
}

/// A fresh in-memory database. Every test gets its own.
AppDatabase openTestDatabase({TestClock? clock}) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory(), clock: clock?.call);
}

/// A syntactically valid, deterministic UUID for test fixtures.
String testUuid(int n) =>
    '00000000-0000-4000-8000-${n.toRadixString(16).padLeft(12, '0')}';

// The fixtures below use obvious placeholder text. They are not scripture.

LocalChapter chapterFixture(
  int id, {
  DateTime? updatedAt,
  DateTime? deletedAt,
  String? overview,
}) => LocalChapter(
  id: id,
  sanskritName: 'TEST sanskrit name $id',
  hindiName: 'TEST hindi name $id',
  englishName: 'TEST english name $id',
  overview: overview,
  keyTopics: const ['TEST topic A', 'TEST topic B'],
  createdAt: DateTime.utc(2025, 1, 1),
  updatedAt: updatedAt ?? DateTime.utc(2025, 1, 1),
  deletedAt: deletedAt,
);

LocalShloka shlokaFixture(
  int chapterId,
  int verseNumber, {
  String? id,
  DateTime? updatedAt,
  DateTime? deletedAt,
  String? indexTitle,
  String? englishMeaning,
}) => LocalShloka(
  id: id ?? testUuid(chapterId * 1000 + verseNumber),
  chapterId: chapterId,
  verseNumber: verseNumber,
  reference: '$chapterId.$verseNumber',
  indexTitle: indexTitle ?? 'TEST title $chapterId.$verseNumber',
  englishMeaning: englishMeaning,
  hindiMeaning: 'TEST hindi meaning',
  hindiMeaningNote: 'TEST hindi wording note',
  reflectionQuestion: 'TEST question?',
  createdAt: DateTime.utc(2025, 1, 1),
  updatedAt: updatedAt ?? DateTime.utc(2025, 1, 1),
  deletedAt: deletedAt,
);

/// Caches chapter [chapterId] with verses 1..[verses] and returns the verses.
Future<List<LocalShloka>> seedChapter(
  AppDatabase db,
  int chapterId, {
  int verses = 3,
}) async {
  await db.chapterDao.upsertChapter(chapterFixture(chapterId));
  final shlokas = [
    for (var v = 1; v <= verses; v++) shlokaFixture(chapterId, v),
  ];
  await db.shlokaDao.upsertShlokas(shlokas);
  return shlokas;
}
