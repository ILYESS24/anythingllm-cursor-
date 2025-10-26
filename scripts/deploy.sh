#!/bin/bash

# Automated Deployment Script for AnythingLLM
# This script handles deployment to staging and production environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

# Configuration
ENVIRONMENT=${1:-staging}
IMAGE_TAG=${2:-latest}
NAMESPACE="anythingllm-${ENVIRONMENT}"

# Validate environment
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    print_error "Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

print_header "Starting deployment to ${ENVIRONMENT} environment"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

print_status "Connected to Kubernetes cluster"

# Create namespace if it doesn't exist
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    print_status "Creating namespace: $NAMESPACE"
    kubectl create namespace "$NAMESPACE"
else
    print_status "Namespace $NAMESPACE already exists"
fi

# Apply deployment configuration
print_status "Applying deployment configuration for $ENVIRONMENT"
if [[ "$ENVIRONMENT" == "staging" ]]; then
    kubectl apply -f deployment/k8s-staging.yaml
else
    kubectl apply -f deployment/k8s-production.yaml
fi

# Wait for deployment to be ready
print_status "Waiting for deployment to be ready..."
kubectl rollout status deployment/anythingllm-${ENVIRONMENT} -n "$NAMESPACE" --timeout=300s

# Check deployment status
print_status "Checking deployment status..."
kubectl get pods -n "$NAMESPACE" -l app=anythingllm-${ENVIRONMENT}

# Get service information
print_status "Service information:"
kubectl get service -n "$NAMESPACE"

# Health check
print_status "Performing health check..."
SERVICE_NAME="anythingllm-${ENVIRONMENT}-service"
if kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" &> /dev/null; then
    # Get the external IP or use port-forward for testing
    EXTERNAL_IP=$(kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [[ -n "$EXTERNAL_IP" ]]; then
        print_status "Testing health endpoint at http://$EXTERNAL_IP/health"
        if curl -f "http://$EXTERNAL_IP/health" &> /dev/null; then
            print_status "✅ Health check passed"
        else
            print_warning "⚠️ Health check failed - service may still be starting"
        fi
    else
        print_warning "No external IP assigned yet - using port-forward for testing"
        kubectl port-forward service/"$SERVICE_NAME" 8080:80 -n "$NAMESPACE" &
        PORT_FORWARD_PID=$!
        sleep 5
        if curl -f "http://localhost:8080/health" &> /dev/null; then
            print_status "✅ Health check passed via port-forward"
        else
            print_warning "⚠️ Health check failed via port-forward"
        fi
        kill $PORT_FORWARD_PID 2>/dev/null || true
    fi
fi

print_header "Deployment to ${ENVIRONMENT} completed successfully!"
print_status "Environment: $ENVIRONMENT"
print_status "Namespace: $NAMESPACE"
print_status "Image tag: $IMAGE_TAG"

# Display access information
if [[ "$ENVIRONMENT" == "staging" ]]; then
    print_status "Staging URL: https://staging.anythingllm.com"
else
    print_status "Production URL: https://anythingllm.com"
fi
