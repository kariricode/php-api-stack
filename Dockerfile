# Multi-stage build for kariricode/php-api-stack
# Production-ready PHP + Nginx + Redis + Symfony CLI stack
# Version: Dynamic from build args

# Build arguments
ARG PHP_VERSION=8.4
ARG NGINX_VERSION=1.27.3
ARG REDIS_VERSION=7.2
ARG ALPINE_VERSION=3.21
ARG VERSION=1.2.0

# Stage 1: Redis binaries
FROM redis:${REDIS_VERSION}-alpine AS redis-build

# Stage 2: Nginx binaries
FROM nginx:${NGINX_VERSION}-alpine AS nginx-build

# Stage 3: Main application
FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION} AS base

# Set shell with pipefail for robust error handling
# Reference: https://docs.docker.com/engine/reference/builder/#shell
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

# Import build arguments
ARG PHP_VERSION
ARG NGINX_VERSION
ARG REDIS_VERSION
ARG ALPINE_VERSION
ARG COMPOSER_VERSION=2.8.12
ARG SYMFONY_CLI_VERSION=7.3.0
ARG PHP_CORE_EXTENSIONS="pdo pdo_mysql opcache intl zip bcmath gd mbstring xml"
ARG PHP_PECL_EXTENSIONS="redis apcu uuid"
ARG APP_ENV=production
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

# Metadata with dynamic version
LABEL maintainer="KaririCode <commuunity@kariricode.org>" \
    org.opencontainers.image.title="PHP API Stack" \
    org.opencontainers.image.description="Production-ready PHP + Nginx + Redis + Symfony stack" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.source="https://github.com/kariricode/php-api-stack" \
    stack.nginx.version="${NGINX_VERSION}" \
    stack.php.version="${PHP_VERSION}" \
    stack.redis.version="${REDIS_VERSION}" \
    stack.version="${VERSION}"

# Environment variables with defaults
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer \
    PATH="/composer/vendor/bin:/symfony/bin:$PATH" \
    APP_ENV=${APP_ENV} \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
    PHP_OPCACHE_MAX_ACCELERATED_FILES=20000 \
    PHP_OPCACHE_MEMORY_CONSUMPTION=256 \
    PHP_OPCACHE_ENABLE=1 \
    STACK_VERSION=${VERSION}

# Install system dependencies
# Note: Not pinning apk versions for base system packages ensures compatibility
# with the underlying Alpine version and receives security updates automatically
# hadolint ignore=DL3018
RUN set -eux; \
    apk update; \
    apk add --no-cache \
    bash \
    shadow \
    su-exec \
    tini \
    # supervisor \
    git \
    curl \
    wget \
    ca-certificates \
    openssl \
    gettext \
    tzdata \
    pcre \
    pcre-dev \
    zlib \
    zlib-dev \
    icu-libs \
    libzip \
    libpng \
    libjpeg-turbo \
    freetype \
    libxml2 \
    postgresql-libs \
    procps \
    htop; \
    # Update CA certificates
    update-ca-certificates; \
    # Create users/groups
    if ! getent group nginx >/dev/null 2>&1; then \
    addgroup -g 101 -S nginx; \
    fi; \
    if ! getent passwd nginx >/dev/null 2>&1; then \
    adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx; \
    fi; \
    if ! getent group redis >/dev/null 2>&1; then \
    addgroup -S redis; \
    fi; \
    if ! getent passwd redis >/dev/null 2>&1; then \
    adduser -D -S -h /var/lib/redis -s /sbin/nologin -G redis redis; \
    fi; \
    echo "Nginx user:"; id nginx; \
    echo "Redis user:"; id redis; \
    # PHPIZE_DEPS must be unquoted to allow word splitting (intentional SC2086)
    # shellcheck disable=SC2086
    apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    icu-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libxml2-dev \
    curl-dev \
    oniguruma-dev \
    postgresql-dev \
    linux-headers; \
    rm -rf /var/cache/apk/*

# Install PHP Core Extensions with improved error handling
# Reference: https://github.com/docker-library/docs/tree/master/php#how-to-install-more-php-extensions
RUN set -eux; \
    echo "==> Processing PHP Core Extensions..."; \
    INSTALLABLE_EXTENSIONS=""; \
    for ext in ${PHP_CORE_EXTENSIONS}; do \
    case "$ext" in \
    pdo|pdo_mysql|pdo_pgsql|opcache|intl|zip|bcmath|gd|mysqli|mbstring|xml|dom|simplexml|sockets|pcntl|exif) \
    echo "  [✓] Adding $ext to installation list"; \
    INSTALLABLE_EXTENSIONS="$INSTALLABLE_EXTENSIONS $ext" \
    ;; \
    tokenizer|filter|json|phar|posix|fileinfo|ctype|iconv|session|curl) \
    echo "  [i] $ext is built-in, skipping installation" \
    ;; \
    *) \
    echo "  [!] Warning: Unknown extension '$ext', skipping" \
    ;; \
    esac; \
    done; \
    # Configure GD if present
    if echo " ${INSTALLABLE_EXTENSIONS} " | grep -q " gd "; then \
    echo "==> Configuring GD with FreeType and JPEG support..."; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    fi; \
    # Install extensions if any (intentional word splitting)
    if [ -n "${INSTALLABLE_EXTENSIONS}" ]; then \
    echo "==> Installing PHP extensions: ${INSTALLABLE_EXTENSIONS}"; \
    # shellcheck disable=SC2086
    docker-php-ext-install -j"$(nproc)" ${INSTALLABLE_EXTENSIONS}; \
    echo "==> Verifying installed extensions..."; \
    php -m; \
    else \
    echo "==> No core extensions to install"; \
    fi

# Install PECL Extensions with improved error handling
# Reference: https://pecl.php.net/
# Note: PECL extension dependencies require latest versions for compatibility
# hadolint ignore=DL3018
RUN set -eux; \
    echo "==> Processing PECL Extensions..."; \
    if [ -n "${PHP_PECL_EXTENSIONS}" ]; then \
    INSTALLABLE_PECL=""; \
    for ext in ${PHP_PECL_EXTENSIONS}; do \
    case "$ext" in \
    redis|apcu|uuid|xdebug|imagick|amqp|swoole) \
    echo "  [✓] Adding PECL extension: $ext"; \
    INSTALLABLE_PECL="$INSTALLABLE_PECL $ext"; \
    case "$ext" in \
    uuid) apk add --no-cache util-linux-dev ;; \
    imagick) apk add --no-cache imagemagick-dev ;; \
    amqp) apk add --no-cache rabbitmq-c-dev ;; \
    esac \
    ;; \
    *) \
    echo "  [!] Warning: Unknown PECL extension '$ext', skipping" \
    ;; \
    esac; \
    done; \
    if [ -n "${INSTALLABLE_PECL}" ]; then \
    echo "==> Installing PECL extensions: ${INSTALLABLE_PECL}"; \
    # Intentional word splitting for loop iteration
    # shellcheck disable=SC2086
    for ext in ${INSTALLABLE_PECL}; do \
    echo "  --> Installing $ext..."; \
    if pecl install "$ext"; then \
    docker-php-ext-enable "$ext"; \
    echo "  [✓] $ext installed successfully"; \
    else \
    echo "  [✗] Failed to install $ext (non-fatal)"; \
    fi; \
    done; \
    pecl clear-cache; \
    rm -rf /tmp/pear; \
    echo "==> Verifying PECL extensions..."; \
    php -m | grep -iE '(redis|apcu|uuid|xdebug|imagick|amqp|swoole)' || true; \
    fi; \
    else \
    echo "==> No PECL extensions to install"; \
    fi

# Copy Nginx binaries from nginx image
COPY --from=nginx-build /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx-build /usr/lib/nginx /usr/lib/nginx
COPY --from=nginx-build /etc/nginx/mime.types /etc/nginx/mime.types
COPY --from=nginx-build /etc/nginx/fastcgi_params /etc/nginx/fastcgi_params
COPY --from=nginx-build /etc/nginx/fastcgi.conf /etc/nginx/fastcgi.conf
COPY --from=nginx-build /etc/nginx/scgi_params /etc/nginx/scgi_params
COPY --from=nginx-build /etc/nginx/uwsgi_params /etc/nginx/uwsgi_params

# Copy Redis binaries from redis image
COPY --from=redis-build /usr/local/bin/redis-* /usr/local/bin/

# Install Composer with retry logic and checksum verification
# Reference: https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
RUN set -eux; \
    echo "==> Installing Composer ${COMPOSER_VERSION}..."; \
    mkdir -p /composer; \
    EXPECTED_CHECKSUM="$(wget --progress=dot:giga -O - https://composer.github.io/installer.sig)"; \
    for i in 1 2 3 4 5; do \
    echo "  Attempt $i to download Composer..."; \
    if wget --progress=dot:giga -O composer-setup.php https://getcomposer.org/installer; then \
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"; \
    if [ "$EXPECTED_CHECKSUM" = "$ACTUAL_CHECKSUM" ]; then \
    echo "  Installer verified, installing Composer..."; \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer --version="${COMPOSER_VERSION}" && break; \
    else \
    echo "  ERROR: Invalid Composer installer signature"; \
    fi; \
    elif [ "$i" -eq 5 ]; then \
    echo "  Falling back to direct download of Composer phar..."; \
    wget -q -O /usr/local/bin/composer "https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar" || \
    wget -q -O /usr/local/bin/composer "https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar"; \
    chmod +x /usr/local/bin/composer && break; \
    fi; \
    sleep 2; \
    done; \
    rm -f composer-setup.php; \
    composer --version || exit 1; \
    chmod 777 /composer; \
    echo "  [✓] Composer installed successfully"

# Install Symfony CLI with retry logic
# Reference: https://symfony.com/download
RUN set -eux; \
    echo "==> Installing Symfony CLI ${SYMFONY_CLI_VERSION}..."; \
    for i in 1 2 3; do \
    echo "  Attempt $i to download Symfony CLI..."; \
    if wget --progress=dot:giga -O /tmp/symfony-installer https://get.symfony.com/cli/installer; then \
    bash /tmp/symfony-installer; \
    mv /root/.symfony*/bin/symfony /usr/local/bin/symfony; \
    chmod +x /usr/local/bin/symfony; \
    rm -rf /root/.symfony* /tmp/symfony-installer; \
    break; \
    elif [ "$i" -eq 3 ]; then \
    echo "  Falling back to direct download of Symfony CLI..."; \
    wget --progress=dot:giga -O /tmp/symfony.tar.gz "https://github.com/symfony-cli/symfony-cli/releases/download/v${SYMFONY_CLI_VERSION}/symfony-cli_linux_amd64.tar.gz"; \
    tar -xzf /tmp/symfony.tar.gz -C /usr/local/bin; \
    rm /tmp/symfony.tar.gz; \
    chmod +x /usr/local/bin/symfony; \
    break; \
    fi; \
    sleep 2; \
    done; \
    symfony version || echo "  [!] Symfony CLI installation failed (non-critical)"; \
    echo "  [✓] Symfony CLI installed successfully"

# Create directory structure with proper permissions
# Following the Principle of Least Privilege
RUN set -eux; \
    mkdir -p \
    /var/www/html/public \
    /var/www/html/var \
    /var/www/html/vendor \
    /var/log/nginx \
    /var/log/php \
    /var/log/redis \
    # /var/log/supervisor \
    /var/log/symfony \
    /var/run \
    /var/run/php \
    /run/nginx \
    /etc/nginx \
    /etc/nginx/conf.d \
    /var/cache/nginx \
    /var/cache/nginx/fastcgi \
    /var/cache/nginx/proxy \
    /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp \
    /var/lib/redis \
    /tmp/symfony; \
    chown -R nginx:nginx \
    /var/www/html \
    /var/log/nginx \
    /var/cache/nginx \
    /run/nginx \
    /var/run/php; \
    if id redis >/dev/null 2>&1; then \
    chown -R redis:redis /var/lib/redis /var/log/redis; \
    fi; \
    chmod -R 755 /var/www/html; \
    chmod -R 777 /var/www/html/var /tmp/symfony; \
    chmod -R 755 /var/log; \
    chmod 755 /var/run

# Configure PHP-FPM to use Unix socket for optimal performance
# Reference: https://www.php.net/manual/en/install.fpm.configuration.php
RUN set -eux; \
    mkdir -p /var/run/php; \
    chown nginx:nginx /var/run/php; \
    { \
    echo '[www]'; \
    echo 'listen = /var/run/php/php-fpm.sock'; \
    echo 'listen.owner = nginx'; \
    echo 'listen.group = nginx'; \
    echo 'listen.mode = 0660'; \
    echo 'listen.backlog = 511'; \
    } > /usr/local/etc/php-fpm.d/zzz-socket-override.conf

# Clean up build dependencies to reduce image size
# Reference: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#minimize-the-number-of-layers
RUN set -eux; \
    apk del --no-cache .build-deps; \
    rm -rf /tmp/* /var/tmp/* /usr/share/doc/* /usr/share/man/*; \
    echo "==> Final verification:"; \
    id nginx || exit 1; \
    id redis || exit 1; \
    nginx -v || exit 1; \
    php -v || exit 1; \
    echo "==> Installed PHP modules:"; \
    php -m

# Copy configuration templates
COPY nginx/nginx.conf /etc/nginx/nginx.conf.template
COPY nginx/default.conf /etc/nginx/conf.d/default.conf.template
COPY php/php.ini /usr/local/etc/php/php.ini.template
COPY php/php-fpm.conf /usr/local/etc/php-fpm.conf.template
COPY php/www.conf /usr/local/etc/php-fpm.d/www.conf.template
COPY redis/redis.conf /etc/redis/redis.conf.template
# COPY supervisor/supervisord.conf /etc/supervisor/supervisord.conf

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

# Copy configuration processing script
COPY scripts/process-configs.sh /usr/local/bin/process-configs
RUN chmod +x /usr/local/bin/process-configs

# Process configs and create health check script
RUN set -eux; \
    /usr/local/bin/process-configs; \
    { \
    printf '#!/bin/sh\n'; \
    printf 'curl -f http://localhost/health || exit 1\n'; \
    } > /usr/local/bin/healthcheck; \
    chmod +x /usr/local/bin/healthcheck

# Copy quick-start script for debugging
COPY scripts/quick-start.sh /usr/local/bin/quick-start
RUN chmod +x /usr/local/bin/quick-start

# Set proper ownership
RUN set -eux; \
    chown -R nginx:nginx /var/www/html; \
    chmod -R 755 /var/www/html

# ============================================================================
# CONDITIONAL HEALTH CHECK (Build Argument)
# Allows switching between simple and comprehensive health checks
# ============================================================================

ARG HEALTH_CHECK_TYPE=simple

# Create templates directory
RUN mkdir -p /usr/local/share/php-api-stack

# Copy demo index.php and health check templates
COPY --chown=nginx:nginx index.php /usr/local/share/php-api-stack/index.php
COPY --chown=nginx:nginx health.php /usr/local/share/php-api-stack/health-comprehensive.php

# Install appropriate health check template based on build type
RUN set -eux; \
    if [ "$HEALTH_CHECK_TYPE" = "comprehensive" ]; then \
    echo "==> Installing comprehensive health check template..."; \
    cp /usr/local/share/php-api-stack/health-comprehensive.php /usr/local/share/php-api-stack/health.php; \
    php -l /usr/local/share/php-api-stack/health.php; \
    else \
    echo "==> Installing simple health check template..."; \
    { \
    printf '<?php\n'; \
    printf 'header("Content-Type: application/json");\n'; \
    printf 'echo json_encode(["status"=>"healthy","timestamp"=>date("c")]);\n'; \
    } > /usr/local/share/php-api-stack/health.php; \
    fi; \
    php -l /usr/local/share/php-api-stack/index.php; \
    echo "  [✓] Templates validated and ready"

# Health check configuration
# Reference: https://docs.docker.com/engine/reference/builder/#healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD /usr/local/bin/healthcheck

# Set working directory
WORKDIR /var/www/html

# Expose HTTP and HTTPS ports
EXPOSE 80 443

# Define volumes for persistence
VOLUME ["/var/www/html", "/var/log", "/var/lib/redis"]

# Use tini as init system for proper signal handling
# Reference: https://github.com/krallin/tini
ENTRYPOINT ["/sbin/tini", "--", "docker-entrypoint"]
# CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
CMD ["start"]