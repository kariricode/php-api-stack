# Makefile for PHP API Stack Docker Image (Docker Hub)
# Usage: make [target]

# Variables
DOCKER_HUB_USER := dtihubmaker
IMAGE_NAME := php-api-stack
VERSION := $(shell cat VERSION)
FULL_IMAGE := $(DOCKER_HUB_USER)/$(IMAGE_NAME)

# Extract major and minor versions
MAJOR_VERSION := $(shell echo $(VERSION) | cut -d. -f1)
MINOR_VERSION := $(shell echo $(VERSION) | cut -d. -f1-2)

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

.PHONY: help
help: ## Show this help message
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

.PHONY: build
build: ## Build the Docker image locally
	@echo "$(GREEN)Building Docker image...$(NC)"
	docker build \
		--build-arg BUILDKIT_INLINE_CACHE=1 \
		--tag $(FULL_IMAGE):$(VERSION) \
		--tag $(FULL_IMAGE):latest \
		--file Dockerfile \
		.
	@echo "$(GREEN)Build complete!$(NC)"

.PHONY: build-test
build-test: ## Build the image and run a quick test
	@echo "$(GREEN)Building Docker image for testing...$(NC)"
	docker build \
		--tag $(FULL_IMAGE):test \
		--file Dockerfile \
		.
	@echo "$(GREEN)Running quick tests on the built image...$(NC)"
	docker run --rm $(FULL_IMAGE):test php -v
	docker run --rm $(FULL_IMAGE):test nginx -v
	docker run --rm $(FULL_IMAGE):test redis-server --version
	@echo "$(GREEN)Test build completed successfully!$(NC)"
	
.PHONY: logs
logs: ## Show logs from the running container
	@if [ -z "$$(docker ps -q -f name=nginx-test)" ]; then \
		echo "$(RED)No running container named nginx-test found!$(NC)"; \
		echo "Run 'make run' first to start the container."; \
	else \
		echo "$(GREEN)Showing logs for nginx-test...$(NC)"; \
		docker logs -f nginx-test; \
	fi

.PHONY: test
test: ## Run tests on the Docker image
	@echo "$(GREEN)Testing Docker image...$(NC)"
	@echo "$(YELLOW)Testing nginx configuration...$(NC)"
	docker run --rm $(FULL_IMAGE):latest nginx -t
	@echo "$(YELLOW)Testing as non-root user...$(NC)"
	@docker run --rm $(FULL_IMAGE):latest id -u | grep -qv "^0$$" && echo "$(GREEN)✓ Running as non-root$(NC)" || echo "$(RED)✗ Running as root!$(NC)"
	@echo "$(YELLOW)Testing health endpoint...$(NC)"
	@docker run -d --name test-nginx -p 8080:8080 $(FULL_IMAGE):latest > /dev/null 2>&1
	@sleep 3
	@curl -f http://localhost:8080/health > /dev/null 2>&1 && echo "$(GREEN)✓ Health check passed$(NC)" || echo "$(RED)✗ Health check failed$(NC)"
	@docker stop test-nginx > /dev/null 2>&1
	@docker rm test-nginx > /dev/null 2>&1
	@echo "$(GREEN)Tests complete!$(NC)"

.PHONY: scan
scan: ## Scan the image for vulnerabilities using Trivy
	@echo "$(GREEN)Scanning for vulnerabilities...$(NC)"
	docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy:latest image \
		--severity HIGH,CRITICAL \
		$(FULL_IMAGE):latest

.PHONY: lint
lint: ## Lint the Dockerfile with hadolint
	@echo "$(GREEN)Linting Dockerfile...$(NC)"
	docker run --rm -i hadolint/hadolint < Dockerfile

.PHONY: validate
validate: ## Validate nginx configuration
	@echo "$(GREEN)Validating nginx configuration...$(NC)"
	docker run --rm \
		-v $(PWD)/nginx.conf:/etc/nginx/nginx.conf:ro \
		-v $(PWD)/conf.d:/etc/nginx/conf.d:ro \
		nginx:alpine nginx -t

.PHONY: push
push: ## Push the image to the registry
	@echo "$(GREEN)Pushing to registry...$(NC)"
	docker push $(FULL_IMAGE):$(VERSION)
	docker push $(FULL_IMAGE):latest
	@echo "$(GREEN)Push complete!$(NC)"

.PHONY: release
release: build test scan push ## Full release process (build, test, scan, push)
	@echo "$(GREEN)Release $(VERSION) complete!$(NC)"

.PHONY: version
version: ## Display current version
	@echo "Current version: $(VERSION)"

.PHONY: bump-patch
bump-patch: ## Bump patch version (x.x.X)
	@VERSION=$$(echo $(VERSION) | awk -F. '{print $$1"."$$2"."$$3+1}'); \
	echo $$VERSION > VERSION; \
	echo "$(GREEN)Version bumped to $$VERSION$(NC)"

.PHONY: bump-minor
bump-minor: ## Bump minor version (x.X.x)
	@VERSION=$$(echo $(VERSION) | awk -F. '{print $$1"."$$2+1".0"}'); \
	echo $$VERSION > VERSION; \
	echo "$(GREEN)Version bumped to $$VERSION$(NC)"

.PHONY: bump-major
bump-major: ## Bump major version (X.x.x)
	@VERSION=$$(echo $(VERSION) | awk -F. '{print $$1+1".0.0"}'); \
	echo $$VERSION > VERSION; \
	echo "$(GREEN)Version bumped to $$VERSION$(NC)"

.PHONY: run
run: ## Run the container locally for testing
	@echo "$(GREEN)Starting container...$(NC)"
	docker run -d \
		--name nginx-test \
		-p 8080:8080 \
		-v $(PWD)/test-app:/var/www/html:ro \
		$(FULL_IMAGE):latest
	@echo "$(GREEN)Container running at http://localhost:8080$(NC)"
	@echo "Use 'make stop' to stop the container"

.PHONY: stop
stop: ## Stop and remove the test container
	@echo "$(YELLOW)Stopping container...$(NC)"
	@docker stop nginx-test 2>/dev/null || true
	@docker rm nginx-test 2>/dev/null || true
	@echo "$(GREEN)Container stopped$(NC)"

.PHONY: shell
shell: ## Open a shell in the running container
	docker exec -it nginx-test sh

.PHONY: clean
clean: ## Remove local images and containers
	@echo "$(YELLOW)Cleaning up...$(NC)"
	@docker stop nginx-test 2>/dev/null || true
	@docker rm nginx-test 2>/dev/null || true
	@docker rmi $(FULL_IMAGE):$(VERSION) 2>/dev/null || true
	@docker rmi $(FULL_IMAGE):latest 2>/dev/null || true
	@echo "$(GREEN)Cleanup complete$(NC)"

.PHONY: info
info: ## Show image information
	@echo "$(GREEN)Image Information:$(NC)"
	@echo "  Registry: $(REGISTRY)"
	@echo "  Namespace: $(NAMESPACE)"
	@echo "  Image: $(IMAGE_NAME)"
	@echo "  Version: $(VERSION)"
	@echo "  Full path: $(FULL_IMAGE):$(VERSION)"
	@echo ""
	@echo "$(GREEN)Image size:$(NC)"
	@docker images $(FULL_IMAGE) --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"

.DEFAULT_GOAL := help