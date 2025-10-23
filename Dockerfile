# Multi-stage build for kariricode/php-api-stack
# Production-ready PHP + Nginx + Redis (+ optional Dev tooling)
# ------------------------------------------------------------
# Versions (overridable via build args)
# ------------------------------------------------------------
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

# ------------------------------------------------------------
# Stage: Redis binaries (from official image)
# ------------------------------------------------------------
FROM redis:${REDIS_VERSION}-alpine AS redis-build

# ------------------------------------------------------------
# Stage: Nginx binaries (from official image)
# ------------------------------------------------------------
FROM nginx:${NGINX_VERSION}-alpine AS nginx-build

# ------------------------------------------------------------
# Stage: Base (production runtime)
# ------------------------------------------------------------
FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION} AS base

SHELL ["/bin/ash", "-o", "pipefail", "-c"]

# Propagate build args to this stage
ARG PHP_VERSION
ARG PHP_OPCACHE_VALIDATE_TIMESTAMPS
ARG PHP_OPCACHE_MAX_ACCELERATED_FILES
ARG PHP_OPCACHE_ENABLE
ARG PHP_OPCACHE_MEMORY_CONSUMPTION
ARG NGINX_VERSION
ARG REDIS_VERSION
ARG ALPINE_VERSION
ARG COMPOSER_VERSION
ARG SYMFONY_CLI_VERSION
ARG VERSION
ARG BUILD_DATE
ARG VCS_REF

# Feature flags
ARG HEALTH_CHECK_TYPE=simple

# Labels for OCI metadata and traceability
LABEL maintainer="KaririCode <community@kariricode.org>" \
    org.opencontainers.image.title="PHP API Stack" \
    org.opencontainers.image.description="Production-ready PHP + Nginx + Redis + Symfony stack" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.source="https://github.com/kariricode/php-api-stack" \
    stack.php.version="${PHP_VERSION}" \
    stack.nginx.version="${NGINX_VERSION}" \
    stack.redis.version="${REDIS_VERSION}" \
    stack.version="${VERSION}"

# Environment defaults for Composer, PHP, and stack
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer \
    PATH="/composer/vendor/bin:/symfony/bin:/usr/local/bin:/usr/sbin:/sbin:$PATH" \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=${PHP_OPCACHE_VALIDATE_TIMESTAMPS} \
    PHP_OPCACHE_MAX_ACCELERATED_FILES=${PHP_OPCACHE_MAX_ACCELERATED_FILES} \
    PHP_OPCACHE_MEMORY_CONSUMPTION=${PHP_OPCACHE_MEMORY_CONSUMPTION} \
    PHP_OPCACHE_ENABLE=${PHP_OPCACHE_ENABLE} \
    STACK_VERSION=${VERSION}

# ------------------------------------------------------------
# System runtime dependencies
# hadolint ignore=DL3018
RUN set -eux; \
    apk update; \
    # process control and init
    apk add --no-cache bash shadow su-exec tini; \
    # network / TLS
    apk add --no-cache git curl wget ca-certificates openssl; \
    # misc runtime libs
    apk add --no-cache gettext tzdata pcre2 zlib p7zip; \
    # image/zip/xml/icu
    apk add --no-cache icu-libs libzip libpng libjpeg-turbo freetype libxml2; \
    \
    # Remove tar if it exists to mitigate CVE-2025-45582
    apk del tar || true; \
    \
    update-ca-certificates \
    \
    git config --global --add safe.directory /var/www/html

# ------------------------------------------------------------
# Users & directories (least privilege)
# SC3009-safe: no brace expansion; explicit dirs listed
RUN set -eux; \
    addgroup -g 101 -S nginx || true; \
    adduser  -u 101 -S -D -H -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx || true; \
    addgroup -S redis  || true; \
    adduser  -S -D -h /var/lib/redis -s /sbin/nologin -G redis redis || true; \
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
    chown -R nginx:nginx /var/www/html /var/log/nginx /var/cache/nginx /run/nginx /var/run/php /var/log/symfony; \
    chown -R redis:redis /var/lib/redis /var/log/redis; \
    chmod 0755 /tmp/symfony; \
    chmod -R 0755 /var/www/html

# ------------------------------------------------------------
# PHP core extensions (built from source with temporary deps)
# hadolint ignore=DL3018
ARG PHP_CORE_EXTENSIONS="pdo pdo_mysql opcache intl zip bcmath gd mbstring xml"
RUN set -eux; \
    apk add --no-cache --virtual .build-deps \ 
    $PHPIZE_DEPS \ 
    icu-dev libzip-dev libpng-dev libjpeg-turbo-dev freetype-dev \ 
    libxml2-dev curl-dev oniguruma-dev postgresql-dev linux-headers; \
    if echo " ${PHP_CORE_EXTENSIONS} " | grep -q " gd "; then \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    fi; \
    # Intentional word splitting for extension list
    # shellcheck disable=SC2086
    docker-php-ext-install -j"$(nproc)" ${PHP_CORE_EXTENSIONS}; \
    apk del .build-deps; \
    php -m | sed 's/^/  -> /'

# ------------------------------------------------------------
# PECL extensions (prod-safe)
# hadolint ignore=DL3018
ARG PHP_PECL_EXTENSIONS="redis apcu uuid"
RUN set -eux; \
    apk add --no-cache --virtual .pecl-build-deps "$PHPIZE_DEPS" util-linux-dev || true; \
    for ext in ${PHP_PECL_EXTENSIONS}; do \
    case "$ext" in \
    imagick) apk add --no-cache imagemagick-dev ;; \
    amqp)    apk add --no-cache rabbitmq-c-dev  ;; \
    esac; \
    if pecl install "$ext"; then docker-php-ext-enable "$ext"; else echo "[warn] PECL $ext failed (non-fatal)"; fi; \
    done; \
    pecl clear-cache; rm -rf /tmp/pear

# ------------------------------------------------------------
# Copy Nginx & Redis binaries from official builds
# ------------------------------------------------------------
COPY --from=nginx-build /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx-build /usr/lib/nginx /usr/lib/nginx
COPY --from=nginx-build /etc/nginx/mime.types /etc/nginx/mime.types
COPY --from=nginx-build /etc/nginx/fastcgi_params /etc/nginx/fastcgi_params
COPY --from=nginx-build /etc/nginx/fastcgi.conf /etc/nginx/fastcgi.conf
COPY --from=nginx-build /etc/nginx/scgi_params /etc/nginx/scgi_params
COPY --from=nginx-build /etc/nginx/uwsgi_params /etc/nginx/uwsgi_params
COPY --from=redis-build /usr/local/bin/redis-* /usr/local/bin/

# ------------------------------------------------------------
# Composer (signature verified)
# ------------------------------------------------------------
RUN set -eux; \
    mkdir -p /composer; \
    EXPECTED_CHECKSUM="$(wget -q -O - https://composer.github.io/installer.sig)"; \
    wget -q -O composer-setup.php https://getcomposer.org/installer; \
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384','composer-setup.php');")"; \
    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then echo "Composer installer checksum mismatch" >&2; exit 1; fi; \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer --version="${COMPOSER_VERSION}"; \
    rm -f composer-setup.php; \
    composer --version; \
    chmod 0775 /composer

# ------------------------------------------------------------
# PHP-FPM socket tuning (for Nginx integration)
# ------------------------------------------------------------
RUN set -eux; \
    { \
    echo '[www]'; \
    echo 'listen = /var/run/php/php-fpm.sock'; \
    echo 'listen.owner = nginx'; \
    echo 'listen.group = nginx'; \
    echo 'listen.mode = 0660'; \
    echo 'listen.backlog = 511'; \
    } > /usr/local/etc/php-fpm.d/zzz-socket-override.conf

# ------------------------------------------------------------
# Config templates & helper scripts (processed by entrypoint)
# ------------------------------------------------------------
COPY nginx/nginx.conf              /etc/nginx/nginx.conf.template
COPY nginx/default.conf            /etc/nginx/conf.d/default.conf.template
COPY php/php.ini                   /usr/local/etc/php/php.ini.template
COPY php/php-fpm.conf              /usr/local/etc/php-fpm.conf.template
COPY php/www.conf                  /usr/local/etc/php-fpm.d/www.conf.template
COPY php/monitoring.conf           /usr/local/etc/php-fpm.d/monitoring.conf.template
COPY redis/redis.conf              /etc/redis/redis.conf.template

COPY docker-entrypoint.sh          /usr/local/bin/docker-entrypoint
COPY scripts/process-configs.sh    /usr/local/bin/process-configs
COPY scripts/quick-start.sh        /usr/local/bin/quick-start
RUN chmod +x /usr/local/bin/docker-entrypoint /usr/local/bin/process-configs /usr/local/bin/quick-start

# ------------------------------------------------------------
# Healthcheck templates
# ------------------------------------------------------------
# Build-time flags (staging only; actual publish happens at runtime)
ARG DEMO_MODE=false
ARG HEALTH_CHECK_INSTALL=false

# Secure staging directory (read-only area inside image)
RUN set -eux; \
    install -d -m 0755 /opt/php-api-stack-templates

# Always stage templates into /opt (safe, outside working dirs). They will
# ONLY be published to /var/www/html/public at runtime when env=true.
COPY --chown=nginx:nginx php/index.php /opt/php-api-stack-templates/index.php
COPY --chown=nginx:nginx php/health.php /opt/php-api-stack-templates/health.php


# Optional: validate syntax at build (does not publish)
RUN php -l /opt/php-api-stack-templates/index.php; \
    php -l /opt/php-api-stack-templates/health.php

# Materialize configs at build time (useful for some CIs)
RUN /usr/local/bin/process-configs

# Healthcheck script used by Docker HEALTHCHECK
RUN set -eux; \
    printf '#!/bin/sh\n' > /usr/local/bin/healthcheck; \
    printf 'curl -f http://localhost/health || exit 1\n' >> /usr/local/bin/healthcheck; \
    chmod +x /usr/local/bin/healthcheck

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD /usr/local/bin/healthcheck

WORKDIR /var/www/html
EXPOSE 80 443
VOLUME ["/var/www/html", "/var/log", "/var/lib/redis"]
ENTRYPOINT ["/sbin/tini", "--", "docker-entrypoint"]
CMD ["start"]

# ======================================================================
# Stage: dev — extra tools only for development
# ======================================================================
FROM base AS dev

ARG SYMFONY_CLI_VERSION
ARG ENABLE_XDEBUG=0
ARG APP_ENV=production

# hadolint ignore=DL3018
RUN set -eux; \
    apk add --no-cache procps htop; \
    if [ "$APP_ENV" = "development" ]; then \
    wget -q -O /tmp/symfony-installer https://get.symfony.com/cli/installer; \
    bash /tmp/symfony-installer; \
    mv /root/.symfony*/bin/symfony /usr/local/bin/symfony; \
    chmod +x /usr/local/bin/symfony; \
    rm -rf /root/.symfony* /tmp/symfony-installer; \
    symfony version || true; \
    else \
    echo "Skipping Symfony CLI install (APP_ENV=$APP_ENV)"; \
    fi

# Optional Xdebug installation for local debugging
# hadolint ignore=DL3018
RUN set -eux; \
    if [ "${ENABLE_XDEBUG}" = "1" ]; then \
    apk add --no-cache --virtual .xd-build "$PHPIZE_DEPS"; \
    pecl install xdebug; \
    docker-php-ext-enable xdebug; \
    apk del --no-cache .xd-build || true; \
    fi
