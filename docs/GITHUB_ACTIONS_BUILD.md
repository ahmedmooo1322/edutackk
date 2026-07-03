# Build APK with GitHub Actions

This package is GitHub-ready. You do not need Flutter, Android Studio, or PowerShell on your Windows PC.

## Upload to GitHub

1. Create a new GitHub repository, for example `edutrack-apk`.
2. Upload all files from this folder to the repository.
3. Make sure this file exists in GitHub:

```text
.github/workflows/build-apk.yml
```

## Run the build

1. Open the GitHub repository.
2. Go to **Actions**.
3. Select **Build EduTrack APK**.
4. Click **Run workflow**.
5. Wait until it finishes.

## Download the APK

1. Open the completed workflow run.
2. Scroll to **Artifacts**.
3. Download **edutrack-debug-apk**.
4. Extract the downloaded zip.
5. Install `app-debug.apk` on your Android phone.

## Backend URL

The app default backend is:

```text
https://ai.elbahet-sm.com
```

You can change it later inside the app Settings screen.

## Notes

- This workflow builds a debug APK for testing.
- For publishing to Google Play, you will later need a signed release APK/AAB.
- The debug APK is fine for direct phone installation and MVP testing.
