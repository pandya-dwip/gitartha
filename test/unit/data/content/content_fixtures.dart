import 'dart:convert';
import 'dart:io';

import 'package:gitartha/data/content/content_constants.dart';
import 'package:gitartha/data/content/services/content_asset_loader.dart';

// Test fixtures for the content pipeline. Every text value is an obvious
// "TEST …" placeholder. None of this is scripture, and the real repository
// is never modified by tests.

/// Reads a schema from the real repository (read-only).
String realSchema(String fileName) =>
    File('${GitaContent.rootPath}/schema/$fileName').readAsStringSync();

/// An in-memory [ContentSource]. Uses the real JSON Schemas.
class MapContentSource implements ContentSource {
  MapContentSource({Map<String, Object?>? chapters, Object? sources})
    : chapterTexts = {
        for (final MapEntry(:key, :value) in (chapters ?? {}).entries)
          key: value is String ? value : jsonEncode(value),
      },
      sourcesText = sources is String
          ? sources
          : jsonEncode(sources ?? {'sources': <Object>[]});

  final Map<String, String> chapterTexts;
  String? sourcesText;

  @override
  String get description => 'test fixtures';

  @override
  Future<List<String>> listChapterFiles() async =>
      chapterTexts.keys.toList()..sort();

  @override
  Future<String> readChapterFile(String fileName) async =>
      chapterTexts[fileName] ??
      (throw ContentLoadException(fileName, 'not in fixtures'));

  @override
  Future<String> readSourcesFile() async =>
      sourcesText ??
      (throw const ContentLoadException('sources.json', 'not in fixtures'));

  @override
  Future<String> readSchemaFile(String fileName) async => realSchema(fileName);

  /// Replaces one chapter file (to simulate an edit before re-import).
  void put(String fileName, Object content) => chapterTexts[fileName] =
      content is String ? content : jsonEncode(content);
}

const String testSourceId = 'test_source';
const String unlicensedSourceId = 'test_unlicensed_source';

Map<String, Object?> sourcesFixture({bool includeUnlicensed = false}) => {
  'sources': [
    {
      'id': testSourceId,
      'name': 'TEST Source',
      'author': 'TEST Author',
      'source_url': 'https://example.test/source',
      'license': 'TEST licence',
      'attribution': 'TEST credit line',
    },
    if (includeUnlicensed)
      {
        'id': unlicensedSourceId,
        'name': 'TEST Unlicensed Source',
        'author': '',
        'source_url': '',
        'license': '',
        'attribution': '',
      },
  ],
};

/// Chapter metadata. Empty by default (like the real templates).
Map<String, Object?> chapterMeta(
  int id, {
  bool complete = false,
  bool named = false,
  String status = 'draft',
}) => {
  'id': id,
  'sanskrit_name': complete || named ? 'TEST sanskrit name $id' : '',
  'hindi_name': complete || named ? 'TEST hindi name $id' : '',
  'english_name': complete || named ? 'TEST english name $id' : '',
  'introduction': complete ? 'TEST introduction' : '',
  'overview': complete ? 'TEST overview' : '',
  'central_theme': complete ? 'TEST theme' : '',
  'key_topics': complete ? ['TEST topic A', 'TEST topic B'] : <String>[],
  'summary': complete ? 'TEST summary' : '',
  'conclusion': complete ? 'TEST conclusion' : '',
  'review_status': status,
};

/// A verse. Complete by default; [blank] lists fields to leave empty.
Map<String, Object?> verse(
  int chapter,
  int number, {
  String status = 'draft',
  Set<String> blank = const {},
  String? hindiNote = 'TEST wording note',
  List<Map<String, String>> attributions = const [],
  String? id,
  String? reference,
  String? englishMeaning,
}) {
  String text(String field, String value) => blank.contains(field) ? '' : value;
  return {
    'id': id ?? GitaContent.shlokaContentId(chapter, number),
    'verse_number': number,
    'reference': reference ?? '$chapter.$number',
    'index_title': text('index_title', 'TEST title $chapter.$number'),
    'index_summary': text('index_summary', 'TEST summary'),
    'sanskrit_text': text(
      'sanskrit_text',
      'TEST संस्कृत पाठ।\nTEST दूसरी पंक्ति॥',
    ),
    'transliteration': text('transliteration', 'TEST transliteration'),
    'hindi_meaning': text('hindi_meaning', 'TEST हिन्दी अर्थ'),
    'hindi_meaning_note': hindiNote ?? '',
    'english_meaning': text(
      'english_meaning',
      englishMeaning ?? 'TEST english meaning',
    ),
    'context': text('context', 'TEST context'),
    'life_lesson': text('life_lesson', 'TEST life lesson'),
    'spiritual_meaning': text('spiritual_meaning', 'TEST spiritual meaning'),
    'reflection_question': text('reflection_question', 'TEST question?'),
    'source_attributions': attributions,
    'review_status': status,
  };
}

/// The attributions an approved verse needs (scripture + translations).
List<Map<String, String>> requiredAttributions([
  String sourceId = testSourceId,
]) => [
  for (final section in ['sanskrit_text', 'hindi_meaning', 'english_meaning'])
    {'source_id': sourceId, 'content_section': section},
];

/// A complete, approved verse with its required attributions.
Map<String, Object?> approvedVerse(
  int chapter,
  int number, {
  String? englishMeaning,
}) => verse(
  chapter,
  number,
  status: 'approved',
  attributions: requiredAttributions(),
  englishMeaning: englishMeaning,
);

Map<String, Object?> chapterFile(
  Map<String, Object?> meta, [
  List<Map<String, Object?>> verses = const [],
]) => {'schema_version': '1.0.0', 'chapter': meta, 'verses': verses};

String fileFor(int chapter) => GitaContent.chapterFileName(chapter);
