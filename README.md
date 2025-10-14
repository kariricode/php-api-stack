# PHP API Stack

[![Docker Hub](https://img.shields.io/docker/v/kariricode/php-api-stack?label=Docker%20Hub&logo=docker)](https://hub.docker.com/r/kariricode/php-api-stack)
[![PHP Version](https://img.shields.io/badge/PHP-8.4-777BB4?logo=php)](https://www.php.net/)
[![Nginx Version](https://img.shields.io/badge/Nginx-1.27.3-009639?logo=nginx)](https://nginx.org/)
[![Redis Version](https://img.shields.io/badge/Redis-7.2-DC382D?logo=redis)](https://redis.io/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Production-ready Docker image with **PHP 8.4 + Nginx 1.27.3 + Redis 7.2 + Supervisor**, optimized for **Symfony**, **Laravel**, and **REST APIs**.

## ✨ Key Features

- 🚀 **Complete Stack**: PHP-FPM + Nginx + Redis + Supervisor
- ⚡ **Peak Performance**: OPcache with JIT, FastCGI cache, optimized PHP-FPM pools
- 🔧 **Flexible Configuration**: 100% customizable via environment variables
- 🛡️ **Enterprise Security**: Security headers, rate limiting, hardened configurations
- 🏥 **Comprehensive Health Check**: SOLID-based validation system (all components)
- 📊 **Production Monitoring**: Structured logs, metrics, health endpoints
- 🐳 **CI/CD Ready**: Automated Makefile, multi-platform builds
- ✅ **Automatic Validation**: Configuration processing and syntax checking

## 🎯 Ideal For

- ✅ REST APIs with Symfony 5.x/6.x/7.x or Laravel
- ✅ Microservices with high-performance PHP
- ✅ GraphQL APIs
- ✅ Asynchronous workers and queue processing
- ✅ Applications requiring aggressive caching

## 🚀 Quick Start

```bash
# Pull and run
docker run -d -p 8080:80 -v $(pwd)/app:/var/www/html kariricode/php-api-stack:latest

# Access
curl http://localhost:8080
```

**That's it!** The stack is ready with demo page, health checks, and all services running.

## 📚 Documentation

| Document | Audience | Description |
|----------|----------|-------------|
| **[IMAGE_USAGE_GUIDE.md](IMAGE_USAGE_GUIDE.md)** | End Users | How to use the published image |
| **[TESTING.md](TESTING.md)** | Maintainers | Complete testing guide |
| **[DOCKER_HUB.md](DOCKER_HUB.md)** | Publishers | How to publish to Docker Hub |

## 🏗️ Architecture

```
Client → Nginx (port 80) → PHP-FPM (Unix socket) → PHP Application
              ↓                    ↓
         FastCGI Cache         Redis (sessions/cache)
```

**Process Management**: Supervisor manages all services as PID 1

## 📦 Stack Components

| Component | Version | Purpose |
|-----------|---------|---------|
| **PHP-FPM** | 8.4 | PHP processing with optimized pool |
| **Nginx** | 1.27.3 | High-performance web server |
| **Redis** | 7.2 | Cache and session management |
| **Supervisor** | Latest | Process manager |
| **Composer** | 2.8.12 | PHP dependency manager |
| **Symfony CLI** | 7.3.0 | Symfony tools (optional) |

## 🔌 PHP Extensions

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

## 🏥 Health Check System

The stack includes **two health check implementations**:

### Simple Health Check (Production)
```bash
curl http://localhost:8080/health
# {"status":"healthy","timestamp":"2025-10-09T14:30:00+00:00"}
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

## 📊 Performance Metrics

With optimized configuration:

| Metric | Expected Value |
|--------|---------------|
| **Requests/sec** | 5,000-10,000 |
| **Latency P50** | < 50ms |
| **Latency P99** | < 200ms |
| **OPcache Hit Rate** | > 95% |
| **Memory Usage** | 200-500MB |

## 🔐 Security Features

- ✅ Security headers (X-Frame-Options, CSP, HSTS)
- ✅ Rate limiting (general: 10r/s, API: 100r/s)
- ✅ Disabled dangerous PHP functions
- ✅ Open basedir restrictions
- ✅ Hidden server tokens

## 📦 Available Tags

| Tag | Description | Use Case |
|-----|-------------|----------|
| `latest` | Latest stable | Production |
| `stable` | Production release | Production |
| `test` | With comprehensive health | Testing/Monitoring |
| `1.2.1` | Specific version | Version pinning |
| `1.2` | Minor version | Auto-updates (patch) |
| `1` | Major version | Auto-updates (minor+patch) |

## 🧰 Makefile Commands

Quick reference (run `make help` for full list):

```bash
# Build
make build              # Production build
make build-test-image   # Build with comprehensive health

# Test
make test               # Full test suite
make run-test           # Run test container
make test-health        # Test health endpoint
make test-health-watch  # Live monitoring

# Run
make run                # Run production container
make stop               # Stop container
make logs               # View logs

# Release
make release            # Full pipeline
make push               # Push to Docker Hub
```

## 🐛 Troubleshooting

### Container won't start
```bash
docker logs <container-id>
make test-structure
```

### 502 Bad Gateway
```bash
docker exec <container> supervisorctl status
docker exec <container> ls -la /var/run/php/php-fpm.sock
```

### Poor Performance
```bash
docker stats <container>
docker exec <container> php -r "print_r(opcache_get_status());"
```

**Full troubleshooting**: [IMAGE_USAGE_GUIDE.md](IMAGE_USAGE_GUIDE.md)

## 📖 Documentation Reference

- [PHP 8.4 Documentation](https://www.php.net/docs.php)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Symfony Best Practices](https://symfony.com/doc/current/best_practices.html)
- [Twelve-Factor App](https://12factor.net/)

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

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) file.

## 🌟 Support

- **Issues**: [GitHub Issues](https://github.com/kariricode/php-api-stack/issues)
- **Discussions**: [GitHub Discussions](https://github.com/kariricode/php-api-stack/discussions)
- **Docker Hub**: [kariricode/php-api-stack](https://hub.docker.com/r/kariricode/php-api-stack)

## 📅 Changelog

### [1.2.1] - 2025-10-09
- 🏥 Added comprehensive health check with SOLID architecture
- 📊 Detailed validation for all stack components
- 🔧 Enhanced Makefile with health monitoring
- 📚 Separated documentation (README, TESTING, DOCKER_HUB, IMAGE_USAGE_GUIDE)
- ✅ Production and test build separation

### [1.2.0] - 2025-10-08
- ✨ Improved PHP extension installation
- 🔧 Enhanced build script
- 📚 Complete English documentation
- 🛠 Fixed PHP-FPM socket performance
- ⚡ Production optimizations

## 💬 Author

**kariricode**
- GitHub: [@kariricode](https://github.com/kariricode)
- Docker Hub: [kariricode](https://hub.docker.com/u/kariricode)

---

<div align="center">

⭐ **If this project helped you, give it a star!** ⭐

📧 **Commercial support**: kariricode@github.com

🔗 **Links**: [Docker Hub](https://hub.docker.com/r/kariricode/php-api-stack) | [GitHub](https://github.com/kariricode/php-api-stack) | [Documentation](IMAGE_USAGE_GUIDE.md)

</div>

---

<sub>Developed with ❤️ for the PHP community</sub>