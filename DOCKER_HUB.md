# KaririCode/php-api-stack

Production-ready **PHP API Stack** image built on Alpine Linux with **Nginx + PHP-FPM + Redis**. Secured, fast, and fully configurable via environment variables — ideal for modern APIs, web applications, and microservices.

<p align="center">
  <a href="https://hub.docker.com/r/kariricode/php-api-stack"><img alt="Docker Pulls" src="https://img.shields.io/docker/pulls/kariricode/php-api-stack"></a>
  <a href="https://hub.docker.com/r/kariricode/php-api-stack"><img alt="Docker Image Size" src="https://img.shields.io/docker/image-size/kariricode/php-api-stack/latest"></a>
  <a href="https://hub.docker.com/r/kariricode/php-api-stack"><img alt="Docker Image Version" src="https://img.shields.io/docker/v/kariricode/php-api-stack?sort=semver"></a>
  <a href="https://github.com/kariricode/php-api-stack"><img alt="Source" src="https://img.shields.io/badge/source-GitHub-black?logo=github"></a>
  <a href="https://kariricode.org/"><img alt="KaririCode" src="https://img.shields.io/badge/site-kariricode.org-0aa344"></a>
  <img alt="Version" src="https://img.shields.io/badge/version-1.5.0-blue">
  <img alt="PHP" src="https://img.shields.io/badge/PHP-8.4.13-777bb3?logo=php">
  <img alt="Alpine" src="https://img.shields.io/badge/Alpine-3.21-0d597f?logo=alpine-linux">
</p>

---

## 🔗 Official Links

* **Docker Hub**: [https://hub.docker.com/r/kariricode/php-api-stack](https://hub.docker.com/r/kariricode/php-api-stack)
* **GitHub Repository**: [https://github.com/kariricode/php-api-stack](https://github.com/kariricode/php-api-stack)
* **Documentation**: [Full guides in GitHub repository](https://github.com/kariricode/php-api-stack#documentation)
* **Official Site**: [https://kariricode.org/](https://kariricode.org/)
* **KaririCode Framework**: [https://github.com/KaririCode-Framework](https://github.com/KaririCode-Framework)

---

## ✨ Highlights

### Core Stack
* **Complete Integration**: Nginx 1.27.3 + PHP-FPM 8.4.13 + Redis 7.2.11
* **Alpine Linux 3.21**: Minimal footprint (~225MB production, ~244MB dev)
* **Multi-platform**: Native support for amd64 and arm64

### Performance
* **OPcache + JIT**: Tracing mode enabled by default for maximum performance
* **Optimized Configuration**: Tuned Nginx/PHP-FPM with Unix socket communication
* **FastCGI Cache**: Built-in for accelerated response times
* **Static Assets**: Direct Nginx serving with aggressive caching

### Security
* **Non-root Services**: All services run as unprivileged users
* **Hardened Defaults**: Security headers (CSP, HSTS, X-Frame-Options)
* **Rate Limiting**: Built-in protection against abuse
* **Regular Updates**: Automated security patches and vulnerability scanning

### Developer Experience
* **100% Configurable**: All settings via environment variables
* **Three Specialized Makefiles**: Build, Docker Hub, and Compose operations (50+ commands)
* **Comprehensive Health Checks**: Simple and detailed endpoints for monitoring
* **CI/CD Ready**: GitHub Actions workflows and automated testing
* **Development Image**: Includes Xdebug 3.4.6 and Symfony CLI 5.15.1

---

## 🚀 Quick Start

### 30-Second Demo

Pull and run the demo page:

```bash
docker pull kariricode/php-api-stack:latest
docker run -d -p 8080:80 --name my-app kariricode/php-api-stack:latest

# Open: http://localhost:8080
```

You'll see a comprehensive status page showing PHP version, loaded extensions, OPcache statistics, Redis connectivity, and system resources.

### With Your Application

```bash
docker run -d \
  -p 8080:80 \
  --name my-app \
  -e APP_ENV=production \
  -e PHP_MEMORY_LIMIT=512M \
  -e PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
  -v $(pwd)/app:/var/www/html:ro \
  kariricode/php-api-stack:latest
```

**Important**: Your application's public entry point must be at `/var/www/html/public/index.php` (Symfony/Laravel standard).

---

## 🐳 Docker Compose

### Basic Setup

Create `docker-compose.yml`:

```yaml
version: '3.9'

services:
  app:
    image: kariricode/php-api-stack:latest
    container_name: my-app
    ports:
      - "8080:80"
    environment:
      APP_ENV: production
      PHP_MEMORY_LIMIT: 512M
      PHP_FPM_PM_MAX_CHILDREN: 100
      REDIS_HOST: 127.0.0.1  # Using internal Redis
    volumes:
      - ./app:/var/www/html:ro
      - ./logs:/var/log
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 3s
      retries: 3
    restart: unless-stopped
```

### With External Database

```yaml
version: '3.9'

services:
  app:
    image: kariricode/php-api-stack:latest
    container_name: my-app
    ports:
      - "8080:80"
    environment:
      APP_ENV: production
      DATABASE_URL: mysql://user:pass@db:3306/myapp
      REDIS_HOST: 127.0.0.1  # Internal Redis
    volumes:
      - ./app:/var/www/html:ro
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
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: myapp
      MYSQL_USER: user
      MYSQL_PASSWORD: pass
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

**Note about Redis**: This image includes an internal Redis instance on `127.0.0.1:6379`. For external Redis, create a separate service and set `REDIS_HOST` to the service name.

Start services:

```bash
docker compose up -d
docker compose logs -f
docker compose ps
```

---

## 🏷️ Available Tags

| Tag | Description | Size | Use Case |
|-----|-------------|------|----------|
| `latest` | Latest stable release | ~225MB | General use |
| `1.5.0` | Specific version | ~225MB | Production (pinned) |
| `1.5` | Latest patch in v1.5.x | ~225MB | Auto-patch updates |
| `1` | Latest minor in v1.x.x | ~225MB | Auto-minor updates |
| `dev` | Development build | ~244MB | Local development with Xdebug |
| `test` | With comprehensive health checks | ~216MB | Testing/monitoring |

### Tagging Strategy

- **Production**: Always pin to specific versions (`1.5.0`) for reproducibility
- **Development**: Use `dev` tag for debugging capabilities
- **Staging**: Use minor version tags (`1.5`) for automatic patch updates
- **Never** use `latest` in production

Pull a specific tag:

```bash
docker pull kariricode/php-api-stack:1.5.0
docker pull kariricode/php-api-stack:dev
```

---

## ⚙️ Configuration

All configuration is done via environment variables. The image supports **100+ configuration options** covering PHP, PHP-FPM, Nginx, Redis, and application settings.

### Essential Variables

```bash
# Application
APP_ENV=production                      # production|development|test
APP_DEBUG=false                         # Enable debug mode
APP_NAME=my-application                 # Application name

# PHP Runtime
PHP_MEMORY_LIMIT=512M                   # Memory per request
PHP_MAX_EXECUTION_TIME=60               # Script timeout
PHP_UPLOAD_MAX_FILESIZE=100M            # Max upload size
PHP_POST_MAX_SIZE=100M                  # Max POST size
PHP_DATE_TIMEZONE=UTC                   # Timezone

# PHP-FPM
PHP_FPM_PM=static                       # static|dynamic|ondemand
PHP_FPM_PM_MAX_CHILDREN=100             # Worker processes

# OPcache
PHP_OPCACHE_ENABLE=1                    # Enable OPcache
PHP_OPCACHE_MEMORY=256                  # OPcache memory (MB)
PHP_OPCACHE_VALIDATE_TIMESTAMPS=0       # 0 for prod, 1 for dev
PHP_OPCACHE_JIT=tracing                 # JIT mode

# Nginx
NGINX_WORKER_PROCESSES=auto             # auto = CPU cores
NGINX_CLIENT_MAX_BODY_SIZE=100M         # Max request size

# Redis (Internal)
REDIS_HOST=127.0.0.1                    # Internal Redis (standalone)
REDIS_PASSWORD=                         # Optional password
```

**Complete reference**: See [.env.example](https://github.com/kariricode/php-api-stack/blob/main/.env.example) in the repository.

### Configuration Examples

#### High Performance Setup

```bash
docker run -d \
  -p 80:80 \
  -e PHP_MEMORY_LIMIT=512M \
  -e PHP_FPM_PM=static \
  -e PHP_FPM_PM_MAX_CHILDREN=200 \
  -e PHP_OPCACHE_MEMORY=512 \
  -e PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
  -e PHP_OPCACHE_JIT=tracing \
  -e NGINX_WORKER_CONNECTIONS=4096 \
  -v $(pwd)/app:/var/www/html:ro \
  kariricode/php-api-stack:latest
```

#### Memory-Constrained Environment

```bash
docker run -d \
  -p 80:80 \
  --memory="512m" \
  -e PHP_MEMORY_LIMIT=256M \
  -e PHP_FPM_PM=dynamic \
  -e PHP_FPM_PM_MAX_CHILDREN=25 \
  -e PHP_OPCACHE_MEMORY=128 \
  -v $(pwd)/app:/var/www/html:ro \
  kariricode/php-api-stack:latest
```

---

## 📊 Stack Components

| Component | Version | Purpose |
|-----------|---------|---------|
| **PHP-FPM** | 8.4.13 | PHP processing with optimized pool |
| **Nginx** | 1.27.3 | High-performance web server |
| **Redis** | 7.2.11 | Cache and session management |
| **Alpine Linux** | 3.21 | Minimal base image |
| **Composer** | 2.8.12 | PHP dependency manager |
| **Symfony CLI** | 5.15.1 | Symfony tools (dev only) |
| **Xdebug** | 3.4.6 | PHP debugger (dev only) |

### PHP Extensions

**Core Extensions** (Pre-installed):
```
pdo, pdo_mysql, opcache, intl, zip, bcmath, gd, mbstring, xml, sockets
```

**PECL Extensions** (Pre-installed):
```
redis (6.1.0), apcu (5.1.24), uuid (1.2.1), imagick (3.7.0), amqp (2.1.2)
```

**Built-in Extensions** (Always available):
```
json, curl, fileinfo, ctype, iconv, session, tokenizer, filter, hash, openssl
```

---

## 🏥 Health Checks

### Simple Health Check

Lightweight endpoint for load balancers and orchestrators:

```bash
curl http://localhost:8080/health
# Response: healthy
```

HTTP 200 if healthy, 503 if unhealthy.

### Comprehensive Health Check

Detailed diagnostics with component-level checks:

```bash
curl http://localhost:8080/health.php | jq
```

Returns JSON with:
- Overall status (healthy/degraded/unhealthy)
- PHP runtime details (version, memory, extensions)
- OPcache statistics (hit rate, memory, JIT status)
- Redis connectivity (latency, memory, persistence)
- System resources (disk, CPU, memory)
- Application directories (permissions, accessibility)

**Docker Healthcheck**:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost/health"]
  interval: 30s
  timeout: 3s
  retries: 3
  start_period: 10s
```

**Kubernetes Probes**:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 80
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health.php
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 5
```

---

## 🎭 Framework Integration

### Symfony

```bash
docker run -d \
  -p 8080:80 \
  -e APP_ENV=prod \
  -e APP_SECRET=$(openssl rand -hex 16) \
  -e DATABASE_URL=mysql://user:pass@db:3306/symfony \
  -v $(pwd):/var/www/html:ro \
  kariricode/php-api-stack:latest
```

### Laravel

```bash
docker run -d \
  -p 8080:80 \
  -e APP_ENV=production \
  -e APP_KEY=base64:your-key-here \
  -e DB_CONNECTION=mysql \
  -e DB_HOST=db \
  -e DB_DATABASE=laravel \
  -v $(pwd):/var/www/html:ro \
  kariricode/php-api-stack:latest
```

### Custom PHP App

```bash
docker run -d \
  -p 8080:80 \
  -e APP_ENV=production \
  -v $(pwd)/my-app:/var/www/html:ro \
  kariricode/php-api-stack:latest
```

**Directory Structure**: Your app must have `public/index.php` as the entry point.

---

## 🔐 Security Features

### Built-in Security

- ✅ **Non-root Services**: All services run as unprivileged users (`www-data`, `nginx`, `redis`)
- ✅ **Security Headers**: X-Frame-Options, X-Content-Type-Options, CSP, HSTS
- ✅ **Rate Limiting**: 10 req/s (general), 100 req/s (API endpoints)
- ✅ **Disabled Functions**: Dangerous PHP functions blocked
- ✅ **Open Basedir**: Restricted to `/var/www/html` and `/tmp`
- ✅ **Hidden Tokens**: Server version and PHP version hidden

### Best Practices

- Always use specific version tags in production
- Mount application code as read-only (`:ro`)
- Store secrets in environment variables
- Enable HTTPS via reverse proxy (Nginx, Traefik, etc.)
- Regularly update to latest patch versions
- Use vulnerability scanning (Trivy included in CI/CD)

---

## 🧪 Testing & Development

### Development Image

The `dev` tag includes additional tools for local development:

```bash
docker run -d \
  -p 8001:80 \
  -p 9003:9003 \
  -e APP_ENV=development \
  -e APP_DEBUG=true \
  -e PHP_DISPLAY_ERRORS=On \
  -e XDEBUG_ENABLE=1 \
  -v $(pwd)/app:/var/www/html \
  kariricode/php-api-stack:dev
```

**Includes**:
- Xdebug 3.4.6 (configurable)
- Symfony CLI 5.15.1
- Extended error reporting
- File change detection (OPcache revalidation)

### Running Tests

```bash
# Quick version check
docker run --rm kariricode/php-api-stack:latest php -v

# Full test suite
docker run --rm kariricode/php-api-stack:test /usr/local/bin/health-check.sh
```

---

## 🛠 Makefile Commands

The repository includes **three specialized Makefiles** with 50+ commands:

### Main Makefile (Build & Runtime)

```bash
make build              # Build production image
make build-dev          # Build dev image
make run                # Run production container
make run-dev            # Run dev container
make test               # Run test suite
make lint               # Lint Dockerfile
make scan               # Security scan
```

### Makefile.dockerhub (Publishing)

```bash
make hub-help           # Show Docker Hub commands
make version            # Show current version
make bump-patch         # Bump patch version
make tag-production     # Tag production image
make push-production    # Push to Docker Hub
make release-production # Full release pipeline
```

### Makefile.compose (Orchestration)

```bash
make compose-help       # Show Compose commands
make compose-up         # Start services
make compose-logs       # View logs
make compose-shell      # Access container
```

**Get the source**: [https://github.com/kariricode/php-api-stack](https://github.com/kariricode/php-api-stack)

---

## 🐛 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs <container-name>

# Common causes:
# - Port already in use → Change port: -p 8081:80
# - Volume permissions → Fix: chmod -R 755 app/
# - Memory limits → Increase: --memory="1g"
```

### 502 Bad Gateway

```bash
# Check PHP-FPM
docker exec <container> ps aux | grep php-fpm

# Check logs
docker exec <container> tail -f /var/log/php/fpm-error.log
docker exec <container> tail -f /var/log/nginx/error.log

# Restart PHP-FPM
docker exec <container> kill -USR2 $(cat /var/run/php/php-fpm.pid)
```

### Redis Connection Issues

```bash
# Check Redis (internal)
docker exec <container> redis-cli -h 127.0.0.1 ping
# Should return: PONG

# Check REDIS_HOST variable
docker exec <container> env | grep REDIS_HOST
# Should be: 127.0.0.1 (standalone) or redis (compose)

# Test with password (if configured)
docker exec <container> redis-cli -h 127.0.0.1 -a "password" ping
```

### Slow Performance

```bash
# Check OPcache hit rate (should be >95%)
docker exec <container> php -r "
\$stats = opcache_get_status()['opcache_statistics'];
echo 'Hit Rate: ' . \$stats['opcache_hit_rate'] . '%' . PHP_EOL;
"

# Check resource usage
docker stats <container>

# Solutions:
# - Increase OPcache memory: -e PHP_OPCACHE_MEMORY=512
# - Increase FPM workers: -e PHP_FPM_PM_MAX_CHILDREN=100
# - Add container resources: --memory="2g" --cpus="4"
```

**Complete troubleshooting guide**: [IMAGE_USAGE_GUIDE.md](https://github.com/kariricode/php-api-stack/blob/main/IMAGE_USAGE_GUIDE.md#troubleshooting)

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **[README.md](https://github.com/kariricode/php-api-stack)** | Project overview and quick start |
| **[IMAGE_USAGE_GUIDE.md](https://github.com/kariricode/php-api-stack/blob/main/IMAGE_USAGE_GUIDE.md)** | Complete usage guide for end users |
| **[DOCKER_COMPOSE_GUIDE.md](https://github.com/kariricode/php-api-stack/blob/main/DOCKER_COMPOSE_GUIDE.md)** | Docker Compose orchestration |
| **[TESTING.md](https://github.com/kariricode/php-api-stack/blob/main/TESTING.md)** | Testing procedures for maintainers |

---

## 🔄 Version History

### v1.5.0 (2025-10-24) - Latest

**Docker Hub Integration**:
- Fixed `hub-check` command display bug
- Simplified dev tagging: only `dev` tag (removed `dev-X.Y.Z`)
- Fixed version bump commands (`bump-patch`, `bump-minor`, `bump-major`)
- Improved `hub-check` output with checkmarks (✓/✗)
- Added comprehensive Docker Hub utilities

**Breaking Changes**:
- Dev versioned tags (`dev-X.Y.Z`) are no longer created

### v1.4.5 (2025-10-24)

**Build System**:
- Fixed PHP extension quoting in Makefile
- Secure `.env` parsing to prevent command execution
- Proper escaping for build args

**Redis Integration**:
- Automatic `REDIS_HOST` override for standalone containers
- Smart DNS fallback in health checks
- Documentation improvements

**Dockerfile**:
- Fixed OPcache validation (Zend extension check)
- Added `util-linux` for UUID extension
- Fixed shellcheck errors

### v1.4.3 (2025-10-20)

- Refactored Makefile with 50+ organized commands
- Enhanced development workflow
- Improved health check monitoring
- Updated documentation

### v1.2.1 (2025-10-18)

- Added comprehensive Makefile
- Docker Compose integration
- Multiple service profiles
- Enhanced health checks

### v1.2.0 (2025-10-15)

- PHP 8.4, Nginx 1.27.3, Redis 7.2
- OPcache + JIT optimization
- Socket-based PHP-FPM
- Environment variable configuration

**Full changelog**: [GitHub Releases](https://github.com/kariricode/php-api-stack/releases)

---

## 🧭 Related Projects

This image is part of the **KaririCode** ecosystem:

### KaririCode Framework

Modern PHP framework with advanced features:
- **Repository**: [KaririCode-Framework](https://github.com/KaririCode-Framework)
- **30+ Components**: DI, Router, Auth, Cache, EventDispatcher, etc.
- **ARFA Architecture**: Adaptive Reactive Flow Architecture

### KaririCode DevKit

Development environment automation:
- **Repository**: [kariricode/devkit](https://github.com/kariricode/devkit)
- **Features**: Docker, Compose, quality tools, CI/CD
- **Integration**: Uses this Docker image

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository: [https://github.com/kariricode/php-api-stack](https://github.com/kariricode/php-api-stack)
2. Create a feature branch
3. Make your changes
4. Submit a Pull Request

**Standards**:
- Follow PSR-12 for PHP
- Use Conventional Commits
- Add tests for new features
- Update documentation

---

## 📄 License

This project is licensed under the MIT License.  
See [LICENSE](https://github.com/kariricode/php-api-stack/blob/main/LICENSE) in the repository.

---

## 🙌 Support

- **Issues**: [GitHub Issues](https://github.com/kariricode/php-api-stack/issues)
- **Discussions**: [GitHub Discussions](https://github.com/kariricode/php-api-stack/discussions)
- **Docker Hub**: [kariricode/php-api-stack](https://hub.docker.com/r/kariricode/php-api-stack)

---

<div align="center">

**Made with 💚 by [KaririCode](https://kariricode.org)**

[![KaririCode](https://img.shields.io/badge/KaririCode-Framework-green)](https://kariricode.org)
[![GitHub](https://img.shields.io/badge/GitHub-KaririCode-black)](https://github.com/KaririCode-Framework)

</div>