#!/bin/bash
set -e

# Colors for output
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

# ==============================================================================
# BYPASS RÁPIDO PARA COMANDOS SIMPLES
# ==============================================================================
# Se for apenas verificação de versão ou comando direto, executar sem processamento
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

# Se for comando básico sem argumentos complexos
if [[ "$1" == "bash" ]] || [[ "$1" == "sh" ]] || [[ "$1" == "/bin/bash" ]] || [[ "$1" == "/bin/sh" ]]; then
    exec "$@"
fi

# ==============================================================================
# PROCESSAMENTO COMPLETO PARA EXECUÇÃO NORMAL
# ==============================================================================

# Function to wait for a service to be ready
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

# Check if configurations need to be processed
CONFIG_PROCESSED_FLAG="/tmp/.config_processed"
if [ ! -f "$CONFIG_PROCESSED_FLAG" ]; then
    # Process configuration templates
    log_info "Processing configuration templates..."
    /usr/local/bin/process-configs
    touch "$CONFIG_PROCESSED_FLAG"
else
    log_info "Configurations already processed, skipping..."
fi


# optimization for production environment to force static PHP-FPM mode
if [ "${APP_ENV}" = "production" ] || [ "${APP_ENV}" = "prod" ]; then
    if [ "${PHP_FPM_PM}" != "static" ]; then
        log_info "Environment is production. Overriding PHP_FPM_PM to 'static' for peak performance."
        export PHP_FPM_PM="static"
    fi
    if [ -z "${PHP_FPM_PM_MAX_CHILDREN}" ] || [ "${PHP_FPM_PM_MAX_CHILDREN}" -lt 50 ]; then
        log_warning "PHP_FPM_PM_MAX_CHILDREN is low for production static mode. Recommended >= 50."
    fi
else
    log_info "Environment is non-production. Using dynamic PHP-FPM settings."
fi


# Create required directories 
log_info "Creating required directories..."
chown -R nginx:nginx /var/log/php /var/log/nginx /var/run/php
chown -R redis:redis /var/log/redis || true
# chown -R root:root /var/log/supervisor
chown -R nginx:nginx /var/run/nginx # Nginx run dir

# Fix permissions for session directory if using files
if [ "${PHP_SESSION_SAVE_HANDLER}" = "files" ]; then
    mkdir -p /var/lib/php/sessions
    chown -R nginx:nginx /var/lib/php/sessions
    chmod 700 /var/lib/php/sessions
fi

# Validate configurations apenas se não foram validadas ainda
VALIDATION_FLAG="/tmp/.config_validated"
if [ ! -f "$VALIDATION_FLAG" ]; then
    log_info "Validating configurations..."
    php-fpm -t 2>&1 | grep -q "test is successful" || log_error "PHP-FPM configuration test failed"
    nginx -t 2>&1 | grep -q "test is successful" || log_error "Nginx configuration test failed"
    touch "$VALIDATION_FLAG"
fi

# Handle Symfony-specific initialization
if [ -f "/var/www/html/bin/console" ]; then
    log_info "Symfony application detected"
    
    # Clear and warm up cache
    if [ "${APP_ENV}" = "production" ] || [ "${APP_ENV}" = "prod" ]; then
        CACHE_FLAG="/tmp/.symfony_cache_warmed"
        if [ ! -f "$CACHE_FLAG" ]; then
            log_info "Warming up Symfony cache..."
            su -s /bin/bash -c "php bin/console cache:clear --env=prod --no-debug" nginx
            su -s /bin/bash -c "php bin/console cache:warmup --env=prod --no-debug" nginx
            touch "$CACHE_FLAG"
        fi
    fi
    
    # Run migrations if configured
    if [ "${RUN_MIGRATIONS}" = "true" ]; then
        log_info "Running database migrations..."
        su -s /bin/bash -c "php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration" nginx || \
            log_warning "Migration failed or no migrations to run"
    fi
    
    # Install assets
    if [ -d "/var/www/html/public/bundles" ]; then
        ASSETS_FLAG="/tmp/.symfony_assets_installed"
        if [ ! -f "$ASSETS_FLAG" ]; then
            log_info "Installing Symfony assets..."
            su -s /bin/bash -c "php bin/console assets:install public --symlink --relative" nginx
            touch "$ASSETS_FLAG"
        fi
    fi
fi

# Install demo index.php if no application is mounted AND DEMO_MODE is enabled
if [ ! -f "/var/www/html/public/index.php" ]; then
    if [ "${DEMO_MODE}" = "true" ]; then
        log_info "DEMO_MODE enabled. Installing demo landing page..."
        
        # Create directory if it doesn't exist
        mkdir -p /var/www/html/public
        
        if [ -f "/usr/local/share/php-api-stack/index.php" ]; then
            cp /usr/local/share/php-api-stack/index.php /var/www/html/public/index.php
            log_info "Demo landing page installed"
        else
            log_warning "Demo template not found, creating basic fallback"
            cat > /var/www/html/public/index.php << 'EOF'
<?php
phpinfo();
EOF
        fi
        
        chown nginx:nginx /var/www/html/public/index.php
        chmod 644 /var/www/html/public/index.php
    else
        log_info "No application detected and DEMO_MODE not enabled - skipping demo installation"
    fi
else
    log_info "Application detected at /var/www/html/public/index.php - skipping demo installation"
fi


# Create health check endpoint if doesn't exist
if [ ! -f "/var/www/html/public/health.php" ]; then
    # Apenas instala health check se habilitado ou se DEMO_MODE estiver ativo
    if [ "${HEALTH_CHECK_INSTALL}" = "true" ] || [ "${DEMO_MODE}" = "true" ]; then
        log_info "Installing health check endpoint..."
        
        # Cria diretório se não existir
        mkdir -p /var/www/html/public
        
        # Copy from template if exists, otherwise create basic fallback
        if [ -f "/usr/local/share/php-api-stack/health.php" ]; then
            cp /usr/local/share/php-api-stack/health.php /var/www/html/public/health.php
            log_info "Health check installed from template"
        else
            log_warning "Health check template not found, creating basic fallback"
            cat > /var/www/html/public/health.php << 'EOF'
<?php
header('Content-Type: application/json');
echo json_encode(['status' => 'healthy', 'timestamp' => date('c')], JSON_PRETTY_PRINT);
EOF
        fi
        
        chown nginx:nginx /var/www/html/public/health.php
        chmod 644 /var/www/html/public/health.php
    else
        log_info "HEALTH_CHECK_INSTALL not enabled - skipping health check installation"
    fi
else
    log_info "Health check already exists at /var/www/html/public/health.php"
fi

# Set up log rotation apenas uma vez
if [ ! -f "/etc/logrotate.d/php-api-stack" ]; then
    cat > /etc/logrotate.d/php-api-stack << EOF
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
        [ -f /var/run/nginx.pid ] && kill -USR1 \$(cat /var/run/nginx.pid)
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

# Performance tuning for production
if [ "${APP_ENV}" = "production" ] || [ "${APP_ENV}" = "prod" ]; then
    log_info "Applying production performance optimizations..."
    
    # Increase system limits
    ulimit -n 65536 2>/dev/null || log_warning "Could not set ulimit -n (normal in containers)"
    ulimit -c unlimited 2>/dev/null || true
    
    # TCP optimizations (geralmente não funcionam em containers, mas tentamos)
    if [ -w /proc/sys/net/core/somaxconn ]; then
        echo 1024 > /proc/sys/net/core/somaxconn
    fi
    
    if [ -w /proc/sys/net/ipv4/tcp_max_syn_backlog ]; then
        echo 2048 > /proc/sys/net/ipv4/tcp_max_syn_backlog
    fi
fi

# ==============================================================================
# START SERVICES BASED ON COMMAND
# ==============================================================================
# removed:
# supervisord|supervisor)
#     log_info "Starting all services with Supervisor..."
#     exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
#     ;;
# Especifics commands 
case "$1" in
    start)
        log_info "Starting all services..."
        
        # Start Redis in background (daemonize)
        log_info "  -> Starting Redis..."
        redis-server /etc/redis/redis.conf --daemonize yes
        
        # Start PHP-FPM in background (daemonize)
        log_info "  -> Starting PHP-FPM..."
        php-fpm -D
        
        # Start Nginx in foreground. The `exec` command is crucial here.
        # It replaces the script process with the Nginx process, making Nginx
        # the main container process (PID 1). This ensures it receives
        # Docker signals correctly (e.g., docker stop).
        log_info "  -> Starting Nginx (foreground)..."
        exec nginx -g 'daemon off;'
        ;;
    php-fpm)
        log_info "Starting PHP-FPM only..."
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
        # Default: start supervisord if no command given
        # if [ "$#" -eq 0 ]; then
        #     log_info "Starting all services with Supervisor (default)..."
        #     exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
        # else
            # Pass through any command
            exec "$@"
        # fi
        ;;
esac