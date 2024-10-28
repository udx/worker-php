# Use the UDX worker as the base image
FROM usabilitydynamics/udx-worker:0.1.0

# Set the maintainer of the image
LABEL maintainer="UDX"

# Arguments for PHP and NGINX versions
ARG PHP_VERSION=8.3
ARG PHP_PACKAGE_VERSION=8.3.6-0ubuntu0.24.04.2
ARG NGINX_VERSION=1.24.0-2ubuntu7.1

# Environment variable for PHP version
ENV PHP_VERSION=${PHP_VERSION}

# Switch to root user for installation and configuration
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

# Copy and modify NGINX config
COPY src/configs/nginx/default.conf /etc/nginx/sites-available/default
RUN sed -i "s|\${PHP_VERSION}|${PHP_VERSION}|g" /etc/nginx/sites-available/default

# Ensure PHP-FPM configurations have correct variables
COPY src/configs/php/php-fpm.conf /etc/php/${PHP_VERSION}/fpm/php-fpm.conf
COPY src/configs/php/www.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
RUN sed -i "s|\${USER}|${USER}|g; s|\${PHP_VERSION}|${PHP_VERSION}|g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# Include PHP-FPM pool configuration if not present
RUN grep -q "^include=/etc/php/${PHP_VERSION}/fpm/pool.d/*.conf" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf || \
    echo "include=/etc/php/${PHP_VERSION}/fpm/pool.d/*.conf" >> /etc/php/${PHP_VERSION}/fpm/php-fpm.conf

# Clean any existing `pid` directive and add only one `pid /tmp/nginx.pid;`
RUN sed -i '/pid\s*\/var\/run\/nginx.pid;/d; /pid\s*\/tmp\/nginx.pid;/d' /etc/nginx/nginx.conf && \
    echo "pid /tmp/nginx.pid;" >> /etc/nginx/nginx.conf

# Prepare writable directories for NGINX and PHP-FPM
RUN mkdir -p /var/log/php /var/log/nginx /run/php /tmp /var/lib/nginx/body && \
    touch /var/log/php/fpm.log /tmp/nginx.pid && \
    chown -R ${USER}:${USER} /var/log/php /var/log/nginx /run/php /tmp /var/lib/nginx /var/www/html && \
    chmod -R 755 /var/log/php /var/log/nginx /run/php /tmp /var/lib/nginx /var/www/html

# Verify PHP-FPM configuration syntax
RUN php-fpm${PHP_VERSION} --fpm-config /etc/php/${PHP_VERSION}/fpm/php-fpm.conf -t

# Copy the entrypoint script and set permissions
COPY ./bin/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set volumes and the working directory
VOLUME [ "/var/www", "/home/${USER}" ]
WORKDIR /var/www/html

# Switch to non-root user as per base image configuration
USER ${USER}

# Use the entrypoint script
CMD ["/usr/local/bin/entrypoint.sh"]
