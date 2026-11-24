# Running Gitartha on an Android phone

## One-time setup (this PC)

The Flutter 3.44.8 SDK, Android SDK 36.1 and platform-tools (`adb`) are installed.
Remaining tasks:

```powershell
flutter doctor --android-licenses   # accept the SDK licences (answer y)
```

`.env` must exist in the project root, because it is bundled at build time. Copy
`.env.example` and fill in `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` (the
**publishable** key only). Without them the app still runs, but sign-in shows as
unavailable.

## Prepare the phone

1. **Settings → About phone** → tap **Build number** 7 times. On some phones it is
   under **Software information**. "You are now a developer" appears.
2. **Settings → System → Developer options** → turn on **USB debugging**.
3. Connect the phone with a USB **data** cable. Charge-only cables don't work. If the
   phone asks, choose **File transfer / Android Auto**.
4. Accept **"Allow USB debugging?"** on the phone. Tick *Always allow from this computer*.

## Detect the device (PowerShell)

```powershell
adb devices
flutter devices
```

- `adb devices` should list a serial with the state `device`. `unauthorized` means you
  haven't accepted the prompt on the phone yet. `offline` means you should reconnect the
  cable.
- `flutter devices` shows the device ID in the second column, e.g.
  `Pixel 7 (mobile) • 2B241FDH30011M • android-arm64 • Android 15`. That ID is
  `DEVICE_ID`.
- If `adb` is not recognised, add platform-tools to PATH for this session:
  `$env:Path += ";$env:LOCALAPPDATA\Android\Sdk\platform-tools"`. To make it permanent:
  System Properties → Environment Variables → Path → add
  `%LOCALAPPDATA%\Android\Sdk\platform-tools`.

## Run

```powershell
cd D:\gitartha
flutter pub get
flutter run -d DEVICE_ID      # or just `flutter run` if the phone is the only device
```

`flutter run` picks the only connected device itself. On this PC, Windows, Chrome and
Edge also count as devices, so pass `-d DEVICE_ID` (or `-d android`, if only one phone is
connected).

There are no `--dart-define` arguments: configuration comes from the bundled `.env`.

While it runs: `r` hot reload, `R` hot restart, `q` quit.

## Useful

```powershell
dart run build_runner build --delete-conflicting-outputs   # after changing Drift tables/DAOs or json models
flutter build apk --debug                                   # build\app\outputs\flutter-apk\app-debug.apk
adb install -r build\app\outputs\flutter-apk\app-debug.apk  # install without flutter run
```
