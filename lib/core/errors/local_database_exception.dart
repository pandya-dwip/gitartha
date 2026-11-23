/// Thrown when the on-device database cannot be opened, migrated or used
/// as expected.
///
/// The [message] is written for developers. [cause] keeps the original error
/// so that it is never silently lost.
class LocalDatabaseException implements Exception {
  const LocalDatabaseException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => cause == null
      ? 'LocalDatabaseException: $message'
      : 'LocalDatabaseException: $message (cause: $cause)';
}
