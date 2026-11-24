import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/member_access.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/member_access_model.dart';

/// [AuthRepository] over Supabase Auth and the `app_members` table.
///
/// * Uses the app's publishable key and the user's own session only, so
///   every query is subject to RLS. Registration creates the Auth account
///   only; its read-only `app_members` row comes from a database trigger.
///   The app never writes to `app_members`.
/// * Passwords and tokens are never logged; errors are mapped to
///   [AuthFailure] / [MembershipFailure] with user-safe messages.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  /// Where password-reset (and invitation) links return to. Must match the
  /// deep-link scheme in AndroidManifest.xml / Info.plist and be listed in
  /// Supabase Dashboard → Authentication → URL Configuration → Redirect URLs.
  static const authRedirectUrl = 'com.gitartha.gitartha://auth-callback';

  static const _timeout = Duration(seconds: 20);

  @override
  AppUser? get currentUser => _toAppUser(_client.auth.currentUser);

  @override
  Stream<AuthChange> get authChanges => _client.auth.onAuthStateChange.map(
    (state) => AuthChange(
      user: _toAppUser(state.session?.user),
      isPasswordRecovery: state.event == AuthChangeEvent.passwordRecovery,
    ),
  );

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _auth(
      () => _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      ),
    );
    final user = _toAppUser(response.user);
    if (user == null || response.session == null) {
      throw const AuthFailure(AuthFailureKind.unknown);
    }
    return user;
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _auth(
      () => _client.auth.signUp(
        email: email.trim(),
        password: password,
        // Display name only. The membership trigger never reads metadata,
        // so nothing here can influence permissions.
        data: {'full_name': fullName.trim()},
        emailRedirectTo: authRedirectUrl,
      ),
    );
    return response.session != null
        ? SignUpOutcome.signedIn
        : SignUpOutcome.confirmEmail;
  }

  @override
  Future<void> signOut() async {
    try {
      // gotrue clears the local session (and emits signedOut) before it
      // calls the server, so this works offline too.
      await _client.auth.signOut().timeout(_timeout);
    } on Object catch (e) {
      if (_client.auth.currentSession != null) rethrow;
      debugPrint(
        'Sign-out: server-side session revoke failed (${e.runtimeType}); '
        'the local session was cleared.',
      );
    }
  }

  @override
  Future<MemberAccess?> fetchOwnMembership() async {
    // The id comes from the authenticated session, never from the caller.
    // RLS (app_members_select_own) returns only this row anyway.
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const MembershipFailure(MembershipFailureKind.accessDenied);
    }
    final Map<String, dynamic>? row;
    try {
      row = await _client
          .from(MemberAccessModel.table)
          .select(MemberAccessModel.columns)
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(_timeout);
    } on PostgrestException catch (e) {
      throw MembershipFailure(membershipFailureKindFor(e));
    } on Object catch (e) {
      debugPrint('Membership lookup failed (${e.runtimeType}).');
      throw const MembershipFailure(MembershipFailureKind.unavailable);
    }
    if (row == null) return null;
    return MemberAccessModel.fromRow(row, expectedUserId: userId);
  }

  @override
  Future<void> requestPasswordReset(String email) => _auth(
    () => _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: authRedirectUrl,
    ),
  );

  @override
  Future<void> updatePassword(String newPassword) async {
    final response = await _auth(
      () => _client.auth.updateUser(UserAttributes(password: newPassword)),
    );
    if (response.user == null) {
      throw const AuthFailure(AuthFailureKind.unknown);
    }
  }

  Future<T> _auth<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on AuthException catch (e) {
      throw AuthFailure(authFailureKindFor(e));
    } on TimeoutException {
      throw const AuthFailure(AuthFailureKind.network);
    } on Object catch (e) {
      debugPrint('Auth request failed (${e.runtimeType}).');
      throw const AuthFailure(AuthFailureKind.unknown);
    }
  }

  static AppUser? _toAppUser(User? user) =>
      user == null ? null : AppUser(id: user.id, email: user.email);
}

/// Maps a Supabase Auth error to a user-safe [AuthFailureKind].
@visibleForTesting
AuthFailureKind authFailureKindFor(AuthException e) {
  if (e is AuthRetryableFetchException) {
    final status = int.tryParse(e.statusCode ?? '');
    return status != null && status >= 500
        ? AuthFailureKind.serviceUnavailable
        : AuthFailureKind.network;
  }
  if (e is AuthWeakPasswordException) return AuthFailureKind.weakPassword;
  if (e is AuthSessionMissingException) return AuthFailureKind.sessionExpired;

  switch (e.code) {
    case 'invalid_credentials' || 'user_not_found':
      return AuthFailureKind.invalidCredentials;
    case 'email_not_confirmed':
      return AuthFailureKind.emailNotConfirmed;
    case 'user_banned':
      return AuthFailureKind.accountDisabled;
    case 'over_request_rate_limit' || 'over_email_send_rate_limit':
      return AuthFailureKind.rateLimited;
    case 'session_expired' ||
        'session_not_found' ||
        'refresh_token_not_found' ||
        'refresh_token_already_used' ||
        'bad_jwt':
      return AuthFailureKind.sessionExpired;
    case 'weak_password':
      return AuthFailureKind.weakPassword;
    case 'same_password':
      return AuthFailureKind.samePassword;
    case 'validation_failed' || 'email_address_invalid':
      return AuthFailureKind.invalidInput;
    case 'user_already_exists' || 'email_exists':
      return AuthFailureKind.emailAlreadyRegistered;
    case 'signup_disabled' || 'email_provider_disabled':
      return AuthFailureKind.signupDisabled;
  }

  final status = int.tryParse(e.statusCode ?? '');
  if (status == 429) return AuthFailureKind.rateLimited;
  if (status != null && status >= 500) {
    return AuthFailureKind.serviceUnavailable;
  }
  // Older Auth servers answer bad credentials with a bare 400.
  if (status == 400 && e.code == null) {
    return AuthFailureKind.invalidCredentials;
  }
  return AuthFailureKind.unknown;
}

/// Maps a PostgREST error on the membership query.
@visibleForTesting
MembershipFailureKind membershipFailureKindFor(PostgrestException e) {
  const denied = {'42501', 'PGRST301', 'PGRST302', '401', '403'};
  return denied.contains(e.code)
      ? MembershipFailureKind.accessDenied
      : MembershipFailureKind.unavailable;
}
