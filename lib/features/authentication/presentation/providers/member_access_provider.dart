import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/member_access.dart';
import 'auth_state_provider.dart';

/// The signed-in user's own membership, fetched from Supabase once per
/// signed-in user (sign-in or restored session) and held in memory only.
///
/// * `AsyncData(null)`: confirmed — the user has no `app_members` row.
/// * `AsyncError(MembershipFailure)`: unknown (network, malformed row…);
///   retry with `ref.invalidate(memberAccessProvider)`.
///
/// No automatic retry: the user sees the error and decides.
final memberAccessProvider = FutureProvider<MemberAccess?>((ref) async {
  final userId = ref.watch(currentUserProvider.select((u) => u?.id));
  final repo = ref.watch(authRepositoryProvider);
  if (userId == null || repo == null) return null;
  return repo.fetchOwnMembership();
}, retry: (_, _) => null);

/// Where the user stands, combining session and membership. The router and
/// screens read this; nothing else re-derives access rules.
enum AuthStatus {
  /// Supabase is not configured or failed to initialize.
  backendUnavailable,
  signedOut,

  /// Must choose a new password (opened a reset link).
  passwordRecovery,
  loadingMembership,

  /// Member with `is_accessible = false`: may read.
  readOnly,

  /// Member with `is_accessible = true`: may read and edit (RLS-enforced).
  editor,

  /// Signed in, but no `app_members` row: not authorized for Gitartha.
  membershipMissing,

  /// Membership could not be checked; retryable.
  membershipError;

  bool get isMember => this == readOnly || this == editor;
}

final authStatusProvider = Provider<AuthStatus>((ref) {
  if (ref.watch(authRepositoryProvider) == null) {
    return AuthStatus.backendUnavailable;
  }
  final session = ref.watch(authControllerProvider);
  if (session.user == null) return AuthStatus.signedOut;
  if (session.isPasswordRecovery) return AuthStatus.passwordRecovery;

  final access = ref.watch(memberAccessProvider);
  // isLoading first: a retry keeps the previous value/error while it runs,
  // and a stale value must never count as current.
  if (access.isLoading) return AuthStatus.loadingMembership;
  if (access.hasError) return AuthStatus.membershipError;
  final member = access.value;
  if (member == null) return AuthStatus.membershipMissing;
  return member.canEditSharedContent ? AuthStatus.editor : AuthStatus.readOnly;
});

/// Whether the UI may offer editing of shared scripture. True only for a
/// confirmed, current editor membership; RLS still checks every write.
final canEditSharedContentProvider = Provider<bool>(
  (ref) => ref.watch(authStatusProvider) == AuthStatus.editor,
);
