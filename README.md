# 🐳 PHP API Stack - Production-Ready Docker Image

<div align="center">

[![Docker Pulls](https://img.shields.io/docker/pulls/kariricode/php-api-stack)](https://hub.docker.com/r/kariricode/php-api-stack)
[![Docker Image Size](https://img.shields.io/docker/image-size/kariricode/php-api-stack/latest)](https://hub.docker.com/r/kariricode/php-api-stack)
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
- 🛠️ **Developer-friendly** with extensive Make targets and examples
- 🔒 **Security-first** with rate limiting, headers, and vulnerability scanning
- 📦 **Multi-platform** support (amd64, arm64)
- 🎭 **Flexible deployment** via Docker or Docker Compose with profiles

---

## 🚀 Quick Start

### Option 1: Docker Run (Simple)

```bash
# Pull the image
docker pull kariricode/php-api-stack:latest

# Run with demo page
docker run -d -p 8080:80 --name my-api kariricode/php-api-stack:latest

# Access the demo
open http://localhost:8080
```

### Option 2: With Your Application

```bash
docker run -d \
  -p 8080:80 \
  -v $(pwd)/app:/var/www/html \
  --env-file .env \
  --name my-api \
  kariricode/php-api-stack:latest
```

### Option 3: Docker Compose (Recommended for Development)

```bash
# Copy example files
cp .env.example .env
cp docker-compose.example.yml docker-compose.yml

# Start with profiles
make compose-up PROFILES="db,monitoring"

# Or start everything
make compose-up-all
```

**📖 See [DOCKER_COMPOSE_GUIDE.md](DOCKER_COMPOSE_GUIDE.md) for complete Docker Compose documentation**

✅ **The stack is ready with demo page, health checks, and all services running.**

---

## 📚 Documentation

| Document | Audience | Description |
|----------|----------|-------------|
| **[IMAGE_USAGE_GUIDE.md](IMAGE_USAGE_GUIDE.md)** | End Users | How to use the published image |
| **[DOCKER_COMPOSE_GUIDE.md](DOCKER_COMPOSE_GUIDE.md)** | Developers | Complete Docker Compose setup guide |
| **[TESTING.md](TESTING.md)** | Maintainers | Complete testing guide |
| **[DOCKER_HUB.md](DOCKER_HUB.md)** | Publishers | How to publish to Docker Hub |

---

## 🗃️ Architecture

```
Client → Nginx (port 80) → PHP-FPM (Unix socket) → PHP Application
              ↓                    ↓
         FastCGI Cache         Redis (sessions/cache)
```

**Container Management**: Services managed by custom entrypoint with health monitoring

---

## 📦 Stack Components

| Component | Version | Purpose |
|-----------|---------|---------|
| **PHP-FPM** | 8.4 | PHP processing with optimized pool |
| **Nginx** | 1.27.3 | High-performance web server |
| **Redis** | 7.2 | Cache and session management |
| **Composer** | 2.8.12 | PHP dependency manager |
| **Symfony CLI** | 5.15.1 | Symfony tools (dev build only) |

---

## 📌 PHP Extensions

### Core Extensions (Installed)
```
pdo, pdo_mysql, opcache, intl, zip, bcmath, gd, mbstring, xml, sockets
```

### PECL Extensions (Installed)
```
redis, apcu, uuid
```

### Built-in Extensions (Auto-available)
```
json, curl, fileinfo, ctype, iconv, session, tokenizer, filter
```

**Add more?** Edit `.env` and rebuild:
```bash
PHP_CORE_EXTENSIONS="... newext"
make build
```

---

## ⚙️ Configuration

All configurations via `.env` file:

```bash
# PHP Performance
PHP_MEMORY_LIMIT=256M
PHP_OPCACHE_MEMORY=256
PHP_OPCACHE_JIT=tracing
PHP_FPM_PM_MAX_CHILDREN=60

# Environment
APP_ENV=production
APP_DEBUG=false
PHP_DISPLAY_ERRORS=Off

# Extensions
PHP_CORE_EXTENSIONS="pdo pdo_mysql opcache..."
PHP_PECL_EXTENSIONS="redis apcu uuid"
```

**Full reference**: See `.env.example`

---

## 🧰 Makefile Commands

The project includes a comprehensive Makefile with **logically organized targets by similarity**. Run `make help` for the complete list.

### 🏗️ Build Targets

```bash
make build              # Build production image
make build-dev          # Build dev image (with Symfony CLI, optional Xdebug)
make build-no-cache     # Build without cache
make build-test-image   # Build test image with comprehensive health check
make lint               # Lint Dockerfile with hadolint
make scan               # Scan for vulnerabilities with Trivy
```

### 🚀 Runtime - Run Containers

```bash
make run                # Run local container (port 8080)
make run-dev            # Run development container (port 8001, Xdebug ready)
make run-test           # Run test container with comprehensive health checks
```

### ⏹️ Runtime - Stop & Restart

```bash
make stop               # Stop and remove local container
make stop-dev           # Stop and remove dev container
make stop-test          # Stop and remove test container
make restart            # Restart local container
make restart-dev        # Restart development container
make restart-test       # Restart test container
```

### 📋 Runtime - Logs & Shell

```bash
make logs               # View local container logs (follow)
make logs-dev           # View development container logs
make logs-test          # View test container logs
make shell              # Access local container shell (alias: exec)
make shell-dev          # Access development container shell
make shell-test         # Access test container shell
make stats              # Show container resource usage
```

### 🧪 Test Targets

```bash
make test               # Run full test suite (versions, config, health)
make test-quick         # Quick component version checks
make test-structure     # Test container structure and directories
make test-health        # Test comprehensive health check endpoint
make test-health-status # Show health check status summary
make test-health-watch  # Live health monitoring (updates every 5s)
```

### 📤 Push & Publish Targets

```bash
make push               # Push all tags to Docker Hub
make push-dev           # Push dev image with custom tag (IMAGE_TAG=xxx)
make publish-dev        # Build and push dev image (build-dev + push-dev)
```

### 🏷️ Release & Versioning

```bash
make tag-latest         # Tag current version as latest/major/minor
make release            # Full release pipeline (lint+build+test+scan+push)
make version            # Display current version
make bump-patch         # Bump patch version (x.x.X)
make bump-minor         # Bump minor version (x.X.x)
make bump-major         # Bump major version (X.x.x)
```

### 🧹 Cleanup Targets

```bash
make clean              # Remove local images and containers
make clean-all          # Deep clean (volumes + build cache)
```

### ℹ️ Information Targets

```bash
make info               # Show image information (tags, sizes)
```

### 🐳 Docker Compose Targets

For complete infrastructure setup with databases, load balancers, and monitoring:

```bash
make compose-help       # Show Docker Compose help
make compose-up         # Start services (respects PROFILES)
make compose-up-all     # Start with all profiles (loadbalancer,monitoring)
make compose-down-v     # Stop and remove volumes
make compose-down-all   # Stop everything including all profiles
make compose-logs       # Tail logs for active services
make compose-logs-all   # Tail logs for all services
make compose-ps         # Show container status
make compose-shell      # Access service shell (default: php-api-stack)
```

**Profile Examples:**
```bash
# Start with database
make compose-up PROFILES="db"

# Start with monitoring
make compose-up PROFILES="monitoring"

# Start with multiple profiles
make compose-up PROFILES="db,monitoring"

# Start specific services
make compose-up-svc SERVICES="php-api-stack mysql"

# View logs for specific service
make compose-logs-svc SERVICES="php-api-stack"
```

### Quick Workflow Examples

**Development Workflow:**
```bash
make build-dev          # Build dev image
make run-dev            # Start dev container (with Xdebug)
make logs-dev           # View dev logs
make shell-dev          # Access dev container
make restart-dev        # Restart dev container
make stop-dev           # Stop dev container
```

**Testing Workflow:**
```bash
make build-test-image   # Build test image
make run-test           # Start test container
make test-health-watch  # Monitor health in real-time
make logs-test          # View test logs
make stop-test          # Stop test container
```

**Release Workflow:**
```bash
make lint               # Lint Dockerfile
make build              # Build production image
make test               # Run tests
make scan               # Security scan
make bump-patch         # Bump version
make release            # Full release pipeline
```

---

## 🐳 Docker Compose

The project includes a complete `docker-compose.example.yml` with multiple service profiles:

### Available Profiles

- **Base** (always active): `php-api-stack` - The main application container
- **db**: MySQL database with optimized configuration
- **loadbalancer**: Nginx load balancer for scaling
- **monitoring**: Prometheus + Grafana + cAdvisor stack

### Quick Start

```bash
# 1. Setup environment
cp .env.example .env
cp docker-compose.example.yml docker-compose.yml

# 2. Start base services
make compose-up

# 3. Start with database
make compose-up PROFILES="db"

# 4. Start with monitoring
make compose-up PROFILES="monitoring"

# 5. Start everything
make compose-up-all  # Equivalent to PROFILES="loadbalancer,monitoring"

# 6. View services
make compose-ps

# 7. View logs
make compose-logs

# 8. Access application
open http://localhost:8089

# 9. Access monitoring (if enabled)
open http://localhost:3000  # Grafana (admin/HmlGrafana_7uV4mRp)
open http://localhost:9091  # Prometheus
```

### Service URLs

When all profiles are active:

| Service | URL | Description |
|---------|-----|-------------|
| Application | http://localhost:8089 | Main PHP application |
| Health Check | http://localhost:8089/health.php | Comprehensive health endpoint |
| Prometheus | http://localhost:9091 | Metrics collection |
| Grafana | http://localhost:3000 | Monitoring dashboards |
| MySQL | localhost:3307 | Database (if db profile enabled) |

**📖 Complete guide with examples**: [DOCKER_COMPOSE_GUIDE.md](DOCKER_COMPOSE_GUIDE.md)

---

## 🛠️ Development Workflow

### For Maintainers (GitHub)

```bash
# Clone and build
git clone https://github.com/kariricode/php-api-stack.git
cd php-api-stack
make build

# Run tests
make test

# Run with comprehensive health check
make run-test
make test-health

# Release
make bump-patch
make release
```

**Complete guide**: [TESTING.md](TESTING.md)

### For Publishers (Docker Hub)

```bash
# Build and push
make build
make push

# Or full release
make release  # lint + build + test + scan + push
```

**Complete guide**: [DOCKER_HUB.md](DOCKER_HUB.md)

### For End Users

```bash
# Pull image
docker pull kariricode/php-api-stack:latest

# Run with your app
docker run -d \
  -p 8080:80 \
  -v $(pwd)/app:/var/www/html \
  kariricode/php-api-stack:latest
```

**Complete guide**: [IMAGE_USAGE_GUIDE.md](IMAGE_USAGE_GUIDE.md)

---

## 🏥 Health Check System

The stack includes **two health check implementations**:

### Simple Health Check (Production)
```bash
curl http://localhost:8080/health
# {"status":"healthy","timestamp":"2025-10-17T14:30:00+00:00"}
```

### Comprehensive Health Check (Testing/Monitoring)
```bash
curl http://localhost:8080/health.php | jq
```

**Features:**
- ✅ PHP Runtime validation (version, memory, SAPI)
- ✅ PHP Extensions check (required + optional)
- ✅ OPcache performance (memory, hit rate, JIT status)
- ✅ Redis connectivity (latency, stats, memory)
- ✅ System resources (disk, CPU load, memory)
- ✅ Application directories (permissions, accessibility)

**Architecture**: SOLID principles, Design Patterns (Strategy, Template Method, Facade)

**Build with comprehensive health**:
```bash
make build-test-image
make run-test
make test-health
```

---

## 🔐 Security Features

- ✅ Security headers (X-Frame-Options, CSP, HSTS)
- ✅ Rate limiting (general: 10r/s, API: 100r/s)
- ✅ Disabled dangerous PHP functions
- ✅ Open basedir restrictions
- ✅ Hidden server tokens

---

## 🛠 Troubleshooting

### Container won't start
```bash
docker logs <container-id>
make test-structure
```

### 502 Bad Gateway
```bash
# Check PHP-FPM socket
docker exec <container> ls -la /var/run/php/php-fpm.sock

# Check logs
make logs
```

### Poor Performance
```bash
docker stats <container>
docker exec <container> php -r "print_r(opcache_get_status());"
```

**Full troubleshooting**: [IMAGE_USAGE_GUIDE.md](IMAGE_USAGE_GUIDE.md)

---

## 📖 Documentation Reference

- [PHP 8.4 Documentation](https://www.php.net/docs.php)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Symfony Best Practices](https://symfony.com/doc/current/best_practices.html)
- [Docker Compose](https://docs.docker.com/compose/)
- [Twelve-Factor App](https://12factor.net/)

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open Pull Request

**Standards:**
- Follow [PSR-12](https://www.php-fig.org/psr/psr-12/) for PHP
- Use [Conventional Commits](https://www.conventionalcommits.org/)
- Add tests for new features
- Update documentation

---

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) file.

---

## 🌟 Support

- **Issues**: [GitHub Issues](https://github.com/kariricode/php-api-stack/issues)
- **Discussions**: [GitHub Discussions](https://github.com/kariricode/php-api-stack/discussions)
- **Docker Hub**: [kariricode/php-api-stack](https://hub.docker.com/r/kariricode/php-api-stack)

---

## 🧭 Roadmap & Contributing

Feature requests and PRs are welcome in the source repository:

* GitHub: [https://github.com/kariricode/php-api-stack](https://github.com/kariricode/php-api-stack)

For broader ecosystem projects, visit:

* KaririCode Framework: [https://github.com/KaririCode-Framework](https://github.com/KaririCode-Framework)

---

## 📝 Changelog

**1.4.3** (Latest)

* ✨ **Makefile refactored** with semantic grouping by similarity (Build, Push, Runtime, Test, Validation, Release, etc.)
* 🎯 **Enhanced development workflow** with dedicated dev container targets (`run-dev`, `stop-dev`, `restart-dev`, `logs-dev`, `shell-dev`)
* 🧪 **Improved test targets** with health monitoring (`test-health-status`, `test-health-watch`)
* 📊 **Better organization** of 50+ Make targets into logical categories
* 📚 **Updated documentation** reflecting new command structure
* 🔧 **Zero breaking changes** - all existing targets work identically

**1.2.1**

* Added comprehensive Makefile with Docker Compose integration
* Added Docker Compose example with multiple profiles (db, loadbalancer, monitoring)
* Improved documentation structure with dedicated guides
* Enhanced health check system with monitoring capabilities

**1.2.0**

* PHP 8.4, Nginx 1.27.3, Redis 7.2
* Socket-based PHP-FPM; OPcache + JIT optimized
* `/health.php` endpoint; improved entrypoint & config processor
* Extensive env-var configuration for Nginx/PHP/Redis

> Full release notes are available in the GitHub repository.

---

**Made with 💚 by KaririCode** – [https://kariricode.org/](https://kariricode.org/)