# Skino Admin Contacts Module

## Purpose

Contacts is the identity center of the Skino admin system. Every operational module should reference a contact instead of duplicating names, emails, sellers, vendors, specialists, or user profile data.

## Contact Types

- `user`: real mobile app user, usually created from Google login or email registration.
- `specialist`: doctor, beauty specialist, clinic worker, or appointment provider.
- `seller`: product seller inside the Skino marketplace.
- `vendor`: supplier, brand, clinic, or external business partner.
- `internal`: Skino staff or operational admin contact.
- `lead`: potential specialist, seller, vendor, or customer not fully onboarded yet.

## Core Fields

- `display_name`: required human-readable contact name.
- `contact_type`: required business role.
- `source`: `google`, `manual`, or `system`.
- `status`: `active`, `archived`, or `blocked`.
- `user_id`: optional link to a real app account.
- `gmail_email`: unique Gmail marker for Google-linked app users.
- `email`, `phone`, `avatar_url`: basic contact channels.
- `specialty`: specialist focus such as acne, pigmentation, or routine care.
- `company_name`: seller, vendor, clinic, or partner organization.
- `tags`: simple labels for filtering.
- `internal_note`: admin-only summary note.
- `last_seen_at`: app activity marker for linked users.

## Workflow

1. When a user registers or logs in, the backend creates or updates their contact profile.
2. When a user signs in with Google, their Gmail address is stored as the contact's real account marker.
3. Admins can manually create contacts for specialists, sellers, vendors, leads, or internal staff.
4. Admin notes attach to the contact, not to separate modules.
5. Future modules should connect through `contact_id`:
   - CRM appointment history
   - product orders and commissions
   - scan and analysis history
   - care/routine progress
   - accounting records when needed

## Design Rule

Keep Contacts useful but not heavy. Do not force long forms at creation time. Start with identity, type, source, email/Gmail, phone, role-specific fields, tags, and notes. Add deeper fields later only when another module genuinely needs them.
