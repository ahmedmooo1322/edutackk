# EduTrack v0.1.9+19 signing/settings patch

## Added
- GitHub Actions now builds signed release APKs using GitHub Secrets.
- Settings page is re-arranged into Account, Privacy & Safety, App, Admin Tools, About, and Danger Zone.
- Logout moved to the bottom Danger Zone.
- Added Blocked Users page with unblock support.
- Added Settings → Check for Update.
- Added app version constants: 0.1.9+19.
- Teacher quiz creation now asks Country first, then Stage, then Level.

## Required GitHub Secrets
- ANDROID_KEYSTORE_BASE64
- ANDROID_KEYSTORE_PASSWORD
- ANDROID_KEY_ALIAS
- ANDROID_KEY_PASSWORD

## Current test keystore values confirmed
- Alias: edutrack
- SHA-256 fingerprint: 28:5E:A0:1F:E7:69:18:FB:EE:CD:19:F5:37:0F:2A:8D:FE:46:28:B3:D7:85:BA:FC:E3:46:AD:28:6E:2F:00:75

Do not publish public production builds with a disposable testing keystore unless you will keep using it forever.
