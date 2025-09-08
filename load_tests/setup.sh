#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log "Setting up load testing environment..."

log "Creating directory structure..."
mkdir -p load_tests/results/{basic_setup,search_engine_setup}
success "Directory structure created"

log "Checking required tools..."

if ! command -v bc &> /dev/null; then
    warning "bc is not installed. Installing..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y bc
    elif command -v yum &> /dev/null; then
        sudo yum install -y bc
    else
        warning "Please install 'bc' manually: sudo apt-get install bc"
    fi
else
    success "bc is installed"
fi

if ! command -v curl &> /dev/null; then
    warning "curl is not installed. Please install curl."
else
    success "curl is installed"
fi

if ! command -v docker &> /dev/null; then
    warning "Docker is not installed. Please install Docker."
else
    success "Docker is installed"
fi

log "Setting permissions..."
chmod +x load_tests/run_complete_tests.sh 2>/dev/null || true
chmod +x load_tests/setup.sh 2>/dev/null || true
success "Permissions set"

log "Pulling JMeter image..."
docker pull justb4/jmeter:latest
success "JMeter image ready"

echo ""
success "Setup completed!"
echo ""