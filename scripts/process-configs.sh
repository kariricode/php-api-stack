#!/bin/bash
# Process configuration templates with default values
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
# Set default environment variables
# ============================================================================
export PHP_FPM_PM=${PHP_FPM_PM:-dynamic}
export PHP_FPM_PM_MAX_CHILDREN=${PHP_FPM_PM_MAX_CHILDREN:-60}
export PHP_FPM_PM_START_SERVERS=${PHP_FPM_PM_START_SERVERS:-5}
export PHP_FPM_PM_MIN_SPARE_SERVERS=${PHP_FPM_PM_MIN_SPARE_SERVERS:-5}
export PHP_FPM_PM_MAX_SPARE_SERVERS=${PHP_FPM_PM_MAX_SPARE_SERVERS:-10}
export PHP_FPM_PM_MAX_REQUESTS=${PHP_FPM_PM_MAX_REQUESTS:-500}
export PHP_FPM_PM_STATUS_PATH=${PHP_FPM_PM_STATUS_PATH:-/status}
export PHP_FPM_PING_PATH=${PHP_FPM_PING_PATH:-/ping}
export PHP_FPM_ACCESS_LOG=${PHP_FPM_ACCESS_LOG:-/var/log/php/fpm-access.log}
export PHP_FPM_SLOW_LOG=${PHP_FPM_SLOW_LOG:-/var/log/php/fpm-slow.log}
export PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-256M}
export PHP_UPLOAD_MAX_FILESIZE=${PHP_UPLOAD_MAX_FILESIZE:-100M}
export PHP_POST_MAX_SIZE=${PHP_POST_MAX_SIZE:-100M}
export PHP_MAX_EXECUTION_TIME=${PHP_MAX_EXECUTION_TIME:-60}
export PHP_MAX_INPUT_TIME=${PHP_MAX_INPUT_TIME:-60}
export PHP_MAX_FILE_UPLOADS=${PHP_MAX_FILE_UPLOADS:-20}
export PHP_DATE_TIMEZONE=${PHP_DATE_TIMEZONE:-America/Sao_Paulo}
export PHP_DISPLAY_ERRORS=${PHP_DISPLAY_ERRORS:-Off}
export PHP_ERROR_LOG=${PHP_ERROR_LOG:-/var/log/php/error.log}
export PHP_SESSION_SAVE_HANDLER=${PHP_SESSION_SAVE_HANDLER:-redis}
export PHP_SESSION_SAVE_PATH=${PHP_SESSION_SAVE_PATH:-tcp://${REDIS_HOST:-redis}:6379?auth=${REDIS_PASSWORD}}
export PHP_OPCACHE_ENABLE=${PHP_OPCACHE_ENABLE:-1}
export PHP_OPCACHE_MEMORY=${PHP_OPCACHE_MEMORY:-256}
export PHP_OPCACHE_MAX_FILES=${PHP_OPCACHE_MAX_FILES:-20000}
export PHP_OPCACHE_VALIDATE_TIMESTAMPS=${PHP_OPCACHE_VALIDATE_TIMESTAMPS:-0}
export PHP_OPCACHE_REVALIDATE_FREQ=${PHP_OPCACHE_REVALIDATE_FREQ:-0}
export PHP_OPCACHE_JIT=${PHP_OPCACHE_JIT:-tracing}
export PHP_OPCACHE_JIT_BUFFER_SIZE=${PHP_OPCACHE_JIT_BUFFER_SIZE:-128M}
export PHP_FPM_REQUEST_SLOWLOG_TIMEOUT=${PHP_FPM_REQUEST_SLOWLOG_TIMEOUT:-30s}
export PHP_PECL_EXTENSIONS="${PHP_PECL_EXTENSIONS:-redis apcu uuid}"
export PHP_CORE_EXTENSIONS="${PHP_CORE_EXTENSIONS:-pdo pdo_mysql opcache intl zip bcmath gd mbstring xml sockets}"

export ENABLE_CACHE=${ENABLE_CACHE:-true}
export ENABLE_COMPRESSION=${ENABLE_COMPRESSION:-true}
export ENABLE_HTTP2=${ENABLE_HTTP2:-true}
export ENABLE_METRICS=${ENABLE_METRICS:-true}
export ENABLE_HEALTH_CHECK=${ENABLE_HEALTH_CHECK:-true}
export SECURITY_HEADERS=${SECURITY_HEADERS:-true}
export HEALTH_CHECK_PATH=${HEALTH_CHECK_PATH:-/health}
export METRICS_PHP_FPM_PORT=${METRICS_PHP_FPM_PORT:-9000}
export CACHE_TTL=${CACHE_TTL:-3600}

export XDEBUG_MODE=${XDEBUG_MODE:-off}
export XDEBUG_HOST=${XDEBUG_HOST:-host.docker.internal}
export XDEBUG_PORT=${XDEBUG_PORT:-9003}
export XDEBUG_IDE_KEY=${XDEBUG_IDE_KEY:-VSCODE}
export XDEBUG_VERSION=${XDEBUG_VERSION:-3.4.6}

export NGINX_WORKER_PROCESSES=${NGINX_WORKER_PROCESSES:-auto}
export NGINX_WORKER_CONNECTIONS=${NGINX_WORKER_CONNECTIONS:-2048}
export NGINX_KEEPALIVE_TIMEOUT=${NGINX_KEEPALIVE_TIMEOUT:-65}
export NGINX_CLIENT_MAX_BODY_SIZE=${NGINX_CLIENT_MAX_BODY_SIZE:-100M}
export NGINX_GZIP=${NGINX_GZIP:-on}
export NGINX_GZIP_COMP_LEVEL=${NGINX_GZIP_COMP_LEVEL:-6}
export NGINX_ACCESS_LOG=${NGINX_ACCESS_LOG:-/var/log/nginx/access.log}
export NGINX_ERROR_LOG=${NGINX_ERROR_LOG:-/var/log/nginx/error.log}

export REDIS_HOST=${REDIS_HOST:-redis}
export REDIS_APPENDONLY=${REDIS_APPENDONLY:-yes}
export REDIS_APPENDFSYNC=${REDIS_APPENDFSYNC:-everysec}
export REDIS_SAVE=${REDIS_SAVE:-"900 1 300 10 60 10000"}
export REDIS_LOG_LEVEL=${REDIS_LOG_LEVEL:-notice}
export REDIS_LOG_FILE=${REDIS_LOG_FILE:- /var/log/redis/redis.log}

export REDIS_MAXMEMORY=${REDIS_MAXMEMORY:-256M}
export REDIS_MAXMEMORY_SAMPLES=${REDIS_MAXMEMORY_SAMPLES:-5}
export REDIS_PASSWORD=${REDIS_PASSWORD:-}
export REDIS_DATABASES=${REDIS_DATABASES:-16}
export REDIS_MAXMEMORY_POLICY=${REDIS_MAXMEMORY_POLICY:-volatile-lru}
export REDIS_MAXCLIENTS=${REDIS_MAXCLIENTS:-10000}
export REDIS_TIMEOUT=${REDIS_TIMEOUT:-0}

# Create a list of variables for envsubst to process
VARS_TO_SUBSTITUTE='
$PHP_FPM_PM
$PHP_FPM_PM_MAX_CHILDREN
$PHP_FPM_PM_START_SERVERS
$PHP_FPM_PM_MIN_SPARE_SERVERS
$PHP_FPM_PM_MAX_SPARE_SERVERS
$PHP_FPM_PM_MAX_REQUESTS
$PHP_FPM_PM_STATUS_PATH
$PHP_FPM_PING_PATH
$PHP_FPM_ACCESS_LOG
$PHP_FPM_SLOW_LOG
$PHP_FPM_REQUEST_SLOWLOG_TIMEOUT
$PHP_MEMORY_LIMIT
$PHP_UPLOAD_MAX_FILESIZE
$PHP_POST_MAX_SIZE
$PHP_MAX_EXECUTION_TIME
$PHP_MAX_INPUT_TIME
$PHP_MAX_FILE_UPLOADS
$PHP_DATE_TIMEZONE
$PHP_DISPLAY_ERRORS
$PHP_ERROR_LOG
$PHP_SESSION_SAVE_HANDLER
$PHP_SESSION_SAVE_PATH
$PHP_PECL_EXTENSIONS
$PHP_CORE_EXTENSIONS
$PHP_OPCACHE_ENABLE
$PHP_OPCACHE_MEMORY
$PHP_OPCACHE_MAX_FILES
$PHP_OPCACHE_VALIDATE_TIMESTAMPS
$PHP_OPCACHE_REVALIDATE_FREQ
$PHP_OPCACHE_JIT
$PHP_OPCACHE_JIT_BUFFER_SIZE
$ENABLE_CACHE
$ENABLE_COMPRESSION
$ENABLE_HTTP2
$ENABLE_METRICS
$ENABLE_HEALTH_CHECK
$SECURITY_HEADERS
$HEALTH_CHECK_PATH
$METRICS_PHP_FPM_PORT
$CACHE_TTL
$XDEBUG_MODE
$XDEBUG_HOST
$XDEBUG_PORT
$XDEBUG_IDE_KEY
$XDEBUG_VERSION
$NGINX_WORKER_PROCESSES
$NGINX_WORKER_CONNECTIONS
$NGINX_KEEPALIVE_TIMEOUT
$NGINX_CLIENT_MAX_BODY_SIZE
$NGINX_GZIP
$NGINX_GZIP_COMP_LEVEL
$NGINX_ACCESS_LOG
$NGINX_ERROR_LOG
$REDIS_HOST
$REDIS_APPENDONLY
$REDIS_APPENDFSYNC
$REDIS_SAVE
$REDIS_LOG_LEVEL
$REDIS_LOG_FILE
$REDIS_MAXMEMORY
$REDIS_MAXMEMORY_SAMPLES
$REDIS_PASSWORD
$REDIS_DATABASES
$REDIS_MAXMEMORY_POLICY
$REDIS_MAXCLIENTS
$REDIS_TIMEOUT
'


log_info "Ensuring log directories exist and have correct permissions for validation..."

# Create log directories
mkdir -p /var/log/php /var/log/nginx /var/log/redis /var/log/supervisor /var/log/symfony /var/run/php /var/run/nginx

# Define permissions
chown -R nginx:nginx /var/log/php /var/log/nginx /var/log/symfony /var/run/php /var/run/nginx
chown -R redis:redis /var/log/redis || true
chown -R root:root /var/log/supervisor

log_info "  ✓ Log directories created and permissions set"

log_info "Processing configuration templates..."

# Process templates
if [ -f /etc/nginx/nginx.conf.template ]; then
    envsubst "$VARS_TO_SUBSTITUTE" < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
    log_info "  ✓ Nginx main configuration processed"
fi

if [ -f /etc/nginx/conf.d/default.conf.template ]; then
    envsubst "$VARS_TO_SUBSTITUTE" < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
    log_info "  ✓ Nginx site configuration processed"
fi

if [ -f /usr/local/etc/php/php.ini.template ]; then
    envsubst "$VARS_TO_SUBSTITUTE" < /usr/local/etc/php/php.ini.template > /usr/local/etc/php/php.ini
    log_info "  ✓ PHP.ini configuration processed"
fi

# Process PHP-FPM global configuration if template exists
if [ -f /usr/local/etc/php-fpm.conf.template ]; then
    envsubst "$VARS_TO_SUBSTITUTE" < /usr/local/etc/php-fpm.conf.template > /usr/local/etc/php-fpm.conf
    log_info "  ✓ PHP-FPM global configuration processed"
fi

if [ -f /usr/local/etc/php-fpm.d/www.conf.template ]; then
    envsubst "$VARS_TO_SUBSTITUTE" < /usr/local/etc/php-fpm.d/www.conf.template > /usr/local/etc/php-fpm.d/www.conf
    log_info "  ✓ PHP-FPM pool configuration processed"
fi

if [ -f /usr/local/etc/php-fpm.d/monitoring.conf.template ]; then
    envsubst "$VARS_TO_SUBSTITUTE" < /usr/local/etc/php-fpm.d/monitoring.conf.template > /usr/local/etc/php-fpm.d/monitoring.conf
    log_info "  ✓ PHP-FPM monitoring pool configuration processed"
fi

if [ -f /etc/redis/redis.conf.template ]; then
    envsubst "$VARS_TO_SUBSTITUTE" < /etc/redis/redis.conf.template > /etc/redis/redis.conf
    log_info "  ✓ Redis configuration processed"
fi

if [ "${XDEBUG_ENABLE:-0}" = "1" ]; then
    if [ -f /usr/local/etc/php/conf.d/xdebug.ini.template ]; then
        envsubst "$VARS_TO_SUBSTITUTE" < /usr/local/etc/php/conf.d/xdebug.ini.template \
          > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
        log_info "  ✓ Xdebug configuration processed (enabled)"
    else
        log_warning "  ⚠ Xdebug enabled, but template not found: /usr/local/etc/php/conf.d/xdebug.ini.template"
    fi
else
    rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini 2>/dev/null || true
    log_info "  ⟳ Xdebug disabled (no ini applied)"
fi


log_info "Configuration templates processed successfully."

# Validate configurations
log_info "Validating configurations..."

# Validate PHP-FPM
if php-fpm -t 2>/dev/null; then
    log_info "  ✓ PHP-FPM configuration is valid"
else
    log_error "  ✗ PHP-FPM configuration test failed!"
    php-fpm -t
    exit 1
fi

# Validate Nginx
if nginx -t 2>/dev/null; then
    log_info "  ✓ Nginx configuration is valid"
else
    log_error "  ✗ Nginx configuration test failed!"
    nginx -t
    exit 1
fi

log_info "All configurations are valid."
