import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/utils/uuid.dart';

/// Deterministic UUIDs for shared content.
///
/// The content repository identifies verses and sources with human-readable
/// keys (`chapter_01_verse_041`, `gita_press_hindi`), while the database
/// uses UUID primary keys (Supabase `shlokas.id`, `content_sources.id`, and
/// the local cache that mirrors them). A text key is never written into a
/// UUID column. Instead, every key maps to a **name-based (version 5) UUID**
/// (RFC 4122 §4.3) under a fixed Gitartha namespace:
///
///  * the same key always gives the same UUID, on every device and in every
///    import, so re-importing never creates duplicates and the ids that
///    personal reflections point to never change;
///  * the future Supabase import must use these same functions, so the
///    server rows get the same UUIDs as the local cache and no mapping table
///    is needed.
///
/// **Never change [namespace] or the name prefixes.** That would change
/// every content id.
abstract final class ContentIds {
  /// The Gitartha content namespace. Generated once, fixed forever.
  static const String namespace = '3b798233-c921-47f3-b5eb-a1bdb069565b';

  /// UUID of the verse with content id [shlokaContentId]. An id that is
  /// already a canonical UUID is kept as it is.
  static String shloka(String shlokaContentId) =>
      isCanonicalUuid(shlokaContentId)
      ? shlokaContentId
      : uuidV5(namespace, 'shloka/$shlokaContentId');

  /// UUID of the source with key [sourceKey]. A key that is already a
  /// canonical UUID is kept as it is.
  static String source(String sourceKey) => isCanonicalUuid(sourceKey)
      ? sourceKey
      : uuidV5(namespace, 'source/$sourceKey');

  /// UUID of one attribution mapping (verse, source, section).
  static String attribution(
    String shlokaContentId,
    String sourceKey,
    String contentSection,
  ) => uuidV5(
    namespace,
    'attribution/$shlokaContentId/$sourceKey/$contentSection',
  );
}

/// RFC 4122 version 5 (SHA-1, name-based) UUID of [name] in [namespace].
String uuidV5(String namespace, String name) {
  final namespaceBytes = _parseUuid(namespace);
  final digest = sha1.convert([...namespaceBytes, ...utf8.encode(name)]).bytes;
  final bytes = digest.sublist(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x50; // version 5
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

List<int> _parseUuid(String uuid) {
  final hex = uuid.replaceAll('-', '');
  if (hex.length != 32) {
    throw FormatException('Not a UUID: $uuid');
  }
  return [
    for (var i = 0; i < 32; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ];
}
