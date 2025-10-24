# KaririCode/php-api-stack

Production‑ready **PHP API Stack** image built on Alpine Linux with **Nginx + PHP‑FPM + Redis**. Secured, fast, and configurable via environment variables — ideal for modern APIs and web apps.

<p align="center">
  <a href="https://hub.docker.com/r/kariricode/php-api-stack"><img alt="Docker Pulls" src="https://img.shields.io/docker/pulls/kariricode/php-api-stack"></a>
  <a href="https://github.com/kariricode/php-api-stack"><img alt="Source" src="https://img.shields.io/badge/source-GitHub-black?logo=github"></a>
  <a href="https://kariricode.org/"><img alt="KaririCode" src="https://img.shields.io/badge/site-kariricode.org-0aa344"></a>
  <img alt="Version" src="https://img.shields.io/badge/version-1.2.0-blue">
  <img alt="PHP" src="https://img.shields.io/badge/PHP-8.4-777bb3?logo=php">
  <img alt="Alpine" src="https://img.shields.io/badge/Alpine-3.21-0d597f?logo=alpine-linux">
</p>

---

## 🔗 Official Links

* **Repository (source)**: [https://github.com/kariricode/php-api-stack](https://github.com/kariricode/php-api-stack)
* **Official site**: [https://kariricode.org/](https://kariricode.org/)
* **KaririCode Framework (org)**: [https://github.com/KaririCode-Framework](https://github.com/KaririCode-Framework)

---

## ✨ Highlights

* **Complete Stack**: Nginx (1.27.3) + PHP‑FPM (8.4) + Redis (7.2)
* **Performance**: OPcache + JIT, tuned Nginx/PHP‑FPM, socket‑based FPM
* **Security‑first**: non‑root services, hardened defaults, CSP/HSTS headers
* **Easy Config**: 100% via environment variables or `.env`
* **Healthcheck**: `/health.php` (simple or comprehensive build)
* **CI/CD‑ready**: multi‑platform builds; Makefile targets; scan/lint helpers

> Image tag `1.2.0` is the latest stable at publication time. Use `:latest` for automatic updates or pin to exact versions for reproducibility.

---

## 🚀 Quick Start

Pull and run the demo page:

```bash
docker run -d \
  -p 8080:80 \
  --name php-api-stack-demo \
  kariricode/php-api-stack:latest

# open: http://localhost:8080
```

Run with your application mounted:

```bash
docker run -d \
  -p 8080:80 \
  --name my-php-app \
  -e APP_ENV=production \
  -e PHP_MEMORY_LIMIT=512M \
  -v $(pwd)/app:/var/www/html \
  kariricode/php-api-stack:latest
```

> **Note**: Your app’s public entry point must be at `/var/www/html/public/index.php`.

---

## 🐳 Docker Compose

Minimal `docker-compose.yml`:

```yaml
version: '3.9'
services:
  app:
    image: kariricode/php-api-stack:latest
    container_name: php-api-stack
    ports:
      - "8080:80"
    env_file: .env
    volumes:
      - ./app:/var/www/html
      - ./logs:/var/log
    depends_on:
      - redis
  redis:
    image: redis:7.2-alpine
    command: ["redis-server", "/etc/redis/redis.conf", "--appendonly", "yes"]
    volumes:
      - redis_data:/data
volumes:
  redis_data:
```

Start services:

```bash
docker compose up -d
```

**Production tips**

* Mount app read‑only: `./app:/var/www/html:ro`
* Add healthcheck:

```yaml
healthcheck:
  test: ["CMD-SHELL", "curl -fsS http://localhost/health.php || exit 1"]
  interval: 30s
  timeout: 3s
  retries: 3
  start_period: 10s
```

---

## ⚙️ Configuration (most used)

Set via `-e` or `.env`:

| Variable                     | Default                 | Description                                             |
| ---------------------------- | ----------------------- | ------------------------------------------------------- |
| `APP_ENV`                    | `production`            | `production`, `staging`, `development`                  |
| `APP_DEBUG`                  | `false`                 | Verbose errors (use only in dev)                        |
| `PHP_MEMORY_LIMIT`           | `256M`                  | Per‑request memory limit                                |
| `PHP_UPLOAD_MAX_FILESIZE`    | `100M`                  | Upload size                                             |
| `PHP_DATE_TIMEZONE`          | `UTC/America/Sao_Paulo` | Server timezone                                         |
| `PHP_FPM_PM`                 | `dynamic`*              | FPM process manager (*auto‑forced to `static` in prod*) |
| `PHP_FPM_PM_MAX_CHILDREN`    | `60`                    | FPM workers (increase in prod)                          |
| `NGINX_CLIENT_MAX_BODY_SIZE` | `100M`                  | Request body limit                                      |
| `PHP_SESSION_SAVE_HANDLER`   | `redis`                 | `redis` or `files`                                      |
| `PHP_SESSION_SAVE_PATH`      | `tcp://redis:6379`      | Session DSN                                             |
| `PHP_OPCACHE_ENABLE`         | `1`                     | Enable OPcache                                          |
| `PHP_OPCACHE_JIT`            | `tracing`               | JIT mode                                                |

> See the **full matrix** in the GitHub repo’s `.env.example` and docs.

---

## 🏷️ Tags

* `1.2.0` – latest stable
* `latest` – tracks the most recent stable release
* `X.Y` (e.g., `1.2`) – latest patch within the minor series
* `X` (e.g., `1`) – latest minor within the major series
* `test` – image variant with extended health checks for testing

Pull a specific tag:

```bash
docker pull kariricode/php-api-stack:latest
```

---

## 🔍 Health Check

* **Simple**: lightweight JSON at `/health.php`

Runtime verification:

```bash
curl -fsS http://localhost:8080/health.php | jq
```

---

## 🧪 Troubleshooting

**Container fails to start**

```bash
docker logs <container>
```

**502 Bad Gateway** (FPM not responding)

```bash
docker exec <container> ps aux | grep php-fpm

docker exec <container> tail -f /var/log/php/fpm-error.log
```

**Slow performance**

```bash
docker stats <container>

docker exec <container> php -r "print_r(opcache_get_status()['opcache_statistics']['opcache_hit_rate']);"
```

---

## 🔐 Security Notes

* Runs services without root privileges; hardened defaults
* Enable/add headers via `SECURITY_HEADERS`, `SECURITY_CSP`, `SECURITY_HSTS_MAX_AGE`
* Prefer immutable deployments in prod (`PHP_OPCACHE_VALIDATE_TIMESTAMPS=0`)

---

## 🧭 Roadmap & Contributing

Feature requests and PRs are welcome in the source repository:

* GitHub: [https://github.com/kariricode/php-api-stack](https://github.com/kariricode/php-api-stack)

For broader ecosystem projects, visit:

* KaririCode Framework: [https://github.com/KaririCode-Framework](https://github.com/KaririCode-Framework)

---

## 📝 Changelog (excerpt)

**1.2.0**

* PHP 8.4, Nginx 1.27.3, Redis 7.2
* Socket‑based PHP‑FPM; OPcache + JIT optimized
* `/health.php` endpoint; improved entrypoint & config processor
* Extensive env‑var configuration for Nginx/PHP/Redis

> Full release notes are available in the GitHub repository.

---

## 📄 License

See `LICENSE` in the source repository.

---

## 🙌 Credits

Made with 💚 by **KaririCode** — [https://kariricode.org/](https://kariricode.org/)
