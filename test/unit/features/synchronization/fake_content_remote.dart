import 'dart:async';

import 'package:gitartha/features/synchronization/data/content_remote_datasource.dart';
import 'package:gitartha/features/synchronization/domain/sync_result.dart';

String uuid(int n) =>
    '00000000-0000-4000-8000-${n.toRadixString(16).padLeft(12, '0')}';

/// An in-memory Supabase for shared content. Rows look exactly like
/// PostgREST JSON (snake_case, `+00:00` timestamps), the server stamps
/// `updated_at`/`created_at` itself, and [fetchPage] applies the same
/// keyset semantics as the real query.
class FakeContentRemote implements ContentRemoteDataSource {
  FakeContentRemote({DateTime? start})
    : serverNow = start ?? DateTime.utc(2026, 3, 1, 12);

  /// Server clock; every write advances it by one second unless [freeze].
  DateTime serverNow;
  bool freeze = false;

  final Map<SyncTable, Map<Object, Map<String, dynamic>>> rows = {
    for (final t in SyncTable.values) t: {},
  };

  /// Every request made, for assertions.
  final List<({SyncTable table, String? since, PageCursor? after, int limit})>
  calls = [];

  /// Throws [failWith] on the request number [failOnCall] (1-based), or on
  /// the next request for [failOnTable] (one-shot).
  int? failOnCall;
  SyncTable? failOnTable;
  SyncException failWith = const SyncException(SyncFailureKind.offline);

  /// When set, requests wait for it (to observe a running sync).
  Completer<void>? gate;

  /// Simulates a server whose max-rows setting is below the client's page
  /// size.
  int? serverRowCap;

  String _stamp() {
    final ts = _format(serverNow);
    if (!freeze) serverNow = serverNow.add(const Duration(seconds: 1));
    return ts;
  }

  static String _format(DateTime t) =>
      t.toUtc().toIso8601String().replaceFirst('Z', '+00:00');

  // --- "publishing" helpers (what the CLI / an editor would do) ----------

  void putChapter(int id, {String english = 'TEST chapter', DateTime? at}) {
    final ts = at == null ? _stamp() : _format(at);
    final old = rows[SyncTable.chapters]![id];
    rows[SyncTable.chapters]![id] = {
      'id': id,
      'sanskrit_name': 'TEST sanskrit $id',
      'hindi_name': 'TEST hindi $id',
      'english_name': english,
      'introduction': null,
      'overview': 'TEST overview $id',
      'central_theme': null,
      'key_topics': ['TEST topic A', 'TEST topic B'],
      'summary': null,
      'conclusion': null,
      'created_at': old?['created_at'] ?? ts,
      'updated_at': ts,
      'deleted_at': old?['deleted_at'],
    };
  }

  void putSource(int n, {String name = 'TEST source', String? license}) {
    final ts = _stamp();
    final id = uuid(0x5000 + n);
    final old = rows[SyncTable.contentSources]![id];
    rows[SyncTable.contentSources]![id] = {
      'id': id,
      'name': name,
      'author': null,
      'source_url': 'https://example.test/source/$n',
      'license': license,
      'attribution': 'TEST attribution $n',
      'created_at': old?['created_at'] ?? ts,
      'updated_at': ts,
      'deleted_at': old?['deleted_at'],
    };
  }

  static String shlokaId(int chapter, int verse) =>
      uuid(chapter * 1000 + verse);

  void putShloka(
    int chapter,
    int verse, {
    String? id,
    String english = 'TEST english',
    String? hindiNote = 'TEST hindi meaning note',
    String? lifeLesson,
    DateTime? at,
  }) {
    final ts = at == null ? _stamp() : _format(at);
    final key = id ?? shlokaId(chapter, verse);
    final old = rows[SyncTable.shlokas]![key];
    rows[SyncTable.shlokas]![key] = {
      'id': key,
      'chapter_id': chapter,
      'verse_number': verse,
      'reference': '$chapter.$verse',
      'index_title': 'TEST title $chapter.$verse',
      'index_summary': null,
      'sanskrit_text': 'TEST sanskrit',
      'transliteration': 'TEST transliteration',
      'hindi_meaning': 'TEST hindi',
      'hindi_meaning_note': hindiNote,
      'english_meaning': english,
      'context': 'TEST context',
      'life_lesson': lifeLesson,
      'spiritual_meaning': 'TEST spiritual',
      'reflection_question': 'TEST question?',
      'created_at': old?['created_at'] ?? ts,
      'updated_at': ts,
      'deleted_at': old?['deleted_at'],
    };
  }

  void putAttribution(int n, String shlokaId, int source, String section) {
    final id = uuid(0xA000 + n);
    rows[SyncTable.attributions]![id] = {
      'id': id,
      'shloka_id': shlokaId,
      'source_id': uuid(0x5000 + source),
      'content_section': section,
      'created_at': _stamp(),
    };
  }

  void deleteAttribution(int n) =>
      rows[SyncTable.attributions]!.remove(uuid(0xA000 + n));

  /// Soft delete (or restore with [restore]): bumps `updated_at`.
  void setDeleted(SyncTable table, Object id, {bool restore = false}) {
    final row = rows[table]![id]!;
    final ts = _stamp();
    row['deleted_at'] = restore ? null : ts;
    row['updated_at'] = ts;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPage(
    SyncTable table, {
    String? since,
    PageCursor? after,
    required int limit,
  }) async {
    calls.add((table: table, since: since, after: after, limit: limit));
    await gate?.future;
    if (failOnTable == table) {
      failOnTable = null;
      throw failWith;
    }
    if (failOnCall == calls.length) throw failWith;
    final tsCol = table.timestampColumn;
    String tsOf(Map<String, dynamic> r) =>
        normalizeRemoteTimestamp(r[tsCol] as String);
    int cmpId(Object a, Object b) => a is int && b is int
        ? a.compareTo(b)
        : a.toString().compareTo(b.toString());

    final sorted = rows[table]!.values.toList()
      ..sort((a, b) {
        final c = tsOf(a).compareTo(tsOf(b));
        return c != 0 ? c : cmpId(a['id'] as Object, b['id'] as Object);
      });
    final matching = sorted.where((r) {
      final ts = tsOf(r);
      if (after != null) {
        final c = ts.compareTo(after.timestamp);
        return c > 0 || (c == 0 && cmpId(r['id'] as Object, after.id) > 0);
      }
      return since == null || ts.compareTo(since) >= 0;
    });
    final n = serverRowCap != null && serverRowCap! < limit
        ? serverRowCap!
        : limit;
    // Copies, like JSON over the wire.
    return [for (final r in matching.take(n)) Map<String, dynamic>.of(r)];
  }
}
