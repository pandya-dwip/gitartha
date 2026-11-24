import '../entities/app_user.dart';
import '../entities/member_access.dart';

/// Authentication and membership operations for the signed-in user.
///
/// Failures are reported as `AuthFailure` / `MembershipFailure`
/// (`../entities/auth_failure.dart`). There is deliberately no sign-up and
/// no way to change a membership permission.
abstract interface class AuthRepository {
  /// The user of the session restored at startup (or the current one).
  AppUser? get currentUser;

  /// Session changes. Emits at least once (the initial session) when
  /// listened to.
  Stream<AuthChange> get authChanges;

  Future<AppUser> signIn({required String email, required String password});

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
