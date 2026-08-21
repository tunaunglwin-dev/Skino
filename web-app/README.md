# Skino Web App

Customer-facing Vue web app for Skino.

## Frontend Stack

- Vue 3 with `<script setup>`
- Vite 8
- Tailwind CSS 4 through the official Vite plugin
- Laravel bearer-token API integration
- Browser MediaDevices camera capture with image-upload fallback

This app is the new user web direction. It is separate from `admin-vue`, which remains the internal admin dashboard.

## Run Locally

```powershell
cd D:\Skin_care_AI_platform\web-app
npm install
Copy-Item .env.example .env
npm run dev
```

Set `VITE_GOOGLE_CLIENT_ID` in `.env` to the same Google web client ID allowed by Laravel's `GOOGLE_CLIENT_ID`. Restart Vite after changing `.env`.

Production environment variables still take priority. For hackathon resilience, a production build without Vercel variables falls back to the public Skino Render API URL and public Google OAuth web client ID defined in `src/services/skinoApi.js`; local development continues to use localhost.

Open:

```text
http://localhost:5174
```

Use this exact URL for Google Sign-In during local development. Google OAuth
considers `localhost`, `127.0.0.1`, and different ports to be different origins.

For another laptop/phone on the same network, open:

```text
http://YOUR_LAPTOP_IP:5174
```

## Build

```powershell
npm run build
```

## Backend Flow

The planned runtime flow is:

```text
Vue web app -> Laravel API -> Python AI service -> Laravel API -> Vue web app
```

The web app now uses the same core user flow as Flutter:

```text
Google/email login -> onboarding + consent -> camera/upload scan -> result -> routine -> history
```

Camera access works on `localhost` during development. A deployed web app must use HTTPS for `navigator.mediaDevices.getUserMedia()` to be available. Upload remains available as the fallback on browsers without camera access.

Start the supporting services before testing a real scan:

```powershell
# Laravel API
cd D:\Skin_care_AI_platform\backend-laravel
php artisan serve --host 0.0.0.0 --port 8000

# Python AI service (second terminal)
cd D:\Skin_care_AI_platform\ai-service-python
$env:SKIN_AI_MODEL_PATH="D:\Skin_care_AI_platform\models\skino_acne_normal_model.json"
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 5000
```
