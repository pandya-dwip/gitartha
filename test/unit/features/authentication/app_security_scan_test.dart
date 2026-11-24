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

  test('no public sign-up, no admin API, no membership writes', () {
    for (final (path, text) in sources('lib/features/authentication')) {
      for (final banned in [
        'signUp(',
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
    // app_members is read in exactly one place, through its select.
    final members = sources('lib')
        .where((s) => s.$2.contains("'app_members'"))
        .map((s) => s.$1.replaceAll(r'\', '/'))
        .toList();
    expect(members, [
      'lib/features/authentication/data/models/member_access_model.dart',
    ]);
  });
}
