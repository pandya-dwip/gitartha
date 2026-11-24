import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guards on the shipped app code (`lib/`). RLS is the real
/// boundary; these catch regressions that would undermine it from the
/// client side.
void main() {
  Iterable<(String, String)> sources(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => (f.path, f.readAsStringSync()));

  test('the app never references privileged credentials', () {
    for (final (path, text) in sources('lib')) {
      for (final banned in [
        'SUPABASE_SERVICE_ROLE',
        'SERVICE_ROLE_KEY',
        'SUPABASE_SECRET',
        'DATABASE_URL',
        'DB_PASSWORD',
        'postgresql://',
        'postgres://',
      ]) {
        expect(text, isNot(contains(banned)), reason: '$path: $banned');
      }
    }
  });

  test('sign-up only via Supabase Auth; no admin API, no writes', () {
    for (final (path, text) in sources('lib/features/authentication')) {
      for (final banned in [
        'auth.admin',
        'inviteUserByEmail',
        '.insert(',
        '.upsert(',
        '.update(',
        'rpc(',
      ]) {
        expect(text, isNot(contains(banned)), reason: '$path: $banned');
      }
    }
    // Registration exists in exactly one place: the Supabase repository
    // (auth.users). Membership rows come from the database trigger.
    final signUps = sources('lib')
        .where((s) => s.$2.contains('auth.signUp('))
        .map((s) => s.$1.replaceAll(r'\', '/'))
        .toList();
    expect(signUps, [
      'lib/features/authentication/data/repositories/auth_repository_impl.dart',
    ]);
    // app_members is read in exactly one place, through its select.
    final members = sources('lib')
        .where((s) => s.$2.contains("'app_members'"))
        .map((s) => s.$1.replaceAll(r'\', '/'))
        .toList();
    expect(members, [
      'lib/features/authentication/data/models/member_access_model.dart',
    ]);
  });

  test('content sync only reads Supabase and never touches personal data', () {
    final remote = File(
      'lib/features/synchronization/data/content_remote_datasource.dart',
    ).readAsStringSync();
    for (final banned in [
      '.insert(',
      '.upsert(',
      '.update(',
      '.delete(',
      'rpc(',
    ]) {
      expect(remote, isNot(contains(banned)), reason: banned);
    }
    for (final (path, text) in sources('lib/features/synchronization')) {
      for (final banned in [
        'reflections',
        'personalNotes',
        'bookmarks',
        'readingProgress',
        'readingHistory',
        'localSettings',
        'app_members',
        'is_accessible',
      ]) {
        expect(text, isNot(contains(banned)), reason: '$path: $banned');
      }
    }
  });
}
