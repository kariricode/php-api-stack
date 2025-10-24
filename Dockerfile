# ============================================================================
# Multi-stage build for kariricode/php-api-stack
# Production-ready PHP + Nginx + Redis (+ optional Dev tooling)
# Architecture: Base → Production | Dev
# ============================================================================
# Author: KaririCode
# License: MIT
# Repository: https://github.com/kariricode/php-api-stack
# ============================================================================

# ----------------------------------------------------------------------------
# Build Arguments - Component Versions
# ----------------------------------------------------------------------------
ARG PHP_VERSION=8.4
ARG NGINX_VERSION=1.27.3
ARG REDIS_VERSION=7.2
ARG ALPINE_VERSION=3.21
ARG COMPOSER_VERSION=2.8.12
ARG SYMFONY_CLI_VERSION=5.15.1
ARG VERSION=1.2.0

# Build metadata for reproducibility
ARG BUILD_DATE
ARG VCS_REF

# ----------------------------------------------------------------------------
# PECL Extension Versions
# Reference: https://pecl.php.net/
# ----------------------------------------------------------------------------
ARG PHP_REDIS_VERSION=6.1.0
ARG PHP_APCU_VERSION=5.1.24
ARG PHP_UUID_VERSION=1.2.1
ARG PHP_IMAGICK_VERSION=3.7.0
ARG PHP_AMQP_VERSION=2.1.2
ARG XDEBUG_VERSION=3.4.6

# ============================================================================
# Stage: Redis Binaries (from official image)
# ============================================================================
FROM redis:${REDIS_VERSION}-alpine AS redis-build

# ============================================================================
# Stage: Nginx Binaries (from official image)
# ============================================================================
FROM nginx:${NGINX_VERSION}-alpine AS nginx-build

# ============================================================================
# Stage: Base - Common runtime foundation (used by both production and dev)
# ============================================================================
FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION} AS base

SHELL ["/bin/ash", "-o", "pipefail", "-c"]

# ----------------------------------------------------------------------------
# Propagate build args to this stage
# CRITICAL: Must be declared BEFORE any RUN that uses them
# ----------------------------------------------------------------------------
ARG PHP_VERSION
ARG NGINX_VERSION
ARG REDIS_VERSION
ARG ALPINE_VERSION
ARG COMPOSER_VERSION
ARG VERSION
ARG BUILD_DATE
ARG VCS_REF

# PECL extension versions
ARG PHP_REDIS_VERSION
ARG PHP_APCU_VERSION
ARG PHP_UUID_VERSION
ARG PHP_IMAGICK_VERSION
ARG PHP_AMQP_VERSION

# Extension lists (defaults can be overridden by --build-arg)
ARG PHP_CORE_EXTENSIONS="pdo pdo_mysql opcache intl zip bcmath gd mbstring xml sockets"
ARG PHP_PECL_EXTENSIONS="redis apcu uuid"

# ----------------------------------------------------------------------------
# Labels for OCI metadata and traceability
# Reference: https://github.com/opencontainers/image-spec/blob/main/annotations.md
# ----------------------------------------------------------------------------
LABEL maintainer="KaririCode <community@kariricode.org>" \
    org.opencontainers.image.title="PHP API Stack" \
    org.opencontainers.image.description="Production-ready PHP + Nginx + Redis + Symfony stack" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.source="https://github.com/kariricode/php-api-stack" \
    org.opencontainers.image.licenses="MIT" \
    stack.version="${VERSION}" \
    stack.php.version="${PHP_VERSION}" \
    stack.nginx.version="${NGINX_VERSION}" \
    stack.redis.version="${REDIS_VERSION}" \
    stack.alpine.version="${ALPINE_VERSION}" \
    stack.composer.version="${COMPOSER_VERSION}" \
    stack.php.redis.version="${PHP_REDIS_VERSION}" \
    stack.php.apcu.version="${PHP_APCU_VERSION}" \
    stack.php.uuid.version="${PHP_UUID_VERSION}"

# ----------------------------------------------------------------------------
# Environment defaults for Composer, PHP, and stack
# ----------------------------------------------------------------------------
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer \
    PATH="/usr/bin:/usr/local/bin:/composer/vendor/bin:/symfony/bin:/usr/sbin:/sbin:$PATH" \
    STACK_VERSION=${VERSION}

# ----------------------------------------------------------------------------
# System runtime dependencies
# Reference: https://pkgs.alpinelinux.org/packages
# hadolint ignore=DL3018
# ----------------------------------------------------------------------------
RUN set -eux; \
    apk update; \
    \
    # Process control and init
    apk add --no-cache bash shadow su-exec tini; \
    \
    # Network / TLS
    apk add --no-cache git curl wget ca-certificates openssl; \
    \
    # Misc runtime libs
    apk add --no-cache gettext tzdata pcre2 zlib p7zip; \
    \
    # Image/zip/xml/icu runtime libs
    apk add --no-cache icu-libs libzip libpng libjpeg-turbo freetype libxml2; \
    \
    # Security: Remove tar to mitigate CVE-2025-45582
    apk del tar 2>/dev/null || true; \
    \
    update-ca-certificates; \
    \
    # Git safe directory for mounted volumes
    git config --global --add safe.directory /var/www/html; \
    \
    echo "✓ System dependencies installed successfully"

# ----------------------------------------------------------------------------
# Users & directories (least privilege principle)
# Reference: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
# ----------------------------------------------------------------------------
RUN set -eux; \
    # Create nginx user/group (idempotent)
    addgroup -g 101 -S nginx 2>/dev/null || true; \
    adduser -u 101 -S -D -H -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx 2>/dev/null || true; \
    \
    # Create redis user/group (idempotent)
    addgroup -S redis 2>/dev/null || true; \
    adduser -S -D -h /var/lib/redis -s /sbin/nologin -G redis redis 2>/dev/null || true; \
    \
    # Create directory structure
    install -d -m 0755 \
    /var/www/html/public \
    /var/www/html/var \
    /var/www/html/vendor \
    /var/log/nginx \
    /var/log/php \
    /var/log/redis \
    /var/log/symfony \
    /var/run/php \
    /run/nginx \
    /etc/nginx \
    /etc/nginx/conf.d \
    /var/cache/nginx/fastcgi \
    /var/cache/nginx/proxy \
    /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp \
    /var/lib/redis \
    /tmp/symfony; \
    \
    # Set ownership
    chown -R nginx:nginx \
    /var/www/html \
    /var/log/nginx \
    /var/log/symfony \
    /var/cache/nginx \
    /run/nginx \
    /var/run/php; \
    chown -R redis:redis /var/lib/redis /var/log/redis; \
    \
    # Ensure correct permissions
    chmod 0755 /tmp/symfony; \
    chmod -R 0755 /var/www/html; \
    \
    echo "✓ Users and directories configured successfully"

# ----------------------------------------------------------------------------
# PHP Core Extensions (built from source)
# Reference: https://github.com/docker-library/docs/blob/master/php/README.md
# hadolint ignore=DL3018
# ----------------------------------------------------------------------------
RUN set -eux; \
    echo "Installing PHP core extensions: ${PHP_CORE_EXTENSIONS}"; \
    \
    # Install build dependencies as virtual package
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
    \
    # Configure GD if present in extension list
    if echo " ${PHP_CORE_EXTENSIONS} " | grep -q " gd "; then \
    echo "Configuring GD with FreeType and JPEG support..."; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    fi; \
    \
    # Install extensions (intentional word splitting)
    # shellcheck disable=SC2086
    docker-php-ext-install -j"$(nproc)" ${PHP_CORE_EXTENSIONS}; \
    \
    # Verify installation
    echo "Verifying core extensions..."; \
    for ext in ${PHP_CORE_EXTENSIONS}; do \
    # OPcache is a Zend extension, check differently
    if [ "${ext}" = "opcache" ]; then \
    if ! php -v | grep -qi "Zend OPcache"; then \
    echo "ERROR: Extension ${ext} not loaded!" >&2; \
    php -v; \
    exit 1; \
    fi; \
    elif ! php -m | grep -qi "^${ext}$"; then \
    echo "ERROR: Extension ${ext} not loaded!" >&2; \
    echo "Available extensions:"; \
    php -m; \
    exit 1; \
    fi; \
    echo "  ✓ ${ext}"; \
    done; \
    \
    # Cleanup
    apk del .build-deps; \
    rm -rf /tmp/*; \
    \
    echo "✓ Core extensions installed successfully"; \
    php -m | sed 's/^/  → /'

# ----------------------------------------------------------------------------
# PECL Extensions (production-safe)
# Reference: https://pecl.php.net/
# hadolint ignore=DL3018
# ----------------------------------------------------------------------------
RUN set -eux; \
    echo "Installing PECL extensions: ${PHP_PECL_EXTENSIONS}"; \
    echo "Extension versions:"; \
    echo "  - Redis:   ${PHP_REDIS_VERSION}"; \
    echo "  - APCu:    ${PHP_APCU_VERSION}"; \
    echo "  - UUID:    ${PHP_UUID_VERSION}"; \
    echo "  - ImageMagick: ${PHP_IMAGICK_VERSION}"; \
    echo "  - AMQP:    ${PHP_AMQP_VERSION}"; \
    \
    # Install build dependencies as virtual package
    apk add --no-cache --virtual .pecl-build-deps \
    $PHPIZE_DEPS \
    util-linux-dev; \
    \
    # Install runtime dependencies (kept after build)
    apk add --no-cache \
    util-linux; \
    \
    # Install each extension with version pinning
    for ext in ${PHP_PECL_EXTENSIONS}; do \
    echo "Processing PECL extension: ${ext}"; \
    \
    case "${ext}" in \
    redis) \
    pecl install "redis-${PHP_REDIS_VERSION}" && \
    docker-php-ext-enable redis \
    ;; \
    apcu) \
    pecl install "apcu-${PHP_APCU_VERSION}" && \
    docker-php-ext-enable apcu \
    ;; \
    uuid) \
    pecl install "uuid-${PHP_UUID_VERSION}" && \
    docker-php-ext-enable uuid \
    ;; \
    imagick) \
    apk add --no-cache imagemagick-dev imagemagick && \
    pecl install "imagick-${PHP_IMAGICK_VERSION}" && \
    docker-php-ext-enable imagick \
    ;; \
    amqp) \
    apk add --no-cache rabbitmq-c-dev rabbitmq-c && \
    pecl install "amqp-${PHP_AMQP_VERSION}" && \
    docker-php-ext-enable amqp \
    ;; \
    xdebug) \
    echo "Skipping xdebug in base stage (handled in dev stage)" \
    ;; \
    *) \
    echo "ERROR: Unknown PECL extension: ${ext}" >&2; \
    echo "Available: redis, apcu, uuid, imagick, amqp, xdebug" >&2; \
    exit 1 \
    ;; \
    esac; \
    done; \
    \
    # Verify installation
    echo "Verifying PECL extensions..."; \
    for ext in ${PHP_PECL_EXTENSIONS}; do \
    # Skip xdebug verification in base stage
    if [ "${ext}" = "xdebug" ]; then continue; fi; \
    \
    if ! php -m | grep -qi "^${ext}$"; then \
    echo "ERROR: Extension ${ext} not loaded!" >&2; \
    echo "Available extensions:"; \
    php -m; \
    exit 1; \
    fi; \
    \
    # Show installed version with proper error handling
    case "${ext}" in \
    redis|apcu|uuid|imagick) \
    php -r "echo '  ✓ ${ext} ' . phpversion('${ext}') . \"\n\";" || echo "  ✓ ${ext} (version check failed)" \
    ;; \
    *) \
    echo "  ✓ ${ext}" \
    ;; \
    esac; \
    done; \
    \
    # Cleanup
    pecl clear-cache; \
    rm -rf /tmp/pear ~/.pearrc /tmp/*; \
    apk del .pecl-build-deps; \
    \
    echo "✓ PECL extensions installed successfully"

# ----------------------------------------------------------------------------
# Copy Nginx & Redis binaries from official builds
# ----------------------------------------------------------------------------
COPY --from=nginx-build /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx-build /usr/lib/nginx /usr/lib/nginx
COPY --from=nginx-build /etc/nginx/mime.types /etc/nginx/mime.types
COPY --from=nginx-build /etc/nginx/fastcgi_params /etc/nginx/fastcgi_params
COPY --from=nginx-build /etc/nginx/fastcgi.conf /etc/nginx/fastcgi.conf
COPY --from=nginx-build /etc/nginx/scgi_params /etc/nginx/scgi_params
COPY --from=nginx-build /etc/nginx/uwsgi_params /etc/nginx/uwsgi_params
COPY --from=redis-build /usr/local/bin/redis-* /usr/local/bin/

# Verify binaries
RUN set -eux; \
    nginx -v 2>&1 | sed 's/^/  → /'; \
    redis-server --version | sed 's/^/  → /'; \
    echo "✓ Nginx and Redis binaries copied successfully"

# ----------------------------------------------------------------------------
# Composer (signature verified)
# Reference: https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
# ----------------------------------------------------------------------------
RUN set -eux; \
    echo "Installing Composer ${COMPOSER_VERSION}..."; \
    mkdir -p /composer; \
    \
    # Download and verify installer
    EXPECTED_CHECKSUM="$(wget -q -O - https://composer.github.io/installer.sig)"; \
    wget -q -O composer-setup.php https://getcomposer.org/installer; \
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384','composer-setup.php');")"; \
    \
    # Fail-fast on checksum mismatch
    if [ "${EXPECTED_CHECKSUM}" != "${ACTUAL_CHECKSUM}" ]; then \
    echo "ERROR: Composer installer checksum mismatch!" >&2; \
    echo "Expected: ${EXPECTED_CHECKSUM}" >&2; \
    echo "Got:      ${ACTUAL_CHECKSUM}" >&2; \
    exit 1; \
    fi; \
    \
    # Install Composer
    php composer-setup.php \
    --install-dir=/usr/local/bin \
    --filename=composer \
    --version="${COMPOSER_VERSION}"; \
    \
    # Cleanup
    rm -f composer-setup.php; \
    chmod 0775 /composer; \
    \
    # Verify installation
    composer --version | sed 's/^/  → /'; \
    echo "✓ Composer installed successfully"

# ----------------------------------------------------------------------------
# PHP-FPM socket tuning (for Nginx integration)
# Reference: https://www.php.net/manual/en/install.fpm.configuration.php
# ----------------------------------------------------------------------------
RUN set -eux; \
    { \
    echo '[www]'; \
    echo 'listen = /var/run/php/php-fpm.sock'; \
    echo 'listen.owner = nginx'; \
    echo 'listen.group = nginx'; \
    echo 'listen.mode = 0660'; \
    echo 'listen.backlog = 511'; \
    } > /usr/local/etc/php-fpm.d/zzz-socket-override.conf; \
    \
    echo "✓ PHP-FPM socket configuration applied"; \
    cat /usr/local/etc/php-fpm.d/zzz-socket-override.conf | sed 's/^/  → /'

# ----------------------------------------------------------------------------
# Config templates & helper scripts (processed by entrypoint)
# ----------------------------------------------------------------------------
COPY nginx/nginx.conf              /etc/nginx/nginx.conf.template
COPY nginx/default.conf            /etc/nginx/conf.d/default.conf.template
COPY php/php.ini                   /usr/local/etc/php/php.ini.template
COPY php/php-fpm.conf              /usr/local/etc/php-fpm.conf.template
COPY php/www.conf                  /usr/local/etc/php-fpm.d/www.conf.template
COPY php/monitoring.conf           /usr/local/etc/php-fpm.d/monitoring.conf.template
COPY redis/redis.conf              /etc/redis/redis.conf.template
COPY php/xdebug.ini                /usr/local/etc/php/conf.d/xdebug.ini.template

COPY docker-entrypoint.sh          /usr/local/bin/docker-entrypoint
COPY scripts/process-configs.sh    /usr/local/bin/process-configs
COPY scripts/quick-start.sh        /usr/local/bin/quick-start

RUN chmod +x /usr/local/bin/docker-entrypoint /usr/local/bin/process-configs /usr/local/bin/quick-start

# ----------------------------------------------------------------------------
# Healthcheck templates (staged, published at runtime)
# ----------------------------------------------------------------------------
RUN install -d -m 0755 /opt/php-api-stack-templates

COPY --chown=nginx:nginx php/index.php /opt/php-api-stack-templates/index.php
COPY --chown=nginx:nginx php/health.php /opt/php-api-stack-templates/health.php

# Validate syntax at build time
RUN set -eux; \
    php -l /opt/php-api-stack-templates/index.php; \
    php -l /opt/php-api-stack-templates/health.php; \
    echo "✓ Healthcheck templates validated successfully"

WORKDIR /var/www/html

# ============================================================================
# Stage: Production - Optimized production runtime
# ============================================================================
FROM base AS production

# Propagate production-specific build args
ARG PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
ARG PHP_OPCACHE_MAX_ACCELERATED_FILES=20000
ARG PHP_OPCACHE_ENABLE=1
ARG PHP_OPCACHE_MEMORY_CONSUMPTION=256

# Production environment variables
ENV APP_ENV=production \
    APP_DEBUG=false \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=${PHP_OPCACHE_VALIDATE_TIMESTAMPS} \
    PHP_OPCACHE_MAX_ACCELERATED_FILES=${PHP_OPCACHE_MAX_ACCELERATED_FILES} \
    PHP_OPCACHE_MEMORY_CONSUMPTION=${PHP_OPCACHE_MEMORY_CONSUMPTION} \
    PHP_OPCACHE_ENABLE=${PHP_OPCACHE_ENABLE}

# Materialize configs at build time for production
RUN /usr/local/bin/process-configs

# Healthcheck script used by Docker HEALTHCHECK
RUN set -eux; \
    printf '#!/bin/sh\n' > /usr/local/bin/healthcheck; \
    printf 'curl -f http://localhost/health || exit 1\n' >> /usr/local/bin/healthcheck; \
    chmod +x /usr/local/bin/healthcheck

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD /usr/local/bin/healthcheck

EXPOSE 80 443
VOLUME ["/var/www/html", "/var/log", "/var/lib/redis"]
ENTRYPOINT ["/sbin/tini", "--", "docker-entrypoint"]
CMD ["start"]

# ============================================================================
# Stage: Dev - Development with additional tooling
# ============================================================================
FROM base AS dev

# Propagate dev-specific build args
ARG SYMFONY_CLI_VERSION
ARG XDEBUG_VERSION
ARG XDEBUG_ENABLE=1
ARG APP_ENV=development

# Development environment variables
ENV APP_ENV=development \
    APP_DEBUG=true \
    XDEBUG_ENABLE=${XDEBUG_ENABLE} \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=1 \
    PHP_OPCACHE_REVALIDATE_FREQ=0

# ----------------------------------------------------------------------------
# Install development tools and build dependencies
# Consolidate all build-time dependencies in a single layer
# hadolint ignore=DL3018
# ----------------------------------------------------------------------------
RUN set -eux; \
    echo "Setting up development environment..."; \
    \
    # 1. Install runtime dev tools (kept after build)
    apk add --no-cache procps htop; \
    \
    # 2. Install ALL build-time dependencies as a single virtual package
    apk add --no-cache --virtual .dev-build-deps \
    $PHPIZE_DEPS \
    build-base \
    curl \
    tar \
    linux-headers; \
    \
    # 3. Install Symfony CLI
    if [ "${APP_ENV}" = "development" ]; then \
    echo "Installing Symfony CLI v${SYMFONY_CLI_VERSION}..."; \
    wget -q -O /tmp/symfony.tar.gz \
    "https://github.com/symfony-cli/symfony-cli/releases/download/v${SYMFONY_CLI_VERSION}/symfony-cli_linux_amd64.tar.gz"; \
    tar -xzf /tmp/symfony.tar.gz -C /usr/local/bin symfony; \
    chmod +x /usr/local/bin/symfony; \
    rm /tmp/symfony.tar.gz; \
    symfony version | sed 's/^/  → /'; \
    fi; \
    \
    # 4. Install Xdebug (manual compile with version pinning)
    if [ "${APP_ENV}" = "development" ] && [ "${XDEBUG_ENABLE}" = "1" ]; then \
    echo "Installing Xdebug v${XDEBUG_VERSION}..."; \
    curl -fsSL "https://pecl.php.net/get/xdebug-${XDEBUG_VERSION}.tgz" -o xdebug.tgz; \
    tar -xzf xdebug.tgz; \
    cd "xdebug-${XDEBUG_VERSION}"; \
    phpize; \
    ./configure; \
    make -j"$(nproc)"; \
    make install; \
    cd ..; \
    rm -rf xdebug.tgz "xdebug-${XDEBUG_VERSION}"; \
    echo "  ✓ Xdebug ${XDEBUG_VERSION} installed successfully"; \
    else \
    echo "Skipping Xdebug install (APP_ENV=${APP_ENV} XDEBUG_ENABLE=${XDEBUG_ENABLE})"; \
    fi; \
    \
    # 5. Cleanup all build dependencies
    apk del .dev-build-deps; \
    rm -rf /tmp/*; \
    \
    echo "✓ Development environment setup complete"

# Materialize configs for development
RUN /usr/local/bin/process-configs

# Development healthcheck (more verbose for debugging)
RUN set -eux; \
    printf '#!/bin/sh\n' > /usr/local/bin/healthcheck; \
    printf 'curl -f http://localhost/health || exit 1\n' >> /usr/local/bin/healthcheck; \
    chmod +x /usr/local/bin/healthcheck

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD /usr/local/bin/healthcheck

EXPOSE 80 443 9003
VOLUME ["/var/www/html", "/var/log", "/var/lib/redis"]
ENTRYPOINT ["/sbin/tini", "--", "docker-entrypoint"]
CMD ["start"]