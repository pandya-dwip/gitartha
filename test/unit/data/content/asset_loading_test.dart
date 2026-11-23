import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/content/content_constants.dart';
import 'package:gitartha/data/content/services/asset_bundle_content_source.dart';
import 'package:gitartha/data/content/services/content_asset_loader.dart';
import 'package:gitartha/data/content/services/content_validation_service.dart';
import 'package:gitartha/data/content/services/file_system_content_source.dart';
import 'package:gitartha/data/content/validators/validation_result.dart';

import 'content_fixtures.dart';

/// Loads the real content through the Flutter asset bundle (as the app
/// does) and from disk (as the CLI does). Read-only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('asset bundle (pubspec.yaml registration)', () {
    final loader = ContentAssetLoader(AssetBundleContentSource());

    test('all 18 chapter files are discoverable', () async {
      final files = await AssetBundleContentSource().listChapterFiles();
      expect(files, [
        for (var n = 1; n <= 18; n++) GitaContent.chapterFileName(n),
      ]);
      final all = await loader.loadChapters();
      expect(all.isComplete, isTrue);
      expect(all.files, hasLength(18));
      expect(all.unexpected, isEmpty);
    });

    test('an individual chapter loads', () async {
      final file = await loader.loadChapter(1);
      expect(file.fileName, 'chapter_01.json');
      final json = jsonDecode(file.text) as Map<String, dynamic>;
      expect((json['chapter'] as Map)['id'], 1);
      expect(file.text, contains('chapter_01_verse_041'));
    });

    test('the sources repository and both schemas load', () async {
      final sources = await loader.loadSources();
      expect(jsonDecode(sources.text), {'sources': <Object>[]});
      expect(
        await loader.loadSchema('chapter.schema.json'),
        contains('2020-12'),
      );
      expect(
        await loader.loadSchema('sources.schema.json'),
        contains('sources'),
      );
    });

    test('documentation files are not bundled', () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final keys = manifest.listAssets();
      expect(keys.where((k) => k.contains('bhagavad_gita')), isNotEmpty);
      expect(keys.where((k) => k.endsWith('.md')), isEmpty);
    });

    test(
      'validation over the bundle matches validation over the files',
      () async {
        final bundled = await ContentValidationService(
          AssetBundleContentSource(),
        ).validate();
        final onDisk = await ContentValidationService(
          FileSystemContentSource(),
        ).validate();
        expect(bundled.result.isValid, isTrue);
        expect(
          jsonEncode(bundled.result.toJson()..remove('source')),
          jsonEncode(onDisk.result.toJson()..remove('source')),
        );
      },
    );

    test('a missing asset produces a useful error', () async {
      await expectLater(
        AssetBundleContentSource().readChapterFile('chapter_99.json'),
        throwsA(
          isA<ContentLoadException>()
              .having((e) => e.fileName, 'fileName', 'chapter_99.json')
              .having((e) => e.message, 'message', contains('pubspec.yaml')),
        ),
      );
      await expectLater(
        loader.loadChapter(19),
        throwsA(isA<ContentLoadException>()),
      );
    });
  });

  group('missing files', () {
    test('are listed by the loader and reported by validation', () async {
      final source = MapContentSource(
        chapters: {
          for (var n = 1; n <= 18; n++)
            if (n != 5) fileFor(n): chapterFile(chapterMeta(n)),
        },
      );
      final load = await ContentAssetLoader(source).loadChapters();
      expect(load.missing, ['chapter_05.json']);
      expect(load.files, hasLength(17));

      await expectLater(
        ContentAssetLoader(source).loadChapter(5),
        throwsA(
          isA<ContentLoadException>().having(
            (e) => e.message,
            'message',
            contains('not found'),
          ),
        ),
      );

      final report = await ContentValidationService(source).validate();
      final issue = report.result.errors.single;
      expect(issue.code, ValidationCode.missingFile);
      expect(issue.fileName, 'chapter_05.json');
    });

    test('a missing repository directory is reported clearly', () async {
      await expectLater(
        FileSystemContentSource('does/not/exist').listChapterFiles(),
        throwsA(isA<ContentLoadException>()),
      );
    });
  });
}
