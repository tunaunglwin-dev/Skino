# Database Foundation

This backend starts with a small skincare catalog schema that supports secure recommendations without relying on raw SQL or free-text matching.

## Core Tables

- `users` - application users with simple roles: `user` for mobile customers and `admin` for dashboard users
- `skin_types` - approved skin type lookup records such as oily, dry, combination
- `skin_concerns` - approved skin concern lookup records such as acne, dark spots, redness
- `product_categories` - product grouping such as cleanser, serum, moisturizer
- `products` - product catalog records
- `product_skin_concern` - recommendation weights between products and concerns
- `product_skin_type` - recommendation weights between products and skin types
- `skin_analyses` - user-owned uploaded image analysis results from the AI service

## Seeded Demo Users

These are development/demo users only:

- `admin@skin-ai.test` / `Password123`
- `user@skin-ai.test` / `Password123`

## Local Reset

```powershell
php artisan migrate:fresh --seed
```

## Design Notes

- Slugs are unique and stable, so mobile/admin clients can safely reference records by slug.
- Products use soft deletes so admin actions do not immediately destroy catalog history.
- Recommendation pivot tables include `recommendation_weight` so matching can improve later without changing the schema.
- Skin analyses store both normalized fields and the raw AI response so the model can evolve without losing traceability.
- Seeders are idempotent and safe to run more than once.
