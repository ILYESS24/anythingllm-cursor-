# Environment Configuration for AnythingLLM CI/CD

## Staging Environment
name: staging
url: https://staging.anythingllm.com
database: postgresql://staging-db:5432/anythingllm_staging

## Production Environment  
name: production
url: https://anythingllm.com
database: postgresql://prod-db:5432/anythingllm_production

## Environment Variables
NODE_ENV=production
ANYTHING_LLM_RUNTIME=docker
DEPLOYMENT_VERSION=1.9.0
JWT_SECRET=${JWT_SECRET}
DATABASE_URL=${DATABASE_URL}
OPENAI_API_KEY=${OPENAI_API_KEY}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
