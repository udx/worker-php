# Use the UDX worker as the base image
FROM usabilitydynamics/udx-worker:0.1.0

# Set the maintainer of the image
LABEL maintainer="UDX"

# Arguments for PHP version
ARG PHP_VERSION=8.3

# Default Environment Variables
ENV PHP_VERSION=${PHP_VERSION} \
    DEBIAN_FRONTEND=noninteractive

# Switch to root user for installation and configuration
USER root

# Install PHP, NGINX, and related dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-zip && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Ensure the correct PHP-FPM socket in NGINX config
RUN sed -i 's|fastcgi_pass unix:/run/php/php.*-fpm.sock|fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock|' /etc/nginx/sites-available/default

# Create necessary directories and set correct permissions
RUN mkdir -p /run/php /var/www/html && \
    chown -R www-data:www-data /run/php /var/www/html && \
    chmod -R 755 /run/php /var/www/html

# Copy custom NGINX configuration
COPY src/configs/nginx/default.conf /etc/nginx/sites-available/default

# Copy the entrypoint script to /usr/local/bin
COPY ./bin/entrypoint.sh /usr/local/bin/entrypoint.sh

# Ensure the entrypoint script is executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set volumes and working directory
VOLUME [ "/var/www", "/home/${USER}" ]
WORKDIR /var/www/html

# Use the entrypoint script
CMD ["/usr/local/bin/entrypoint.sh"]
