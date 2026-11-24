import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/providers/member_access_provider.dart';
import '../../features/authentication/presentation/screens/account_access_screen.dart';
import '../../features/authentication/presentation/screens/auth_loading_screen.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/reset_password_screen.dart';
import '../bootstrap_screen.dart';

/// Route paths. Feature routes are added here as features are implemented.
abstract final class AppRoutes {
  /// The authenticated application entry point.
  static const home = '/';
  static const loading = '/loading';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  /// Signed in, but membership is missing or could not be checked.
  static const accountAccess = '/account-access';

  /// Routes that only make sense while not (fully) signed in. Every other
  /// route is protected and requires an active membership.
  static const authFlow = {
    loading,
    login,
    forgotPassword,
    resetPassword,
    accountAccess,
  };
}

/// Where [status] allows the user to be, given they asked for [path].
/// Returns null to stay, or the path to redirect to. Pure, so it is tested
/// directly and cannot loop: every status maps to one fixed destination
/// (or, for members and signed-out users, a set they may move within).
String? authRedirect(AuthStatus status, String path) {
  final target = switch (status) {
    AuthStatus.backendUnavailable || AuthStatus.signedOut =>
      path == AppRoutes.login || path == AppRoutes.forgotPassword
          ? path
          : AppRoutes.login,
    AuthStatus.passwordRecovery => AppRoutes.resetPassword,
    AuthStatus.loadingMembership => AppRoutes.loading,
    AuthStatus.membershipMissing ||
    AuthStatus.membershipError => AppRoutes.accountAccess,
    // Read-only members and editors use the same application.
    AuthStatus.readOnly || AuthStatus.editor =>
      AppRoutes.authFlow.contains(path) ? AppRoutes.home : path,
  };
  return target == path ? null : target;
}

/// The application's [GoRouter]. Every navigation — including deep links —
/// passes through [authRedirect], and the router re-evaluates whenever
/// [authStatusProvider] changes (sign-in, sign-out, membership loaded).
final appRouterProvider = Provider<GoRouter>((ref) {
  final status = ValueNotifier(ref.read(authStatusProvider));
  ref.listen(authStatusProvider, (_, next) => status.value = next);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: status,
    redirect: (context, state) => authRedirect(status.value, state.uri.path),
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const BootstrapScreen(),
      ),
      GoRoute(
        path: AppRoutes.loading,
        builder: (context, state) => const AuthLoadingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountAccess,
        builder: (context, state) => const AccountAccessScreen(),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    status.dispose();
  });
  return router;
});
