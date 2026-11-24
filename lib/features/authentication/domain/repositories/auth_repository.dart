import '../entities/app_user.dart';
import '../entities/member_access.dart';

/// Authentication and membership operations for the signed-in user.
///
/// Failures are reported as `AuthFailure` / `MembershipFailure`
/// (`../entities/auth_failure.dart`). There is deliberately no way to change
/// a membership permission: a new account's read-only membership is created
/// by a database trigger, never by the app.
abstract interface class AuthRepository {
  /// The user of the session restored at startup (or the current one).
  AppUser? get currentUser;

  /// Session changes. Emits at least once (the initial session) when
  /// listened to.
  Stream<AuthChange> get authChanges;

  Future<AppUser> signIn({required String email, required String password});

  /// Creates a Supabase Auth account. Returns [SignUpOutcome.signedIn] when
  /// the project does not require email confirmation (a session exists),
  /// otherwise [SignUpOutcome.confirmEmail].
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  /// Ends the session on this device. Always clears the local session, even
  /// when the server cannot be reached. Never touches local app data.
  Future<void> signOut();

  /// The signed-in user's own `app_members` row, or null if they have none.
  /// The user id comes from the session, never from the caller.
  Future<MemberAccess?> fetchOwnMembership();

  /// Sends a password-reset email that links back into the app.
  Future<void> requestPasswordReset(String email);

  /// Sets a new password for the signed-in (or recovering) user. Completes
  /// only after Supabase confirms the change.
  Future<void> updatePassword(String newPassword);
}

/// What happened after a successful registration request.
enum SignUpOutcome {
  /// Signed in straight away.
  signedIn,

  /// A confirmation email was sent; the account works after the link is
  /// opened. (Supabase answers the same way when the address is already
  /// registered, so the app never reveals which addresses have accounts.)
  confirmEmail,
}
