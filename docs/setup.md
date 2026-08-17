# Setup Guide

Run these commands from `D:\Skin_care_AI_platform`.

## Check Tools

```powershell
git --version
node --version
npm --version
php --version
composer --version
py --version
flutter doctor
```

## Laravel Backend

```powershell
cd backend-laravel
composer install
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve
```

To seed the first admin, set these in `backend-laravel\.env` before running the seed:

```env
ADMIN_SEED_ENABLED=true
ADMIN_SEED_EMAIL=admin@skincare.local
ADMIN_SEED_PASSWORD=StrongAdmin123!
```

Admin seeding creates the account only when it does not already exist. If you intentionally need to update that account from the seeder, also set `ADMIN_SEED_UPDATE_EXISTING=true`.

Useful backend commands:

```powershell
php artisan admin:create --name="Platform Admin" --email=admin@skincare.local --password="StrongAdmin123!"
php artisan auth:prune-tokens
php artisan auth:clear-resets
```

Configure MySQL in `backend-laravel\.env` when XAMPP/MySQL is ready:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=skin_ai_platform
DB_USERNAME=root
DB_PASSWORD=
```

For team sharing later, Docker should provide MySQL with the same database name and credentials in a committed `docker-compose.yml`. For now, the schema is defined entirely in migrations and seeders, so it can move cleanly from SQLite/local setup to Docker MySQL.

## Vue Admin Dashboard

```powershell
cd admin-vue
npm install
npm run dev
```

Run Laravel and Vue together in two terminals:

```powershell
# Terminal 1
cd D:\Skin_care_AI_platform\backend-laravel
php artisan serve --host=127.0.0.1 --port=8000

# Terminal 2
cd D:\Skin_care_AI_platform\admin-vue
npm run dev -- --host 127.0.0.1 --port 5173
```

## Flutter Mobile App

```powershell
cd mobile-flutter
flutter doctor
flutter run
```

## Python AI Service

```powershell
cd ai-service-python
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --host 127.0.0.1 --port 5000 --reload
```
