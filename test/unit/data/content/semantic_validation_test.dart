import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/content/services/content_validation_service.dart';
import 'package:gitartha/data/content/services/file_system_content_source.dart';
import 'package:gitartha/data/content/validators/validation_result.dart';

import 'content_fixtures.dart';

void main() {
  Future<ContentValidationReport> run(
    Map<String, Object?> chapters, {
    Object? sources,
    ValidationMode mode = ValidationMode.draft,
  }) => ContentValidationService(
    MapContentSource(chapters: chapters, sources: sources ?? sourcesFixture()),
  ).validate(mode: mode, chapterIds: _ids(chapters));

  List<String> codes(ContentValidationReport r, ValidationSeverity severity) =>
      [
        for (final i in r.result.issues)
          if (i.severity == severity) i.code,
      ];

  group('chapters', () {
    test('chapter id must match the file name', () async {
      final r = await run({fileFor(2): chapterFile(chapterMeta(3))});
      final issue = r.result.errors.firstWhere(
        (i) => i.code == ValidationCode.chapterIdFilenameMismatch,
      );
      expect(issue.fileName, 'chapter_02.json');
      expect(issue.jsonPath, r'$.chapter.id');
      expect(r.chapters.single.isUsable, isFalse);
    });

    test('chapter ids must be unique across files', () async {
      final r = await run({
        fileFor(1): chapterFile(chapterMeta(1)),
        fileFor(2): chapterFile(chapterMeta(1)),
      });
      expect(codes(r, ValidationSeverity.error), [
        ValidationCode.chapterIdFilenameMismatch,
        ValidationCode.duplicateChapterId,
      ]);
    });

    test('missing and unexpected files are reported', () async {
      final r = await ContentValidationService(
        MapContentSource(
          chapters: {
            fileFor(1): chapterFile(chapterMeta(1)),
            'chapter_1.json': chapterFile(chapterMeta(1)),
          },
          sources: sourcesFixture(),
        ),
      ).validate();
      final errors = codes(r, ValidationSeverity.error);
      expect(
        errors.where((c) => c == ValidationCode.missingFile),
        hasLength(17),
      );
      expect(errors, contains(ValidationCode.unexpectedFile));
    });

    test('an empty chapter is incomplete, not malformed', () async {
      final draft = await run({fileFor(1): chapterFile(chapterMeta(1))});
      expect(draft.result.isValid, isTrue);
      expect(codes(draft, ValidationSeverity.info), [
        ValidationCode.missingVerses,
      ]);
      expect(codes(draft, ValidationSeverity.warning), [
        ValidationCode.incompleteContent,
      ]);

      final strict = await run({
        fileFor(1): chapterFile(chapterMeta(1)),
      }, mode: ValidationMode.strict);
      expect(strict.result.isValid, isFalse);
      expect(
        codes(strict, ValidationSeverity.error),
        containsAll([
          ValidationCode.incompleteContent,
          ValidationCode.notApproved,
          ValidationCode.missingVerses,
        ]),
      );
      expect(strict.chapters.single.isUsable, isTrue); // still importable shape
    });

    test('approved metadata must be complete', () async {
      final r = await run({
        fileFor(1): chapterFile(
          chapterMeta(1, named: true, status: 'approved'),
        ),
      });
      final issue = r.result.errors.single;
      expect(issue.code, ValidationCode.incompleteContent);
      expect(issue.scope, IssueScope.chapterMetadata);
    });
  });

  group('verses', () {
    test('duplicate verse numbers and ids are errors', () async {
      final r = await run({
        fileFor(1): chapterFile(chapterMeta(1), [verse(1, 1), verse(1, 1)]),
      });
      expect(
        codes(r, ValidationSeverity.error),
        containsAll([
          ValidationCode.duplicateVerseNumber,
          ValidationCode.duplicateShlokaId,
          ValidationCode.versesOutOfOrder,
        ]),
      );
      expect(r.chapters.single.verses.map((v) => v.hasErrors), [false, true]);
    });

    test('reference and id must agree with chapter and verse', () async {
      final r = await run({
        fileFor(1): chapterFile(chapterMeta(1), [
          verse(1, 41, reference: '1.42'),
          verse(1, 42, id: 'chapter_01_verse_043'),
        ]),
      });
      final errors = r.result.errors;
      expect(errors[0].code, ValidationCode.invalidReference);
      expect(errors[0].jsonPath, r'$.verses[0].reference');
      expect(errors[0].message, contains('"1.41"'));
      expect(errors[1].code, ValidationCode.invalidShlokaId);
      expect(errors[1].recordId, 'chapter_01_verse_043');
    });

    test('verse ids are unique across chapters', () async {
      final r = await run({
        fileFor(1): chapterFile(chapterMeta(1), [verse(1, 1)]),
        fileFor(2): chapterFile(chapterMeta(2), [
          verse(2, 1, id: 'chapter_01_verse_001'),
        ]),
      });
      expect(
        codes(r, ValidationSeverity.error),
        contains(ValidationCode.duplicateShlokaId),
      );
    });

    test('verses must be in ascending order', () async {
      final r = await run({
        fileFor(1): chapterFile(chapterMeta(1), [verse(1, 2), verse(1, 1)]),
      });
      expect(codes(r, ValidationSeverity.error), [
        ValidationCode.versesOutOfOrder,
      ]);
    });

    test(
      'incomplete verses: info-free structural, warning draft, error strict',
      () async {
        final files = {
          fileFor(1): chapterFile(chapterMeta(1, complete: true), [
            verse(1, 41, blank: {'index_summary', 'context'}),
          ]),
        };
        bool hasIncompleteVerse(ContentValidationReport r) =>
            r.result.issues.any(
              (i) =>
                  i.code == ValidationCode.incompleteContent &&
                  i.scope == IssueScope.verse,
            );

        final structural = await run(files, mode: ValidationMode.structural);
        expect(structural.result.isValid, isTrue);
        expect(hasIncompleteVerse(structural), isFalse);
        expect(structural.result.incompleteVerses, 1);

        final draft = await run(files);
        expect(draft.result.isValid, isTrue);
        final warning = draft.result.warnings.firstWhere(
          (i) => i.scope == IssueScope.verse,
        );
        expect(warning.code, ValidationCode.incompleteContent);
        expect(warning.message, contains('index_summary, context'));

        final strict = await run(files, mode: ValidationMode.strict);
        expect(strict.result.isValid, isFalse);
        expect(
          strict.result.errors
              .where((i) => i.scope == IssueScope.verse)
              .map((i) => i.code),
          [ValidationCode.incompleteContent, ValidationCode.notApproved],
        );
      },
    );

    test('hindi_meaning_note is optional for completeness', () async {
      final r = await run({
        fileFor(1): chapterFile(chapterMeta(1), [verse(1, 1, hindiNote: null)]),
      });
      expect(r.chapters.single.verses.single.isComplete, isTrue);
    });

    test('an "approved" verse must be complete and sourced', () async {
      final r = await run({
        fileFor(1): chapterFile(chapterMeta(1), [
          verse(1, 1, status: 'approved', blank: {'context'}),
          verse(1, 2, status: 'approved'),
          verse(
            1,
            3,
            status: 'approved',
            attributions: requiredAttributions(unlicensedSourceId),
          ),
        ]),
      }, sources: sourcesFixture(includeUnlicensed: true));
      final byVerse = {
        for (final i in r.result.errors) '${i.recordId}:${i.code}': i,
      };
      expect(byVerse.keys, {
        'chapter_01_verse_001:${ValidationCode.incompleteContent}',
        'chapter_01_verse_001:${ValidationCode.missingAttribution}',
        'chapter_01_verse_002:${ValidationCode.missingAttribution}',
        'chapter_01_verse_003:${ValidationCode.unverifiedSourceLicense}',
      });
    });

    test('a complete, approved, sourced verse passes strict checks', () async {
      final r = await run({
        fileFor(1): chapterFile(
          chapterMeta(1, complete: true, status: 'approved'),
          [approvedVerse(1, 1)],
        ),
      }, mode: ValidationMode.strict);
      // Only the chapter coverage is missing (1 of 47 verses).
      expect(codes(r, ValidationSeverity.error), [
        ValidationCode.missingVerses,
      ]);
      expect(r.chapters.single.verses.single.isApproved, isTrue);
      expect(r.result.approvedVerses, 1);
    });
  });

  group('sources and attributions', () {
    test('unknown source ids are errors', () async {
      final r = await run({
        fileFor(1): chapterFile(chapterMeta(1), [
          verse(
            1,
            1,
            attributions: [
              {'source_id': 'nobody', 'content_section': 'english_meaning'},
            ],
          ),
        ]),
      });
      final issue = r.result.errors.single;
      expect(issue.code, ValidationCode.unknownSourceId);
      expect(issue.jsonPath, r'$.verses[0].source_attributions[0].source_id');
    });

    test('attributions must point at sections with text', () async {
      final r = await run({
        fileFor(1): chapterFile(chapterMeta(1), [
          verse(
            1,
            1,
            hindiNote: null,
            attributions: [
              {
                'source_id': testSourceId,
                'content_section': 'hindi_meaning_note',
              },
            ],
          ),
        ]),
      });
      expect(codes(r, ValidationSeverity.error), [
        ValidationCode.attributionForEmptySection,
      ]);
    });

    test('invalid sections are rejected', () async {
      final r = await run({
        fileFor(1): chapterFile(chapterMeta(1), [
          verse(
            1,
            1,
            attributions: [
              {'source_id': testSourceId, 'content_section': 'user_answer'},
            ],
          ),
        ]),
      });
      expect(r.result.errors.single.code, ValidationCode.invalidContentSection);
    });

    test('duplicate source ids are errors; unlicensed sources warn', () async {
      final doubled = sourcesFixture(includeUnlicensed: true);
      (doubled['sources']! as List).add((doubled['sources']! as List).first);
      final r = await run({
        fileFor(1): chapterFile(chapterMeta(1)),
      }, sources: doubled);
      expect(r.result.errors.single.code, ValidationCode.duplicateSourceId);
      expect(
        r.result.warnings.map((w) => w.code),
        contains(ValidationCode.unverifiedSourceLicense),
      );
    });

    test(
      'an unusable sources.json is reported and skips reference checks',
      () async {
        final r = await run({
          fileFor(1): chapterFile(chapterMeta(1), [
            verse(
              1,
              1,
              attributions: [
                {'source_id': 'nobody', 'content_section': 'context'},
              ],
            ),
          ]),
        }, sources: '{not json');
        expect(codes(r, ValidationSeverity.error), [
          ValidationCode.invalidJson,
        ]);
        expect(
          codes(r, ValidationSeverity.warning),
          contains(ValidationCode.sourcesUnavailable),
        );
        expect(r.sourcesUsable, isFalse);
      },
    );
  });

  group('the real repository (read-only)', () {
    final service = ContentValidationService(FileSystemContentSource());

    test('all 18 files are valid in structural and draft modes', () async {
      for (final mode in [ValidationMode.structural, ValidationMode.draft]) {
        final r = (await service.validate(mode: mode)).result;
        expect(r.isValid, isTrue, reason: '${mode.name}: ${r.errors}');
        expect(r.totalFiles, 19); // 18 chapters + sources.json
        expect(r.validFiles, 19);
        expect(r.totalChapters, 18);
        expect(r.totalVerses, 1);
        expect(r.approvedVerses, 0);
      }
    });

    test('strict mode correctly refuses the unreviewed repository', () async {
      final r = (await service.validate(mode: ValidationMode.strict)).result;
      expect(r.isValid, isFalse);
      expect(r.publicationReadyChapters, 0);
    });

    test(
      'Verse 1.41 is structurally valid, incomplete only for its summary',
      () async {
        final report = await service.validate(chapterIds: [1]);
        final verse = report.chapters.single.verses.single;
        expect(verse.contentId, 'chapter_01_verse_041');
        expect(verse.hasErrors, isFalse);
        expect(verse.missingFields, ['index_summary']);
        expect(verse.isApproved, isFalse);
      },
    );
  });
}

Set<int> _ids(Map<String, Object?> chapters) => {
  for (final name in chapters.keys)
    if (RegExp(r'^chapter_(\d\d)\.json$').firstMatch(name) case final m?)
      int.parse(m.group(1)!),
};
