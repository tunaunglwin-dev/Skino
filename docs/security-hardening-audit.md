# Skino Security and Quality Audit

Date: 2026-07-23

## Scope Checked

- Laravel backend API, auth, validation, database queries, contacts module, catalog, and skin analysis flow.
- Vue admin login/dashboard and admin auth storage.
- Flutter mobile auth, scan flow, settings, and guest-first UX.
- Python AI service upload endpoint and tests.
- Project weight from generated folders, datasets, and model artifacts.

## Fixes Applied

- Backend registration now uses the same token creation path as login.
- Skin analysis history pagination is capped to `1..50` to prevent oversized requests.
- Password reset requests no longer reveal whether an email exists.
- `.env.example` now uses safer defaults: `APP_DEBUG=false`, `LOG_LEVEL=info`, admin seed disabled.
- Admin Vue token storage moved from `localStorage` to `sessionStorage`, with legacy token migration cleanup.
- Admin reset-password page removes `token` and `email` from the browser URL after reading them.
- Mobile email login no longer ships with prefilled demo credentials.
- AI service rejects unsupported upload content types before image parsing and caps images at 8 MB.
- Added tests for Contacts API and password reset email enumeration behavior.

## SQL Injection Review

No raw SQL execution was found in app code. Searches checked for `DB::raw`, `selectRaw`, `whereRaw`, `orderByRaw`, `statement`, and `unprepared`.

Current query filters use Laravel query builder and validation rules. User-provided filters are parameterized. Search fields still allow wildcard-style broad matching, but this is not SQL injection.

## Remaining Security Priorities

1. Add live admin Contacts UI API integration with create/edit forms using strict client-side and backend validation.
2. Add CSRF/session-cookie auth for admin web before production, or keep bearer tokens short-lived and HTTPS-only.
3. Add image malware scanning or deeper file validation before storing user scan images in production.
4. Add audit logs for admin actions: contact create/update, notes, status changes, product updates, appointment edits.
5. Add role permissions beyond `admin/user`: specialist, seller, vendor, support/admin.
6. Add production CORS configuration and rate limits per endpoint group.
7. Add privacy controls for deleting/exporting user scan history and contact data.

## Project Weight Notes

Safe generated folders already ignored by `.gitignore`:

- `admin-vue/dist`
- `admin-vue/node_modules`
- `backend-laravel/vendor`
- `mobile-flutter/build`
- `mobile-flutter/.dart_tool`
- `ai-service-python/.pytest_cache`
- Python `__pycache__` folders

Datasets are the largest project weight, but they are training assets. Do not delete them casually. Recommended policy:

- Keep raw source datasets outside the production app bundle.
- Keep only the current demo model in deploy/runtime packaging.
- Archive older prepared datasets after final model choice.
- Store dataset lineage in docs so training can be reproduced without keeping every duplicate prepared folder in the main software package.

## UX Notes

- Mobile is now guest-first, Myanmar-default, and scan-focused.
- Admin visual design matches Skino better after the theme refresh.
- Contacts is correctly positioned as the center of ERP-style operations.
- Next UX improvement should be live Contacts list/create/edit connected to the admin API, then appointment CRM.
