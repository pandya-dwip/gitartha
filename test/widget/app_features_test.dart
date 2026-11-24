import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/app/app.dart';
import 'package:gitartha/app/router/app_router.dart';
import 'package:gitartha/core/config/app_config.dart';
import 'package:gitartha/core/config/app_config_provider.dart';
import 'package:gitartha/data/local/database/app_database.dart';
import 'package:gitartha/data/local/local_database_providers.dart';
import 'package:gitartha/data/local/repositories/local_database_repository.dart';
import 'package:gitartha/features/authentication/presentation/providers/auth_state_provider.dart';

import '../unit/data/local/test_database.dart';
import '../unit/features/authentication/fake_auth_repository.dart';

/// The real app, router and screens over an in-memory SQLite database with
/// placeholder (TEST) content, a signed-in member, and no backend (offline).
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  final v11 = testUuid(1001);
  final v12 = testUuid(1002);

  Future<void> seed() async {
    await LocalDatabaseRepository(db).cacheContent(
      chapters: [
        chapterFixture(1, overview: 'TEST overview one'),
        chapterFixture(2),
      ],
      shlokas: [
        shlokaFixture(
          1,
          1,
          indexTitle: 'TEST first verse',
          englishMeaning: 'TEST english one',
        ),
        shlokaFixture(
          1,
          2,
          indexTitle: 'TEST second verse',
          englishMeaning: 'TEST english two',
        ),
        for (var v = 1; v <= 12; v++) shlokaFixture(2, v),
      ],
    );
  }

  Future<void> launch(
    WidgetTester tester, {
    bool isEditor = false,
    bool seeded = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    db = openTestDatabase();
    addTearDown(db.close);
    if (seeded) await seed();
    final user = isEditor ? editor : reader;
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.fromMap(const {})),
        appDatabaseProvider.overrideWithValue(db),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            restoredUser: user,
            members: {user.id: membership(user, isAccessible: isEditor)},
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const GitarthaApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  String location() => container
      .read(appRouterProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .path;

  Future<void> go(WidgetTester tester, String path) async {
    container.read(appRouterProvider).go(path);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f.first);
    await tester.pumpAndSettle();
    await tester.tap(f.first);
    await tester.pumpAndSettle();
  }

  /// Scrolls the reader (or any single ListView screen) until [f] is built.
  Future<void> scrollTo(WidgetTester tester, Finder f) async {
    await tester.dragUntilVisible(
      f,
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
  }

  Future<List<ReadingHistoryEntry>> history() =>
      db.select(db.readingHistory).get();

  testWidgets(
    'home shows cached content; chapters → overview → index → reader',
    (tester) async {
      await launch(tester);
      expect(location(), AppRoutes.home);
      expect(
        find.text('Peace to the mind, stillness to the heart'),
        findsOneWidget,
      );
      expect(
        find.text('14 sacred verses saved on this device'),
        findsOneWidget,
      );
      expect(find.text('0 of 18 Chapters explored'), findsOneWidget);

      await tap(tester, find.text('Read'));
      expect(location(), AppRoutes.chapters);
      expect(find.text('CHAPTER LIBRARY'), findsOneWidget);
      expect(find.text('TEST sanskrit name 1'), findsOneWidget);
      expect(find.text('2 Verses'), findsOneWidget);

      await tap(tester, find.text('TEST sanskrit name 1'));
      expect(location(), AppRoutes.chapter(1));
      expect(find.text('TEST overview one'), findsOneWidget);
      expect(find.text('TEST topic A'), findsOneWidget);

      await tap(tester, find.text('Explore All 2 Verses'));
      expect(location(), AppRoutes.verses(1));
      await tap(tester, find.text('TEST second verse'));
      expect(location(), AppRoutes.verse(1, 2));
      expect(find.text('BG 1.2'), findsOneWidget);
      expect(find.text('Verse 2 of 2'), findsOneWidget);
      expect(find.text('TEST english two'), findsOneWidget);
      expect(find.textContaining('TEST hindi wording note'), findsOneWidget);

      // System back walks up the hierarchy.
      await tester.binding.handlePopRoute(); // Android system back
      await tester.pumpAndSettle();
      expect(location(), AppRoutes.verses(1));
    },
  );

  testWidgets(
    'opening a verse records history once and never marks it studied',
    (tester) async {
      await launch(tester);
      await go(tester, AppRoutes.verse(1, 1));
      await tester.pump(const Duration(milliseconds: 50));
      // Rebuilds (here: a text-size change) must not log again.
      await tap(tester, find.byTooltip('Text size: Medium'));
      await tester.pumpAndSettle();

      final h = await history();
      expect(h.length, 1);
      expect(h.single.shlokaId, v11);
      final progress = await db.readingProgressDao.getProgress(v11);
      expect(progress!.status, ReadingStatus.opened);

      // Home now offers to continue there.
      await go(tester, AppRoutes.home);
      expect(find.text('Last read: Shloka 1.1'), findsOneWidget);
      expect(find.text('1 of 18 Chapters explored'), findsOneWidget);
    },
  );

  testWidgets('verse navigation: next / previous and range chips', (
    tester,
  ) async {
    await launch(tester);
    await go(tester, AppRoutes.verses(2));
    expect(find.text('2.1 – 2.10'), findsOneWidget);
    expect(find.text('2.11 – 2.12'), findsOneWidget);
    expect(find.text('Verse 2.12'), findsNothing, reason: 'first range shown');
    await tap(tester, find.text('2.11 – 2.12'));
    expect(find.text('TEST title 2.12'), findsOneWidget);
    expect(find.text('TEST title 2.1'), findsNothing);

    await go(tester, AppRoutes.verse(1, 1));
    await scrollTo(tester, find.text('Verse 1.2'));
    expect(find.text('Beginning'), findsOneWidget);
    await tap(tester, find.text('Verse 1.2'));
    expect(location(), AppRoutes.verse(1, 2));
    await scrollTo(tester, find.text('End of Ch 1'));
    expect(find.text('End of Ch 1'), findsOneWidget);
  });

  testWidgets('bookmarks persist and appear in the Bookmarks tab', (
    tester,
  ) async {
    await launch(tester);
    await go(tester, AppRoutes.bookmarks);
    expect(find.text('No bookmarks yet'), findsOneWidget);

    await go(tester, AppRoutes.verse(1, 1));
    await tap(tester, find.byTooltip('Bookmark this verse'));
    expect(await db.bookmarkDao.isBookmarked(v11), isTrue);
    expect(find.byTooltip('Remove bookmark'), findsOneWidget);
    // Tapping twice quickly cannot create duplicates (unique per verse).
    expect((await db.select(db.bookmarks).get()).length, 1);

    await tap(tester, find.text('Bookmarks'));
    expect(find.text('TEST first verse'), findsOneWidget);
    await tap(tester, find.byTooltip('Remove bookmark'));
    expect(await db.bookmarkDao.isBookmarked(v11), isFalse);
    expect(find.text('No bookmarks yet'), findsOneWidget);
  });

  testWidgets(
    'reflections: new answers are separate records; edit updates in place',
    (tester) async {
      await launch(tester);
      await go(tester, AppRoutes.verse(1, 1));
      final field = find.widgetWithText(
        TextField,
        'Write your answer to the reflection question…',
      );
      await scrollTo(tester, field);
      await tester.enterText(field, 'My first answer');
      await tap(tester, find.text('Save reflection'));
      expect(find.text('Reflection saved on this device.'), findsOneWidget);

      await tester.enterText(field, 'My second answer');
      await tap(tester, find.text('Save new reflection'));
      var rows = await db.select(db.reflections).get();
      expect(
        rows.map((r) => r.answer),
        unorderedEquals(['My first answer', 'My second answer']),
      );
      expect(
        (await db.readingProgressDao.getProgress(v11))!.status,
        ReadingStatus.reflected,
      );

      // Edit the first answer.
      final first = rows.firstWhere((r) => r.answer == 'My first answer');
      await scrollTo(tester, find.text('My first answer'));
      final editButtons = find.byTooltip('Edit reflection');
      await tap(tester, editButtons.last); // oldest is listed last
      await tester.enterText(
        find.byType(TextField).last,
        'My first answer, revised',
      );
      await tap(tester, find.text('Save'));
      rows = await db.select(db.reflections).get();
      expect(rows.length, 2, reason: 'no accidental duplicate');
      expect(
        rows.firstWhere((r) => r.id == first.id).answer,
        'My first answer, revised',
      );

      // The journal lists both.
      await go(tester, AppRoutes.journal);
      expect(find.text('My first answer, revised'), findsOneWidget);
      expect(find.text('My second answer'), findsOneWidget);
    },
  );

  testWidgets('progress is explicit: read, then studied', (tester) async {
    await launch(tester);
    await go(tester, AppRoutes.verse(1, 2));
    await scrollTo(tester, find.widgetWithText(OutlinedButton, 'Read'));
    await tap(tester, find.widgetWithText(OutlinedButton, 'Read'));
    expect(
      (await db.readingProgressDao.getProgress(v12))!.status,
      ReadingStatus.read,
    );
    await tap(tester, find.widgetWithText(OutlinedButton, 'Studied'));
    expect(
      (await db.readingProgressDao.getProgress(v12))!.status,
      ReadingStatus.studied,
    );
    expect(find.text('You have studied this verse.'), findsOneWidget);
  });

  testWidgets('notes: on a verse and free-standing, edited and deleted', (
    tester,
  ) async {
    await launch(tester);
    await go(tester, AppRoutes.verse(1, 1));
    await scrollTo(tester, find.text('Add note'));
    await tap(tester, find.text('Add note'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Title (optional)'),
      'TEST my title',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Write your note…'),
      'TEST my note',
    );
    await tap(tester, find.text('Save note'));
    var notes = await db.select(db.personalNotes).get();
    expect(notes.single.shlokaId, v11);
    expect(notes.single.title, 'TEST my title');

    await go(tester, AppRoutes.journal);
    await tap(tester, find.text('Notes'));
    expect(find.text('TEST my note'), findsOneWidget);

    await tap(tester, find.text('New note'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Write your note…'),
      'TEST standalone',
    );
    await tap(tester, find.text('Save note'));
    notes = await db.select(db.personalNotes).get();
    expect(notes.length, 2);
    expect(
      notes.firstWhere((n) => n.content == 'TEST standalone').shlokaId,
      isNull,
    );

    // Edit, then delete.
    await tap(tester, find.text('TEST standalone'));
    await tester.enterText(
      find.widgetWithText(TextField, 'TEST standalone'),
      'TEST edited',
    );
    await tap(tester, find.text('Save note'));
    expect(
      (await db.select(db.personalNotes).get()).map((n) => n.content),
      contains('TEST edited'),
    );
    await tap(tester, find.text('TEST edited'));
    await tap(tester, find.byTooltip('Delete note'));
    await tap(tester, find.widgetWithText(FilledButton, 'Delete'));
    expect((await db.select(db.personalNotes).get()).length, 1);
  });

  testWidgets('search finds cached verses and chapters, and clears', (
    tester,
  ) async {
    await launch(tester);
    await go(tester, AppRoutes.chapters);
    await tester.enterText(find.byType(TextField), 'second verse');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('1 VERSE'), findsOneWidget);
    expect(find.text('TEST second verse'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz-nothing');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'TEST english name 2');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await tap(tester, find.text('TEST sanskrit name 2'));
    expect(location(), AppRoutes.chapter(2));

    await go(tester, AppRoutes.chapters);
    await tester.enterText(find.byType(TextField), 'second verse');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await tap(tester, find.text('TEST second verse'));
    expect(location(), AppRoutes.verse(1, 2));
  });

  testWidgets(
    'settings: theme and font size persist; offline sync is reported',
    (tester) async {
      await launch(tester);
      await tap(tester, find.byTooltip('Settings & About'));
      expect(find.text('Gitartha Settings'), findsOneWidget);
      expect(find.text('Not updated on this device yet'), findsOneWidget);

      await tap(tester, find.text('Night Mode'));
      expect(await db.settingsDao.getValue(LocalSettingKeys.themeMode), 'dark');
      expect(find.text('Ivory Mode'), findsOneWidget);

      await tap(tester, find.text('Medium'));
      expect(
        await db.settingsDao.getValue(LocalSettingKeys.bodyFontScale),
        1.15,
      );
      expect(find.text('Large'), findsOneWidget);

      // No backend in this test: a manual check reports offline, cached
      // content stays readable.
      await tap(tester, find.text('Check now'));
      expect(find.textContaining('Offline'), findsOneWidget);
      await tap(tester, find.text('Done'));
      expect(find.text('TEST sanskrit name 1'), findsWidgets);
    },
  );

  for (final isEditor in [false, true]) {
    testWidgets(
      '${isEditor ? 'editor' : 'read-only member'}: same app, no editing tools',
      (tester) async {
        await launch(tester, isEditor: isEditor);
        expect(location(), AppRoutes.home);
        for (final tab in ['Home', 'Read', 'Bookmarks', 'My Journal']) {
          expect(find.text(tab), findsWidgets);
        }
        await go(tester, AppRoutes.verse(1, 1));
        expect(find.textContaining('Edit verse'), findsNothing);
        expect(find.textContaining('Publish'), findsNothing);
        await go(tester, AppRoutes.home);
        await tap(tester, find.byTooltip('Settings & About'));
        expect(
          find.text(
            isEditor
                ? 'Editor access: you may also publish shared scripture.'
                : 'Read-only access.',
          ),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('first launch with nothing cached shows a calm offline state', (
    tester,
  ) async {
    await launch(tester, seeded: false);
    expect(find.text('No scripture on this device yet'), findsOneWidget);
    await tap(tester, find.text('Download scripture'));
    expect(find.textContaining('offline'), findsOneWidget);
  });

  testWidgets('bad or missing routes do not crash', (tester) async {
    await launch(tester);
    await go(tester, '/chapters/9');
    expect(find.text('Chapter not available'), findsOneWidget);
    await go(tester, '/chapters/abc/verses/1');
    expect(find.text('Verse not available'), findsOneWidget);
    await go(tester, AppRoutes.verse(1, 99));
    expect(find.text('Verse not available'), findsOneWidget);
    await go(tester, '/no-such-page');
    expect(find.text('Page not found'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'every screen fits a small phone with large text (${dark ? 'dark' : 'light'})',
      (tester) async {
        await launch(tester);
        tester.view.physicalSize = const Size(320 * 2, 640 * 2);
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        if (dark) {
          await db.settingsDao.setValue(LocalSettingKeys.themeMode, 'dark');
        }
        await tester.pumpAndSettle();
        for (final path in [
          AppRoutes.home,
          AppRoutes.chapters,
          AppRoutes.chapter(1),
          AppRoutes.verses(2),
          AppRoutes.verse(1, 1),
          AppRoutes.bookmarks,
          AppRoutes.journal,
        ]) {
          await go(tester, path);
          expect(tester.takeException(), isNull, reason: path);
        }
        await go(tester, AppRoutes.home);
        await tap(tester, find.byTooltip('Settings & About'));
        expect(tester.takeException(), isNull, reason: 'settings sheet');
        expect(
          Theme.of(tester.element(find.text('Gitartha Settings'))).brightness,
          dark ? Brightness.dark : Brightness.light,
        );
      },
    );
  }

  testWidgets(
    'light is the default theme, even when the phone is in dark mode',
    (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await launch(tester);
      expect(
        Theme.of(
          tester.element(
            find.text('Peace to the mind, stillness to the heart'),
          ),
        ).brightness,
        Brightness.light,
      );
    },
  );

  testWidgets('reader: journal, then progress; no sources; centred title', (
    tester,
  ) async {
    await launch(tester);
    await go(tester, AppRoutes.verse(1, 1));
    expect(find.text('SOURCES'), findsNothing);
    await scrollTo(tester, find.text('MY PROGRESS'));
    final journal = tester.getTopLeft(
      find.text('MY PERSONAL JOURNAL & REFLECTIONS'),
    );
    final progress = tester.getTopLeft(find.text('MY PROGRESS'));
    expect(journal.dy, lessThan(progress.dy));
    // The top-bar title sits in the middle of the screen. (A wider screen,
    // because the square-glyph test font is far wider than real text.)
    tester.view.physicalSize = const Size(1800, 2400);
    await tester.pumpAndSettle();
    final title = tester.getCenter(find.text('BG 1.1'));
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect((title.dx - width / 2).abs(), lessThan(2));
  });
}
