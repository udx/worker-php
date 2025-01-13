#!/bin/bash
set -e

# Trap termination signals for graceful shutdown
trap 'echo "Received termination signal, shutting down..."; exit 0;' SIGTERM SIGINT

# Clean up any old PID files
echo " * Cleaning up old PID files..."
rm -f /tmp/nginx.pid

# Start NGINX in the foreground
echo " * Starting NGINX..."
nginx -g "daemon off;"