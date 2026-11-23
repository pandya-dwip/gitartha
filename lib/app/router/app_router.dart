import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../bootstrap_screen.dart';

/// Route paths. Feature routes are added here as features are implemented.
abstract final class AppRoutes {
  static const bootstrap = '/';
}

/// The application's [GoRouter], exposed through Riverpod so routes can later
/// depend on app state (e.g. redirects).
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.bootstrap,
    routes: [
      GoRoute(
        path: AppRoutes.bootstrap,
        builder: (context, state) => const BootstrapScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
