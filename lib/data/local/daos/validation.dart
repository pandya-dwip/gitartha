/// Throws [ArgumentError] if [value] is empty or only whitespace.
///
/// Mirrors the CHECK constraints on personal text columns, but fails before
/// SQL runs and with a clearer message. The value is stored as given; it is
/// not trimmed, because whitespace inside personal writing can be meaningful.
String requireText(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must not be empty');
  }
  return value;
}

/// Returns null for null or blank [value], otherwise [value] unchanged.
String? blankToNull(String? value) =>
    value == null || value.trim().isEmpty ? null : value;

/// [now], but never earlier than [notBefore]. Protects `updated_at >=
/// created_at` (and similar CHECKs) if the device clock moves backwards.
DateTime notEarlierThan(DateTime now, DateTime notBefore) =>
    now.isBefore(notBefore) ? notBefore : now;
