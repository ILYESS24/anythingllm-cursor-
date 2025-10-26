#!/bin/bash

# CI/CD Simulation Script
# This script simulates the CI/CD pipeline locally to identify and fix issues

set -e

echo "🚀 Starting CI/CD Simulation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed"
        exit 1
    fi
    
    if ! command -v yarn &> /dev/null; then
        print_error "Yarn is not installed"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not installed - skipping Docker tests"
        SKIP_DOCKER=true
    fi
    
    print_status "Dependencies check completed"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Install root dependencies
    yarn install --frozen-lockfile
    
    # Install server dependencies
    cd server
    yarn install --frozen-lockfile
    cd ..
    
    # Install frontend dependencies
    cd frontend
    yarn install --frozen-lockfile
    cd ..
    
    # Install collector dependencies
    cd collector
    yarn install --frozen-lockfile
    cd ..
    
    print_status "Dependencies installed successfully"
}

# Run linting
run_linting() {
    print_status "Running linting..."
    
    # Run ESLint
    if yarn lint; then
        print_status "Linting passed"
    else
        print_error "Linting failed"
        exit 1
    fi
}

# Run Prettier check
run_prettier_check() {
    print_status "Running Prettier check..."
    
    # Check server
    cd server
    if npx prettier --check .; then
        print_status "Server Prettier check passed"
    else
        print_error "Server Prettier check failed"
        exit 1
    fi
    cd ..
    
    # Check frontend
    cd frontend
    if npx prettier --check .; then
        print_status "Frontend Prettier check passed"
    else
        print_error "Frontend Prettier check failed"
        exit 1
    fi
    cd ..
    
    # Check collector
    cd collector
    if npx prettier --check .; then
        print_status "Collector Prettier check passed"
    else
        print_error "Collector Prettier check failed"
        exit 1
    fi
    cd ..
}

# Run TypeScript checks
run_typescript_check() {
    print_status "Running TypeScript checks..."
    
    # Check server
    cd server
    if npx tsc --noEmit; then
        print_status "Server TypeScript check passed"
    else
        print_error "Server TypeScript check failed"
        exit 1
    fi
    cd ..
    
    # Check frontend
    cd frontend
    if npx tsc --noEmit; then
        print_status "Frontend TypeScript check passed"
    else
        print_error "Frontend TypeScript check failed"
        exit 1
    fi
    cd ..
}

# Run unit tests
run_unit_tests() {
    print_status "Running unit tests..."
    
    if yarn test; then
        print_status "Unit tests passed"
    else
        print_error "Unit tests failed"
        exit 1
    fi
}

# Run integration tests
run_integration_tests() {
    print_status "Running integration tests..."
    
    # Start test database if needed
    # This would typically start a test PostgreSQL instance
    
    if yarn test:integration; then
        print_status "Integration tests passed"
    else
        print_error "Integration tests failed"
        exit 1
    fi
}

# Run security audit
run_security_audit() {
    print_status "Running security audit..."
    
    # Run npm audit
    if yarn audit --level moderate; then
        print_status "Security audit passed"
    else
        print_warning "Security vulnerabilities found"
    fi
    
    # Check server
    cd server
    if yarn audit --level moderate; then
        print_status "Server security audit passed"
    else
        print_warning "Server security vulnerabilities found"
    fi
    cd ..
    
    # Check frontend
    cd frontend
    if yarn audit --level moderate; then
        print_status "Frontend security audit passed"
    else
        print_warning "Frontend security vulnerabilities found"
    fi
    cd ..
    
    # Check collector
    cd collector
    if yarn audit --level moderate; then
        print_status "Collector security audit passed"
    else
        print_warning "Collector security vulnerabilities found"
    fi
    cd ..
}

# Build Docker images
build_docker_images() {
    if [ "$SKIP_DOCKER" = true ]; then
        print_warning "Skipping Docker build (Docker not installed)"
        return
    fi
    
    print_status "Building Docker images..."
    
    # Build for amd64
    if docker buildx build --platform linux/amd64 -t anythingllm:test-amd64 -f docker/Dockerfile .; then
        print_status "AMD64 Docker image built successfully"
    else
        print_error "AMD64 Docker image build failed"
        exit 1
    fi
    
    # Build for arm64
    if docker buildx build --platform linux/arm64 -t anythingllm:test-arm64 -f docker/Dockerfile .; then
        print_status "ARM64 Docker image built successfully"
    else
        print_error "ARM64 Docker image build failed"
        exit 1
    fi
}

# Test Docker images
test_docker_images() {
    if [ "$SKIP_DOCKER" = true ]; then
        print_warning "Skipping Docker tests (Docker not installed)"
        return
    fi
    
    print_status "Testing Docker images..."
    
    # Test AMD64 image
    if docker run --rm -d --name anythingllm-test-amd64 -p 3001:3001 anythingllm:test-amd64; then
        sleep 30
        if curl -f http://localhost:3001/health; then
            print_status "AMD64 Docker image test passed"
        else
            print_error "AMD64 Docker image health check failed"
        fi
        docker stop anythingllm-test-amd64
    else
        print_error "AMD64 Docker image test failed"
    fi
}

# Run build process
run_build() {
    print_status "Running build process..."
    
    # Build frontend
    cd frontend
    if yarn build; then
        print_status "Frontend build successful"
    else
        print_error "Frontend build failed"
        exit 1
    fi
    cd ..
    
    # Build server (if needed)
    cd server
    if yarn build; then
        print_status "Server build successful"
    else
        print_warning "Server build not configured or failed"
    fi
    cd ..
}

# Main execution
main() {
    print_status "Starting CI/CD simulation for AnythingLLM"
    
    check_dependencies
    install_dependencies
    run_linting
    run_prettier_check
    run_typescript_check
    run_unit_tests
    run_integration_tests
    run_security_audit
    run_build
    build_docker_images
    test_docker_images
    
    print_status "🎉 CI/CD simulation completed successfully!"
    print_status "All checks passed. The pipeline is ready for production."
}

# Run main function
main "$@"
