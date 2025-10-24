#!/bin/bash
# Build script for kariricode/php-api-stack
# Architecture: Base → Production | Dev
# Usage: ./build-from-env.sh [OPTIONS]

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Default values
PUSH_TO_HUB=false
NO_CACHE=false
MULTI_PLATFORM=false
BUILD_TARGET="production"  # default: production
VERSION_ARG=""

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --push)
            PUSH_TO_HUB=true
            shift
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        --multi-platform)
            MULTI_PLATFORM=true
            shift
            ;;
        --target=*)
            BUILD_TARGET="${arg#*=}"
            shift
            ;;
        --version=*)
            VERSION_ARG="${arg#*=}"
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Build Architecture: Base → Production | Dev"
            echo ""
            echo "Options:"
            echo "  --target=TARGET      Build target stage: base, production, dev (default: production)"
            echo "  --push               Push image to Docker Hub after build"
            echo "  --no-cache           Build without using cache"
            echo "  --multi-platform     Build for multiple platforms (amd64, arm64)"
            echo "  --version=X.Y.Z      Override version instead of using VERSION file"
            echo "  --help               Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                           # Build production image"
            echo "  $0 --target=dev              # Build dev image with Xdebug"
            echo "  $0 --target=base             # Build base layer only"
            echo "  $0 --target=production --push  # Build and push production"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $arg${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate build target
case $BUILD_TARGET in
    base|production|dev)
        ;;
    *)
        echo -e "${RED}Invalid build target: $BUILD_TARGET${NC}"
        echo "Valid targets: base, production, dev"
        exit 1
        ;;
esac

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

log_step() {
    echo -e "${CYAN}==>${NC} $1"
}

# Check if .env exists
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        log_warning ".env file not found! Creating from .env.example..."
        cp .env.example .env
        log_info "Created .env from .env.example"
        log_warning "Please review and customize .env before building!"
        echo ""
        read -p "Do you want to edit .env now? [Y/n]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            ${EDITOR:-vim} .env
        fi
    else
        log_error ".env file not found! Please create it from .env.example"
    fi
fi

# Load .env file
log_step "Loading configuration from .env..."
set -a
while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ $key =~ ^#.*$ ]] || [[ -z $key ]] && continue
    # Remove leading/trailing whitespace from value
    value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    # Export the variable
    export "$key=$value"
done < .env
set +a

# Set default values if not defined in .env
DOCKER_HUB_USER="${DOCKER_HUB_USER:-kariricode}"
IMAGE_NAME="${IMAGE_NAME:-php-api-stack}"
FULL_IMAGE="${DOCKER_HUB_USER}/${IMAGE_NAME}"

# Resolve VERSION precedence: CLI > VERSION file > default
if [ -n "${VERSION_ARG:-}" ]; then
    VERSION="$VERSION_ARG"
elif [ -f VERSION ]; then
    VERSION="$(head -n1 VERSION)"
else
    VERSION="1.0.0"
fi

BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "no-git")

# Display build configuration
echo ""
echo -e "${MAGENTA}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║     PHP API Stack - Docker Build Configuration   ║${NC}"
echo -e "${MAGENTA}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${WHITE}Architecture:${NC}  Base → Production | Dev"
echo -e "${WHITE}Build Target:${NC}  ${CYAN}${BUILD_TARGET}${NC}"
echo -e "${WHITE}Image:${NC}         ${FULL_IMAGE}:${VERSION}"
echo ""
echo -e "${YELLOW}Stack Versions:${NC}"
echo "  • PHP:         ${PHP_VERSION}"
echo "  • Nginx:       ${NGINX_VERSION}"
echo "  • Redis:       ${REDIS_VERSION}"
echo "  • Alpine:      ${ALPINE_VERSION}"
echo "  • Composer:    ${COMPOSER_VERSION}"

if [ "$BUILD_TARGET" = "dev" ]; then
    echo "  • Symfony CLI: ${SYMFONY_CLI_VERSION}"
    echo "  • Xdebug:      ${XDEBUG_VERSION}"
fi

echo ""
echo -e "${YELLOW}PHP Extensions:${NC}"
echo "  • Core: ${PHP_CORE_EXTENSIONS}"
echo "  • PECL: ${PHP_PECL_EXTENSIONS}"
echo ""
echo -e "${YELLOW}PECL Versions:${NC}"
echo "  • Redis:   ${PHP_REDIS_VERSION}"
echo "  • APCu:    ${PHP_APCU_VERSION}"
echo "  • UUID:    ${PHP_UUID_VERSION}"
echo "  • ImageMagick: ${PHP_IMAGICK_VERSION}"
echo "  • AMQP:    ${PHP_AMQP_VERSION}"
echo "" 

# Confirm build
read -p "$(echo -e ${GREEN}Proceed with build? [Y/n]: ${NC})" -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    log_warning "Build cancelled by user"
    exit 0
fi

# Prepare build command
log_step "Preparing build command for target: ${BUILD_TARGET}..."

# Base build command
BUILD_CMD="docker"

# Use buildx for multi-platform
if [ "$MULTI_PLATFORM" = true ]; then
    log_info "Setting up Docker buildx for multi-platform build..."
    
    if ! docker buildx ls | grep -q "php-api-stack-builder"; then
        docker buildx create --name php-api-stack-builder --use
        docker buildx inspect --bootstrap
    else
        docker buildx use php-api-stack-builder
    fi
    
    BUILD_CMD="docker buildx"
    PLATFORM_ARG="--platform linux/amd64,linux/arm64"
else
    PLATFORM_ARG=""
fi

# Build command
BUILD_CMD="$BUILD_CMD build"

# Add platform if multi-platform
if [ "$MULTI_PLATFORM" = true ]; then
    BUILD_CMD="$BUILD_CMD $PLATFORM_ARG"
fi

# Add no-cache or cache-from
if [ "$NO_CACHE" = true ]; then
    BUILD_CMD="$BUILD_CMD --no-cache"
else
    if docker manifest inspect "${FULL_IMAGE}:latest" >/dev/null 2>&1; then
        BUILD_CMD="$BUILD_CMD --cache-from ${FULL_IMAGE}:latest"
    else
        log_warning "Remote cache ${FULL_IMAGE}:latest not found; building without --cache-from"
    fi
fi

# Common build arguments
BUILD_CMD="$BUILD_CMD \
    --build-arg PHP_VERSION=${PHP_VERSION} \
    --build-arg NGINX_VERSION=${NGINX_VERSION} \
    --build-arg REDIS_VERSION=${REDIS_VERSION} \
    --build-arg ALPINE_VERSION=${ALPINE_VERSION} \
    --build-arg COMPOSER_VERSION=${COMPOSER_VERSION} \
    --build-arg PHP_CORE_EXTENSIONS=${PHP_CORE_EXTENSIONS} \
    --build-arg PHP_PECL_EXTENSIONS=${PHP_PECL_EXTENSIONS} \
    --build-arg VERSION=${VERSION} \
    --build-arg BUILD_DATE=\"${BUILD_DATE}\" \
    --build-arg VCS_REF=\"${VCS_REF}\""

# Target-specific build arguments and tags
case $BUILD_TARGET in
    base)
        BUILD_CMD="$BUILD_CMD --target base"
        BUILD_CMD="$BUILD_CMD --tag ${FULL_IMAGE}:base"
        ;;
        
    production)
        BUILD_CMD="$BUILD_CMD --target production"
        BUILD_CMD="$BUILD_CMD \
            --build-arg APP_ENV=production \
            --build-arg PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
            --build-arg PHP_OPCACHE_MAX_ACCELERATED_FILES=20000 \
            --build-arg PHP_OPCACHE_ENABLE=1 \
            --build-arg PHP_OPCACHE_MEMORY_CONSUMPTION=256"
        
        # Production tags
        BUILD_CMD="$BUILD_CMD \
            --tag ${FULL_IMAGE}:${VERSION} \
            --tag ${FULL_IMAGE}:latest"
        
        MAJOR_VERSION=$(echo $VERSION | cut -d. -f1)
        MINOR_VERSION=$(echo $VERSION | cut -d. -f1-2)
        BUILD_CMD="$BUILD_CMD \
            --tag ${FULL_IMAGE}:${MAJOR_VERSION} \
            --tag ${FULL_IMAGE}:${MINOR_VERSION}"
        ;;
        
    dev)
        BUILD_CMD="$BUILD_CMD --target dev"
        BUILD_CMD="$BUILD_CMD \
            --build-arg APP_ENV=development \
            --build-arg SYMFONY_CLI_VERSION=${SYMFONY_CLI_VERSION} \
            --build-arg XDEBUG_VERSION=${XDEBUG_VERSION} \
            --build-arg XDEBUG_ENABLE=1"
        
        # Dev tags
        BUILD_CMD="$BUILD_CMD \
            --tag ${FULL_IMAGE}:dev \
            --tag ${FULL_IMAGE}:dev-${VERSION}"
        ;;
esac

# Add push flag if multi-platform and push requested
if [ "$MULTI_PLATFORM" = true ] && [ "$PUSH_TO_HUB" = true ]; then
    BUILD_CMD="$BUILD_CMD --push"
fi

# Add Dockerfile path
BUILD_CMD="$BUILD_CMD --file Dockerfile ."

# Execute build
log_step "Building Docker image (target: ${BUILD_TARGET})..."
echo -e "${BLUE}Command:${NC} $BUILD_CMD"
echo ""

# Start timer
START_TIME=$(date +%s)

# Execute build
eval $BUILD_CMD

# Check build result
if [ $? -eq 0 ]; then
    END_TIME=$(date +%s)
    BUILD_TIME=$((END_TIME - START_TIME))
    
    echo ""
    log_info "✅ Build completed successfully in ${BUILD_TIME} seconds!"
    echo ""
    
    # Show image info if not multi-platform
    if [ "$MULTI_PLATFORM" = false ]; then
        log_step "Image information:"
        docker images ${FULL_IMAGE} --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
        
        IMAGE_SIZE=$(docker images ${FULL_IMAGE}:${BUILD_TARGET} --format "{{.Size}}" 2>/dev/null || echo "N/A")
        echo ""
        echo -e "${GREEN}Image size:${NC} ${IMAGE_SIZE}"
    fi
    
    # Test the image if not multi-platform and not base
    if [ "$MULTI_PLATFORM" = false ] && [ "$BUILD_TARGET" != "base" ]; then
        echo ""
        log_step "Testing image..."
        
        TEST_TAG="${BUILD_TARGET}"
        [ "$BUILD_TARGET" = "production" ] && TEST_TAG="latest"
        
        # Quick tests
        docker run --rm ${FULL_IMAGE}:${TEST_TAG} php -v > /dev/null 2>&1 && log_info "✓ PHP test passed"
        docker run --rm ${FULL_IMAGE}:${TEST_TAG} nginx -v > /dev/null 2>&1 && log_info "✓ Nginx test passed"
        docker run --rm ${FULL_IMAGE}:${TEST_TAG} redis-server --version > /dev/null 2>&1 && log_info "✓ Redis test passed"
        
        if [ "$BUILD_TARGET" = "dev" ]; then
            docker run --rm ${FULL_IMAGE}:dev php -m | grep -q xdebug && log_info "✓ Xdebug installed"
            docker run --rm ${FULL_IMAGE}:dev symfony version > /dev/null 2>&1 && log_info "✓ Symfony CLI installed"
        fi
    fi
    
    # Push to Docker Hub if requested
    if [ "$PUSH_TO_HUB" = true ] && [ "$MULTI_PLATFORM" = false ]; then
        echo ""
        log_step "Pushing to Docker Hub..."
        
        if ! docker info 2>/dev/null | grep -q "Username"; then
            log_warning "Not logged in to Docker Hub. Logging in..."
            docker login -u ${DOCKER_HUB_USER}
            [ $? -ne 0 ] && log_error "Failed to login to Docker Hub"
        fi
        
        case $BUILD_TARGET in
            production)
                for tag in ${VERSION} latest ${MAJOR_VERSION} ${MINOR_VERSION}; do
                    log_info "Pushing ${FULL_IMAGE}:${tag}..."
                    docker push ${FULL_IMAGE}:${tag}
                done
                ;;
            dev)
                log_info "Pushing ${FULL_IMAGE}:dev..."
                docker push ${FULL_IMAGE}:dev
                docker push ${FULL_IMAGE}:dev-${VERSION}
                ;;
            base)
                log_info "Pushing ${FULL_IMAGE}:base..."
                docker push ${FULL_IMAGE}:base
                ;;
        esac
        
        echo ""
        log_info "✅ Push completed!"
        echo -e "${GREEN}Image available at:${NC} https://hub.docker.com/r/${FULL_IMAGE}"
    fi
    
    # Show usage instructions
    echo ""
    echo -e "${CYAN}━━━ Usage Instructions ━━━${NC}"
    echo ""
    
    case $BUILD_TARGET in
        production)
            echo "To run the production container:"
            echo -e "  ${YELLOW}docker run -d -p 8080:80 ${FULL_IMAGE}:latest${NC}"
            ;;
        dev)
            echo "To run the dev container with Xdebug:"
            echo -e "  ${YELLOW}docker run -d -p 8080:80 -p 9003:9003 -e XDEBUG_ENABLE=1 ${FULL_IMAGE}:dev${NC}"
            ;;
        base)
            echo "Base image built successfully (foundation layer)"
            echo "Use as base for production or dev stages"
            ;;
    esac
    
    echo ""
    echo "To pull from Docker Hub:"
    echo -e "  ${YELLOW}docker pull ${FULL_IMAGE}:${BUILD_TARGET}${NC}"
    echo ""
    
else
    log_error "❌ Build failed! Check the error messages above."
fi

# Cleanup buildx if it was created
if [ "$MULTI_PLATFORM" = true ]; then
    log_info "Builder 'php-api-stack-builder' kept for future use"
    log_info "To remove: docker buildx rm php-api-stack-builder"
fi

exit 0