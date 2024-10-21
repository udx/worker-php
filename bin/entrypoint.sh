#!/bin/bash
############################################################
## UDX Docker Site Entrypoint Script
############################################################

set -e  # Exit immediately if a command exits with a non-zero status

# Clean up old pid files
rm -f /var/run/{memcached.pid,nginx.pid}
[ -d /var/run/php ] && rm -f /var/run/php/php*.pid

# Set environment variables if not set
[[ -z "$CI_RABBIT_NAME" && -n "$HOSTNAME" ]] && export CI_RABBIT_NAME="${HOSTNAME:-default_rabbit_name}"
[[ -z "$CI_RABBIT_DOMAIN" && -n "$CI_RABBIT_ID" ]] && export CI_RABBIT_DOMAIN="${CI_RABBIT_ID:-default_rabbit_domain}"
[[ -z "$NEW_RELIC_APP_NAME" && -n "$CI_RABBIT_ID" ]] && export NEW_RELIC_APP_NAME="${CI_RABBIT_ID:-default_app_name}"

echo " * Starting wpcloud/site version [${DOCKER_IMAGE_VERSION}]."

# Start NGINX with default configuration
echo " * Starting NGINX with default configuration."
if ! nginx -g 'daemon off;' &; then
    echo "Error: NGINX failed to start."
    exit 1
else
    echo "NGINX started successfully."
fi

# Start PM2 Daemon
echo " * Starting PM2 Daemon."
if ! pm2 startOrReload ${PROCESS_FILE} --only daemon --silent --no-vizion > /var/log/pm2.log 2>&1; then
    echo "Error: PM2 failed to start."
    exit 1
else
    echo "PM2 started successfully."
fi

# Command pass-through to allow further execution
exec "$@"
