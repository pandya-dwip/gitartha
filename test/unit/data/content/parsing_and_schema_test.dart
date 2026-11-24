import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/content/content_constants.dart';
import 'package:gitartha/data/content/content_ids.dart';
import 'package:gitartha/data/content/models/content_enums.dart';
import 'package:gitartha/data/content/parsers/chapter_json_parser.dart';
import 'package:gitartha/data/content/parsers/source_json_parser.dart';
import 'package:gitartha/data/content/validators/json_schema_validator.dart';
import 'package:gitartha/data/content/validators/validation_result.dart';

import 'content_fixtures.dart';

void main() {
  late ChapterJsonParser parser;
  late JsonSchemaValidator schema;

  setUpAll(() {
    schema = JsonSchemaValidator.fromSchemaText(
      realSchema(GitaContent.chapterSchemaFileName),
      schemaName: 'chapter.schema.json',
    );
    parser = ChapterJsonParser(schema);
  });

  List<ValidationIssue> schemaIssues(Map<String, Object?> doc) =>
      schema.validate(jsonDecode(jsonEncode(doc)), fileName: 'chapter_01.json');

  group('parsing', () {
    test('a valid chapter with several verses becomes typed models', () {
      final outcome = parser.parse(
        jsonEncode(
          chapterFile(chapterMeta(2, complete: true, status: 'approved'), [
            verse(2, 1),
            verse(2, 2, blank: {'context'}, hindiNote: null),
          ]),
        ),
        fileName: 'chapter_02.json',
      );

      expect(outcome.issues, isEmpty);
      final model = outcome.value!;
      expect(model.schemaVersion, '1.0.0');
      expect(model.chapter.id, 2);
      expect(model.chapter.keyTopics, ['TEST topic A', 'TEST topic B']);
      expect(model.chapter.reviewStatus, ReviewStatus.approved);
      expect(model.verses.map((v) => v.reference), ['2.1', '2.2']);
      // Empty strings become null.
      expect(model.verses[1].context, isNull);
      expect(model.verses[1].hindiMeaningNote, isNull);
      expect(model.verses[0].hindiMeaningNote, 'TEST wording note');
      expect(model.verses[1].missingRequiredFields, ['context']);
    });

    test(
      'the real Chapter 1 file parses; Verse 41 keeps every field intact',
      () {
        final text = File(
          '${GitaContent.rootPath}/chapters/chapter_01.json',
        ).readAsStringSync();
        final outcome = parser.parse(text, fileName: 'chapter_01.json');
        expect(outcome.issues, isEmpty);

        final verses = outcome.value!.verses;
        expect(verses.map((v) => v.verseNumber), [
          for (var n = 1; n <= 41; n++) n,
        ]);
        final v = verses.last;
        expect(v.id, 'chapter_01_verse_041');
        expect(v.verseNumber, 41);
        expect(v.reference, '1.41');
        expect(v.indexTitle, 'The Consequences of Adharma and Social Disorder');
        expect(v.indexSummary, isNotNull);
        expect(v.sanskritText, startsWith('अधर्माभिभवात्कृष्ण'));
        expect(v.sanskritText, endsWith('॥ १.४१॥'));
        expect(v.transliteration, contains('Kṛṣṇa'));
        expect(v.hindiMeaning, startsWith('हे कृष्ण (श्रीकृष्ण)!'));
        expect(
          v.hindiMeaningNote,
          startsWith('This is a traditional translation'),
        );
        expect(v.hindiMeaning, isNot(contains('traditional translation')));
        expect(
          v.reflectionQuestion,
          endsWith('nothing to do with the conflict?'),
        );
        expect(v.sourceAttributions, isEmpty);
        expect(v.reviewStatus, ReviewStatus.draft);

        // The model round-trips to exactly the file's JSON.
        expect(outcome.value!.toJson(), jsonDecode(text));
      },
    );

    test('malformed JSON is reported, not thrown', () {
      final outcome = parser.parse(
        '{"schema_version": "1.0.0", ',
        fileName: 'x.json',
      );
      expect(outcome.value, isNull);
      expect(outcome.issues.single.code, ValidationCode.invalidJson);
      expect(outcome.issues.single.fileName, 'x.json');
    });

    test('a missing property is reported with its location', () {
      final doc = chapterFile(chapterMeta(1), [verse(1, 1)]);
      ((doc['verses']! as List).first as Map).remove('hindi_meaning_note');
      final outcome = parser.parse(
        jsonEncode(doc),
        fileName: 'chapter_01.json',
      );
      expect(outcome.value, isNull);
      final issue = outcome.issues.firstWhere(
        (i) => i.message.contains('hindi_meaning_note'),
      );
      expect(issue.jsonPath, r'$.verses[0]');
      expect(issue.message, 'Missing required property "hindi_meaning_note".');
    });

    test('a UTF-8 byte order mark is rejected', () {
      final outcome = parser.parse(
        '\uFEFF${jsonEncode(chapterFile(chapterMeta(1)))}',
        fileName: 'chapter_01.json',
      );
      expect(outcome.value, isNull);
      expect(outcome.issues.single.code, ValidationCode.invalidEncoding);
    });

    test('sources.json parses, with empty fields as null', () {
      final sourcesSchema = JsonSchemaValidator.fromSchemaText(
        realSchema(GitaContent.sourcesSchemaFileName),
        schemaName: 'sources.schema.json',
      );
      final outcome = SourceJsonParser(sourcesSchema).parse(
        jsonEncode(sourcesFixture(includeUnlicensed: true)),
        fileName: 'sources.json',
      );
      final sources = outcome.value!.sources;
      expect(sources.first.license, 'TEST licence');
      expect(sources.last.license, isNull);
      expect(sources.last.hasVerifiedLicense, isFalse);
    });
  });

  group('JSON Schema (Draft 2020-12)', () {
    test('uses the draft declared by the schema file', () {
      expect(schema.draft, contains('2020-12'));
    });

    test('valid documents pass', () {
      expect(
        schemaIssues(chapterFile(chapterMeta(1), [verse(1, 41)])),
        isEmpty,
      );
      expect(schemaIssues(chapterFile(chapterMeta(5))), isEmpty);
    });

    test('wrong property types fail with path and message', () {
      final doc = chapterFile(chapterMeta(1), [verse(1, 41)]);
      ((doc['verses']! as List).first as Map)['hindi_meaning'] = 5;
      final issue = schemaIssues(doc).single;
      expect(issue.fileName, 'chapter_01.json');
      expect(issue.jsonPath, r'$.verses[0].hindi_meaning');
      expect(issue.severity, ValidationSeverity.error);
      expect(issue.code, ValidationCode.schemaValidationFailed);
      expect(issue.message, startsWith('Expected a string value'));
    });

    test('missing required fields fail', () {
      final doc = chapterFile(chapterMeta(1))..remove('verses');
      expect(
        schemaIssues(doc).map((i) => i.message),
        contains('Missing required property "verses".'),
      );
    });

    test('invalid nested structures fail', () {
      final doc = chapterFile(chapterMeta(1), [
        verse(
          1,
          1,
          attributions: [
            {'source_id': 'Not Snake Case', 'content_section': 'context'},
          ],
        ),
      ]);
      final issue = schemaIssues(doc).single;
      expect(issue.jsonPath, r'$.verses[0].source_attributions[0].source_id');
    });

    test(
      'unexpected properties are rejected (additionalProperties: false)',
      () {
        final top = chapterFile(chapterMeta(1))..['notes'] = 'x';
        expect(schemaIssues(top).single.message, contains('"notes"'));

        final nested = chapterFile(chapterMeta(1), [verse(1, 1)]);
        ((nested['verses']! as List).first as Map)['user_answer'] = 'x';
        final issue = schemaIssues(nested).single;
        expect(issue.jsonPath, r'$.verses[0]');
        expect(issue.message, contains('"user_answer"'));
      },
    );

    test('well-known fields get specific error codes', () {
      String codeOf(Map<String, Object?> doc) => schemaIssues(doc).first.code;

      expect(
        codeOf(chapterFile(chapterMeta(19))),
        ValidationCode.invalidChapterId,
      );
      final badNumber = chapterFile(chapterMeta(1), [verse(1, 1)]);
      ((badNumber['verses']! as List).first as Map)['verse_number'] = 0;
      expect(codeOf(badNumber), ValidationCode.invalidVerseNumber);
      expect(
        codeOf(chapterFile(chapterMeta(1), [verse(1, 1, reference: '1.01')])),
        ValidationCode.invalidReference,
      );
      expect(
        codeOf(chapterFile(chapterMeta(1), [verse(1, 1, id: 'verse-1')])),
        ValidationCode.invalidShlokaId,
      );
      expect(
        codeOf(
          chapterFile(chapterMeta(1), [
            verse(
              1,
              1,
              attributions: [
                {'source_id': testSourceId, 'content_section': 'answer'},
              ],
            ),
          ]),
        ),
        ValidationCode.invalidContentSection,
      );
    });

    test('hindi_meaning_note is an allowed attribution section', () {
      final doc = chapterFile(chapterMeta(1), [
        verse(
          1,
          1,
          attributions: [
            {
              'source_id': testSourceId,
              'content_section': 'hindi_meaning_note',
            },
          ],
        ),
      ]);
      expect(schemaIssues(doc), isEmpty);
    });

    test('JSON Pointers become readable paths', () {
      expect(JsonSchemaValidator.jsonPointerToPath(''), r'$');
      expect(
        JsonSchemaValidator.jsonPointerToPath(
          '/verses/0/source_attributions/2',
        ),
        r'$.verses[0].source_attributions[2]',
      );
    });
  });

  group('deterministic content ids (UUID v5)', () {
    test('match the RFC 4122 algorithm (cross-checked with Python uuid5)', () {
      expect(
        uuidV5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'www.example.com'),
        '2ed6657d-e927-568b-95e1-2665a8aea6a2',
      );
      expect(
        ContentIds.shloka('chapter_01_verse_041'),
        '8c555087-1c57-50db-9632-7bbd1e10a472',
      );
      expect(
        ContentIds.source(testSourceId),
        '5c132c83-a915-50de-b00f-029b7728df60',
      );
      expect(
        uuidV5(ContentIds.namespace, 'shloka/अधर्म'),
        '9f7f07b7-046c-5078-9232-766c26b4c0bb',
      );
    });

    test('are stable and distinct', () {
      expect(
        ContentIds.shloka('chapter_01_verse_041'),
        ContentIds.shloka('chapter_01_verse_041'),
      );
      expect(
        ContentIds.shloka('chapter_01_verse_041'),
        isNot(ContentIds.shloka('chapter_01_verse_042')),
      );
    });
  });
}
