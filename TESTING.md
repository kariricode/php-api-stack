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
- [Health Check Testing](#health-check-testing)
- [Open Basedir Compliance Testing](#open-basedir-compliance-testing)
- [CI/CD Pipeline](#cicd-pipeline)
- [Troubleshooting Tests](#troubleshooting-tests)
- [Test Coverage Report](#test-coverage-report)
- [Best Practices](#best-practices)

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

### Testing Philosophy

Our testing approach follows industry standards:

- **[Testing Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html)**: Many fast unit tests, fewer integration tests
- **[Shift-Left Testing](https://en.wikipedia.org/wiki/Shift-left_testing)**: Find issues early in development
- **[Defense in Depth](https://owasp.org/www-community/controls/Defense_in_depth)**: Multiple layers of security validation
- **[Continuous Testing](https://www.ibm.com/topics/continuous-testing)**: Automated testing in CI/CD pipeline

## 🏗️ Testing Pyramid

### Level 1: Build Validation (Fast - Seconds)
- ✅ Dockerfile syntax ([hadolint](https://github.com/hadolint/hadolint))
- ✅ Configuration templates
- ✅ Script syntax
- ✅ File structure

### Level 2: Component Tests (Fast - Seconds)
- ✅ PHP version check
- ✅ Nginx configuration validation
- ✅ Redis connectivity
- ✅ Extension availability
- ✅ OPcache functionality

### Level 3: Integration Tests (Medium - Minutes)
- ✅ Service communication (PHP-FPM ↔ Nginx ↔ Redis)
- ✅ Health endpoints (simple + comprehensive)
- ✅ Request processing
- ✅ Cache behavior
- ✅ Session management

### Level 4: Performance Tests (Slow - Minutes)
- ✅ Load testing ([Apache Bench](https://httpd.apache.org/docs/2.4/programs/ab.html))
- ✅ Memory profiling
- ✅ Response times
- ✅ Concurrent connections
- ✅ OPcache hit rate

### Level 5: Security Scans (Slow - Minutes)
- ✅ Vulnerability scanning ([Trivy](https://aquasecurity.github.io/trivy/))
- ✅ Configuration hardening
- ✅ Dependency audit
- ✅ open_basedir compliance

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

#### macOS
```bash
brew install docker docker-compose make curl jq trivy hadolint
```

#### Ubuntu/Debian
```bash
apt-get update
apt-get install -y docker.io docker-compose make curl jq apache2-utils
snap install trivy
wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
chmod +x /usr/local/bin/hadolint
```

#### Verification
```bash
make --version
docker --version
trivy --version
hadolint --version
ab -V
jq --version
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

**Common Issues:**
- `DL3003`: Use WORKDIR instead of cd
- `DL3008`: Pin apt package versions
- `DL3015`: Avoid apt-get upgrade
- `DL3059`: Multiple consecutive RUN instructions

**Reference**: [Hadolint Rules](https://github.com/hadolint/hadolint#rules)

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

**Reference**: [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)

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

**Why Unix Sockets?**
- **Performance**: ~20% faster than TCP sockets for local communication
- **Security**: No network exposure
- **Reliability**: Fewer connection failures

**Reference**: [FastCGI Process Manager](https://www.php.net/manual/en/install.fpm.php)

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

**Purpose**: Lightweight check for load balancers and Kubernetes liveness probes.

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
#     "php_extensions": { "healthy": true, ... },
#     "opcache": { "healthy": true, ... },
#     "redis": { "healthy": true, ... },
#     "system": { "healthy": true, ... },
#     "application": { "healthy": true, ... }
#   }
# }

# Test specific components
curl -s http://localhost:8080/health.php | jq '.checks.opcache'
curl -s http://localhost:8080/health.php | jq '.checks.redis'

# Live monitoring
make test-health-watch

make stop-test
```

**Purpose**: Detailed diagnostics for monitoring systems and troubleshooting.

**Design Patterns Used**:
- **Strategy Pattern**: Different health check strategies for each component
- **Template Method**: AbstractHealthCheck defines common structure
- **Facade**: HealthCheckManager simplifies client interaction

**Reference**: [Health Check Pattern](https://microservices.io/patterns/observability/health-check-api.html)

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
set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== PHP API Stack Test Suite ==="
echo "Generated: $(date)"
echo ""

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name=$1
    local test_cmd=$2
    
    echo -n "Testing $test_name... "
    if eval "$test_cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC}"
        ((TESTS_FAILED++))
    fi
}

# 1. Lint
echo "1. Build Validation"
run_test "Dockerfile lint" "make lint"
echo ""

# 2. Build
echo "2. Build Tests"
run_test "Production image build" "make build"
echo ""

# 3. Component tests
echo "3. Component Tests"
run_test "PHP version check" "docker run --rm kariricode/php-api-stack:latest php -v"
run_test "Nginx version check" "docker run --rm kariricode/php-api-stack:latest nginx -v"
run_test "Redis version check" "docker run --rm kariricode/php-api-stack:latest redis-server --version"
run_test "Composer version check" "docker run --rm kariricode/php-api-stack:latest composer --version"
echo ""

# 4. Configuration tests
echo "4. Configuration Tests"
run_test "PHP-FPM config" "docker run --rm kariricode/php-api-stack:latest php-fpm -t"
run_test "Nginx config" "docker run --rm kariricode/php-api-stack:latest nginx -t"
echo ""

# 5. Integration tests
echo "5. Integration Tests"
run_test "Full test suite" "make test"
echo ""

# 6. Security
echo "6. Security Tests"
run_test "Vulnerability scan" "make scan"
echo ""

# Results
echo "=== Test Report ==="
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    exit 1
fi
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
echo 'Cached Scripts: ' . \$status['opcache_statistics']['num_cached_scripts'] . PHP_EOL;
"

# Expected:
# Memory Used: ~50 MB
# Hit Rate: >90%
# Cached Scripts: >0

make stop
```

**OPcache Best Practices**:
- Hit rate should be >95% in production
- Validate timestamps disabled in production (opcache.validate_timestamps=0)
- Memory consumption tuned to application size

**Reference**: [OPcache Configuration](https://www.php.net/manual/en/opcache.configuration.php)

## 🔗 Integration Testing

### Test: Full Stack Integration

Create `tests/integration-test.sh`:
```bash
#!/bin/bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== Full Stack Integration Test ==="

# Start stack
echo "Starting stack..."
make run >/dev/null 2>&1

# Wait for services
sleep 5

# Test 1: Web server
echo -n "Test 1: Web server... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAIL (HTTP $HTTP_CODE)${NC}"
    make stop
    exit 1
fi

# Test 2: PHP processing
echo -n "Test 2: PHP processing... "
docker exec php-api-stack-local bash -c "echo '<?php echo \"OK\";' > /var/www/html/public/test.php" >/dev/null 2>&1
RESPONSE=$(curl -s http://localhost:8080/test.php)
if [ "$RESPONSE" = "OK" ]; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    make stop
    exit 1
fi

# Test 3: Redis connectivity
echo -n "Test 3: Redis... "
docker exec php-api-stack-local redis-cli ping >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    make stop
    exit 1
fi

# Test 4: PHP-Redis integration
echo -n "Test 4: PHP-Redis integration... "
docker exec php-api-stack-local php -r "
\$redis = new Redis();
\$connected = \$redis->connect('127.0.0.1', 6379);
exit(\$connected ? 0 : 1);
" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    make stop
    exit 1
fi

# Test 5: Session storage
echo -n "Test 5: Session storage... "
docker exec php-api-stack-local bash -c "cat > /var/www/html/public/session-test.php << 'EOF'
<?php
session_start();
\$_SESSION['test'] = 'works';
echo \$_SESSION['test'];
EOF
" >/dev/null 2>&1
RESPONSE=$(curl -s http://localhost:8080/session-test.php)
if [ "$RESPONSE" = "works" ]; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    make stop
    exit 1
fi

# Cleanup
make stop >/dev/null 2>&1

echo ""
echo -e "${GREEN}✓ All integration tests passed!${NC}"
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
      - PHP_MEMORY_LIMIT=512M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 5s
      timeout: 3s
      retries: 3
      start_period: 10s
    networks:
      - test-network

  test:
    image: curlimages/curl:latest
    depends_on:
      app:
        condition: service_healthy
    command: >
      sh -c "
        echo 'Testing health endpoint...' &&
        curl -f http://app/health &&
        echo 'Testing demo page...' &&
        curl -f http://app/ | grep 'PHP API Stack' &&
        echo '✓ Integration tests passed'
      "
    networks:
      - test-network

networks:
  test-network:
    driver: bridge
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

# With keepalive (simulates realistic traffic)
ab -n 10000 -c 100 -k http://localhost:8080/

# Test static files (should be very fast)
ab -n 20000 -c 200 http://localhost:8080/test.txt

# Test PHP processing
ab -n 5000 -c 50 http://localhost:8080/index.php

# Cleanup
make stop
```

**Performance Targets**:
| Metric | Target | Excellent |
|--------|--------|-----------|
| Requests/sec | >5000 | >10000 |
| Time/request | <20ms | <10ms |
| Failed requests | 0% | 0% |
| Memory usage | <500MB | <300MB |

**Reference**: [Apache Bench Documentation](https://httpd.apache.org/docs/2.4/programs/ab.html)

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
echo 'Cached Scripts: ' . \$status['opcache_statistics']['num_cached_scripts'] . PHP_EOL;
echo 'JIT Enabled: ' . (\$status['jit']['enabled'] ? 'Yes' : 'No') . PHP_EOL;
"

make stop
```

### Memory Profiling

```bash
make run

# Run memory test
docker exec php-api-stack-local php -r "
echo 'Initial: ' . memory_get_usage(true) . ' bytes' . PHP_EOL;
\$data = [];
for (\$i = 0; \$i < 10000; \$i++) {
    \$data[] = str_repeat('x', 1024);
}
echo 'After loop: ' . memory_get_usage(true) . ' bytes' . PHP_EOL;
unset(\$data);
gc_collect_cycles();
echo 'After GC: ' . memory_get_usage(true) . ' bytes' . PHP_EOL;
"

make stop
```

**Expected Behavior**:
- Initial: ~2MB (PHP base memory)
- After loop: ~12MB (10MB allocated)
- After GC: ~2MB (memory freed)

## 🔒 Security Testing

### Vulnerability Scanning with Trivy

```bash
# Scan image
make scan

# Detailed scan
trivy image --severity HIGH,CRITICAL --format table kariricode/php-api-stack:latest

# JSON output for CI/CD
trivy image --severity HIGH,CRITICAL --format json kariricode/php-api-stack:latest > scan-results.json

# Expected: 0 HIGH/CRITICAL vulnerabilities
```

**Security Targets**:
- **Critical**: 0 vulnerabilities
- **High**: 0 vulnerabilities
- **Medium**: <5 vulnerabilities
- **Low**: Acceptable

**Reference**: [Trivy Scanning](https://aquasecurity.github.io/trivy/)

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

# Check allow_url_include
docker exec php-api-stack-local php -r "echo ini_get('allow_url_include');"
# Expected: Off

# Check server tokens
curl -I http://localhost:8080 | grep -i server
# Expected: Server: nginx (no version)

make stop
```

**Security Hardening Applied**:
- ✅ Disabled dangerous PHP functions
- ✅ open_basedir restriction
- ✅ expose_php disabled
- ✅ allow_url_include disabled
- ✅ Server tokens hidden

**Reference**: [PHP Security](https://www.php.net/manual/en/security.php)

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

**OWASP Secure Headers**:
- ✅ X-Frame-Options: Prevents clickjacking
- ✅ X-Content-Type-Options: Prevents MIME sniffing
- ✅ X-XSS-Protection: XSS filter
- ✅ Referrer-Policy: Controls referrer information
- ✅ Permissions-Policy: Feature policy

**Reference**: [OWASP Secure Headers](https://owasp.org/www-project-secure-headers/)

## 🏥 Health Check Testing

### Comprehensive Health Check Validation

```bash
# Build test image with comprehensive health check
make build-test-image

# Run test container
make run-test

# Test all health check components
echo "Testing PHP Runtime..."
curl -s http://localhost:8080/health.php | jq '.checks.php'

echo "Testing PHP Extensions..."
curl -s http://localhost:8080/health.php | jq '.checks.php_extensions'

echo "Testing OPcache..."
curl -s http://localhost:8080/health.php | jq '.checks.opcache'

echo "Testing Redis..."
curl -s http://localhost:8080/health.php | jq '.checks.redis'

echo "Testing System Resources..."
curl -s http://localhost:8080/health.php | jq '.checks.system'

echo "Testing Application..."
curl -s http://localhost:8080/health.php | jq '.checks.application'

# Verify overall health
curl -s http://localhost:8080/health.php | jq '.status'
# Expected: "healthy"

# Stop test container
make stop-test
```

### Health Check Response Time Test

```bash
make run-test

# Measure response time
time curl -s http://localhost:8080/health.php > /dev/null

# Expected: <100ms

# Measure with curl timing
curl -w "@-" -o /dev/null -s http://localhost:8080/health.php <<'EOF'
    time_namelookup:  %{time_namelookup}\n
       time_connect:  %{time_connect}\n
    time_appconnect:  %{time_appconnect}\n
   time_pretransfer:  %{time_pretransfer}\n
      time_redirect:  %{time_redirect}\n
 time_starttransfer:  %{time_starttransfer}\n
                    ----------\n
         time_total:  %{time_total}\n
EOF

make stop-test
```

### Health Check Under Load

```bash
make run-test

# Load test health endpoint
ab -n 1000 -c 10 http://localhost:8080/health.php

# Expected:
# - All requests successful
# - Response time consistent
# - No errors in logs

make stop-test
```

## 🛡️ Open Basedir Compliance Testing

### Understanding open_basedir

The `open_basedir` directive restricts file access to specified directories, enhancing security.

**Current Configuration**:
```ini
open_basedir = /var/www/html:/tmp:/usr/local/lib/php:/usr/share/php
```

**Reference**: [PHP open_basedir](https://www.php.net/manual/en/ini.core.php#ini.open-basedir)

### Test: Verify Restricted Access

```bash
make run-test

# Test 1: Allowed path (should succeed)
docker exec php-api-stack-test php -r "
\$allowed = '/var/www/html/public/test.txt';
file_put_contents(\$allowed, 'test');
echo is_readable(\$allowed) ? 'OK' : 'FAIL';
"
# Expected: OK

# Test 2: Restricted path (should fail gracefully)
docker exec php-api-stack-test php -r "
set_error_handler(function() { return true; });
\$restricted = '/var/log/nginx/access.log';
\$result = @is_readable(\$restricted);
echo \$result ? 'FAIL' : 'OK';
"
# Expected: OK (access blocked)

make stop-test
```

### Test: Health Check Respects open_basedir

```bash
make run-test

# Verify health check handles restricted paths gracefully
curl -s http://localhost:8080/health.php | jq '.checks.application'

# Expected output:
# {
#   "healthy": true,
#   "status": "healthy",
#   "details": {
#     "directories": {
#       "html": {
#         "path": "/var/www/html",
#         "exists": true,
#         "readable": true,
#         "writable": true
#       },
#       "public": {
#         "path": "/var/www/html/public",
#         "exists": true,
#         "readable": true,
#         "writable": true
#       },
#       "tmp": {
#         "path": "/tmp",
#         "exists": true,
#         "readable": true,
#         "writable": true
#       }
#     },
#     "security_note": "Log directories (/var/log) excluded per open_basedir policy",
#     "open_basedir": "/var/www/html:/tmp:/usr/local/lib/php:/usr/share/php"
#   }
# }

make stop-test
```

### Test: Memory Info Fallback

```bash
make run-test

# Verify system check uses PHP fallback when /proc/meminfo is restricted
curl -s http://localhost:8080/health.php | jq '.checks.system.details.memory'

# Expected: Falls back to PHP memory usage if /proc/meminfo restricted
# {
#   "source": "php_fallback" | "proc_meminfo",
#   ...
# }

make stop-test
```

**Why This Matters**:
- ✅ **Security**: Prevents path traversal attacks
- ✅ **Compliance**: Follows principle of least privilege
- ✅ **Stability**: No runtime errors from restricted access
- ✅ **Transparency**: Clear reporting of security restrictions

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
  workflow_dispatch:

jobs:
  lint:
    name: Lint Dockerfile
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run hadolint
        run: make lint

  build:
    name: Build Image
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build production image
        run: make build
      
      - name: Quick component tests
        run: make test-quick
      
      - name: Save image
        run: docker save kariricode/php-api-stack:latest | gzip > image.tar.gz
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: docker-image
          path: image.tar.gz

  test:
    name: Run Tests
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Download image
        uses: actions/download-artifact@v3
        with:
          name: docker-image
      
      - name: Load image
        run: docker load < image.tar.gz
      
      - name: Run comprehensive tests
        run: make test
      
      - name: Run integration tests
        run: |
          make run
          sleep 10
          curl -f http://localhost:8080
          curl -f http://localhost:8080/health
          make stop

  test-health:
    name: Test Health Checks
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Download image
        uses: actions/download-artifact@v3
        with:
          name: docker-image
      
      - name: Load image
        run: docker load < image.tar.gz
      
      - name: Build test image
        run: make build-test-image
      
      - name: Run test container
        run: make run-test
      
      - name: Test comprehensive health check
        run: |
          sleep 10
          make test-health
          curl -s http://localhost:8080/health.php | jq '.status' | grep -q "healthy"
      
      - name: Stop test container
        run: make stop-test

  security:
    name: Security Scan
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Download image
        uses: actions/download-artifact@v3
        with:
          name: docker-image
      
      - name: Load image
        run: docker load < image.tar.gz
      
      - name: Run Trivy scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'kariricode/php-api-stack:latest'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'
      
      - name: Upload Trivy results
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

variables:
  DOCKER_DRIVER: overlay2
  IMAGE_NAME: kariricode/php-api-stack

lint:dockerfile:
  stage: lint
  image: hadolint/hadolint:latest
  script:
    - hadolint Dockerfile
  only:
    - merge_requests
    - main
    - develop

build:production:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - make build
    - docker save $IMAGE_NAME:latest | gzip > image.tar.gz
  artifacts:
    paths:
      - image.tar.gz
      - VERSION
    expire_in: 1 hour

test:quick:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  dependencies:
    - build:production
  script:
    - docker load < image.tar.gz
    - make test-quick

test:full:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  dependencies:
    - build:production
  script:
    - docker load < image.tar.gz
    - make test

test:integration:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  dependencies:
    - build:production
  script:
    - docker load < image.tar.gz
    - make run
    - sleep 10
    - curl -f http://localhost:8080
    - curl -f http://localhost:8080/health
    - make stop

test:health:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  dependencies:
    - build:production
  script:
    - docker load < image.tar.gz
    - make build-test-image
    - make run-test
    - sleep 10
    - make test-health
    - make stop-test

security:trivy:
  stage: security
  image: aquasec/trivy:latest
  dependencies:
    - build:production
  script:
    - docker load < image.tar.gz
    - trivy image --severity HIGH,CRITICAL --exit-code 1 $IMAGE_NAME:latest
  allow_failure: false
```

## 🐛 Troubleshooting Tests

### Test Failures

#### Build fails
```bash
# Clean and rebuild
make clean-all
make build-no-cache

# Check logs with detailed output
docker build --progress=plain -t test-build .

# Check for common issues:
# - Network connectivity
# - Disk space: df -h
# - Docker daemon: docker info
```

#### Container won't start in tests
```bash
# Debug mode
docker run -it --rm \
  kariricode/php-api-stack:latest \
  /bin/bash

# Check inside container
php-fpm -t
nginx -t
redis-cli ping
supervisorctl status

# Check logs
docker logs <container-id>
```

#### Health check fails
```bash
# Check logs
make run-test
docker logs php-api-stack-test

# Test components individually
docker exec php-api-stack-test supervisorctl status
docker exec php-api-stack-test php-fpm -t
docker exec php-api-stack-test nginx -t
docker exec php-api-stack-test redis-cli ping

# Test health endpoint
docker exec php-api-stack-test curl -v http://localhost/health.php

# Check PHP errors
docker exec php-api-stack-test tail -50 /var/log/php/error.log
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

# Check OPcache configuration
docker exec <container> php -i | grep opcache
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `php-fpm.sock not found` | PHP-FPM not started | Check `supervisorctl status php-fpm` |
| `502 Bad Gateway` | Socket permission issue | Verify `nginx:nginx` ownership |
| `Redis connection refused` | Redis not started | Check `redis-cli ping` |
| `OPcache disabled` | Wrong environment | Check `PHP_OPCACHE_ENABLE=1` |
| `Permission denied` | open_basedir restriction | Use allowed paths only |
| `Health check unhealthy` | Component failure | Check individual components |

## 📊 Test Coverage Report

### Generate Test Report

Create `tests/generate-report.sh`:

```bash
#!/bin/bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=== PHP API Stack Test Report ==="
echo "Generated: $(date)"
echo "Version: $(cat VERSION)"
echo ""

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test_category() {
    local category=$1
    local test_cmd=$2
    
    echo -e "${BLUE}[$category]${NC}"
    if eval "$test_cmd" >/dev/null 2>&1; then
        echo -e "   ${GREEN}✓${NC} $category passed"
        ((PASSED_TESTS++))
    else
        echo -e "   ${RED}✗${NC} $category failed"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
}

# 1. Build Tests
echo "1. Build Validation"
run_test_category "Dockerfile lint" "make lint"
run_test_category "Production build" "make build"
echo ""

# 2. Component Tests
echo "2. Component Tests"
run_test_category "PHP version" "docker run --rm kariricode/php-api-stack:latest php -v"
run_test_category "Nginx config" "docker run --rm kariricode/php-api-stack:latest nginx -t"
run_test_category "Redis version" "docker run --rm kariricode/php-api-stack:latest redis-server --version"
run_test_category "Composer version" "docker run --rm kariricode/php-api-stack:latest composer --version"
echo ""

# 3. Integration Tests
echo "3. Integration Tests"
run_test_category "Full test suite" "make test"
echo ""

# 4. Health Check Tests
echo "4. Health Check Tests"
run_test_category "Test image build" "make build-test-image"
make run-test >/dev/null 2>&1
sleep 5
run_test_category "Health endpoint" "curl -sf http://localhost:8080/health.php"
run_test_category "Overall health" "curl -s http://localhost:8080/health.php | jq -e '.status == \"healthy\"'"
make stop-test >/dev/null 2>&1
echo ""

# 5. Security Tests
echo "5. Security Tests"
run_test_category "Vulnerability scan" "make scan"
echo ""

# 6. Performance Tests
echo "6. Performance Tests"
make run >/dev/null 2>&1
sleep 5
run_test_category "Load test" "ab -n 1000 -c 10 http://localhost:8080/ >/dev/null 2>&1"
make stop >/dev/null 2>&1
echo ""

# Summary
echo "=== Test Summary ==="
echo -e "Total tests:  ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"
echo ""

PERCENTAGE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
echo -e "Success rate: ${GREEN}$PERCENTAGE%${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    exit 1
fi
```

Run:
```bash
chmod +x tests/generate-report.sh
./tests/generate-report.sh
```

## ✅ Success Criteria

A successful test run should show:

### Functional Requirements
- ✅ All Makefile targets execute without errors
- ✅ Health checks return `200 OK` with `"healthy"` status
- ✅ All services (PHP-FPM, Nginx, Redis) start correctly
- ✅ PHP scripts execute successfully
- ✅ Static files served with proper caching headers

### Performance Requirements
- ✅ Requests per second: >5000 (excellent: >10000)
- ✅ Response time P50: <20ms (excellent: <10ms)
- ✅ Response time P99: <100ms (excellent: <50ms)
- ✅ OPcache hit rate: >90% (excellent: >95%)
- ✅ Memory usage: <500MB under load

### Security Requirements
- ✅ Vulnerability scan: 0 HIGH/CRITICAL
- ✅ Security headers: All present and correct
- ✅ open_basedir: Properly restricted
- ✅ Dangerous functions: Disabled
- ✅ Server tokens: Hidden

### Quality Requirements
- ✅ No errors in logs during tests
- ✅ Graceful handling of restricted paths
- ✅ Clear error messages
- ✅ Proper cleanup after tests

## 🎯 Best Practices

### 1. Test Early and Often
```bash
# Run quick tests after every change
make test-quick

# Run full tests before committing
make test
```

### 2. Use Test Containers
```bash
# Always use test containers for comprehensive testing
make build-test-image
make run-test

# Don't forget to clean up
make stop-test
```

### 3. Monitor Performance
```bash
# Regular performance testing
make run
ab -n 10000 -c 100 http://localhost:8080/
docker stats php-api-stack-local
make stop
```

### 4. Security First
```bash
# Always scan before release
make scan

# Test security headers
curl -I http://localhost:8080
```

### 5. Document Failures
When tests fail:
1. Capture logs: `docker logs <container> > test-failure.log`
2. Note environment: OS, Docker version, resources
3. Create reproducible test case
4. File issue with all information

### 6. Automate Everything
- Use CI/CD pipelines
- Automate security scans
- Generate test reports
- Track metrics over time

## 📚 References

### Official Documentation
- [PHP Manual](https://www.php.net/manual/en/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Docker Documentation](https://docs.docker.com/)

### Testing Tools
- [Apache Bench](https://httpd.apache.org/docs/2.4/programs/ab.html)
- [Trivy Security Scanner](https://aquasecurity.github.io/trivy/)
- [Hadolint](https://github.com/hadolint/hadolint)

### Best Practices
- [Testing Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [PHP Security Best Practices](https://www.php.net/manual/en/security.php)
- [Docker Security](https://docs.docker.com/engine/security/)

## 📞 Support

For testing issues:
- **GitHub Issues**: [Report bugs](https://github.com/kariricode/php-api-stack/issues)
- **Discussions**: [Ask questions](https://github.com/kariricode/php-api-stack/discussions)
- **Documentation**: [Full documentation](README.md)

---

**Next Steps**:
- [DOCKER_HUB.md](DOCKER_HUB.md) - Learn how to publish the image
- [IMAGE_USAGE_GUIDE.md](IMAGE_USAGE_GUIDE.md) - Learn how to use the published image
- [README.md](README.md) - Project overview

---