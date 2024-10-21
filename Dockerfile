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

# Copy application code to /var/www/html
COPY ./src/ /var/www/html/

# Copy the entrypoint script to /usr/local/bin
COPY ./bin/wpcloud.site.entrypoint.sh /usr/local/bin/wpcloud.site.entrypoint.sh

# Ensure the entrypoint script is executable
RUN chmod +x /usr/local/bin/wpcloud.site.entrypoint.sh

# Set ownership and permissions for the web application directory
RUN chown -R www-data:www-data /var/www/html

# Set volumes and working directory
VOLUME [ "/var/www", "/home/${USER}" ]
WORKDIR /var/www/html

# Use the entrypoint script
CMD ["/usr/local/bin/wpcloud.site.entrypoint.sh"]
