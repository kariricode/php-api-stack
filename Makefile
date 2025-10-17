# Makefile for PHP API Stack Docker Image
# Usage: make [target]

# =============================================================
# Variables
# =============================================================
DOCKER_HUB_USER := kariricode
IMAGE_NAME      := php-api-stack
VERSION         := $(shell cat VERSION 2>/dev/null || echo "1.2.0")
FULL_IMAGE      := $(DOCKER_HUB_USER)/$(IMAGE_NAME)

# Container names
LOCAL_CONTAINER := $(IMAGE_NAME)-local
TEST_CONTAINER  := $(IMAGE_NAME)-test
CI_TEST_CONTAINER := $(IMAGE_NAME)-ci-test

# Ports (can be overridden: e.g., make run LOCAL_PORT=8000)
LOCAL_PORT ?= 8080
TEST_PORT  ?= 8081

# Version tags
MAJOR_VERSION := $(shell echo $(VERSION) | cut -d. -f1)
MINOR_VERSION := $(shell echo $(VERSION) | cut -d. -f1-2)

# Colors
RED     := \033[0;31m
GREEN   := \033[0;32m
YELLOW  := \033[1;33m
BLUE    := \033[0;34m
CYAN    := \033[0;36m
MAGENTA := \033[0;35m
NC      := \033[0m

# Default target
.DEFAULT_GOAL := help

# Detect build script
BUILD_SCRIPT := ./build-from-env.sh
HAVE_BUILD_SCRIPT := $(shell [ -x $(BUILD_SCRIPT) ] && echo 1 || echo 0)

# Docker build args (override via env: e.g., `make build PHP_VERSION=8.4`)
PHP_VERSION?=8.4
NGINX_VERSION?=1.27.3
REDIS_VERSION?=7.2
ALPINE_VERSION?=3.21
COMPOSER_VERSION?=2.8.12
SYMFONY_CLI_VERSION?=5.15.1

# Common build args block
BUILD_ARGS := \
    --build-arg PHP_VERSION=$(PHP_VERSION) \
    --build-arg NGINX_VERSION=$(NGINX_VERSION) \
    --build-arg REDIS_VERSION=$(REDIS_VERSION) \
    --build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
    --build-arg COMPOSER_VERSION=$(COMPOSER_VERSION) \
    --build-arg SYMFONY_CLI_VERSION=$(SYMFONY_CLI_VERSION) \
    --build-arg VERSION=$(VERSION) \
    --build-arg BUILD_DATE="$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --build-arg VCS_REF=$$(git rev-parse --short=12 HEAD 2>/dev/null || echo unknown)

# =============================================================
# Help
# =============================================================
.PHONY: help
help: ## Show this help message
	@echo "$(GREEN)╔══════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║      PHP API Stack - Docker Build System           ║$(NC)"
	@echo "$(GREEN)╚══════════════════════════════════════════════════════╝$(NC)"
	@echo "$(CYAN)Version: $(VERSION)$(NC)"
	@echo ""
	@echo "$(MAGENTA)═══ BUILD TARGETS ═══$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v "^#" | awk 'BEGIN {FS = ":.*?## "}; /^build/ || /^scan/ || /^lint/ {printf "  $(YELLOW)%-22s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(MAGENTA)═══ TEST TARGETS ═══$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v "^#" | awk 'BEGIN {FS = ":.*?## "}; /^test/ || /run-test/ || /stop-test/ || /logs-test/ || /shell-test/ {printf "  $(YELLOW)%-22s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(MAGENTA)═══ RUNTIME TARGETS ═══$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v "^#" | awk 'BEGIN {FS = ":.*?## "}; /^run/ || /^stop$$/ || /^restart/ || /^logs$$/ || /^exec/ || /^shell$$/ {printf "  $(YELLOW)%-22s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(MAGENTA)═══ UTILITY TARGETS ═══$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v "^#" | awk 'BEGIN {FS = ":.*?## "}; /version/ || /bump/ || /push/ || /release/ || /clean/ || /info/ || /stats/ {printf "  $(YELLOW)%-22s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Quick Start Examples:$(NC)"
	@echo "  $(CYAN)make build$(NC)           # Build production image"
	@echo "  $(CYAN)make build-dev$(NC)       # Build dev image (Symfony CLI/Xdebug opt.)"
	@echo "  $(CYAN)make run$(NC)             # Run local container on port $(LOCAL_PORT)"
	@echo "  $(CYAN)make run-test$(NC)        # Run test container on port $(TEST_PORT) with comprehensive health"
	@echo "  $(CYAN)make release$(NC)         # Full release pipeline"

# =============================================================
# BUILD TARGETS
# =============================================================
.PHONY: build
build: ## Build the Docker image locally (production)
	@echo "$(GREEN)Building production Docker image...$(NC)"
	@if [ $(HAVE_BUILD_SCRIPT) -eq 1 ]; then \
		$(BUILD_SCRIPT) --version=$(VERSION); \
	else \
		docker build $(BUILD_ARGS) -t $(FULL_IMAGE):$(VERSION) . && \
		docker tag $(FULL_IMAGE):$(VERSION) $(FULL_IMAGE):latest && \
		echo "Tagged: $(FULL_IMAGE):latest"; \
	fi
	@echo "$(GREEN)✓ Production build complete!$(NC)"

.PHONY: build-no-cache
build-no-cache: ## Build without using cache (production)
	@echo "$(GREEN)Building Docker image (no cache)...$(NC)"
	@if [ $(HAVE_BUILD_SCRIPT) -eq 1 ]; then \
		$(BUILD_SCRIPT) --no-cache --version=$(VERSION); \
	else \
		docker build --no-cache $(BUILD_ARGS) -t $(FULL_IMAGE):$(VERSION) . && \
		docker tag $(FULL_IMAGE):$(VERSION) $(FULL_IMAGE):latest; \
	fi
	@echo "$(GREEN)✓ Build complete!$(NC)"

.PHONY: build-dev
build-dev: ## Build development image (target=dev, optional Xdebug ENABLE_XDEBUG=1)
	@echo "$(GREEN)Building development Docker image...$(NC)"
	@docker build $(BUILD_ARGS) --target dev \
		--build-arg ENABLE_XDEBUG=$(or $(ENABLE_XDEBUG),0) \
		-t $(FULL_IMAGE):dev .
	@echo "$(GREEN)✓ Dev image built as $(FULL_IMAGE):dev$(NC)"

.PHONY: build-test-image
build-test-image: ## Build test image (production base) with comprehensive health check
	@echo "$(GREEN)Building test image with comprehensive health check...$(NC)"
	@docker build $(BUILD_ARGS) --build-arg HEALTH_CHECK_TYPE=comprehensive \
		-t $(FULL_IMAGE):test .
	@echo "$(GREEN)✓ Test image built: $(FULL_IMAGE):test$(NC)"

# =============================================================
# TEST TARGETS
# =============================================================
.PHONY: test-quick
test-quick: ## Quick test of built image (versions only)
	@echo "$(GREEN)Running quick version tests...$(NC)"
	@echo "\n$(CYAN)Testing PHP:$(NC)"
	@docker run --rm --entrypoint php $(FULL_IMAGE):latest -v | head -2
	@echo "\n$(CYAN)Testing Nginx:$(NC)"
	@docker run --rm --entrypoint nginx $(FULL_IMAGE):latest -v 2>&1 | head -1
	@echo "\n$(CYAN)Testing Redis:$(NC)"
	@docker run --rm --entrypoint redis-server $(FULL_IMAGE):latest --version
	@echo "\n$(CYAN)Testing Composer:$(NC)"
	@docker run --rm --entrypoint composer $(FULL_IMAGE):latest --version --no-ansi | head -1
	@echo "\n$(GREEN)✓ All components verified!$(NC)"

.PHONY: test
test: ## Run comprehensive tests on the production image
	@echo "$(GREEN)Running comprehensive tests...$(NC)"
	@echo "\n$(YELLOW)[1/5] Testing component versions...$(NC)"
	@$(MAKE) test-quick --no-print-directory
	@echo "\n$(YELLOW)[2/5] Testing configuration processing...$(NC)"
	@docker run --rm $(FULL_IMAGE):latest /usr/local/bin/process-configs
	@echo "\n$(YELLOW)[3/5] Testing Nginx configuration...$(NC)"
	@docker run --rm --entrypoint nginx $(FULL_IMAGE):latest -t
	@echo "\n$(YELLOW)[4/5] Testing PHP-FPM configuration...$(NC)"
	@docker run --rm --entrypoint php-fpm $(FULL_IMAGE):latest -t
	@echo "\n$(YELLOW)[5/5] Testing health endpoint...$(NC)"
	@docker run -d --name $(CI_TEST_CONTAINER) -p $(TEST_PORT):80 $(FULL_IMAGE):latest >/dev/null
	@echo "Waiting for container to start on port $(TEST_PORT)..."
	@tries=0; while ! curl -s -f -o /dev/null http://localhost:$(TEST_PORT)/health; do \
		sleep 2; \
		tries=$$(($$tries + 1)); \
		if [ $$tries -ge 15 ]; then \
			echo "$(RED)✗ Health check failed: Container did not become healthy in time.$(NC)"; \
			docker logs $(CI_TEST_CONTAINER); \
			docker stop $(CI_TEST_CONTAINER) >/dev/null; \
			docker rm $(CI_TEST_CONTAINER) >/dev/null; \
			exit 1; \
		fi; \
	done
	@echo "$(GREEN)✓ Health check passed$(NC)"
	@docker stop $(CI_TEST_CONTAINER) >/dev/null
	@docker rm $(CI_TEST_CONTAINER) >/dev/null
	@echo "\n$(GREEN)✓ All tests complete!$(NC)"

.PHONY: run-test
run-test: build-test-image ## Run test container (comprehensive health)
	@echo "$(GREEN)Starting test container...$(NC)"
	@docker stop $(TEST_CONTAINER) >/dev/null 2>&1 || true
	@docker rm $(TEST_CONTAINER) >/dev/null 2>&1 || true
	@docker run -d \
		--name $(TEST_CONTAINER) \
		-p $(TEST_PORT):80 \
		--env-file .env \
		-v $(PWD)/logs:/var/log \
		$(FULL_IMAGE):test
	@echo "\n$(GREEN)✓ Test container running!$(NC)"
	@echo "$(CYAN)════════════════════════════════════════$(NC)"
	@echo "$(CYAN)Container:$(NC)    $(TEST_CONTAINER)"
	@echo "$(CYAN)URL:$(NC)           http://localhost:$(TEST_PORT)"
	@echo "$(CYAN)Health Check:$(NC) http://localhost:$(TEST_PORT)/health"
	@echo "$(CYAN)════════════════════════════════════════$(NC)"
	@echo "\n$(YELLOW)⏳ Waiting for services to start...$(NC)"; sleep 5
	@echo "\n$(CYAN)Testing comprehensive health endpoint...$(NC)"
	@curl -s http://localhost:$(TEST_PORT)/health || true

.PHONY: test-health
test-health: ## Test comprehensive health check endpoint
	@if [ -z "$$(docker ps -q -f name=$(TEST_CONTAINER))" ]; then \
		echo "$(RED)Test container not running!$(NC)"; \
		echo "Run '$(CYAN)make run-test$(NC)' first."; \
		exit 1; \
	fi
	@curl -s http://localhost:$(TEST_PORT)/health.php | jq '.' || curl -s http://localhost:$(TEST_PORT)/health

.PHONY: test-health-status
test-health-status: ## Show health check status summary
	@if [ -z "$$(docker ps -q -f name=$(TEST_CONTAINER))" ]; then \
		echo "$(RED)Test container not running!$(NC)"; exit 1; \
	fi
	@echo "$(GREEN)Health Check Status Summary$(NC)"
	@echo "$(CYAN)════════════════════════════════════════$(NC)"
	@curl -s http://localhost:$(TEST_PORT)/health.php | jq -r '"Overall: \(.status | ascii_upcase)"' || true
	@curl -s http://localhost:$(TEST_PORT)/health.php | jq -r '"Duration: \(.duration_ms // "n/a")ms"' || true
	@echo ""; echo "$(CYAN)Component Status:$(NC)"; \
	curl -s http://localhost:$(TEST_PORT)/health.php | jq -r '.checks | to_entries[] | "  \(.key | ascii_upcase): \(.value.status)"' || true

.PHONY: test-health-watch
test-health-watch: ## Watch health check status (updates every 5s)
	@if [ -z "$$(docker ps -q -f name=$(TEST_CONTAINER))" ]; then \
		echo "$(RED)Test container not running!$(NC)"; \
		echo "Run '$(CYAN)make run-test$(NC)' first."; \
		exit 1; \
	fi
	@echo "$(GREEN)Watching health status (Ctrl+C to stop)...$(NC)"; echo ""
	@watch -n 5 "curl -s http://localhost:$(TEST_PORT)/health.php | jq '{overall: .status, duration_ms: .duration_ms, checks: (.checks // {})}'"

.PHONY: stop-test
stop-test: ## Stop and remove test container
	@echo "$(YELLOW)Stopping test container...$(NC)"
	@docker stop $(TEST_CONTAINER) >/dev/null 2>&1 || true
	@docker rm $(TEST_CONTAINER) >/dev/null 2>&1 || true
	@echo "$(GREEN)✓ Test container stopped$(NC)"

.PHONY: logs-test
logs-test: ## Show logs from test container
	@if [ -z "$$(docker ps -a -q -f name=$(TEST_CONTAINER))" ]; then \
		echo "$(RED)Test container not found!$(NC)"; \
		echo "Run '$(CYAN)make run-test$(NC)' first."; \
	else \
		echo "$(GREEN)Showing logs for $(TEST_CONTAINER)...$(NC)"; \
		docker logs -f $(TEST_CONTAINER); \
	fi

.PHONY: shell-test
shell-test: ## Execute bash in test container
	@if [ -z "$$(docker ps -q -f name=$(TEST_CONTAINER))" ]; then \
		echo "$(RED)Test container not running!$(NC)"; \
		echo "Run '$(CYAN)make run-test$(NC)' first."; \
	else \
		docker exec -it $(TEST_CONTAINER) bash; \
	fi

# =============================================================
# VALIDATION TARGETS
# =============================================================
.PHONY: test-structure
test-structure: ## Test container structure and files
	@echo "$(GREEN)Testing container structure...$(NC)"
	@docker run --rm $(FULL_IMAGE):latest ls -la /var/www/html/public/ || true
	@docker run --rm $(FULL_IMAGE):latest ls -la /etc/nginx/ || true
	@docker run --rm $(FULL_IMAGE):latest ls -la /usr/local/etc/php/ || true

.PHONY: scan
scan: ## Scan the image for vulnerabilities using Trivy
	@echo "$(GREEN)Scanning for vulnerabilities...$(NC)"
	@if command -v trivy >/dev/null 2>&1; then \
		trivy image --severity HIGH,CRITICAL $(FULL_IMAGE):latest; \
	else \
		docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL $(FULL_IMAGE):latest; \
	fi

.PHONY: lint
lint: ## Lint the Dockerfile with hadolint
	@echo "$(GREEN)Linting Dockerfile...$(NC)"
	@if command -v hadolint >/dev/null 2>&1; then \
		hadolint Dockerfile || true; \
	else \
		docker run --rm -i hadolint/hadolint < Dockerfile || true; \
	fi

# =============================================================
# RUNTIME TARGETS
# =============================================================
.PHONY: run
run: ## Run local container for demo/testing
	@echo "$(GREEN)Starting local container...$(NC)"
	@docker stop $(LOCAL_CONTAINER) >/dev/null 2>&1 || true
	@docker rm $(LOCAL_CONTAINER) >/dev/null 2>&1 || true
	@docker run -d \
		--name $(LOCAL_CONTAINER) \
		-p $(LOCAL_PORT):80 \
		-e DEMO_MODE=true \
		--env-file .env \
		-v $(PWD)/logs:/var/log \
		$(FULL_IMAGE):latest
	@echo "$(GREEN)✓ Container running at http://localhost:$(LOCAL_PORT)$(NC)"
	@echo "$(CYAN)Container name:$(NC) $(LOCAL_CONTAINER)"
	@echo "\n$(YELLOW)⏳ Waiting for services to start...$(NC)"; sleep 5
	@echo "\n$(CYAN)Testing demo page...$(NC)"
	@if curl -s http://localhost:$(LOCAL_PORT) | grep -q "PHP API Stack"; then \
		echo "$(GREEN)✓ Demo page is live!$(NC)"; \
		echo "$(CYAN)Visit:$(NC) http://localhost:$(LOCAL_PORT)"; \
	else \
		echo "$(YELLOW)⚠ Page loaded but demo not detected$(NC)"; \
	fi
	@echo "\n$(BLUE)Useful commands:$(NC)"
	@echo "  $(CYAN)make stop$(NC)            # Stop container"
	@echo "  $(CYAN)make logs$(NC)            # View logs"
	@echo "  $(CYAN)make shell$(NC)           # Access shell"
	@echo "  $(CYAN)make run-with-app$(NC)  # Run with app mounted"

.PHONY: run-with-app
run-with-app: ## Run local container with mounted application
	@echo "$(GREEN)Starting local container with application mount...$(NC)"
	@docker stop $(LOCAL_CONTAINER) >/dev/null 2>&1 || true
	@docker rm $(LOCAL_CONTAINER) >/dev/null 2>&1 || true
	@if [ ! -d "$(PWD)/app" ]; then \
		echo "$(YELLOW)Creating app directory...$(NC)"; \
		mkdir -p $(PWD)/app/public; \
	fi
	@docker run -d \
		--name $(LOCAL_CONTAINER) \
		-p $(LOCAL_PORT):80 \
		-e DEMO_MODE=true \
		--env-file .env \
		-v $(PWD)/app:/var/www/html \
		-v $(PWD)/logs:/var/log \
		$(FULL_IMAGE):latest
	@echo "$(GREEN)✓ Container running at http://localhost:$(LOCAL_PORT)$(NC)"
	@echo "$(CYAN)Application mounted from:$(NC) $(PWD)/app"
	@echo "\n$(BLUE)Next steps:$(NC)"
	@echo "  1. Create your $(CYAN)app/public/index.php$(NC)"
	@echo "  2. Run $(CYAN)docker exec $(LOCAL_CONTAINER) nginx -s reload$(NC)"
	@echo "  3. Visit http://localhost:$(LOCAL_PORT)"

.PHONY: stop
stop: ## Stop and remove local container
	@echo "$(YELLOW)Stopping local container...$(NC)"
	@docker stop $(LOCAL_CONTAINER) >/dev/null 2>&1 || true
	@docker rm $(LOCAL_CONTAINER) >/dev/null 2>&1 || true
	@echo "$(GREEN)✓ Container stopped$(NC)"

.PHONY: restart
restart: stop run ## Restart the local container

.PHONY: logs
logs: ## Show logs from local container
	@if [ -z "$$(docker ps -a -q -f name=$(LOCAL_CONTAINER))" ]; then \
		echo "$(RED)No container named $(LOCAL_CONTAINER) found!$(NC)"; \
		echo "Run '$(CYAN)make run$(NC)' first."; \
	else \
		echo "$(GREEN)Showing logs for $(LOCAL_CONTAINER)...$(NC)"; \
		docker logs -f $(LOCAL_CONTAINER); \
	fi

.PHONY: exec
exec: ## Execute bash in the running local container
	@if [ -z "$$(docker ps -q -f name=$(LOCAL_CONTAINER))" ]; then \
		echo "$(RED)No running container found!$(NC)"; \
		echo "Run '$(CYAN)make run$(NC)' first."; \
	else \
		docker exec -it $(LOCAL_CONTAINER) bash; \
	fi

.PHONY: shell
shell: exec ## Alias for exec

# =============================================================
# RELEASE TARGETS
# =============================================================
.PHONY: tag-latest
tag-latest: ## Tag current version as latest/major/minor
	@docker tag $(FULL_IMAGE):$(VERSION) $(FULL_IMAGE):latest || true
	@docker tag $(FULL_IMAGE):$(VERSION) $(FULL_IMAGE):$(MAJOR_VERSION) || true
	@docker tag $(FULL_IMAGE):$(VERSION) $(FULL_IMAGE):$(MINOR_VERSION) || true
	@echo "$(GREEN)✓ Tags created: latest, $(MAJOR_VERSION), $(MINOR_VERSION)$(NC)"

.PHONY: push
push: ## Push the image to Docker Hub
	@echo "$(GREEN)Pushing to Docker Hub...$(NC)"
	@echo "Pushing $(FULL_IMAGE):$(VERSION)..."
	@docker push $(FULL_IMAGE):$(VERSION)
	@docker push $(FULL_IMAGE):latest || true
	@docker push $(FULL_IMAGE):$(MAJOR_VERSION) || true
	@docker push $(FULL_IMAGE):$(MINOR_VERSION) || true
	@echo "$(GREEN)✓ Push complete!$(NC)"
	@echo "Available at: https://hub.docker.com/r/$(FULL_IMAGE)"

.PHONY: release
release: lint build test scan tag-latest push ## Full release pipeline
	@echo "$(GREEN)════════════════════════════════════════$(NC)"
	@echo "$(GREEN)✅ Release $(VERSION) complete!$(NC)"
	@echo "$(GREEN)════════════════════════════════════════$(NC)"

# =============================================================
# VERSION MANAGEMENT
# =============================================================
.PHONY: version
version: ## Display current version
	@echo "$(CYAN)Current version:$(NC) $(VERSION)"
	@echo "$(CYAN)Docker image:$(NC)   $(FULL_IMAGE):$(VERSION)"

.PHONY: bump-patch
bump-patch: ## Bump patch version (x.x.X)
	@VERSION=$$(echo $(VERSION) | awk -F. '{print $$1"."$$2"."$$3+1}'); \
	echo $$VERSION > VERSION; \
	echo "$(GREEN)✓ Version bumped to $$VERSION$(NC)"; \
	git add VERSION 2>/dev/null || true; \
	git commit -m "chore: bump version to $$VERSION" 2>/dev/null || true

.PHONY: bump-minor
bump-minor: ## Bump minor version (x.X.x)
	@VERSION=$$(echo $(VERSION) | awk -F. '{print $$1"."$$2+1".0"}'); \
	echo $$VERSION > VERSION; \
	echo "$(GREEN)✓ Version bumped to $$VERSION$(NC)"; \
	git add VERSION 2>/dev/null || true; \
	git commit -m "chore: bump version to $$VERSION" 2>/dev/null || true

.PHONY: bump-major
bump-major: ## Bump major version (X.x.x)
	@VERSION=$$(echo $(VERSION) | awk -F. '{print $$1+1".0.0"}'); \
	echo $$VERSION > VERSION; \
	echo "$(GREEN)✓ Version bumped to $$VERSION$(NC)"; \
	git add VERSION 2>/dev/null || true; \
	git commit -m "chore: bump version to $$VERSION" 2>/dev/null || true

# =============================================================
# CLEANUP TARGETS
# =============================================================
.PHONY: clean
clean: ## Remove local images and containers
	@echo "$(YELLOW)Cleaning up...$(NC)"
	@docker stop $(LOCAL_CONTAINER) $(TEST_CONTAINER) >/dev/null 2>&1 || true
	@docker rm $(LOCAL_CONTAINER) $(TEST_CONTAINER) >/dev/null 2>&1 || true
	@docker rmi $(FULL_IMAGE):$(VERSION) >/dev/null 2>&1 || true
	@docker rmi $(FULL_IMAGE):latest >/dev/null 2>&1 || true
	@docker rmi $(FULL_IMAGE):test >/dev/null 2>&1 || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

.PHONY: clean-all
clean-all: clean ## Deep clean including volumes and build cache
	@echo "$(YELLOW)Deep cleaning...$(NC)"
	@docker volume prune -f 2>/dev/null || true
	@docker builder prune -f 2>/dev/null || true
	@echo "$(GREEN)✓ Deep cleanup complete$(NC)"

# =============================================================
# INFORMATION TARGETS
# =============================================================
.PHONY: info
info: ## Show image information
	@echo "$(CYAN)════════════════════════════════════════$(NC)"
	@echo "$(GREEN)PHP API Stack - Image Information$(NC)"
	@echo "$(CYAN)════════════════════════════════════════$(NC)"
	@echo "  $(CYAN)Hub User:$(NC)    $(DOCKER_HUB_USER)"
	@echo "  $(CYAN)Image:$(NC)       $(IMAGE_NAME)"
	@echo "  $(CYAN)Version:$(NC)     $(VERSION)"
	@echo "  $(CYAN)Full path:$(NC)   $(FULL_IMAGE):$(VERSION)"
	@echo "\n$(GREEN)Container names:$(NC)"
	@echo "  $(CYAN)Local:$(NC)       $(LOCAL_CONTAINER) (Port: $(LOCAL_PORT))"
	@echo "  $(CYAN)Test:$(NC)        $(TEST_CONTAINER) (Port: $(TEST_PORT))"
	@echo "\n$(GREEN)Available tags:$(NC)"
	@echo "  - $(FULL_IMAGE):$(VERSION)"
	@echo "  - $(FULL_IMAGE):$(MAJOR_VERSION)"
	@echo "  - $(FULL_IMAGE):$(MINOR_VERSION)"
	@echo "  - $(FULL_IMAGE):latest"
	@echo "  - $(FULL_IMAGE):test"
	@echo ""
	@if docker images $(FULL_IMAGE) --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep -q $(IMAGE_NAME); then \
		echo "$(GREEN)Local images:$(NC)"; \
		docker images $(FULL_IMAGE) --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"; \
	else \
		echo "$(YELLOW)No local images found. Run 'make build' to create one.$(NC)"; \
	fi

.PHONY: stats
stats: ## Show container resource usage
	@if [ -z "$$(docker ps -q -f name=$(LOCAL_CONTAINER))" ]; then \
		echo "$(YELLOW)Local container not running. Checking test container...$(NC)"; \
		if [ -z "$$(docker ps -q -f name=$(TEST_CONTAINER))" ]; then \
			echo "$(RED)No running containers found!$(NC)"; \
		else \
			echo "$(GREEN)Test container resource usage:$(NC)"; \
			docker stats $(TEST_CONTAINER) --no-stream; \
		fi; \
	else \
		echo "$(GREEN)Local container resource usage:$(NC)"; \
		docker stats $(LOCAL_CONTAINER) --no-stream; \
	fi

# =============================================================
# DOCKER-COMPOSE TARGETS (optional include)
# =============================================================
-include Makefile.compose

