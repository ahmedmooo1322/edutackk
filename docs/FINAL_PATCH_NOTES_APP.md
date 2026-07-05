# EduTrack App Final Patch Notes

Version: `0.1.7+17`

## Added

- In-app Admin Mode password reset action.
- Settings switch for admin accounts:
  - Switch to Admin Mode
  - Switch to Normal Support Mode
- Admin normal/support mode card linking back to Admin Dashboard.
- Smooth Material route transitions and polished card/button shapes.
- Settings developer credit:

```text
Developed with ❤️
By
Ahmed Elbahet
```

## Stability

- Admin Dashboard now caches the API client after dependencies load instead of repeatedly resolving it during admin actions.
- Added safer mounted checks around async admin actions.
- Localization keys verified for English and Arabic.

## Build note

Run locally:

```bash
flutter clean
flutter pub get
flutter analyze
flutter build apk --release
```
