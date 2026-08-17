# Skino Project Scope

## 1. Product Summary

Skino is a face beauty improvement platform that combines:

- facial skin analysis
- specialist appointment booking
- personalized beauty routines
- reminders and user skin-progress tracking
- admin operations through ERP-style modules

The product is a wellness and face beauty assistant. It is not a medical diagnosis system. The app can detect visible skin patterns, suggest daily beauty routines, send reminders, track improvement, and connect users with specialists when needed, but medical decisions must stay with licensed professionals.

## 2. Main Business Goal

The goal is to keep users active in the app by helping them understand their skin, take action, and track improvement over time.

The business model can include:

- appointment fees or commissions from specialists
- premium progress tracking or specialist follow-up later
- beauty routine subscriptions or premium reminder plans later

## 3. User-Facing Services

### 3.1 Facial Skin Analysis

Users upload or scan a face image. The AI service returns:

- skin type, such as `normal`, `oily`, `dry`, `combination`, or `sensitive`
- visible concerns, such as `acne`, `dark_spots`, `oiliness`, `dryness`, or `redness`
- confidence values
- skin health score
- daily beauty routine suggestion
- next check-in or reminder suggestion

The first production baseline should focus on:

- normal or healthy skin detection
- acne detection
- basic routine recommendation
- scan history

Future AI versions can add more concerns after enough clean labeled data exists.

### 3.2 Appointment With Specialist

Users can book appointments with skincare specialists or clinics.

Core appointment features:

- specialist profile
- available schedule
- appointment request
- appointment status: pending, confirmed, completed, cancelled, no-show
- appointment notes
- skin analysis history visible to the specialist when permission is granted
- follow-up appointment recommendation

The CRM module in the admin panel mainly supports this workflow.

### 3.3 Beauty Routines

The platform should focus on helping users improve face beauty through consistent routines, not on product selling as the main experience.

Core routine features:

- skin concern tags
- routine step tags, such as cleanser, serum, moisturizer, sunscreen
- morning/evening routine guidance
- reminder schedule
- routine completion tracking
- safety warnings based on allergies or sensitivity
- optional product reference later, without making commerce the main focus

Routine copy should stay in beauty/wellness language and avoid diagnosis claims.

### 3.4 Progress Tracking

Progress tracking is important for retention. Users should come back because they can compare their skin journey.

Core tracking features:

- scan history timeline
- skin health score changes
- concern changes over time
- before/after comparison
- routine checklist
- routine adherence tracking
- appointment follow-up notes
- reminders and notifications

The app should answer: "Is my skin improving, staying the same, or getting worse?"

## 4. Admin Panel Scope

The admin panel should be designed like a lightweight ERP/CRM system. It should not be only a simple product admin.

### 4.1 Contacts Module

Contacts is the central people and organization module. It should be reused across the platform.

Contact types:

- app user
- specialist
- seller
- vendor
- clinic
- warehouse contact
- internal staff
- partner

Contact data:

- name
- email
- phone
- Google account identity when user logs in with Google
- role/type
- status
- address
- notes
- related appointments
- related orders
- related products
- related skin history when applicable

Notes are important. Admins should be able to record notes for users, specialists, sellers, vendors, and partners.

### 4.2 CRM Module

CRM is mainly for appointment and relationship management.

Core CRM features:

- appointment pipeline
- specialist leads
- user consultation requests
- follow-up tasks
- conversation notes
- appointment history
- specialist performance
- cancelled/no-show tracking

CRM should help answer:

- Which users need follow-up?
- Which appointments are pending?
- Which specialists are active?
- Which users may need specialist help based on scan history?

### 4.3 Optional Inventory Module

Inventory is optional and later-phase. It should only matter if the platform later supports physical beauty products, partner kits, or clinic inventory.

Possible later inventory features:

- beauty kit stock by warehouse/location
- stock in and stock out
- low-stock alert
- partner/clinic kit ownership
- inventory adjustment history
- kit availability
- kit movement history

Inventory may also link to:

- routine kit suggestion history
- order fulfillment
- appointment-related kit suggestions
- user skin history when a kit was suggested

### 4.4 Sales Module

Sales is not part of the early focus. It should wait unless the business decides to add paid routines, specialist bookings, subscriptions, or products.

Possible later sales features:

- cart/order records
- order status
- payment status
- customer purchase history
- seller/vendor sales history
- refunds or cancellations later
- commission tracking later

Sales can start simple. It does not need full enterprise sales complexity for MVP.

### 4.5 Accounting Module

Accounting is optional for early MVP, but the structure should not block it.

Possible accounting features:

- payment records
- seller/vendor payable amount
- appointment commission
- routine, subscription, or kit commission
- refund records
- platform revenue summary
- basic expense tracking later

Accounting should be added after order and appointment flows are stable.

### 4.6 User Activity And Event Tracking

User activity tracking helps retention, analytics, and operational decisions.

Track events such as:

- login
- Google login
- scan started
- scan completed
- routine viewed
- appointment requested
- appointment completed
- routine checked
- progress photo uploaded

Useful admin views:

- active users
- inactive users
- scan frequency
- appointment conversion
- routine recommendation conversion
- retention by week/month

## 5. Core Data Areas

The project should be organized around these main data areas:

- users and auth
- contacts
- skin analyses
- progress tracking
- specialists
- appointments
- beauty routines
- notifications/reminders
- optional products later
- optional payments later
- admin notes
- activity events

Contacts should connect many of these areas, so the admin panel has one shared place to understand people and organizations.

## 6. Recommended MVP Scope

The MVP should stay narrow enough to finish.

### MVP Must Have

- user registration/login
- Google login support if practical
- face image upload or scan
- AI skin analysis with normal/healthy and acne baseline
- analysis result screen
- analysis history
- beauty routine recommendation based on scan result
- routine reminder hooks
- appointment request with specialist
- admin contacts module
- admin routine/content management
- admin appointment management
- admin scan/history view

### MVP Should Have

- specialist notes
- user progress timeline
- user activity event log

### MVP Can Wait

- full accounting
- advanced ERP dashboards
- complex warehouse transfers
- seller payout automation
- chat
- subscription system
- ecommerce/product sales
- advanced AI deep learning model
- dermatologist-grade diagnosis

## 7. Roles And Permissions

Suggested roles:

- user
- admin
- specialist
- staff

Early MVP can start with:

- user
- admin
- specialist

Seller/vendor roles can wait unless third-party products become real later.

## 8. System Components

### Mobile App

Used by customers.

Responsibilities:

- login/register
- scan/upload face image
- view skin analysis
- view beauty routine guidance
- track progress
- request appointments

### Laravel Backend

Main API and business system.

Responsibilities:

- authentication
- users and roles
- contacts
- skin analysis records
- beauty routines
- routine recommendations
- appointments
- admin APIs
- activity events

### Python AI Service

Image analysis service.

Responsibilities:

- receive image from Laravel
- run skin analysis model
- return stable JSON result
- keep model logic separate from business logic

### Vue Admin Panel

Internal operation dashboard.

Responsibilities:

- contacts
- CRM appointments
- routines/content
- optional inventory later
- user scan history
- activity events
- reports

## 9. Important Product Rules

- The app must say it is skincare guidance, not medical diagnosis.
- The mobile app should default to Myanmar language and allow English switching in Settings.
- Specialist appointment should be recommended for severe or uncertain cases.
- User consent and privacy must be clear for face images.
- Face images and skin history are sensitive data.
- Routine recommendation should be explainable: why this routine was shown.
- Admin notes should be traceable by author and time.
- AI model can improve over time without changing the mobile/backend API contract.

## 10. Development Order

Recommended build order:

1. Stable auth and user profile.
2. Skin analysis upload and history.
3. Normal/acne AI baseline integration.
4. Beauty routine recommendation rules.
5. Appointment request workflow.
6. Admin contacts.
7. Admin appointment CRM.
8. Admin routine/content management.
9. Progress tracking.
10. Optional payments/products only if needed.
11. Activity analytics.
12. Accounting and vendor payout logic.

## 11. Current Narrow Scope Statement

For the next development phase, Skino should focus on:

> A face beauty mobile app where users can enter as guests, scan their face, understand whether their skin looks normal/healthy or acne-prone, receive daily beauty routine guidance, get reminders, book a specialist appointment when needed, and track improvement over time. The admin panel should manage contacts, appointments, routines/content, scan history, and activity events.

Everything outside that statement should be treated as later-phase unless it directly supports the MVP.
