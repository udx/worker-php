#!/bin/bash
set -e

# Trap termination signals for graceful shutdown
trap 'echo "Received termination signal, shutting down..."; exit 0;' SIGTERM SIGINT

# Clean up any old PID files
echo " * Cleaning up old PID files..."
rm -f /tmp/nginx.pid /run/php/php*.pid || true

# Verifying PHP-FPM pool configuration
echo "Verifying PHP-FPM pool configuration..."
cat /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf

# Start PHP-FPM and check if it starts correctly
echo " * Starting PHP-FPM..."
if php-fpm"${PHP_VERSION}" --fpm-config /etc/php/"${PHP_VERSION}"/fpm/php-fpm.conf; then
    echo " * PHP-FPM started."
else
    echo "Error: PHP-FPM failed to start."
    exit 1
fi

# Start NGINX in the foreground (without pid directive)
echo " * Starting NGINX..."
nginx -g "daemon off;"
