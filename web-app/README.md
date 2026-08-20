# Skino Web App

Customer-facing Vue web app for Skino.

This app is the new user web direction. It is separate from `admin-vue`, which remains the internal admin dashboard.

## Run Locally

```powershell
cd D:\Skin_care_AI_platform\web-app
npm install
npm run dev -- --host 0.0.0.0 --port 5174
```

Open:

```text
http://localhost:5174
```

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

The first UI step is intentionally frontend-only. API login, scan upload, routine, appointment, and history wiring will be added in later steps.
