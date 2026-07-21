# The Wiretap operations guide

## Requirements

- Docker Engine with Compose, Node.js 24+, Flutter stable, Android SDK, and Java 17.
- A local MariaDB instance is the sole source of truth. Do not use SQLite or client-side balance storage.

## First deployment

1. Create `.env` from the repository `.env.example`. Set a unique, at least 64-character `JWT_SECRET`, database credentials, the Arabic/brand-safe `COIN_NAME`, stake limits within 50–1000, the server-enforced countdown, and working SMTP credentials for password-reset delivery.
2. Start the database from the repository root: `docker compose --env-file .env up -d`. The schema is only initialized on the first volume creation; for a manually installed MariaDB, create the database with UTF-8 (`utf8mb4`) first, then run `mariadb --database="$DB_NAME" < database/schema.sql`.
3. Copy the root `.env` into `backend/.env`, then run `cd backend && npm ci && npm run seed:admin && npm run start`.
4. Import manually reviewed stories with `npm run import:stories -- ../stories.json`. Every item must have five levels and three choices per level. The importer rejects malformed stories and imports each story transactionally.
5. Build the Android app: `cd flutter && flutter pub get && flutter build apk --release --dart-define=API_BASE_URL=https://your-api.example/api/v1`.

For Android emulator local use, use `http://10.0.2.2:3000/api/v1`. For a physical phone, use the LAN IP of the computer and only a trusted local network. Set `usesCleartextTraffic` to `false` before any internet deployment and use HTTPS.

## Game and wallet rules

The API assigns a random story only where `stories.status = published`, its category is active, and no `story_assignments` record exists for that user/story pair. Completing, expiring, or abandoning still retains that unique assignment. An active game must be resumed before another starts.

The app’s displayed countdown is only a visual aid. The API computes the deadline from `games.level_started_at` plus `LEVEL_COUNTDOWN_SECONDS`. On expiry it either applies the configured server choice or marks the game abandoned. A request after the deadline cannot force its own choice.

The stake is debited atomically before a game is created. A withdrawal immediately creates a `withdrawal_hold` ledger debit; a rejected withdrawal writes a refund ledger row. Approved deposits and administrator changes also go through the same locked wallet service. Never update `users.balance` directly.

## Admin guide

The bootstrap credentials are `ADMIN_EMAIL` and `ADMIN_PASSWORD`; change the password with the reset flow after SMTP is configured. Admin endpoints require an authenticated `admin` role.

Key administrative actions:

- Publish/unpublish stories: `PATCH /api/v1/admin/stories/:storyId/status` with `{ "status": "published" }`.
- Import stories using the reviewed importer above; it preserves normalized categories, levels, and choices.
- Review requests: `POST /api/v1/admin/deposits/:requestId/review` or `/withdrawals/:requestId/review` with `{ "action": "approve"|"reject", "note": "..." }`.
- Adjust balances only through `POST /api/v1/admin/wallet/adjustments`; this creates a ledger transaction and audit record.
- Ban or unban: `PATCH /api/v1/admin/users/:userId/status`.

## API summary

All endpoints return `{ "success": true, "data": ... }` or `{ "success": false, "error": { "code", "message" } }`.

| Area | Endpoints |
| --- | --- |
| Session | `POST /auth/register`, `/login`, `/refresh`, `/logout`; `GET /auth/me` |
| Config | `GET /config/public-config` |
| Game | `POST /games`, `GET /games/resume`, `GET /games/:id`, `POST /games/:id/choice`, `POST /games/:id/abandon`, `GET /games/history` |
| Wallet | `GET /wallet/balance`, `/wallet/transactions`, `POST /wallet/deposits`, `/wallet/withdrawals` |
| Notifications | `GET /notifications`, `PATCH /notifications/:id/read` |
| Admin | `/admin/dashboard`, `/admin/users`, `/admin/requests/:kind`, story, review, status, and adjustment endpoints |

## Troubleshooting

- `NO_NEW_STORIES`: import and publish additional stories. The system intentionally does not repeat any assigned story.
- `INSUFFICIENT_BALANCE`: approve a deposit request or reduce the stake. Do not change the balance directly in SQL.
- `Invalid or expired access token`: obtain a rotated refresh token or sign in again.
- Android cannot reach local API: confirm the `API_BASE_URL`, firewall, and that the phone can reach the server; `localhost` means the phone itself.
- Schema changes after first Docker start: back up the volume, apply a reviewed migration, and restart. Do not rely on the initial schema mount to alter an existing database.

## Folder structure

`backend/src` contains layered HTTP routes, controllers, validation, services, repositories, security middleware, and configuration. `database/schema.sql` is the normalized MariaDB baseline. `flutter/lib` is feature-first and separates domain models, data repositories, and presentation. `.github/workflows` verifies both the API and Android artifact builds.
