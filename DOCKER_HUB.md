# Docker Hub Publishing Guide

**Audience**: Image publishers and maintainers  
**Purpose**: Complete guide for publishing images to Docker Hub

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Docker Hub Setup](#docker-hub-setup)
- [Versioning Strategy](#versioning-strategy)
- [Build Process](#build-process)
- [Tagging Strategy](#tagging-strategy)
- [Publishing Process](#publishing-process)
- [Multi-Platform Builds](#multi-platform-builds)
- [Automated Publishing](#automated-publishing)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

This guide covers the complete workflow for publishing **kariricode/php-api-stack** to Docker Hub, including:

- ✅ Proper versioning and tagging
- ✅ Multi-platform builds (amd64, arm64)
- ✅ Automated CI/CD pipelines
- ✅ Quality gates and validation
- ✅ Documentation synchronization

## 🔧 Prerequisites

### Required Accounts

1. **Docker Hub Account**
   - Username: `kariricode` (or your organization)
   - Repository: `php-api-stack`
   - Access: Write permissions

2. **GitHub Account** (for CI/CD)
   - Repository access
   - Secrets configuration

### Required Tools

```bash
# Core tools
docker --version        # >= 20.10
docker buildx version   # >= 0.10
make --version
git --version

# Optional but recommended
trivy --version        # Security scanning
hadolint --version     # Dockerfile linting
```

### Environment Setup

```bash
# Clone repository
git clone https://github.com/kariricode/php-api-stack.git
cd php-api-stack

# Verify structure
ls -la
# Expected: Dockerfile, Makefile, VERSION, .env, etc.
```

## 🚀 Docker Hub Setup

### 1. Login to Docker Hub

```bash
# Interactive login
docker login

# Or with credentials
docker login -u kariricode -p YOUR_TOKEN

# Verify login
docker info | grep Username
# Expected: Username: kariricode
```

### 2. Create Access Token (Recommended)

Instead of using password:

1. Go to https://hub.docker.com/settings/security
2. Click "New Access Token"
3. Name: `php-api-stack-ci`
4. Permissions: `Read, Write, Delete`
5. Copy token (you won't see it again!)

```bash
# Login with token
echo "YOUR_TOKEN" | docker login -u kariricode --password-stdin

# Save to environment (optional)
export DOCKER_HUB_TOKEN="YOUR_TOKEN"
```

### 3. Repository Configuration

Ensure Docker Hub repository exists:
- **Name**: `php-api-stack`
- **Visibility**: Public
- **Description**: "Production-ready PHP 8.4 + Nginx + Redis + Supervisor stack"
- **README**: Synced from GitHub (see [Documentation Sync](#documentation-sync))

## 📦 Versioning Strategy

The project follows [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH

Examples:
1.2.1  → Patch release (bug fixes)
1.3.0  → Minor release (new features, backward compatible)
2.0.0  → Major release (breaking changes)
```

### Version Management

#### Check Current Version
```bash
make version
# Output: Current version: 1.2.1
```

#### Bump Version

```bash
# Patch (1.2.1 → 1.2.2)
make bump-patch

# Minor (1.2.1 → 1.3.0)
make bump-minor

# Major (1.2.1 → 2.0.0)
make bump-major
```

#### Manual Version Update
```bash
# Edit VERSION file
echo "1.3.0" > VERSION

# Commit
git add VERSION
git commit -m "chore: bump version to 1.3.0"
git tag v1.3.0
git push origin main --tags
```

## 🏗️ Build Process

### Local Build

#### Simple Build
```bash
# Production build
make build

# Expected output:
# Building Docker image...
# Image: kariricode/php-api-stack:1.2.1
# ✓ Build complete!
```

#### Build with Tests
```bash
# Build + quick tests
make build-test

# Build test image with comprehensive health
make build-test-image
```

#### Build without Cache
```bash
# Force rebuild
make build-no-cache

# Or manual
./build-from-env.sh --no-cache
```

### Build Validation

```bash
# 1. Check image exists
docker images kariricode/php-api-stack

# 2. Verify tags
docker images kariricode/php-api-stack --format "table {{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# 3. Test image
make test-quick

# 4. Scan for vulnerabilities
make scan
```

## 🏷️ Tagging Strategy

### Standard Tags

For version `1.2.1`, the following tags are created:

| Tag | Description | Auto-updates |
|-----|-------------|--------------|
| `1.2.1` | Specific version | Never |
| `1.2` | Minor version | Patch only |
| `1` | Major version | Minor + Patch |
| `latest` | Latest stable | All releases |
| `stable` | Production | Stable releases |

### Environment-Specific Tags

| Tag | Description | When |
|-----|-------------|------|
| `dev` | Development | `APP_ENV=development` |
| `staging` | Staging | `APP_ENV=staging` |
| `stable` | Production | `APP_ENV=production` |
| `test` | Testing | `--test` flag |

### Manual Tagging

```bash
# Tag existing image
docker tag kariricode/php-api-stack:1.2.1 kariricode/php-api-stack:latest
docker tag kariricode/php-api-stack:1.2.1 kariricode/php-api-stack:1.2
docker tag kariricode/php-api-stack:1.2.1 kariricode/php-api-stack:1
docker tag kariricode/php-api-stack:1.2.1 kariricode/php-api-stack:stable
```

### Automated Tagging

The `build-from-env.sh` script handles tagging automatically:

```bash
# Production build (creates all tags)
./build-from-env.sh --version=1.2.1

# Test build (creates test tags)
./build-from-env.sh --test --version=1.2.1
```

## 📤 Publishing Process

### Quick Publish

#### Using Makefile (Recommended)
```bash
# Build and push
make build
make push

# Or combined
make release  # lint + build + test + scan + push
```

#### Using Script
```bash
# Build with push
./build-from-env.sh --push

# Or separate
./build-from-env.sh
docker push kariricode/php-api-stack:1.2.1
docker push kariricode/php-api-stack:latest
```

### Complete Release Workflow

```bash
# 1. Update version
make bump-patch  # or bump-minor, bump-major

# 2. Quality gates
make lint        # Dockerfile validation
make build       # Build image
make test        # Run tests
make scan        # Security scan

# 3. Push to registry
make push

# 4. Tag in git
git tag v$(cat VERSION)
git push origin main --tags

# 5. Create GitHub release (optional)
gh release create v$(cat VERSION) \
  --title "Release $(cat VERSION)" \
  --notes "See CHANGELOG.md"
```

### Push Individual Tags

```bash
VERSION=$(cat VERSION)

# Push specific version
docker push kariricode/php-api-stack:$VERSION

# Push semantic versions
docker push kariricode/php-api-stack:${VERSION%.*}  # 1.2
docker push kariricode/php-api-stack:${VERSION%%.*} # 1

# Push latest
docker push kariricode/php-api-stack:latest

# Push environment-specific
docker push kariricode/php-api-stack:stable
```

## 🌍 Multi-Platform Builds

Build for multiple architectures (amd64, arm64):

### Setup Buildx

```bash
# Create builder
docker buildx create --name php-api-stack-builder --use

# Verify
docker buildx ls
# Expected: php-api-stack-builder running
```

### Multi-Platform Build

#### Using Script
```bash
# Build and push for multiple platforms
./build-from-env.sh --multi-platform --push

# Platforms: linux/amd64, linux/arm64
```

#### Manual Build
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag kariricode/php-api-stack:1.2.1 \
  --tag kariricode/php-api-stack:latest \
  --push \
  .
```

### Verify Multi-Platform

```bash
# Check manifest
docker manifest inspect kariricode/php-api-stack:latest

# Expected output shows:
# - linux/amd64
# - linux/arm64
```

## 🤖 Automated Publishing

### GitHub Actions

Create `.github/workflows/publish.yml`:

```yaml
name: Publish to Docker Hub

on:
  push:
    tags:
      - 'v*'

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_TOKEN }}

      - name: Extract version
        id: version
        run: echo "VERSION=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT

      - name: Build and test
        run: |
          make build
          make test
          make scan

      - name: Build and push multi-platform
        run: |
          ./build-from-env.sh \
            --version=${{ steps.version.outputs.VERSION }} \
            --multi-platform \
            --push

      - name: Update Docker Hub description
        uses: peter-evans/dockerhub-description@v3
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_TOKEN }}
          repository: kariricode/php-api-stack
          readme-filepath: ./IMAGE_USAGE_GUIDE.md
```

### Required GitHub Secrets

Add these secrets to your GitHub repository:
- `DOCKER_HUB_USERNAME`: Your Docker Hub username
- `DOCKER_HUB_TOKEN`: Your Docker Hub access token

Settings → Secrets and variables → Actions → New repository secret

### Trigger Automated Publish

```bash
# 1. Bump version
make bump-patch

# 2. Commit and tag
git add VERSION
git commit -m "chore: bump version to $(cat VERSION)"
git tag v$(cat VERSION)

# 3. Push (triggers GitHub Action)
git push origin main --tags

# 4. Monitor workflow
# Visit: https://github.com/kariricode/php-api-stack/actions
```

## 🎯 Best Practices

### Pre-Publish Checklist

```bash
# ✅ 1. Code quality
make lint

# ✅ 2. Build succeeds
make build-no-cache

# ✅ 3. All tests pass
make test

# ✅ 4. No vulnerabilities
make scan

# ✅ 5. Health check works
make run-test
make test-health
make stop-test

# ✅ 6. Documentation updated
# Review: README.md, TESTING.md, DOCKER_HUB.md, IMAGE_USAGE_GUIDE.md

# ✅ 7. Changelog updated
# Add entry to CHANGELOG.md

# ✅ 8. Version bumped
cat VERSION  # Should be new version

# ✅ 9. Git tagged
git tag | tail -1  # Should match VERSION
```

### Image Size Optimization

```bash
# Check current size
docker images kariricode/php-api-stack:latest

# Optimize .dockerignore
cat > .dockerignore << EOF
.git
.github
.gitignore
tests/
docs/
*.md
!README.md
.env
.env.*
!.env.example
EOF

# Rebuild
make build-no-cache

# Compare
docker images kariricode/php-api-stack
```

### Security Best Practices

1. **Use Access Tokens**: Never use passwords directly
2. **Scan Before Push**: Always run `make scan`
3. **Pin Base Images**: Use specific versions (already done)
4. **Regular Updates**: Update base images monthly
5. **Minimal Privileges**: Use non-root user when possible

### Documentation Sync

#### Docker Hub Description

Option 1: Automated (GitHub Actions)
```yaml
# Already in publish.yml workflow
- name: Update Docker Hub description
  uses: peter-evans/dockerhub-description@v3
  with:
    readme-filepath: ./IMAGE_USAGE_GUIDE.md
```

Option 2: Manual
```bash
# Install tool
npm install -g dockerhub-description

# Update description
dockerhub-description \
  kariricode/php-api-stack \
  ./IMAGE_USAGE_GUIDE.md \
  --username kariricode \
  --password "$DOCKER_HUB_TOKEN"
```

## 🐛 Troubleshooting

### Build Issues

#### Error: Cannot connect to Docker daemon
```bash
# Check Docker is running
docker ps

# Restart Docker
sudo systemctl restart docker  # Linux
# or restart Docker Desktop
```

#### Error: Build fails with "no space left on device"
```bash
# Clean up
docker system prune -af --volumes

# Check space
df -h
```

### Push Issues

#### Error: Authentication required
```bash
# Re-login
docker logout
docker login

# Verify
docker info | grep Username
```

#### Error: Denied: requested access to the resource is denied
```bash
# Check repository name
docker images | grep php-api-stack

# Should be: kariricode/php-api-stack
# Not: php-api-stack

# Retag if needed
docker tag php-api-stack:latest kariricode/php-api-stack:latest
```

#### Error: Image push failed
```bash
# Check network
ping registry-1.docker.io

# Check size (max 10GB per layer)
docker images kariricode/php-api-stack:latest

# Try again with retry
for i in {1..3}; do
  docker push kariricode/php-api-stack:latest && break
  sleep 5
done
```

### Multi-Platform Issues

#### Error: Multiple platforms feature is currently not supported
```bash
# Enable experimental features
export DOCKER_CLI_EXPERIMENTAL=enabled

# Or in ~/.docker/config.json:
{
  "experimental": "enabled"
}
```

#### Error: Buildx builder not found
```bash
# Create builder
docker buildx create --name php-api-stack-builder --use

# Bootstrap
docker buildx inspect --bootstrap
```

## 📊 Monitoring Published Images

### Docker Hub Stats

```bash
# View on Docker Hub
open https://hub.docker.com/r/kariricode/php-api-stack

# Check pulls (requires Docker Hub account)
curl -s "https://hub.docker.com/v2/repositories/kariricode/php-api-stack/" | jq '.pull_count'
```

### Image Verification

```bash
# Pull and verify
docker pull kariricode/php-api-stack:latest

# Check digest
docker inspect kariricode/php-api-stack:latest | jq '.[0].RepoDigests'

# Verify signature (if signed)
docker trust inspect kariricode/php-api-stack:latest
```

## 📅 Release Schedule

### Recommended Schedule

- **Patch releases**: As needed (bug fixes)
- **Minor releases**: Monthly (new features)
- **Major releases**: Quarterly (breaking changes)
- **Security patches**: Immediately (critical vulnerabilities)

### Release Process Timeline

```
Week 1: Development
  - Feature development
  - Bug fixes
  - Testing

Week 2: Pre-release
  - Code freeze
  - Final testing
  - Documentation update

Week 3: Release
  - Version bump
  - Build and test
  - Publish to Docker Hub
  - GitHub release

Week 4: Monitoring
  - Monitor issues
  - Quick patches if needed
  - Plan next release
```

## 📞 Support

### For Publishing Issues

- **GitHub Issues**: [Report issues](https://github.com/kariricode/php-api-stack/issues)
- **Docker Hub**: [Repository page](https://hub.docker.com/r/kariricode/php-api-stack)
- **Discussions**: [GitHub Discussions](https://github.com/kariricode/php-api-stack/discussions)

### Quick Reference

```bash
# Complete release
make version        # Check version
make bump-patch     # Bump version
make release        # Full pipeline
git tag v$(cat VERSION)
git push origin main --tags

# Emergency hotfix
make build-no-cache
make test
make push
```

---

**Next**: [IMAGE_USAGE_GUIDE.md](IMAGE_USAGE_GUIDE.md) - Learn how to use the published image