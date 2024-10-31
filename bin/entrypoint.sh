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

# Start PHP-FPM in the background and check if it starts correctly
echo " * Starting PHP-FPM..."
php-fpm"${PHP_VERSION}" --fpm-config /etc/php/"${PHP_VERSION}"/fpm/php-fpm.conf &

# Wait for PHP-FPM to be ready
sleep 2
if ! pgrep -x "php-fpm${PHP_VERSION}" > /dev/null; then
    echo "Error: PHP-FPM failed to start."
    exit 1
fi
echo " * PHP-FPM started successfully."

# Start NGINX in the foreground
echo " * Starting NGINX..."
nginx -g "daemon off;"
