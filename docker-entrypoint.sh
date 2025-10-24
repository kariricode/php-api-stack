#!/bin/bash
set -e

# ============================================================================
# Colors for output
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# ============================================================================
# QUICK BYPASS FOR SIMPLE COMMANDS
# ============================================================================
# If it's only a version check or a direct shell, execute without any processing
if [[ "$1" == "php" && "$2" == "-v" ]] || \
   [[ "$1" == "php" && "$2" == "--version" ]] || \
   [[ "$1" == "nginx" && "$2" == "-v" ]] || \
   [[ "$1" == "nginx" && "$2" == "-V" ]] || \
   [[ "$1" == "redis-server" && "$2" == "--version" ]] || \
   [[ "$1" == "redis-cli" && "$2" == "--version" ]] || \
   [[ "$1" == "composer" && "$2" == "--version" ]] || \
   [[ "$1" == "symfony" && "$2" == "version" ]]; then
    exec "$@"
fi

# If it's a basic shell command
if [[ "$1" == "bash" ]] || [[ "$1" == "sh" ]] || [[ "$1" == "/bin/bash" ]] || [[ "$1" == "/bin/sh" ]]; then
    exec "$@"
fi

# ============================================================================
# FULL INITIALIZATION FOR NORMAL EXECUTION
# ============================================================================

# Wait until a service is ready (basic checks)
wait_for_service() {
    local service=$1
    local max_attempts=${2:-30}
    local attempt=0

    log_info "Waiting for $service to be ready..."

    case $service in
        "php-fpm")
            while [ $attempt -lt $max_attempts ]; do
                if php-fpm -t >/dev/null 2>&1; then
                    log_info "PHP-FPM configuration valid"
                    return 0
                fi
                attempt=$((attempt + 1))
                sleep 1
            done
            ;;
        "nginx")
            while [ $attempt -lt $max_attempts ]; do
                if nginx -t >/dev/null 2>&1; then
                    log_info "Nginx configuration valid"
                    return 0
                fi
                attempt=$((attempt + 1))
                sleep 1
            done
            ;;
        "redis")
            while [ $attempt -lt $max_attempts ]; do
                if redis-cli ping >/dev/null 2>&1; then
                    log_info "Redis is responding"
                    return 0
                fi
                attempt=$((attempt + 1))
                sleep 1
            done
            ;;
    esac

    log_warning "$service failed to start after $max_attempts attempts"
    return 1
}

# ----------------------------------------------------------------------------
# Process configuration templates (once per container lifetime)
# ----------------------------------------------------------------------------
CONFIG_PROCESSED_FLAG="/tmp/.config_processed"
if [ ! -f "$CONFIG_PROCESSED_FLAG" ]; then
    log_info "Processing configuration templates..."
    /usr/local/bin/process-configs
    touch "$CONFIG_PROCESSED_FLAG"
else
    log_info "Configurations already processed, skipping..."
fi

# ----------------------------------------------------------------------------
# Production optimization: enforce static PHP-FPM in prod
# ----------------------------------------------------------------------------
if [ "${APP_ENV}" = "production" ] || [ "${APP_ENV}" = "prod" ]; then
    if [ "${PHP_FPM_PM}" != "static" ]; then
        log_info "Environment is production. Overriding PHP_FPM_PM to 'static' for peak performance."
        export PHP_FPM_PM="static"
    fi
    # Guard low pm.max_children (only warns)
    if [ -z "${PHP_FPM_PM_MAX_CHILDREN}" ] || [ "${PHP_FPM_PM_MAX_CHILDREN}" -lt 50 ]; then
        log_warning "PHP_FPM_PM_MAX_CHILDREN may be low for production static mode. Recommended >= 50."
    fi
else
    log_info "Environment is non-production. Using dynamic PHP-FPM settings."
fi

# ----------------------------------------------------------------------------
# Create required directories and fix permissions
# ----------------------------------------------------------------------------
log_info "Creating required directories..."
chown -R nginx:nginx /var/log/php /var/log/nginx /var/run/php
chown -R redis:redis /var/log/redis || true
chown -R nginx:nginx /run/nginx

# Session directory (file handler)
if [ "${PHP_SESSION_SAVE_HANDLER}" = "files" ]; then
    mkdir -p /var/lib/php/sessions
    chown -R nginx:nginx /var/lib/php/sessions
    chmod 700 /var/lib/php/sessions
fi

# ----------------------------------------------------------------------------
# Validate configurations (only once)
# ----------------------------------------------------------------------------
VALIDATION_FLAG="/tmp/.config_validated"
if [ ! -f "$VALIDATION_FLAG" ]; then
    log_info "Validating configurations..."
    php-fpm -t 2>&1 | grep -q "test is successful" || log_error "PHP-FPM configuration test failed"
    nginx -t 2>&1 | grep -q "test is successful" || log_error "Nginx configuration test failed"
    touch "$VALIDATION_FLAG"
fi

# ----------------------------------------------------------------------------
# Symfony bootstrap (if app detected)
# ----------------------------------------------------------------------------
if [ -f "/var/www/html/bin/console" ]; then
    log_info "Symfony application detected"

    # Cache warmup (prod only)
    if [ "${APP_ENV}" = "production" ] || [ "${APP_ENV}" = "prod" ]; then
        CACHE_FLAG="/tmp/.symfony_cache_warmed"
        if [ ! -f "$CACHE_FLAG" ]; then
            log_info "Warming up Symfony cache..."
            su -s /bin/bash -c "php bin/console cache:clear --env=prod --no-debug" nginx
            su -s /bin/bash -c "php bin/console cache:warmup --env=prod --no-debug" nginx
            touch "$CACHE_FLAG"
        fi
    fi

    # Database migrations (optional)
    if [ "${RUN_MIGRATIONS}" = "true" ]; then
        log_info "Running database migrations..."
        su -s /bin/bash -c "php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration" nginx || \
            log_warning "Migration failed or no migrations to run"
    fi

    # Assets (optional)
    if [ -d "/var/www/html/public/bundles" ]; then
        ASSETS_FLAG="/tmp/.symfony_assets_installed"
        if [ ! -f "$ASSETS_FLAG" ]; then
            log_info "Installing Symfony assets..."
            su -s /bin/bash -c "php bin/console assets:install public --symlink --relative" nginx
            touch "$ASSETS_FLAG"
        fi
    fi
fi

# ----------------------------------------------------------------------------
# DEMO_MODE
# ----------------------------------------------------------------------------
if [ "${DEMO_MODE}" = "true" ] && [ -f "/opt/php-api-stack-templates/index.php" ]; then
  log_info "Publishing demo index.php to /var/www/html/public"
  mkdir -p /var/www/html/public
  cp /opt/php-api-stack-templates/index.php /var/www/html/public/index.php
  chown nginx:nginx /var/www/html/public/index.php
  chmod 644 /var/www/html/public/index.php
else
  rm -f /var/www/html/public/index.php 2>/dev/null || true
fi

# HEALTH_CHECK_INSTALL
if [ "${HEALTH_CHECK_INSTALL}" = "true" ] && [ -f "/opt/php-api-stack-templates/health.php" ]; then
  log_info "Publishing health.php to /var/www/html/public"
  mkdir -p /var/www/html/public
  cp /opt/php-api-stack-templates/health.php /var/www/html/public/health.php
  chown nginx:nginx /var/www/html/public/health.php
  chmod 644 /var/www/html/public/health.php
else
  rm -f /var/www/html/public/health.php 2>/dev/null || true
fi

# -----------------------------------------------------------------------------
# XDEBUG
# -----------------------------------------------------------------------------
XDEBUG_IS_ACTIVE=false
# Toggle Xdebug at runtime
if [ "${XDEBUG_ENABLE:-0}" = "1" ]; then
    # First, check if the .so module is actually installed
    if php -m | grep -q xdebug; then
        # Module is installed. Now, apply the configuration.
        if [ -f /usr/local/etc/php/conf.d/xdebug.ini.template ]; then
            envsubst < /usr/local/etc/php/conf.d/xdebug.ini.template \
              > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
            log_info "Xdebug enabled (module loaded and config applied)"
            XDEBUG_IS_ACTIVE=true
        else
            # Module is installed, but the .ini is missing (bad state)
            log_warning "Xdebug module is installed, but xdebug.ini.template is missing!"
        fi
    else
        # XDEBUG_ENABLE=1, but the module was not found in the image.
        log_warning "XDEBUG_ENABLE=1, but Xdebug module is not installed. Skipping."
    fi
else
    # XDEBUG_ENABLE is not 1, so ensure it's disabled.
    rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini 2>/dev/null || true
    log_info "Xdebug disabled"
fi


# ----------------------------------------------------------------------------
# Log rotate setup (only useful if logs are bind-mounted)
# ----------------------------------------------------------------------------
if [ ! -f "/etc/logrotate.d/php-api-stack" ]; then
    cat > /etc/logrotate.d/php-api-stack << 'EOF'
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 nginx nginx
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 $(cat /var/run/nginx.pid)
    endscript
}

/var/log/php/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 nginx nginx
}

/var/log/redis/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 redis redis
}
EOF
fi

# ----------------------------------------------------------------------------
# Production tuning (best-effort inside containers)
# ----------------------------------------------------------------------------
if [ "${APP_ENV}" = "production" ] || [ "${APP_ENV}" = "prod" ]; then
    log_info "Applying production performance optimizations..."
    ulimit -n 65536 2>/dev/null || log_warning "Could not set ulimit -n (normal in containers)"
    ulimit -c unlimited 2>/dev/null || true
    if [ -w /proc/sys/net/core/somaxconn ]; then echo 1024 > /proc/sys/net/core/somaxconn; fi
    if [ -w /proc/sys/net/ipv4/tcp_max_syn_backlog ]; then echo 2048 > /proc/sys/net/ipv4/tcp_max_syn_backlog; fi
fi

# ----------------------------------------------------------------------------
# Git safe directory fix for mounted volumes
# ----------------------------------------------------------------------------
if [ "$1" != "bash" ] && [ "$1" != "sh" ]; then 
    log_info "Marking /var/www/html as a safe Git directory"
    git config --global --add safe.directory /var/www/html || true
fi

# ============================================================================
# START SERVICES BASED ON COMMAND
# ============================================================================
case "$1" in
    start)
        log_info "Starting all services..."

        # Redis in background (daemonized)
        log_info "  -> Starting Redis..."
        redis-server /etc/redis/redis.conf --daemonize yes

        # PHP-FPM in background (daemonized)
        log_info "  -> Starting PHP-FPM..."
        if [ "${XDEBUG_IS_ACTIVE}" = "true" ]; then
            log_info "  -> Xdebug is active"
        fi
        php-fpm -D

        # Nginx in foreground (PID 1) so it receives Docker signals (e.g., stop)
        log_info "  -> Starting Nginx (foreground)..."
        exec nginx -g 'daemon off;'
        ;;
    php-fpm)
        log_info "Starting PHP-FPM only..."
        if [ "${XDEBUG_IS_ACTIVE}" = "true" ]; then
            log_info "  -> Xdebug is active"
        fi
        exec php-fpm -F
        ;;
    nginx)
        log_info "Starting Nginx only..."
        exec nginx -g 'daemon off;'
        ;;
    redis|redis-server)
        log_info "Starting Redis only..."
        exec redis-server /etc/redis/redis.conf
        ;;
    console|symfony)
        shift
        log_info "Running Symfony console command..."
        exec su -s /bin/bash -c "php bin/console $*" nginx
        ;;
    *)
        # Pass through any command
        exec "$@"
        ;;
esac

