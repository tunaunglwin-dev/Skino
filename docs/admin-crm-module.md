# Skino Admin CRM Module

## Purpose

CRM is the appointment and follow-up pipeline for Skino. It connects real contacts to specialist support without duplicating user, specialist, seller, or vendor identity data.

## Current Implementation

- `crm_records`: appointment/lead pipeline records.
- `crm_notes`: notes for appointment updates, follow-up, safety, or CRM context.
- Every CRM record links to a required `contact_id`.
- A CRM record can optionally link to a `specialist_contact_id`.
- Admin API is live and protected by admin role middleware.
- Admin dashboard has a live **CRM** module.

## CRM Fields

- `contact_id`: required client/user/lead contact.
- `specialist_contact_id`: optional specialist contact.
- `owner_id`: admin who created the record.
- `title`: short appointment or opportunity name.
- `stage`: `new`, `contacted`, `appointment_scheduled`, `completed`, `closed`.
- `priority`: `low`, `normal`, `high`, `urgent`.
- `appointment_status`: `not_scheduled`, `scheduled`, `completed`, `cancelled`.
- `scheduled_at`: appointment date/time.
- `beauty_goal`: user's goal.
- `concern_summary`: scan/user concern context.
- `tags`: lightweight filtering labels.

## Admin Endpoints

- `GET /api/admin/crm-records`
- `POST /api/admin/crm-records`
- `GET /api/admin/crm-records/{crmRecord}`
- `PUT /api/admin/crm-records/{crmRecord}`
- `POST /api/admin/crm-records/{crmRecord}/notes`

## Next Improvements

- Link CRM creation from mobile appointment request.
- Show related scan history inside CRM detail.
- Add calendar view.
- Add specialist account permissions.
- Add commission tracking after appointment completion.
