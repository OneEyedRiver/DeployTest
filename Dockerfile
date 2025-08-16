### Step 1: Node.js for frontend (Vite)
FROM node:18 AS node-builder

WORKDIR /app
COPY . .

RUN npm install && npm run build


### Step 2: PHP for Laravel backend
FROM php:8.2-fpm

WORKDIR /var/www

RUN apt-get update && apt-get install -y \
    zip unzip curl git libxml2-dev libzip-dev libpng-dev libjpeg-dev libonig-dev \
    sqlite3 libsqlite3-dev \
    && docker-php-ext-install pdo pdo_sqlite mbstring exif pcntl bcmath gd zip \
    && rm -rf /var/lib/apt/lists/*

# Copy composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy app files
COPY --chown=www-data:www-data . /var/www

# Copy only built frontend assets (from Vite)
COPY --from=node-builder /app/public/build /var/www/public/build

# Ensure database file exists
RUN mkdir -p /var/www/database \
    && touch /var/www/database/database.sqlite \
    && chown -R www-data:www-data /var/www/database

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Copy env before artisan commands
COPY .env.example .env

# Generate app key
RUN php artisan key:generate

# Clear caches (make sure .env takes effect)
RUN php artisan config:clear && php artisan cache:clear

EXPOSE 8000

# Run migrations (force) then start server
CMD php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=8000
