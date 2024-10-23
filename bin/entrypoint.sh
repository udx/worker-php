#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Graceful shutdown handling
trap 'echo "Received termination signal, shutting down..."; exit 0;' SIGTERM SIGINT

# Clean up old PID files
echo " * Cleaning up old PID files..."
rm -f /var/run/nginx.pid /run/php/php*.pid

echo " * Starting UDX site version [${DOCKER_IMAGE_VERSION}]."

# Start PHP-FPM and check if it started correctly
echo " * Starting PHP-FPM..."
if service php"${PHP_VERSION}"-fpm start; then
    echo " * PHP-FPM started."
else
    echo "Error: PHP-FPM failed to start."
    service php"${PHP_VERSION}"-fpm status
    exit 1
fi

# Wait a moment to ensure PHP-FPM initializes
sleep 3

# Check if PHP-FPM socket exists
if [ ! -S /run/php/php"${PHP_VERSION}"-fpm.sock ]; then
    echo "Error: No PHP-FPM socket found at /run/php/php${PHP_VERSION}-fpm.sock."
    service php"${PHP_VERSION}"-fpm status  # Output the status of PHP-FPM for debugging
    # Check PHP-FPM logs
    tail -n 50 /var/log/php"${PHP_VERSION}"-fpm.log
    exit 1
fi

echo " * PHP-FPM socket found at /run/php/php${PHP_VERSION}-fpm.sock."

# Start NGINX
echo " * Starting NGINX..."
nginx -g 'daemon off;' &
wait "$!"
