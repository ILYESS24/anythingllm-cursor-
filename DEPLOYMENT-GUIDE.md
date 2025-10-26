# 🚀 Guide de Déploiement Complet - AnythingLLM

## 📋 Prérequis

### Outils Requis
- ✅ **Docker** installé et configuré
- ✅ **kubectl** pour Kubernetes
- ✅ **Git** pour le contrôle de version
- ✅ **Node.js 18+** et **Yarn**

### Comptes et Services
- ✅ **GitHub** avec Actions activées
- ✅ **Docker Registry** (GitHub Container Registry)
- ✅ **Cluster Kubernetes** (staging/production)
- ✅ **Base de données PostgreSQL**

## 🔧 Configuration Initiale

### 1. Secrets GitHub
Configurer les secrets suivants dans GitHub Settings > Secrets:

```bash
DATABASE_URL=postgresql://user:pass@host:5432/db
JWT_SECRET=your-super-secret-jwt-key
OPENAI_API_KEY=sk-your-openai-key
ANTHROPIC_API_KEY=your-anthropic-key
KUBECONFIG=base64-encoded-kubeconfig
DOCKER_REGISTRY_TOKEN=your-github-token
```

### 2. Variables d'Environnement
```bash
# Staging
NODE_ENV=production
ANYTHING_LLM_RUNTIME=docker
DEPLOYMENT_VERSION=1.9.0

# Production
NODE_ENV=production
ANYTHING_LLM_RUNTIME=docker
DEPLOYMENT_VERSION=1.9.0
```

## 🚀 Déploiement Automatique

### Pipeline CI/CD
Le pipeline GitHub Actions s'exécute automatiquement sur :
- **Push** vers `main` → Déploiement production
- **Push** vers `develop` → Déploiement staging
- **Pull Request** → Tests et validation

### Jobs du Pipeline
1. **Linting** (2-3 min)
2. **Tests Unitaires** (5-10 min)
3. **Tests d'Intégration** (10-15 min)
4. **Scan Sécurité** (3-5 min)
5. **Build Docker** (15-20 min)
6. **Déploiement** (5-10 min)

## 🐳 Déploiement Docker

### Build Local
```bash
# Build optimisé
docker build -f docker/Dockerfile.optimized -t anythingllm:latest .

# Test de l'image
docker run -d --name anythingllm-test -p 3001:3001 anythingllm:latest

# Health check
curl http://localhost:3001/health
```

### Multi-Architecture
```bash
# Build pour amd64 et arm64
docker buildx build --platform linux/amd64,linux/arm64 -t anythingllm:latest .
```

## ☸️ Déploiement Kubernetes

### Staging
```bash
# Déploiement staging
powershell -ExecutionPolicy Bypass -File scripts/deploy.ps1 -Environment staging

# Ou avec kubectl
kubectl apply -f deployment/k8s-staging.yaml
```

### Production
```bash
# Déploiement production
powershell -ExecutionPolicy Bypass -File scripts/deploy.ps1 -Environment production

# Ou avec kubectl
kubectl apply -f deployment/k8s-production.yaml
```

### Vérification
```bash
# Status des pods
kubectl get pods -n anythingllm-staging
kubectl get pods -n anythingllm-production

# Logs
kubectl logs -f deployment/anythingllm-staging -n anythingllm-staging
```

## 🔍 Monitoring et Maintenance

### Health Checks
- **Endpoint** : `/health`
- **Intervalle** : 1 minute
- **Timeout** : 10 secondes

### Logs
```bash
# Logs en temps réel
kubectl logs -f deployment/anythingllm-production -n anythingllm-production

# Logs avec filtrage
kubectl logs deployment/anythingllm-production -n anythingllm-production --since=1h
```

### Métriques
- **CPU** : 500m-1000m
- **Mémoire** : 1Gi-2Gi
- **Replicas** : 2 (staging), 3 (production)

## 🛠️ Commandes Utiles

### Tests Locaux
```bash
# Test rapide
powershell -ExecutionPolicy Bypass -File scripts/quick-test.ps1

# Simulation complète
powershell -ExecutionPolicy Bypass -File scripts/ci-simulation.ps1 -SkipDocker

# Mise à jour dépendances
node scripts/update-dependencies.js
```

### Déploiement Manuel
```bash
# Staging
kubectl apply -f deployment/k8s-staging.yaml

# Production
kubectl apply -f deployment/k8s-production.yaml

# Rollback
kubectl rollout undo deployment/anythingllm-production -n anythingllm-production
```

### Maintenance
```bash
# Redémarrage
kubectl rollout restart deployment/anythingllm-production -n anythingllm-production

# Scale
kubectl scale deployment anythingllm-production --replicas=5 -n anythingllm-production

# Secrets
kubectl create secret generic anythingllm-secrets --from-literal=key=value -n anythingllm-production
```

## 🚨 Dépannage

### Problèmes Courants

#### Build Docker Échoue
```bash
# Vérifier les permissions
docker system prune -a
docker build -f docker/Dockerfile.optimized -t anythingllm:test .
```

#### Déploiement Kubernetes Échoue
```bash
# Vérifier les ressources
kubectl describe pod <pod-name> -n anythingllm-production

# Vérifier les secrets
kubectl get secrets -n anythingllm-production
```

#### Tests Échouent
```bash
# Réinstaller les dépendances
yarn install
cd frontend && yarn install
cd ../server && yarn install
cd ../collector && yarn install
```

### Logs d'Erreur
```bash
# Logs détaillés
kubectl logs deployment/anythingllm-production -n anythingllm-production --previous

# Events
kubectl get events -n anythingllm-production --sort-by='.lastTimestamp'
```

## 📊 Métriques de Performance

### Temps de Build
- **Frontend** : ~3 minutes
- **Docker** : ~15-20 minutes
- **Pipeline complet** : ~45-60 minutes

### Ressources
- **Staging** : 2 replicas, 512Mi RAM
- **Production** : 3 replicas, 1Gi RAM
- **Scaling** : Auto-scaling configuré

## ✅ Checklist de Déploiement

### Avant Déploiement
- [ ] Tests locaux passent
- [ ] Secrets configurés
- [ ] Cluster Kubernetes accessible
- [ ] Base de données disponible

### Après Déploiement
- [ ] Health check passe
- [ ] Logs sans erreurs
- [ ] Métriques normales
- [ ] Accès web fonctionnel

## 🎯 URLs de Déploiement

- **Staging** : https://staging.anythingllm.com
- **Production** : https://anythingllm.com
- **Health Check** : https://anythingllm.com/health

---

**🎉 Félicitations ! Votre pipeline CI/CD AnythingLLM est maintenant opérationnel !**

**Support** : Consultez les logs GitHub Actions et Kubernetes pour le dépannage.
