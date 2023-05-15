FROM php:8.1.0-apache
WORKDIR /var/www/html

# Copy the Laravel application files to the container
COPY ./laravel-app /var/www/html
# Mod Rewrite
RUN a2enmod rewrite

# Linux Library
RUN apt-get update -y && apt-get install -y \
    libicu-dev \
    libmariadb-dev \
    unzip zip \
    zlib1g-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev

# Install Node.js and npm
RUN apt-get update \
    && apt-get install -y curl \
    && curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs

# Install NPM dependencies
WORKDIR /var/www/html/laravel-app
RUN npm install \
    && npm run dev

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# PHP Extension
RUN docker-php-ext-install gettext intl pdo_mysql gd \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && a2enmod rewrite

RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# Set the Apache document root \
RUN sed -i 's|/var/www/html/public|/var/www/html/laravel-app/public|' /etc/apache2/sites-available/000-default.conf

# Start Apache in the foreground when the container starts
CMD ["apache2-foreground"]