# Use official PHP with Apache
FROM php:8.2-apache

# Set working directory
WORKDIR /var/www/html

# Install dependencies
RUN apt-get update && apt-get install -y \
    git unzip libpng-dev libonig-dev libxml2-dev zip curl \
    sqlite3 libsqlite3-dev \
    && docker-php-ext-install pdo pdo_sqlite mbstring exif pcntl bcmath gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# ✅ Install Node.js (latest LTS) & npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Copy project files
COPY . .

# Enable Apache mod_rewrite & configure virtual host
RUN a2enmod rewrite \
    && rm -rf /var/www/html/index.html \
    && echo '<VirtualHost *:80>
        DocumentRoot /var/www/html/public
        <Directory /var/www/html/public>
            AllowOverride All
            Require all granted
        </Directory>
    </VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Install PHP dependencies
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer install --no-dev --optimize-autoloader

# Install Node dependencies & build Vite
RUN npm install && npm run build

# Expose Laravel public directory
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Run Laravel setup
RUN php artisan storage:link || true

# Run migrations (force to skip confirmation)
RUN php artisan migrate --force || true

# Expose port
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
