# Backend Connection Guide

## Live backend

Default API URL in this APK source is now:

```text
https://ai.elbahet-sm.com
```

Use this for emulator and real phone builds when the public backend is live.

## Local fallback

If you want to test against your PC directly, open the app Settings screen and change the backend URL.

Android emulator local backend:

```text
http://10.0.2.2:9999
```

Real phone on same Wi-Fi:

```text
http://YOUR_PC_LAN_IP:9999
```

Example:

```text
http://192.168.1.14:9999
```

## HTTPS note

For public phone testing, HTTPS is recommended. The app default now uses HTTPS.

## Health test

Before testing the APK, open this in a browser:

```text
https://ai.elbahet-sm.com/health
```

It should return the backend health response.
