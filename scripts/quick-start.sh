#!/bin/bash
echo "Quick start - Processing configs and starting services..."
/usr/local/bin/process-configs
php-fpm -D
nginx
redis-server --daemonize yes
echo "Services started. Use 'ps aux' to verify."