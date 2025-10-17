# 📊 Monitoring Guide - PHP API Stack

Complete guide for using the monitoring system with Prometheus and Grafana.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Quick Start](#-quick-start)
- [Available Metrics](#-available-metrics)
- [Grafana Dashboard](#-grafana-dashboard)
- [Prometheus Alerts](#-prometheus-alerts)
- [PromQL Query Examples](#-promql-query-examples)
- [Troubleshooting](#-troubleshooting)
- [Best Practices](#-best-practices)
- [References](#-references)

---

## 🎯 Overview

The monitoring stack provides complete observability of the PHP API Stack through:

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **cAdvisor**: Container metrics
- **Exporters**: Nginx, PHP-FPM, and Redis

### Components

| Component | Port | Description |
|-----------|------|-------------|
| Application | 8089 | Main PHP API Stack |
| Prometheus | 9091 | Time-series database and alerting |
| Grafana | 3000 | Visualization and dashboards |
| cAdvisor | 8080 | Container metrics |
| Nginx Exporter | 9113 | Nginx metrics |
| PHP-FPM Exporter | 9253 | PHP-FPM metrics |
| Redis Exporter | 9121 | Redis metrics |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      PHP API Stack                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │  Nginx   │  │ PHP-FPM  │  │  Redis   │                  │
│  │  :80     │  │  :9000   │  │  :6379   │                  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                  │
│       │             │             │                          │
└───────┼─────────────┼─────────────┼──────────────────────────┘
        │             │             │
   ┌────▼─────┐  ┌───▼──────┐  ┌──▼───────┐
   │  Nginx   │  │ PHP-FPM  │  │  Redis   │
   │ Exporter │  │ Exporter │  │ Exporter │
   │  :9113   │  │  :9253   │  │  :9121   │
   └────┬─────┘  └────┬─────┘  └────┬─────┘
        │             │             │
        └──────────┬──┴─────────────┘
                   │
        ┌──────────▼──────────┐
        │    Prometheus        │
        │       :9091          │
        │  ┌────────────────┐  │
        │  │  Alert Rules   │  │
        │  │  alerts.yml    │  │
        │  └────────────────┘  │
        └──────────┬───────────┘
                   │
        ┌──────────▼──────────┐
        │      Grafana         │
        │       :3000          │
        │  ┌────────────────┐  │
        │  │  Dashboards    │  │
        │  └────────────────┘  │
        └──────────────────────┘
```

---

## 🚀 Quick Start

### 1. Start Complete Stack

```bash
# With Docker Compose (recommended)
make compose-up PROFILES="monitoring"

# Or manually
docker compose -f docker-compose.example.yml --profile monitoring up -d
```

### 2. Verify Services

```bash
# Container status
make compose-ps

# Check Prometheus targets
curl http://localhost:9091/api/v1/targets | jq .

# Grafana health check
curl http://localhost:3000/api/health
```

### 3. Access Interfaces

```bash
# Open all interfaces in browser
make compose-open

# Or access manually:
# - Grafana: http://localhost:3000 (admin / HmlGrafana_7uV4mRp)
# - Prometheus: http://localhost:9091
# - cAdvisor: http://localhost:8080
```

### 4. Verify Dashboard

1. Login to Grafana
2. Navigate: **Dashboards** → **PHP API Stack**
3. View real-time metrics

---

## 📈 Available Metrics

### Nginx Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `nginx_connections_active` | gauge | Active connections |
| `nginx_connections_reading` | gauge | Connections reading headers |
| `nginx_connections_writing` | gauge | Connections writing response |
| `nginx_connections_waiting` | gauge | Idle connections (keepalive) |
| `nginx_http_requests_total` | counter | Total HTTP requests |
| `nginx_connections_accepted` | counter | Accepted connections |
| `nginx_connections_handled` | counter | Handled connections |

**Useful queries:**
```promql
# Request rate
rate(nginx_http_requests_total[5m])

# Connections by state
nginx_connections_reading
nginx_connections_writing
nginx_connections_waiting
```

### PHP-FPM Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `phpfpm_active_processes` | gauge | Active processes |
| `phpfpm_idle_processes` | gauge | Idle processes |
| `phpfpm_total_processes` | gauge | Total processes |
| `phpfpm_listen_queue` | gauge | Requests in queue |
| `phpfpm_listen_queue_length` | gauge | Maximum queue size |
| `phpfpm_max_children_reached` | counter | Times limit was reached |
| `phpfpm_slow_requests` | counter | Slow requests |
| `phpfpm_accepted_connections` | counter | Accepted connections |

**Useful queries:**
```promql
# Pool saturation rate
(phpfpm_active_processes / phpfpm_total_processes) * 100

# Slow requests rate
rate(phpfpm_slow_requests[5m])

# Listen queue (critical if > 0)
phpfpm_listen_queue
```

### Redis Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `redis_connected_clients` | gauge | Connected clients |
| `redis_blocked_clients` | gauge | Blocked clients |
| `redis_memory_used_bytes` | gauge | Memory used |
| `redis_memory_max_bytes` | gauge | Maximum memory |
| `redis_keyspace_hits_total` | counter | Cache hits |
| `redis_keyspace_misses_total` | counter | Cache misses |
| `redis_evicted_keys_total` | counter | Evicted keys |
| `redis_expired_keys_total` | counter | Expired keys |
| `redis_commands_processed_total` | counter | Processed commands |
| `redis_mem_fragmentation_ratio` | gauge | Fragmentation ratio |

**Useful queries:**
```promql
# Cache hit rate
rate(redis_keyspace_hits_total[5m]) / 
(rate(redis_keyspace_hits_total[5m]) + rate(redis_keyspace_misses_total[5m])) * 100

# Memory usage
(redis_memory_used_bytes / redis_memory_max_bytes) * 100

# Eviction rate
rate(redis_evicted_keys_total[5m])
```

### Container Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `container_cpu_usage_seconds_total` | counter | CPU usage |
| `container_memory_usage_bytes` | gauge | Memory usage |
| `container_network_receive_bytes_total` | counter | Bytes received |
| `container_network_transmit_bytes_total` | counter | Bytes transmitted |
| `container_fs_usage_bytes` | gauge | Filesystem usage |

**Useful queries:**
```promql
# CPU usage %
rate(container_cpu_usage_seconds_total{
  container_label_com_docker_compose_service="php-api-stack"
}[5m]) * 100

# Memory usage %
container_memory_usage_bytes{
  container_label_com_docker_compose_service="php-api-stack"
} / container_spec_memory_limit_bytes * 100
```

---

## 📊 Grafana Dashboard

### Dashboard Sections

#### 1. **Key Performance Indicators (KPIs)**
- Requests Per Second (RPS)
- PHP Active Processes
- PHP Listen Queue
- Redis Cache Hit Ratio

#### 2. **Application Overview**
- Request Rate
- Response Time Percentiles (P50, P95, P99)
- Error Rate
- Active Connections

#### 3. **Container Health & Resources**
- CPU Usage
- Memory Usage
- Network Traffic

#### 4. **Nginx Details**
- Connections Status (Reading, Writing, Waiting)
- HTTP Status Codes Distribution

#### 5. **PHP-FPM Details**
- Process Manager State
- Slow Requests
- OPcache Statistics

#### 6. **Redis Details**
- Operations Per Second
- Cache Hit/Miss Rate
- Memory Usage
- Connected Clients
- Eviction Rate

### Customizing the Dashboard

#### Add New Panel

1. In Grafana, open **PHP API Stack** dashboard
2. Click **Add** → **Visualization**
3. Select **Prometheus** as datasource
4. Configure PromQL query
5. Adjust visualization and thresholds
6. **Save dashboard**

**Example - Error Rate Panel:**

```promql
sum(rate(nginx_http_requests_total{status=~"5.."}[5m])) / 
sum(rate(nginx_http_requests_total[5m])) * 100
```

#### Dashboard Variables

The dashboard supports variables for dynamic filtering:

- `$datasource`: Prometheus datasource
- `$interval`: Aggregation interval
- `$job`: Prometheus job (nginx, php_fpm, redis)

---

## 🚨 Prometheus Alerts

### Alert Structure

Alerts are organized in groups in the `alerts.yml` file:

1. **application_performance** - Application performance
2. **phpfpm_health** - PHP-FPM health
3. **nginx_health** - Nginx health
4. **redis_health** - Redis health
5. **container_health** - Container health
6. **prometheus_health** - Prometheus self-monitoring

### Critical Alerts

| Alert | Condition | Recommended Action |
|-------|-----------|-------------------|
| **PHPFPMListenQueueHigh** | Queue > 0 for 2min | Scale PHP processes or instances |
| **PHPFPMPoolSaturation** | 80% active processes | Increase `pm.max_children` |
| **RedisMemoryCritical** | 95% memory used | Increase maxmemory or clear cache |
| **ContainerMemoryCritical** | 95% container memory | Investigate memory leak or increase limit |
| **PrometheusTargetDown** | Target down for 2min | Check connectivity and logs |

### Check Active Alerts

```bash
# Via API
curl http://localhost:9091/api/v1/alerts | jq '.data.alerts[] | select(.state=="firing")'

# Via Web UI
open http://localhost:9091/alerts
```

### Testing Alerts

```bash
# Simulate high load (trigger PHPFPMPoolSaturation)
ab -n 100000 -c 200 http://localhost:8089/

# Monitor alert status
watch -n 2 'curl -s http://localhost:9091/api/v1/alerts | jq ".data.alerts[] | {alert: .labels.alertname, state: .state}"'
```

### Alert Severity Levels

| Severity | Description | Response Time | Example |
|----------|-------------|---------------|---------|
| **critical** | Service degradation/outage | Immediate (< 5min) | Service down, Memory critical |
| **warning** | Potential issues | Within 30min | High CPU, Slow requests |
| **info** | Informational only | Review daily | Configuration changes |

---

## 🔍 PromQL Query Examples

### Application Performance

```promql
# Request rate per minute
sum(rate(nginx_http_requests_total[1m])) * 60

# P95 response time
histogram_quantile(0.95, 
  rate(prometheus_http_request_duration_seconds_bucket[5m])
)

# Error rate (5xx responses)
sum(rate(nginx_http_requests_total{status=~"5.."}[5m])) / 
sum(rate(nginx_http_requests_total[5m])) * 100

# Success rate (2xx responses)
sum(rate(nginx_http_requests_total{status=~"2.."}[5m])) / 
sum(rate(nginx_http_requests_total[5m])) * 100
```

### PHP-FPM Analysis

```promql
# Average request duration (if available)
rate(phpfpm_process_request_duration[5m])

# Pool utilization percentage
(phpfpm_active_processes / 
 (phpfpm_active_processes + phpfpm_idle_processes)) * 100

# Slow request rate
rate(phpfpm_slow_requests[5m])

# Max children reached rate
rate(phpfpm_max_children_reached[5m])
```

### Redis Performance

```promql
# Operations per second
rate(redis_commands_processed_total[5m])

# Cache hit ratio
rate(redis_keyspace_hits_total[5m]) / 
(rate(redis_keyspace_hits_total[5m]) + 
 rate(redis_keyspace_misses_total[5m])) * 100

# Memory fragmentation
redis_mem_fragmentation_ratio

# Eviction rate
rate(redis_evicted_keys_total[5m])

# Command latency P99
redis_latency_percentiles_usec{quantile="0.99"}
```

### Container Monitoring

```promql
# CPU usage by container
sum(rate(container_cpu_usage_seconds_total[5m])) 
  by (container_label_com_docker_compose_service) * 100

# Memory usage by container
container_memory_usage_bytes{
  container_label_com_docker_compose_service="php-api-stack"
} / 1024 / 1024

# Network I/O
rate(container_network_receive_bytes_total[5m]) + 
rate(container_network_transmit_bytes_total[5m])
```

---

## 🔧 Troubleshooting

### Prometheus Not Scraping Metrics

**Symptoms:**
- Targets showing as "DOWN" in Prometheus UI
- No data in Grafana dashboards

**Diagnosis:**
```bash
# Check Prometheus targets
curl http://localhost:9091/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Check exporter connectivity
docker exec php-api-stack curl http://php-api-nginx-exporter:9113/metrics
docker exec php-api-stack curl http://php-api-phpfpm-exporter:9253/metrics
docker exec php-api-stack curl http://php-api-redis-exporter:9121/metrics
```

**Solutions:**
1. Verify all exporters are running: `make compose-ps`
2. Check network connectivity between containers
3. Verify exporter configurations in `docker-compose.yml`
4. Check Prometheus logs: `make compose-logs-svc SERVICES="prometheus"`

### Grafana Dashboard Not Loading Data

**Symptoms:**
- Dashboard panels show "No data"
- Queries timeout

**Diagnosis:**
```bash
# Test Prometheus datasource
curl http://localhost:3000/api/datasources

# Test query directly in Prometheus
curl 'http://localhost:9091/api/v1/query?query=up'
```

**Solutions:**
1. Verify Prometheus datasource is configured correctly in Grafana
2. Check if data is being collected: Visit Prometheus `/targets` page
3. Verify time range in Grafana dashboard
4. Test queries directly in Prometheus UI

### High Memory Usage

**Symptoms:**
- Container memory usage > 90%
- OOMKill events

**Diagnosis:**
```bash
# Check container memory
docker stats php-api-stack --no-stream

# Check Prometheus metrics
curl 'http://localhost:9091/api/v1/query?query=container_memory_usage_bytes'
```

**Solutions:**
1. Increase container memory limits in `docker-compose.yml`
2. Optimize PHP-FPM pool settings (`pm.max_children`)
3. Adjust Redis `maxmemory` setting
4. Review application for memory leaks

### Alert False Positives

**Symptoms:**
- Alerts firing incorrectly
- Too many notifications

**Diagnosis:**
```bash
# Check alert history
curl http://localhost:9091/api/v1/alerts | jq .

# View alert rules
curl http://localhost:9091/api/v1/rules | jq .
```

**Solutions:**
1. Adjust alert thresholds in `alerts.yml`
2. Increase `for` duration to reduce flapping
3. Add more specific label filters
4. Review alert conditions for accuracy

---

## ✅ Best Practices

### 1. **Metric Naming Conventions**

Follow Prometheus naming best practices:
- Use base units (seconds, bytes, not milliseconds or megabytes)
- Include unit suffix (`_seconds`, `_bytes`, `_total`)
- Use descriptive names (`http_requests_total` not `requests`)

### 2. **Alert Design**

```yaml
# ✅ GOOD: Specific, actionable alert
- alert: PHPFPMPoolSaturation
  expr: (phpfpm_active_processes / phpfpm_total_processes) > 0.8
  for: 5m
  annotations:
    summary: "PHP-FPM pool near capacity"
    description: "{{ $value | humanizePercentage }} - Consider increasing pm.max_children"

# ❌ BAD: Vague, non-actionable alert
- alert: SomethingWrong
  expr: some_metric > 100
  annotations:
    summary: "Check the system"
```

### 3. **Dashboard Organization**

- Group related metrics together
- Use consistent color schemes
- Add descriptions to panels
- Set appropriate time ranges
- Use template variables for flexibility

### 4. **Data Retention**

Configure appropriate retention in Prometheus:

```bash
# In docker-compose.yml command section:
--storage.tsdb.retention.time=15d
--storage.tsdb.retention.size=10GB
```

### 5. **Query Optimization**

```promql
# ✅ GOOD: Efficient aggregation
sum(rate(metric[5m])) by (label)

# ❌ BAD: Expensive query
sum(rate(metric[5m])) without (instance, job, pod, ...)
```

### 6. **Regular Maintenance**

```bash
# Weekly tasks
- Review alert false positives
- Check Prometheus storage usage
- Verify all targets are up
- Update dashboards based on new insights

# Monthly tasks
- Review and optimize slow queries
- Archive old dashboards
- Update alert thresholds based on trends
- Document any custom queries
```

### 7. **Security**

```bash
# Enable authentication in Grafana
# Use HTTPS for external access
# Restrict Prometheus API access
# Regular backup of Grafana dashboards
```

---

## 📚 References

### Official Documentation

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Alerting Rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)

### Exporters

- [Nginx Exporter](https://github.com/nginxinc/nginx-prometheus-exporter)
- [PHP-FPM Exporter](https://github.com/hipages/php-fpm_exporter)
- [Redis Exporter](https://github.com/oliver006/redis_exporter)
- [cAdvisor](https://github.com/google/cadvisor)

### Best Practices

- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Monitoring Best Practices](https://www.robustperception.io/blog/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)
- [Grafana Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)

### Books & Articles

- "Prometheus: Up & Running" by Brian Brazil
- "Observability Engineering" by Charity Majors
- [Google SRE Book - Monitoring](https://sre.google/sre-book/monitoring-distributed-systems/)

---

## 🆘 Support

For issues and questions:

- **GitHub Issues**: [Report bugs](https://github.com/kariricode/php-api-stack/issues)
- **Discussions**: [Ask questions](https://github.com/kariricode/php-api-stack/discussions)
- **Documentation**: [Full documentation](README.md)

---

**Related Guides:**
- [README.md](README.md) - Project overview
- [DOCKER_COMPOSE_GUIDE.md](DOCKER_COMPOSE_GUIDE.md) - Docker Compose guide
- [TESTING.md](TESTING.md) - Testing guide

---

**Made with 💚 by KaririCode** – [https://kariricode.org/](https://kariricode.org/)