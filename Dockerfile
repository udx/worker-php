# Set the base image (UDX Worker)
FROM udx-worker/udx-worker:latest

# Set the maintainer of the image
LABEL maintainer="UDX"

# Arguments
ARG NODE_MAJOR=20
ARG PHP_VERSION=8.3

# Default Environment Variables
ENV PHP_VERSIONS_AVAILABLE="8.1 8.2 8.3" \
    PHP_VERSION=${PHP_VERSION}

# Install PHP, Node.js, NGINX, and related dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    git \
    build-essential \
    libssl-dev \
    memcached \
    mariadb-server \
    nginx \
    inotify-tools \
    htop \
    mc \
    libxml2-dev \
    libxslt1-dev \
    libpcre3-dev \
    libcurl4-openssl-dev \
    zlib1g-dev && \
    add-apt-repository ppa:ondrej/php && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-memcached \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-zip && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g pm2 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy ecosystem.config.js to /usr/lib
COPY ./etc/home/ecosystem.config.js /usr/lib/ecosystem.config.js

# Create necessary directories and set permissions
RUN mkdir -p /var/run/wpcloud.site /var/log/wpcloud.site/nginx/logs && \
    chown -R root:root /var/run/wpcloud.site /var/log/wpcloud.site/nginx/logs

# Set volumes and working directory
VOLUME [ "/var/www", "/home/${USER}" ]
WORKDIR /var/www

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost || exit 1

# Switch to non-root user after privileged tasks
USER ${USER}

# Use the entrypoint script from the base image
CMD ["/bin/bash", "/opt/sources/wpCloud/docker-site/bin/wpcloud.site.entrypoint.sh"]
