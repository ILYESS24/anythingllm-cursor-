# Railway Deployment Simulation Script
Write-Host " Railway Deployment Simulation Started" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Check Node.js version
if (Get-Command "node" -ErrorAction SilentlyContinue) {
    $nodeVersion = node --version
    Write-Host " Node.js version: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host " Node.js not found" -ForegroundColor Red
}

# Check Yarn
if (Get-Command "yarn" -ErrorAction SilentlyContinue) {
    $yarnVersion = yarn --version
    Write-Host " Yarn version: $yarnVersion" -ForegroundColor Green
} else {
    Write-Host " Yarn not found" -ForegroundColor Red
}

# Check Git repository
if (Test-Path ".git") {
    Write-Host " Git repository detected" -ForegroundColor Green
} else {
    Write-Host " Not in a Git repository" -ForegroundColor Red
}

# Check required files
$requiredFiles = @(
    "package.json",
    "server/package.json", 
    "frontend/package.json",
    "collector/package.json",
    "docker/Dockerfile.optimized",
    "docker/.env.example"
)

Write-Host "`n Checking Required Files..." -ForegroundColor Yellow
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host " $file exists" -ForegroundColor Green
    } else {
        Write-Host " $file missing" -ForegroundColor Red
    }
}

# Check dependencies
Write-Host "`n Checking Dependencies..." -ForegroundColor Yellow
if (Test-Path "package.json") {
    $packageJson = Get-Content "package.json" | ConvertFrom-Json
    if ($packageJson.scripts.start) {
        Write-Host " Start script defined" -ForegroundColor Green
    } else {
        Write-Host " Start script missing" -ForegroundColor Red
    }
}

# Check Prisma schema
Write-Host "`n Checking Database Configuration..." -ForegroundColor Yellow
if (Test-Path "server/prisma/schema.prisma") {
    Write-Host " Prisma schema exists" -ForegroundColor Green
    $schemaContent = Get-Content "server/prisma/schema.prisma"
    if ($schemaContent -match "provider = \"sqlite\"") {
        Write-Host " SQLite provider configured" -ForegroundColor Green
    } elseif ($schemaContent -match "provider = \"postgresql\"") {
        Write-Host " PostgreSQL provider configured" -ForegroundColor Green
    }
} else {
    Write-Host " Prisma schema missing" -ForegroundColor Red
}

Write-Host "`n Railway Simulation Complete!" -ForegroundColor Cyan
