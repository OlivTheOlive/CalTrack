# CalTrack

CalTrack is a Flutter app for tracking calories and related health logs.

## Requirements

- Flutter SDK (Dart is bundled with Flutter)
- Android Studio (recommended) or Android SDK + platform tools
- Java 17 (required by the Android build configuration in this repo)

## Setup

```bash
flutter pub get
```

## Run

- Run on a connected device or emulator:

```bash
flutter run
```

## Tests

```bash
flutter test
```

## Build an APK (Android)

### Debug APK (quick local install)

```bash
flutter build apk --debug
```

Output:

- `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK

```bash
flutter build apk --release
```

Output:

- `build/app/outputs/flutter-apk/app-release.apk`

## Sideload the APK to a device

### Option A: Install with adb (recommended)

1. Enable Developer options and USB debugging on the Android device.
2. Connect the device over USB (or use a running emulator).
3. Verify the device is visible:

```bash
adb devices
```

1. Install the APK:

```bash
# Debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Option B: Copy the APK and install on-device

1. Copy `app-debug.apk` or `app-release.apk` to the phone (USB file transfer, email to yourself, cloud drive, etc.).
2. Open the APK on the phone and install it.
3. If prompted, allow installs from unknown sources for the app you used to open the APK (for example, your file manager).

### Notes about signing

This repository currently signs the Android `release` build type with the **debug** signing config so that `flutter run --release` / release builds work out of the box.

