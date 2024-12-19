# Use the UDX worker as the base image
FROM usabilitydynamics/udx-worker:0.2.0

LABEL maintainer="UDX"

# Arguments and Environment Variables
ARG PHP_VERSION=8.3
ARG PHP_PACKAGE_VERSION=8.3.6-0ubuntu0.24.04.3
ARG NGINX_VERSION=1.24.0-2ubuntu7.1

ENV PHP_VERSION="${PHP_VERSION}"

# Temporarily switch to root for package installation
USER root

# Install NGINX, PHP, clean up, and set up directories and permissions in one step
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx="${NGINX_VERSION}" \
    php"${PHP_VERSION}"-fpm="${PHP_PACKAGE_VERSION}" \
    php"${PHP_VERSION}"-cli="${PHP_PACKAGE_VERSION}" \
    php"${PHP_VERSION}"-mysql="${PHP_PACKAGE_VERSION}" \
    php"${PHP_VERSION}"-curl="${PHP_PACKAGE_VERSION}" \
    php"${PHP_VERSION}"-xml="${PHP_PACKAGE_VERSION}" \
    php"${PHP_VERSION}"-zip="${PHP_PACKAGE_VERSION}" && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    mkdir -p /var/log/php /var/log/nginx /run/php /tmp /var/lib/nginx/body && \
    touch /var/log/php/fpm.log && \
    chown -R "${USER}:${USER}" /var/log/php /var/log/nginx /run/php /tmp /var/lib/nginx /var/www/html && \
    chmod -R 755 /var/log/php /var/log/nginx /run/php /tmp /var/lib/nginx /var/www/html

# Copy configurations and set permissions
COPY src/configs/nginx/nginx.conf /etc/nginx/nginx.conf
COPY src/configs/nginx/default.conf /etc/nginx/sites-available/default
COPY src/index.html /var/www/html/index.html
RUN chmod 644 /var/www/html/index.html

# Update default.conf with PHP socket and configure PHP-FPM with custom settings
RUN sed -i "s|\${PHP_VERSION}|${PHP_VERSION}|g" /etc/nginx/sites-available/default && \
    sed -i "s|\${USER}|${USER}|g; s|\${PHP_VERSION}|${PHP_VERSION}|g" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf && \
    grep -q "^include=/etc/php/${PHP_VERSION}/fpm/pool.d/*.conf" /etc/php/"${PHP_VERSION}"/fpm/php-fpm.conf || \
    echo "include=/etc/php/${PHP_VERSION}/fpm/pool.d/*.conf" >> /etc/php/"${PHP_VERSION}"/fpm/php-fpm.conf

# Set PHP-FPM socket permissions in the configuration
RUN sed -i "s|^error_log =.*|error_log = /var/log/php/fpm.log|" /etc/php/"${PHP_VERSION}"/fpm/php-fpm.conf && \
    sed -i "s|^listen.owner =.*|listen.owner = ${USER}|" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf && \
    sed -i "s|^listen.group =.*|listen.group = ${USER}|" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf && \
    sed -i "s|^listen.mode =.*|listen.mode = 0660|" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf && \
    chown -R "${USER}:${USER}" /var/log/php/fpm.log

# Validate PHP-FPM configuration syntax
RUN php-fpm"${PHP_VERSION}" --fpm-config /etc/php/"${PHP_VERSION}"/fpm/php-fpm.conf -t

# Copy entrypoint script and set permissions
COPY ./bin/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Revert to non-root user
USER "${USER}"

# Set volumes, working directory, and default command
VOLUME [ "/var/www", "/home/${USER}" ]
WORKDIR /var/www/html
CMD ["/usr/local/bin/entrypoint.sh"]
