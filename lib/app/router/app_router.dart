import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/providers/member_access_provider.dart';
import '../../features/authentication/presentation/screens/account_access_screen.dart';
import '../../features/authentication/presentation/screens/auth_loading_screen.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/reset_password_screen.dart';
import '../../features/bookmarks/presentation/bookmarks_screen.dart';
import '../../features/chapters/presentation/chapter_library_screen.dart';
import '../../features/chapters/presentation/chapter_overview_screen.dart';
import '../../features/chapters/presentation/verse_index_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/welcome_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/shlokas/presentation/shloka_reader_screen.dart';
import '../shell/app_shell.dart';
import '../widgets/state_views.dart';

/// Route paths.
abstract final class AppRoutes {
  // Bottom navigation destinations.
  static const home = '/';
  static const chapters = '/chapters';
  static const bookmarks = '/bookmarks';
  static const journal = '/journal';

  static String chapter(int id) => '/chapters/$id';
  static String verses(int chapterId) => '/chapters/$chapterId/verses';
  static String verse(int chapterId, int verse) =>
      '/chapters/$chapterId/verses/$verse';

  // Authentication flow.
  static const welcome = '/welcome';
  static const loading = '/loading';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  /// Signed in, but membership is missing or could not be checked.
  static const accountAccess = '/account-access';

  /// Reachable while signed out.
  static const public = {welcome, login, forgotPassword};

  /// Routes that only make sense while not (fully) signed in. Every other
  /// route is protected and requires an active membership.
  static const authFlow = {
    welcome,
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
      AppRoutes.public.contains(path) ? path : AppRoutes.welcome,
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

/// Parses a route parameter as a positive int (bad values → null; the
/// screen then shows "not found" instead of crashing).
int? _intParam(GoRouterState state, String name) {
  final v = int.tryParse(state.pathParameters[name] ?? '');
  return v != null && v > 0 ? v : null;
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
    errorBuilder: (context, state) => const Scaffold(
      body: EmptyState(
        icon: Icons.explore_off_outlined,
        title: 'Page not found',
        message:
            'This page does not exist. Use the navigation below or go back.',
      ),
    ),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chapters,
                builder: (context, state) => const ChapterLibraryScreen(),
                routes: [
                  GoRoute(
                    path: ':chapterId',
                    builder: (context, state) => ChapterOverviewScreen(
                      chapterId: _intParam(state, 'chapterId'),
                    ),
                    routes: [
                      GoRoute(
                        path: 'verses',
                        builder: (context, state) => VerseIndexScreen(
                          chapterId: _intParam(state, 'chapterId'),
                        ),
                        routes: [
                          GoRoute(
                            path: ':verse',
                            builder: (context, state) => ShlokaReaderScreen(
                              chapterId: _intParam(state, 'chapterId'),
                              verseNumber: _intParam(state, 'verse'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.bookmarks,
                builder: (context, state) => const BookmarksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.journal,
                builder: (context, state) => const JournalScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
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
