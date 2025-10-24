# Makefile for PHP API Stack Docker Image
# Usage: make [target]

# =============================================================
# VARIABLES
# =============================================================
DOCKER_HUB_USER := kariricode
IMAGE_NAME      := php-api-stack
VERSION         := $(shell cat VERSION 2>/dev/null || echo "1.2.0")
FULL_IMAGE      := $(DOCKER_HUB_USER)/$(IMAGE_NAME)

ENV_FILE ?= .env
ifneq ("$(wildcard $(ENV_FILE))","")
	include $(ENV_FILE)
	export $(shell sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' $(ENV_FILE))
endif

# Container names
LOCAL_CONTAINER := $(IMAGE_NAME)-local
DEV_CONTAINER := $(IMAGE_NAME)-dev
TEST_CONTAINER  := $(IMAGE_NAME)-test
CI_TEST_CONTAINER := $(IMAGE_NAME)-ci-test

# Ports (can be overridden: e.g., make run LOCAL_PORT=8000)
LOCAL_PORT ?= 8080
DEV_PORT   ?= 8001
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

DEMO_MODE ?= false
HEALTH_CHECK_INSTALL ?= false

# Common build args block
BUILD_ARGS := \
	--build-arg DEMO_MODE=$(DEMO_MODE) \
	--build-arg HEALTH_CHECK_INSTALL=$(HEALTH_CHECK_INSTALL) \
	--build-arg VERSION=$(VERSION) \
	--build-arg PHP_VERSION=$(PHP_VERSION) \
	--build-arg PHP_CORE_EXTENSIONS=$(PHP_CORE_EXTENSIONS) \
	--build-arg PHP_PECL_EXTENSIONS=$(PHP_PECL_EXTENSIONS) \
	--build-arg NGINX_VERSION=$(NGINX_VERSION) \
	--build-arg REDIS_VERSION=$(REDIS_VERSION) \
	--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
	--build-arg COMPOSER_VERSION=$(COMPOSER_VERSION) \
	--build-arg PHP_REDIS_VERSION=$(PHP_REDIS_VERSION) \
	--build-arg PHP_APCU_VERSION=$(PHP_APCU_VERSION) \
	--build-arg PHP_UUID_VERSION=$(PHP_UUID_VERSION) \
	--build-arg PHP_IMAGICK_VERSION=$(PHP_IMAGICK_VERSION) \
	--build-arg PHP_AMQP_VERSION=$(PHP_AMQP_VERSION) \
	--build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
	--build-arg VCS_REF=$(git rev-parse --short=12 HEAD 2>/dev/null || echo unknown)

# Production build args
PROD_BUILD_ARGS := \
	--build-arg APP_ENV=production \
	--build-arg PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
	--build-arg PHP_OPCACHE_MAX_ACCELERATED_FILES=20000 \
	--build-arg PHP_OPCACHE_ENABLE=1 \
	--build-arg PHP_OPCACHE_MEMORY_CONSUMPTION=256 \
	--build-arg XDEBUG_ENABLE=0 \
	--build-arg APP_DEBUG=false \
	--build-arg DEMO_MODE=false \
	--build-arg HEALTH_CHECK_INSTALL=false


# Development build args
IMAGE_TAG ?= dev
XDEBUG_ENABLE ?= 1
XDEBUG_VERSION ?= 3.4.6

DEV_BUILD_ARGS := \
	--build-arg APP_ENV=development \
	--build-arg APP_DEBUG=true \
	--build-arg DEMO_MODE=true \
	--build-arg SYMFONY_CLI_VERSION=$(SYMFONY_CLI_VERSION) \
	--build-arg XDEBUG_VERSION=$(XDEBUG_VERSION) \
	--build-arg HEALTH_CHECK_INSTALL=true \
	--build-arg XDEBUG_ENABLE=$(XDEBUG_ENABLE)

.PHONY: help
help: ## Show this help message
	@echo "$(GREEN)╔═══════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║      PHP API Stack - Docker Build System        ║$(NC)"
	@echo "$(GREEN)╚═══════════════════════════════════════════════════╝$(NC)"
	@echo "$(CYAN)Version: $(VERSION)$(NC)"
	@echo "$(CYAN)Architecture: Base → Production | Dev$(NC)"
	@echo ""
	@echo "$(MAGENTA)━━━ BUILD TARGETS ━━━$(NC)"
	@grep -hE '^build.*:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  $(YELLOW)%-22s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(MAGENTA)━━━ TEST TARGETS ━━━$(NC)"
	@grep -hE '^test.*:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  $(YELLOW)%-22s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(MAGENTA)━━━ RUNTIME TARGETS ━━━$(NC)"
	@grep -hE '^(run|stop|restart|logs|shell).*:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  $(YELLOW)%-22s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(MAGENTA)━━━ DOCKER HUB TARGETS ━━━$(NC)"
	@grep -hE '^(push|release|publish|tag|hub|docker-).*:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  $(YELLOW)%-22s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(MAGENTA)━━━ UTILITY TARGETS ━━━$(NC)"
	@grep -hE '^(version|bump|clean|info|lint|scan).*:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  $(YELLOW)%-22s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Quick Start Examples:$(NC)"
	@echo "  $(CYAN)make build$(NC)              # Build production image"
	@echo "  $(CYAN)make build-dev$(NC)          # Build dev image with Xdebug"
	@echo "  $(CYAN)make test$(NC)               # Run comprehensive tests"
	@echo "  $(CYAN)make release-production$(NC) # Full production release pipeline"
	@echo "  $(CYAN)make publish-dev$(NC)        # Build + push dev image"
	@echo "  $(CYAN)make run$(NC)                 # Run production container"
	@echo "  $(CYAN)make run-dev$(NC)            # Run dev container"
	@echo ""
	@echo "$(YELLOW)For Docker Hub commands:$(NC) $(CYAN)make hub-help$(NC)"
	@echo "$(YELLOW)For Docker Hub commands:$(NC) $(CYAN)make compose-help$(NC)"

# =============================================================
# BUILD TARGETS
# =============================================================
.PHONY: build
build: ## Build production image (target=production)
	@echo "$(GREEN)Building production Docker image...$(NC)"
	@if [ $(HAVE_BUILD_SCRIPT) -eq 1 ]; then \
		$(BUILD_SCRIPT) --version=$(VERSION); \
	else \
		docker build --no-cache \
			$(BUILD_ARGS) \
			$(PROD_BUILD_ARGS) \
			--target production \
			-t $(FULL_IMAGE):$(VERSION) \
			-t $(FULL_IMAGE):latest \
			-t $(FULL_IMAGE):$(MAJOR_VERSION) \
			-t $(FULL_IMAGE):$(MINOR_VERSION) \
			$(BUILD_CONTEXT); \
	fi
	@echo "$(GREEN)OK: Production build complete!$(NC)"

.PHONY: build-dev
build-dev: ## Build development image (target=dev)
	@echo "$(GREEN)Building development Docker image...$(NC)"
	@docker build \
		--no-cache \
		$(BUILD_ARGS) \
		$(DEV_BUILD_ARGS) \
		--target dev \
		--tag $(FULL_IMAGE):$(IMAGE_TAG) \
		--tag $(FULL_IMAGE):dev \
		.
	@echo "$(GREEN)OK: Dev image built as $(FULL_IMAGE):$(IMAGE_TAG)$(NC)"

.PHONY: build-base
build-base: ## Build base image (target=base) - for debugging only
	@echo "$(GREEN)Building base Docker image...$(NC)"
	@docker build \
		--no-cache \
		$(BUILD_ARGS) \
		--target base \
		--tag $(FULL_IMAGE):base \
		.
	@echo "$(GREEN)OK: Base image built as $(FULL_IMAGE):base$(NC)"

.PHONY: build-test
build-test: ## Build test image (production with health check)
	@echo "$(GREEN)Building test image with comprehensive health check...$(NC)"
	@docker build \
		$(BUILD_ARGS) \
		$(PROD_BUILD_ARGS) \
		--build-arg HEALTH_CHECK_INSTALL=true \
		--target production \
		-t $(FULL_IMAGE):test \
		.
	@echo "$(GREEN)OK: Test image built: $(FULL_IMAGE):test$(NC)"

.PHONY: build-all
build-all: build build-dev ## Build both production and dev images
	@echo "$(GREEN)OK: All images built successfully!$(NC)"

# =============================================================
# PUSH & PUBLISH TARGETS (moved to Makefile.dockerhub)
# =============================================================
# Use: make push-production, make push-dev, make publish-all
# See: make hub-help for all Docker Hub commands

# =============================================================
# RUNTIME TARGETS - RUN
# =============================================================
.PHONY: run
run: ## Run production container
	@echo "$(GREEN)Starting production container...$(NC)"
	@docker stop $(LOCAL_CONTAINER) >/dev/null 2>&1 || true
	@docker rm $(LOCAL_CONTAINER) >/dev/null 2>&1 || true
	@docker run -d \
		--name $(LOCAL_CONTAINER) \
		-p $(LOCAL_PORT):80 \
		--env-file $(ENV_FILE) \
		-e APP_ENV=production \
		-v $(PWD)/logs:/var/log \
		$(FULL_IMAGE):latest
	@echo "$(GREEN)OK: Production container running at http://localhost:$(LOCAL_PORT)$(NC)"
	@echo "$(CYAN)Container name:$(NC) $(LOCAL_CONTAINER)"

.PHONY: run-dev
run-dev: ## Run dev container with Xdebug
	@echo "$(GREEN)Starting dev container...$(NC)"
	@docker stop $(DEV_CONTAINER) >/dev/null 2>&1 || true
	@docker rm $(DEV_CONTAINER) >/dev/null 2>&1 || true
	@if docker ps --format '{{.Ports}}' | grep -q '$(DEV_PORT)->'; then \
		echo "$(RED)X Port $(DEV_PORT) is already in use!$(NC)"; \
		echo "$(YELLOW)Try another port:$(NC) make run-dev DEV_PORT=9000"; \
		exit 1; \
	fi
	@docker run -d \
		--name $(DEV_CONTAINER) \
		-p $(DEV_PORT):80 \
		-p 9003:9003 \
		--env-file $(ENV_FILE) \
		-e APP_ENV=development \
		-e XDEBUG_ENABLE=1 \
		-v $(PWD)/logs:/var/log \
		$(FULL_IMAGE):$(IMAGE_TAG)
	@echo "$(GREEN)OK: Dev container running at http://localhost:$(DEV_PORT)$(NC)"
	@echo "$(CYAN)Xdebug enabled on port 9003$(NC)"

.PHONY: run-test
run-test: build-test ## Run test container
	@echo "$(GREEN)Starting test container...$(NC)"
	@docker stop $(TEST_CONTAINER) >/dev/null 2>&1 || true
	@docker rm $(TEST_CONTAINER) >/dev/null 2>&1 || true
	@docker run -d \
		--name $(TEST_CONTAINER) \
		-p $(TEST_PORT):80 \
		--env-file $(ENV_FILE) \
		-v $(PWD)/logs:/var/log \
		$(FULL_IMAGE):test
	@echo "$(GREEN)OK: Test container running at http://localhost:$(TEST_PORT)/health$(NC)"

# =============================================================
# RUNTIME TARGETS - STOP & RESTART
# =============================================================
.PHONY: stop
stop: ## Stop production container
	@echo "$(YELLOW)Stopping production container...$(NC)"
	@docker stop $(LOCAL_CONTAINER) >/dev/null 2>&1 || true
	@docker rm $(LOCAL_CONTAINER) >/dev/null 2>&1 || true
	@echo "$(GREEN)OK: Container stopped$(NC)"

.PHONY: stop-dev
stop-dev: ## Stop dev container
	@echo "$(YELLOW)Stopping dev container...$(NC)"
	@docker stop $(DEV_CONTAINER) >/dev/null 2>&1 || true
	@docker rm $(DEV_CONTAINER) >/dev/null 2>&1 || true
	@echo "$(GREEN)OK: Dev container stopped$(NC)"

.PHONY: stop-test
stop-test: ## Stop test container
	@echo "$(YELLOW)Stopping test container...$(NC)"
	@docker stop $(TEST_CONTAINER) >/dev/null 2>&1 || true
	@docker rm $(TEST_CONTAINER) >/dev/null 2>&1 || true
	@echo "$(GREEN)OK: Test container stopped$(NC)"

.PHONY: restart
restart: stop run ## Restart production container

.PHONY: restart-dev
restart-dev: stop-dev run-dev ## Restart dev container

# =============================================================
# RUNTIME TARGETS - LOGS & SHELL
# =============================================================
.PHONY: logs
logs: ## Show logs from production container
	@if [ -z "$$(docker ps -a -q -f name=$(LOCAL_CONTAINER))" ]; then \
		echo "$(RED)Container $(LOCAL_CONTAINER) not found!$(NC)"; \
	else \
		docker logs -f $(LOCAL_CONTAINER); \
	fi

.PHONY: logs-dev
logs-dev: ## Show logs from dev container
	@if [ -z "$$(docker ps -a -q -f name=$(DEV_CONTAINER))" ]; then \
		echo "$(RED)Dev container not found!$(NC)"; \
	else \
		docker logs -f $(DEV_CONTAINER); \
	fi

.PHONY: shell
shell: ## Access shell in production container
	@if [ -z "$$(docker ps -q -f name=$(LOCAL_CONTAINER))" ]; then \
		echo "$(RED)Container not running!$(NC)"; \
	else \
		docker exec -it $(LOCAL_CONTAINER) bash; \
	fi

.PHONY: shell-dev
shell-dev: ## Access shell in dev container
	@if [ -z "$$(docker ps -q -f name=$(DEV_CONTAINER))" ]; then \
		echo "$(RED)Dev container not running!$(NC)"; \
	else \
		docker exec -it $(DEV_CONTAINER) bash; \
	fi

# =============================================================
# TEST TARGETS
# =============================================================
.PHONY: test-quick
test-quick: ## Quick version check
	@echo "$(GREEN)Running quick version tests...$(NC)"
	@echo "\n$(CYAN)Testing PHP:$(NC)"
	@docker run --rm --entrypoint php $(FULL_IMAGE):latest -v | head -2
	@echo "\n$(CYAN)Testing Nginx:$(NC)"
	@docker run --rm --entrypoint nginx $(FULL_IMAGE):latest -v 2>&1 | head -1
	@echo "\n$(CYAN)Testing Redis:$(NC)"
	@docker run --rm --entrypoint redis-server $(FULL_IMAGE):latest --version
	@echo "\n$(CYAN)Testing Composer:$(NC)"
	@docker run --rm --entrypoint composer $(FULL_IMAGE):latest --version --no-ansi | head -1
	@echo "\n$(GREEN)OK: All components verified!$(NC)"

.PHONY: test
test: ## Run comprehensive tests
	@echo "$(GREEN)Running comprehensive tests...$(NC)"
	@$(MAKE) test-quick --no-print-directory
	@echo "\n$(YELLOW)Testing production configuration...$(NC)"
	@docker run --rm --entrypoint nginx $(FULL_IMAGE):latest -t
	@docker run --rm --entrypoint php-fpm $(FULL_IMAGE):latest -t
	@echo "$(GREEN)OK: All tests passed!$(NC)"

# =============================================================
# CLEANUP TARGETS
# =============================================================
.PHONY: clean
clean: ## Remove local images and containers
	@echo "$(YELLOW)Cleaning up...$(NC)"
	@docker stop $(LOCAL_CONTAINER) $(DEV_CONTAINER) $(TEST_CONTAINER) >/dev/null 2>&1 || true
	@docker rm $(LOCAL_CONTAINER) $(DEV_CONTAINER) $(TEST_CONTAINER) >/dev/null 2>&1 || true
	@docker rmi $(FULL_IMAGE):$(VERSION) >/dev/null 2>&1 || true
	@docker rmi $(FULL_IMAGE):latest >/dev/null 2>&1 || true
	@docker rmi $(FULL_IMAGE):dev >/dev/null 2>&1 || true
	@docker rmi $(FULL_IMAGE):test >/dev/null 2>&1 || true
	@echo "$(GREEN)OK: Cleanup complete$(NC)"

# =============================================================
# INFORMATION TARGETS
# =============================================================
.PHONY: info
info: ## Show build information
	@echo "$(CYAN)╔══════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║  PHP API Stack - Build Information      ║$(NC)"
	@echo "$(CYAN)╚══════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)Architecture:$(NC)"
	@echo "  Base -> Production | Dev"
	@echo ""
	@echo "$(CYAN)Available Stages:$(NC)"
	@echo "  • base       (foundation layer)"
	@echo "  • production (optimized for production)"
	@echo "  • dev        (with Xdebug + Symfony CLI)"
	@echo ""
	@echo "$(CYAN)Version:$(NC)       $(VERSION)"
	@echo "$(CYAN)Full Image:$(NC)    $(FULL_IMAGE)"
	@echo "$(CYAN)PHP Version:$(NC)   $(PHP_VERSION)"
	@echo "$(CYAN)Nginx:$(NC)         $(NGINX_VERSION)"
	@echo "$(CYAN)Redis:$(NC)         $(REDIS_VERSION)"


.PHONY: info-versions
info-versions: ## Show detailed version information
	@echo "$(CYAN)╔═══════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║  Component Versions - PHP API Stack          ║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)Base Components:$(NC)"
	@echo "  PHP:            $(PHP_VERSION)"
	@echo "  Nginx:          $(NGINX_VERSION)"
	@echo "  Redis Server:   $(REDIS_VERSION)"
	@echo "  Alpine:         $(ALPINE_VERSION)"
	@echo "  Composer:       $(COMPOSER_VERSION)"
	@echo ""
	@echo "$(CYAN)PECL Extensions:$(NC)"
	@echo "  redis:          $(PHP_REDIS_VERSION)"
	@echo "  apcu:           $(PHP_APCU_VERSION)"
	@echo "  uuid:           $(PHP_UUID_VERSION)"
	@echo "  imagick:        $(PHP_IMAGICK_VERSION)"
	@echo "  amqp:           $(PHP_AMQP_VERSION)"
	@echo ""
	@echo "$(CYAN)Dev Tools:$(NC)"
	@echo "  Symfony CLI:    $(SYMFONY_CLI_VERSION)"
	@echo "  Xdebug:         $(XDEBUG_VERSION)"
	
# =============================================================
# INCLUDE ADDITIONAL MAKEFILES
# =============================================================
-include Makefile.dockerhub
-include Makefile.compose