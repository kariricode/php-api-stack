# Makefile for PHP API Stack Docker Image
# Usage: make [target]

# Variables
DOCKER_HUB_USER := kariricode
IMAGE_NAME := php-api-stack
VERSION := $(shell cat VERSION 2>/dev/null || echo "1.2.0")
FULL_IMAGE := $(DOCKER_HUB_USER)/$(IMAGE_NAME)

# Container names (derived from IMAGE_NAME)
LOCAL_CONTAINER := $(IMAGE_NAME)-local
TEST_CONTAINER := $(IMAGE_NAME)-test

# Extract major and minor versions
MAJOR_VERSION := $(shell echo $(VERSION) | cut -d. -f1)
MINOR_VERSION := $(shell echo $(VERSION) | cut -d. -f1-2)

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
CYAN := \033[0;36m
MAGENTA := \033[0;35m
NC := \033[0m

# Default target
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@echo "$(GREEN)╔══════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║       PHP API Stack - Docker Build System           ║$(NC)"
	@echo "$(GREEN)╚══════════════════════════════════════════════════════╝$(NC)"
	@echo "$(CYAN)Version: $(VERSION)$(NC)"
	@echo ""
	@echo "$(MAGENTA)═══ BUILD TARGETS ═══$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v "^#" | awk 'BEGIN {FS = ":.*?## "}; /^build/ || /^scan/ || /^lint/ {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(MAGENTA)═══ TEST TARGETS ═══$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v "^#" | awk 'BEGIN {FS = ":.*?## "}; /^test/ || /run-test/ || /stop-test/ || /logs-test/ || /shell-test/ {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(MAGENTA)═══ RUNTIME TARGETS ═══$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v "^#" | awk 'BEGIN {FS = ":.*?## "}; /^run/ || /^stop$$/ || /^restart/ || /^logs$$/ || /^exec/ || /^shell$$/ {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(MAGENTA)═══ UTILITY TARGETS ═══$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v "^#" | awk 'BEGIN {FS = ":.*?## "}; /version/ || /bump/ || /push/ || /release/ || /clean/ || /info/ || /stats/ {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Quick Start Examples:$(NC)"
	@echo "  $(CYAN)make build$(NC)              # Build production image"
	@echo "  $(CYAN)make run$(NC)                # Run local container"
	@echo "  $(CYAN)make run-test$(NC)           # Run test container with health check"
	@echo "  $(CYAN)make release$(NC)            # Full release pipeline"

# ============================================================================
# BUILD TARGETS
# ============================================================================

.PHONY: build
build: ## Build the Docker image locally (production)
	@echo "$(GREEN)Building production Docker image...$(NC)"
	@echo "Image: $(FULL_IMAGE):$(VERSION)"
	./build-from-env.sh --version=$(VERSION)
	@echo "$(GREEN)✓ Production build complete!$(NC)"

.PHONY: build-no-cache
build-no-cache: ## Build without using cache
	@echo "$(GREEN)Building Docker image (no cache)...$(NC)"
	./build-from-env.sh --no-cache --version=$(VERSION)
	@echo "$(GREEN)✓ Build complete!$(NC)"

.PHONY: build-test-image
build-test-image: ## Build test image with comprehensive health check
	@echo "$(GREEN)Building test image with comprehensive health check...$(NC)"
	@if [ ! -f health.php ]; then \
		echo "$(RED)Error: health.php not found!$(NC)"; \
		echo "Please ensure health.php is in the project root."; \
		exit 1; \
	fi
	./build-from-env.sh --test --version=$(VERSION)
	@echo "$(GREEN)✓ Test image built successfully!$(NC)"
	@echo "$(CYAN)Image:$(NC) $(FULL_IMAGE):test"

# ============================================================================
# TEST TARGETS
# ============================================================================

.PHONY: test-quick
test-quick: ## Quick test of built image (versions only)
	@echo "$(GREEN)Running quick version tests...$(NC)"
	@echo ""
	@echo "$(CYAN)Testing PHP:$(NC)"
	@docker run --rm --entrypoint php $(FULL_IMAGE):latest -v | head -2
	@echo ""
	@echo "$(CYAN)Testing Nginx:$(NC)"
	@docker run --rm --entrypoint nginx $(FULL_IMAGE):latest -v 2>&1 | head -1
	@echo ""
	@echo "$(CYAN)Testing Redis:$(NC)"
	@docker run --rm --entrypoint redis-server $(FULL_IMAGE):latest --version
	@echo ""
	@echo "$(CYAN)Testing Composer:$(NC)"
	@docker run --rm --entrypoint composer $(FULL_IMAGE):latest --version --no-ansi | head -1
	@echo ""
	@echo "$(GREEN)✓ All components verified!$(NC)"

.PHONY: test
test: ## Run comprehensive tests on production image
	@echo "$(GREEN)Running comprehensive tests...$(NC)"
	@echo ""
	@echo "$(YELLOW)[1/5] Testing component versions...$(NC)"
	@make test-quick --no-print-directory
	@echo ""
	@echo "$(YELLOW)[2/5] Testing configuration processing...$(NC)"
	@docker run --rm $(FULL_IMAGE):latest /usr/local/bin/process-configs
	@echo ""
	@echo "$(YELLOW)[3/5] Testing Nginx configuration...$(NC)"
	@docker run --rm --entrypoint nginx $(FULL_IMAGE):latest -t
	@echo ""
	@echo "$(YELLOW)[4/5] Testing PHP-FPM configuration...$(NC)"
	@docker run --rm --entrypoint php-fpm $(FULL_IMAGE):latest -t
	@echo ""
	@echo "$(YELLOW)[5/5] Testing health endpoint...$(NC)"
	@docker run -d --name test-health -p 18080:80 $(FULL_IMAGE):latest >/dev/null 2>&1
	@sleep 5
	@curl -sf http://localhost:18080/health >/dev/null && echo "$(GREEN)✓ Health check passed$(NC)" || echo "$(RED)✗ Health check failed$(NC)"
	@docker stop test-health >/dev/null 2>&1
	@docker rm test-health >/dev/null 2>&1
	@echo ""
	@echo "$(GREEN)✓ All tests complete!$(NC)"

.PHONY: run-test
run-test: ## run test container with comprehensive health check
	@echo "$(GREEN)Starting test container...$(NC)"
	@docker stop $(TEST_CONTAINER) 2>/dev/null >/dev/null || true
	@docker rm $(TEST_CONTAINER) 2>/dev/null >/dev/null || true
	@docker run -d \
		--name $(TEST_CONTAINER) \
		-p 8080:80 \
		-v $(PWD)/logs:/var/log \
		$(FULL_IMAGE):test
	@echo ""
	@echo "$(GREEN)✓ Test container running!$(NC)"
	@echo "$(CYAN)════════════════════════════════════════$(NC)"
	@echo "$(CYAN)Container:$(NC)    $(TEST_CONTAINER)"
	@echo "$(CYAN)URL:$(NC)          http://localhost:8080"
	@echo "$(CYAN)Health Check:$(NC) http://localhost:8080/health.php"
	@echo "$(CYAN)════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)⏳ Waiting for services to start...$(NC)"
	@sleep 5
	@echo ""
	@echo "$(CYAN)Testing comprehensive health endpoint...$(NC)"
	@if curl -s http://localhost:8080/health.php | jq -e '.status == "healthy"' >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Health check: HEALTHY$(NC)"; \
		curl -s http://localhost:8080/health.php | jq -r '"Duration: \(.duration_ms)ms"'; \
		echo ""; \
		echo "$(CYAN)Available checks:$(NC)"; \
		curl -s http://localhost:8080/health.php | jq -r '.checks | keys[]' | sed 's/^/  - /'; \
	else \
		echo "$(YELLOW)⚠ jq not installed or health check failed$(NC)"; \
		curl -s http://localhost:8080/health.php; \
	fi
	@echo ""
	@echo "$(BLUE)Useful commands:$(NC)"
	@echo "  $(CYAN)make test-health$(NC)       # Test health endpoint"
	@echo "  $(CYAN)make test-health-watch$(NC) # Watch health status"
	@echo "  $(CYAN)make logs-test$(NC)         # View logs"
	@echo "  $(CYAN)make shell-test$(NC)        # Access shell"
	@echo "  $(CYAN)make stop-test$(NC)         # Stop container"

.PHONY: test-health
test-health: ## Test comprehensive health check endpoint
	@echo "$(GREEN)Testing comprehensive health check...$(NC)"
	@if [ -z "$$(docker ps -q -f name=$(TEST_CONTAINER))" ]; then \
		echo "$(RED)Test container not running!$(NC)"; \
		echo "Run '$(CYAN)make run-test$(NC)' first."; \
		exit 1; \
	fi
	@echo ""
	@curl -s http://localhost:8080/health.php | jq '.' || curl -s http://localhost:8080/health.php

.PHONY: test-health-status
test-health-status: ## Show health check status summary
	@if [ -z "$$(docker ps -q -f name=$(TEST_CONTAINER))" ]; then \
		echo "$(RED)Test container not running!$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Health Check Status Summary$(NC)"
	@echo "$(CYAN)════════════════════════════════════════$(NC)"
	@curl -s http://localhost:8080/health.php | jq -r '"Overall: \(.status | ascii_upcase)"'
	@curl -s http://localhost:8080/health.php | jq -r '"Duration: \(.duration_ms)ms"'
	@echo ""
	@echo "$(CYAN)Component Status:$(NC)"
	@curl -s http://localhost:8080/health.php | jq -r '.checks | to_entries[] | "  \(.key | ascii_upcase): \(.value.status)"'

.PHONY: test-health-watch
test-health-watch: ## Watch health check status (updates every 5s)
	@if [ -z "$$(docker ps -q -f name=$(TEST_CONTAINER))" ]; then \
		echo "$(RED)Test container not running!$(NC)"; \
		echo "Run '$(CYAN)make run-test$(NC)' first."; \
		exit 1; \
	fi
	@echo "$(GREEN)Watching health status (Ctrl+C to stop)...$(NC)"
	@echo ""
	@watch -n 5 'curl -s http://localhost:8080/health.php | jq ".status, .duration_ms, .checks | to_entries[] | {name: .key, healthy: .value.healthy, status: .value.status}"'

.PHONY: stop-test
stop-test: ## Stop and remove test container
	@echo "$(YELLOW)Stopping test container...$(NC)"
	@docker stop $(TEST_CONTAINER) 2>/dev/null >/dev/null || true
	@docker rm $(TEST_CONTAINER) 2>/dev/null >/dev/null || true
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

# ============================================================================
# VALIDATION TARGETS
# ============================================================================

.PHONY: test-structure
test-structure: ## Test container structure and files
	@echo "$(GREEN)Testing container structure...$(NC)"
	@docker run --rm $(FULL_IMAGE):latest ls -la /var/www/html/public/
	@docker run --rm $(FULL_IMAGE):latest ls -la /etc/nginx/
	@docker run --rm $(FULL_IMAGE):latest ls -la /usr/local/etc/php/

.PHONY: scan
scan: ## Scan the image for vulnerabilities using Trivy
	@echo "$(GREEN)Scanning for vulnerabilities...$(NC)"
	@if command -v trivy >/dev/null 2>&1; then \
		trivy image --severity HIGH,CRITICAL $(FULL_IMAGE):latest; \
	else \
		docker run --rm \
			-v /var/run/docker.sock:/var/run/docker.sock \
			aquasec/trivy:latest image \
			--severity HIGH,CRITICAL \
			$(FULL_IMAGE):latest; \
	fi

.PHONY: lint
lint: ## Lint the Dockerfile with hadolint
	@echo "$(GREEN)Linting Dockerfile...$(NC)"
	@if command -v hadolint >/dev/null 2>&1; then \
		hadolint Dockerfile || true; \
	else \
		docker run --rm -i hadolint/hadolint < Dockerfile || true; \
	fi

# ============================================================================
# RUNTIME TARGETS
# ============================================================================

.PHONY: run
run: ## Run local container for demo/testing
	@echo "$(GREEN)Starting local container...$(NC)"
	@docker stop $(LOCAL_CONTAINER) 2>/dev/null >/dev/null || true
	@docker rm $(LOCAL_CONTAINER) 2>/dev/null >/dev/null || true
	@docker run -d \
		--name $(LOCAL_CONTAINER) \
		-p 8080:80 \
		-v $(PWD)/logs:/var/log \
		$(FULL_IMAGE):latest
	@echo "$(GREEN)✓ Container running at http://localhost:8080$(NC)"
	@echo "$(CYAN)Container name:$(NC) $(LOCAL_CONTAINER)"
	@echo ""
	@echo "$(YELLOW)⏳ Waiting for services to start...$(NC)"
	@sleep 5
	@echo ""
	@echo "$(CYAN)Testing demo page...$(NC)"
	@if curl -s http://localhost:8080 | grep -q "PHP API Stack"; then \
		echo "$(GREEN)✓ Demo page is live!$(NC)"; \
		echo "$(CYAN)Visit:$(NC) http://localhost:8080"; \
	else \
		echo "$(YELLOW)⚠ Page loaded but demo not detected$(NC)"; \
	fi
	@echo ""
	@echo "$(BLUE)Useful commands:$(NC)"
	@echo "  $(CYAN)make stop$(NC)          # Stop container"
	@echo "  $(CYAN)make logs$(NC)          # View logs"
	@echo "  $(CYAN)make shell$(NC)         # Access shell"
	@echo "  $(CYAN)make run-with-app$(NC)  # Run with app mounted"

.PHONY: run-with-app
run-with-app: ## Run local container with mounted application
	@echo "$(GREEN)Starting local container with application mount...$(NC)"
	@docker stop $(LOCAL_CONTAINER) 2>/dev/null >/dev/null || true
	@docker rm $(LOCAL_CONTAINER) 2>/dev/null >/dev/null || true
	@if [ ! -d "$(PWD)/app" ]; then \
		echo "$(YELLOW)Creating app directory...$(NC)"; \
		mkdir -p $(PWD)/app/public; \
	fi
	@docker run -d \
		--name $(LOCAL_CONTAINER) \
		-p 8080:80 \
		-v $(PWD)/app:/var/www/html \
		-v $(PWD)/logs:/var/log \
		$(FULL_IMAGE):latest
	@echo "$(GREEN)✓ Container running at http://localhost:8080$(NC)"
	@echo "$(CYAN)Application mounted from:$(NC) $(PWD)/app"
	@echo ""
	@echo "$(BLUE)Next steps:$(NC)"
	@echo "  1. Create your $(CYAN)app/public/index.php$(NC)"
	@echo "  2. Run $(CYAN)docker exec $(LOCAL_CONTAINER) supervisorctl restart nginx$(NC)"
	@echo "  3. Visit http://localhost:8080"

.PHONY: stop
stop: ## Stop and remove local container
	@echo "$(YELLOW)Stopping local container...$(NC)"
	@docker stop $(LOCAL_CONTAINER) 2>/dev/null >/dev/null || true
	@docker rm $(LOCAL_CONTAINER) 2>/dev/null >/dev/null || true
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

# ============================================================================
# RELEASE TARGETS
# ============================================================================

.PHONY: push
push: ## Push the image to Docker Hub
	@echo "$(GREEN)Pushing to Docker Hub...$(NC)"
	@echo "Pushing $(FULL_IMAGE):$(VERSION)..."
	@docker push $(FULL_IMAGE):$(VERSION)
	@docker push $(FULL_IMAGE):latest
	@docker push $(FULL_IMAGE):$(MAJOR_VERSION)
	@docker push $(FULL_IMAGE):$(MINOR_VERSION)
	@echo "$(GREEN)✓ Push complete!$(NC)"
	@echo "Available at: https://hub.docker.com/r/$(FULL_IMAGE)"

.PHONY: release
release: lint build test scan push ## Full release pipeline
	@echo "$(GREEN)════════════════════════════════════════$(NC)"
	@echo "$(GREEN)✅ Release $(VERSION) complete!$(NC)"
	@echo "$(GREEN)════════════════════════════════════════$(NC)"

# ============================================================================
# VERSION MANAGEMENT
# ============================================================================

.PHONY: version
version: ## Display current version
	@echo "$(CYAN)Current version:$(NC) $(VERSION)"
	@echo "$(CYAN)Docker image:$(NC)    $(FULL_IMAGE):$(VERSION)"

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

# ============================================================================
# CLEANUP TARGETS
# ============================================================================

.PHONY: clean
clean: ## Remove local images and containers
	@echo "$(YELLOW)Cleaning up...$(NC)"
	@docker stop $(LOCAL_CONTAINER) $(TEST_CONTAINER) 2>/dev/null >/dev/null || true
	@docker rm $(LOCAL_CONTAINER) $(TEST_CONTAINER) 2>/dev/null >/dev/null || true
	@docker rmi $(FULL_IMAGE):$(VERSION) 2>/dev/null >/dev/null || true
	@docker rmi $(FULL_IMAGE):latest 2>/dev/null >/dev/null || true
	@docker rmi $(FULL_IMAGE):test 2>/dev/null >/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

.PHONY: clean-all
clean-all: clean ## Deep clean including volumes and build cache
	@echo "$(YELLOW)Deep cleaning...$(NC)"
	@docker volume prune -f 2>/dev/null || true
	@docker builder prune -f 2>/dev/null || true
	@echo "$(GREEN)✓ Deep cleanup complete$(NC)"

# ============================================================================
# INFORMATION TARGETS
# ============================================================================

.PHONY: info
info: ## Show image information
	@echo "$(CYAN)════════════════════════════════════════$(NC)"
	@echo "$(GREEN)PHP API Stack - Image Information$(NC)"
	@echo "$(CYAN)════════════════════════════════════════$(NC)"
	@echo "  $(CYAN)Hub User:$(NC)    $(DOCKER_HUB_USER)"
	@echo "  $(CYAN)Image:$(NC)       $(IMAGE_NAME)"
	@echo "  $(CYAN)Version:$(NC)     $(VERSION)"
	@echo "  $(CYAN)Full path:$(NC)   $(FULL_IMAGE):$(VERSION)"
	@echo ""
	@echo "$(GREEN)Container names:$(NC)"
	@echo "  $(CYAN)Local:$(NC)       $(LOCAL_CONTAINER)"
	@echo "  $(CYAN)Test:$(NC)        $(TEST_CONTAINER)"
	@echo ""
	@echo "$(GREEN)Available tags:$(NC)"
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

# ============================================================================
# ALIAS TARGETS
# ============================================================================

.PHONY: b
b: build ## Alias for build

.PHONY: t
t: test ## Alias for test

.PHONY: r
r: run ## Alias for run

.PHONY: s
s: stop ## Alias for stop

.PHONY: l
l: logs ## Alias for logs