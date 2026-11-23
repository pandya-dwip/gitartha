import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/main.dart' as app;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches on a device', (tester) async {
    await app.main();
    await tester.pumpAndSettle();

    expect(find.text('गीतार्थ'), findsOneWidget);
  });
}
