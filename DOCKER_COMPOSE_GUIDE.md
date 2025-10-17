# 🐳 Docker Compose Guide - PHP API Stack

Complete guide for using Docker Compose to orchestrate the PHP API Stack with databases, load balancers, and monitoring.

---

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Architecture Overview](#-architecture-overview)
- [Available Profiles](#-available-profiles)
- [Configuration](#-configuration)
- [Service Details](#-service-details)
- [Makefile Commands](#-makefile-commands)
- [Common Scenarios](#-common-scenarios)
- [Monitoring & Observability](#-monitoring--observability)
- [Troubleshooting](#-troubleshooting)
- [Best Practices](#-best-practices)
- [References](#-references)

---

## 🚀 Quick Start

### Initial Setup

```bash
# 1. Clone repository (if not already)
git clone https://github.com/kariricode/php-api-stack.git
cd php-api-stack

# 2. Copy configuration files
cp .env.example .env
cp docker-compose.example.yml docker-compose.yml

# 3. Review and adjust .env file
nano .env  # or vim, code, etc.

# 4. Start base services
make compose-up

# 5. Verify services are running
make compose-ps

# 6. Access application
open http://localhost:8089
```

### Quick Commands Reference

```bash
# Start services
make compose-up                    # Base services only
make compose-up PROFILES="db"      # With database
make compose-up-all                # All profiles

# View status
make compose-ps                    # Container status
make compose-logs                  # Tail logs
make compose-stats                 # Resource usage

# Stop services
make compose-down-v                # Stop and remove volumes
make compose-down-all              # Stop everything

# Access services
make compose-shell                 # Shell in php-api-stack
make compose-shell SERVICE=mysql   # Shell in MySQL
```

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer (Optional)                  │
│                   nginx-lb:80, nginx-lb:443                  │
└───────────────────────────┬─────────────────────────────────┘
                            │
              ┌─────────────┴──────────────┐
              │                            │
    ┌─────────▼──────────┐    ┌───────────▼─────────┐
    │  php-api-stack (1) │    │  php-api-stack (2)  │
    │   Nginx + PHP-FPM  │    │   Nginx + PHP-FPM   │
    │   + Redis (local)  │    │   + Redis (local)   │
    └─────────┬──────────┘    └───────────┬─────────┘
              │                            │
              └────────────┬───────────────┘
                           │
              ┌────────────┴────────────┐
              │                         │
    ┌─────────▼──────┐      ┌──────────▼──────┐
    │  MySQL (db)    │      │  Redis (cache)  │
    │  Port: 3307    │      │  Port: 6380     │
    └────────────────┘      └─────────────────┘
              │
    ┌─────────▼─────────────────────────────┐
    │     Monitoring Stack (monitoring)      │
    │  ┌──────────┐  ┌──────────┐          │
    │  │Prometheus│  │ Grafana  │          │
    │  │  :9091   │  │  :3000   │          │
    │  └──────────┘  └──────────┘          │
    │       ┌──────────┐                    │
    │       │ cAdvisor │                    │
    │       │  :8080   │                    │
    │       └──────────┘                    │
    └────────────────────────────────────────┘
```

**Networks:**
- `api-network`: Main application network
- `db-network`: Database isolation
- `monitoring-network`: Monitoring stack

---

## 🎭 Available Profiles

Docker Compose profiles allow you to enable optional service groups on demand.

### Base Profile (Always Active)

**Service:** `php-api-stack`

```bash
make compose-up  # Starts only base services
```

**Includes:**
- Nginx web server
- PHP-FPM 8.4
- Redis (embedded in container)
- Demo landing page
- Health check endpoints

**Access:**
- Application: http://localhost:8089
- Health: http://localhost:8089/health.php

---

### Database Profile (`db`)

**Service:** `mysql`

```bash
make compose-up PROFILES="db"
```

**Features:**
- MySQL 8.0 optimized for API workloads
- Persistent volume for data
- Health checks with automatic recovery
- Custom configuration via `example/config/mysql/my.cnf`

**Configuration:**
```bash
# .env
DB_ROOT_PASSWORD=HmlRoot_9dY7q!Sg
DB_DATABASE=php_api_hml
DB_USERNAME=phpapi_hml
DB_PASSWORD=HmlUser_3kT8zQf
DB_PORT=3307  # Host port (container uses 3306)
```

**Connect from host:**
```bash
mysql -h 127.0.0.1 -P 3307 -u phpapi_hml -pHmlUser_3kT8zQf php_api_hml
```

**Connect from container:**
```bash
make compose-shell
mysql -h mysql -u phpapi_hml -pHmlUser_3kT8zQf php_api_hml
```

---

### Load Balancer Profile (`loadbalancer`)

**Service:** `nginx-lb`

```bash
make compose-up PROFILES="loadbalancer"
```

**Features:**
- Nginx reverse proxy/load balancer
- SSL/TLS termination support
- Round-robin load balancing
- Health check integration
- Rate limiting and security headers

**Configuration:**
- Config: `example/config/nginx-lb/nginx.conf`
- SSL certificates: `example/config/nginx-lb/ssl/` (optional)

**Access:**
- HTTP: http://localhost:80
- HTTPS: https://localhost:443 (if SSL configured)

**Scale backend:**
```bash
# Scale to 3 instances
docker compose -f docker-compose.yml up -d --scale php-api-stack=3

# Load balancer automatically distributes traffic
```

---

### Monitoring Profile (`monitoring`)

**Services:** `prometheus`, `grafana`, `cadvisor`

```bash
make compose-up PROFILES="monitoring"
# or
make compose-up-all  # Includes loadbalancer + monitoring
```

**Features:**
- **Prometheus** - Metrics collection and alerting
- **Grafana** - Visualization dashboards
- **cAdvisor** - Container resource metrics

**Access:**
- Grafana: http://localhost:3000 (admin / HmlGrafana_7uV4mRp)
- Prometheus: http://localhost:9091
- cAdvisor: http://localhost:8080

**Pre-configured Dashboards:**
1. **PHP API Stack Dashboard** (`php-api-stack.json`)
   - Request rates and response times
   - PHP-FPM pool status
   - OPcache hit rates
   - Redis performance
   - Container resources

**Configuration:**
```bash
# .env
PROMETHEUS_PORT=9091
GRAFANA_PORT=3000
GRAFANA_PASSWORD=HmlGrafana_7uV4mRp
```

---

## ⚙️ Configuration

### Environment Variables

The `.env` file controls all service configurations. Key sections:

#### Application Settings

```bash
# Application
APP_NAME="PHP API Stack"
APP_ENV=production
APP_DEBUG=false
APP_URL=http://localhost:8089
APP_PORT=8089
```

#### PHP Settings

```bash
# PHP Performance
PHP_VERSION=8.4
PHP_MEMORY_LIMIT=256M
PHP_MAX_EXECUTION_TIME=30
PHP_UPLOAD_MAX_FILESIZE=20M
PHP_POST_MAX_SIZE=25M

# OPcache
PHP_OPCACHE_ENABLE=1
PHP_OPCACHE_MEMORY=256
PHP_OPCACHE_STRINGS=32
PHP_OPCACHE_JIT=tracing
PHP_OPCACHE_JIT_BUFFER=128M

# PHP-FPM
PHP_FPM_PM=dynamic
PHP_FPM_PM_MAX_CHILDREN=60
PHP_FPM_PM_START_SERVERS=10
PHP_FPM_PM_MIN_SPARE_SERVERS=5
PHP_FPM_PM_MAX_SPARE_SERVERS=20
```

#### Database Settings

```bash
# MySQL
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306  # Internal port
DB_DATABASE=php_api_hml
DB_USERNAME=phpapi_hml
DB_PASSWORD=HmlUser_3kT8zQf
DB_ROOT_PASSWORD=HmlRoot_9dY7q!Sg
```

#### Redis Settings

```bash
# Redis
REDIS_HOST=redis  # or redis-external for external service
REDIS_PORT=6379   # Internal port
REDIS_PASSWORD=HmlRedis_3Qy7nFTZgW6M2bK9pX4c
REDIS_DATABASES=16
REDIS_MAXMEMORY=256mb
REDIS_MAXMEMORY_POLICY=allkeys-lru
```

#### Security Settings

```bash
# Security Headers
SECURITY_HEADERS=true
SECURITY_CSP="default-src 'self'"
SECURITY_HSTS_MAX_AGE=31536000

# Rate Limiting
RATE_LIMIT_ZONE_SIZE=10m
RATE_LIMIT_RATE=10r/s
RATE_LIMIT_BURST=20
```

---

## 🔧 Service Details

### PHP API Stack Container

**Image:** `kariricode/php-api-stack:latest`

**Ports:**
- `8089:80` - HTTP traffic

**Volumes:**
```yaml
# Application code (optional - for development)
- ./app:/var/www/html

# Logs
- ./logs:/var/log

# Custom configs (optional)
- ./example/config/nginx/custom.conf:/etc/nginx/conf.d/custom.conf:ro
- ./example/config/php/custom.ini:/usr/local/etc/php/conf.d/custom.ini:ro
```

**Environment:**
```yaml
# See .env file for all options
APP_ENV: production
APP_DEBUG: false
PHP_MEMORY_LIMIT: 256M
REDIS_HOST: redis-external  # or use embedded Redis
```

**Health Check:**
```yaml
test: ["CMD", "curl", "-f", "http://localhost/health"]
interval: 30s
timeout: 10s
retries: 3
start_period: 40s
```

---

### MySQL Service

**Image:** `mysql:8.0`

**Ports:**
- `3307:3306` - MySQL protocol

**Volumes:**
```yaml
# Persistent data
- mysql_data:/var/lib/mysql

# Custom configuration
- ./example/config/mysql/my.cnf:/etc/mysql/conf.d/custom.cnf:ro
```

**Custom Configuration (`my.cnf`):**
```ini
[mysqld]
max_connections = 200
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
query_cache_size = 0
query_cache_type = 0
```

**Resource Limits:**
```yaml
deploy:
  resources:
    limits:
      cpus: "1"
      memory: 1G
```

---

### Redis External Service (Optional)

**Image:** `redis:7.2-alpine`

**Ports:**
- `6380:6379` - Redis protocol

**Volumes:**
```yaml
# Persistent data
- redis_data:/data

# Custom configuration
- ./example/config/redis/redis.conf:/usr/local/etc/redis/redis.conf:ro
```

**Configuration:**
```bash
# Use external Redis instead of embedded
REDIS_HOST=redis-external
REDIS_PORT=6379
REDIS_PASSWORD=HmlRedis_3Qy7nFTZgW6M2bK9pX4c
```

**Profile:** `redis-external`

```bash
make compose-up PROFILES="redis-external"
```

---

### Nginx Load Balancer

**Image:** `nginx:alpine`

**Ports:**
- `80:80` - HTTP
- `443:443` - HTTPS (optional)

**Volumes:**
```yaml
# Configuration
- ./example/config/nginx-lb/nginx.conf:/etc/nginx/nginx.conf:ro

# SSL certificates (optional)
- ./example/config/nginx-lb/ssl:/etc/nginx/ssl:ro

# Logs
- ./logs/nginx-lb:/var/log/nginx
```

**Backend Pool:**
```nginx
upstream php_api_backend {
    least_conn;  # or round_robin, ip_hash
    
    server php-api-stack:80 max_fails=3 fail_timeout=30s;
    
    # For scaled instances
    # server php-api-stack-1:80;
    # server php-api-stack-2:80;
    
    keepalive 32;
}
```

---

### Prometheus

**Image:** `prom/prometheus:latest`

**Ports:**
- `9091:9090` - Web UI and API

**Volumes:**
```yaml
# Configuration
- ./example/config/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro

# Persistent data
- prometheus_data:/prometheus
```

**Scrape Targets:**
```yaml
scrape_configs:
  - job_name: 'php-api-stack'
    static_configs:
      - targets: ['php-api-stack:9000']  # PHP-FPM metrics
  
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
  
  - job_name: 'redis'
    static_configs:
      - targets: ['redis-external:6379']
```

---

### Grafana

**Image:** `grafana/grafana:latest`

**Ports:**
- `3000:3000` - Web UI

**Volumes:**
```yaml
# Persistent data
- grafana_data:/var/lib/grafana

# Provisioning (datasources, dashboards)
- ./example/config/grafana/provisioning:/etc/grafana/provisioning:ro
- ./example/config/grafana/dashboards:/var/lib/grafana/dashboards:ro
```

**Default Credentials:**
- Username: `admin`
- Password: `HmlGrafana_7uV4mRp` (from .env)

**Pre-configured:**
- Prometheus datasource
- PHP API Stack dashboard
- Container metrics dashboard

---

### cAdvisor

**Image:** `gcr.io/cadvisor/cadvisor:latest`

**Ports:**
- `8080:8080` - Web UI

**Volumes:**
```yaml
# Docker socket (read-only)
- /var/run/docker.sock:/var/run/docker.sock:ro

# Container filesystem
- /:/rootfs:ro
- /var/run:/var/run:ro
- /sys:/sys:ro
- /var/lib/docker:/var/lib/docker:ro
```

**Metrics:**
- CPU usage
- Memory usage
- Network I/O
- Filesystem I/O
- Per-container statistics

---

## 🎯 Makefile Commands

### Lifecycle Management

```bash
# Start services
make compose-up                          # Base services
make compose-up PROFILES="db"            # With database
make compose-up PROFILES="db,monitoring" # Multiple profiles
make compose-up-all                      # All profiles

# Stop services
make compose-down                        # Stop (keep volumes)
make compose-down-v                      # Stop + remove volumes
make compose-down-all                    # Stop all profiles + volumes

# Restart services
make compose-restart                     # Restart active services
make compose-restart-svc SERVICES="mysql" # Restart specific service
```

### Service Control

```bash
# Start specific services
make compose-up-svc SERVICES="php-api-stack mysql"

# Stop specific services
make compose-stop-svc SERVICES="grafana"

# Restart specific services
make compose-restart-svc SERVICES="prometheus"
```

### Logs & Monitoring

```bash
# View logs
make compose-logs                        # Tail all active services
make compose-logs-all                    # Tail all profiles
make compose-logs-once                   # Show latest logs (no follow)
make compose-logs-svc SERVICES="mysql"   # Tail specific service

# Customize log output
make compose-logs TAIL=500               # Last 500 lines
make compose-logs SINCE="2h"             # Last 2 hours
```

### Shell Access

```bash
# Access container shell
make compose-shell                       # Default: php-api-stack
make compose-shell SERVICE=mysql         # MySQL shell
make compose-shell SERVICE=grafana       # Grafana shell

# Execute commands
make compose-exec CMD="php -v"           # Run PHP version
make compose-exec SERVICE=mysql CMD="mysql -u root -p" # MySQL CLI
```

### Status & Information

```bash
# Container status
make compose-ps                          # Show running containers

# Resource usage
make compose-stats                       # Real-time resource usage
```

### Configuration & Help

```bash
# Show help
make compose-help                        # Detailed help

# Validate configuration
docker compose -f docker-compose.yml config
```

---

## 💡 Common Scenarios

### Scenario 1: Development Environment

**Goal:** Run application with database and live code reloading

```bash
# 1. Setup
cp .env.example .env
cp docker-compose.example.yml docker-compose.yml

# 2. Edit .env
APP_ENV=development
APP_DEBUG=true
PHP_DISPLAY_ERRORS=On

# 3. Uncomment application mount in docker-compose.yml
# volumes:
#   - ./app:/var/www/html

# 4. Start services
make compose-up PROFILES="db"

# 5. Verify
make compose-ps
curl http://localhost:8089/health.php

# 6. Watch logs
make compose-logs
```

### Scenario 2: Production-like Staging

**Goal:** Test production configuration with monitoring

```bash
# 1. Setup with production settings
APP_ENV=production
APP_DEBUG=false

# 2. Start all services
make compose-up-all

# 3. Load test
ab -n 10000 -c 100 http://localhost:8089/

# 4. Monitor in Grafana
open http://localhost:3000

# 5. Check Prometheus metrics
open http://localhost:9091
```

### Scenario 3: Load Balanced Setup

**Goal:** Test horizontal scaling with load balancer

```bash
# 1. Start with load balancer
make compose-up PROFILES="loadbalancer,db,monitoring"

# 2. Scale backend
docker compose -f docker-compose.yml up -d --scale php-api-stack=3

# 3. Verify load balancing
for i in {1..10}; do
  curl -s http://localhost/health | jq .hostname
done

# 4. Monitor distribution in Grafana
open http://localhost:3000
```

### Scenario 4: Database Migration

**Goal:** Run database migrations safely

```bash
# 1. Start database only
make compose-up PROFILES="db"

# 2. Wait for MySQL to be ready
make compose-logs-svc SERVICES="mysql"
# Wait for "ready for connections"

# 3. Run migrations from php-api-stack
make compose-shell
php bin/console doctrine:migrations:migrate --no-interaction

# or from host (if you have PHP)
DATABASE_URL="mysql://phpapi_hml:HmlUser_3kT8zQf@127.0.0.1:3307/php_api_hml"
php bin/console doctrine:migrations:migrate
```

### Scenario 5: Monitoring Setup

**Goal:** Configure comprehensive monitoring

```bash
# 1. Start monitoring stack
make compose-up PROFILES="monitoring"

# 2. Import Grafana dashboard
# - Open http://localhost:3000
# - Login: admin / HmlGrafana_7uV4mRp
# - Go to Dashboards > Import
# - Upload: example/config/grafana/dashboards/php-api-stack.json

# 3. Configure alerts in Prometheus
# Edit: example/config/prometheus/alerts.yml

# 4. Test alerting
# Simulate high load
ab -n 100000 -c 200 http://localhost:8089/

# 5. Check alerts in Prometheus
open http://localhost:9091/alerts
```

---

## 📊 Monitoring & Observability

### Key Metrics to Monitor

#### Application Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `nginx_requests_total` | Total HTTP requests | - |
| `nginx_request_duration_seconds` | Request latency | P99 > 1s |
| `phpfpm_active_processes` | Active PHP workers | > 80% of max |
| `phpfpm_slow_requests` | Slow PHP requests | > 10/min |

#### System Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `container_cpu_usage_seconds_total` | CPU usage | > 80% |
| `container_memory_usage_bytes` | Memory usage | > 90% limit |
| `container_network_receive_bytes_total` | Network ingress | - |
| `container_fs_usage_bytes` | Disk usage | > 85% |

#### Redis Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `redis_connected_clients` | Active connections | > 90% of maxclients |
| `redis_keyspace_hits_total` | Cache hits | Hit ratio < 80% |
| `redis_memory_used_bytes` | Memory usage | > 90% of maxmemory |
| `redis_evicted_keys_total` | Evicted keys | Increasing trend |

#### MySQL Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `mysql_global_status_threads_connected` | Active connections | > 80% max |
| `mysql_global_status_slow_queries` | Slow queries | > 10/min |
| `mysql_global_status_innodb_buffer_pool_pages_free` | Free buffer pages | < 10% |

### Grafana Dashboards

**PHP API Stack Dashboard** (`php-api-stack.json`)

Panels:
1. **Overview**
   - Request rate (req/s)
   - Error rate (%)
   - Response time (P50, P95, P99)
   - Active connections

2. **PHP-FPM**
   - Active/Idle processes
   - Slow requests
   - Memory per process
   - Queue length

3. **OPcache**
   - Hit rate (%)
   - Memory usage
   - Cached scripts
   - JIT buffer usage

4. **Redis**
   - Operations per second
   - Hit rate
   - Memory usage
   - Connected clients

5. **System Resources**
   - CPU usage (%)
   - Memory usage (MB)
   - Network I/O (MB/s)
   - Disk I/O (MB/s)

### Custom Alerts

Create `example/config/prometheus/alerts.yml`:

```yaml
groups:
  - name: php_api_stack
    interval: 30s
    rules:
      - alert: HighErrorRate
        expr: rate(nginx_http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }} (threshold: 0.05)"

      - alert: HighResponseTime
        expr: histogram_quantile(0.99, nginx_request_duration_seconds_bucket) > 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High response time"
          description: "P99 latency is {{ $value }}s"

      - alert: PHPFPMPoolSaturation
        expr: phpfpm_active_processes / phpfpm_max_children > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "PHP-FPM pool near capacity"
          description: "Active: {{ $value }}%"

      - alert: RedisMemoryHigh
        expr: redis_memory_used_bytes / redis_memory_max_bytes > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Redis memory usage high"
          description: "Memory usage: {{ $value }}%"
```

---

## 🔧 Troubleshooting

### Services Won't Start

```bash
# Check service status
make compose-ps

# View logs
make compose-logs

# Check configuration
docker compose -f docker-compose.yml config

# Common issues:
# 1. Port conflicts
netstat -an | grep LISTEN | grep -E '8089|3306|6379|3000|9091'

# 2. Environment variables
cat .env | grep -v '^#' | grep -v '^

# 3. Network issues
docker network ls
docker network inspect php-api-stack_api-network
```

### MySQL Connection Issues

```bash
# Test connection from host
mysql -h 127.0.0.1 -P 3307 -u phpapi_hml -p
# Password: HmlUser_3kT8zQf

# Test from container
make compose-shell
mysql -h mysql -u phpapi_hml -p

# Check MySQL logs
make compose-logs-svc SERVICES="mysql"

# Reset MySQL
make compose-down-v
make compose-up PROFILES="db"
```

### Redis Connection Issues

```bash
# Test connection from host
redis-cli -h 127.0.0.1 -p 6380 -a HmlRedis_3Qy7nFTZgW6M2bK9pX4c
PING  # Should return PONG

# Test from container
make compose-shell
redis-cli -h redis-external -a HmlRedis_3Qy7nFTZgW6M2bK9pX4c

# Check Redis logs
make compose-logs-svc SERVICES="redis-external"
```

### Grafana Dashboard Not Loading

```bash
# Check Grafana logs
make compose-logs-svc SERVICES="grafana"

# Verify Prometheus datasource
curl http://localhost:3000/api/datasources

# Re-provision dashboards
docker compose -f docker-compose.yml restart grafana

# Manual import
# 1. Login to Grafana
# 2. Go to Dashboards > Import
# 3. Upload: example/config/grafana/dashboards/php-api-stack.json
```

### High Resource Usage

```bash
# Check resource usage
make compose-stats

# Identify problematic container
docker stats --no-stream | sort -k3 -h

# Adjust resource limits in docker-compose.yml
deploy:
  resources:
    limits:
      cpus: "0.5"      # Reduce CPU
      memory: 512M     # Reduce memory

# Restart service
make compose-restart
```

### Network Connectivity Issues

```bash
# List networks
docker network ls

# Inspect network
docker network inspect php-api-stack_api-network

# Test connectivity between containers
make compose-exec SERVICE=php-api-stack CMD="ping -c 3 mysql"
make compose-exec SERVICE=php-api-stack CMD="ping -c 3 redis-external"

# Check DNS resolution
make compose-exec SERVICE=php-api-stack CMD="nslookup mysql"
```

---

## ✅ Best Practices

### 1. Environment Management

```bash
# Use separate .env files for different environments
.env.development
.env.staging
.env.production

# Load appropriate file
cp .env.production .env
make compose-up-all
```

### 2. Volume Management

```bash
# Backup volumes before updates
docker run --rm \
  -v php-api-stack_mysql_data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/mysql-$(date +%Y%m%d).tar.gz /data

# Restore volumes
docker run --rm \
  -v php-api-stack_mysql_data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar xzf /backup/mysql-20251017.tar.gz -C /
```

### 3. Security Hardening

```bash
# Use secrets instead of plain text passwords
# Docker Compose secrets (Swarm mode)
secrets:
  db_password:
    file: ./secrets/db_password.txt

# Or use environment file
# .env (add to .gitignore)
DB_PASSWORD=$(openssl rand -base64 32)
```

### 4. Resource Allocation

```yaml
# Set appropriate limits for production
deploy:
  resources:
    limits:
      cpus: "2"
      memory: 2G
    reservations:
      cpus: "0.5"
      memory: 512M
```

### 5. Logging Strategy

```bash
# Configure log rotation
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"

# Centralized logging (optional)
# Use Fluentd, Logstash, or similar
```

### 6. Health Checks

```bash
# Always define health checks
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### 7. Scaling Strategy

```bash
# Horizontal scaling
docker compose -f docker-compose.yml up -d --scale php-api-stack=3

# Monitor with load balancer
make compose-up PROFILES="loadbalancer,monitoring"

# Auto-scaling (requires orchestrator like Kubernetes or Swarm)
```

---

## 📚 References

### Official Documentation

- [Docker Compose](https://docs.docker.com/compose/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [MySQL Docker](https://hub.docker.com/_/mysql)
- [Redis Docker](https://hub.docker.com/_/redis)
- [Nginx Docker](https://hub.docker.com/_/nginx)
- [Prometheus](https://prometheus.io/docs/introduction/overview/)
- [Grafana](https://grafana.com/docs/)

### Best Practices

- [Docker Compose Best Practices](https://docs.docker.com/compose/production/)
- [12-Factor App](https://12factor.net/)
- [Docker Security](https://docs.docker.com/engine/security/)
- [MySQL Performance Tuning](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)
- [Redis Best Practices](https://redis.io/docs/management/optimization/)

### Monitoring & Observability

- [Prometheus Best Practices](https://prometheus.io/docs/practices/naming/)
- [Grafana Tutorials](https://grafana.com/tutorials/)
- [cAdvisor](https://github.com/google/cadvisor)

---

## 🆘 Support

### Getting Help

- **GitHub Issues**: [Report bugs](https://github.com/kariricode/php-api-stack/issues)
- **Discussions**: [Ask questions](https://github.com/kariricode/php-api-stack/discussions)
- **Documentation**: [Full docs](README.md)

### Related Guides

- [README.md](README.md) - Project overview
- [IMAGE_USAGE_GUIDE.md](IMAGE_USAGE_GUIDE.md) - Using the Docker image
- [TESTING.md](TESTING.md) - Testing guide
- [DOCKER_HUB.md](DOCKER_HUB.md) - Publishing guide

---

**Made with 💚 by KaririCode** – [https://kariricode.org/](https://kariricode.org/)