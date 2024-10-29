# Use the UDX worker as the base image
FROM usabilitydynamics/udx-worker:0.1.0

LABEL maintainer="UDX"

ARG PHP_VERSION=8.3
ARG PHP_PACKAGE_VERSION=8.3.6-0ubuntu0.24.04.2
ARG NGINX_VERSION=1.24.0-2ubuntu7.1

ENV PHP_VERSION=${PHP_VERSION}

USER root

# Install PHP, NGINX, and necessary dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx=${NGINX_VERSION} \
    php${PHP_VERSION}-fpm=${PHP_PACKAGE_VERSION} \
    php${PHP_VERSION}-cli=${PHP_PACKAGE_VERSION} \
    php${PHP_VERSION}-mysql=${PHP_PACKAGE_VERSION} \
    php${PHP_VERSION}-curl=${PHP_PACKAGE_VERSION} \
    php${PHP_VERSION}-xml=${PHP_PACKAGE_VERSION} \
    php${PHP_VERSION}-zip=${PHP_PACKAGE_VERSION} && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Clean all default configurations to avoid conflicts
RUN rm -f /etc/nginx/nginx.conf /etc/nginx/conf.d/* /etc/nginx/sites-enabled/* /etc/nginx/sites-available/*

# Copy in minimal NGINX configuration
COPY src/configs/nginx/nginx.conf /etc/nginx/nginx.conf
COPY src/configs/nginx/default.conf /etc/nginx/sites-available/default

# Update default.conf for PHP socket
RUN sed -i "s|\${PHP_VERSION}|${PHP_VERSION}|g" /etc/nginx/sites-available/default

# Configure PHP-FPM
COPY src/configs/php/php-fpm.conf /etc/php/${PHP_VERSION}/fpm/php-fpm.conf
COPY src/configs/php/www.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
RUN sed -i "s|\${USER}|${USER}|g; s|\${PHP_VERSION}|${PHP_VERSION}|g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# Ensure PHP-FPM includes the pool configuration
RUN grep -q "^include=/etc/php/${PHP_VERSION}/fpm/pool.d/*.conf" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf || \
    echo "include=/etc/php/${PHP_VERSION}/fpm/pool.d/*.conf" >> /etc/php/${PHP_VERSION}/fpm/php-fpm.conf

# Prepare directories with correct permissions
RUN mkdir -p /var/log/php /var/log/nginx /run/php /tmp /var/lib/nginx/body && \
    touch /var/log/php/fpm.log && \
    chown -R ${USER}:${USER} /var/log/php /var/log/nginx /run/php /tmp /var/lib/nginx /var/www/html && \
    chmod -R 755 /var/log/php /var/log/nginx /run/php /tmp /var/lib/nginx /var/www/html

# Verify PHP-FPM configuration syntax
RUN php-fpm${PHP_VERSION} --fpm-config /etc/php/${PHP_VERSION}/fpm/php-fpm.conf -t

# Copy entrypoint script
COPY ./bin/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy default index.html to serve as the main page
COPY src/index.html /var/www/html/index.html

# Set volumes and the working directory
VOLUME [ "/var/www", "/home/${USER}" ]
WORKDIR /var/www/html

# Switch to non-root user as per base image configuration
USER ${USER}

# Use the entrypoint script
CMD ["/usr/local/bin/entrypoint.sh"]
