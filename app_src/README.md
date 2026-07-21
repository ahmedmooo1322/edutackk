# The Wiretap Android source

This is a portable Flutter source bundle. It deliberately does not include generated Android Gradle files.

## GitHub build

Upload this folder as `app_src/` at the root of a GitHub repository together with `.github/workflows/build-android.yml`. The workflow creates a new Flutter Android project, copies this source bundle into it, runs analysis/tests, then uploads a debug APK and AAB artifact.

## Local build

Create a fresh Android Flutter project, then copy these items into it:

- `lib/`
- `test/`
- `pubspec.yaml`
- `analysis_options.yaml`
- `android/app/src/main/`

Run `flutter pub get`, then `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1` for a local Android emulator backend.

