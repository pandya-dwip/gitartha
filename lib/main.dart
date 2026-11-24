import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/startup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  // Draw immediately; GitarthaStartup prepares Supabase and the database
  // behind a startup screen (never a blank one).
  runApp(const GitarthaStartup());
}

/// The bundled fonts are under the SIL Open Font License, which must
/// accompany them; they appear in Flutter's licence page.
void _registerFontLicenses() {
  const fonts = {
    'Noto Serif': 'assets/fonts/english/OFL-NotoSerif.txt',
    'Noto Serif Devanagari':
        'assets/fonts/devanagari/OFL-NotoSerifDevanagari.txt',
    'Plus Jakarta Sans': 'assets/fonts/english/OFL-PlusJakartaSans.txt',
  };
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: path) in fonts.entries) {
      yield LicenseEntryWithLineBreaks([
        name,
      ], await rootBundle.loadString(path));
    }
  });
}
