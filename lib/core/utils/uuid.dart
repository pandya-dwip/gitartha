import 'dart:math';

final Random _secureRandom = Random.secure();

/// Generates a random (version 4) UUID, e.g. `9f1c2a7e-3b4d-4c5e-8f60-1a2b3c4d5e6f`.
///
/// Used for records created on the device (reflections, notes, bookmarks,
/// progress and history). Shared scripture keeps the ids that Supabase gave
/// it and never goes through this function.
///
/// Implemented here, on top of a cryptographically secure RNG, so that a
/// whole package is not needed for one function.
String generateUuidV4() {
  final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant

  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

/// Whether [value] is a canonical lower-case UUID string.
bool isCanonicalUuid(String value) => _uuidPattern.hasMatch(value);
