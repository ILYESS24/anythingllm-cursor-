# Secrets Management for AnythingLLM

## Creating Kubernetes Secrets

# Database Secret
kubectl create secret generic anythingllm-secrets \
  --from-literal=database-url="postgresql://username:password@host:5432/database" \
  --from-literal=jwt-secret="your-jwt-secret-key" \
  --from-literal=openai-api-key="your-openai-api-key" \
  --from-literal=anthropic-api-key="your-anthropic-api-key" \
  --namespace=anythingllm-staging

kubectl create secret generic anythingllm-secrets \
  --from-literal=database-url="postgresql://username:password@host:5432/database" \
  --from-literal=jwt-secret="your-jwt-secret-key" \
  --from-literal=openai-api-key="your-openai-api-key" \
  --from-literal=anthropic-api-key="your-anthropic-api-key" \
  --namespace=anythingllm-production

## GitHub Secrets (for CI/CD)

# Required GitHub Secrets:
# - DATABASE_URL
# - JWT_SECRET
# - OPENAI_API_KEY
# - ANTHROPIC_API_KEY
# - KUBECONFIG (base64 encoded)
# - DOCKER_REGISTRY_TOKEN

## Environment Variables Template

# Staging
NODE_ENV=production
ANYTHING_LLM_RUNTIME=docker
DEPLOYMENT_VERSION=1.9.0
DATABASE_URL=${DATABASE_URL}
JWT_SECRET=${JWT_SECRET}
OPENAI_API_KEY=${OPENAI_API_KEY}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}

# Production
NODE_ENV=production
ANYTHING_LLM_RUNTIME=docker
DEPLOYMENT_VERSION=1.9.0
DATABASE_URL=${DATABASE_URL}
JWT_SECRET=${JWT_SECRET}
OPENAI_API_KEY=${OPENAI_API_KEY}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
