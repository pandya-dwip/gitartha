import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/app/app.dart';
import 'package:gitartha/core/config/app_config.dart';
import 'package:gitartha/core/config/app_config_provider.dart';
import 'package:gitartha/data/local/local_database_providers.dart';

import '../unit/data/local/test_database.dart';

void main() {
  testWidgets('app boots without Supabase and shows sign-in as unavailable', (
    tester,
  ) async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.fromMap(const {})),
        appDatabaseProvider.overrideWithValue(db),
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

    expect(find.text('गीतार्थ'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.textContaining('not connected to its server'), findsOneWidget);
  });
}
