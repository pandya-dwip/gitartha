import 'dart:convert';

/// Pure-Dart checks on Supabase connection settings, shared by the app
/// (`AppConfig`) and the developer tools (`tool/publish_gita_content.dart`).

/// Whether [key] is a **privileged** Supabase key that must never be used
/// by the app or the publishing tool: a new `sb_secret_...` key, or a legacy
/// JWT whose `role` claim is `service_role`.
bool looksLikeSupabaseSecretKey(String key) {
  if (key.startsWith('sb_secret_')) return true;

  final parts = key.split('.');
  if (parts.length != 3) return false;
  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final claims = jsonDecode(payload);
    return claims is Map && claims['role'] == 'service_role';
  } on FormatException {
    return false;
  }
}

/// Hosts that may be reached over plain http (a local Supabase instance).
bool isLocalSupabaseHost(String host) =>
    host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';

/// Why [url] is not a usable Supabase project URL, or null if it is fine.
String? supabaseUrlProblem(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return 'is not a valid URL: "$url". '
        'Expected something like https://<project-ref>.supabase.co';
  }
  if (uri.scheme != 'https' && !isLocalSupabaseHost(uri.host)) {
    return 'must use https (http is only allowed for a local Supabase '
        'instance).';
  }
  return null;
}
