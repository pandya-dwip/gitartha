import 'remote_content_store.dart';

/// Why a signed-in user may not publish.
enum PublisherDenial {
  /// No `app_members` row: not an authorized member at all.
  noMembership,

  /// `is_accessible = false`: a read-only member.
  notAccessible,
}

class PublisherAccessDenied implements Exception {
  const PublisherAccessDenied(this.denial);

  final PublisherDenial denial;

  /// The message shown to the publisher (identical for both reasons, so it
  /// does not reveal more than necessary).
  static const String message =
      'Publishing permission denied.\n\n'
      'Your account does not have permission to modify shared scripture '
      'content.\n\n'
      'Contact the project owner if you require publishing access.';

  @override
  String toString() => 'PublisherAccessDenied(${denial.name})';
}

/// A signed-in user whose own membership allows editing shared content.
class PublisherAccess {
  const PublisherAccess(this.userId);

  final String userId;
}

/// Signs in and checks the individual `app_members.is_accessible`
/// permission.
///
/// This check gives a clear early answer. It is **not** the security
/// boundary: every write still goes out with the user's own session, and
/// Supabase RLS (`can_edit_shared_content()`) has the final say. Nothing
/// here can change a permission.
class PublisherAccessService {
  const PublisherAccessService();

  /// Throws [PublisherAuthException] if sign-in fails, and
  /// [PublisherAccessDenied] if the user may not publish.
  Future<PublisherAccess> authorize(
    RemoteContentStore store, {
    required String email,
    required String password,
  }) async {
    final userId = await store.signIn(email: email, password: password);
    final membership = await store.fetchOwnMembership();
    if (membership == null || membership.userId != userId) {
      throw const PublisherAccessDenied(PublisherDenial.noMembership);
    }
    if (!membership.isAccessible) {
      throw const PublisherAccessDenied(PublisherDenial.notAccessible);
    }
    return PublisherAccess(userId);
  }
}
