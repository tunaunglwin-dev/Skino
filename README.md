# Skin Care AI Platform

Full-stack AI hackathon project for visible skin concern analysis and skincare recommendations.

This project is a wellness/skincare assistant, not a medical diagnosis system.

## Workspace Structure

- `backend-laravel/` - Laravel API, authentication, MySQL data, recommendations, admin APIs
- `mobile-flutter/` - Flutter mobile app for users, camera capture, analysis results, history
- `web-app/` - Vue customer web app, replacing the Flutter-focused user direction
- `admin-vue/` - Vue admin dashboard for products, users, orders, and analytics
- `ai-service-python/` - Python FastAPI AI service, starting with mock responses
- `datasets/` - Local datasets for later training
- `models/` - Saved trained models
- `docs/` - Architecture notes, setup commands, API contracts

## Local Development URLs

- Laravel API: `http://127.0.0.1:8000`
- Vue admin: `http://localhost:5173`
- Vue user web app: `http://localhost:5174`
- Python AI service: `http://127.0.0.1:5000`
- Flutter Android emulator API host: `http://10.0.2.2:8000`

## First MVP Path

1. Start Laravel with auth, products, skin analysis records, and recommendations.
2. Start Python FastAPI with the stable mock AI JSON response.
3. Connect Laravel to the Python AI service.
4. Build Vue user web app login/register, image upload, results, and history screens.
5. Build Vue admin product and analytics screens.
6. Replace mock AI with a trained model later without changing the Laravel contract.
