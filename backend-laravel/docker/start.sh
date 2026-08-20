#!/bin/sh
set -eu

cd /var/www/html

render_port="${PORT:-10000}"
sed -i "s/__PORT__/${render_port}/g" /etc/nginx/http.d/default.conf

mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

php artisan config:cache
php artisan view:cache
php artisan migrate --force

exec /usr/bin/supervisord -c /etc/supervisord.conf
