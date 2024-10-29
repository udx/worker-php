#!/bin/bash
set -e

# Graceful shutdown handling
trap 'echo "Received termination signal, shutting down..."; nginx -s stop; php-fpm${PHP_VERSION} --fpm-config /etc/php/${PHP_VERSION}/fpm/php-fpm.conf --stop; exit 0;' SIGTERM SIGINT

# Clean up old PID files
echo " * Cleaning up old PID files..."
rm -f /tmp/nginx.pid /run/php/php*.pid

# Verifying PHP-FPM pool configuration
echo "Verifying PHP-FPM pool configuration..."
cat /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# Start PHP-FPM and check if it started correctly
echo " * Starting PHP-FPM..."
if php-fpm${PHP_VERSION} --fpm-config /etc/php/${PHP_VERSION}/fpm/php-fpm.conf; then
    echo " * PHP-FPM started."
else
    echo "Error: PHP-FPM failed to start."
    exit 1
fi

# Start NGINX with an explicit PID file path
echo " * Starting NGINX..."
nginx -g "pid /tmp/nginx.pid; daemon off;" &
wait "$!"
