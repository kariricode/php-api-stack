# PHP API Stack - Complete Guide

[![Docker Hub](https://img.shields.io/docker/v/kariricode/php-api-stack?label=Docker%20Hub&logo=docker)](https://hub.docker.com/r/kariricode/php-api-stack)
[![PHP Version](https://img.shields.io/badge/PHP-8.4-777BB4?logo=php)](https://www.php.net/)
[![Nginx Version](https://img.shields.io/badge/Nginx-1.27.3-009639?logo=nginx)](https://nginx.org/)
[![Redis Version](https://img.shields.io/badge/Redis-7.2-DC382D?logo=redis)](https://redis.io/)
[![Health Check](https://img.shields.io/badge/Health%20Check-Comprehensive-brightgreen)](#-comprehensive-health-check)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kariricode/php-api-stack)

## 🚀 Quick Start

```bash
# Option 1: Use pre-built image from Docker Hub
docker run -d -p 8080:80 -v $(pwd):/var/www/html kariricode/php-api-stack:latest

# Option 2: Local build with Make
git clone https://github.com/kariricode/php-api-stack.git
cd php-api-stack
make build-test
make run

# Option 3: Build with Comprehensive Health Check (Testing)
make run-test
curl http://localhost:8080/health.php | jq

# Option 4: Docker Compose
curl -O https://raw.githubusercontent.com/kariricode/php-api-stack/main/docker-compose.yml
docker-compose up -d
```

Access: http://localhost:8080

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Project Structure](#-project-structure)
- [Installation and Build](#-installation-and-build)
- [Configuration](#-configuration)
- [Using the Image](#-using-the-image)
- [PHP Extensions](#-php-extensions)
- [Automated Testing](#-automated-testing)
- [Debug and Troubleshooting](#-debug-and-troubleshooting)
- [Comprehensive Health Check](#-comprehensive-health-check)
- [Local Development](#-local-development)
- [Development vs Production](#-development-vs-production)
- [Versioning](#-versioning)
- [Performance Optimizations](#-performance-optimizations)
- [Security](#-security)
- [Monitoring](#-monitoring)
- [FAQ](#-faq)
- [Use Cases and Best Practices](#-use-cases-and-best-practices)
- [References](#-references)

## 🎯 Overview

**PHP API Stack** is a production-optimized Docker image providing a complete stack for PHP applications, especially optimized for Symfony and REST APIs. This image combines DevOps best practices with robust components and optimized configurations.

### Key Features

- 🚀 **Complete Stack**: PHP-FPM + Nginx + Redis + Supervisor
- ⚡ **Optimized Performance**: OPcache, JIT, FastCGI cache
- 🔧 **Flexible Configuration**: Fully customizable via environment variables
- 🛡️ **Enhanced Security**: Security headers, rate limiting, hardened configurations
- 📊 **Integrated Monitoring**: Health checks, metrics, structured logs
- 🏥 **Comprehensive Health Check**: SOLID-based validation system
- 🐳 **Multi-stage Build**: Optimized and reduced image size
- 📄 **CI/CD Ready**: Automated scripts for build and deploy
- ✅ **Automatic Validation**: Configuration processing and validation on startup

## 🗃️ Architecture

### Stack Components

| Component | Version | Function |
|-----------|---------|----------|
| **PHP-FPM** | 8.4 | PHP processing with optimized pool |
| **Nginx** | 1.27.3 | High-performance web server |
| **Redis** | 7.2 | Cache and session management |
| **Supervisor** | Latest | Process manager |
| **Composer** | 2.8.12 | PHP dependency manager |
| **Symfony CLI** | 7.3.0 | Symfony tools (optional) |

### Request Flow

```
Client → Nginx (port 80) → PHP-FPM (Unix socket) → PHP Application
                ↓                    ↓
            FastCGI Cache         Redis (sessions/cache)
```

### Component Communication

- **Nginx ↔ PHP-FPM**: Unix socket at `/var/run/php/php-fpm.sock` (faster than TCP)
- **PHP ↔ Redis**: TCP connection at `127.0.0.1:6379`
- **Supervisor**: Manages all processes as single PID 1

## 📦 Prerequisites

### System Requirements

- **Docker**: version 20.10+ 
- **Docker Compose**: version 2.0+ (optional)
- **Git**: for version control
- **Bash**: for automation scripts

### Recommended Resources

- **CPU**: 2+ cores
- **RAM**: 2GB+ (4GB recommended for production)
- **Disk**: 10GB+ free space

## 📁 Project Structure

```
php-api-stack/
├── .env                    # Main configurations
├── .env.example           # Configuration template
├── VERSION                # Current version (1.2.1)
├── Dockerfile             # Multi-stage image definition
├── build-from-env.sh      # Automated build script
├── docker-entrypoint.sh   # Container entry script
├── health.php             # Comprehensive health check
│
├── nginx/
│   ├── nginx.conf         # Nginx main configuration
│   └── default.conf       # Site/vhost configuration
│
├── php/
│   ├── php.ini           # PHP configuration
│   ├── php-fpm.conf      # PHP-FPM global configuration
│   └── www.conf          # PHP-FPM pool configuration
│
├── redis/
│   └── redis.conf        # Redis configuration
│
├── supervisor/
│   └── supervisord.conf  # Supervisor configuration
│
└── scripts/
    ├── process-configs.sh # Template processor
    └── quick-start.sh     # Quick initialization
```

## 🔨 Installation and Build

### 1. Clone Repository

```bash
git clone https://github.com/kariricode/php-api-stack.git
cd php-api-stack
```

### 2. Configure Environment

```bash
# Copy example file
cp .env.example .env

# Edit configurations
vim .env  # or your preferred editor
```

### 3. Build with Makefile (Recommended)

The project includes a **complete Makefile** for total automation:

```bash
# View all available commands
make help

# Simple build (production)
make build

# Build with tests
make build-test

# Build test image with comprehensive health check
make build-test-image

# Complete release (build + test + scan + push)
make release

# Automatic versioning
make bump-patch  # 1.2.0 -> 1.2.1
make bump-minor  # 1.2.0 -> 1.3.0
make bump-major  # 1.2.0 -> 2.0.0
```

#### Available Makefile Commands

| Command | Description |
|---------|-------------|
| **Build Targets** | |
| `make build` | Build production image locally |
| `make build-test` | Build + quick tests (PHP, Nginx, Redis) |
| `make build-test-image` | Build test image with comprehensive health check |
| `make build-no-cache` | Build without using cache |
| **Test Targets** | |
| `make test` | Run comprehensive test suite on production image |
| `make test-quick` | Quick component version tests |
| `make run-test` | Build + run test container with comprehensive health |
| `make test-health` | Test comprehensive health endpoint (full JSON) |
| `make test-health-status` | Show health status summary |
| `make test-health-watch` | Watch health status (updates every 5s) |
| **Runtime Targets** | |
| `make run` | Start production container for local testing |
| `make stop` | Stop and remove test container |
| `make stop-test` | Stop and remove comprehensive test container |
| `make restart` | Restart the test container |
| `make logs` | Show container logs |
| `make logs-test` | Show logs from test container |
| `make shell` | Open shell in running container |
| `make shell-test` | Open shell in test container |
| **Validation Targets** | |
| `make scan` | Scan vulnerabilities with Trivy |
| `make lint` | Validate Dockerfile with Hadolint |
| `make test-structure` | Test container structure and files |
| **Release Targets** | |
| `make push` | Push image to Docker Hub |
| `make release` | Full release pipeline (lint + build + test + scan + push) |
| **Utility Targets** | |
| `make version` | Display current version |
| `make bump-patch` | Bump patch version (x.x.X) |
| `make bump-minor` | Bump minor version (x.X.x) |
| `make bump-major` | Bump major version (X.x.x) |
| `make clean` | Remove local images and containers |
| `make clean-all` | Deep clean including volumes and build cache |
| `make info` | Show image information |
| `make stats` | Show container resource usage |

### 4. Build with Shell Script

```bash
# Simple build (production)
./build-from-env.sh

# Build without cache (force rebuild)
./build-from-env.sh --no-cache

# Build test image with comprehensive health check
./build-from-env.sh --test

# Build and push to Docker Hub
./build-from-env.sh --push

# Multi-platform build (amd64 + arm64)
./build-from-env.sh --multi-platform --push
```

### 5. Manual Build (Advanced)

```bash
# Build with custom arguments
docker build \
  --build-arg PHP_VERSION=8.4 \
  --build-arg NGINX_VERSION=1.27.3 \
  --build-arg REDIS_VERSION=7.2 \
  --build-arg APP_ENV=production \
  --tag kariricode/php-api-stack:custom \
  .

# Build with comprehensive health check
docker build \
  --build-arg HEALTH_CHECK_TYPE=comprehensive \
  --tag kariricode/php-api-stack:test \
  .
```

## ⚙️ Configuration

### Main Environment Variables

#### Stack Versions
```bash
PHP_VERSION=8.4              # PHP version
NGINX_VERSION=1.27.3         # Nginx version
REDIS_VERSION=7.2            # Redis version
COMPOSER_VERSION=2.8.12      # Composer version
SYMFONY_CLI_VERSION=7.3.0    # Symfony CLI version
```

#### PHP Extensions
```bash
# Core extensions (installed via docker-php-ext-install)
# Only installable extensions (built-ins like tokenizer, fileinfo are automatic)
PHP_CORE_EXTENSIONS="pdo pdo_mysql opcache intl zip bcmath gd mbstring xml sockets"

# PECL extensions (installed via pecl)
PHP_PECL_EXTENSIONS="redis apcu uuid"
```

#### PHP-FPM Settings
```bash
PHP_FPM_PM=dynamic           # Process manager
PHP_FPM_PM_MAX_CHILDREN=50   # Maximum child processes
PHP_FPM_PM_START_SERVERS=5   # Initial processes
PHP_FPM_PM_MIN_SPARE_SERVERS=5
PHP_FPM_PM_MAX_SPARE_SERVERS=10
PHP_FPM_PM_MAX_REQUESTS=500  # Requests before recycling
```

#### Performance and OPcache
```bash
PHP_OPCACHE_ENABLE=1
PHP_OPCACHE_MEMORY=256       # MB of memory for OPcache
PHP_OPCACHE_MAX_FILES=20000  # Maximum files in cache
PHP_OPCACHE_JIT=tracing      # JIT mode (PHP 8+)
PHP_OPCACHE_JIT_BUFFER_SIZE=128M
```

### Custom Configurations

#### For Development
```bash
APP_ENV=development
APP_DEBUG=true
PHP_DISPLAY_ERRORS=On
PHP_OPCACHE_VALIDATE_TIMESTAMPS=1
XDEBUG_ENABLE=true
XDEBUG_MODE=develop,debug,coverage
```

#### For Production
```bash
APP_ENV=production
APP_DEBUG=false
PHP_DISPLAY_ERRORS=Off
PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
XDEBUG_ENABLE=false
```

## 🚀 Using the Image

### Basic Execution

```bash
# Run basic container
docker run -d \
  --name my-app \
  -p 8080:80 \
  -v $(pwd)/app:/var/www/html \
  kariricode/php-api-stack:latest

# With custom .env file
docker run -d \
  --name my-app \
  --env-file .env.production \
  -p 8080:80 \
  -v $(pwd)/app:/var/www/html \
  kariricode/php-api-stack:latest
```

### Docker Compose

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

### Useful Commands

```bash
# Check logs
docker exec my-app tail -f /var/log/nginx/access.log
docker exec my-app tail -f /var/log/php/error.log

# Access container shell
docker exec -it my-app bash

# Run Symfony commands
docker exec my-app symfony console cache:clear
docker exec my-app symfony console doctrine:migrations:migrate

# Check service status
docker exec my-app supervisorctl status

# Reload configurations
docker exec my-app supervisorctl reload
```

## 🔌 PHP Extensions

### ✅ Verified Installed Extensions

```bash
# Check installed extensions
docker run --rm kariricode/php-api-stack:latest php -m
```

**Output (verified):**
```
[PHP Modules]
apcu          ← PECL (cache)
bcmath        ← Core (arbitrary precision math)
Core          ← Built-in
ctype         ← Built-in (character type checking)
curl          ← Built-in (HTTP client)
date          ← Built-in
dom           ← Core (XML DOM)
fileinfo      ← Built-in (file type detection)
filter        ← Built-in (data filtering)
hash          ← Built-in
iconv         ← Built-in (character encoding)
intl          ← Core (internationalization)
json          ← Built-in (JSON handling)
libxml        ← Built-in
mbstring      ← Core (multibyte strings)
mysqlnd       ← Built-in (MySQL native driver)
openssl       ← Built-in
pcre          ← Built-in (regex)
PDO           ← Core (database abstraction)
pdo_mysql     ← Core (MySQL PDO driver)
pdo_sqlite    ← Built-in
Phar          ← Built-in (PHP archives)
posix         ← Built-in (POSIX functions)
random        ← Built-in
readline      ← Built-in
redis         ← PECL (Redis client)
Reflection    ← Built-in
session       ← Built-in (session handling)
SimpleXML     ← Built-in
sockets       ← Core (socket programming)
sodium        ← Built-in (cryptography)
SPL           ← Built-in
sqlite3       ← Built-in
standard      ← Built-in
tokenizer     ← Built-in (PHP token parsing)
uuid          ← PECL (UUID generation)
xml           ← Core (XML processing)
xmlreader     ← Built-in
xmlwriter     ← Built-in
Zend OPcache  ← Core (bytecode cache)
zip           ← Core (ZIP compression)
zlib          ← Built-in

[Zend Modules]
Zend OPcache
```

### 📚 Extension Reference

#### Core Extensions (Installable)
| Extension | Dependencies | Use Case |
|----------|-------------|----------|
| `pdo` | None | Database abstraction layer |
| `pdo_mysql` | MySQL libs | MySQL PDO driver |
| `opcache` | None | **Essential** - PHP bytecode cache |
| `intl` | icu-dev | Internationalization |
| `zip` | libzip-dev | ZIP compression |
| `bcmath` | None | Arbitrary precision mathematics |
| `gd` | libpng-dev, libjpeg-turbo-dev, freetype-dev | Image manipulation |
| `mbstring` | oniguruma-dev | Multibyte string handling |
| `xml` | libxml2-dev | XML processing |
| `sockets` | None | Low-level socket programming |

#### PECL Extensions
| Extension | Use Case | Production? |
|----------|----------|-------------|
| `redis` | Redis client | ✅ Yes |
| `apcu` | User cache | ✅ Yes |
| `uuid` | UUID generation | ✅ Yes |
| `xdebug` | Debugging | ❌ No (dev only) |
| `imagick` | Advanced image processing | ✅ Optional |
| `swoole` | Async I/O framework | ✅ Optional |

#### Built-in Extensions (Auto-available)
| Extension | Since | Notes |
|----------|-------|-------|
| `tokenizer` | PHP 4.3+ | Parse PHP tokens |
| `fileinfo` | PHP 5.3+ | File type detection |
| `ctype` | PHP 4.0+ | Character type checking |
| `iconv` | PHP 5.0+ | Character encoding conversion |
| `session` | PHP 4.0+ | Session handling |
| `filter` | PHP 5.2+ | Data filtering/validation |
| `json` | PHP 5.2+ | JSON encoding/decoding |
| `curl` | Built-in | HTTP client |

### Adding New Extensions

#### Core Extension
```bash
# In .env, add to list:
PHP_CORE_EXTENSIONS="pdo pdo_mysql opcache intl zip bcmath gd mbstring xml sockets pcntl"
#                                                                              ^^^^^^ New

# Rebuild:
make build-test
```

#### PECL Extension
```bash
# In .env:
PHP_PECL_EXTENSIONS="redis apcu uuid imagick"
#                                    ^^^^^^^^ New

# Rebuild:
make build-test
```

## 🧪 Automated Testing

### Test Pipeline

The project includes a complete automated test suite:

```bash
# Quick test after build
make build-test

# Expected output:
# ✓ PHP 8.4.x with OPcache
# ✓ Nginx configuration valid
# ✓ Redis server operational
# ✓ Template processing OK
# ✓ Configuration validation OK
```

### Configuration Validation

During initialization, the container automatically executes:

1. **Template Processing** (`process-configs.sh`)
   - ✓ Nginx main configuration
   - ✓ Nginx site configuration  
   - ✓ PHP.ini configuration
   - ✓ PHP-FPM pool configuration
   - ✓ Redis configuration

2. **Syntax Validation**
   - `php-fpm -t` - Validates PHP-FPM
   - `nginx -t` - Validates Nginx
   - Production optimizations applied

### Security Tests

```bash
# Vulnerability scan with Trivy
make scan

# Dockerfile lint with Hadolint
make lint

# Validate Nginx configuration
make test-structure
```

### Performance Tests

```bash
# Load test with Apache Bench
docker exec my-app ab -n 10000 -c 100 http://localhost/

# Monitor resources during test
docker stats my-app

# Check OPcache hits
docker exec my-app php -r "print_r(opcache_get_status()['opcache_statistics']);"
```

## 🛠 Debug and Troubleshooting

### Health Verification

```bash
# General health check endpoint (simple)
curl http://localhost:8080/health

# Comprehensive health check (test builds)
curl http://localhost:8080/health.php | jq

# PHP-FPM status
curl http://localhost:8080/fpm-status

# PHP-FPM ping
curl http://localhost:8080/fpm-ping
```

### Structured Logs

```bash
# Log locations
/var/log/nginx/access.log    # Nginx access
/var/log/nginx/error.log     # Nginx errors
/var/log/php/error.log        # PHP errors
/var/log/php/fpm-access.log   # PHP-FPM access
/var/log/php/fpm-slow.log     # Slow requests
/var/log/redis/redis.log     # Redis logs
/var/log/supervisor/*.log    # Supervisor logs
```

### Common Issues

#### 1. Container won't start
```bash
# Check container logs
docker logs my-app

# Run in debug mode
docker run -it --rm \
  -v $(pwd)/app:/var/www/html \
  kariricode/php-api-stack:latest \
  /bin/bash

# Test configurations
php-fpm -t
nginx -t
redis-cli ping
```

#### 2. 502 Bad Gateway Error
```bash
# Check PHP-FPM socket
docker exec my-app ls -la /var/run/php/php-fpm.sock

# Check processes
docker exec my-app ps aux | grep php-fpm

# Restart PHP-FPM
docker exec my-app supervisorctl restart php-fpm
```

#### 3. Poor Performance
```bash
# Check memory usage
docker exec my-app free -h

# Check OPcache
docker exec my-app php -r "print_r(opcache_get_status());"

# Adjust limits
docker update --memory="2g" --cpus="2" my-app
```

### XDebug (Development)

```bash
# Enable XDebug
XDEBUG_ENABLE=true
XDEBUG_MODE=develop,debug,coverage
XDEBUG_HOST=host.docker.internal
XDEBUG_PORT=9003
XDEBUG_IDE_KEY=PHPSTORM
```

## 🏥 Comprehensive Health Check

The stack includes two health check implementations:

### Production Health Check (Simple)
- **Endpoint**: `/health`
- **Usage**: Lightweight check for container orchestrators
- **Response**: Simple JSON with status and timestamp

### Test/Development Health Check (Comprehensive)
- **Endpoint**: `/health.php`
- **Usage**: Detailed validation of all stack components
- **Architecture**: SOLID principles, Design Patterns, Type-safe

#### Features

✅ **PHP Runtime Validation**
- PHP version, SAPI, memory usage
- Memory limit monitoring with alerts (>90% usage)
- Zend Engine version

✅ **PHP Extensions Check**
- Required extensions validation (PDO, OPcache, mbstring, JSON, cURL)
- Optional extensions detection (Redis, APCu, Intl, Zip, GD, XML)
- Missing extensions alerting

✅ **OPcache Performance**
- Memory usage (used, free, wasted percentage)
- Hit rate monitoring (alert if <90%)
- JIT status and buffer size
- Cache statistics (scripts cached, hits, misses)
- Restart counters (OOM, hash, manual)

✅ **Redis Connectivity**
- Connection latency measurement
- Ping test (<100ms expected)
- Version, uptime, memory statistics
- Client connections and command statistics
- Keyspace hit/miss ratio

✅ **System Resources**
- Disk space monitoring (alert if >90%)
- CPU load average (1min, 5min, 15min)
- System memory (total, available, usage %)
- Memory from `/proc/meminfo` (Linux)

✅ **Application Directories**
- Critical paths validation
- Read/write permissions check
- Directory existence verification

### Using Comprehensive Health Check

#### 1. Build Test Image

```bash
# Via Makefile (recommended)
make build-test-image

# Via script
./build-from-env.sh --test

# Manual build
docker build \
  --build-arg HEALTH_CHECK_TYPE=comprehensive \
  -t kariricode/php-api-stack:test \
  .
```

#### 2. Run Test Container

```bash
# Via Makefile (automatic)
make run-test

# Expected output:
# ✓ Test container running!
# Container:    php-api-stack-test
# URL:          http://localhost:8080
# Health Check: http://localhost:8080/health.php
#
# Testing comprehensive health endpoint...
# ✓ Health check: HEALTHY
# Duration: 42.15ms
#
# Available checks:
#   - php
#   - php_extensions
#   - opcache
#   - redis
#   - system
#   - application
```

#### 3. Test Health Endpoint

```bash
# Full health check
curl http://localhost:8080/health.php | jq

# Check overall status
curl -s http://localhost:8080/health.php | jq '.status'
# Output: "healthy"

# Check specific component
curl -s http://localhost:8080/health.php | jq '.checks.opcache'

# Find failed checks
curl -s http://localhost:8080/health.php | jq '.checks | to_entries[] | select(.value.healthy == false)'

# Via Makefile
make test-health              # Full JSON output
make test-health-status       # Summary only
make test-health-watch        # Live monitoring (5s refresh)
```

### Example Response

```json
{
  "status": "healthy",
  "timestamp": "2025-10-09T14:30:00+00:00",
  "duration_ms": 42.15,
  "checks": {
    "php": {
      "healthy": true,
      "status": "healthy",
      "details": {
        "version": "8.4.0",
        "sapi": "fpm-fcgi",
        "memory": {
          "limit": "256 MB",
          "usage": "32 MB",
          "peak": "35 MB",
          "usage_percent": 12.5
        },
        "zend_version": "4.4.0"
      },
      "duration_ms": 0.52
    },
    "php_extensions": {
      "healthy": true,
      "status": "healthy",
      "details": {
        "total_loaded": 45,
        "required": {
          "loaded": ["pdo", "opcache", "mbstring", "json", "curl"],
          "missing": []
        },
        "optional_loaded": ["redis", "apcu", "intl", "zip", "gd", "xml"]
      },
      "duration_ms": 0.31
    },
    "opcache": {
      "healthy": true,
      "status": "healthy",
      "details": {
        "enabled": true,
        "memory": {
          "used": "48 MB",
          "free": "208 MB",
          "usage_percent": 18.75,
          "wasted_percent": 0.5
        },
        "statistics": {
          "hits": 125000,
          "misses": 1500,
          "hit_rate": 98.81,
          "cached_scripts": 1250,
          "max_cached_keys": 20000
        },
        "jit": {
          "enabled": true,
          "on": true,
          "buffer_size": "128 MB"
        },
        "restarts": {
          "oom": 0,
          "hash": 0,
          "manual": 0
        }
      },
      "duration_ms": 1.23
    },
    "redis": {
      "healthy": true,
      "status": "healthy",
      "details": {
        "connected": true,
        "version": "7.2.0",
        "uptime_seconds": 86400,
        "memory": {
          "used": "2.5M",
          "peak": "3.2M",
          "fragmentation_ratio": 1.03
        },
        "stats": {
          "connected_clients": 5,
          "total_commands_processed": 50000,
          "keyspace_hits": 48000,
          "keyspace_misses": 2000
        },
        "latency": {
          "connect_ms": 0.15,
          "ping_ms": 0.08
        }
      },
      "duration_ms": 1.45
    },
    "system": {
      "healthy": true,
      "status": "healthy",
      "details": {
        "disk": {
          "total": "100 GB",
          "free": "45 GB",
          "usage_percent": 55
        },
        "load_average": {
          "1min": 0.5,
          "5min": 0.3,
          "15min": 0.2
        },
        "memory": {
          "total": "4 GB",
          "available": "2.5 GB",
          "used": "1.5 GB",
          "usage_percent": 37.5
        }
      },
      "duration_ms": 2.34
    },
    "application": {
      "healthy": true,
      "status": "healthy",
      "details": {
        "directories": {
          "html": {
            "path": "/var/www/html",
            "exists": true,
            "readable": true,
            "writable": true
          },
          "public": {
            "path": "/var/www/html/public",
            "exists": true,
            "readable": true,
            "writable": true
          },
          "php": {
            "path": "/var/log/php",
            "exists": true,
            "readable": true,
            "writable": true
          },
          "nginx": {
            "path": "/var/log/nginx",
            "exists": true,
            "readable": true,
            "writable": true
          }
        },
        "document_root": "/var/www/html/public"
      },
      "duration_ms": 0.89
    }
  }
}
```

### HTTP Status Codes

| Code | Status | Description |
|------|--------|-------------|
| **200** | Healthy | All critical checks passed |
| **503** | Unhealthy | One or more critical checks failed |
| **500** | Error | Internal error during health check |

### Integration Examples

#### Docker Compose

```yaml
services:
  app:
    image: kariricode/php-api-stack:test
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health.php"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

#### Kubernetes

```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: php-app
    image: kariricode/php-api-stack:test
    livenessProbe:
      httpGet:
        path: /health.php
        port: 80
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /health.php
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
```

#### Prometheus Monitoring

```yaml
scrape_configs:
  - job_name: 'php-api-health'
    static_configs:
      - targets: ['app:80']
    metrics_path: '/health.php'
    scrape_interval: 30s
```

### Makefile Commands Reference

| Command | Description |
|---------|-------------|
| `make build-test-image` | Build test image with comprehensive health check |
| `make run-test` | Build + run test container with auto-validation |
| `make test-health` | Test comprehensive health endpoint (full JSON) |
| `make test-health-status` | Show health status summary |
| `make test-health-watch` | Live monitoring (updates every 5s) |
| `make logs-test` | View test container logs |
| `make shell-test` | Access test container shell |
| `make stop-test` | Stop and remove test container |

### Architecture Details

The comprehensive health check follows **SOLID principles** and implements several **Design Patterns**:

- **Single Responsibility**: Each checker validates one component
- **Open/Closed**: Easy to extend with new checkers
- **Liskov Substitution**: All checkers are interchangeable
- **Interface Segregation**: Clean, focused interfaces
- **Dependency Inversion**: Depends on abstractions

**Patterns Used**:
- **Strategy Pattern**: Different health check strategies
- **Template Method**: Abstract base with common logic
- **Facade Pattern**: `HealthCheckManager` simplifies usage
- **Value Object**: Immutable `CheckResult` type

### Performance Impact

- **Execution Time**: ~40-50ms (all checks)
- **Memory Usage**: <1MB additional
- **CPU Impact**: Negligible (<1% spike)
- **Network**: Local connections only (Redis)

### Customization

Add custom checkers by extending `AbstractHealthCheck`:

```php
final class DatabaseCheck extends AbstractHealthCheck
{
    public function getName(): string 
    { 
        return 'database'; 
    }

    protected function performCheck(): array
    {
        // Your custom validation logic
        return [
            'healthy' => true,
            'status' => 'healthy',
            'details' => ['connections' => 5]
        ];
    }
}

// Register in health.php
$manager->addChecker(new DatabaseCheck());
```

### Troubleshooting

```bash
# Check if health.php exists
docker exec php-api-stack-test ls -la /var/www/html/public/health.php

# Test syntax
docker exec php-api-stack-test php -l /var/www/html/public/health.php

# Run directly (bypass web server)
docker exec php-api-stack-test php /var/www/html/public/health.php

# Check Nginx error logs
docker exec php-api-stack-test tail -f /var/log/nginx/error.log

# Check PHP-FPM logs
docker exec php-api-stack-test tail -f /var/log/php/error.log
```

## 💻 Local Development

### Development Workflow

#### 1. Initial Setup

```bash
# Clone and prepare
git clone https://github.com/kariricode/php-api-stack.git
cd php-api-stack
make build-test

# Start container for development
make run
```

#### 2. Iterative Development

```bash
# View logs in real-time
make logs

# Access container shell
make shell

# Restart services after changes
docker exec php-api-test supervisorctl restart all

# Stop container
make stop
```

#### 3. Release Cycle

```bash
# 1. Make changes and test
make build-test

# 2. Increment version
make bump-patch  # or bump-minor, bump-major

# 3. Validate quality
make lint
make scan

# 4. Complete release
make release
```

### Docker Compose for Development

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  app:
    build:
      context: .
      args:
        APP_ENV: development
        PHP_PECL_EXTENSIONS: "redis apcu uuid xdebug"
        HEALTH_CHECK_TYPE: comprehensive
    image: kariricode/php-api-stack:dev
    volumes:
      - ./app:/var/www/html
      - ./logs:/var/log
      - ./.env.dev:/var/www/.env
    ports:
      - "8080:80"
      - "9003:9003"  # XDebug
    environment:
      - APP_ENV=development
      - APP_DEBUG=true
      - XDEBUG_ENABLE=true
      - XDEBUG_MODE=develop,debug
      - XDEBUG_HOST=host.docker.internal
    networks:
      - dev-network

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: app_dev
    volumes:
      - db-data:/var/lib/mysql
    ports:
      - "3306:3306"
    networks:
      - dev-network

volumes:
  db-data:

networks:
  dev-network:
    driver: bridge
```

## 📊 Development vs Production

### Development Settings

```bash
# .env.development
APP_ENV=development
APP_DEBUG=true
PHP_DISPLAY_ERRORS=On
PHP_ERROR_REPORTING=E_ALL
PHP_OPCACHE_VALIDATE_TIMESTAMPS=1
PHP_OPCACHE_REVALIDATE_FREQ=2
XDEBUG_ENABLE=true
```

### Production Settings

```bash
# .env.production
APP_ENV=production
APP_DEBUG=false
PHP_DISPLAY_ERRORS=Off
PHP_ERROR_REPORTING=E_ALL & ~E_DEPRECATED & ~E_STRICT
PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
PHP_OPCACHE_REVALIDATE_FREQ=0
XDEBUG_ENABLE=false

# Additional optimizations
PHP_FPM_PM=static
PHP_FPM_PM_MAX_CHILDREN=100
PHP_OPCACHE_ENABLE_FILE_OVERRIDE=1
PHP_OPCACHE_SAVE_COMMENTS=0
```

## 🔢 Versioning

### Versioning Strategy

The project follows [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH

1.2.1
│ │ └── Bug fixes
│ └──── New features (backward compatible)
└────── Breaking changes
```

### Available Tags

- `latest` - Latest stable version
- `stable` - Production version
- `test` - Test version with comprehensive health check
- `dev` - Development version
- `1.2.1` - Specific version
- `1.2` - Minor version
- `1` - Major version

### Version Update

```bash
# Edit VERSION file
echo "1.3.0" > VERSION

# Build with new version
./build-from-env.sh --version=1.3.0 --push

# Or let it read from VERSION file
./build-from-env.sh --push
```

## ⚡ Performance Optimizations

### Configured OPcache

```php
// Check OPcache status
<?php
$status = opcache_get_status();
echo "Memory Used: " . $status['memory_usage']['used_memory'] . "\n";
echo "Memory Free: " . $status['memory_usage']['free_memory'] . "\n";
echo "Files Cached: " . $status['opcache_statistics']['num_cached_scripts'] . "\n";
?>
```

### JIT Compiler (PHP 8+)

```bash
# Optimized configuration
PHP_OPCACHE_JIT=tracing
PHP_OPCACHE_JIT_BUFFER_SIZE=128M
```

### FastCGI Cache

```nginx
# Configured in nginx.conf
fastcgi_cache_path /var/cache/nginx/fastcgi 
                   levels=1:2 
                   keys_zone=FASTCGI:100m 
                   inactive=60m 
                   max_size=1g;
```

### Redis for Sessions

```bash
# Automatic configuration
PHP_SESSION_SAVE_HANDLER=redis
PHP_SESSION_SAVE_PATH="tcp://127.0.0.1:6379"
```

### Gzip Compression

```bash
# Enabled by default
NGINX_GZIP=on
NGINX_GZIP_COMP_LEVEL=6
```

## 🔒 Security

### Security Headers

Automatically implemented:
- `X-Frame-Options: SAMEORIGIN`
- `X-Content-Type-Options: nosniff`
- `X-XSS-Protection: 1; mode=block`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy: geolocation=(), microphone=(), camera=()`

### Rate Limiting

```nginx
# Configured in nginx.conf
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=api:10m rate=100r/s;
```

### Disabled PHP Functions

```ini
# In production
disable_functions = exec,passthru,shell_exec,system,popen,show_source
```

### Open Basedir

```ini
open_basedir = /var/www/html:/tmp:/usr/local/lib/php:/usr/share/php
```

## 📊 Monitoring

### Monitoring Endpoints

| Endpoint | Description | Access |
|----------|-------------|---------|
| `/health` | General health check (simple) | Public |
| `/health.php` | Comprehensive health check | Public (test builds) |
| `/fpm-status` | PHP-FPM status | 127.0.0.1 only |
| `/fpm-ping` | PHP-FPM ping | 127.0.0.1 only |
| `/redis-status` | Redis status | 127.0.0.1 only |

### Prometheus Integration

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'php-app'
    static_configs:
      - targets: ['app:9090']
    metrics_path: '/metrics'
```

### JSON Logs

```bash
# Enable JSON logs
log_format json escape=json '{...}';
access_log /var/log/nginx/access.log json;
```

## ❓ FAQ

### How to add additional PHP extensions?

Edit `.env`:
```bash
PHP_CORE_EXTENSIONS="... new_extension"
PHP_PECL_EXTENSIONS="... new_pecl_extension"
```

### How to optimize for high load?

```bash
# Adjust in .env
PHP_FPM_PM=static
PHP_FPM_PM_MAX_CHILDREN=200
NGINX_WORKER_CONNECTIONS=4096
```

### How to enable HTTPS?

Mount certificates and configure:
```bash
docker run -d \
  -v ./certs:/etc/nginx/certs \
  -p 443:443 \
  kariricode/php-api-stack:latest
```

### How to use with external database?

```yaml
# docker-compose.yml
services:
  app:
    image: kariricode/php-api-stack:latest
    environment:
      - DATABASE_URL=mysql://user:pass@db:3306/database
  
  db:
    image: mysql:8.0
```

### How to use the comprehensive health check in production?

Build with the `--test` flag:
```bash
./build-from-env.sh --test --push
```

Then use the `:test` tag in production if you need detailed monitoring.

## 📖 Use Cases and Best Practices

### Ideal Use Cases

#### ✅ Perfect For:
- **REST APIs** with Symfony, Laravel, or Lumen
- **Microservices** with high-performance PHP
- **Symfony Applications** 5.x/6.x/7.x
- **GraphQL APIs** with PHP
- **Workers** and asynchronous processing
- **Applications** with high cache demand

#### ⚠️ Consider Alternatives For:
- WordPress sites (use specialized images)
- Legacy PHP applications < 7.4
- Projects specifically requiring Apache
- Applications requiring very specific PHP extensions

### Production Best Practices

#### 1. **Resource Configuration**
```yaml
# docker-compose.prod.yml
services:
  app:
    image: kariricode/php-api-stack:stable
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    environment:
      PHP_FPM_PM: static
      PHP_FPM_PM_MAX_CHILDREN: 100
```

#### 2. **Volumes and Persistence**
```yaml
volumes:
  # Composer cache (reuse between builds)
  - composer-cache:/composer
  # Persistent logs
  - ./logs:/var/log:rw
  # Read-only code in production
  - ./app:/var/www/html:ro
```

#### 3. **Network and Security**
```yaml
networks:
  frontend:
    external: true
  backend:
    internal: true
    
services:
  app:
    networks:
      - frontend  # Only for reverse proxy
      - backend   # For database
```

### Expected Performance Metrics

With optimized configuration, you can expect:

| Metric | Expected Value |
|--------|---------------|
| **Requests/sec** | 5000-10000 (hardware dependent) |
| **Latency P50** | < 50ms |
| **Latency P99** | < 200ms |
| **CPU Usage** | 60-80% under load |
| **Memory Usage** | 200-500MB per container |
| **Cache Hit Rate** | > 95% (OPcache) |

### Advanced Troubleshooting

```bash
# Performance profiling with XHProf
docker exec my-app pecl install xhprof
docker exec my-app php -d extension=xhprof.so script.php

# Slow query analysis
docker exec my-app tail -f /var/log/php/fpm-slow.log

# System trace
docker exec my-app strace -p $(pidof php-fpm)

# Memory analysis
docker exec my-app php -r "print_r(memory_get_usage(true));"
```

## 📚 References

### Official Documentation
- [PHP Documentation](https://www.php.net/docs.php)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Symfony Best Practices](https://symfony.com/doc/current/best_practices.html)

### Standards and Practices
- [The Twelve-Factor App](https://12factor.net/)
- [OWASP Security Guidelines](https://owasp.org/www-project-top-ten/)
- [PHP-FIG Standards](https://www.php-fig.org/psr/)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)

### Related Tools
- [Docker Hub - kariricode/php-api-stack](https://hub.docker.com/r/kariricode/php-api-stack)
- [GitHub Actions](https://github.com/features/actions)
- [Kubernetes](https://kubernetes.io/)

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Standards

- Follow [PSR-12](https://www.php-fig.org/psr/psr-12/) for PHP
- Use [Conventional Commits](https://www.conventionalcommits.org/)
- Add tests for new features
- Update documentation when necessary

## 📝 Changelog

### [1.2.1] - 2025-10-09
- 🏥 Added comprehensive health check with SOLID architecture
- 📊 Detailed validation for all stack components (PHP, OPcache, Redis, System, Application)
- 🔧 New Makefile targets for test builds and health monitoring
- 📚 Enhanced documentation with comprehensive health check section
- ✅ Production and test build separation via build arguments
- 🎨 Improved Makefile organization and help system
- 🐛 Fixed health check integration in Docker builds

### [1.2.0] - 2025-10-08
- ✨ Improved PHP extension installation with smart detection
- 🔧 Enhanced build script with better error handling
- 📚 Complete documentation in English
- 🛠 Fixed socket PHP-FPM for better performance
- ⚡ Production performance optimizations
- ✅ Automatic configuration validation

### [1.0.8] - 2025-09-20
- 🎉 Initial release
- 🚀 PHP 8.2 + Nginx 1.27.3 + Redis 7.2 stack
- 📦 Support for Symfony and REST APIs
- 🔒 Implemented security configurations

## 💬 Support

### Support Channels

- **Issues**: [GitHub Issues](https://github.com/kariricode/php-api-stack/issues)
- **Discussions**: [GitHub Discussions](https://github.com/kariricode/php-api-stack/discussions)
- **Stack Overflow**: Tag `php-api-stack`
- **Docker Hub**: [Comments](https://hub.docker.com/r/kariricode/php-api-stack)

### Reporting Issues

When reporting an issue, include:

1. **Image version** (`docker images kariricode/php-api-stack`)
2. **Container logs** (`docker logs <container-id>`)
3. **.env file** used (without sensitive data)
4. **Steps to reproduce** the problem
5. **Expected behavior** vs **actual behavior**

## 🌟 Roadmap

### Upcoming Versions

- [ ] **v1.3.0** - PHP 8.4 GA support
- [ ] **v1.4.0** - OpenTelemetry integration
- [ ] **v1.5.0** - Native gRPC support
- [ ] **v2.0.0** - Migration to Alpine 3.20 + PHP 9

### Planned Features

- 📈 Auto-scaling based on metrics
- 📊 Integrated monitoring dashboard
- 🔐 Vault integration for secrets
- 🚀 Swoole/RoadRunner support
- 📦 Specialized variants (Laravel, API Platform)

## 👤 Author

**kariricode**
- GitHub: [@kariricode](https://github.com/kariricode)
- Docker Hub: [kariricode](https://hub.docker.com/u/kariricode)

---

<div align="center">

⭐ **If this project helped you, consider giving it a star!** ⭐

🔧 **For commercial support or consulting**: kariricode@github.com

🔗 **Useful Links**: [Docker Hub](https://hub.docker.com/r/kariricode/php-api-stack) | [GitHub](https://github.com/kariricode/php-api-stack) | [Issues](https://github.com/kariricode/php-api-stack/issues)

</div>

---

<sub>Developed with ❤️ for the PHP community</sub>