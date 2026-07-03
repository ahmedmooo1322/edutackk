# EduTrack Task 2 APK — GitHub Ready v2

## Build note

This package uses an unsigned/debug APK workflow. No keystore or GitHub signing secrets are required.



Flutter Android MVP for the EduTrack student app.

## What changed in v2

- Login fields are blank by default.
- App name after installing: `EduTrack`.
- Added nicer EduTrack logo in the app and a custom Android launcher icon.
- Added Arabic/English language toggle in Settings.
- Added Profile page with student DB ID, public ID, stage, grade, progress, and subscription data.
- App renders even when subscription is not activated.
- Inactive subscription is shown as `Free Plan` with 3 AI messages/day.
- Registration stage/level rules:
  - Primary = 6 levels
  - Preparatory = 3 levels
  - Secondary = 3 levels
- Arabic grade names include:
  - الصف الاول الاعدادي
  - الصف الثاني الاعدادي
  - الصف الثالث الاعدادي
  - الصف الاول الثانوي
  - الصف الثاني الثانوي
  - الصف الثالث الثانوي
- GitHub Actions workflow builds APK without needing Windows Flutter/Android Studio.

## Default backend

```text
https://ai.elbahet-sm.com
```

You can change it inside app Settings.

## Build on GitHub

Upload this repo to GitHub, then open:

```text
Actions → Build EduTrack APK → Run workflow
```

Download artifact:

```text
edutrack-debug-apk
```

Install:

```text
app-debug.apk
```

## Expected root files

```text
.github/workflows/build-apk.yml
app_src/
docs/
tools/
README.md
```

Do not upload the whole folder inside another folder. `app_src` must be at repo root.

## v3 loading fix

This package fixes the first-open/login/register/settings infinite loading issue by moving initial screen loads to a safe Flutter lifecycle path and by making Settings render immediately. It also keeps the free-plan behavior: inactive subscription users can enter the app and use the 3-message/day free limit.

Build with GitHub Actions as before.


## v4 message display fix
- Chat bubbles now allow wider text, explicit RTL/LTR direction, line height, and unlimited lines.
- Rebuild APK after uploading this version to GitHub.

## v5 Community + Loading/History Fix

New APK features:
- AI chat loads saved history from backend: last 20 messages, then Load more 50-by-50.
- AI chat shows daily remaining messages in Arabic/English.
- Dark mode in Settings and quick toggle in AI Chat.
- API Base URL is hidden behind Admin API key verification.
- Registration includes phone and username.
- Primary stage hidden for now; only Preparatory and Secondary are shown.
- Level room, student search, friend requests, friends list, private chat, report/block actions.
- Photo/PDF attachment picker for level room and private chat, max 10 MB enforced by backend.

Build using GitHub Actions as before.


## v5.1 GitHub build fix

This package fixes the GitHub Actions Android build failure caused by `flutter_plugin_android_lifecycle` / `file_picker` requiring Android compile SDK 35.

The workflow now:

- installs Android SDK platform 35
- creates the Flutter Android project
- forces `compileSdk = 35` and `targetSdk = 35` before building

No backend or database change is needed for this APK-only build fix.


## v6 UI

Adds bottom navigation, profile photo upload, friends/search merged tab, inbox with pinned level room and message requests.


## V6.1 safe patch

This APK package is based on V6 UI/community, not V7.

It keeps the Android SDK 36 GitHub Actions workflow that already worked, and applies only the requested UI/upload/back-button/settings fixes.

## V6.3 signed release + inline media patch

Based on V6.2 / V6.1 line, not V7.

Changes:
- Chat photos render inline inside private chats and level rooms.
- Tapping a photo opens full-screen preview.
- PDFs show as file cards and open externally.
- Friend profile action now shows Unfriend when already friends, and Request already sent when pending.
- GitHub Actions now builds a debug APK.

Required GitHub Secrets for signed release build:

```text
KEYSTORE_BASE64
KEYSTORE_PASSWORD
KEY_ALIAS
KEY_PASSWORD
```

Artifact name:

```text
edutrack-debug-apk
```

APK output:

```text
app-debug.apk
```
