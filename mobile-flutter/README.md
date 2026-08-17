# Skin Lens AI Mobile

Flutter test app for the Skin Care AI analysis pipeline.

## What This App Does

- Logs in or registers a mobile tester account against the Laravel API.
- Picks a skin image from the camera or gallery.
- Uploads the image to `POST /api/skin-analyses`.
- Shows skin type, confidence, concerns, skin health score, and recommended products.

## Run The Full AI Analysis Stack

Run each service in a separate terminal.

```powershell
cd D:\Skin_care_AI_platform\ai-service-python
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --host 127.0.0.1 --port 5000 --reload
```

```powershell
cd D:\Skin_care_AI_platform\backend-laravel
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

```powershell
cd D:\Skin_care_AI_platform\mobile-flutter
flutter run
```

For Android emulator testing, keep the app API URL as:

```text
http://10.0.2.2:8000/api
```

For a real Android phone, replace it with your computer LAN IP:

```text
http://YOUR_COMPUTER_IP:8000/api
```

Example:

```text
http://192.168.1.10:8000/api
```

If login says it cannot connect:

- Make sure Laravel is running with `--host=0.0.0.0`, not `127.0.0.1`.
- Make sure your phone and computer are on the same Wi-Fi.
- Allow PHP/Laravel through Windows Firewall if Windows asks.
- Use `10.0.2.2` only for Android emulator, not for a real phone.
- Keep Python AI running on the same computer at `127.0.0.1:5000`; Laravel calls Python, the phone does not call Python directly.

## Build Release APK

```powershell
cd D:\Skin_care_AI_platform\mobile-flutter
flutter build apk --release
```

The APK is created at:

```text
build\app\outputs\flutter-apk\app-release.apk
```
