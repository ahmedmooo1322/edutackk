# EduTrack Task 2 APK — GitHub Ready v2

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
