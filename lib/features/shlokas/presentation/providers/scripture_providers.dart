import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/daos/reading_progress_dao.dart';
import '../../../../data/local/database/app_database.dart';
import '../../../../data/local/local_database_providers.dart';

// Shared scripture, read from SQLite only. Every provider here is backed by a
// Drift watch query, so screens update by themselves when content sync
// commits.

/// One cached live chapter (null if not cached or retired).
final chapterProvider = Provider.family<AsyncValue<LocalChapter?>, int>(
  (ref, id) => ref
      .watch(localChaptersProvider)
      .whenData((all) => all.where((c) => c.id == id).firstOrNull),
);

/// Per-chapter live verse counts and progress, keyed by chapter id.
final chapterSummariesProvider = Provider<Map<int, ChapterProgressSummary>>(
  (ref) => {
    for (final s
        in ref.watch(chapterProgressSummariesProvider).value ??
            const <ChapterProgressSummary>[])
      s.chapterId: s,
  },
);

/// Total live verses cached on the device.
final cachedVerseCountProvider = Provider<int>(
  (ref) => ref
      .watch(chapterSummariesProvider)
      .values
      .fold(0, (sum, s) => sum + s.totalShlokas),
);

/// A shloka by id, live; soft-deleted ones included (`deletedAt != null`).
final shlokaByIdProvider = StreamProvider.family<LocalShloka?, String>(
  (ref, id) => ref.watch(localDatabaseRepositoryProvider).watchShloka(id),
);

/// A source credited for some sections of a verse.
typedef SourceCredit = ({LocalContentSource source, List<String> sections});

/// The sources credited for [shlokaId], grouped by source.
final sourceCreditsProvider = FutureProvider.family<List<SourceCredit>, String>(
  (ref, shlokaId) async {
    final repo = ref.watch(localDatabaseRepositoryProvider);
    final bySource = <String, List<String>>{};
    for (final a in await repo.getSourceAttributionsForShloka(shlokaId)) {
      (bySource[a.sourceId] ??= []).add(a.contentSection);
    }
    return [
      for (final MapEntry(key: id, value: sections) in bySource.entries)
        if (await repo.getContentSource(id) case final source?
            when source.deletedAt == null)
          (source: source, sections: sections),
    ];
  },
);

/// Local search over cached live verses (reference, titles, texts,
/// meanings). Empty for blank queries.
final verseSearchProvider = FutureProvider.autoDispose
    .family<List<LocalShloka>, String>(
      (ref, query) =>
          ref.watch(localDatabaseRepositoryProvider).searchShlokas(query),
    );

/// The most recently opened verse, for "Continue Reading".
final lastOpenedShlokaProvider = StreamProvider<LocalShloka?>((ref) {
  final repo = ref.watch(localDatabaseRepositoryProvider);
  return repo.watchLastOpened().asyncMap(
    (p) async =>
        p == null ? null : await repo.getShloka(p.shlokaId), // live only
  );
});

/// A verse for "Daily Contemplation": chosen deterministically from the
/// cached verses that have Sanskrit text, changing once a day. Null when
/// nothing suitable is cached. Never invents content.
final dailyShlokaProvider = FutureProvider<LocalShloka?>((ref) async {
  final repo = ref.watch(localDatabaseRepositoryProvider);
  final summaries = ref.watch(chapterSummariesProvider);
  final total = summaries.values.fold(0, (s, c) => s + c.totalShlokas);
  if (total == 0) return null;
  final now = DateTime.now();
  final day = now.difference(DateTime(now.year)).inDays + now.year * 366;
  var index = day % total;
  final chapters = summaries.keys.toList()..sort();
  for (final chapterId in chapters) {
    final count = summaries[chapterId]!.totalShlokas;
    if (index >= count) {
      index -= count;
      continue;
    }
    final verses = await repo.getShlokasForChapter(chapterId);
    final withText = verses.where((v) => v.sanskritText != null).toList();
    if (withText.isEmpty) return null;
    return withText[index % withText.length];
  }
  return null;
});
