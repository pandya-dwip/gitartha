import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/local/local_database_providers.dart';

import 'test_database.dart';

void main() {
  test('one database instance per container, closed on dispose', () async {
    var closed = false;
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          final db = openTestDatabase();
          ref.onDispose(() {
            closed = true;
            db.close();
          });
          return db;
        }),
      ],
    );

    final db = container.read(appDatabaseProvider);
    expect(container.read(appDatabaseProvider), same(db));

    final repo = container.read(localDatabaseRepositoryProvider);
    expect(container.read(localDatabaseRepositoryProvider), same(repo));

    await db.chapterDao.upsertChapter(chapterFixture(1));
    expect((await repo.getChapters()).single.id, 1); // same database

    container.dispose();
    expect(closed, isTrue);
  });
}
