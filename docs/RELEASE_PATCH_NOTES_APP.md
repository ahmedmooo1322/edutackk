# EduTrack App Release Patch Notes

Version bumped to `0.1.6+16`.

## Added

- Admin accounts now route to `/admin` after login/splash.
- New in-app Admin Mode screen:
  - overview metrics
  - user search/list
  - edit basic user info
  - activate/suspend/ban users
  - view user inbox with required audit reason
  - review private messages and delete messages with reason
  - reports overview
  - account deletion requests
  - admin audit logs
- Settings now includes an account deletion request action.
- Home screen now uses scrollable fast action cards to improve speed of access and reduce small-screen overflow.
- Bottom menu spacing was improved.

## Backend requirements

The backend must include the release patch routes from `015_release_security_admin_mode.sql` and the updated admin routes.
