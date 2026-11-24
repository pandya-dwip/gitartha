import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/providers/member_access_provider.dart';
import '../../features/authentication/presentation/screens/account_access_screen.dart';
import '../../features/authentication/presentation/screens/auth_loading_screen.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/reset_password_screen.dart';
import '../../features/bookmarks/presentation/bookmarks_screen.dart';
import '../../features/chapters/presentation/chapter_library_screen.dart';
import '../../features/chapters/presentation/chapter_overview_screen.dart';
import '../../features/chapters/presentation/verse_index_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/shlokas/presentation/shloka_reader_screen.dart';
import '../shell/app_shell.dart';
import '../widgets/state_views.dart';
import '../motion/motion.dart';

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
  static const loading = '/loading';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  /// Signed in, but membership is missing or could not be checked.
  static const accountAccess = '/account-access';

  /// Reachable while signed out.
  static const public = {login, register, forgotPassword};

  /// Routes that only make sense while not (fully) signed in. Every other
  /// route is protected and requires an active membership.
  static const authFlow = {
    loading,
    login,
    register,
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
      AppRoutes.public.contains(path) ? path : AppRoutes.login,
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

/// Authentication screens cross-fade with a slight rise, instead of the
/// platform slide, so moving between sign-in and registration feels calm.
Page<void> _authPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );

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
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(shell: shell),
        // Like indexedStack (tabs keep their state), with a fade between tabs.
        navigatorContainerBuilder: (context, shell, children) =>
            FadingBranchContainer(
              currentIndex: shell.currentIndex,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) =>
                    const EntranceScope(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chapters,
                builder: (context, state) =>
                    const EntranceScope(child: ChapterLibraryScreen()),
                routes: [
                  GoRoute(
                    path: ':chapterId',
                    builder: (context, state) => EntranceScope(
                      child: ChapterOverviewScreen(
                        chapterId: _intParam(state, 'chapterId'),
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'verses',
                        builder: (context, state) => EntranceScope(
                          child: VerseIndexScreen(
                            chapterId: _intParam(state, 'chapterId'),
                          ),
                        ),
                        routes: [
                          GoRoute(
                            path: ':verse',
                            builder: (context, state) => EntranceScope(
                              child: ShlokaReaderScreen(
                                chapterId: _intParam(state, 'chapterId'),
                                verseNumber: _intParam(state, 'verse'),
                              ),
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
                builder: (context, state) =>
                    const EntranceScope(child: BookmarksScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.journal,
                builder: (context, state) =>
                    const EntranceScope(child: JournalScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.loading,
        pageBuilder: (context, state) =>
            _authPage(state, const AuthLoadingScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _authPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) =>
            _authPage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) =>
            _authPage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        pageBuilder: (context, state) =>
            _authPage(state, const ResetPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.accountAccess,
        pageBuilder: (context, state) =>
            _authPage(state, const AccountAccessScreen()),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    status.dispose();
  });
  return router;
});
