/// Why an authentication operation failed. [message] is safe to show to the
/// user: it never contains server responses, tokens or keys.
enum AuthFailureKind {
  backendUnavailable(
    'Sign-in is not available: the app is not connected to its server.',
  ),
  invalidInput('Enter a valid email address and password.'),
  // Supabase deliberately answers "invalid credentials" for unknown users
  // too, so the app cannot (and should not) tell them apart.
  invalidCredentials('Invalid email or password.'),
  emailNotConfirmed(
    'This account has not confirmed its email address yet. Open the '
    'invitation email first.',
  ),
  accountDisabled(
    'This account is disabled. Contact the project owner if you think this '
    'is a mistake.',
  ),
  rateLimited('Too many attempts. Wait a few minutes and try again.'),
  network('Could not reach the server. Check your connection and try again.'),
  serviceUnavailable(
    'The sign-in service is unavailable right now. Try again later.',
  ),
  sessionExpired('Your session has expired. Please sign in again.'),
  weakPassword(
    'That password is too weak. Use a longer password with a mix of '
    'characters.',
  ),
  samePassword('Choose a password different from your current one.'),
  emailAlreadyRegistered(
    'An account with this email already exists. Sign in instead, or use '
    '"Forgot password?".',
  ),
  signupDisabled(
    'New registrations are not open right now. Please contact the project '
    'owner.',
  ),
  unknown('Something went wrong. Please try again.');

  const AuthFailureKind(this.message);

  final String message;
}

class AuthFailure implements Exception {
  const AuthFailure(this.kind);

  final AuthFailureKind kind;

  String get message => kind.message;

  @override
  String toString() => 'AuthFailure(${kind.name})';
}

/// Why the user's membership could not be read. Distinct from "no
/// membership": a [MembershipFailure] means the answer is unknown, and the
/// user may retry.
enum MembershipFailureKind {
  /// Network error, timeout or server error.
  unavailable,

  /// The request was rejected (e.g. RLS / expired session).
  accessDenied,

  /// The row came back malformed (e.g. `is_accessible` missing).
  invalidResponse,
}

class MembershipFailure implements Exception {
  const MembershipFailure(this.kind);

  final MembershipFailureKind kind;

  static const String message =
      'Your account access could not be checked right now. '
      'Check your connection and try again.';

  @override
  String toString() => 'MembershipFailure(${kind.name})';
}
