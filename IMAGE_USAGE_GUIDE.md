# Image Usage Guide - PHP API Stack

**Audience**: End users and developers  
**Purpose**: Complete guide for using the published Docker image  
**Version**: 1.5.0

---

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Installation](#-installation)
- [Basic Usage](#-basic-usage)
- [Configuration](#%EF%B8%8F-configuration)
- [Framework Integration](#-framework-integration)
- [Docker Compose](#-docker-compose)
- [Kubernetes Deployment](#%EF%B8%8F-kubernetes-deployment)
- [Production Setup](#-production-setup)
- [Monitoring and Health](#-monitoring-and-health)
- [Performance Tuning](#-performance-tuning)
- [Troubleshooting](#-troubleshooting)
- [Examples](#-examples)
- [Best Practices](#-best-practices)

---

## 🚀 Quick Start

### 30-Second Start

```bash
# Pull and run
docker pull kariricode/php-api-stack:latest
docker run -d -p 8080:80 --name my-app kariricode/php-api-stack:latest

# Test
curl http://localhost:8080
```

**That's it!** You'll see the demo landing page showing stack status and component information.

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

---

## 📥 Installation

### Prerequisites

- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher (optional, for multi-service setups)
- **Disk Space**: Minimum 300MB for the image

### Pull Image

```bash
# Latest stable version
docker pull kariricode/php-api-stack:latest

# Specific version (recommended for production)
docker pull kariricode/php-api-stack:1.5.0

# Development version (with Xdebug, Symfony CLI)
docker pull kariricode/php-api-stack:dev

# Verify
docker images kariricode/php-api-stack
```

### Available Tags

| Tag | Description | Size | When to Use |
|-----|-------------|------|-------------|
| `latest` | Latest stable production | ~225MB | Most cases |
| `1.5.0` | Specific version | ~225MB | Version pinning |
| `1.5` | Minor version | ~225MB | Auto-patch updates |
| `1` | Major version | ~225MB | Auto-minor updates |
| `dev` | Development build | ~244MB | Local development with debugging |
| `test` | With comprehensive health | ~216MB | Testing/Monitoring |

**Recommendation**: Use specific version tags (`1.5.0`) in production for predictability.

---

## 🎯 Basic Usage

### Standalone Container

#### Basic Run

```bash
docker run -d \
  --name my-php-app \
  -p 8080:80 \
  kariricode/php-api-stack:latest
```

#### With Application Volume

```bash
docker run -d \
  --name my-php-app \
  -p 8080:80 \
  -v $(pwd)/app:/var/www/html \
  kariricode/php-api-stack:latest
```

#### Production Setup

```bash
docker run -d \
  --name my-php-app \
  -p 80:80 \
  -v $(pwd)/app:/var/www/html:ro \
  -v $(pwd)/logs:/var/log \
  -e APP_ENV=production \
  -e APP_DEBUG=false \
  -e PHP_MEMORY_LIMIT=512M \
  -e PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
  --restart unless-stopped \
  kariricode/php-api-stack:latest
```

### Common Commands

```bash
# View logs
docker logs -f my-php-app

# Access shell
docker exec -it my-php-app bash

# Check running processes
docker exec my-php-app ps aux

# Check PHP version
docker exec my-php-app php -v

# Check PHP extensions
docker exec my-php-app php -m

# Stop container
docker stop my-php-app

# Remove container
docker rm my-php-app

# Restart container
docker restart my-php-app
```

### Service Management

Services are managed by the custom entrypoint script:

```bash
# View all processes
docker exec my-php-app ps aux | grep -E "(nginx|php-fpm|redis)"

# Nginx
docker exec my-php-app nginx -t          # Test config
docker exec my-php-app nginx -s reload   # Reload config

# PHP-FPM
docker exec my-php-app php-fpm -t        # Test config
docker exec my-php-app kill -USR2 $(cat /var/run/php/php-fpm.pid)  # Reload

# Redis
docker exec my-php-app redis-cli ping    # Test connection
docker exec my-php-app redis-cli info    # Get info
```

---

## ⚙️ Configuration

### Environment Variables

#### Application Settings

```bash
# Environment and debug
-e APP_ENV=production                    # production|development|test
-e APP_DEBUG=false                       # Enable/disable debug mode
-e APP_NAME=my-application              # Application name
```

#### PHP Runtime Settings

```bash
# Memory and execution
-e PHP_MEMORY_LIMIT=512M                 # Memory limit per request
-e PHP_MAX_EXECUTION_TIME=60             # Script execution timeout
-e PHP_MAX_INPUT_TIME=60                 # Input parsing timeout
-e PHP_POST_MAX_SIZE=100M                # Max POST data size
-e PHP_UPLOAD_MAX_FILESIZE=100M          # Max file upload size

# Error handling
-e PHP_DISPLAY_ERRORS=Off                # Display errors (On for dev)
-e PHP_ERROR_LOG=/var/log/php/error.log  # Error log path
-e PHP_LOG_ERRORS=On                     # Enable error logging

# Timezone
-e PHP_DATE_TIMEZONE=UTC                 # Default timezone
```

#### PHP-FPM Pool Configuration

```bash
# Process manager mode
-e PHP_FPM_PM=dynamic                    # static|dynamic|ondemand

# Dynamic mode settings
-e PHP_FPM_PM_MAX_CHILDREN=60            # Maximum child processes
-e PHP_FPM_PM_START_SERVERS=10           # Initial server count
-e PHP_FPM_PM_MIN_SPARE_SERVERS=5        # Minimum idle servers
-e PHP_FPM_PM_MAX_SPARE_SERVERS=20       # Maximum idle servers
-e PHP_FPM_PM_MAX_REQUESTS=500           # Max requests per child

# Static mode (for production with predictable load)
-e PHP_FPM_PM=static
-e PHP_FPM_PM_MAX_CHILDREN=100           # Fixed number of children
```

#### OPcache Configuration

```bash
# Enable/disable
-e PHP_OPCACHE_ENABLE=1                  # 1=enabled, 0=disabled

# Memory settings
-e PHP_OPCACHE_MEMORY=256                # Memory consumption (MB)
-e PHP_OPCACHE_MAX_ACCELERATED_FILES=20000  # Max cached files

# Validation (0 for production, 1 for development)
-e PHP_OPCACHE_VALIDATE_TIMESTAMPS=0     # 0=never revalidate, 1=check mtimes
-e PHP_OPCACHE_REVALIDATE_FREQ=0         # Revalidation frequency (seconds)

# JIT configuration
-e PHP_OPCACHE_JIT=tracing               # off|tracing|function
-e PHP_OPCACHE_JIT_BUFFER_SIZE=128M      # JIT buffer size
```

#### Nginx Configuration

```bash
# Worker configuration
-e NGINX_WORKER_PROCESSES=auto           # auto = CPU cores
-e NGINX_WORKER_CONNECTIONS=2048         # Connections per worker

# Timeouts
-e NGINX_KEEPALIVE_TIMEOUT=65            # Keep-alive timeout (seconds)
-e NGINX_CLIENT_BODY_TIMEOUT=60          # Client body timeout
-e NGINX_SEND_TIMEOUT=60                 # Send timeout

# Limits
-e NGINX_CLIENT_MAX_BODY_SIZE=20M        # Max upload size
```

#### Redis Configuration

```bash
# Connection (standalone mode)
-e REDIS_HOST=127.0.0.1                  # Redis host
-e REDIS_PASSWORD=your-password          # Redis password
-e REDIS_DATABASES=16                    # Number of databases

# Memory settings
-e REDIS_MAXMEMORY=256mb                 # Max memory usage
-e REDIS_MAXMEMORY_POLICY=allkeys-lru    # Eviction policy

# Persistence
-e REDIS_APPENDONLY=yes                  # Enable AOF persistence
-e REDIS_APPENDFSYNC=everysec            # Fsync frequency
```

**Note**: When using Docker Compose, `REDIS_HOST` should be set to the service name (e.g., `redis`). For standalone containers, it uses `127.0.0.1` (internal Redis).

### Volume Mounts

#### Application Code

```bash
# Development (read-write)
-v $(pwd)/app:/var/www/html

# Production (read-only)
-v $(pwd)/app:/var/www/html:ro
```

#### Logs

```bash
# Export logs to host
-v $(pwd)/logs:/var/log

# Then access:
# - $(pwd)/logs/nginx/access.log
# - $(pwd)/logs/nginx/error.log
# - $(pwd)/logs/php/error.log
# - $(pwd)/logs/redis/redis.log
```

#### Custom Configurations

```bash
# Custom PHP configuration
-v $(pwd)/custom-php.ini:/usr/local/etc/php/conf.d/99-custom.ini:ro

# Custom Nginx configuration
-v $(pwd)/custom-nginx.conf:/etc/nginx/conf.d/custom.conf:ro

# Custom Redis configuration (if needed)
-v $(pwd)/custom-redis.conf:/etc/redis/redis-custom.conf:ro
```

### Network Configuration

```bash
# Create custom network
docker network create my-app-network

# Run container in network
docker run -d \
  --name my-php-app \
  --network my-app-network \
  -p 8080:80 \
  kariricode/php-api-stack:latest

# Connect another container
docker run -d \
  --name mysql \
  --network my-app-network \
  -e MYSQL_ROOT_PASSWORD=secret \
  mysql:8.0
```

---

## 🚀 Framework Integration

### Symfony Application

#### Project Structure

```
my-symfony-app/
├── bin/
├── config/
├── public/          ← Document root (Nginx serves from here)
│   └── index.php
├── src/
├── var/
│   ├── cache/
│   └── log/
├── vendor/
├── .env
└── composer.json
```

#### Docker Run

```bash
docker run -d \
  --name symfony-app \
  -p 8080:80 \
  -v $(pwd):/var/www/html \
  -e APP_ENV=prod \
  -e APP_SECRET=$(openssl rand -hex 16) \
  -e DATABASE_URL="mysql://user:pass@db:3306/symfony" \
  kariricode/php-api-stack:latest
```

#### With Database

```bash
# Create network
docker network create symfony-network

# Run MySQL
docker run -d \
  --name symfony-db \
  --network symfony-network \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=symfony \
  -e MYSQL_USER=symfony \
  -e MYSQL_PASSWORD=symfony \
  mysql:8.0

# Run Symfony app
docker run -d \
  --name symfony-app \
  --network symfony-network \
  -p 8080:80 \
  -v $(pwd):/var/www/html \
  -e APP_ENV=prod \
  -e DATABASE_URL="mysql://symfony:symfony@symfony-db:3306/symfony" \
  kariricode/php-api-stack:latest
```

#### Common Symfony Commands

```bash
# Cache operations
docker exec symfony-app php bin/console cache:clear
docker exec symfony-app php bin/console cache:warmup

# Database
docker exec symfony-app php bin/console doctrine:database:create
docker exec symfony-app php bin/console doctrine:migrations:migrate --no-interaction

# Assets
docker exec symfony-app php bin/console assets:install public --symlink

# Debug
docker exec symfony-app php bin/console debug:router
docker exec symfony-app php bin/console debug:container
```

### Laravel Application

#### Project Structure

```
my-laravel-app/
├── app/
├── bootstrap/
├── config/
├── database/
├── public/          ← Document root (Nginx serves from here)
│   └── index.php
├── resources/
├── routes/
├── storage/
│   ├── app/
│   ├── framework/
│   └── logs/
├── vendor/
├── .env
└── composer.json
```

#### Docker Run

```bash
docker run -d \
  --name laravel-app \
  -p 8080:80 \
  -v $(pwd):/var/www/html \
  -e APP_ENV=production \
  -e APP_KEY=$(php -r "echo 'base64:'.base64_encode(random_bytes(32));") \
  -e DB_CONNECTION=mysql \
  -e DB_HOST=db \
  -e DB_DATABASE=laravel \
  -e DB_USERNAME=laravel \
  -e DB_PASSWORD=secret \
  kariricode/php-api-stack:latest
```

#### With Database and Redis

```bash
# Create network
docker network create laravel-network

# Run MySQL
docker run -d \
  --name laravel-db \
  --network laravel-network \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=laravel \
  -e MYSQL_USER=laravel \
  -e MYSQL_PASSWORD=secret \
  mysql:8.0

# Run Redis (external)
docker run -d \
  --name laravel-redis \
  --network laravel-network \
  redis:7-alpine

# Run Laravel app
docker run -d \
  --name laravel-app \
  --network laravel-network \
  -p 8080:80 \
  -v $(pwd):/var/www/html \
  -e APP_ENV=production \
  -e APP_KEY=base64:your-key-here \
  -e DB_CONNECTION=mysql \
  -e DB_HOST=laravel-db \
  -e DB_DATABASE=laravel \
  -e DB_USERNAME=laravel \
  -e DB_PASSWORD=secret \
  -e CACHE_DRIVER=redis \
  -e SESSION_DRIVER=redis \
  -e QUEUE_CONNECTION=redis \
  -e REDIS_HOST=laravel-redis \
  kariricode/php-api-stack:latest
```

**Note**: The container has an internal Redis instance on `127.0.0.1:6379`. For external Redis (as shown above), use the container name as host.

#### Common Laravel Commands

```bash
# Optimization
docker exec laravel-app php artisan optimize
docker exec laravel-app php artisan config:cache
docker exec laravel-app php artisan route:cache
docker exec laravel-app php artisan view:cache

# Database
docker exec laravel-app php artisan migrate --force
docker exec laravel-app php artisan db:seed --force

# Queue worker (run in background)
docker exec -d laravel-app php artisan queue:work --tries=3

# Cache
docker exec laravel-app php artisan cache:clear
docker exec laravel-app php artisan config:clear
```

### Custom PHP Application

```bash
# Simple PHP app structure
my-app/
├── public/
│   ├── index.php
│   ├── api.php
│   └── assets/
│       ├── css/
│       └── js/
├── src/
│   └── App.php
├── vendor/
└── composer.json

# Run
docker run -d \
  --name custom-php-app \
  -p 8080:80 \
  -v $(pwd)/my-app:/var/www/html \
  kariricode/php-api-stack:latest
```

---

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
      APP_ENV: production
      PHP_MEMORY_LIMIT: 512M
      PHP_FPM_PM_MAX_CHILDREN: 100
      REDIS_HOST: 127.0.0.1  # Using internal Redis
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 3s
      retries: 3
    restart: unless-stopped
```

Commands:

```bash
docker-compose up -d        # Start
docker-compose logs -f      # View logs
docker-compose ps           # Status
docker-compose down         # Stop
docker-compose restart app  # Restart service
```

### With External Database

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
      APP_ENV: prod
      DATABASE_URL: mysql://symfony:secret@db:3306/symfony
      REDIS_HOST: 127.0.0.1  # Internal Redis
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
      MYSQL_DATABASE: symfony
      MYSQL_USER: symfony
      MYSQL_PASSWORD: secret
      MYSQL_ROOT_PASSWORD: root
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

### Production Configuration

```yaml
version: '3.8'

services:
  app:
    image: kariricode/php-api-stack:1.5.0  # Pin version
    container_name: prod-app
    ports:
      - "80:80"
    volumes:
      - ./app:/var/www/html:ro  # Read-only
      - ./logs:/var/log
    environment:
      APP_ENV: production
      APP_DEBUG: "false"
      PHP_MEMORY_LIMIT: 512M
      PHP_FPM_PM: static
      PHP_FPM_PM_MAX_CHILDREN: 100
      PHP_OPCACHE_VALIDATE_TIMESTAMPS: "0"
      PHP_OPCACHE_JIT: tracing
      REDIS_HOST: 127.0.0.1
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
    networks:
      - prod-network

networks:
  prod-network:
    driver: bridge
```

---

## ☸️ Kubernetes Deployment

### Deployment Manifest

Create `k8s/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-api-stack
  labels:
    app: php-api-stack
    version: v1.5.0
spec:
  replicas: 3
  selector:
    matchLabels:
      app: php-api-stack
  template:
    metadata:
      labels:
        app: php-api-stack
        version: v1.5.0
    spec:
      containers:
      - name: app
        image: kariricode/php-api-stack:1.5.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
          name: http
          protocol: TCP
        env:
        - name: APP_ENV
          value: "production"
        - name: PHP_MEMORY_LIMIT
          value: "512M"
        - name: PHP_FPM_PM
          value: "static"
        - name: PHP_FPM_PM_MAX_CHILDREN
          value: "100"
        - name: PHP_OPCACHE_VALIDATE_TIMESTAMPS
          value: "0"
        - name: REDIS_HOST
          value: "127.0.0.1"  # Using internal Redis
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
            scheme: HTTP
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 80
            scheme: HTTP
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 3
        volumeMounts:
        - name: app-volume
          mountPath: /var/www/html
          readOnly: true
        - name: logs-volume
          mountPath: /var/log
      volumes:
      - name: app-volume
        persistentVolumeClaim:
          claimName: app-pvc
      - name: logs-volume
        emptyDir: {}
```

### Service Manifest

Create `k8s/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: php-api-stack
  labels:
    app: php-api-stack
spec:
  type: ClusterIP
  selector:
    app: php-api-stack
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
```

### Ingress Manifest

Create `k8s/ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: php-api-stack
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls-secret
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

### HorizontalPodAutoscaler

Create `k8s/hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-api-stack-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-api-stack
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Deploy to Kubernetes

```bash
# Apply all configurations
kubectl apply -f k8s/

# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get services
kubectl get ingress

# View logs
kubectl logs -f deployment/php-api-stack

# Scale manually
kubectl scale deployment php-api-stack --replicas=5

# Check autoscaling
kubectl get hpa

# Port-forward for local testing
kubectl port-forward deployment/php-api-stack 8080:80
```

---

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
  -e APP_ENV=production \
  -e PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
  kariricode/php-api-stack:1.5.0
```

### Production Environment Variables

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
  -e PHP_OPCACHE_ENABLE=1 \
  -e PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
  -e PHP_OPCACHE_REVALIDATE_FREQ=0 \
  -e PHP_OPCACHE_JIT=tracing \
  -e PHP_OPCACHE_JIT_BUFFER_SIZE=256M \
  --restart unless-stopped \
  kariricode/php-api-stack:1.5.0
```

### High Availability with Docker Swarm

```bash
# Initialize swarm
docker swarm init

# Create stack file: docker-stack.yml
cat > docker-stack.yml << 'EOF'
version: '3.8'

services:
  app:
    image: kariricode/php-api-stack:1.5.0
    deploy:
      replicas: 5
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
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
      - app-data:/var/www/html:ro
    environment:
      APP_ENV: production
      PHP_FPM_PM: static
      PHP_FPM_PM_MAX_CHILDREN: 100
      PHP_OPCACHE_VALIDATE_TIMESTAMPS: 0
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 3s
      retries: 3

volumes:
  app-data:
    driver: local
EOF

# Deploy stack
docker stack deploy -c docker-stack.yml prod-stack

# Check services
docker service ls
docker service ps prod-stack_app

# Scale
docker service scale prod-stack_app=10

# Update image (zero-downtime)
docker service update --image kariricode/php-api-stack:1.5.1 prod-stack_app

# Remove stack
docker stack rm prod-stack
```

---

## 📊 Monitoring and Health

### Health Check Endpoints

#### Simple Health Check (Production)

```bash
# Basic health status
curl http://localhost:8080/health

# Response: healthy

# With details (HTTP status)
curl -v http://localhost:8080/health
# HTTP/1.1 200 OK
# Content-Type: text/plain
# Content-Length: 7
#
# healthy
```

**Use case**: Load balancers, Kubernetes liveness probes, Docker healthchecks

#### Comprehensive Health Check

```bash
# Full system diagnostics
curl http://localhost:8080/health.php | jq

# Response includes:
# - Overall status (healthy/degraded/unhealthy)
# - PHP runtime details
# - OPcache statistics
# - Redis connectivity
# - System resources
# - Application directories
```

**Sample response**:

```json
{
  "status": "healthy",
  "timestamp": "2025-10-24T22:00:00+00:00",
  "overall": "✓ All Systems Operational",
  "components": {
    "php": {
      "status": "healthy",
      "details": {
        "version": "8.4.13",
        "memory_limit": "512M",
        "max_execution_time": "60"
      }
    },
    "opcache": {
      "status": "healthy",
      "details": {
        "enabled": true,
        "hit_rate": 99.87,
        "memory_used": "45.2 MB",
        "jit_enabled": true
      }
    },
    "redis": {
      "status": "healthy",
      "details": {
        "connected": true,
        "version": "7.2.11",
        "latency_ms": 0.5
      }
    }
  }
}
```

### Checking Components

```bash
# PHP version and extensions
docker exec my-app php -v
docker exec my-app php -m

# OPcache status
docker exec my-app php -r "print_r(opcache_get_status());"

# Redis connectivity
docker exec my-app redis-cli -h 127.0.0.1 ping
# PONG

# Redis info
docker exec my-app redis-cli -h 127.0.0.1 info server

# Nginx status
docker exec my-app nginx -t
docker exec my-app nginx -V

# Process list
docker exec my-app ps aux
```

### Log Access

```bash
# Real-time logs
docker logs -f my-app

# Nginx access log
docker exec my-app tail -f /var/log/nginx/access.log

# Nginx error log
docker exec my-app tail -f /var/log/nginx/error.log

# PHP error log
docker exec my-app tail -f /var/log/php/error.log

# PHP-FPM access log
docker exec my-app tail -f /var/log/php/fpm-access.log

# PHP-FPM slow log
docker exec my-app tail -f /var/log/php/fpm-slow.log

# Redis log
docker exec my-app tail -f /var/log/redis/redis.log

# All logs simultaneously
docker exec my-app tail -f /var/log/**/*.log
```

### Metrics and Statistics

```bash
# Container resource usage
docker stats my-app

# Container inspect (detailed info)
docker inspect my-app

# OPcache statistics
docker exec my-app php -r "
\$status = opcache_get_status();
echo 'Memory Used: ' . \$status['memory_usage']['used_memory'] / 1024 / 1024 . ' MB' . PHP_EOL;
echo 'Hit Rate: ' . \$status['opcache_statistics']['opcache_hit_rate'] . '%' . PHP_EOL;
echo 'Cached Scripts: ' . \$status['opcache_statistics']['num_cached_scripts'] . PHP_EOL;
"

# Redis statistics
docker exec my-app redis-cli -h 127.0.0.1 info stats
docker exec my-app redis-cli -h 127.0.0.1 info memory
```

---

## ⚡ Performance Tuning

### High Traffic Configuration

For applications with heavy load (100+ req/s):

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
  -e PHP_OPCACHE_ENABLE=1 \
  -e PHP_OPCACHE_MEMORY=512 \
  -e PHP_OPCACHE_MAX_ACCELERATED_FILES=50000 \
  -e PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
  -e PHP_OPCACHE_JIT=tracing \
  -e PHP_OPCACHE_JIT_BUFFER_SIZE=256M \
  -e NGINX_WORKER_PROCESSES=auto \
  -e NGINX_WORKER_CONNECTIONS=4096 \
  kariricode/php-api-stack:latest
```

### Low Latency Configuration

For API with strict latency requirements (<50ms):

```bash
docker run -d \
  --name low-latency-app \
  --memory="1g" \
  --cpus="2" \
  -p 80:80 \
  -v $(pwd)/app:/var/www/html:ro \
  -e PHP_MEMORY_LIMIT=256M \
  -e PHP_FPM_PM=ondemand \
  -e PHP_FPM_PM_MAX_CHILDREN=50 \
  -e PHP_FPM_PM_PROCESS_IDLE_TIMEOUT=10s \
  -e PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
  -e PHP_OPCACHE_JIT=tracing \
  -e PHP_OPCACHE_JIT_BUFFER_SIZE=256M \
  -e NGINX_KEEPALIVE_TIMEOUT=30 \
  kariricode/php-api-stack:latest
```

### Memory-Constrained Environment

For environments with limited memory (<512MB):

```bash
docker run -d \
  --name memory-efficient-app \
  --memory="512m" \
  --memory-swap="512m" \
  -p 80:80 \
  -v $(pwd)/app:/var/www/html:ro \
  -e PHP_MEMORY_LIMIT=128M \
  -e PHP_FPM_PM=dynamic \
  -e PHP_FPM_PM_MAX_CHILDREN=25 \
  -e PHP_FPM_PM_START_SERVERS=5 \
  -e PHP_FPM_PM_MIN_SPARE_SERVERS=2 \
  -e PHP_FPM_PM_MAX_SPARE_SERVERS=10 \
  -e PHP_OPCACHE_MEMORY=64 \
  -e PHP_OPCACHE_JIT_BUFFER_SIZE=32M \
  kariricode/php-api-stack:latest
```

### Performance Monitoring

```bash
# Real-time resource monitoring
docker stats my-app --no-stream

# OPcache hit rate (should be >95%)
docker exec my-app php -r "
\$stats = opcache_get_status()['opcache_statistics'];
echo 'Hit Rate: ' . round(\$stats['opcache_hit_rate'], 2) . '%' . PHP_EOL;
echo 'Misses: ' . \$stats['misses'] . PHP_EOL;
echo 'Hits: ' . \$stats['hits'] . PHP_EOL;
"

# PHP-FPM pool status (if status page is enabled)
docker exec my-app curl -s http://localhost/fpm-status | jq

# Request timing (add to Nginx config for detailed timing)
docker exec my-app tail -f /var/log/nginx/access.log | \
  awk '{print $NF}' | \
  awk 'BEGIN{sum=0;count=0} {sum+=$1;count++} END{print "Avg:", sum/count, "Count:", count}'
```

---

## 🐛 Troubleshooting

### Container Won't Start

**Symptoms**: Container exits immediately after starting

```bash
# Check logs
docker logs my-app

# Common issues and solutions:

# 1. Port already in use
# Error: "bind: address already in use"
# Solution: Use different port
docker run -d -p 8081:80 ... kariricode/php-api-stack:latest

# 2. Volume mount permission issues
# Error: "Permission denied"
# Solution: Fix permissions
chmod -R 755 app/
chown -R $(id -u):$(id -g) app/

# 3. Invalid environment variables
# Error: "Invalid PHP_MEMORY_LIMIT"
# Solution: Check format (e.g., "512M" not "512")

# 4. Memory limit too low
# Solution: Increase Docker memory limit
docker run -d --memory="1g" ... kariricode/php-api-stack:latest
```

### 502 Bad Gateway

**Symptoms**: Nginx returns 502 error

```bash
# Check if PHP-FPM is running
docker exec my-app ps aux | grep php-fpm

# Check PHP-FPM socket
docker exec my-app ls -la /var/run/php/php-fpm.sock
# Should show: srw-rw---- 1 www-data www-data

# Test PHP-FPM configuration
docker exec my-app php-fpm -t

# Check PHP-FPM logs
docker exec my-app tail -50 /var/log/php/fpm-error.log

# Check Nginx error log
docker exec my-app tail -50 /var/log/nginx/error.log

# Restart PHP-FPM
docker exec my-app kill -USR2 $(cat /var/run/php/php-fpm.pid)

# If problem persists, restart container
docker restart my-app
```

### Redis Connection Issues

**Symptoms**: Application can't connect to Redis

#### Standalone Container Mode

```bash
# Check if Redis is running
docker exec my-app ps aux | grep redis
# Should show: redis-server 0.0.0.0:6379

# Verify REDIS_HOST environment variable
docker exec my-app env | grep REDIS_HOST
# Should be: REDIS_HOST=127.0.0.1

# Test Redis connection
docker exec my-app redis-cli -h 127.0.0.1 ping
# Should return: PONG

# Test with password (if configured)
docker exec my-app redis-cli -h 127.0.0.1 -a "your-password" ping

# Check Redis logs
docker exec my-app tail -f /var/log/redis/redis.log
```

#### Docker Compose Mode

```bash
# Check if redis service is running
docker-compose ps redis

# Verify REDIS_HOST points to service name
docker-compose exec app env | grep REDIS_HOST
# Should be: REDIS_HOST=redis (service name)

# Test connection from app container
docker-compose exec app redis-cli -h redis ping
# Should return: PONG

# Check network connectivity
docker-compose exec app ping -c 3 redis
```

### Slow Performance

**Symptoms**: Requests take longer than expected

```bash
# 1. Check OPcache hit rate
docker exec my-app php -r "
\$status = opcache_get_status();
\$hit_rate = \$status['opcache_statistics']['opcache_hit_rate'];
echo 'OPcache Hit Rate: ' . round(\$hit_rate, 2) . '%' . PHP_EOL;
if (\$hit_rate < 90) {
    echo 'WARNING: Hit rate is low. Increase PHP_OPCACHE_MEMORY' . PHP_EOL;
}
"

# 2. Check resource usage
docker stats my-app --no-stream

# 3. Check PHP-FPM pool
docker exec my-app cat /var/run/php/php-fpm.pid
docker exec my-app kill -USR1 $(cat /var/run/php/php-fpm.pid)  # Get pool status

# 4. Enable slow log analysis
docker exec my-app tail -f /var/log/php/fpm-slow.log

# Solutions:
# - Increase OPcache memory: -e PHP_OPCACHE_MEMORY=512
# - Increase FPM children: -e PHP_FPM_PM_MAX_CHILDREN=100
# - Add more CPU/memory to container
# - Enable JIT: -e PHP_OPCACHE_JIT=tracing
```

### High Memory Usage

**Symptoms**: Container uses excessive memory

```bash
# Check memory usage
docker stats my-app --no-stream

# Check PHP memory limit
docker exec my-app php -r "echo ini_get('memory_limit') . PHP_EOL;"

# Check OPcache memory
docker exec my-app php -r "
\$status = opcache_get_status();
\$memory = \$status['memory_usage'];
echo 'Used: ' . round(\$memory['used_memory'] / 1024 / 1024, 2) . ' MB' . PHP_EOL;
echo 'Free: ' . round(\$memory['free_memory'] / 1024 / 1024, 2) . ' MB' . PHP_EOL;
echo 'Wasted: ' . round(\$memory['wasted_memory'] / 1024 / 1024, 2) . ' MB' . PHP_EOL;
"

# Solutions:
# - Reduce PHP memory limit: -e PHP_MEMORY_LIMIT=256M
# - Reduce FPM children: -e PHP_FPM_PM_MAX_CHILDREN=30
# - Use dynamic PM mode: -e PHP_FPM_PM=dynamic
# - Set container memory limit: --memory="512m"
```

### Permission Issues

**Symptoms**: Application can't write to directories

```bash
# Check current ownership
docker exec my-app ls -la /var/www/html

# Fix ownership (application directories)
docker exec my-app chown -R www-data:www-data /var/www/html/var
docker exec my-app chown -R www-data:www-data /var/www/html/storage

# Fix permissions
docker exec my-app chmod -R 775 /var/www/html/var
docker exec my-app chmod -R 775 /var/www/html/storage

# From host (if volume mounted)
sudo chown -R $(id -u):$(id -g) app/var
sudo chmod -R 775 app/var
```

### Nginx Configuration Issues

```bash
# Test Nginx configuration
docker exec my-app nginx -t

# Reload Nginx (after config changes)
docker exec my-app nginx -s reload

# Check Nginx error log
docker exec my-app tail -100 /var/log/nginx/error.log

# View current configuration
docker exec my-app cat /etc/nginx/nginx.conf
docker exec my-app cat /etc/nginx/conf.d/default.conf
```

### Debug Mode

Enable debug mode for troubleshooting:

```bash
docker run -d \
  --name debug-app \
  -p 8080:80 \
  -v $(pwd)/app:/var/www/html \
  -e APP_ENV=development \
  -e APP_DEBUG=true \
  -e PHP_DISPLAY_ERRORS=On \
  -e PHP_ERROR_REPORTING=E_ALL \
  -e PHP_OPCACHE_VALIDATE_TIMESTAMPS=1 \
  kariricode/php-api-stack:dev  # Use dev image for Xdebug
```

---

## 📚 Examples

### Example 1: Simple REST API

```bash
# Create simple API structure
mkdir -p my-api/public
cat > my-api/public/index.php << 'EOF'
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$response = [
    'status' => 'success',
    'message' => 'API is running',
    'timestamp' => time(),
    'php_version' => PHP_VERSION,
    'server' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'
];

echo json_encode($response, JSON_PRETTY_PRINT);
EOF

# Run
docker run -d \
  --name simple-api \
  -p 8080:80 \
  -v $(pwd)/my-api:/var/www/html \
  kariricode/php-api-stack:latest

# Test
curl http://localhost:8080 | jq
```

### Example 2: With Environment File

```bash
# Create .env.production
cat > .env.production << 'EOF'
APP_ENV=production
APP_DEBUG=false
PHP_MEMORY_LIMIT=512M
PHP_FPM_PM=static
PHP_FPM_PM_MAX_CHILDREN=100
PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
DATABASE_URL=mysql://user:pass@db:3306/mydb
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=secure-password
EOF

# Run with env file
docker run -d \
  --name my-app \
  -p 8080:80 \
  --env-file .env.production \
  -v $(pwd)/app:/var/www/html \
  kariricode/php-api-stack:latest
```

### Example 3: Multi-Stage Development

```bash
# Development
docker run -d \
  --name dev-app \
  -p 8001:80 \
  -v $(pwd)/app:/var/www/html \
  -e APP_ENV=development \
  -e APP_DEBUG=true \
  -e PHP_DISPLAY_ERRORS=On \
  -e PHP_OPCACHE_VALIDATE_TIMESTAMPS=1 \
  kariricode/php-api-stack:dev

# Staging
docker run -d \
  --name staging-app \
  -p 8002:80 \
  -v $(pwd)/app:/var/www/html:ro \
  -e APP_ENV=staging \
  -e APP_DEBUG=false \
  -e PHP_OPCACHE_VALIDATE_TIMESTAMPS=1 \
  kariricode/php-api-stack:latest

# Production
docker run -d \
  --name prod-app \
  -p 80:80 \
  -v $(pwd)/app:/var/www/html:ro \
  -e APP_ENV=production \
  -e APP_DEBUG=false \
  -e PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
  --restart unless-stopped \
  kariricode/php-api-stack:1.5.0
```

### Example 4: Health Check Integration

```bash
# With Docker healthcheck
docker run -d \
  --name monitored-app \
  -p 8080:80 \
  -v $(pwd)/app:/var/www/html \
  --health-cmd="curl -f http://localhost/health || exit 1" \
  --health-interval=30s \
  --health-timeout=3s \
  --health-retries=3 \
  --health-start-period=5s \
  kariricode/php-api-stack:latest

# Check health status
docker inspect --format='{{.State.Health.Status}}' monitored-app
```

---

## 🎓 Best Practices

### Development

- ✅ Use `dev` tag for full debugging capabilities
- ✅ Mount code read-write: `-v $(pwd)/app:/var/www/html`
- ✅ Enable debug mode: `-e APP_DEBUG=true`
- ✅ Enable OPcache timestamp validation: `-e PHP_OPCACHE_VALIDATE_TIMESTAMPS=1`
- ✅ Use local network for multi-container setup
- ✅ Keep dependencies up to date with Composer

### Staging

- ✅ Use specific version tags (e.g., `1.5`)
- ✅ Mirror production configuration
- ✅ Mount code read-only: `-v $(pwd)/app:/var/www/html:ro`
- ✅ Test with production-like data volumes
- ✅ Run load and performance tests
- ✅ Validate health checks work correctly

### Production

- ✅ **Always** pin specific versions: `kariricode/php-api-stack:1.5.0`
- ✅ **Always** mount code read-only: `:ro`
- ✅ Set resource limits: `--memory`, `--cpus`
- ✅ Disable OPcache validation: `-e PHP_OPCACHE_VALIDATE_TIMESTAMPS=0`
- ✅ Use static PM mode for predictable load: `-e PHP_FPM_PM=static`
- ✅ Enable health checks
- ✅ Configure proper logging and monitoring
- ✅ Use `--restart unless-stopped` or `always`
- ✅ Store logs externally: `-v $(pwd)/logs:/var/log`
- ✅ Never use `latest` tag in production
- ✅ Plan for zero-downtime deployments

### Security

- ✅ Never run as root (container uses `www-data` by default)
- ✅ Use read-only filesystem where possible
- ✅ Keep secrets in environment variables, not in code
- ✅ Regularly update to latest patch versions
- ✅ Use HTTPS/TLS in production (via reverse proxy)
- ✅ Implement rate limiting at the proxy level
- ✅ Monitor container for vulnerabilities

---

## 📞 Support & Resources

### Documentation

- **Main README**: [GitHub README](https://github.com/kariricode/php-api-stack)
- **Docker Compose Guide**: [DOCKER_COMPOSE_GUIDE.md](DOCKER_COMPOSE_GUIDE.md)
- **Testing Guide**: [TESTING.md](TESTING.md) - For maintainers
- **Docker Hub Guide**: [DOCKER_HUB.md](DOCKER_HUB.md) - For publishers

### Community

- **Issues**: [Report bugs](https://github.com/kariricode/php-api-stack/issues)
- **Discussions**: [Ask questions](https://github.com/kariricode/php-api-stack/discussions)
- **Docker Hub**: [Image repository](https://hub.docker.com/r/kariricode/php-api-stack)

### Quick Links

- [PHP 8.4 Documentation](https://www.php.net/docs.php)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Symfony Deployment](https://symfony.com/doc/current/deployment.html)
- [Laravel Deployment](https://laravel.com/docs/deployment)

---

**Version**: 1.5.0  
**Last Updated**: 2025-10-24  
**Made with 💚 by [KaririCode](https://kariricode.org)**