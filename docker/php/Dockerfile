FROM php:8.2-apache

# Suppress Apache warning about ServerName
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Create default VirtualHost
COPY "./docker/php/vhost.conf" "/etc/apache2/sites-enabled/000-default.conf"

# Override some php.ini configuration for our needs
COPY "./docker/php/php.ini" "/usr/local/etc/php/conf.d/php-overrides.ini"

# Install tool to manage PHP extensions as official Docker images
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Install symfony-cli
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash; \
    apt install -y symfony-cli;

# Install required dependencies
RUN chmod +x /usr/local/bin/install-php-extensions; \
  install-php-extensions intl zip pgsql pdo_pgsql @composer;

# Enable mod_rewrite module for Apache (not enabled by default)
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html/
