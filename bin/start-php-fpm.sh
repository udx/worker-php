#!/bin/bash
set -e

# Default configuration
PHP_VERSION=${PHP_VERSION:-"8.3"}
PHP_CONFIG_DIR=${PHP_CONFIG_DIR:-"/etc/php/${PHP_VERSION}"}

# Read paths from config files
PHP_FPM_CONFIG="${PHP_CONFIG_DIR}/fpm/php-fpm.conf"
PHP_POOL_CONFIG="${PHP_CONFIG_DIR}/fpm/pool.d/www.conf"

# Extract paths from configs
if [ -f "${PHP_FPM_CONFIG}" ]; then
    PHP_ERROR_LOG=$(grep -oP 'error_log\s*=\s*\K[^\n]+' "${PHP_FPM_CONFIG}" | tr -d ' ' || echo "/var/log/php/fpm.log")
else
    PHP_ERROR_LOG="/var/log/php/fpm.log"
fi

if [ -f "${PHP_POOL_CONFIG}" ]; then
    PHP_SOCKET_FILE=$(grep -oP 'listen\s*=\s*\K[^\n]+' "${PHP_POOL_CONFIG}" | tr -d ' ' || echo "/run/php/php${PHP_VERSION}-fpm.sock")
else
    PHP_SOCKET_FILE="/run/php/php${PHP_VERSION}-fpm.sock"
fi

# Derive PID file path
PHP_PID_FILE="/run/php/php${PHP_VERSION}-fpm.pid"

# Trap termination signals for graceful shutdown
trap 'echo "ℹ️ Service: Shutting down PHP-FPM..."; kill $(jobs -p); wait; exit 0;' SIGTERM SIGINT

# Clean up any old process files
echo " * Cleaning up old process files..."
rm -f "${PHP_PID_FILE}" "${PHP_SOCKET_FILE}" 2>/dev/null || true

# Display current configuration
echo "ℹ️ Service: Current PHP-FPM configuration:"
echo "   NAME            VALUE"
echo "   ----            -----"
if [ -f "${PHP_POOL_CONFIG}" ]; then
    # First line is [www], handle it separately
    echo "   [www]           "
    # Rest of the configuration
    grep -v '^;' "${PHP_POOL_CONFIG}" | grep -v '^$' | grep -v '\[www\]' | while IFS='=' read -r key value; do
        if [ -n "$key" ]; then
            printf "   %-15s %s\n" "${key// /}" "${value// /}"
        fi
    done
else
    echo "❌ Service: Pool configuration not found at ${PHP_POOL_CONFIG}"
    exit 1
fi

# Show important paths
echo "
ℹ️ Service: Important paths:"
echo "   Config file     ${PHP_FPM_CONFIG}"
echo "   Pool config     ${PHP_POOL_CONFIG}"
echo "   Socket         ${PHP_SOCKET_FILE}"
echo "   Error log      ${PHP_ERROR_LOG}"

# Start PHP-FPM
echo " * Starting PHP-FPM..."
exec php-fpm"${PHP_VERSION}" --nodaemonize --fpm-config "${PHP_FPM_CONFIG}"