FROM php:8.4-fpm AS builder

WORKDIR /var/www

RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    nodejs \
    npm \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY . .

RUN composer install --no-interaction --prefer-dist --optimize-autoloader

RUN npm ci

RUN npm run build

FROM php:8.4-fpm-alpine

WORKDIR /var/www

COPY docker/php/prod.ini /usr/local/etc/php/conf.d/99-prod.ini

RUN apk add --no-cache --update \
    $PHPIZE_DEPS \
    libzip-dev \
    oniguruma-dev \
    libexif-dev \
    libpng-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath zip gd \
    && apk del $PHPIZE_DEPS

COPY --from=builder /var/www .

RUN mkdir -p storage/framework/{sessions,views,cache/data} && \
    mkdir -p storage/app/public && \
    mkdir -p storage/logs \

RUN chown -R www-data:www-data storage bootstrap/cache public

RUN find /var/www/storage -type f -exec chmod 664 {};
RUN find /var/www/storage -type d -exec chmod 775 {};

RUN find /var/www/bootstrap/cache -type f -exec chmod 664 {};
RUN find /var/www/bootstrap/cache -type d -exec chmod 775 {};

EXPOSE 9000

CMD ["php-fpm"]
