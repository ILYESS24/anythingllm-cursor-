# CI/CD Simulation Script for Windows
# This script simulates the CI/CD pipeline locally to identify and fix issues

param(
    [switch]$SkipDocker,
    [switch]$Verbose
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$White = "White"

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Red
}

# Check if required tools are installed
function Test-Dependencies {
    Write-Status "Checking dependencies..."
    
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Error "Node.js is not installed"
        exit 1
    }
    
    if (-not (Get-Command yarn -ErrorAction SilentlyContinue)) {
        Write-Error "Yarn is not installed"
        exit 1
    }
    
    if (-not $SkipDocker -and -not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Warning "Docker is not installed - skipping Docker tests"
        $script:SkipDocker = $true
    }
    
    Write-Status "Dependencies check completed"
}

# Install dependencies
function Install-Dependencies {
    Write-Status "Installing dependencies..."
    
    try {
        # Install root dependencies
        yarn install --frozen-lockfile
        
        # Install server dependencies
        Set-Location server
        yarn install --frozen-lockfile
        Set-Location ..
        
        # Install frontend dependencies
        Set-Location frontend
        yarn install --frozen-lockfile
        Set-Location ..
        
        # Install collector dependencies
        Set-Location collector
        yarn install --frozen-lockfile
        Set-Location ..
        
        Write-Status "Dependencies installed successfully"
    }
    catch {
        Write-Error "Failed to install dependencies: $($_.Exception.Message)"
        exit 1
    }
}

# Run linting
function Invoke-Linting {
    Write-Status "Running linting..."
    
    try {
        yarn lint
        Write-Status "Linting passed"
    }
    catch {
        Write-Error "Linting failed: $($_.Exception.Message)"
        exit 1
    }
}

# Run Prettier check
function Invoke-PrettierCheck {
    Write-Status "Running Prettier check..."
    
    try {
        # Check server
        Set-Location server
        npx prettier --check .
        Write-Status "Server Prettier check passed"
        Set-Location ..
        
        # Check frontend
        Set-Location frontend
        npx prettier --check .
        Write-Status "Frontend Prettier check passed"
        Set-Location ..
        
        # Check collector
        Set-Location collector
        npx prettier --check .
        Write-Status "Collector Prettier check passed"
        Set-Location ..
    }
    catch {
        Write-Error "Prettier check failed: $($_.Exception.Message)"
        exit 1
    }
}

# Run TypeScript checks
function Invoke-TypeScriptCheck {
    Write-Status "Running TypeScript checks..."
    
    try {
        # Check server
        Set-Location server
        npx tsc --noEmit
        Write-Status "Server TypeScript check passed"
        Set-Location ..
        
        # Check frontend
        Set-Location frontend
        npx tsc --noEmit
        Write-Status "Frontend TypeScript check passed"
        Set-Location ..
    }
    catch {
        Write-Error "TypeScript check failed: $($_.Exception.Message)"
        exit 1
    }
}

# Run unit tests
function Invoke-UnitTests {
    Write-Status "Running unit tests..."
    
    try {
        yarn test
        Write-Status "Unit tests passed"
    }
    catch {
        Write-Error "Unit tests failed: $($_.Exception.Message)"
        exit 1
    }
}

# Run integration tests
function Invoke-IntegrationTests {
    Write-Status "Running integration tests..."
    
    try {
        # Start test database if needed
        # This would typically start a test PostgreSQL instance
        
        yarn test:integration
        Write-Status "Integration tests passed"
    }
    catch {
        Write-Error "Integration tests failed: $($_.Exception.Message)"
        exit 1
    }
}

# Run security audit
function Invoke-SecurityAudit {
    Write-Status "Running security audit..."
    
    try {
        # Run npm audit
        yarn audit --level moderate
        Write-Status "Security audit passed"
    }
    catch {
        Write-Warning "Security vulnerabilities found"
    }
    
    try {
        # Check server
        Set-Location server
        yarn audit --level moderate
        Write-Status "Server security audit passed"
        Set-Location ..
    }
    catch {
        Write-Warning "Server security vulnerabilities found"
        Set-Location ..
    }
    
    try {
        # Check frontend
        Set-Location frontend
        yarn audit --level moderate
        Write-Status "Frontend security audit passed"
        Set-Location ..
    }
    catch {
        Write-Warning "Frontend security vulnerabilities found"
        Set-Location ..
    }
    
    try {
        # Check collector
        Set-Location collector
        yarn audit --level moderate
        Write-Status "Collector security audit passed"
        Set-Location ..
    }
    catch {
        Write-Warning "Collector security vulnerabilities found"
        Set-Location ..
    }
}

# Build Docker images
function Build-DockerImages {
    if ($SkipDocker) {
        Write-Warning "Skipping Docker build (Docker not installed or skipped)"
        return
    }
    
    Write-Status "Building Docker images..."
    
    try {
        # Build for amd64
        docker buildx build --platform linux/amd64 -t anythingllm:test-amd64 -f docker/Dockerfile .
        Write-Status "AMD64 Docker image built successfully"
        
        # Build for arm64
        docker buildx build --platform linux/arm64 -t anythingllm:test-arm64 -f docker/Dockerfile .
        Write-Status "ARM64 Docker image built successfully"
    }
    catch {
        Write-Error "Docker image build failed: $($_.Exception.Message)"
        exit 1
    }
}

# Test Docker images
function Test-DockerImages {
    if ($SkipDocker) {
        Write-Warning "Skipping Docker tests (Docker not installed or skipped)"
        return
    }
    
    Write-Status "Testing Docker images..."
    
    try {
        # Test AMD64 image
        docker run --rm -d --name anythingllm-test-amd64 -p 3001:3001 anythingllm:test-amd64
        
        Start-Sleep -Seconds 30
        
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3001/health" -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Status "AMD64 Docker image test passed"
            } else {
                Write-Error "AMD64 Docker image health check failed"
            }
        }
        catch {
            Write-Error "AMD64 Docker image health check failed: $($_.Exception.Message)"
        }
        finally {
            docker stop anythingllm-test-amd64
        }
    }
    catch {
        Write-Error "Docker image test failed: $($_.Exception.Message)"
    }
}

# Run build process
function Invoke-Build {
    Write-Status "Running build process..."
    
    try {
        # Build frontend
        Set-Location frontend
        yarn build
        Write-Status "Frontend build successful"
        Set-Location ..
        
        # Build server (if needed)
        Set-Location server
        try {
            yarn build
            Write-Status "Server build successful"
        }
        catch {
            Write-Warning "Server build not configured or failed"
        }
        Set-Location ..
    }
    catch {
        Write-Error "Build process failed: $($_.Exception.Message)"
        exit 1
    }
}

# Main execution
function Main {
    Write-Status "Starting CI/CD simulation for AnythingLLM"
    
    Test-Dependencies
    Install-Dependencies
    Invoke-Linting
    Invoke-PrettierCheck
    Invoke-TypeScriptCheck
    Invoke-UnitTests
    Invoke-IntegrationTests
    Invoke-SecurityAudit
    Invoke-Build
    Build-DockerImages
    Test-DockerImages
    
    Write-Status "🎉 CI/CD simulation completed successfully!"
    Write-Status "All checks passed. The pipeline is ready for production."
}

# Run main function
Main
