# 🐳 PHP API Stack - Production-Ready Docker Image

<div align="center">

[![Docker Pulls](https://img.shields.io/docker/pulls/kariricode/php-api-stack)](https://hub.docker.com/r/kariricode/php-api-stack)
[![Docker Image Size](https://img.shields.io/docker/image-size/kariricode/php-api-stack/latest)](https://hub.docker.com/r/kariricode/php-api-stack)
[![Docker Image Version](https://img.shields.io/docker/v/kariricode/php-api-stack?sort=semver)](https://hub.docker.com/r/kariricode/php-api-stack)
[![License](https://img.shields.io/github/license/kariricode/php-api-stack)](LICENSE)
[![Build Status](https://img.shields.io/github/actions/workflow/status/kariricode/php-api-stack/build.yml)](https://github.com/kariricode/php-api-stack/actions)

**Production-grade PHP 8.4 + Nginx + Redis stack for modern web applications**

[Features](#-features) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Makefile Commands](#-makefile-commands) • [Docker Compose](#-docker-compose)

</div>

---

## ✨ Features

- 🚀 **PHP 8.4** with OPcache JIT (tracing mode) for maximum performance
- ⚡ **Nginx 1.27.3** optimized for high-throughput APIs
- 🔴 **Redis 7.2** for caching and session management
- 🎯 **Production-ready** with security hardening and performance tuning
- 📊 **Comprehensive health checks** for monitoring and orchestration
- 🛠️ **Developer-friendly** with extensive Make targets (50+) and examples
- 🔒 **Security-first** with rate limiting, headers, and vulnerability scanning
- 📦 **Multi-platform** support (amd64, arm64)
- 🎭 **Flexible deployment** via Docker or Docker Compose with profiles
- 🧰 **Three specialized Makefiles** for building, Docker Hub, and Compose operations

---

## 🚀 Quick Start

### Option 1: Docker Run (Simplest)

```bash
# Pull and run with demo page
docker pull kariricode/php-api-stack:latest
docker run -d -p 8080:80 --name my-api kariricode/php-api-stack:latest

# Access the demo
curl http://localhost:8080
# or open http://localhost:8080 in browser
```

### Option 2: With Your Application

```bash
docker run -d \
  -p 8080:80 \
  -v $(pwd)/app:/var/www/html \
  -v $(pwd)/.env:/var/www/html/.env:ro \
  -e APP_ENV=production \
  --name my-api \
  kariricode/php-api-stack:latest
```

### Option 3: Docker Compose (Recommended)

```bash
# Setup
cp .env.example .env
cp docker-compose.example.yml docker-compose.yml

# Start base services
make compose-up

# Start with database + monitoring
make compose-up PROFILES="db,monitoring"

# Or start everything
make compose-up-all

# Access
open http://localhost:8089          # Application
open http://localhost:8089/health   # Health check
open http://localhost:3000          # Grafana (admin/password)
```

**📖 See [DOCKER_COMPOSE_GUIDE.md](DOCKER_COMPOSE_GUIDE.md) for complete Docker Compose documentation**

---

## 📚 Documentation

| Document | Audience | Description |
|----------|----------|-------------|
| **[IMAGE_USAGE_GUIDE.md](IMAGE_USAGE_GUIDE.md)** | End Users | How to use the published Docker image |
| **[DOCKER_COMPOSE_GUIDE.md](DOCKER_COMPOSE_GUIDE.md)** | Developers | Complete Docker Compose orchestration guide |
| **[TESTING.md](TESTING.md)** | Maintainers | Comprehensive testing procedures |
| **[DOCKER_HUB.md](DOCKER_HUB.md)** | Publishers | Docker Hub publication workflow |

---

## 🗃️ Architecture

```
                    ┌─────────────────────────────────┐
                    │         Client Request          │
                    └─────────────┬───────────────────┘
                                  │
                    ┌─────────────▼───────────────────┐
                    │   Nginx (port 80)               │
                    │   • FastCGI Cache               │
                    │   • Rate Limiting               │
                    │   • Security Headers            │
                    └─────────────┬───────────────────┘
                                  │ Unix Socket
                    ┌─────────────▼───────────────────┐
                    │   PHP-FPM 8.4                   │
                    │   • OPcache + JIT               │
                    │   • Pool Manager (60 children)  │
                    └─────────────┬───────────────────┘
                                  │
                    ┌─────────────▼───────────────────┐
                    │   PHP Application               │
                    │   • Framework (Symfony/Laravel) │
                    │   • Business Logic              │
                    └─────────────┬───────────────────┘
                                  │
                    ┌─────────────▼───────────────────┐
                    │   Redis (sessions/cache)        │
                    │   • AOF Persistence             │
                    │   • LRU Eviction                │
                    └─────────────────────────────────┘
```

**Container Management**: All services orchestrated by custom entrypoint with health monitoring and graceful shutdown

---

## 📦 Stack Components

| Component | Version | Purpose | Configuration |
|-----------|---------|---------|--------------|
| **PHP-FPM** | 8.4.13 | PHP processing | Optimized pool, OPcache JIT |
| **Nginx** | 1.27.3 | Web server | FastCGI cache, rate limiting |
| **Redis** | 7.2.11 | Cache & sessions | AOF persistence, LRU eviction |
| **Composer** | 2.8.12 | Dependency manager | Included in production |
| **Symfony CLI** | 5.15.1 | Symfony tools | Dev image only |
| **Xdebug** | 3.4.6 | PHP debugger | Dev image only (optional) |

---

## 📌 PHP Extensions

### Core Extensions (Pre-installed)
```
pdo, pdo_mysql, opcache, intl, zip, bcmath, gd, mbstring, xml, sockets
```

### PECL Extensions (Pre-installed)
```
redis (6.1.0), apcu (5.1.24), uuid (1.2.1), imagick (3.7.0), amqp (2.1.2)
```

### Built-in Extensions (Always Available)
```
json, curl, fileinfo, ctype, iconv, session, tokenizer, filter, hash, openssl
```

### Adding Custom Extensions

Edit `.env` before building:
```bash
# Add your extension to the list
PHP_CORE_EXTENSIONS="pdo pdo_mysql opcache intl zip bcmath gd mbstring xml sockets mysqli"
PHP_PECL_EXTENSIONS="redis apcu uuid xdebug"

# Rebuild
make build
```

**Note**: For production images, extensions are optimized and loaded automatically.

---

## ⚙️ Configuration

All configuration is managed via `.env` file with extensive customization options:

### Essential Variables

```bash
# Environment
APP_ENV=production                    # production|development|test
APP_DEBUG=false                       # Enable debug mode (dev only)

# PHP Performance
PHP_MEMORY_LIMIT=256M                 # Memory limit per request
PHP_MAX_EXECUTION_TIME=60             # Script timeout
PHP_OPCACHE_MEMORY=256                # OPcache memory (MB)
PHP_OPCACHE_JIT=tracing               # JIT mode: off|tracing|function
PHP_OPCACHE_ENABLE=1                  # Enable OPcache (always 1 in prod)

# PHP-FPM Pool
PHP_FPM_PM=dynamic                    # Process manager mode
PHP_FPM_PM_MAX_CHILDREN=60            # Max child processes
PHP_FPM_PM_START_SERVERS=10           # Initial servers
PHP_FPM_PM_MIN_SPARE_SERVERS=5        # Min idle servers
PHP_FPM_PM_MAX_SPARE_SERVERS=20       # Max idle servers

# Redis
REDIS_HOST=127.0.0.1                  # Redis host (standalone mode)
REDIS_PASSWORD=your-secure-password   # Redis authentication
REDIS_DATABASES=16                    # Number of databases
REDIS_MAXMEMORY=256mb                 # Max memory usage
REDIS_MAXMEMORY_POLICY=allkeys-lru    # Eviction policy

# Nginx
NGINX_WORKER_PROCESSES=auto           # Worker processes (auto = CPU cores)
NGINX_WORKER_CONNECTIONS=2048         # Connections per worker
NGINX_KEEPALIVE_TIMEOUT=65            # Keep-alive timeout
NGINX_CLIENT_MAX_BODY_SIZE=20M        # Max upload size
```

### Development Mode

```bash
APP_ENV=development
APP_DEBUG=true
PHP_DISPLAY_ERRORS=On
PHP_OPCACHE_VALIDATE_TIMESTAMPS=1     # Reload PHP files without restart
XDEBUG_ENABLE=1                       # Enable Xdebug
```

**Full reference**: Copy `.env.example` and customize for your needs.

---

## 🧰 Makefile Commands

The project includes **three specialized Makefiles** for different purposes:

### 📁 Makefile Organization

| Makefile | Purpose | Commands |
|----------|---------|----------|
| **Makefile** | Build, test, run containers | 40+ commands |
| **Makefile.dockerhub** | Docker Hub operations | Version management, tagging, push, release |
| **Makefile.compose** | Docker Compose orchestration | Multi-service management |

Run `make help` for the main menu, or specialized help:
- `make hub-help` - Docker Hub commands
- `make compose-help` - Docker Compose commands

---

### 🏗️ Build Targets

```bash
make build              # Build production image (optimized)
make build-dev          # Build dev image (Symfony CLI + optional Xdebug)
make build-base         # Build base layer only (for debugging)
make build-test         # Build test image with comprehensive health check
make build-all          # Build both production and dev images
make lint               # Lint Dockerfile with hadolint
make scan               # Security scan with Trivy
make scan-dev           # Scan dev image for vulnerabilities
```

### 🚀 Runtime - Run Containers

```bash
make run                # Run production container (port 8080)
make run-dev            # Run dev container (port 8001, Xdebug on 9003)
make run-test           # Run test container with health monitoring
```

### ⏹️ Runtime - Stop & Restart

```bash
make stop               # Stop production container
make stop-dev           # Stop dev container
make stop-test          # Stop test container
make restart            # Restart production container
make restart-dev        # Restart dev container
```

### 📋 Runtime - Logs & Shell

```bash
make logs               # Follow production logs
make logs-dev           # Follow dev logs
make shell              # Open shell in production container
make shell-dev          # Open shell in dev container
```

### 🧪 Test Targets

```bash
make test               # Run comprehensive test suite
make test-quick         # Quick component version checks
make test-structure     # Validate container structure
make test-health        # Test health check endpoint
```

---

### 🐳 Docker Hub Commands

These commands are in **Makefile.dockerhub**. Run `make hub-help` for complete list.

#### Version Management

```bash
make version            # Show current version
make bump-patch         # Bump patch (1.5.0 → 1.5.1)
make bump-minor         # Bump minor (1.5.0 → 1.6.0)
make bump-major         # Bump major (1.5.0 → 2.0.0)
```

#### Tagging & Push

```bash
make tag-production     # Tag production image (latest, 1, 1.5, 1.5.0)
make tag-dev            # Tag dev image (dev only)
make push-production    # Push all production tags
make push-dev           # Push dev tag
make push-all           # Push all images
```

#### Complete Workflows

```bash
make publish-production # Build + Tag + Push production
make publish-dev        # Build + Tag + Push dev
make release-production # Full release: pre-check + build + test + scan + push
make release-all        # Release both production and dev
```

#### Hub Utilities

```bash
make hub-check          # Check if images exist on Docker Hub
make hub-tags           # List all published tags
make hub-info           # Show repository information
make hub-clean          # Remove old local tags
make pre-release-check  # Validate before release (git, docker, auth)
```

**Example Release Workflow:**
```bash
make bump-minor         # 1.5.0 → 1.6.0
make release-production # Full automated release
```

---

### 🎭 Docker Compose Commands

These commands are in **Makefile.compose**. Run `make compose-help` for complete list.

#### Lifecycle

```bash
make compose-up              # Start services (respects PROFILES)
make compose-up-all          # Start with all profiles
make compose-down-v          # Stop and remove volumes
make compose-down-all        # Stop everything + all profiles
make compose-restart         # Restart services
make compose-ps              # Show service status
```

#### Logs & Shell

```bash
make compose-logs            # Tail logs (all active services)
make compose-logs-all        # Tail logs (base + all profiles)
make compose-logs-svc        # Tail logs for specific services
make compose-shell           # Open shell in service
make compose-exec            # Execute command in service
```

#### Utilities

```bash
make compose-config          # Show resolved config
make compose-health          # Test health endpoint
make compose-open            # Open app/Prometheus/Grafana in browser
```

**Example with Profiles:**
```bash
# Start with database
make compose-up PROFILES="db"

# Start with monitoring
make compose-up PROFILES="monitoring"

# Start specific services
make compose-up-svc SERVICES="php-api-stack mysql"

# View specific logs
make compose-logs-svc SERVICES="php-api-stack"
```

---

### Quick Workflow Examples

**Development Workflow:**
```bash
make build-dev          # Build dev image
make run-dev            # Start dev (port 8001, Xdebug ready)
make logs-dev           # View logs
make shell-dev          # Access container
curl http://localhost:8001/health
```

**Testing Workflow:**
```bash
make build-test         # Build with comprehensive health check
make run-test           # Start test container
make test-health        # Test health endpoint
make logs-test          # View logs
```

**Release Workflow:**
```bash
make lint               # Lint Dockerfile
make build-all          # Build production + dev
make test               # Run tests
make scan               # Security scan
make bump-patch         # Bump version
make release-all        # Full release pipeline
make hub-check          # Verify on Docker Hub
```

**Docker Compose Workflow:**
```bash
make compose-up-all     # Start all services
make compose-ps         # Check status
make compose-logs       # View logs
make compose-open       # Open in browser
make compose-down-all   # Stop everything
```

---

## 🐳 Docker Compose

Complete orchestration with databases, load balancing, and monitoring.

### Available Profiles

| Profile | Services | Purpose |
|---------|----------|---------|
| **Base** | php-api-stack | Main application (always active) |
| **db** | mysql, redis-external | Databases with persistence |
| **loadbalancer** | nginx-lb | Nginx load balancer for scaling |
| **monitoring** | prometheus, grafana, cadvisor | Full monitoring stack |

### Quick Start

```bash
# 1. Setup
cp .env.example .env
cp docker-compose.example.yml docker-compose.yml

# 2. Start base
make compose-up

# 3. Start with profiles
make compose-up PROFILES="db,monitoring"

# 4. Or start everything
make compose-up-all

# 5. Access services
make compose-open  # Opens app, Prometheus, Grafana
```

### Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **Application** | http://localhost:8089 | - |
| **Health Check** | http://localhost:8089/health | - |
| **Prometheus** | http://localhost:9091 | - |
| **Grafana** | http://localhost:3000 | admin / HmlGrafana_7uV4mRp |
| **MySQL** | localhost:3307 | root / HmlMysql_9tQ2wRx |

### Management

```bash
# View status
make compose-ps

# View logs
make compose-logs

# Restart services
make compose-restart

# Scale application
docker compose up -d --scale php-api-stack=3

# Stop everything
make compose-down-all
```

**📖 Complete guide**: [DOCKER_COMPOSE_GUIDE.md](DOCKER_COMPOSE_GUIDE.md)

---

## 🛠️ Development Workflow

### For Maintainers

```bash
# 1. Clone and setup
git clone https://github.com/kariricode/php-api-stack.git
cd php-api-stack
cp .env.example .env

# 2. Build
make build-all

# 3. Test
make test
make scan

# 4. Run dev
make run-dev
curl http://localhost:8001/health

# 5. Release
make bump-patch
make release-production
```

**Complete guide**: [TESTING.md](TESTING.md)

### For Publishers

```bash
# Quick release
make release-production

# Or step by step
make lint
make build
make test
make scan
make bump-patch
make push-production
```

**Complete guide**: [DOCKER_HUB.md](DOCKER_HUB.md)

### For End Users

```bash
# Pull and run
docker pull kariricode/php-api-stack:latest
docker run -d -p 8080:80 \
  -v $(pwd)/app:/var/www/html \
  kariricode/php-api-stack:latest
```

**Complete guide**: [IMAGE_USAGE_GUIDE.md](IMAGE_USAGE_GUIDE.md)

---

## 🏥 Health Check System

Two health check implementations for different needs:

### 1. Simple Health Check (Production)

Lightweight endpoint for load balancers and orchestrators:

```bash
curl http://localhost:8080/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-10-24T22:00:00+00:00"
}
```

### 2. Comprehensive Health Check (Monitoring)

Detailed system diagnostics with component-level checks:

```bash
curl http://localhost:8080/health.php | jq
```

**Features:**
- ✅ **PHP Runtime**: Version, memory, SAPI, configuration
- ✅ **PHP Extensions**: Required and optional extensions validation
- ✅ **OPcache**: Hit rate, memory usage, JIT status, cached scripts
- ✅ **Redis**: Connectivity, latency, stats, memory usage, persistence
- ✅ **System Resources**: Disk space, CPU load, memory usage
- ✅ **Application**: Directory permissions, accessibility checks

**Response Structure:**
```json
{
  "status": "healthy|degraded|unhealthy",
  "timestamp": "2025-10-24T22:00:00+00:00",
  "overall": "✓ All Systems Operational",
  "components": {
    "php": { "status": "healthy", "details": {...} },
    "opcache": { "status": "healthy", "details": {...} },
    "redis": { "status": "healthy", "details": {...} },
    "system": { "status": "healthy", "details": {...} },
    "application": { "status": "healthy", "details": {...} }
  },
  "stack_info": {
    "docker_image": "kariricode/php-api-stack",
    "version": "1.5.0",
    "php_version": "8.4.13"
  }
}
```

### Using Health Checks

**With Docker:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1
```

**With Docker Compose:**
```yaml
services:
  app:
    image: kariricode/php-api-stack:latest
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 3s
      retries: 3
```

**With Kubernetes:**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 30

readinessProbe:
  httpGet:
    path: /health.php
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 10
```

**Makefile Commands:**
```bash
make test-health          # Test comprehensive health check
make test-health-status   # Show health summary
make test-health-watch    # Live monitoring (updates every 5s)
```

**Architecture**: Built with SOLID principles using Strategy, Template Method, and Facade patterns.

---

## 🔐 Security Features

Production-hardened security configuration:

### Nginx Security

- ✅ **Security Headers**: X-Frame-Options, X-Content-Type-Options, CSP, HSTS
- ✅ **Rate Limiting**: 
  - General: 10 req/s per IP
  - API endpoints: 100 req/s per IP
- ✅ **Hidden Tokens**: Server version and tokens hidden
- ✅ **Request Filtering**: Protection against common attacks

### PHP Security

- ✅ **Disabled Functions**: `exec`, `shell_exec`, `system`, `passthru`, etc.
- ✅ **Open Basedir**: Restricted to `/var/www/html` and `/tmp`
- ✅ **Expose PHP**: Off (version hidden)
- ✅ **File Uploads**: Configurable with size limits
- ✅ **Session Security**: Secure cookies, HTTP-only

### Redis Security

- ✅ **Authentication**: Password-protected (configurable)
- ✅ **Bind Address**: Internal only (127.0.0.1 or network)
- ✅ **Command Renaming**: Dangerous commands can be disabled
- ✅ **Persistence**: AOF with fsync control

### Container Security

- ✅ **Non-root User**: Application runs as `www-data`
- ✅ **Read-only Filesystem**: Where possible
- ✅ **Resource Limits**: CPU and memory constraints
- ✅ **Security Scanning**: Automated Trivy scans

**Scan for vulnerabilities:**
```bash
make scan       # Scan production image
make scan-dev   # Scan dev image
```

---

## 🛠 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs <container-id>

# Test structure
make test-structure

# Check entrypoint
docker run --rm kariricode/php-api-stack:latest cat /entrypoint.sh
```

### 502 Bad Gateway

```bash
# Check PHP-FPM socket
docker exec <container> ls -la /var/run/php/php-fpm.sock

# Check PHP-FPM status
docker exec <container> php-fpm -t

# Check logs
make logs
```

### Redis Connection Issues

**Standalone Mode:**
```bash
# Should use 127.0.0.1
docker exec <container> env | grep REDIS_HOST
# REDIS_HOST=127.0.0.1

# Test connection
docker exec <container> redis-cli -h 127.0.0.1 -a "$REDIS_PASSWORD" ping
```

**Docker Compose Mode:**
```bash
# Should use 'redis' (service name)
docker compose exec php-api-stack env | grep REDIS_HOST
# REDIS_HOST=redis

# Test connection
docker compose exec php-api-stack redis-cli -h redis -a "$REDIS_PASSWORD" ping
```

### Poor Performance

```bash
# Check container resources
docker stats <container>

# Check OPcache status
docker exec <container> php -r "print_r(opcache_get_status());"

# Check PHP-FPM pool
docker exec <container> cat /var/run/php/php-fpm.pid
docker exec <container> kill -USR2 $(cat /var/run/php/php-fpm.pid)
```

### Permission Issues

```bash
# Check ownership
docker exec <container> ls -la /var/www/html

# Fix permissions
docker exec <container> chown -R www-data:www-data /var/www/html
```

**Full troubleshooting guide**: [IMAGE_USAGE_GUIDE.md](IMAGE_USAGE_GUIDE.md#troubleshooting)

---

## 📖 External References

- [PHP 8.4 Documentation](https://www.php.net/docs.php)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Symfony Best Practices](https://symfony.com/doc/current/best_practices.html)
- [Laravel Deployment](https://laravel.com/docs/deployment)
- [Twelve-Factor App](https://12factor.net/)

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

### Getting Started

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Run tests: `make test`
5. Lint: `make lint`
6. Commit: `git commit -m 'feat: add amazing feature'`
7. Push: `git push origin feature/amazing-feature`
8. Open a Pull Request

### Standards

- **Code Style**: Follow [PSR-12](https://www.php-fig.org/psr/psr-12/) for PHP code
- **Commit Messages**: Use [Conventional Commits](https://www.conventionalcommits.org/)
  - `feat:` New features
  - `fix:` Bug fixes
  - `docs:` Documentation changes
  - `refactor:` Code refactoring
  - `test:` Test additions/changes
  - `chore:` Build/tooling changes
- **Testing**: Add tests for new features
- **Documentation**: Update relevant documentation

### Before Submitting

```bash
make lint               # Lint Dockerfile
make build-all          # Build all images
make test               # Run tests
make scan               # Security scan
```

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

**TL;DR**: You can use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the software.

---

## 🌟 Support & Community

### Get Help

- **Issues**: [GitHub Issues](https://github.com/kariricode/php-api-stack/issues)
- **Discussions**: [GitHub Discussions](https://github.com/kariricode/php-api-stack/discussions)
- **Docker Hub**: [kariricode/php-api-stack](https://hub.docker.com/r/kariricode/php-api-stack)

### Report Bugs

Found a bug? Please open an issue with:
- Docker image version
- Steps to reproduce
- Expected vs actual behavior
- Relevant logs

### Request Features

Have an idea? Open a discussion or issue with:
- Use case description
- Proposed solution
- Any alternative solutions considered

---

## 🧭 Roadmap

### Current Focus (v1.5.x)

- ✅ Comprehensive Makefile system with 50+ commands
- ✅ Docker Hub automation and versioning
- ✅ Docker Compose orchestration with profiles
- ✅ Advanced health check system
- 🔄 Performance benchmarking suite
- 🔄 Automated CI/CD workflows

### Future Plans (v1.6+)

- 📋 Multi-stage build optimization
- 📋 Additional PECL extensions (gRPC, protobuf)
- 📋 ARM64 native builds
- 📋 Kubernetes manifests and Helm charts
- 📋 Additional monitoring integrations (Datadog, New Relic)
- 📋 Development containers (devcontainer.json)

### Long-term Vision (v2.0+)

- 📋 PHP 8.5 support
- 📋 Alternative web servers (Caddy, FrankenPHP)
- 📋 WebAssembly integration
- 📋 Enhanced security profiles

---

## 📚 Related Projects

This image is part of the **KaririCode** ecosystem:

### KaririCode Framework

Modern PHP framework with advanced features:

- **Repository**: [KaririCode-Framework](https://github.com/KaririCode-Framework)
- **Features**: ARFA architecture, DI container, Router, Auth, etc.
- **Components**: 30+ independent packages
- **Documentation**: Comprehensive guides and examples

### KaririCode DevKit

Development environment automation:

- **Repository**: [kariricode/devkit](https://github.com/kariricode/devkit)
- **Features**: Docker + Compose, quality tools, CI/CD
- **Setup Time**: 2-3 minutes
- **Integration**: Uses this Docker image

---

## 📝 Changelog

### **v1.5.0** (2025-10-24)

**Docker Hub Integration:**
- ✨ Fixed `hub-check` command display bug (showing 'ag' instead of tag names)
- ✨ Simplified dev tagging strategy: only `dev` tag (removed `dev-X.Y.Z`)
- ✨ Fixed `bump-patch/bump-minor/bump-major` dollar sign escaping
- ✨ Improved `hub-check` output with checkmark indicators (✓/✗)
- ✨ Added comprehensive Docker Hub utilities (`hub-tags`, `hub-info`, `hub-clean`)

**Breaking Changes:**
- ⚠️ Dev versioned tags (`dev-X.Y.Z`) are no longer created or pushed to Docker Hub

### **v1.4.5** (2025-10-24)

**Build System:**
- ✨ Fixed PHP extension quoting in Makefile (`PHP_CORE_EXTENSIONS`, `PHP_PECL_EXTENSIONS`)
- ✨ Secure `.env` parsing in `build-from-env.sh` to prevent command execution
- ✨ Proper escaping for build args with spaces

**Redis Integration:**
- ✨ Automatic `REDIS_HOST` override to `127.0.0.1` for standalone containers
- ✨ Smart DNS fallback in health.php for docker-compose vs standalone modes
- ✨ Documentation improvements for `REDIS_HOST` behavior

**Dockerfile Fixes:**
- 🐛 Fixed OPcache validation check (Zend extension vs regular extension)
- 🐛 Added `util-linux` runtime dependency for UUID extension
- 🐛 Fixed SC1075 shellcheck error (`else if` → `elif`)
- ✨ Improved extension loading verification

### **v1.4.3**

**Makefile Refactoring:**
- ✨ Semantic grouping by similarity (Build, Push, Runtime, Test, Validation, Release)
- ✨ Enhanced development workflow with dedicated dev targets
- ✨ Improved test targets with health monitoring
- ✨ Better organization of 50+ Make targets
- 📚 Updated documentation

### **v1.2.1**

- ✨ Added comprehensive Makefile with Docker Compose integration
- ✨ Added Docker Compose example with multiple profiles
- ✨ Improved documentation structure
- ✨ Enhanced health check system

### **v1.2.0**

- ✨ PHP 8.4, Nginx 1.27.3, Redis 7.2
- ✨ Socket-based PHP-FPM communication
- ✨ OPcache + JIT optimization
- ✨ `/health.php` comprehensive endpoint
- ✨ Improved entrypoint and config processor
- ✨ Extensive environment variable configuration

### **v1.0.0**

- 🎉 Initial release
- ✨ PHP 8.3, Nginx 1.25, Redis 7.0
- ✨ Basic production configuration
- ✨ Docker and Docker Compose support

---

<div align="center">

**Made with 💚 by [KaririCode](https://kariricode.org)**

[![KaririCode](https://img.shields.io/badge/KaririCode-Framework-green)](https://kariricode.org)
[![GitHub](https://img.shields.io/badge/GitHub-KaririCode-black)](https://github.com/KaririCode-Framework)

</div>