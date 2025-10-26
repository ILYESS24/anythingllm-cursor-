# Quick Test Script for CI/CD Fixes
# This script runs a quick validation of the fixes

param(
    [switch]$SkipDocker,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Colors
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"

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

function Test-Command {
    param([string]$Command, [string]$WorkingDir = ".")
    
    try {
        $result = Invoke-Expression "cd '$WorkingDir'; $Command"
        return $true
    }
    catch {
        return $false
    }
}

function Main {
    Write-Status "🚀 Running quick CI/CD validation tests..."
    
    # Test 1: Check if scripts exist
    Write-Status "Testing script files..."
    $scripts = @(
        "scripts\ci-simulation.ps1",
        "scripts\update-dependencies.js",
        "docker\Dockerfile.optimized",
        ".github\workflows\ci-cd.yml"
    )
    
    foreach ($script in $scripts) {
        if (Test-Path $script) {
            Write-Status "✅ $script exists"
        } else {
            Write-Error "❌ $script missing"
        }
    }
    
    # Test 2: Validate package.json scripts
    Write-Status "Validating package.json scripts..."
    
    $packages = @("server", "frontend", "collector")
    foreach ($pkg in $packages) {
        $packageJson = Get-Content "$pkg\package.json" | ConvertFrom-Json
        if ($packageJson.scripts.build) {
            Write-Status "✅ $pkg has build script"
        } else {
            Write-Error "❌ $pkg missing build script"
        }
        
        if ($packageJson.scripts.test) {
            Write-Status "✅ $pkg has test script"
        } else {
            Write-Error "❌ $pkg missing test script"
        }
    }
    
    # Test 3: Check dependencies installation
    Write-Status "Testing dependency installation..."
    
    if (Test-Command "yarn --version") {
        Write-Status "✅ Yarn is available"
    } else {
        Write-Error "❌ Yarn not found"
    }
    
    # Test 4: Quick lint check
    Write-Status "Running quick lint check..."
    
    try {
        Set-Location frontend
        if (Test-Command "yarn lint") {
            Write-Status "✅ Frontend lint passed"
        } else {
            Write-Warning "⚠️ Frontend lint issues found"
        }
        Set-Location ..
    }
    catch {
        Write-Warning "⚠️ Could not run frontend lint"
    }
    
    # Test 5: Check Docker (if available)
    if (-not $SkipDocker) {
        Write-Status "Testing Docker availability..."
        if (Test-Command "docker --version") {
            Write-Status "✅ Docker is available"
            
            # Test optimized Dockerfile syntax
            Write-Status "Validating optimized Dockerfile..."
            if (Test-Command "docker build --dry-run -f docker/Dockerfile.optimized .") {
                Write-Status "✅ Optimized Dockerfile syntax is valid"
            } else {
                Write-Warning "⚠️ Optimized Dockerfile has syntax issues"
            }
        } else {
            Write-Warning "⚠️ Docker not available"
        }
    }
    
    # Test 6: Security audit summary
    Write-Status "Running security audit summary..."
    
    try {
        $auditResult = yarn audit --json --level moderate 2>&1 | ConvertFrom-Json
        $vulnerabilities = $auditResult | Where-Object { $_.type -eq "auditSummary" }
        if ($vulnerabilities) {
            Write-Warning "Found $($vulnerabilities.data.vulnerabilities.high) high and $($vulnerabilities.data.vulnerabilities.critical) critical vulnerabilities"
        }
    }
    catch {
        Write-Warning "Could not run security audit"
    }
    
    Write-Status "🎉 Quick validation completed!"
    Write-Status "Next steps:"
    Write-Status "1. Run: node scripts/update-dependencies.js"
    Write-Status "2. Run: powershell -ExecutionPolicy Bypass -File scripts/ci-simulation.ps1 -SkipDocker"
    Write-Status "3. Test Docker build with: docker build -f docker/Dockerfile.optimized ."
}

Main
