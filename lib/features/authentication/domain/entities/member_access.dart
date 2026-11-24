/// The signed-in user's own `public.app_members` row.
///
/// Having a row makes the user a Gitartha member (they may read shared
/// scripture). [isAccessible] is their individual permission to modify it.
///
/// This is held in memory for the current session only and is never
/// persisted. It drives the UI; Supabase RLS enforces the same rule on
/// every write, so a stale value can never authorize anything.
class MemberAccess {
  const MemberAccess({
    required this.userId,
    required this.isAccessible,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final bool isAccessible;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether the UI should offer editing of shared scripture.
  bool get canEditSharedContent => isAccessible;

  @override
  bool operator ==(Object other) =>
      other is MemberAccess &&
      other.userId == userId &&
      other.isAccessible == isAccessible &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(userId, isAccessible, createdAt, updatedAt);

  @override
  String toString() => 'MemberAccess($userId, isAccessible: $isAccessible)';
}
