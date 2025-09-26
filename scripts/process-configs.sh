#!/bin/bash
# Process configuration templates with default values
set -e

# Set default environment variables
export PHP_FPM_PM=${PHP_FPM_PM:-dynamic}
export PHP_FPM_PM_MAX_CHILDREN=${PHP_FPM_PM_MAX_CHILDREN:-50}
export PHP_FPM_PM_START_SERVERS=${PHP_FPM_PM_START_SERVERS:-5}
export PHP_FPM_PM_MIN_SPARE_SERVERS=${PHP_FPM_PM_MIN_SPARE_SERVERS:-5}
export PHP_FPM_PM_MAX_SPARE_SERVERS=${PHP_FPM_PM_MAX_SPARE_SERVERS:-10}
export PHP_FPM_PM_MAX_REQUESTS=${PHP_FPM_PM_MAX_REQUESTS:-500}
export PHP_FPM_PM_STATUS_PATH=${PHP_FPM_PM_STATUS_PATH:-/status}
export PHP_FPM_PING_PATH=${PHP_FPM_PING_PATH:-/ping}
export PHP_FPM_ACCESS_LOG=${PHP_FPM_ACCESS_LOG:-/var/log/php/fpm-access.log}
export PHP_FPM_SLOW_LOG=${PHP_FPM_SLOW_LOG:-/var/log/php/fpm-slow.log}
export PHP_FPM_REQUEST_SLOWLOG_TIMEOUT=${PHP_FPM_REQUEST_SLOWLOG_TIMEOUT:-30s}
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
export PHP_SESSION_SAVE_PATH=${PHP_SESSION_SAVE_PATH:-tcp://127.0.0.1:6379}
export PHP_OPCACHE_ENABLE=${PHP_OPCACHE_ENABLE:-1}
export PHP_OPCACHE_MEMORY=${PHP_OPCACHE_MEMORY:-256}
export PHP_OPCACHE_MAX_FILES=${PHP_OPCACHE_MAX_FILES:-20000}
export PHP_OPCACHE_VALIDATE_TIMESTAMPS=${PHP_OPCACHE_VALIDATE_TIMESTAMPS:-0}
export PHP_OPCACHE_REVALIDATE_FREQ=${PHP_OPCACHE_REVALIDATE_FREQ:-0}
export PHP_OPCACHE_JIT=${PHP_OPCACHE_JIT:-tracing}
export PHP_OPCACHE_JIT_BUFFER_SIZE=${PHP_OPCACHE_JIT_BUFFER_SIZE:-128M}
export XDEBUG_MODE=${XDEBUG_MODE:-off}
export XDEBUG_HOST=${XDEBUG_HOST:-host.docker.internal}
export XDEBUG_PORT=${XDEBUG_PORT:-9003}
export XDEBUG_IDE_KEY=${XDEBUG_IDE_KEY:-PHPSTORM}

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
$PHP_OPCACHE_ENABLE
$PHP_OPCACHE_MEMORY
$PHP_OPCACHE_MAX_FILES
$PHP_OPCACHE_VALIDATE_TIMESTAMPS
$PHP_OPCACHE_REVALIDATE_FREQ
$PHP_OPCACHE_JIT
$PHP_OPCACHE_JIT_BUFFER_SIZE
$XDEBUG_MODE
$XDEBUG_HOST
$XDEBUG_PORT
$XDEBUG_IDE_KEY
'

echo "Processing configuration templates..."

# Process templates
if [ -f /etc/nginx/nginx.conf.template ]; then
    envsubst "$VARS_TO_SUBSTITUTE" < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
    echo "  ✓ Nginx main configuration processed"
fi

if [ -f /etc/nginx/conf.d/default.conf.template ]; then
    envsubst "$VARS_TO_SUBSTITUTE" < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
    echo "  ✓ Nginx site configuration processed"
fi

if [ -f /usr/local/etc/php/php.ini.template ]; then
    envsubst "$VARS_TO_SUBSTITUTE" < /usr/local/etc/php/php.ini.template > /usr/local/etc/php/php.ini
    echo "  ✓ PHP.ini configuration processed"
fi

# Process PHP-FPM global configuration if template exists
if [ -f /usr/local/etc/php-fpm.conf.template ]; then
    envsubst "$VARS_TO_SUBSTITUTE" < /usr/local/etc/php-fpm.conf.template > /usr/local/etc/php-fpm.conf
    echo "  ✓ PHP-FPM global configuration processed"
fi

if [ -f /usr/local/etc/php-fpm.d/www.conf.template ]; then
    envsubst "$VARS_TO_SUBSTITUTE" < /usr/local/etc/php-fpm.d/www.conf.template > /usr/local/etc/php-fpm.d/www.conf
    echo "  ✓ PHP-FPM pool configuration processed"
fi

if [ -f /etc/redis/redis.conf.template ]; then
    envsubst "$VARS_TO_SUBSTITUTE" < /etc/redis/redis.conf.template > /etc/redis/redis.conf
    echo "  ✓ Redis configuration processed"
fi

echo "Configuration templates processed successfully."

# Validate configurations
echo "Validating configurations..."

# Validate PHP-FPM
if php-fpm -t 2>/dev/null; then
    echo "  ✓ PHP-FPM configuration is valid"
else
    echo "  ✗ PHP-FPM configuration test failed!"
    php-fpm -t
    exit 1
fi

# Validate Nginx
if nginx -t 2>/dev/null; then
    echo "  ✓ Nginx configuration is valid"
else
    echo "  ✗ Nginx configuration test failed!"
    nginx -t
    exit 1
fi

echo "All configurations are valid."