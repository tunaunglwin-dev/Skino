# Google Login Android Setup

The Flutter app can call Google Sign-In, but Google Cloud must know the exact Android app package and SHA-1 fingerprint.

Current Android package:

```text
com.example.mobile_flutter
```

## Get Debug SHA-1

Run this on Windows:

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

Copy the `SHA1` value.

## Google Cloud

Create or update an Android OAuth client:

- Package name: `com.example.mobile_flutter`
- SHA-1: value from the command above

Also keep a Web OAuth client and put that web client ID in:

```text
mobile-flutter/lib/src/core/google_auth_config.dart
backend-laravel/.env GOOGLE_CLIENT_ID
```

Put the Android client ID in:

```text
backend-laravel/.env GOOGLE_MOBILE_CLIENT_ID
```

After changing `.env`, restart Laravel:

```powershell
cd D:\Skin_care_AI_platform\backend-laravel
php artisan config:clear
php artisan serve --host=0.0.0.0 --port=8000
```

If Google says the token was issued for a different app, the Android client ID or SHA-1 does not match the APK installed on the phone.
