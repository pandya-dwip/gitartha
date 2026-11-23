import 'package:flutter_test/flutter_test.dart';

/// Matches a future/function that fails with an SQLite error whose message
/// contains [fragment], e.g. `FOREIGN KEY constraint failed`.
Matcher throwsSqlite(String fragment) => throwsA(
  predicate<Object>(
    (e) => e.toString().contains(fragment),
    'an SQLite error containing "$fragment"',
  ),
);

final Matcher throwsForeignKeyError = throwsSqlite(
  'FOREIGN KEY constraint failed',
);
final Matcher throwsUniqueError = throwsSqlite('UNIQUE constraint failed');
final Matcher throwsCheckError = throwsSqlite('CHECK constraint failed');
