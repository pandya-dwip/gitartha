import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/app/router/app_router.dart';
import 'package:gitartha/features/authentication/presentation/providers/member_access_provider.dart';

void main() {
  const protected = [AppRoutes.home, '/chapters/2', '/settings'];
  const allPaths = [...protected, ...AppRoutes.authFlow];

  test(
    'unauthenticated users are sent to login from every protected route',
    () {
      for (final status in [
        AuthStatus.signedOut,
        AuthStatus.backendUnavailable,
      ]) {
        for (final path in protected) {
          expect(
            authRedirect(status, path),
            AppRoutes.login,
            reason: '$status $path',
          );
        }
        expect(authRedirect(status, AppRoutes.login), isNull);
        expect(authRedirect(status, AppRoutes.forgotPassword), isNull);
        expect(authRedirect(status, AppRoutes.accountAccess), AppRoutes.login);
        expect(authRedirect(status, AppRoutes.loading), AppRoutes.login);
      }
    },
  );

  test('read-only members and editors reach the same application', () {
    for (final status in [AuthStatus.readOnly, AuthStatus.editor]) {
      for (final path in protected) {
        expect(authRedirect(status, path), isNull, reason: '$status $path');
      }
      for (final path in AppRoutes.authFlow) {
        expect(
          authRedirect(status, path),
          AppRoutes.home,
          reason: '$status $path',
        );
      }
    }
  });

  test('missing membership and lookup errors are blocked from the app', () {
    for (final status in [
      AuthStatus.membershipMissing,
      AuthStatus.membershipError,
    ]) {
      for (final path in protected) {
        expect(authRedirect(status, path), AppRoutes.accountAccess);
      }
    }
  });

  test('membership loading holds on the loading route', () {
    for (final path in allPaths) {
      final target = authRedirect(AuthStatus.loadingMembership, path);
      expect(target, path == AppRoutes.loading ? isNull : AppRoutes.loading);
    }
  });

  test('password recovery forces the reset screen', () {
    for (final path in allPaths) {
      final target = authRedirect(AuthStatus.passwordRecovery, path);
      expect(
        target,
        path == AppRoutes.resetPassword ? isNull : AppRoutes.resetPassword,
      );
    }
  });

  test('no redirect loops: one redirect always lands on a stable route', () {
    for (final status in AuthStatus.values) {
      for (final path in allPaths) {
        final target = authRedirect(status, path) ?? path;
        expect(
          authRedirect(status, target),
          isNull,
          reason: '$status $path → $target',
        );
      }
    }
  });
}
