# PowerShell Deployment Script for AnythingLLM

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("staging", "production")]
    [string]$Environment,
    
    [string]$ImageTag = "latest",
    
    [switch]$DryRun
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

function Write-Header {
    param([string]$Message)
    Write-Host "[DEPLOY] $Message" -ForegroundColor $Blue
}

# Configuration
$Namespace = "anythingllm-$Environment"

Write-Header "Starting deployment to $Environment environment"

# Check if kubectl is available
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Error "kubectl is not installed or not in PATH"
    exit 1
}

# Check if cluster is accessible
try {
    kubectl cluster-info | Out-Null
    Write-Status "Connected to Kubernetes cluster"
}
catch {
    Write-Error "Cannot connect to Kubernetes cluster"
    exit 1
}

# Create namespace if it doesn't exist
try {
    kubectl get namespace $Namespace | Out-Null
    Write-Status "Namespace $Namespace already exists"
}
catch {
    Write-Status "Creating namespace: $Namespace"
    kubectl create namespace $Namespace
}

# Apply deployment configuration
Write-Status "Applying deployment configuration for $Environment"
if ($Environment -eq "staging") {
    $ConfigFile = "deployment/k8s-staging.yaml"
} else {
    $ConfigFile = "deployment/k8s-production.yaml"
}

if ($DryRun) {
    Write-Status "Dry run mode - would apply: $ConfigFile"
    kubectl apply -f $ConfigFile --dry-run=client
} else {
    kubectl apply -f $ConfigFile
}

# Wait for deployment to be ready
if (-not $DryRun) {
    Write-Status "Waiting for deployment to be ready..."
    kubectl rollout status deployment/anythingllm-$Environment -n $Namespace --timeout=300s
    
    # Check deployment status
    Write-Status "Checking deployment status..."
    kubectl get pods -n $Namespace -l app=anythingllm-$Environment
    
    # Get service information
    Write-Status "Service information:"
    kubectl get service -n $Namespace
    
    # Health check
    Write-Status "Performing health check..."
    $ServiceName = "anythingllm-$Environment-service"
    
    try {
        $Service = kubectl get service $ServiceName -n $Namespace -o json | ConvertFrom-Json
        $ExternalIP = $Service.status.loadBalancer.ingress[0].ip
        
        if ($ExternalIP) {
            Write-Status "Testing health endpoint at http://$ExternalIP/health"
            try {
                $Response = Invoke-WebRequest -Uri "http://$ExternalIP/health" -UseBasicParsing -TimeoutSec 10
                if ($Response.StatusCode -eq 200) {
                    Write-Status "✅ Health check passed"
                } else {
                    Write-Warning "⚠️ Health check failed - service may still be starting"
                }
            }
            catch {
                Write-Warning "⚠️ Health check failed: $($_.Exception.Message)"
            }
        } else {
            Write-Warning "No external IP assigned yet - using port-forward for testing"
            $PortForward = Start-Process kubectl -ArgumentList "port-forward", "service/$ServiceName", "8080:80", "-n", $Namespace -PassThru -WindowStyle Hidden
            Start-Sleep 5
            
            try {
                $Response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 10
                if ($Response.StatusCode -eq 200) {
                    Write-Status "✅ Health check passed via port-forward"
                } else {
                    Write-Warning "⚠️ Health check failed via port-forward"
                }
            }
            catch {
                Write-Warning "⚠️ Health check failed via port-forward: $($_.Exception.Message)"
            }
            finally {
                Stop-Process -Id $PortForward.Id -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-Warning "Could not perform health check: $($_.Exception.Message)"
    }
}

Write-Header "Deployment to $Environment completed successfully!"
Write-Status "Environment: $Environment"
Write-Status "Namespace: $Namespace"
Write-Status "Image tag: $ImageTag"

# Display access information
if ($Environment -eq "staging") {
    Write-Status "Staging URL: https://staging.anythingllm.com"
} else {
    Write-Status "Production URL: https://anythingllm.com"
}
