#!/bin/sh
# PHP API Stack - Diagnostic Script (POSIX Compatible)
# Compatible with sh, ash, dash, bash

set -eu

# Colors (POSIX compatible)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
ISSUES_FOUND=0
ISSUES_FIXED=0

# Functions
print_header() {
    echo "======================================"
    echo "  PHP API Stack - Diagnostic Tool"
    echo "======================================"
    echo ""
}

log_info() {
    printf "${GREEN}[INFO]${NC} %s\n" "$1"
}

log_warning() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
}

log_success() {
    printf "${GREEN}[✓]${NC} %s\n" "$1"
}

log_fixed() {
    printf "${CYAN}[FIXED]${NC} %s\n" "$1"
    ISSUES_FIXED=$((ISSUES_FIXED + 1))
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Quick diagnostic
quick_diagnose() {
    print_header
    
    echo "1. Checking Environment..."
    echo "----------------------------"
    
    # Check if in Docker
    if [ -f /.dockerenv ]; then
        log_success "Running inside Docker"
    else
        log_warning "Not inside Docker container"
    fi
    
    # Check user
    if check_root; then
        log_success "Running as root"
    else
        log_warning "Not root (limited fixes)"
    fi
    
    echo ""
    echo "2. Checking Software..."
    echo "----------------------------"
    
    # Check installed software
    for cmd in nginx php php-fpm redis-server; do
        if command -v $cmd >/dev/null 2>&1; then
            log_success "$cmd is installed"
        else
            log_error "$cmd NOT installed"
        fi
    done
    
    echo ""
    echo "3. Checking Users..."
    echo "----------------------------"
    
    # Check nginx user
    if id nginx >/dev/null 2>&1; then
        log_success "nginx user exists"
    else
        log_error "nginx user missing"
        if check_root; then
            addgroup -g 101 -S nginx 2>/dev/null || true
            adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx 2>/dev/null || true
            log_fixed "Created nginx user"
        fi
    fi
    
    # Check redis user
    if id redis >/dev/null 2>&1; then
        log_success "redis user exists"
    else
        log_error "redis user missing"
        if check_root; then
            addgroup -S redis 2>/dev/null || true
            adduser -D -S -h /var/lib/redis -s /sbin/nologin -G redis redis 2>/dev/null || true
            log_fixed "Created redis user"
        fi
    fi
    
    echo ""
    echo "4. Checking Directories..."
    echo "----------------------------"
    
    # Check critical directories
    for dir in /var/www/html /var/log/nginx /var/cache/nginx /var/run/php; do
        if [ -d "$dir" ]; then
            log_success "$dir exists"
        else
            log_error "$dir missing"
            if check_root; then
                mkdir -p "$dir"
                log_fixed "Created $dir"
            fi
        fi
    done
    
    echo ""
    echo "5. Checking Nginx Config..."
    echo "----------------------------"
    
    if [ -f /etc/nginx/nginx.conf ]; then
        log_success "nginx.conf exists"
        
        # Test configuration
        if nginx -t 2>/dev/null; then
            log_success "Nginx config is valid"
        else
            log_error "Nginx config has errors:"
            nginx -t 2>&1 | head -5
        fi
    else
        log_error "nginx.conf missing"
    fi
    
    echo ""
    echo "6. Quick Fixes Applied..."
    echo "----------------------------"
    
    if check_root; then
        # Create missing directories
        mkdir -p /var/cache/nginx/client_temp 2>/dev/null || true
        mkdir -p /var/cache/nginx/proxy_temp 2>/dev/null || true
        mkdir -p /var/cache/nginx/fastcgi_temp 2>/dev/null || true
        mkdir -p /var/run 2>/dev/null || true
        mkdir -p /run/nginx 2>/dev/null || true
        
        # Fix permissions
        chown -R nginx:nginx /var/cache/nginx 2>/dev/null || true
        chown -R nginx:nginx /var/www/html 2>/dev/null || true
        
        # Create PID file
        touch /var/run/nginx.pid 2>/dev/null || true
        chown nginx:nginx /var/run/nginx.pid 2>/dev/null || true
        
        log_fixed "Applied permission fixes"
    else
        log_warning "Run as root to apply fixes"
    fi
    
    echo ""
    echo "======================================"
    echo "Summary:"
    printf "Issues Found: %d\n" "$ISSUES_FOUND"
    printf "Issues Fixed: %d\n" "$ISSUES_FIXED"
    
    if [ $ISSUES_FOUND -eq 0 ]; then
        echo ""
        printf "${GREEN}✓ All checks passed!${NC}\n"
    elif [ $ISSUES_FIXED -eq $ISSUES_FOUND ]; then
        echo ""
        printf "${GREEN}✓ All issues fixed!${NC}\n"
    else
        REMAINING=$((ISSUES_FOUND - ISSUES_FIXED))
        echo ""
        printf "${YELLOW}⚠ %d issues need manual fix${NC}\n" "$REMAINING"
    fi
    echo "======================================"
}

# Main execution
main() {
    quick_diagnose
}

# Run
main