/// The signed-in Supabase Auth user, as the app sees it.
///
/// Holds identity only. What the user may do comes from [MemberAccess].
class AppUser {
  const AppUser({required this.id, this.email});

  /// `auth.users.id`.
  final String id;
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is AppUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);

  @override
  String toString() => 'AppUser($id)';
}

/// One change reported by Supabase Auth: initial session, sign-in, token
/// refresh, user update, password recovery or sign-out.
class AuthChange {
  const AuthChange({required this.user, this.isPasswordRecovery = false});

  /// The user of the current session, or null when there is no session.
  final AppUser? user;

  /// True when the user arrived through a password-recovery link and must
  /// choose a new password.
  final bool isPasswordRecovery;
}
