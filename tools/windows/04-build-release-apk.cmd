@echo off
cd edutrack_app
flutter build apk --release

echo.
echo Release APK output:
echo edutrack_app\build\app\outputs\flutter-apk\app-release.apk
echo.
echo Note: For Play Store or public release you must configure proper app signing first.
