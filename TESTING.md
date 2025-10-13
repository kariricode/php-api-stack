# Testing Guide - PHP API Stack

**Audience**: Project maintainers and contributors  
**Purpose**: Complete testing methodology and quality assurance

## 📋 Table of Contents

- [Overview](#overview)
- [Testing Pyramid](#testing-pyramid)
- [Prerequisites](#prerequisites)
- [Testing Workflow](#testing-workflow)
- [Manual Testing](#manual-testing)
- [Automated Testing](#automated-testing)
- [Integration Testing](#integration-testing)
- [Performance Testing](#performance-testing)
- [Security Testing](#security-testing)
- [CI/CD Pipeline](#cicd-pipeline)
- [Troubleshooting Tests](#troubleshooting-tests)

## 🎯 Overview

The PHP API Stack testing strategy follows a **layered approach** ensuring quality at every level:

```
          ┌──────────────────────┐
          │  Manual Inspection   │  ← Developer verification
          └──────────────────────┘
                    ↓
          ┌──────────────────────┐
          │   Unit Tests         │  ← Component validation
          └──────────────────────┘
                    ↓
          ┌──────────────────────┐
          │ Integration Tests    │  ← Stack interaction
          └──────────────────────┘
                    ↓
          ┌──────────────────────┐
          │ Performance Tests    │  ← Load and stress
          └──────────────────────┘
                    ↓
          ┌──────────────────────┐
          │  Security Scans      │  ← Vulnerabilities
          └──────────────────────┘
```

## 🏗️ Testing Pyramid

### Level 1: Build Validation (Fast - Seconds)
- ✅ Dockerfile syntax
- ✅ Configuration templates
- ✅ Script syntax
- ✅ File structure

### Level 2: Component Tests (Fast - Seconds)
- ✅ PHP version check
- ✅ Nginx configuration
- ✅ Redis connectivity
- ✅ Extension availability

### Level 3: Integration Tests (Medium - Minutes)
- ✅ Service communication
- ✅ Health endpoints
- ✅ Request processing
- ✅ Cache behavior

### Level 4: Performance Tests (Slow - Minutes)
- ✅ Load testing
- ✅ Memory profiling
- ✅ Response times
- ✅ Concurrent connections

### Level 5: Security Scans (Slow - Minutes)
- ✅ Vulnerability scanning
- ✅ Configuration hardening
- ✅ Dependency audit

## 🔧 Prerequisites

### Required Tools

```bash
# Docker and Docker Compose
docker --version  # >= 20.10
docker-compose --version  # >= 2.0

# Testing tools
make --version
curl --version
jq --version  # For JSON parsing

# Optional but recommended
trivy --version  # Security scanner
hadolint --version  # Dockerfile linter
ab --version  # Apache Bench for load testing
```

### Installation

```bash
# macOS
brew install docker docker-compose make curl jq trivy hadolint

# Ubuntu/Debian
apt-get update
apt-get install -y docker.io docker-compose make curl jq
snap install trivy
wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
chmod +x /usr/local/bin/hadolint

# Verify
make --version
trivy --version
hadolint --version
```

## 🔄 Testing Workflow

### Complete Test Cycle

```bash
# 1. Clone and setup
git clone https://github.com/kariricode/php-api-stack.git
cd php-api-stack

# 2. Lint and validate
make lint          # Dockerfile validation
make version       # Check current version

# 3. Build
make build         # Production build
make build-test-image  # Test build with comprehensive health

# 4. Quick tests
make test-quick    # Component version checks (5s)

# 5. Full test suite
make test          # Comprehensive validation (30s)

# 6. Integration tests
make run-test      # Start test container
make test-health   # Validate health endpoint
make test-health-watch  # Live monitoring

# 7. Security scan
make scan          # Trivy vulnerability scan

# 8. Performance test (optional)
# See Performance Testing section

# 9. Cleanup
make stop-test
make clean
```

### Pre-Release Checklist

```bash
# ✅ 1. Code quality
make lint

# ✅ 2. Build succeeds
make build-no-cache

# ✅ 3. All tests pass
make test

# ✅ 4. Health check works
make run-test
make test-health

# ✅ 5. No vulnerabilities
make scan

# ✅ 6. Documentation updated
# Review: README.md, TESTING.md, DOCKER_HUB.md, IMAGE_USAGE_GUIDE.md

# ✅ 7. Version bumped
make bump-patch  # or bump-minor, bump-major

# ✅ 8. Ready for release
make release
```

## 🧪 Manual Testing

### 1. Build Validation

#### Test: Dockerfile Syntax
```bash
# Lint Dockerfile
make lint

# Expected output:
# ✓ No issues found
```

**Failure scenarios:**
- DL3003: Use WORKDIR instead of cd
- DL3008: Pin apt package versions
- DL3015: Avoid apt-get upgrade

#### Test: Configuration Templates
```bash
# Validate templates exist
ls -la nginx/*.conf
ls -la php/*.ini
ls -la redis/*.conf

# Process configs manually
docker run --rm \
  -v $(pwd)/scripts:/scripts \
  kariricode/php-api-stack:latest \
  /scripts/process-configs.sh

# Expected output:
# ✓ Nginx main configuration processed
# ✓ PHP.ini configuration processed
# ✓ All configurations are valid
```

### 2. Component Tests

#### Test: PHP Version and Extensions
```bash
make test-quick

# Expected output:
# Testing PHP:
#   PHP 8.4.x (cli) (built: ...)
# Testing Nginx:
#   nginx version: nginx/1.27.3
# Testing Redis:
#   Redis server v=7.2.x
# Testing Composer:
#   Composer version 2.8.12
# ✓ All components verified!
```

**Manual alternative:**
```bash
# PHP
docker run --rm kariricode/php-api-stack:latest php -v
docker run --rm kariricode/php-api-stack:latest php -m

# Nginx
docker run --rm kariricode/php-api-stack:latest nginx -v
docker run --rm kariricode/php-api-stack:latest nginx -t

# Redis
docker run --rm kariricode/php-api-stack:latest redis-server --version

# Composer
docker run --rm kariricode/php-api-stack:latest composer --version
```

#### Test: Configuration Validity
```bash
# Start container
make run

# Check PHP-FPM
docker exec php-api-stack-local php-fpm -t
# Expected: test is successful

# Check Nginx
docker exec php-api-stack-local nginx -t
# Expected: test is successful

# Check Redis
docker exec php-api-stack-local redis-cli ping
# Expected: PONG

# Cleanup
make stop
```

### 3. Service Communication Tests

#### Test: PHP-FPM Socket
```bash
make run

# Verify socket exists
docker exec php-api-stack-local ls -la /var/run/php/php-fpm.sock
# Expected: srw-rw---- 1 nginx nginx ... /var/run/php/php-fpm.sock

# Test Nginx -> PHP-FPM communication
curl -I http://localhost:8080
# Expected: HTTP/1.1 200 OK

make stop
```

#### Test: PHP -> Redis Communication
```bash
make run

# Test Redis from PHP
docker exec php-api-stack-local php -r "
\$redis = new Redis();
\$redis->connect('127.0.0.1', 6379);
echo \$redis->ping() ? 'Redis OK' : 'Redis FAIL';
"
# Expected: Redis OK

make stop
```

### 4. Health Check Tests

#### Test: Simple Health Check
```bash
make run

# Test endpoint
curl http://localhost:8080/health
# Expected: healthy

# With verbose
curl -v http://localhost:8080/health
# Expected: HTTP/1.1 200 OK

make stop
```

#### Test: Comprehensive Health Check
```bash
# Build test image
make build-test-image

# Run test container
make run-test

# Test full health
make test-health

# Expected JSON with:
# {
#   "status": "healthy",
#   "checks": {
#     "php": { "healthy": true, ... },
#     "opcache": { "healthy": true, ... },
#     "redis": { "healthy": true, ... },
#     ...
#   }
# }

# Test specific components
curl -s http://localhost:8080/health.php | jq '.checks.opcache'
curl -s http://localhost:8080/health.php | jq '.checks.redis'

# Live monitoring
make test-health-watch

make stop-test
```

### 5. Request Processing Tests

#### Test: Static File Serving
```bash
make run

# Create test file
docker exec php-api-stack-local bash -c "echo 'test' > /var/www/html/public/test.txt"

# Request file
curl http://localhost:8080/test.txt
# Expected: test

# Check caching headers
curl -I http://localhost:8080/test.txt | grep -i cache
# Expected: Cache-Control: public, immutable

make stop
```

#### Test: PHP Script Execution
```bash
make run

# Create test script
docker exec php-api-stack-local bash -c "cat > /var/www/html/public/info.php << 'EOF'
<?php
phpinfo();
EOF
"

# Test execution
curl -s http://localhost:8080/info.php | grep "PHP Version"
# Expected: PHP Version => 8.4.x

make stop
```

## 🤖 Automated Testing

### Using Makefile

#### Quick Test Suite
```bash
# Build and test
make build-test

# This runs:
# 1. make build     → Build production image
# 2. make test-quick → Verify component versions
```

#### Comprehensive Test Suite
```bash
make test

# This runs:
# 1. Component version tests
# 2. Configuration validation
# 3. Syntax checks (nginx -t, php-fpm -t)
# 4. Health endpoint test
# Total time: ~30 seconds
```

#### Test Script Example

Create `tests/run-all-tests.sh`:
```bash
#!/bin/bash
set -e

echo "=== PHP API Stack Test Suite ==="

# 1. Lint
echo "→ Linting Dockerfile..."
make lint

# 2. Build
echo "→ Building image..."
make build

# 3. Quick tests
echo "→ Running quick tests..."
make test-quick

# 4. Full tests
echo "→ Running full test suite..."
make test

# 5. Security scan
echo "→ Scanning for vulnerabilities..."
make scan

echo "✓ All tests passed!"
```

Run:
```bash
chmod +x tests/run-all-tests.sh
./tests/run-all-tests.sh
```

### Custom Test Cases

#### Test: Custom Extension Installation
```bash
# Modify .env
echo 'PHP_CORE_EXTENSIONS="pdo pdo_mysql opcache intl zip bcmath gd mbstring xml sockets pcntl"' >> .env

# Rebuild
make build-no-cache

# Verify
docker run --rm kariricode/php-api-stack:latest php -m | grep pcntl
# Expected: pcntl

# Cleanup
git checkout .env
```

#### Test: OPcache Configuration
```bash
make run

# Check OPcache status
docker exec php-api-stack-local php -r "
\$status = opcache_get_status();
echo 'Memory Used: ' . (\$status['memory_usage']['used_memory'] / 1024 / 1024) . ' MB' . PHP_EOL;
echo 'Hit Rate: ' . (\$status['opcache_statistics']['opcache_hit_rate']) . '%' . PHP_EOL;
"

# Expected:
# Memory Used: ~50 MB
# Hit Rate: >90%

make stop
```

## 🔗 Integration Testing

### Test: Full Stack Integration

Create `tests/integration-test.sh`:
```bash
#!/bin/bash
set -e

# Start stack
make run

# Wait for services
sleep 5

# Test 1: Web server
echo "Test 1: Web server..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Web server OK"
else
    echo "✗ Web server failed (HTTP $HTTP_CODE)"
    exit 1
fi

# Test 2: PHP processing
echo "Test 2: PHP processing..."
docker exec php-api-stack-local bash -c "echo '<?php echo \"OK\";' > /var/www/html/public/test.php"
RESPONSE=$(curl -s http://localhost:8080/test.php)
if [ "$RESPONSE" = "OK" ]; then
    echo "✓ PHP processing OK"
else
    echo "✗ PHP processing failed"
    exit 1
fi

# Test 3: Redis connectivity
echo "Test 3: Redis..."
docker exec php-api-stack-local redis-cli ping | grep -q PONG
if [ $? -eq 0 ]; then
    echo "✓ Redis OK"
else
    echo "✗ Redis failed"
    exit 1
fi

# Test 4: PHP-Redis integration
echo "Test 4: PHP-Redis integration..."
docker exec php-api-stack-local php -r "
\$redis = new Redis();
\$connected = \$redis->connect('127.0.0.1', 6379);
exit(\$connected ? 0 : 1);
"
if [ $? -eq 0 ]; then
    echo "✓ PHP-Redis OK"
else
    echo "✗ PHP-Redis failed"
    exit 1
fi

# Cleanup
make stop

echo "✓ All integration tests passed!"
```

Run:
```bash
chmod +x tests/integration-test.sh
./tests/integration-test.sh
```

### Test: Docker Compose Integration

Create `docker-compose.test.yml`:
```yaml
version: '3.8'

services:
  app:
    image: kariricode/php-api-stack:latest
    ports:
      - "8080:80"
    environment:
      - APP_ENV=production
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 5s
      timeout: 3s
      retries: 3
      start_period: 10s

  test:
    image: curlimages/curl:latest
    depends_on:
      app:
        condition: service_healthy
    command: >
      sh -c "
        curl -f http://app/health &&
        curl -f http://app/ | grep 'PHP API Stack' &&
        echo '✓ Integration tests passed'
      "
```

Run:
```bash
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
docker-compose -f docker-compose.test.yml down
```

## ⚡ Performance Testing

### Load Testing with Apache Bench

```bash
# Start container
make run

# Simple load test
ab -n 10000 -c 100 http://localhost:8080/

# Expected results:
# Requests per second: 5000-10000
# Time per request: 10-20ms (mean)
# Failed requests: 0

# With keepalive
ab -n 10000 -c 100 -k http://localhost:8080/

# Test static files
ab -n 20000 -c 200 http://localhost:8080/test.txt

# Cleanup
make stop
```

### Performance Monitoring

```bash
make run

# Monitor resources
docker stats php-api-stack-local

# Expected:
# CPU: 60-80% under load
# Memory: 200-500MB
# Network: Depends on throughput

# OPcache stats during load
docker exec php-api-stack-local php -r "
\$status = opcache_get_status();
echo 'Hit Rate: ' . \$status['opcache_statistics']['opcache_hit_rate'] . '%' . PHP_EOL;
echo 'Memory Usage: ' . (\$status['memory_usage']['used_memory'] / 1024 / 1024) . ' MB' . PHP_EOL;
"

make stop
```

### Memory Profiling

```bash
make run

# Run memory test
docker exec php-api-stack-local php -r "
echo 'Initial: ' . memory_get_usage(true) . PHP_EOL;
\$data = [];
for (\$i = 0; \$i < 10000; \$i++) {
    \$data[] = str_repeat('x', 1024);
}
echo 'After loop: ' . memory_get_usage(true) . PHP_EOL;
unset(\$data);
gc_collect_cycles();
echo 'After GC: ' . memory_get_usage(true) . PHP_EOL;
"

make stop
```

## 🔒 Security Testing

### Vulnerability Scanning with Trivy

```bash
# Scan image
make scan

# Detailed scan
trivy image --severity HIGH,CRITICAL --format table kariricode/php-api-stack:latest

# JSON output
trivy image --severity HIGH,CRITICAL --format json kariricode/php-api-stack:latest > scan-results.json

# Expected: 0 HIGH/CRITICAL vulnerabilities
```

### Configuration Security Audit

```bash
make run

# Check disabled functions
docker exec php-api-stack-local php -r "echo ini_get('disable_functions');"
# Expected: exec,passthru,shell_exec,system,popen,show_source

# Check open_basedir
docker exec php-api-stack-local php -r "echo ini_get('open_basedir');"
# Expected: /var/www/html:/tmp:/usr/local/lib/php:/usr/share/php

# Check expose_php
docker exec php-api-stack-local php -r "echo ini_get('expose_php');"
# Expected: Off

# Check server tokens
curl -I http://localhost:8080 | grep -i server
# Expected: Server: nginx (no version)

make stop
```

### Security Headers Test

```bash
make run

# Check all security headers
curl -I http://localhost:8080

# Expected headers:
# X-Frame-Options: SAMEORIGIN
# X-Content-Type-Options: nosniff
# X-XSS-Protection: 1; mode=block
# Referrer-Policy: strict-origin-when-cross-origin
# Permissions-Policy: geolocation=(), microphone=(), camera=()

make stop
```

## 🚀 CI/CD Pipeline

### GitHub Actions Example

Create `.github/workflows/test.yml`:
```yaml
name: Test PHP API Stack

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Lint Dockerfile
        run: make lint

  build:
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build image
        run: make build
      - name: Quick tests
        run: make test-quick

  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build image
        run: make build
      - name: Run test suite
        run: make test
      - name: Integration tests
        run: |
          make run
          sleep 10
          curl -f http://localhost:8080
          make stop

  security:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build image
        run: make build
      - name: Run Trivy scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'kariricode/php-api-stack:latest'
          format: 'sarif'
          output: 'trivy-results.sarif'
      - name: Upload results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

### GitLab CI Example

Create `.gitlab-ci.yml`:
```yaml
stages:
  - lint
  - build
  - test
  - security

lint:
  stage: lint
  script:
    - make lint

build:
  stage: build
  script:
    - make build
  artifacts:
    paths:
      - VERSION

test:quick:
  stage: test
  script:
    - make build
    - make test-quick

test:full:
  stage: test
  script:
    - make build
    - make test

test:integration:
  stage: test
  script:
    - make run
    - sleep 10
    - curl -f http://localhost:8080
    - make stop

security:scan:
  stage: security
  script:
    - make build
    - make scan
```

## 🐛 Troubleshooting Tests

### Test Failures

#### Build fails
```bash
# Clean and rebuild
make clean-all
make build-no-cache

# Check logs
docker build --progress=plain -t test-build .
```

#### Container won't start in tests
```bash
# Debug mode
docker run -it --rm \
  kariricode/php-api-stack:latest \
  /bin/bash

# Check inside
php-fpm -t
nginx -t
redis-cli ping
```

#### Health check fails
```bash
# Check logs
make run
docker logs php-api-stack-local

# Test components individually
docker exec php-api-stack-local supervisorctl status
docker exec php-api-stack-local curl -f http://localhost/health
```

#### Performance tests fail
```bash
# Check resources
docker stats

# Increase limits
docker run -d \
  --memory="2g" \
  --cpus="2" \
  -p 8080:80 \
  kariricode/php-api-stack:latest
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `php-fpm.sock not found` | PHP-FPM not started | Check supervisorctl status |
| `502 Bad Gateway` | Socket permission issue | Verify nginx:nginx ownership |
| `Redis connection refused` | Redis not started | Check redis-cli ping |
| `OPcache disabled` | Wrong environment | Check PHP_OPCACHE_ENABLE=1 |

## 📊 Test Coverage Report

Run complete test suite and generate report:

```bash
#!/bin/bash
# tests/generate-report.sh

echo "=== PHP API Stack Test Report ==="
echo "Generated: $(date)"
echo ""

# 1. Build
echo "1. Build Tests"
make lint && echo "   ✓ Dockerfile lint" || echo "   ✗ Dockerfile lint"
make build && echo "   ✓ Image build" || echo "   ✗ Image build"
echo ""

# 2. Component tests
echo "2. Component Tests"
make test-quick && echo "   ✓ Version checks" || echo "   ✗ Version checks"
echo ""

# 3. Integration tests
echo "3. Integration Tests"
make test && echo "   ✓ Full test suite" || echo "   ✗ Full test suite"
echo ""

# 4. Security
echo "4. Security Tests"
make scan && echo "   ✓ Vulnerability scan" || echo "   ✗ Vulnerability scan"
echo ""

# 5. Performance
echo "5. Performance Tests"
make run
sleep 5
ab -n 1000 -c 10 http://localhost:8080/ > /dev/null 2>&1 && echo "   ✓ Load test" || echo "   ✗ Load test"
make stop
echo ""

echo "=== Test Report Complete ==="
```

## ✅ Success Criteria

A successful test run should show:

- ✅ All Makefile targets execute without errors
- ✅ Health checks return `200 OK` with `"healthy"` status
- ✅ Security scan shows 0 HIGH/CRITICAL vulnerabilities
- ✅ Performance tests achieve >5000 req/s
- ✅ OPcache hit rate >90%
- ✅ Memory usage stable under load
- ✅ No errors in logs during tests

## 📞 Support

For testing issues:
- **GitHub Issues**: [Report bugs](https://github.com/kariricode/php-api-stack/issues)
- **Discussions**: [Ask questions](https://github.com/kariricode/php-api-stack/discussions)

---

**Next**: [DOCKER_HUB.md](DOCKER_HUB.md) - Learn how to publish the image