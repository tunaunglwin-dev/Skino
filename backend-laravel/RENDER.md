# Render deployment

Create a Render **Web Service** from this repository with the following settings:

- Branch: `master`
- Root directory: `backend-laravel`
- Runtime: `Docker`
- Health check path: `/up`
- Region: the same region as PostgreSQL and the Python AI service

Required environment variables:

```dotenv
APP_NAME=Skino
APP_ENV=production
APP_DEBUG=false
APP_URL=https://YOUR-LARAVEL-SERVICE.onrender.com
APP_KEY=base64:GENERATE_A_REAL_KEY
LOG_CHANNEL=stderr
LOG_LEVEL=info
DB_CONNECTION=pgsql
DB_URL=YOUR_RENDER_INTERNAL_DATABASE_URL
SESSION_DRIVER=file
CACHE_STORE=file
QUEUE_CONNECTION=sync
SKIN_AI_SERVICE_URL=https://YOUR-AI-SERVICE.onrender.com
SKIN_AI_SERVICE_TIMEOUT=90
GOOGLE_CLIENT_ID=YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com
CORS_ALLOWED_ORIGINS=https://skino-coral.vercel.app
ADMIN_FRONTEND_URL=https://skino-coral.vercel.app
GEMINI_DEMO_FALLBACK=true
```

Generate `APP_KEY` locally with:

```shell
php artisan key:generate --show
```

The container caches configuration and views, runs `php artisan migrate --force`, and then starts PHP-FPM and Nginx on Render's `PORT`.
