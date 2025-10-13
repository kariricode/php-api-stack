# Image Usage Guide - PHP API Stack

**Audience**: End users and developers  
**Purpose**: Complete guide for using the published Docker image

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Configuration](#configuration)
- [Framework Integration](#framework-integration)
- [Docker Compose](#docker-compose)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Production Setup](#production-setup)
- [Monitoring and Health](#monitoring-and-health)
- [Performance Tuning](#performance-tuning)
- [Troubleshooting](#troubleshooting)
- [Examples](#examples)

## 🚀 Quick Start

### 30-Second Start

```bash
# Pull and run
docker pull kariricode/php-api-stack:latest
docker run -d -p 8080:80 kariricode/php-api-stack:latest

# Test
curl http://localhost:8080
```

**That's it!** You'll see the demo landing page showing stack status.

### With Your Application

```bash
# Run with your app mounted
docker run -d \
  --name my-app \
  -p 8080:80 \
  -v $(pwd)/app:/var/www/html \
  kariricode/php-api-stack:latest

# Access
curl http://localhost:8080
```

## 📥 Installation

### Prerequisites

- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher (optional)

### Pull Image

```bash
# Latest version
docker pull kariricode/php-api-stack:latest

# Specific version
docker pull kariricode/php-api-stack:1.2.1

# Verify
docker images kariricode/php-api-stack
```

### Available Tags

| Tag | Description | When to Use |
|-----|-------------|-------------|
| `latest` | Latest stable | Most cases |
| `stable` | Production release | Production |
| `1.2.1` | Specific version | Version pinning |
| `1.2` | Minor version | Auto-patch updates |
| `1` | Major version | Auto-minor updates |
| `test` | With comprehensive health | Testing/Monitoring |

## 🎯 Basic Usage

### Standalone Container

```bash
# Basic run
docker run -d \
  --name my-php-app \
  -p 8080:80 \
  kariricode/php-api-stack:latest

# With volume
docker run -d \
  --name my-php-app \
  -p 8080:80 \
  -v $(pwd)/app:/var/www/html \
  kariricode/php-api-stack:latest

# With environment variables
docker run -d \
  --name my-php-app \
  -p 8080:80 \
  -e APP_ENV=production \
  -e PHP_MEMORY_LIMIT=512M \
  -v $(pwd)/app:/var/www/html \
  kariricode/php-api-stack:latest
```

### Common Commands

```bash
# View logs
docker logs -f my-php-app

# Access shell
docker exec -it my-php-app bash

# Restart services
docker exec my-php-app supervisorctl restart all

# Stop container
docker stop my-php-app

# Remove container
docker rm my-php-app
```

## ⚙️ Configuration

### Environment Variables

#### PHP Settings
```bash
# Memory and execution
-e PHP_MEMORY_LIMIT=512M
-e PHP_MAX_EXECUTION_TIME=60
-e PHP_MAX_INPUT_TIME=60
-e PHP_POST_MAX_SIZE=100M
-e PHP_UPLOAD_MAX_FILESIZE=100M

# Error handling
-e PHP_DISPLAY_ERRORS=Off
-e PHP_ERROR_LOG=/var/log/php/error.log

# Timezone
-e PHP_DATE_TIMEZONE=America/New_York
```

#### PHP-FPM Pool
```bash
# Process manager
-e PHP_FPM_PM=dynamic
-e PHP_FPM_PM_MAX_CHILDREN=50
-e PHP_FPM_PM_START_SERVERS=5
-e PHP_FPM_PM_MIN_SPARE_SERVERS=5
-e PHP_FPM_PM_MAX_SPARE_SERVERS=10
-e PHP_FPM_PM_MAX_REQUESTS=500
```

#### OPcache
```bash
# OPcache configuration
-e PHP_OPCACHE_ENABLE=1
-e PHP_OPCACHE_MEMORY=256
-e PHP_OPCACHE_MAX_FILES=20000
-e PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
-e PHP_OPCACHE_JIT=tracing
-e PHP_OPCACHE_JIT_BUFFER_SIZE=128M
```

#### Application
```bash
# Application settings
-e APP_ENV=production
-e APP_DEBUG=false
-e APP_NAME=my-api
```

### Volume Mounts

```bash
# Application code (read-only in production)
-v $(pwd)/app:/var/www/html:ro

# Logs (for external monitoring)
-v $(pwd)/logs:/var/log

# Custom configurations
-v $(pwd)/php.ini:/usr/local/etc/php/php.ini:ro
-v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro
```

### Network Configuration

```bash
# Custom network
docker network create my-network

# Run with network
docker run -d \
  --name my-php-app \
  --network my-network \
  -p 8080:80 \
  kariricode/php-api-stack:latest
```

## 🚀 Framework Integration

### Symfony Application

#### Project Structure
```
my-symfony-app/
├── bin/
├── config/
├── public/          ← Mount point
│   └── index.php
├── src/
├── var/
└── vendor/
```

#### Docker Run
```bash
docker run -d \
  --name symfony-app \
  -p 8080:80 \
  -v $(pwd):/var/www/html \
  -e APP_ENV=prod \
  -e APP_SECRET=your-secret-here \
  -e DATABASE_URL=mysql://user:pass@db:3306/dbname \
  kariricode/php-api-stack:latest
```

#### With Database
```bash
# Create network
docker network create symfony-net

# Run MySQL
docker run -d \
  --name symfony-db \
  --network symfony-net \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=symfony \
  mysql:8.0

# Run Symfony app
docker run -d \
  --name symfony-app \
  --network symfony-net \
  -p 8080:80 \
  -v $(pwd):/var/www/html \
  -e APP_ENV=prod \
  -e DATABASE_URL=mysql://root:root@symfony-db:3306/symfony \
  kariricode/php-api-stack:latest
```

#### Symfony Commands
```bash
# Cache clear
docker exec symfony-app php bin/console cache:clear

# Database migrations
docker exec symfony-app php bin/console doctrine:migrations:migrate --no-interaction

# Assets install
docker exec symfony-app php bin/console assets:install public --symlink
```

### Laravel Application

#### Project Structure
```
my-laravel-app/
├── app/
├── bootstrap/
├── config/
├── public/          ← Mount point
│   └── index.php
├── resources/
├── routes/
└── storage/
```

#### Docker Run
```bash
docker run -d \
  --name laravel-app \
  -p 8080:80 \
  -v $(pwd):/var/www/html \
  -e APP_ENV=production \
  -e APP_KEY=base64:your-app-key-here \
  -e DB_CONNECTION=mysql \
  -e DB_HOST=db \
  -e DB_DATABASE=laravel \
  -e DB_USERNAME=root \
  -e DB_PASSWORD=secret \
  kariricode/php-api-stack:latest
```

#### Laravel Commands
```bash
# Optimize
docker exec laravel-app php artisan optimize

# Cache config
docker exec laravel-app php artisan config:cache

# Migrations
docker exec laravel-app php artisan migrate --force

# Queue worker (if needed)
docker exec laravel-app supervisorctl start symfony-messenger
```

### Custom PHP Application

```bash
# Simple PHP app structure
my-app/
└── public/
    ├── index.php
    ├── api.php
    └── assets/

# Run
docker run -d \
  --name custom-php-app \
  -p 8080:80 \
  -v $(pwd)/my-app:/var/www/html \
  kariricode/php-api-stack:latest
```

## 🐳 Docker Compose

### Basic Setup

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  app:
    image: kariricode/php-api-stack:latest
    container_name: my-app
    ports:
      - "8080:80"
    volumes:
      - ./app:/var/www/html
      - ./logs:/var/log
    environment:
      - APP_ENV=production
      - PHP_MEMORY_LIMIT=512M
      - PHP_FPM_PM_MAX_CHILDREN=100
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 3s
      retries: 3
    restart: unless-stopped
```

Run:
```bash
docker-compose up -d
docker-compose logs -f
docker-compose down
```

### With Database (Symfony)

```yaml
version: '3.8'

services:
  app:
    image: kariricode/php-api-stack:latest
    container_name: symfony-app
    ports:
      - "8080:80"
    volumes:
      - ./:/var/www/html
      - ./logs:/var/log
    environment:
      - APP_ENV=prod
      - DATABASE_URL=mysql://symfony:secret@db:3306/symfony
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
    restart: unless-stopped
    networks:
      - app-network

  db:
    image: mysql:8.0
    container_name: symfony-db
    environment:
      - MYSQL_DATABASE=symfony
      - MYSQL_USER=symfony
      - MYSQL_PASSWORD=secret
      - MYSQL_ROOT_PASSWORD=root
    volumes:
      - db-data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - app-network

volumes:
  db-data:

networks:
  app-network:
    driver: bridge
```

### Production Setup

```yaml
version: '3.8'

services:
  app:
    image: kariricode/php-api-stack:stable
    container_name: prod-app
    ports:
      - "80:80"
    volumes:
      - ./app:/var/www/html:ro  # Read-only
      - ./logs:/var/log
    environment:
      - APP_ENV=production
      - APP_DEBUG=false
      - PHP_MEMORY_LIMIT=512M
      - PHP_FPM_PM=static
      - PHP_FPM_PM_MAX_CHILDREN=100
      - PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s
    restart: always
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## ☸️ Kubernetes Deployment

### Deployment

Create `k8s/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-api-stack
  labels:
    app: php-api-stack
spec:
  replicas: 3
  selector:
    matchLabels:
      app: php-api-stack
  template:
    metadata:
      labels:
        app: php-api-stack
    spec:
      containers:
      - name: app
        image: kariricode/php-api-stack:stable
        ports:
        - containerPort: 80
          name: http
        env:
        - name: APP_ENV
          value: "production"
        - name: PHP_MEMORY_LIMIT
          value: "512M"
        - name: PHP_FPM_PM_MAX_CHILDREN
          value: "100"
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        volumeMounts:
        - name: app-volume
          mountPath: /var/www/html
          readOnly: true
      volumes:
      - name: app-volume
        persistentVolumeClaim:
          claimName: app-pvc
```

### Service

Create `k8s/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: php-api-stack
spec:
  type: LoadBalancer
  selector:
    app: php-api-stack
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

### Ingress

Create `k8s/ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: php-api-stack
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: php-api-stack
            port:
              number: 80
```

### Deploy

```bash
# Apply configurations
kubectl apply -f k8s/

# Check status
kubectl get pods
kubectl get services
kubectl get ingress

# Logs
kubectl logs -f deployment/php-api-stack

# Scale
kubectl scale deployment php-api-stack --replicas=5
```

## 🏭 Production Setup

### Resource Limits

```bash
docker run -d \
  --name prod-app \
  --memory="1g" \
  --memory-swap="1g" \
  --memory-reservation="512m" \
  --cpus="2" \
  --cpu-shares=1024 \
  -p 80:80 \
  -v $(pwd)/app:/var/www/html:ro \
  kariricode/php-api-stack:stable
```

### Production Environment

```bash
docker run -d \
  --name prod-app \
  -p 80:80 \
  -v $(pwd)/app:/var/www/html:ro \
  -e APP_ENV=production \
  -e APP_DEBUG=false \
  -e PHP_DISPLAY_ERRORS=Off \
  -e PHP_MEMORY_LIMIT=512M \
  -e PHP_FPM_PM=static \
  -e PHP_FPM_PM_MAX_CHILDREN=100 \
  -e PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
  -e PHP_OPCACHE_REVALIDATE_FREQ=0 \
  kariricode/php-api-stack:stable
```

### High Availability

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  app:
    image: kariricode/php-api-stack:stable
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    ports:
      - "80:80"
    volumes:
      - ./app:/var/www/html:ro
    environment:
      - APP_ENV=production
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 3s
      retries: 3
```

## 📊 Monitoring and Health

### Health Checks

#### Simple Health Check
```bash
# Basic health
curl http://localhost:8080/health
# Response: healthy

# With details
curl -v http://localhost:8080/health
# HTTP/1.1 200 OK
# Content-Type: text/plain
# healthy
```

#### Comprehensive Health Check
```bash
# Full health report (test builds only)
curl http://localhost:8080/health.php | jq

# Check specific component
curl -s http://localhost:8080/health.php | jq '.checks.php'
curl -s http://localhost:8080/health.php | jq '.checks.opcache'
curl -s http://localhost:8080/health.php | jq '.checks.redis'
```

### PHP-FPM Status

```bash
# Status page (internal only)
docker exec my-app curl http://localhost/fpm-status

# Ping
docker exec my-app curl http://localhost/fpm-ping
# Response: pong
```

### Logs

```bash
# Application logs
docker logs -f my-app

# Nginx access logs
docker exec my-app tail -f /var/log/nginx/access.log

# Nginx error logs
docker exec my-app tail -f /var/log/nginx/error.log

# PHP error logs
docker exec my-app tail -f /var/log/php/error.log

# PHP-FPM logs
docker exec my-app tail -f /var/log/php/fpm-access.log
docker exec my-app tail -f /var/log/php/fpm-slow.log

# All logs
docker exec my-app tail -f /var/log/**/*.log
```

### Metrics

```bash
# Container stats
docker stats my-app

# OPcache stats
docker exec my-app php -r "print_r(opcache_get_status());"

# Process list
docker exec my-app ps aux

# Service status
docker exec my-app supervisorctl status
```

## ⚡ Performance Tuning

### For High Traffic

```bash
docker run -d \
  --name high-traffic-app \
  --memory="2g" \
  --cpus="4" \
  -p 80:80 \
  -v $(pwd)/app:/var/www/html:ro \
  -e PHP_MEMORY_LIMIT=512M \
  -e PHP_FPM_PM=static \
  -e PHP_FPM_PM_MAX_CHILDREN=200 \
  -e PHP_OPCACHE_MEMORY=512 \
  -e PHP_OPCACHE_MAX_FILES=50000 \
  -e NGINX_WORKER_CONNECTIONS=4096 \
  kariricode/php-api-stack:latest
```

### For Low Latency

```bash
docker run -d \
  --name low-latency-app \
  -p 80:80 \
  -v $(pwd)/app:/var/www/html:ro \
  -e PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
  -e PHP_OPCACHE_JIT=tracing \
  -e PHP_OPCACHE_JIT_BUFFER_SIZE=256M \
  -e PHP_FPM_PM=ondemand \
  -e PHP_FPM_PM_MAX_CHILDREN=50 \
  kariricode/php-api-stack:latest
```

### For Memory Efficiency

```bash
docker run -d \
  --name memory-efficient-app \
  --memory="512m" \
  -p 80:80 \
  -v $(pwd)/app:/var/www/html:ro \
  -e PHP_MEMORY_LIMIT=256M \
  -e PHP_FPM_PM=dynamic \
  -e PHP_FPM_PM_MAX_CHILDREN=25 \
  -e PHP_OPCACHE_MEMORY=128 \
  kariricode/php-api-stack:latest
```

## 🐛 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs my-app

# Common issues:
# - Port already in use → Change port: -p 8081:80
# - Volume permissions → Fix with: chmod -R 755 app/
# - Memory limits → Increase: --memory="2g"
```

### 502 Bad Gateway

```bash
# Check PHP-FPM
docker exec my-app supervisorctl status php-fpm
docker exec my-app ls -la /var/run/php/php-fpm.sock

# Restart PHP-FPM
docker exec my-app supervisorctl restart php-fpm

# Check logs
docker exec my-app tail -f /var/log/php/fpm-error.log
```

### Slow Performance

```bash
# Check OPcache
docker exec my-app php -r "
\$status = opcache_get_status();
echo 'Hit Rate: ' . \$status['opcache_statistics']['opcache_hit_rate'] . '%' . PHP_EOL;
"

# If hit rate < 90%, increase memory:
# -e PHP_OPCACHE_MEMORY=512

# Check resource usage
docker stats my-app

# Adjust PHP-FPM pool
# -e PHP_FPM_PM_MAX_CHILDREN=100
```

### Memory Issues

```bash
# Check memory usage
docker exec my-app free -h
docker exec my-app php -r "echo memory_get_usage(true);"

# Increase PHP memory limit
docker stop my-app
docker rm my-app
docker run -d \
  --name my-app \
  -e PHP_MEMORY_LIMIT=1G \
  ...
```

### Redis Connection Failed

```bash
# Check Redis
docker exec my-app redis-cli ping
# Should return: PONG

# Restart Redis
docker exec my-app supervisorctl restart redis

# Check logs
docker exec my-app tail -f /var/log/redis/redis.log
```

## 📚 Examples

### Example 1: Simple API

```bash
# Create simple API
mkdir -p my-api/public
cat > my-api/public/index.php << 'EOF'
<?php
header('Content-Type: application/json');
echo json_encode([
    'status' => 'ok',
    'message' => 'API is running',
    'php_version' => PHP_VERSION
]);
EOF

# Run
docker run -d \
  --name simple-api \
  -p 8080:80 \
  -v $(pwd)/my-api:/var/www/html \
  kariricode/php-api-stack:latest

# Test
curl http://localhost:8080
```

### Example 2: With Environment File

```bash
# Create .env.production
cat > .env.production << EOF
APP_ENV=production
APP_DEBUG=false
PHP_MEMORY_LIMIT=512M
PHP_FPM_PM_MAX_CHILDREN=100
DATABASE_URL=mysql://user:pass@db:3306/mydb
EOF

# Run with env file
docker run -d \
  --name my-app \
  -p 8080:80 \
  --env-file .env.production \
  -v $(pwd)/app:/var/www/html \
  kariricode/php-api-stack:latest
```

### Example 3: With Custom PHP Configuration

```bash
# Create custom php.ini
cat > custom-php.ini << EOF
memory_limit = 1G
max_execution_time = 300
upload_max_filesize = 200M
post_max_size = 200M
EOF

# Run with custom config
docker run -d \
  --name custom-app \
  -p 8080:80 \
  -v $(pwd)/custom-php.ini:/usr/local/etc/php/conf.d/99-custom.ini:ro \
  -v $(pwd)/app:/var/www/html \
  kariricode/php-api-stack:latest
```

## 🎓 Best Practices

### Development
- ✅ Use `latest` tag for easier updates
- ✅ Mount code as read-write (`-v $(pwd)/app:/var/www/html`)
- ✅ Enable debug mode (`APP_DEBUG=true`)
- ✅ Use hot reload tools

### Staging
- ✅ Use specific version tags (e.g., `1.2`)
- ✅ Mirror production config
- ✅ Test with production data volume
- ✅ Run load tests

### Production
- ✅ Use `stable` or specific version tags
- ✅ Mount code as read-only (`:ro`)
- ✅ Set resource limits (`--memory`, `--cpus`)
- ✅ Use health checks
- ✅ Configure log rotation
- ✅ Set up monitoring

## 📞 Support

- **Documentation**: [GitHub README](https://github.com/kariricode/php-api-stack)
- **Issues**: [Report bugs](https://github.com/kariricode/php-api-stack/issues)
- **Docker Hub**: [Image repository](https://hub.docker.com/r/kariricode/php-api-stack)
- **Discussions**: [Ask questions](https://github.com/kariricode/php-api-stack/discussions)

---

**More Info**:
- [Testing Guide](TESTING.md) - For maintainers
- [Docker Hub Guide](DOCKER_HUB.md) - For publishers
- [README](README.md) - Project overview