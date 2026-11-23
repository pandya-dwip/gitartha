import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/local/daos/settings_dao.dart';
import 'package:gitartha/data/local/daos/sync_metadata_dao.dart';
import 'package:gitartha/data/local/database/app_database.dart';

import 'test_database.dart';

void main() {
  late TestClock clock;
  late AppDatabase db;
  late SettingsDao settings;

  setUp(() {
    clock = TestClock();
    db = openTestDatabase(clock: clock);
    settings = db.settingsDao;
  });
  tearDown(() => db.close());

  group('settings', () {
    test('typed values round-trip', () async {
      await settings.setString(LocalSettingKeys.themeMode, 'dark');
      await settings.setDouble(LocalSettingKeys.sanskritFontScale, 1.25);
      await settings.setBool(LocalSettingKeys.showHindi, false);
      await settings.setInt('reading_goal_per_day', 3);
      await settings.setJson('layout', {'columns': 2, 'dense': true});

      expect(await settings.getString(LocalSettingKeys.themeMode), 'dark');
      expect(
        await settings.getDouble(LocalSettingKeys.sanskritFontScale),
        1.25,
      );
      expect(await settings.getBool(LocalSettingKeys.showHindi), isFalse);
      expect(await settings.getInt('reading_goal_per_day'), 3);
      expect(await settings.getJson('layout'), {'columns': 2, 'dense': true});
      expect(await settings.getString('missing'), isNull);
    });

    test('whole numbers read back as doubles', () async {
      await settings.setDouble(LocalSettingKeys.bodyFontScale, 1.0);
      expect(await settings.getDouble(LocalSettingKeys.bodyFontScale), 1.0);
    });

    test('overwrite, delete and list', () async {
      await settings.setString(LocalSettingKeys.themeMode, 'light');
      clock.advance(const Duration(minutes: 1));
      await settings.setString(LocalSettingKeys.themeMode, 'dark');
      await settings.setBool(LocalSettingKeys.showEnglish, true);

      expect(await settings.getAll(), {
        LocalSettingKeys.themeMode: 'dark',
        LocalSettingKeys.showEnglish: true,
      });
      final row = await db.select(db.localSettings).get();
      expect(
        row.firstWhere((r) => r.key == LocalSettingKeys.themeMode).updatedAt,
        clock(),
      );

      expect(await settings.deleteValue(LocalSettingKeys.themeMode), isTrue);
      expect(await settings.deleteValue(LocalSettingKeys.themeMode), isFalse);
      expect(await settings.getAll(), {LocalSettingKeys.showEnglish: true});
    });

    test('a value of the wrong type is reported, not coerced', () async {
      await settings.setString(LocalSettingKeys.showHindi, 'yes');
      await expectLater(
        settings.getBool(LocalSettingKeys.showHindi),
        throwsFormatException,
      );
    });

    test('keys that look like credentials are refused', () {
      for (final key in [
        'supabase_anon_key',
        'access_token',
        'refresh_token',
        'password',
        'service_role',
        'api_key',
      ]) {
        expect(
          () => settings.setString(key, 'x'),
          throwsArgumentError,
          reason: key,
        );
      }
      expect(() => settings.setString(' ', 'x'), throwsArgumentError);
    });
  });

  group('sync metadata', () {
    test('stores plain key/value bookkeeping', () async {
      final dao = db.syncMetadataDao;
      await dao.setValue(SyncMetadataKeys.contentSyncState, 'idle');
      await dao.setValue(SyncMetadataKeys.contentCursor('shlokas'), 'c1');
      await dao.setValue(SyncMetadataKeys.contentSyncState, 'failed');

      expect(await dao.getValue(SyncMetadataKeys.contentSyncState), 'failed');
      expect(await dao.getValue('content_cursor.shlokas'), 'c1');
      expect(await dao.getAll(), hasLength(2));
      expect(await dao.deleteValue('content_cursor.shlokas'), isTrue);
      expect(await dao.getValue('content_cursor.shlokas'), isNull);
    });
  });
}
