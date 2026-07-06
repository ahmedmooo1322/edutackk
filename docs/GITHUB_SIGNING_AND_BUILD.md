# EduTrack signed build notes

This package uses GitHub Actions to create a clean Android v2 embedding Flutter project during CI, copy `app_src/lib` into it, restore the signing keystore from GitHub Secrets, and build signed APK/AAB artifacts.

Required GitHub Secrets:

- ANDROID_KEYSTORE_BASE64
- ANDROID_KEYSTORE_PASSWORD
- ANDROID_KEY_ALIAS
- ANDROID_KEY_PASSWORD

Current app version: 0.1.9+19

If GitHub still reports Android v1 embedding, make sure GitHub is running `.github/workflows/build-apk.yml` from this package and there are no other old workflows running.
