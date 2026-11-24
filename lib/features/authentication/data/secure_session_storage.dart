import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the Supabase session in platform secure storage (iOS Keychain,
/// Android Keystore-encrypted storage) instead of plain SharedPreferences,
/// which Android auto-backup would copy off the device.
///
/// Only the Supabase session lives here. Local app data (scripture cache,
/// reflections, notes, bookmarks, progress, settings) is in SQLite and is
/// never touched by sign-in or sign-out.
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _key = 'gitartha.supabase.session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _key);

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);
}
