import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/member_access.dart';

/// Converts an `app_members` row from Supabase into [MemberAccess].
///
/// Strict on purpose: a missing or non-boolean `is_accessible`, or a row for
/// a different user, is an invalid response (retryable), never silently read
/// as "editor" or "read-only".
abstract final class MemberAccessModel {
  static const table = 'app_members';
  static const columns = 'user_id,is_accessible,created_at,updated_at';

  static MemberAccess fromRow(
    Map<String, dynamic> row, {
    required String expectedUserId,
  }) {
    final userId = row['user_id'];
    final isAccessible = row['is_accessible'];
    final createdAt = _timestamp(row['created_at']);
    final updatedAt = _timestamp(row['updated_at']);
    if (userId is! String ||
        userId != expectedUserId ||
        isAccessible is! bool ||
        createdAt == null ||
        updatedAt == null) {
      throw const MembershipFailure(MembershipFailureKind.invalidResponse);
    }
    return MemberAccess(
      userId: userId,
      isAccessible: isAccessible,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _timestamp(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}
