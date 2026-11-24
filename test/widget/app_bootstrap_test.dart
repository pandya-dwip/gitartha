import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/app/app.dart';
import 'package:gitartha/core/config/app_config.dart';
import 'package:gitartha/core/config/app_config_provider.dart';

void main() {
  testWidgets('app boots without Supabase and shows sign-in as unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.fromMap(const {})),
        ],
        child: const GitarthaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('गीतार्थ'), findsOneWidget);
    expect(find.textContaining('not connected to its server'), findsOneWidget);
  });
}
