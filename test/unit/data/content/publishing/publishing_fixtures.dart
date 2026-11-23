import 'package:gitartha/data/content/publishing/publishing_models.dart';
import 'package:gitartha/data/content/publishing/publishing_planner.dart';
import 'package:gitartha/data/content/services/content_validation_service.dart';
import 'package:gitartha/data/content/validators/validation_result.dart';

import '../content_fixtures.dart';
import 'fake_remote_store.dart';

const String editorEmail = 'editor@example.test';
const String editorPassword = 'TEST-editor-password';
const String editorId = '00000000-0000-4000-8000-00000000e001';
const String readerEmail = 'reader@example.test';
const String readerPassword = 'TEST-reader-password';
const String readerId = '00000000-0000-4000-8000-00000000e002';
const String strangerEmail = 'stranger@example.test';
const String strangerPassword = 'TEST-stranger-password';

/// A fake Supabase with an editor (is_accessible = true), a read-only
/// reader, and a signed-up user without any membership.
FakeRemoteStore newRemote() => FakeRemoteStore(
  users: {
    editorEmail: (password: editorPassword, userId: editorId),
    readerEmail: (password: readerPassword, userId: readerId),
    strangerEmail: (
      password: strangerPassword,
      userId: '00000000-0000-4000-8000-00000000e003',
    ),
  },
  members: {editorId: true, readerId: false},
);

/// All 18 chapter files: empty templates, except [chapters] overrides.
MapContentSource repository(
  Map<int, Map<String, Object?>> chapters, {
  Object? sources,
}) => MapContentSource(
  chapters: {
    for (var n = 1; n <= 18; n++)
      fileFor(n): chapters[n] ?? chapterFile(chapterMeta(n)),
  },
  sources: sources ?? sourcesFixture(),
);

/// Chapter 1: approved, complete metadata with [verses] (default: three
/// approved, sourced verses 1.1–1.3).
Map<String, Object?> approvedChapterOne([List<Map<String, Object?>>? verses]) =>
    chapterFile(chapterMeta(1, complete: true, status: 'approved'), [
      ...(verses ?? [for (var v = 1; v <= 3; v++) approvedVerse(1, v)]),
    ]);

Future<ContentValidationReport> strictReport(MapContentSource source) =>
    ContentValidationService(source).validate(mode: ValidationMode.strict);

/// Plans [source] against [remote] (signed in as the editor).
Future<PublishingPlan> planAgainst(
  MapContentSource source,
  FakeRemoteStore remote, {
  PublishingScope scope = const PublishingScope.all(),
}) async {
  if (remote.currentUser == null) {
    await remote.signIn(email: editorEmail, password: editorPassword);
  }
  return const PublishingPlanner().plan(
    report: await strictReport(source),
    scope: scope,
    store: remote,
  );
}
