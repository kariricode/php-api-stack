# Makefile for PHP API Stack Docker Image
# Usage: make [target]

# Variables
DOCKER_HUB_USER := kariricode
IMAGE_NAME := php-api-stack
VERSION := $(shell cat VERSION 2>/dev/null || echo "1.1.0")
FULL_IMAGE := $(DOCKER_HUB_USER)/$(IMAGE_NAME)

# Extract major and minor versions
MAJOR_VERSION := $(shell echo $(VERSION) | cut -d. -f1)
MINOR_VERSION := $(shell echo $(VERSION) | cut -d. -f1-2)

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
CYAN := \033[0;36m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@echo "$(GREEN)PHP API Stack - Docker Build System$(NC)"
	@echo "$(CYAN)Version: $(VERSION)$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-18s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Examples:$(NC)"
	@echo "  make build         # Build image locally"
	@echo "  make test-quick    # Quick test after build"
	@echo "  make release       # Full release pipeline"

.PHONY: build
build: ## Build the Docker image locally
	@echo "$(GREEN)Building Docker image...$(NC)"
	@echo "Image: $(FULL_IMAGE):$(VERSION)"
	./build-from-env.sh  --version=$(VERSION)
	@echo "$(GREEN)✓ Build complete!$(NC)"

.PHONY: build-no-cache
build-no-cache: ## Build without using cache
	@echo "$(GREEN)Building Docker image (no cache)...$(NC)"
	./build-from-env.sh --no-cache --version=$(VERSION)
	@echo "$(GREEN)✓ Build complete!$(NC)"

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

.PHONY: build-test
build-test: build test-quick ## Build and run quick tests

.PHONY: test
test: ## Run comprehensive tests on the Docker image
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
	@docker run -d --name test-health -p 18080:80 $(FULL_IMAGE):latest > /dev/null 2>&1
	@sleep 5
	@curl -sf http://localhost:18080/health > /dev/null && echo "$(GREEN)✓ Health check passed$(NC)" || echo "$(RED)✗ Health check failed$(NC)"
	@docker stop test-health > /dev/null 2>&1
	@docker rm test-health > /dev/null 2>&1
	@echo ""
	@echo "$(GREEN)✓ All tests complete!$(NC)"

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
		hadolint Dockerfile; \
	else \
		docker run --rm -i hadolint/hadolint < Dockerfile; \
	fi

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
	@echo "$(GREEN)✅ Release $(VERSION) complete!$(NC)"

.PHONY: version
version: ## Display current version
	@echo "Current version: $(VERSION)"
	@echo "Docker image: $(FULL_IMAGE):$(VERSION)"

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

.PHONY: run
run: ## Run the container locally for testing
	@echo "$(GREEN)Starting container...$(NC)"
	@docker run -d \
		--name php-api-test \
		-p 8080:80 \
		-v $(PWD)/test-app:/var/www/html \
		$(FULL_IMAGE):latest
	@echo "$(GREEN)✓ Container running at http://localhost:8080$(NC)"
	@echo "Container name: php-api-test"
	@echo "Use 'make stop' to stop the container"
	@echo "Use 'make logs' to view logs"

.PHONY: stop
stop: ## Stop and remove the test container
	@echo "$(YELLOW)Stopping container...$(NC)"
	@docker stop php-api-test 2>/dev/null || true
	@docker rm php-api-test 2>/dev/null || true
	@echo "$(GREEN)✓ Container stopped$(NC)"

.PHONY: restart
restart: stop run ## Restart the test container

.PHONY: logs
logs: ## Show logs from the running container
	@if [ -z "$$(docker ps -q -f name=php-api-test)" ]; then \
		echo "$(RED)No running container named php-api-test found!$(NC)"; \
		echo "Run 'make run' first to start the container."; \
	else \
		echo "$(GREEN)Showing logs for php-api-test...$(NC)"; \
		docker logs -f php-api-test; \
	fi

.PHONY: exec
exec: ## Execute bash in the running container
	@if [ -z "$$(docker ps -q -f name=php-api-test)" ]; then \
		echo "$(RED)No running container found!$(NC)"; \
		echo "Run 'make run' first."; \
	else \
		docker exec -it php-api-test bash; \
	fi

.PHONY: shell
shell: exec ## Alias for exec

.PHONY: clean
clean: ## Remove local images and containers
	@echo "$(YELLOW)Cleaning up...$(NC)"
	@docker stop php-api-test 2>/dev/null || true
	@docker rm php-api-test 2>/dev/null || true
	@docker rmi $(FULL_IMAGE):$(VERSION) 2>/dev/null || true
	@docker rmi $(FULL_IMAGE):latest 2>/dev/null || true
	@docker rmi $(FULL_IMAGE):test 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

.PHONY: clean-all
clean-all: clean ## Deep clean including volumes and build cache
	@echo "$(YELLOW)Deep cleaning...$(NC)"
	@docker volume prune -f 2>/dev/null || true
	@docker builder prune -f 2>/dev/null || true
	@echo "$(GREEN)✓ Deep cleanup complete$(NC)"

.PHONY: info
info: ## Show image information
	@echo "$(CYAN)════════════════════════════════════════$(NC)"
	@echo "$(GREEN)PHP API Stack - Image Information$(NC)"
	@echo "$(CYAN)════════════════════════════════════════$(NC)"
	@echo "  Hub User:    $(DOCKER_HUB_USER)"
	@echo "  Image:       $(IMAGE_NAME)"
	@echo "  Version:     $(VERSION)"
	@echo "  Full path:   $(FULL_IMAGE):$(VERSION)"
	@echo ""
	@echo "$(GREEN)Available tags:$(NC)"
	@echo "  - $(FULL_IMAGE):$(VERSION)"
	@echo "  - $(FULL_IMAGE):$(MAJOR_VERSION)"
	@echo "  - $(FULL_IMAGE):$(MINOR_VERSION)"
	@echo "  - $(FULL_IMAGE):latest"
	@echo ""
	@if docker images $(FULL_IMAGE) --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep -q $(IMAGE_NAME); then \
		echo "$(GREEN)Local images:$(NC)"; \
		docker images $(FULL_IMAGE) --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"; \
	else \
		echo "$(YELLOW)No local images found. Run 'make build' to create one.$(NC)"; \
	fi

.PHONY: stats
stats: ## Show container resource usage
	@if [ -z "$$(docker ps -q -f name=php-api-test)" ]; then \
		echo "$(RED)No running container found!$(NC)"; \
	else \
		echo "$(GREEN)Container resource usage:$(NC)"; \
		docker stats php-api-test --no-stream; \
	fi

# Alias targets
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