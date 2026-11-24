/// Basic client-side input checks, shared by the forms and the controller.
/// Supabase Auth remains the authority; these only catch obvious mistakes
/// before a network round trip.
abstract final class AuthValidators {
  /// Minimum length the app asks for when choosing a new password. The
  /// Supabase project may enforce a stricter policy; its answer is mapped to
  /// `AuthFailureKind.weakPassword`.
  static const minNewPasswordLength = 8;

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email address.';
    if (!_email.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) =>
      (value == null || value.isEmpty) ? 'Enter your password.' : null;

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a new password.';
    if (value.length < minNewPasswordLength) {
      return 'Use at least $minNewPasswordLength characters.';
    }
    return null;
  }
}
