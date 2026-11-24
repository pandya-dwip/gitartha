import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/auth_validators.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// The initialized Supabase client, or null when Supabase is not configured
/// (allowed in development) or failed to initialize. Overridden in
/// `main.dart` after `Supabase.initialize`.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);

/// Null when there is no backend; the app then shows sign-in as unavailable.
/// Tests override this with a fake.
final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseAuthRepository(client);
});

/// The current Supabase session, as far as the app is concerned.
@immutable
class AuthSession {
  const AuthSession({this.user, this.isPasswordRecovery = false});

  /// Null when signed out.
  final AppUser? user;

  /// The user opened a password-reset link and must choose a new password
  /// before using the app.
  final bool isPasswordRecovery;

  @override
  bool operator ==(Object other) =>
      other is AuthSession &&
      other.user == user &&
      other.isPasswordRecovery == isPasswordRecovery;

  @override
  int get hashCode => Object.hash(user, isPasswordRecovery);
}

/// Owns the app's single subscription to Supabase auth events and exposes
/// sign-in, sign-out and password recovery.
///
/// Signing out only ends the Supabase session. It never touches the local
/// SQLite database: cached scripture and all personal data stay on the
/// device.
class AuthController extends Notifier<AuthSession> {
  @override
  AuthSession build() {
    final repo = ref.watch(authRepositoryProvider);
    if (repo == null) return const AuthSession();
    final sub = repo.authChanges.listen(_onChange, onError: _onStreamError);
    ref.onDispose(sub.cancel);
    // Supabase.initialize has already restored any persisted session.
    return AuthSession(user: repo.currentUser);
  }

  AuthRepository get _repo =>
      ref.read(authRepositoryProvider) ??
      (throw const AuthFailure(AuthFailureKind.backendUnavailable));

  void _onChange(AuthChange change) {
    final user = change.user;
    if (user == null) {
      state = const AuthSession();
      return;
    }
    final stillRecovering =
        state.isPasswordRecovery && state.user?.id == user.id;
    state = AuthSession(
      user: user,
      isPasswordRecovery: change.isPasswordRecovery || stillRecovering,
    );
  }

  void _onStreamError(Object error, StackTrace _) {
    // Supabase reports e.g. a failed token refresh here. Re-read the
    // session: if it is gone, the user is signed out.
    debugPrint('Auth state stream error (${error.runtimeType}).');
    final user = ref.read(authRepositoryProvider)?.currentUser;
    state = user == null
        ? const AuthSession()
        : AuthSession(user: user, isPasswordRecovery: state.isPasswordRecovery);
  }

  /// Throws [AuthFailure] with a user-safe message.
  Future<void> signIn({required String email, required String password}) async {
    if (AuthValidators.email(email) != null ||
        AuthValidators.password(password) != null) {
      throw const AuthFailure(AuthFailureKind.invalidInput);
    }
    final user = await _repo.signIn(email: email, password: password);
    state = AuthSession(user: user);
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthSession();
  }

  Future<void> requestPasswordReset(String email) async {
    if (AuthValidators.email(email) != null) {
      throw const AuthFailure(AuthFailureKind.invalidInput);
    }
    await _repo.requestPasswordReset(email);
  }

  /// Completes only after Supabase confirms the new password; then leaves
  /// password-recovery mode.
  Future<void> updatePassword(String newPassword) async {
    if (AuthValidators.newPassword(newPassword) != null) {
      throw const AuthFailure(AuthFailureKind.invalidInput);
    }
    await _repo.updatePassword(newPassword);
    state = AuthSession(user: state.user);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthSession>(
  AuthController.new,
);

/// The signed-in user, or null.
final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authControllerProvider.select((s) => s.user)),
);
