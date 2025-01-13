#!/bin/bash
set -e

# Trap termination signals for graceful shutdown
trap 'echo "Received termination signal, shutting down..."; kill $(jobs -p); wait; exit 0;' SIGTERM SIGINT

# Clean up any old PID files and the socket file
echo " * Cleaning up old PID files and the socket file..."
rm -f /run/php/php*.pid /run/php/php"${PHP_VERSION}"-fpm.sock || true

# Verifying PHP-FPM pool configuration
echo "Verifying PHP-FPM pool configuration..."
cat /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf

# Start PHP-FPM in the foreground and check if it starts correctly
echo " * Starting PHP-FPM..."
php-fpm"${PHP_VERSION}" --nodaemonize --fpm-config /etc/php/"${PHP_VERSION}"/fpm/php-fpm.conf

# Wait for PHP-FPM to be ready
sleep 2
if ! pgrep -x "php-fpm${PHP_VERSION}" > /dev/null; then
    echo "Error: PHP-FPM failed to start."
    exit 1
else
    echo " * PHP-FPM started successfully."
fi