# Use the UDX worker as the base image
FROM usabilitydynamics/udx-worker:0.23.0

# Add metadata labels
LABEL maintainer="UDX"
LABEL version="0.22.0"

# Arguments and Environment Variables
ARG PHP_VERSION=8.4
ARG PHP_PACKAGE_VERSION=8.4.5-1ubuntu1.1
ARG NGINX_VERSION=1.26.3-2ubuntu1.1

# Set the PHP_VERSION and PHP_PACKAGE_VERSION as environment variables
ENV PHP_VERSION="${PHP_VERSION}"
ENV PHP_PACKAGE_VERSION="${PHP_PACKAGE_VERSION}"
# Standard directories for PHP application
ENV APP_HOME="/var/www"

# Temporarily switch to root for package installation
USER root

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx="${NGINX_VERSION}" \
    php"${PHP_VERSION}"-fpm="${PHP_PACKAGE_VERSION}" \
    php"${PHP_VERSION}"-cli="${PHP_PACKAGE_VERSION}" \
    php"${PHP_VERSION}"-mysql="${PHP_PACKAGE_VERSION}" \
    php"${PHP_VERSION}"-curl="${PHP_PACKAGE_VERSION}" \
    php"${PHP_VERSION}"-xml="${PHP_PACKAGE_VERSION}" \
    php"${PHP_VERSION}"-zip="${PHP_PACKAGE_VERSION}" \
    mysql-client=8.4.5-0ubuntu0.2 && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/* && \
    mkdir -p /etc/apt/sources.list.d && \
    chmod 755 /etc/apt/sources.list.d && \
    mkdir -p /var/log/php /var/log/nginx /run/php /tmp /var/lib/nginx/body && \
    touch /var/log/php/fpm.log && \
    chown -R "${USER}:${USER}" /var/log/php /var/log/nginx /run/php /tmp /var/lib/nginx $APP_HOME && \
    chmod -R 755 /var/log/php /var/log/nginx /run/php /tmp /var/lib/nginx $APP_HOME

# Copy NGINX and PHP configurations
COPY etc/configs/nginx/nginx.conf /etc/nginx/nginx.conf
COPY etc/configs/nginx/default.conf /etc/nginx/sites-available/default
COPY etc/configs/nginx/snippets/fastcgi-php.conf /etc/nginx/snippets/fastcgi-php"${PHP_VERSION}".conf
COPY etc/configs/php/php-fpm.conf /etc/php/"${PHP_VERSION}"/fpm/php-fpm.conf
COPY etc/configs/php/www.conf /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf

# Update default.conf with PHP socket and configure PHP-FPM with custom settings
RUN sed -i "s|\${PHP_VERSION}|${PHP_VERSION}|g" /etc/nginx/snippets/fastcgi-php"${PHP_VERSION}".conf && \
    sed -i "s|\${PHP_VERSION}|${PHP_VERSION}|g" /etc/nginx/sites-available/default && \
    sed -i "s|\${USER}|${USER}|g; s|\${PHP_VERSION}|${PHP_VERSION}|g" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf && \
    grep -q "^include=/etc/php/${PHP_VERSION}/fpm/pool.d/*.conf" /etc/php/"${PHP_VERSION}"/fpm/php-fpm.conf || \
    echo "include=/etc/php/${PHP_VERSION}/fpm/pool.d/*.conf" >> /etc/php/"${PHP_VERSION}"/fpm/php-fpm.conf

# Set PHP-FPM socket permissions in the configuration
RUN sed -i "s|^error_log =.*|error_log = /var/log/php/fpm.log|" /etc/php/"${PHP_VERSION}"/fpm/php-fpm.conf && \
    sed -i "s|^listen.owner =.*|listen.owner = ${USER}|" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf && \
    sed -i "s|^listen.group =.*|listen.group = ${USER}|" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf && \
    sed -i "s|^listen.mode =.*|listen.mode = 0660|" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf && \
    chown -R "${USER}:${USER}" /var/log/php/fpm.log

# Copy entrypoint script and set permissions
COPY ./bin/start-nginx.sh /usr/local/bin/start-nginx.sh
COPY ./bin/start-php-fpm.sh /usr/local/bin/start-php-fpm.sh
RUN chmod +x /usr/local/bin/start-nginx.sh /usr/local/bin/start-php-fpm.sh

# Copy services configuration to standard worker config directory
COPY etc/configs/worker/services.yaml $HOME/.config/worker/services.yaml

# Revert to non-root user
USER "${USER}"

# Define volumes for both application and worker data
VOLUME [ "$APP_HOME" ]

# Set working directory to standard PHP application location
WORKDIR $APP_HOME

# Keep container running
CMD ["tail", "-f", "/dev/null"]