# EduTrack Task 2 APK MVP

This package starts **Task 2**: an Android APK user experience that talks directly to the Task 1 backend.

It is a Flutter Android MVP for students only.

## Current screens

- Login
- Register student
- Home
- AI chat
- Subscription status
- Settings / backend URL

## Backend required

Task 1 backend must be running:

```bat
npm run dev
```

Worker must be running:

```bat
npm run worker
```

Default backend URL in the app:

```text
https://ai.elbahet-sm.com
```

This works for Android emulator and real phones as long as the public backend is live.

Local fallback URLs can still be set from the app Settings screen:

```text
http://10.0.2.2:9999
http://YOUR_PC_LAN_IP:9999
```

## Build setup on Windows

1. Install Flutter.
2. Install Android Studio / Android SDK.
3. Unzip this package.
4. From this package folder, run:

```bat
tools\windows\01-create-flutter-project.cmd
```

5. Run debug app:

```bat
tools\windows\02-run-debug.cmd
```

6. Build debug APK:

```bat
tools\windows\03-build-debug-apk.cmd
```

Debug APK location:

```text
edutrack_app\build\app\outputs\flutter-apk\app-debug.apk
```

## Important notes

This is an MVP source package. It does not include compiled APK because Flutter/Android SDK are not available inside this chat environment.

The app currently supports only the student flow. Teacher/parent screens are later Task 2 milestones. Admin will be Task 3 website only.

## Tested against Task 1 APIs

- POST `/api/v1/auth/register`
- POST `/api/v1/auth/login`
- GET `/api/v1/me`
- POST `/api/v1/student/chat`
- GET `/api/v1/jobs/:id`
- POST `/api/v1/auth/logout`

## If the phone cannot connect

- Emulator: use `http://10.0.2.2:9999`
- Real phone: use `http://YOUR_PC_LAN_IP:9999`
- Make sure phone and PC are on same Wi-Fi.
- Allow Node.js/backend through Windows Firewall.
- Check backend health from phone browser: `http://YOUR_PC_LAN_IP:9999/health`

## Build on GitHub Actions

This package includes a ready workflow:

```text
.github/workflows/build-apk.yml
```

Upload this folder to a GitHub repository, then open:

```text
Actions → Build EduTrack APK → Run workflow
```

After it completes, download the artifact named:

```text
edutrack-debug-apk
```

Full steps are in:

```text
docs/GITHUB_ACTIONS_BUILD.md
```
