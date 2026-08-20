# Skino Project Brief For Lovable UI

Use this file as a complete product and UI brief when asking Lovable to help redesign or build UI screens for this project.

## Project Name

Skino - AI Skin Care Buddy

## One-Line Summary

Skino is a skincare and face beauty platform that lets users scan their face, understand visible skin concerns, receive simple daily routine guidance, track progress over time, and request specialist appointments when needed.

## Important Safety Positioning

Skino is a wellness, skincare, and beauty guidance app. It must not present itself as a medical diagnosis system.

Use language like:

- "visible skin guidance"
- "skin care routine"
- "beauty routine"
- "skin score"
- "specialist support"
- "not medical advice"

Avoid language like:

- "diagnose disease"
- "medical treatment"
- "dermatology diagnosis"
- "cure"

## Target Users

### Customer / App User

Someone who wants to understand their skin condition, especially acne or normal/healthy skin status, and follow a beauty routine.

Main user needs:

- Scan or upload a face image.
- See skin type, concerns, acne severity, and skin score.
- Get an easy morning/evening beauty routine.
- Save scan history.
- Track improvement over time.
- Request a specialist appointment when acne is moderate, severe, or uncertain.
- Control privacy and AI model-training consent.

### Admin / Staff

Internal team members who manage operations.

Main admin needs:

- Manage users, specialists, vendors, clinics, and staff as contacts.
- Review appointment requests in a CRM-style pipeline.
- View scan history and scan review queues.
- Manage care routines and follow-up operations.
- Review consented AI training samples and corrected labels.

### Specialist

A skincare specialist or clinic contact who can help users with appointments and follow-ups. Specialist-facing UI can come later, but the admin CRM should support specialist workflow now.

## Current Product Scope

The MVP should focus on:

- User registration and login.
- Google login support.
- Guest skin scan without saving history.
- Authenticated scan with saved history.
- AI analysis for normal/healthy skin and acne baseline.
- Skin result screen.
- Daily beauty routine recommendation.
- Routine check-in and reminder hooks.
- Appointment request.
- Admin contacts module.
- Admin CRM appointment/follow-up module.
- Admin scan review and AI training review module.
- Progress tracking.

Later features:

- Ecommerce and product orders.
- Subscriptions.
- Payments and accounting.
- Vendor payout.
- Inventory.
- Advanced AI model training UI.
- Full specialist portal.

## Existing Repository Structure

```text
Skin_care_AI_platform/
  backend-laravel/      Laravel API, authentication, database, recommendations, admin APIs
  mobile-flutter/       Flutter mobile app for users
  web-app/              Vue customer web app preview
  admin-vue/            Vue admin dashboard
  ai-service-python/    FastAPI skin analysis service
  datasets/             Local datasets for training
  models/               Saved model files
  docs/                 Project documentation
```

## Technology Stack

### Customer Mobile App

- Flutter
- Android, iOS, web, desktop scaffold exists
- Uses Laravel API
- Supports normal login, Google login, guest scan, authenticated scan, routine tracking, appointment request, privacy consent

### Customer Web App

- Vue 3
- Vite
- Currently a polished product/UI preview
- Shows landing page, login preview, dashboard module cards
- API auth is not fully connected in this web app yet

### Admin Web App

- Vue 3
- Vite
- Uses Laravel admin APIs
- Has login, password reset, dashboard, contacts, CRM, care operations, scan review, and AI training review panels

### Backend

- Laravel
- Sanctum bearer token authentication
- MySQL-ready database migrations
- Routes for auth, skin analyses, privacy consent, routine, appointment requests, catalog, admin contacts, CRM, scan review, and training samples

### AI Service

- Python FastAPI
- Receives an uploaded image from Laravel
- Returns stable JSON for skin type, concerns, acne severity, and skin health score
- Currently uses lightweight image processing / prototype logic, with model path support for later trained model use

## Main User Flow

1. User opens Skino.
2. User sees onboarding and consent language.
3. User can continue as guest or login/register.
4. User captures or uploads a clear face image.
5. App sends the image to Laravel.
6. Laravel sends the image to the Python AI service.
7. Python returns skin analysis JSON.
8. Laravel stores the result if user is authenticated.
9. User sees result:
   - skin type
   - confidence
   - visible concerns
   - acne severity
   - skin health score
   - daily routine
   - recommended products or care steps
10. User can start a routine.
11. User can check off morning/night routine steps.
12. User can request specialist appointment.
13. User can view scan history and progress.

## Guest User Flow

Guest scan should be fast and low-friction.

Guest can:

- Upload/capture image.
- See analysis result.
- See login prompt for saving history, progress tracking, and appointments.

Guest cannot:

- Save scan history.
- Track long-term progress.
- Manage active routines.
- Book authenticated appointment history.

## Authenticated User Flow

Authenticated user can:

- Save scan history.
- View previous analyses.
- Delete scan history items.
- Start a routine plan from an analysis.
- Update today's morning/night routine check-ins.
- Stop routine plan.
- Request appointment.
- Control model-training consent.
- Use Google login.

## Admin Flow

Admin signs into `admin-vue` and sees ERP/CRM-style modules.

Important modules:

- Contacts: users, specialists, leads, vendors, clinics, staff, notes
- CRM: appointment pipeline, follow-ups, user consultation requests
- Care: routine progress and follow-up operations
- Scan Review: scan quality and scan result review
- AI Training: consented samples and corrected labels

Admin UI should feel operational and calm, not like a marketing page.

## Key Backend API Endpoints

Base URL for local Laravel API:

```text
http://127.0.0.1:8000/api
```

Mobile emulator API URL:

```text
http://10.0.2.2:8000/api
```

Important endpoints:

```text
GET    /api/health
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/google
POST   /api/auth/forgot-password
POST   /api/auth/reset-password
POST   /api/auth/logout
GET    /api/me

POST   /api/guest/skin-analysis
POST   /api/guest/appointment-requests

GET    /api/privacy/model-training-consent
PUT    /api/privacy/model-training-consent

GET    /api/skin-analyses
POST   /api/skin-analyses
GET    /api/skin-analyses/{id}
DELETE /api/skin-analyses/{id}

GET    /api/routine
POST   /api/routine/start
PUT    /api/routine/today
DELETE /api/routine

POST   /api/chat/routine-assistant
POST   /api/appointment-requests

GET    /api/catalog/skin-types
GET    /api/catalog/skin-concerns
GET    /api/catalog/product-categories
GET    /api/catalog/products
GET    /api/catalog/products/{slug}

GET    /api/admin/contacts
POST   /api/admin/contacts
GET    /api/admin/contacts/{id}
PUT    /api/admin/contacts/{id}
POST   /api/admin/contacts/{id}/avatar
POST   /api/admin/contacts/{id}/notes

GET    /api/admin/crm-records
POST   /api/admin/crm-records
GET    /api/admin/crm-records/{id}
PUT    /api/admin/crm-records/{id}
POST   /api/admin/crm-records/{id}/notes

GET    /api/admin/care-routines
GET    /api/admin/scan-reviews
GET    /api/admin/training-samples
GET    /api/admin/training-samples/{id}
POST   /api/admin/training-samples/{id}/review
```

## AI Service Contract

Local AI service URL:

```text
http://127.0.0.1:5000
```

Endpoints:

```text
GET  /health
POST /analyze
```

Example AI result:

```json
{
  "skin_type": "oily",
  "skin_type_confidence": 0.82,
  "concerns": [
    {
      "name": "acne",
      "confidence": 0.76,
      "severity": "moderate"
    }
  ],
  "acne_severity": "moderate",
  "skin_health_score": 68
}
```

## Visual Brand Direction

Brand name:

```text
Skino
```

Tone:

- Friendly
- Clean
- Gentle
- Beauty/wellness focused
- Trustworthy
- Mobile-first
- Privacy-aware

Existing color direction:

- Warm orange: `#f98128`
- Deep green: `#0e5c56`
- Soft off-white: `#fbf9f4`
- Warm white: `#fffdf9`
- Soft peach border/background: `#ffe3d1`
- Dark text: `#282420`
- Muted text: `#625b53`

Use color carefully. The UI should not become only orange. Balance warm orange with green, white, dark neutral text, and subtle supporting colors.

Existing asset style:

- Skino logo
- Friendly "little guy" mascot illustrations
- Icons for scan, routine, specialist, report, reminder, progress, history, chat
- Product-style images for cleanser, moisturizer, serum, sunscreen

Relevant asset folders:

```text
mobile-flutter/assets/branding/
web-app/src/assets/branding/
admin-vue/src/assets/
```

## UI Screens Lovable Can Help Design

### Customer App / Web Screens

Design or improve these screens:

- Welcome / onboarding
- AI scan consent screen
- Guest scan screen
- Login and register
- Google login entry
- Face image upload/capture
- Loading/analyzing state
- Analysis result screen
- Acne severity result card
- Skin health score card
- Beauty routine recommendation screen
- Active routine checklist
- Reminder settings
- Scan history timeline
- Progress tracking dashboard
- Before/after comparison
- Specialist appointment request
- Appointment status screen
- Privacy and model-training consent settings
- Language switcher: Myanmar first, English second

### Admin Screens

Design or improve these screens:

- Admin login
- Password reset
- Admin dashboard
- Contacts list
- Contact detail with notes
- Contact create/edit form
- CRM appointment pipeline
- Appointment detail drawer
- Follow-up tasks
- Care routine operations
- Scan review queue
- AI training sample review
- Admin analytics overview

## Customer Dashboard Modules

The user dashboard should include these module cards:

- AI Skin Scan
- Routine
- Specialist
- Appointment
- History
- Progress
- Report
- Reminder
- Settings

Each module card should show:

- Icon or mascot image
- Short title
- One-line description
- Current status
- Clear action button

## Admin Dashboard Modules

Admin dashboard modules:

- Contacts: "Users, specialists, leads, and notes"
- CRM: "Specialist appointment cards and follow-up"
- Care: "Routine progress and follow-up operations"
- Scan Review: "Scan quality, results, bad scan review"
- AI Training: "Consented samples and label review"

Admin dashboard should prioritize:

- Search
- Filters
- Status badges
- Tables/lists
- Detail drawers
- Notes
- Clear operational actions

## UX Rules

- Make the customer app mobile-first.
- Make the admin app desktop-first and operations-focused.
- Do not make medical claims.
- Always explain that AI scan results are guidance only.
- Keep privacy controls visible and clear.
- Use simple language for skincare concerns.
- Recommend specialist help when severity is moderate, severe, or uncertain.
- Do not make ecommerce the main experience for MVP.
- Keep routines practical: cleanser, serum, moisturizer, sunscreen.
- Make scan history and progress easy to understand.
- Support Myanmar language as the default product direction, with English switching in settings.

## Suggested Lovable Prompt

Copy and paste this prompt into Lovable:

```text
I am building Skino, an AI Skin Care Buddy. Please help me design a polished mobile-first customer UI and a calm admin dashboard UI.

Skino is a wellness and skincare guidance app, not a medical diagnosis product. Users can scan/upload a face image, see visible skin concerns, acne severity, skin type, skin health score, daily beauty routine guidance, scan history, progress tracking, reminders, and specialist appointment requests.

The current stack is:
- Vue 3 + Vite customer web app preview
- Vue 3 + Vite admin dashboard
- Flutter mobile app
- Laravel API with Sanctum auth
- Python FastAPI AI service

Brand direction:
- Friendly, clean, gentle, trustworthy, beauty/wellness focused
- Warm orange #f98128
- Deep green #0e5c56
- Soft off-white #fbf9f4
- Warm white #fffdf9
- Soft peach #ffe3d1
- Dark text #282420
- Muted text #625b53
- Use the Skino logo, mascot, and scan/routine/specialist/progress icons when possible

Customer screens I need:
- Welcome/onboarding
- AI scan consent
- Guest scan
- Login/register with Google login entry
- Face upload/capture
- Analyzing/loading state
- Analysis result with skin type, concerns, acne severity, confidence, and skin score
- Beauty routine recommendation
- Active routine checklist
- Scan history timeline
- Progress tracking
- Before/after comparison
- Specialist appointment request
- Appointment status
- Privacy/model-training consent settings
- Language switcher, Myanmar first and English second

Admin screens I need:
- Admin login and password reset
- Dashboard
- Contacts module
- Contact detail with notes
- CRM appointment pipeline
- Appointment detail drawer
- Care routine operations
- Scan review queue
- AI training sample review
- Analytics overview

Important UX rules:
- Customer UI must be mobile-first.
- Admin UI must be desktop-first, dense, scannable, and operational.
- Avoid medical diagnosis wording.
- Use "guidance, not diagnosis."
- Make privacy and consent clear.
- Make specialist handoff visible when acne is moderate, severe, or uncertain.
- Do not make ecommerce the main MVP experience.

Please produce a complete UI plan with screens, layout sections, components, visual style, interaction states, and copy suggestions. Then generate implementation-ready Vue components for the customer web app first.
```

## Local Run Commands

Run each service in a separate terminal.

### Python AI Service

```powershell
cd D:\Skin_care_AI_platform\ai-service-python
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --host 127.0.0.1 --port 5000 --reload
```

### Laravel Backend

```powershell
cd D:\Skin_care_AI_platform\backend-laravel
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

### Customer Vue Web App

```powershell
cd D:\Skin_care_AI_platform\web-app
npm install
npm run dev -- --port 5174
```

### Admin Vue App

```powershell
cd D:\Skin_care_AI_platform\admin-vue
npm install
npm run dev
```

### Flutter Mobile App

```powershell
cd D:\Skin_care_AI_platform\mobile-flutter
flutter run
```

## Current Local URLs

```text
Laravel API: http://127.0.0.1:8000
Python AI service: http://127.0.0.1:5000
Vue admin: http://localhost:5173
Vue customer web app: http://localhost:5174
Flutter Android emulator API host: http://10.0.2.2:8000/api
```

## Implementation Notes For Lovable

If Lovable generates code, focus first on the Vue customer web app in:

```text
web-app/src/App.vue
web-app/src/style.css
```

Then improve the admin Vue app in:

```text
admin-vue/src/App.vue
admin-vue/src/components/
admin-vue/src/style.css
```

Do not change backend API contracts unless required. The AI service response shape should remain stable so Laravel, Flutter, and Vue can all rely on the same analysis result fields.
