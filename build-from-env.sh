#!/bin/bash
# Build script for dtihubmaker/php-api-stack
# This script reads all configurations from .env file and builds the Docker image
# Usage: ./build-from-env.sh [--push] [--no-cache]

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

# Parse command line arguments
PUSH_TO_HUB=false
NO_CACHE=false
MULTI_PLATFORM=false

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
        --version=*)
            VERSION_ARG="${arg#*=}"
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --push           Push image to Docker Hub after build"
            echo "  --no-cache       Build without using cache"
            echo "  --multi-platform Build for multiple platforms (amd64, arm64)"
            echo "  --version=X.Y.Z  Override version instead of using VERSION file"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $arg${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done



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
source .env
set +a

# Set default values if not defined in .env
DOCKER_HUB_USER="${DOCKER_HUB_USER:-dtihubmaker}"
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
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║     PHP API Stack - Docker Build Configuration      ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${WHITE}Image:${NC}         ${FULL_IMAGE}:${VERSION}"
echo -e "${WHITE}Environment:${NC}   ${APP_ENV}"
echo ""
echo -e "${YELLOW}Stack Versions:${NC}"
echo "  • PHP:         ${PHP_VERSION}"
echo "  • Nginx:       ${NGINX_VERSION}"
echo "  • Redis:       ${REDIS_VERSION}"
echo "  • Composer:    ${COMPOSER_VERSION}"
echo "  • Symfony CLI: ${SYMFONY_CLI_VERSION}"
echo ""
echo -e "${YELLOW}PHP Extensions:${NC}"
echo "  • Core: ${PHP_CORE_EXTENSIONS}"
echo "  • PECL: ${PHP_PECL_EXTENSIONS}"
echo ""
echo -e "${YELLOW}Build Options:${NC}"
echo "  • No Cache:       ${NO_CACHE}"
echo "  • Push to Hub:    ${PUSH_TO_HUB}"
echo "  • Multi-Platform: ${MULTI_PLATFORM}"
echo ""

# Confirm build
read -p "$(echo -e ${GREEN}Proceed with build? [Y/n]: ${NC})" -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    log_warning "Build cancelled by user"
    exit 0
fi

# Prepare build command
log_step "Preparing build command..."

# Base build command
BUILD_CMD="docker"

# Use buildx for multi-platform
if [ "$MULTI_PLATFORM" = true ]; then
    log_info "Setting up Docker buildx for multi-platform build..."
    
    # Create builder if it doesn't exist
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

# Add no-cache if requested
# Add no-cache if requested or guard cache-from
if [ "$NO_CACHE" = true ]; then
    BUILD_CMD="$BUILD_CMD --no-cache"
else
    if docker manifest inspect "${FULL_IMAGE}:latest" >/dev/null 2>&1; then
        BUILD_CMD="$BUILD_CMD --cache-from ${FULL_IMAGE}:latest"
    else
        log_warning "Remote cache ${FULL_IMAGE}:latest not found; building without --cache-from"
    fi
fi


# Add build arguments
BUILD_CMD="$BUILD_CMD \
    --build-arg PHP_VERSION=${PHP_VERSION} \
    --build-arg NGINX_VERSION=${NGINX_VERSION} \
    --build-arg REDIS_VERSION=${REDIS_VERSION} \
    --build-arg COMPOSER_VERSION=${COMPOSER_VERSION} \
    --build-arg SYMFONY_CLI_VERSION=${SYMFONY_CLI_VERSION} \
    --build-arg PHP_CORE_EXTENSIONS=\"${PHP_CORE_EXTENSIONS}\" \
    --build-arg PHP_PECL_EXTENSIONS=\"${PHP_PECL_EXTENSIONS}\" \
    --build-arg APP_NAME=\"${APP_NAME}\" \
    --build-arg APP_ENV=${APP_ENV} \
    --build-arg APP_PORT=${APP_PORT} \
    --build-arg BUILD_DATE=\"${BUILD_DATE}\" \
    --build-arg VCS_REF=\"${VCS_REF}\""

# Add install PHP tools flag based on environment
if [ "${APP_ENV}" = "development" ]; then
    BUILD_CMD="$BUILD_CMD --build-arg INSTALL_PHP_TOOLS=true"
else
    BUILD_CMD="$BUILD_CMD --build-arg INSTALL_PHP_TOOLS=false"
fi

# Add tags
BUILD_CMD="$BUILD_CMD \
    --tag ${FULL_IMAGE}:${VERSION} \
    --tag ${FULL_IMAGE}:latest"

# Add minor and major version tags
MAJOR_VERSION=$(echo $VERSION | cut -d. -f1)
MINOR_VERSION=$(echo $VERSION | cut -d. -f1-2)
BUILD_CMD="$BUILD_CMD \
    --tag ${FULL_IMAGE}:${MAJOR_VERSION} \
    --tag ${FULL_IMAGE}:${MINOR_VERSION}"

# Add environment-specific tag
if [ "${APP_ENV}" = "development" ]; then
    BUILD_CMD="$BUILD_CMD --tag ${FULL_IMAGE}:dev"
elif [ "${APP_ENV}" = "staging" ]; then
    BUILD_CMD="$BUILD_CMD --tag ${FULL_IMAGE}:staging"
elif [ "${APP_ENV}" = "production" ]; then
    BUILD_CMD="$BUILD_CMD --tag ${FULL_IMAGE}:stable"
fi

# Add push flag if multi-platform and push requested
if [ "$MULTI_PLATFORM" = true ] && [ "$PUSH_TO_HUB" = true ]; then
    BUILD_CMD="$BUILD_CMD --push"
fi

# Add Dockerfile path
BUILD_CMD="$BUILD_CMD --file Dockerfile ."

# Execute build
log_step "Building Docker image..."
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
        
        # Get image size
        IMAGE_SIZE=$(docker images ${FULL_IMAGE}:latest --format "{{.Size}}")
        echo ""
        echo -e "${GREEN}Image size:${NC} ${IMAGE_SIZE}"
    fi
    
    # Test the image if not multi-platform
    if [ "$MULTI_PLATFORM" = false ]; then
        echo ""
        log_step "Testing image..."
        
        # Quick test
        docker run --rm ${FULL_IMAGE}:${VERSION} php -v > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            log_info "✓ PHP test passed"
        else
            log_warning "PHP test failed"
        fi
        
        docker run --rm ${FULL_IMAGE}:${VERSION} nginx -v > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            log_info "✓ Nginx test passed"
        else
            log_warning "Nginx test failed"
        fi
        
        docker run --rm ${FULL_IMAGE}:${VERSION} redis-server --version > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            log_info "✓ Redis test passed"
        else
            log_warning "Redis test failed"
        fi
    fi
    
    # Push to Docker Hub if requested and not already pushed (multi-platform)
    if [ "$PUSH_TO_HUB" = true ] && [ "$MULTI_PLATFORM" = false ]; then
        echo ""
        log_step "Pushing to Docker Hub..."
        
        # Check if logged in
        if ! docker info 2>/dev/null | grep -q "Username"; then
            log_warning "Not logged in to Docker Hub. Logging in..."
            docker login -u ${DOCKER_HUB_USER}
            
            if [ $? -ne 0 ]; then
                log_error "Failed to login to Docker Hub"
            fi
        fi
        
        # Push all tags
        for tag in ${VERSION} latest ${MAJOR_VERSION} ${MINOR_VERSION}; do
            log_info "Pushing ${FULL_IMAGE}:${tag}..."
            docker push ${FULL_IMAGE}:${tag}
        done
        
        # Push environment-specific tag
        if [ "${APP_ENV}" = "development" ]; then
            docker push ${FULL_IMAGE}:dev
        elif [ "${APP_ENV}" = "staging" ]; then
            docker push ${FULL_IMAGE}:staging
        elif [ "${APP_ENV}" = "production" ]; then
            docker push ${FULL_IMAGE}:stable
        fi
        
        echo ""
        log_info "✅ Push completed!"
        echo ""
        echo -e "${GREEN}Image available at:${NC}"
        echo "  https://hub.docker.com/r/${FULL_IMAGE}"
    fi
    
    # Show usage instructions
    echo ""
    echo -e "${CYAN}═══ Usage Instructions ═══${NC}"
    echo ""
    echo "To run the container:"
    echo -e "  ${YELLOW}docker run -d -p ${APP_PORT}:80 ${FULL_IMAGE}:${VERSION}${NC}"
    echo ""
    echo "To pull from Docker Hub:"
    echo -e "  ${YELLOW}docker pull ${FULL_IMAGE}:latest${NC}"
    echo ""
    
    if [ "$PUSH_TO_HUB" = false ]; then
        echo "To push to Docker Hub:"
        echo -e "  ${YELLOW}docker push ${FULL_IMAGE}:${VERSION}${NC}"
        echo "Or run this script with --push flag:"
        echo -e "  ${YELLOW}./build-from-env.sh --push${NC}"
        echo ""
    fi
    
else
    log_error "❌ Build failed! Check the error messages above."
fi

# Cleanup buildx if it was created
if [ "$MULTI_PLATFORM" = true ]; then
    # Don't remove the builder, keep it for future use
    log_info "Builder 'php-api-stack-builder' kept for future use"
    log_info "To remove: docker buildx rm php-api-stack-builder"
fi

exit 0