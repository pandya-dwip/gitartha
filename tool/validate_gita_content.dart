// Validates the Bhagavad Gita content repository in assets/data/bhagavad_gita.
//
// Usage, from the project root:
//
//   dart run tool/validate_gita_content.dart              # summary
//   dart run tool/validate_gita_content.dart --verbose    # + per-verse detail
//   dart run tool/validate_gita_content.dart <content_dir>
//
// Exit codes: 0 = no errors (drafts and incomplete content are fine),
//             1 = validation errors, 2 = files missing or unreadable.
//
// What is checked:
//   1. Structure: every file against schema/chapter.schema.json or
//      schema/sources.schema.json. The schemas are interpreted directly,
//      so they stay the single source of truth for structure. Only the
//      keywords those schemas use are supported; any other keyword is a
//      hard error rather than being silently ignored.
//   2. Consistency that JSON Schema cannot express: file name vs chapter id,
//      verse id / reference vs verse_number, unique verse ids and numbers,
//      ascending order, unique source ids, attributions pointing at existing
//      sources and at sections that actually contain text.
//   3. Readiness: each verse is "incomplete", "ready for review" or
//      "approved"; each chapter is publication-ready or not. Approval rules
//      are enforced (see content-guidelines.md).
//
// Uses only the Dart SDK. No packages are needed.

import 'dart:convert';
import 'dart:io';

const String defaultContentDir = 'assets/data/bhagavad_gita';

/// Verse fields that must be filled before a verse can be reviewed.
/// `hindi_meaning_note` is optional and deliberately not listed.
const List<String> verseFieldsRequiredForReview = [
  'index_title',
  'index_summary',
  'sanskrit_text',
  'transliteration',
  'hindi_meaning',
  'english_meaning',
  'context',
  'life_lesson',
  'spiritual_meaning',
  'reflection_question',
];

/// Chapter fields that must be filled before a chapter can be approved.
const List<String> chapterFieldsRequiredForReview = [
  'sanskrit_name',
  'hindi_name',
  'english_name',
  'introduction',
  'overview',
  'central_theme',
  'key_topics',
  'summary',
  'conclusion',
];

/// Sections that need at least one verified source before a verse can be
/// approved: the scripture itself and its translations.
const List<String> sectionsRequiringAttributionForApproval = [
  'sanskrit_text',
  'hindi_meaning',
  'english_meaning',
];

/// Verse counts in the widely used 700-verse numbering (Chapter 13 = 34).
/// Confirm against the edition chosen for Gitartha (see README) before relying
/// on these for publication decisions.
const Map<int, int> expectedVerseCounts = {
  1: 47, 2: 72, 3: 43, 4: 42, 5: 29, 6: 47, 7: 30, 8: 28, 9: 34, //
  10: 42, 11: 55, 12: 20, 13: 34, 14: 27, 15: 20, 16: 24, 17: 28, 18: 78,
};

final RegExp _placeholderText =
    RegExp(r'\b(TODO|TBD|FIXME|lorem ipsum)\b', caseSensitive: false);

Future<void> main(List<String> args) async {
  final verbose = args.contains('--verbose');
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final root = positional.isEmpty ? defaultContentDir : positional.first;

  final report = Report();
  final exitCode = await validateRepository(root, report, verbose: verbose);
  exit(exitCode);
}

// ---------------------------------------------------------------------------
// Repository validation
// ---------------------------------------------------------------------------

Future<int> validateRepository(
  String root,
  Report report, {
  bool verbose = false,
}) async {
  final out = stdout;
  out.writeln('Gitartha content validation: $root');

  final Object? chapterSchemaJson;
  final Object? sourcesSchemaJson;
  try {
    chapterSchemaJson = _readJson('$root/schema/chapter.schema.json');
    sourcesSchemaJson = _readJson('$root/schema/sources.schema.json');
  } on FileSystemException catch (e) {
    stderr.writeln('Cannot read schema: ${e.path}: ${e.message}');
    return 2;
  } on FormatException catch (e) {
    stderr.writeln('Schema is not valid JSON: ${e.message}');
    return 2;
  }
  final chapterSchema = SchemaValidator(_asMap(chapterSchemaJson));
  final sourcesSchema = SchemaValidator(_asMap(sourcesSchemaJson));

  // --- sources -------------------------------------------------------------
  final sourcesPath = '$root/sources/sources.json';
  final sourceLicences = <String, String>{}; // id -> licence ('' = unverified)
  final sourcesDoc = _loadAndValidate(sourcesPath, sourcesSchema, report);
  final sourcesUsable = sourcesDoc != null;
  if (sourcesDoc != null) {
    final sources = _asList(sourcesDoc['sources']);
    for (var i = 0; i < sources.length; i++) {
      final s = _asMap(sources[i]);
      final id = s['id']! as String;
      if (sourceLicences.containsKey(id)) {
        report.error(sourcesPath, 'sources[$i]: duplicate source id "$id"');
      }
      final licence = s['license']! as String;
      sourceLicences[id] = licence;
      if (licence.isEmpty) {
        report.warning(
          sourcesPath,
          'source "$id" has no licence recorded; content attributed to it '
          'cannot be approved',
        );
      }
    }
  } else if (!File(sourcesPath).existsSync()) {
    report.error(sourcesPath, 'file is missing');
  }
  if (!sourcesUsable) {
    report.warning(
      sourcesPath,
      'sources could not be loaded, so verse source_id references were not checked',
    );
  }

  // --- chapter files -------------------------------------------------------
  final chaptersDir = Directory('$root/chapters');
  if (!chaptersDir.existsSync()) {
    stderr.writeln('Missing directory: ${chaptersDir.path}');
    return 2;
  }
  final expectedNames = {
    for (var n = 1; n <= 18; n++) 'chapter_${_pad(n, 2)}.json',
  };
  for (final entity in chaptersDir.listSync()) {
    final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    if (!expectedNames.contains(name)) {
      report.error('${chaptersDir.path}/$name', 'unexpected file in chapters/');
    }
  }

  final summaries = <ChapterSummary>[];
  for (var n = 1; n <= 18; n++) {
    final path = '${chaptersDir.path}/chapter_${_pad(n, 2)}.json';
    if (!File(path).existsSync()) {
      report.error(path, 'file is missing');
      continue;
    }
    final doc = _loadAndValidate(path, chapterSchema, report);
    if (doc == null) {
      summaries.add(ChapterSummary(n)..structurallyValid = false);
      continue;
    }
    summaries.add(
      _checkChapter(
        n,
        path,
        doc,
        sourcesUsable ? sourceLicences : null,
        report,
        verbose: verbose,
      ),
    );
  }

  _printSummary(summaries, sourceLicences.length);
  return report.finish(out);
}

/// Reads a JSON file and validates it against [schema]. Returns the document
/// when it is structurally valid, otherwise records errors and returns null.
Map<String, Object?>? _loadAndValidate(
  String path,
  SchemaValidator schema,
  Report report,
) {
  final file = File(path);
  if (!file.existsSync()) return null;
  final Object? doc;
  try {
    final text = file.readAsStringSync(encoding: utf8);
    if (text.startsWith('﻿')) {
      report.error(path, 'file starts with a UTF-8 BOM; save as UTF-8 without BOM');
    }
    doc = jsonDecode(text.startsWith('﻿') ? text.substring(1) : text);
  } on FormatException catch (e) {
    report.error(path, 'not valid JSON / UTF-8: ${e.message}');
    return null;
  }
  final errors = schema.validate(doc);
  for (final e in errors) {
    report.error(path, 'schema: $e');
  }
  return errors.isEmpty ? _asMap(doc) : null;
}

ChapterSummary _checkChapter(
  int n,
  String path,
  Map<String, Object?> doc,
  Map<String, String>? sourceLicences, // null = sources.json unusable
  Report report, {
  required bool verbose,
}) {
  final summary = ChapterSummary(n);
  final chapter = _asMap(doc['chapter']);

  if (chapter['id'] != n) {
    report.error(path, 'chapter.id is ${chapter['id']} but the file is chapter $n');
  }

  // Chapter metadata completeness.
  final missingMeta = chapterFieldsRequiredForReview
      .where((f) => _isEmpty(chapter[f]))
      .toList();
  summary.metadataFilled =
      chapterFieldsRequiredForReview.length - missingMeta.length;
  summary.chapterStatus = chapter['review_status']! as String;
  if (summary.chapterStatus == 'approved' && missingMeta.isNotEmpty) {
    report.error(
      path,
      'chapter is "approved" but these fields are empty: ${missingMeta.join(', ')}',
    );
  }
  _warnPlaceholders(path, 'chapter', chapter, report);

  // Verses.
  final verses = _asList(doc['verses']).map(_asMap).toList();
  final seenIds = <String>{};
  final seenNumbers = <int>{};
  var previousNumber = 0;
  final expected = expectedVerseCounts[n]!;

  for (var i = 0; i < verses.length; i++) {
    final v = verses[i];
    final vn = (v['verse_number']! as num).toInt();
    final id = v['id']! as String;
    final where = 'verses[$i] (${v['reference']})';

    final expectedId = 'chapter_${_pad(n, 2)}_verse_${_pad(vn, 3)}';
    if (id != expectedId) {
      report.error(path, '$where: id "$id" should be "$expectedId"');
    }
    if (v['reference'] != '$n.$vn') {
      report.error(path, '$where: reference should be "$n.$vn"');
    }
    if (!seenIds.add(id)) report.error(path, '$where: duplicate verse id "$id"');
    if (!seenNumbers.add(vn)) {
      report.error(path, '$where: duplicate verse_number $vn');
    }
    if (vn <= previousNumber) {
      report.error(path, '$where: verses must be in ascending verse_number order');
    }
    previousNumber = vn;
    if (vn > expected) {
      report.warning(
        path,
        '$where: verse_number $vn exceeds the $expected verses expected for '
        'chapter $n in the 700-verse numbering; check the chosen edition',
      );
    }

    // Attributions.
    final attributions = _asList(v['source_attributions']).map(_asMap).toList();
    final attributedSections = <String>{};
    for (final a in attributions) {
      final sourceId = a['source_id']! as String;
      final section = a['content_section']! as String;
      attributedSections.add(section);
      if (sourceLicences != null && !sourceLicences.containsKey(sourceId)) {
        report.error(path, '$where: unknown source_id "$sourceId" (not in sources.json)');
      }
      if (_isEmpty(v[section])) {
        report.error(path, '$where: attribution for "$section", which is empty');
      }
    }

    // Readiness.
    final missing =
        verseFieldsRequiredForReview.where((f) => _isEmpty(v[f])).toList();
    final status = v['review_status']! as String;
    if (missing.isNotEmpty) {
      summary.incomplete++;
      if (status == 'approved') {
        report.error(path, '$where: "approved" but empty: ${missing.join(', ')}');
      } else if (status == 'in_review') {
        report.warning(path, '$where: "in_review" but empty: ${missing.join(', ')}');
      }
      if (verbose) {
        report.info(path, '$where: incomplete; empty: ${missing.join(', ')}');
      }
    } else if (status == 'approved') {
      summary.approved++;
    } else {
      summary.readyForReview++;
      if (verbose) report.info(path, '$where: ready for review ($status)');
    }

    if (status == 'approved') {
      final unsourced = sectionsRequiringAttributionForApproval
          .where((s) => !attributedSections.contains(s))
          .toList();
      if (unsourced.isNotEmpty) {
        report.error(
          path,
          '$where: "approved" but has no source attribution for: '
          '${unsourced.join(', ')}',
        );
      }
      for (final a in attributions) {
        final licence = sourceLicences?[a['source_id']];
        if (licence != null && licence.isEmpty) {
          report.error(
            path,
            '$where: "approved" but source "${a['source_id']}" has no verified licence',
          );
        }
      }
    }
    _warnPlaceholders(path, where, v, report);
  }

  summary.verseCount = verses.length;
  summary.expectedVerses = expected;
  final complete = seenNumbers.length == expected &&
      List.generate(expected, (i) => i + 1).every(seenNumbers.contains);
  summary.publicationReady = complete &&
      missingMeta.isEmpty &&
      summary.chapterStatus == 'approved' &&
      summary.approved == expected;
  return summary;
}

void _warnPlaceholders(
  String path,
  String where,
  Map<String, Object?> object,
  Report report,
) {
  for (final entry in object.entries) {
    final value = entry.value;
    if (value is String) {
      if (value.contains('\r')) {
        report.warning(path, '$where.${entry.key}: contains \\r; use \\n line breaks only');
      }
      if (_placeholderText.hasMatch(value)) {
        report.warning(path, '$where.${entry.key}: looks like placeholder text');
      }
    }
  }
}

void _printSummary(List<ChapterSummary> chapters, int sourceCount) {
  final out = stdout;
  out.writeln('Sources: $sourceCount');
  out.writeln();
  out.writeln('Chapter  Metadata  Verses    Incomplete  Ready for review  '
      'Approved  Publication-ready');
  var verses = 0, approved = 0, ready = 0, incomplete = 0;
  for (final c in chapters) {
    if (!c.structurallyValid) {
      out.writeln('${c.number.toString().padLeft(5)}    (invalid structure — see errors)');
      continue;
    }
    verses += c.verseCount;
    approved += c.approved;
    ready += c.readyForReview;
    incomplete += c.incomplete;
    out.writeln(
      '${c.number.toString().padLeft(5)}    '
      '${'${c.metadataFilled}/${chapterFieldsRequiredForReview.length}'.padRight(10)}'
      '${'${c.verseCount}/${c.expectedVerses}'.padRight(10)}'
      '${c.incomplete.toString().padRight(12)}'
      '${c.readyForReview.toString().padRight(18)}'
      '${c.approved.toString().padRight(10)}'
      '${c.publicationReady ? 'yes' : 'no'}',
    );
  }
  final total = expectedVerseCounts.values.fold(0, (a, b) => a + b);
  out.writeln();
  out.writeln('Verses present: $verses of $total '
      '($incomplete incomplete, $ready ready for review, $approved approved)');
}

// ---------------------------------------------------------------------------
// Minimal JSON Schema (Draft 2020-12) interpreter
// ---------------------------------------------------------------------------

/// Interprets the subset of JSON Schema 2020-12 used by Gitartha's schemas:
/// type, const, enum, required, properties, additionalProperties (boolean),
/// items, uniqueItems, minLength, pattern, minimum, maximum and local `$ref`
/// (`#/$defs/...`). Annotation keywords are ignored. Any other keyword throws,
/// so the schema can't silently ask for checks that aren't performed.
class SchemaValidator {
  SchemaValidator(this.root);

  final Map<String, Object?> root;

  static const Set<String> _annotations = {
    r'$schema', r'$id', r'$defs', r'$comment', //
    'title', 'description', 'examples', 'default',
  };

  List<String> validate(Object? instance) {
    final errors = <String>[];
    _check(root, instance, r'$', errors);
    return errors;
  }

  void _check(
    Map<String, Object?> schema,
    Object? value,
    String path,
    List<String> errors,
  ) {
    final type = schema['type'];
    if (type != null && !_hasType(value, type as String)) {
      errors.add('$path: expected $type, found ${_typeName(value)}');
      return;
    }
    for (final MapEntry(:key, value: keywordValue) in schema.entries) {
      switch (key) {
        case 'type':
          break;
        case r'$ref':
          _check(_resolve(keywordValue! as String), value, path, errors);
        case 'const':
          if (!_deepEquals(value, keywordValue)) {
            errors.add('$path: must be ${jsonEncode(keywordValue)}');
          }
        case 'enum':
          if (!_asList(keywordValue).any((e) => _deepEquals(e, value))) {
            errors.add('$path: must be one of ${jsonEncode(keywordValue)}');
          }
        case 'required':
          if (value is Map) {
            for (final name in _asList(keywordValue)) {
              if (!value.containsKey(name)) {
                errors.add('$path: missing required property "$name"');
              }
            }
          }
        case 'properties':
          if (value is Map) {
            final props = _asMap(keywordValue);
            for (final name in value.keys) {
              final sub = props[name];
              if (sub != null) {
                _check(_asMap(sub), value[name], '$path.$name', errors);
              }
            }
          }
        case 'additionalProperties':
          if (keywordValue is! bool) {
            throw StateError('Only boolean additionalProperties is supported');
          }
          if (!keywordValue && value is Map) {
            final allowed = _asMap(schema['properties'] ?? <String, Object?>{});
            for (final name in value.keys) {
              if (!allowed.containsKey(name)) {
                errors.add('$path: unexpected property "$name"');
              }
            }
          }
        case 'items':
          if (value is List) {
            for (var i = 0; i < value.length; i++) {
              _check(_asMap(keywordValue), value[i], '$path[$i]', errors);
            }
          }
        case 'uniqueItems':
          if (keywordValue == true && value is List) {
            final seen = <String>{};
            for (var i = 0; i < value.length; i++) {
              if (!seen.add(_canonical(value[i]))) {
                errors.add('$path[$i]: duplicate item');
              }
            }
          }
        case 'minLength':
          if (value is String && value.runes.length < (keywordValue! as int)) {
            errors.add('$path: must not be empty');
          }
        case 'pattern':
          if (value is String &&
              !RegExp(keywordValue! as String, unicode: true).hasMatch(value)) {
            errors.add(
              '$path: ${jsonEncode(_preview(value))} does not match the required '
              'format (${schema['description'] ?? keywordValue})',
            );
          }
        case 'minimum':
          if (value is num && value < (keywordValue! as num)) {
            errors.add('$path: must be >= $keywordValue');
          }
        case 'maximum':
          if (value is num && value > (keywordValue! as num)) {
            errors.add('$path: must be <= $keywordValue');
          }
        default:
          if (!_annotations.contains(key)) {
            throw StateError('Unsupported schema keyword "$key" at $path');
          }
      }
    }
  }

  Map<String, Object?> _resolve(String ref) {
    if (!ref.startsWith('#/')) {
      throw StateError('Only local \$ref values are supported: $ref');
    }
    Object? node = root;
    for (final part in ref.substring(2).split('/')) {
      node = _asMap(node)[part];
    }
    if (node == null) throw StateError('Unresolvable \$ref: $ref');
    return _asMap(node);
  }

  static bool _hasType(Object? v, String type) => switch (type) {
        'object' => v is Map,
        'array' => v is List,
        'string' => v is String,
        'integer' => v is int || (v is double && v == v.truncateToDouble()),
        'number' => v is num,
        'boolean' => v is bool,
        'null' => v == null,
        _ => throw StateError('Unsupported type "$type"'),
      };

  static String _typeName(Object? v) => switch (v) {
        null => 'null',
        Map() => 'object',
        List() => 'array',
        String() => 'string',
        int() => 'integer',
        num() => 'number',
        bool() => 'boolean',
        _ => v.runtimeType.toString(),
      };

  static String _preview(String s) =>
      s.length <= 40 ? s : '${s.substring(0, 40)}…';
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class ChapterSummary {
  ChapterSummary(this.number);

  final int number;
  bool structurallyValid = true;
  int metadataFilled = 0;
  String chapterStatus = 'draft';
  int verseCount = 0;
  int expectedVerses = 0;
  int incomplete = 0;
  int readyForReview = 0;
  int approved = 0;
  bool publicationReady = false;
}

class Report {
  final List<String> _errors = [];
  final List<String> _warnings = [];
  final List<String> _info = [];

  void error(String path, String message) => _errors.add('$path: $message');
  void warning(String path, String message) => _warnings.add('$path: $message');
  void info(String path, String message) => _info.add('$path: $message');

  int finish(IOSink out) {
    for (final (title, items) in [
      ('Details', _info),
      ('Warnings', _warnings),
      ('Errors', _errors),
    ]) {
      if (items.isEmpty) continue;
      out.writeln();
      out.writeln('$title (${items.length}):');
      for (final item in items) {
        out.writeln('  - $item');
      }
    }
    out.writeln();
    if (_errors.isNotEmpty) {
      out.writeln('RESULT: FAILED with ${_errors.length} error(s).');
      return 1;
    }
    out.writeln('RESULT: OK. Structure and cross-references are valid. '
        'Completeness is shown above; incomplete drafts are allowed.');
    return 0;
  }
}

Object? _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync(encoding: utf8));

Map<String, Object?> _asMap(Object? v) => (v! as Map).cast<String, Object?>();

List<Object?> _asList(Object? v) => (v! as List).cast<Object?>();

bool _isEmpty(Object? v) =>
    v == null || (v is String && v.isEmpty) || (v is List && v.isEmpty);

String _pad(int n, int width) => n.toString().padLeft(width, '0');

bool _deepEquals(Object? a, Object? b) => _canonical(a) == _canonical(b);

/// JSON encoding with sorted object keys, for equality and uniqueness checks.
String _canonical(Object? v) {
  if (v is Map) {
    final keys = v.keys.map((k) => k as String).toList()..sort();
    return '{${keys.map((k) => '${jsonEncode(k)}:${_canonical(v[k])}').join(',')}}';
  }
  if (v is List) return '[${v.map(_canonical).join(',')}]';
  if (v is double && v == v.truncateToDouble()) return v.toInt().toString();
  return jsonEncode(v);
}
