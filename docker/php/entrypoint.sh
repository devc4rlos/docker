#!/bin/sh

echo "Sincronizando código da aplicação para o volume..."
rsync -a --delete --chown=www-data:www-data /app_source/ /var/www/

cd /var/www

echo "Limpando caches antigos..."
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "Gerando cache de configuração para produção..."
php artisan config:cache

echo "Rodando migrações do banco de dados..."
php artisan migrate --force

echo "Iniciando PHP-FPM..."
exec "$@"
