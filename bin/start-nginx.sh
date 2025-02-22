#!/bin/bash
set -e

# Default configuration - read from nginx.conf if possible
NGINX_CONFIG_DIR=${NGINX_CONFIG_DIR:-"/etc/nginx"}
NGINX_CONFIG_FILE="${NGINX_CONFIG_DIR}/nginx.conf"

# Try to extract log paths from nginx.conf
if [ -f "${NGINX_CONFIG_FILE}" ]; then
    NGINX_ACCESS_LOG=$(grep -oP 'access_log\s+\K[^;]+' "${NGINX_CONFIG_FILE}" | tr -d ' ' || echo "/var/log/nginx/access.log")
    NGINX_ERROR_LOG=$(grep -oP 'error_log\s+\K[^;]+' "${NGINX_CONFIG_FILE}" | tr -d ' ' || echo "/var/log/nginx/error.log")
    NGINX_PID_FILE=$(grep -oP 'pid\s+\K[^;]+' "${NGINX_CONFIG_FILE}" | tr -d ' ' || echo "/tmp/nginx.pid")
else
    NGINX_ACCESS_LOG="/var/log/nginx/access.log"
    NGINX_ERROR_LOG="/var/log/nginx/error.log"
    NGINX_PID_FILE="/tmp/nginx.pid"
fi

# Ensure log directory exists (usually already exists in container)
LOG_DIR=$(dirname "${NGINX_ACCESS_LOG}")
if [ ! -d "${LOG_DIR}" ]; then
    mkdir -p "${LOG_DIR}" 2>/dev/null || true
    touch "${NGINX_ACCESS_LOG}" "${NGINX_ERROR_LOG}" 2>/dev/null || true
fi

# Trap termination signals for graceful shutdown
trap 'echo "ℹ️ Service: Shutting down NGINX..."; exit 0;' SIGTERM SIGINT

# Clean up any old PID files
echo " * Cleaning up old process files..."
rm -f "${NGINX_PID_FILE}" 2>/dev/null || true

# Test NGINX configuration
echo "ℹ️ Service: Testing NGINX configuration..."
if ! nginx -t 2>/dev/null; then
    echo "❌ Service: NGINX configuration test failed"
    nginx -t
    exit 1
fi

# Start NGINX and monitor its status
echo " * Starting NGINX..."
nginx -g "daemon off;" &
NGINX_PID=$!

# Wait for NGINX to be ready
sleep 1
if ! kill -0 $NGINX_PID 2>/dev/null; then
    echo "❌ Service: NGINX failed to start"
    exit 1
fi

# Log successful start with PID and paths
echo "✅ Service: NGINX is running"
echo "   PID             $NGINX_PID"
echo "   Started at      $(date '+%Y-%m-%d %H:%M:%S')"
echo "
ℹ️ Service: Important paths:"
echo "   Config file     ${NGINX_CONFIG_FILE}"
echo "   PID file        ${NGINX_PID_FILE}"
echo "   Access log      ${NGINX_ACCESS_LOG}"
echo "   Error log       ${NGINX_ERROR_LOG}"

# Wait for the NGINX process
wait $NGINX_PID