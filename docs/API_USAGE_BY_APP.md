# API Usage By App

## Login

`POST /api/v1/auth/login`

Request:

```json
{
  "email": "student@example.com",
  "password": "password123"
}
```

App saves `token` and sends it in:

```text
Authorization: Bearer TOKEN
```

## Register Student

`POST /api/v1/auth/register`

Request:

```json
{
  "name": "Test Student",
  "role": "student",
  "email": "student@example.com",
  "password": "password123",
  "stage": "prep",
  "level": 2
}
```

## Current User

`GET /api/v1/me`

Used by home and subscription screen.

## Create AI Chat Job

`POST /api/v1/student/chat`

Request:

```json
{
  "message": "Explain fractions simply."
}
```

Response:

```json
{
  "ok": true,
  "job_id": "...",
  "status": "queued",
  "poll_url": "/api/v1/jobs/...",
  "retry_after_ms": 1500
}
```

## Poll Job

`GET /api/v1/jobs/:id`

The app polls until `done` is true.
