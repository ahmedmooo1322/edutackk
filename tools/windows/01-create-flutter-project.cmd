@echo off
setlocal

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter was not found in PATH.
  echo Install Flutter first, then open a new terminal and retry.
  exit /b 1
)

if not exist edutrack_app (
  flutter create edutrack_app --platforms=android --org com.edutrack --project-name edutrack_app
)

xcopy /E /Y app_src\lib edutrack_app\lib\
copy /Y app_src\pubspec.yaml edutrack_app\pubspec.yaml
copy /Y app_src\analysis_options.yaml edutrack_app\analysis_options.yaml

powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='edutrack_app/android/app/src/main/AndroidManifest.xml'; $s=Get-Content $p -Raw; if($s -notmatch 'usesCleartextTraffic') { $s=$s -replace '<application ', '<application android:usesCleartextTraffic=\"true\" '; Set-Content $p $s -Encoding UTF8 }"

cd edutrack_app
flutter pub get

echo.
echo EduTrack Flutter Android project is ready in edutrack_app
echo Run: cd edutrack_app ^&^& flutter run
endlocal
