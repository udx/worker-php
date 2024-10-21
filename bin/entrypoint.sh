#!/bin/bash
############################################################
## UDX Docker Site Entrypoint Script
############################################################

set -e  # Exit immediately if a command exits with a non-zero status

# Clean up old PID files
rm -f /var/run/{memcached.pid,nginx.pid}
[ -d /var/run/php ] && rm -f /var/run/php/php*.pid

# Set environment variables if not set
[[ -z "$CI_RABBIT_NAME" && -n "$HOSTNAME" ]] && export CI_RABBIT_NAME="${HOSTNAME:-default_rabbit_name}"
[[ -z "$CI_RABBIT_DOMAIN" && -n "$CI_RABBIT_ID" ]] && export CI_RABBIT_DOMAIN="${CI_RABBIT_ID:-default_rabbit_domain}"
[[ -z "$NEW_RELIC_APP_NAME" && -n "$CI_RABBIT_ID" ]] && export NEW_RELIC_APP_NAME="${CI_RABBIT_ID:-default_app_name}"

echo " * Starting UDX site version [${DOCKER_IMAGE_VERSION}]."

# Check if a Git repository and token are provided
if [[ -z "$GIT_REPO_URL" || -z "$GIT_TOKEN" ]]; then
    echo "No Git repository or token provided. Skipping code pull."
else
    echo "Cloning repository from $GIT_REPO_URL."
    git clone https://"$GIT_TOKEN"@"$GIT_REPO_URL" /var/www/html || {
        echo "Git clone failed"
        exit 1
    }
fi

# Start NGINX with default configuration
echo " * Starting NGINX with default configuration."
nginx -g 'daemon off;' &

# Start PM2 Daemon
echo " * Starting PM2 Daemon."
pm2 startOrReload ${PROCESS_FILE:-default_process.json} --only daemon --silent --no-vizion || {
    echo "Error: PM2 failed to start."
    exit 1
}

# Command pass-through to allow further execution
exec "$@"
