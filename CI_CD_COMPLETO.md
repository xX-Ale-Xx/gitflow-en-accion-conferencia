# CI/CD Pipeline Completo - Guía Final

## ✅ Estado Actual

**TODO está configurado y listo para funcionar.**

### ¿Qué sucede al hacer push?

```
git push origin develop          git push origin main
        ↓                              ↓
    ┌───────────────────────────────────────────┐
    │  GitHub Actions Workflow Trigger         │
    │  (.github/workflows/ci-cd.yml)           │
    └───────────────────────────────────────────┘
                        ↓
    ┌───────────────────────────────────────────┐
    │  1. LINT & TEST (5 min)                   │
    │  • npm lint                               │
    │  • npm test + coverage                    │
    │  • SonarQube analysis                     │
    └───────────────────────────────────────────┘
                        ↓
    ┌───────────────────────────────────────────┐
    │  2. BUILD & PUSH (3 min)                  │
    │  • npm build                              │
    │  • Docker build                           │
    │  • Push to ghcr.io (GitHub Container)    │
    │  • Tags: branch, sha, semver             │
    └───────────────────────────────────────────┘
                        ↓
    ┌───────────────────────────────────────────┐
    │  3. INFRASTRUCTURE (Terraform)            │
    │  • Auth con GCP                           │
    │  • terraform init                         │
    │  • terraform plan                         │
    │  • terraform apply ← CREA TODO EN GCP    │
    │                                           │
    │  DEVELOP → dev-gke-cluster                │
    │  MAIN → prod-gke-cluster                  │
    └───────────────────────────────────────────┘
                        ↓
    ┌───────────────────────────────────────────┐
    │  4. DEPLOY & VERIFY (2 min)               │
    │  • Configure kubectl                      │
    │  • Create namespace                       │
    │  • Verify cluster connectivity            │
    │                                           │
    │  ✅ DEPLOYMENT COMPLETE                   │
    └───────────────────────────────────────────┘

Total: ~15-20 minutos
```

---

## 🚀 Paso a Paso - Qué Hacer Ahora

### 1️⃣ Crear Service Account en GCP

```bash
# Reemplaza YOUR_PROJECT_ID con tu proyecto real
export PROJECT_ID="your-gcp-project-id"

# 1.1. Crear service account
gcloud iam service-accounts create github-actions-sa \
  --display-name="GitHub Actions Deployment" \
  --project=$PROJECT_ID

# 1.2. Asignar permisos
for role in container.admin compute.admin iam.securityAdmin; do
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/$role"
done

# 1.3. Crear JSON key
gcloud iam service-accounts keys create gha-key.json \
  --iam-account=github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --project=$PROJECT_ID

# 1.4. Convertir a base64
cat gha-key.json | base64 > gha-key.base64

# ⚠️ GUARDAR el contenido base64 para el siguiente paso
cat gha-key.base64
```

### 2️⃣ Agregar Secretos a GitHub

Ir a: `https://github.com/[tu-usuario]/[tu-repo]/settings/secrets/actions`

**Agregar estas variables:**

| Tipo | Nombre | Valor |
|------|--------|-------|
| Variable | `GCP_PROJECT_ID` | `your-gcp-project-id` |
| Secreto | `GCP_SA_KEY` | (contenido base64 de gha-key.json) |

**Pasos en GitHub:**

```
1. Settings → Secrets and Variables → Actions
2. Click "New repository variable"
   - Name: GCP_PROJECT_ID
   - Value: your-gcp-project-id
   
3. Click "New repository secret"
   - Name: GCP_SA_KEY
   - Value: (pegar el contenido base64)
```

### 3️⃣ Actualizar terraform.tfvars

**Para development:**
```bash
# terraform/environments/development/terraform.tfvars
gcp_project_id = "your-gcp-project-id"
docker_image   = "ghcr.io/your-org/professional-nestjs-backend:latest"
```

**Para production:**
```bash
# terraform/environments/production/terraform.tfvars
gcp_project_id = "your-gcp-project-id"
docker_image   = "ghcr.io/your-org/professional-nestjs-backend:latest"
```

### 4️⃣ Hacer Push

```bash
# Crear rama feature/develop/bugfix
git checkout -b feature/mi-feature develop

# Hacer cambios
echo "Cambios locales"

# Commit
git add .
git commit -m "feat: mi nueva feature"

# Push a develop
git push origin feature/mi-feature

# Crear PR
# GitHub te ofrece un link para crear PR
# Merge a develop

# ↓ Trigger 1: Push a develop
# Terraform crea dev-gke-cluster
# Deployment automático a development

git checkout main
git merge develop

# ↓ Trigger 2: Push a main (con tag)
# Terraform crea prod-gke-cluster
# Deployment automático a production
```

---

## 📊 Flujo de Ramas (Gitflow)

```
                    ┌─ feature/auth
                   /
    main ─ develop ┼─ feature/users
    │         │    \
    │         │     └─ bugfix/security
    ↓         ↓
   PROD      DEV
   (prod-    (dev-
   gke-      gke-
  cluster)  cluster)
```

---

## 🔍 Verificaciones Antes de Push

### ✅ Checklist

- [ ] Código pasa lint: `npm run lint`
- [ ] Tests pasan: `npm run test`
- [ ] Build funciona: `npm run build`
- [ ] Docker builds: `docker build -t test .`
- [ ] No hay secrets en código
- [ ] `.env` está en `.gitignore`
- [ ] `gha-key.json` está en `.gitignore`
- [ ] GitHub secrets configurados (GCP_SA_KEY, GCP_PROJECT_ID)
- [ ] `terraform.tfvars` tiene proyecto correcto

### Verificar Localmente

```bash
# Lint
npm run lint

# Tests
npm run test:cov

# Build NestJS
npm run build

# Docker
docker build -t nestjs-backend:test .

# Terraform (opcional)
cd terraform/environments/development
terraform validate
terraform plan
```

---

## 📈 Monitoreo del Despliegue

### Ver logs en GitHub

```
https://github.com/[owner]/[repo]/actions
→ Selecciona el workflow ejecutándose
→ Click en "deploy" job
→ Expande cada step
```

### Logs Específicos

```bash
# Ver último evento
gcloud container operations list --project=YOUR_PROJECT_ID

# Ver pods desplegados
gcloud container clusters get-credentials dev-gke-cluster \
  --region us-central1 \
  --project=YOUR_PROJECT_ID

kubectl get pods -A
kubectl get svc -A
kubectl logs -l app.kubernetes.io/name=nestjs-api -f -n development
```

---

## 🎯 Qué Se Crea Automáticamente

### En `develop` → **DEVELOPMENT**

```
GCP Project
├── VPC: nestjs-network (10.0.0.0/20)
├── GKE: dev-gke-cluster
│   ├── 2 nodos n1-standard-1 (preemptible)
│   ├── Auto-escalado 1-3 nodos
│   └── Kubernetes deployment
│       ├── nestjs-api (2-5 replicas)
│       ├── ConfigMap
│       ├── Secret
│       ├── Service
│       └── HPA + PDB
├── Firewall rules
├── Cloud NAT
├── GCS Bucket: tfstate-PROJECT_ID-dev
└── Permisos IAM
```

### En `main` → **PRODUCTION**

```
GCP Project
├── VPC: nestjs-network-prod (10.0.0.0/20)
├── GKE: prod-gke-cluster
│   ├── 3 nodos n2-standard-4 (NO preemptible)
│   ├── Auto-escalado 2-10 nodos
│   └── Kubernetes deployment
│       ├── nestjs-api (3-20 replicas)
│       ├── ConfigMap
│       ├── Secret
│       ├── Service
│       └── HPA (más agresivo) + PDB
├── Firewall rules
├── Cloud NAT
├── GCS Bucket: tfstate-PROJECT_ID-prod
└── Permisos IAM
```

---

## 🚨 Troubleshooting

### Error: "GitHub Actions no se ejecuta"

```
Causas:
1. Workflow file tiene errores YAML
2. Rama no es develop ni main
3. Repository variable/secret no está configurado

Soluciones:
• Verificar .github/workflows/ci-cd.yml sintaxis
• Push debe ser a develop o main
• Ir a Settings → Secrets and check GCP_SA_KEY
```

### Error: "terraform init failed"

```
Causas:
1. GCP_SA_KEY incorrecto
2. GCS bucket no existe
3. Permisos insuficientes

Soluciones:
• Verificar base64 encoding
• El bucket SE CREA automáticamente si no existe
• Revisar permisos del Service Account
```

### Error: "pods en Pending"

```bash
# Ver qué está pasando
kubectl describe pod [pod-name] -n development

# Si es "Image pull failed"
kubectl get events -n development

# Si es recursos insuficientes
kubectl top nodes
kubectl scale deployment nestjs-api --replicas=1 -n development
```

### Error: "No puedo acceder a la app"

```bash
# Ver servicio
kubectl get svc nestjs-api -n development

# Port-forward temporal
kubectl port-forward svc/nestjs-api 3000:80 -n development

# Acceder a http://localhost:3000
```

---

## 💾 Backup de Configuración

### Guardar estado actual

```bash
# Backup de Terraform
cd terraform/environments/development
terraform state pull > terraform.state.backup

# Backup de secrets (⚠️ MANEJAR CON CUIDADO)
# NUNCA commitear en git, guardar en lugar seguro
kubectl get secrets -n development -o yaml > secrets.backup.yaml
```

---

## 🔄 Ciclo de Vida Típico

### Día 1: Setup Inicial
```bash
1. Crear Service Account en GCP
2. Agregar secretos a GitHub
3. Push a develop
   → GitHub Actions ejecuta
   → Terraform crea dev-gke-cluster
   → Despliegue exitoso ✅
```

### Día 2+: Desarrollo Normal
```bash
1. Feature branch desde develop
   git checkout -b feature/algo develop

2. Hacer cambios
   code src/
   git add .
   git commit -m "feat: ..."

3. Push a GitHub
   git push origin feature/algo

4. GitHub Actions:
   - Lint ✓
   - Test ✓
   - Build ✓
   
5. Merge a develop
   git pull origin develop
   git merge feature/algo
   git push origin develop
   
6. GitHub Actions (deploy a dev):
   - Terraform plan
   - Terraform apply
   - Deployment ✓

7. Merge a main (release)
   git checkout main
   git merge develop
   git tag v1.0.0
   git push origin main --tags
   
8. GitHub Actions (deploy a prod):
   - Terraform plan
   - Terraform apply
   - Deployment ✓
```

---

## 📝 Variables de Entorno

### ConfigMap en Development
```hcl
config_map_data = {
  "LOG_LEVEL"    = "debug"
  "ENVIRONMENT"  = "development"
  "DATABASE_NAME" = "nestjs_dev"
}
```

### ConfigMap en Production
```hcl
config_map_data = {
  "LOG_LEVEL"    = "info"
  "ENVIRONMENT"  = "production"
  "DATABASE_NAME" = "nestjs_prod"
}
```

### Modificar Variables

```bash
# Editar terraform.tfvars
vim terraform/environments/development/terraform.tfvars

# Push para desplegar cambios
git add terraform/environments/development/terraform.tfvars
git commit -m "chore: update dev config"
git push origin develop
# ↓ Automáticamente actualiza en GCP
```

---

## ✨ Ventajas de Esta Arquitectura

✅ **Infraestructura como Código**: Todo versionado en Git
✅ **Automatización Completa**: De desarrollo a deployment
✅ **Reproducibilidad**: Mismo resultado siempre
✅ **Escalabilidad**: Manual o automática con HPA
✅ **Seguridad**: Secrets encriptados, Network Policies
✅ **Multi-ambiente**: Dev y Prod con configuraciones diferentes
✅ **Observabilidad**: Logs, eventos, métricas

---

## 🎓 Próximos Pasos (Recomendado)

1. ✅ **Completada**: Configuración Terraform
2. ⬜ **Siguiente**: Integración de Monitoring (Prometheus/Grafana)
3. ⬜ **Luego**: Backups automáticos
4. ⬜ **Después**: Service Mesh (Istio)
5. ⬜ **Finalmente**: Multi-region deployment

---

## 📞 Resumen Rápido

| Qué necesitas | Dónde está |
|--------------|-----------|
| Iniciar deployment | `git push origin develop` |
| Ver logs | GitHub Actions → workflow |
| Acceder a app | `kubectl port-forward svc/nestjs-api 3000:80` |
| Cambiar config | Editar `terraform/environments/*/terraform.tfvars` |
| Destruir env | `terraform destroy -auto-approve` |
| Admin cluster | `gcloud container clusters get-credentials ...` |

---

## 🏁 ¡LISTO!

**Ahora solo tienes que:**

1. Crear Service Account en GCP (5 min)
2. Agregar secrets a GitHub (2 min)
3. Hacer `git push` (automático)

**¿Dudas? Revisa:**
- `GITHUB_SECRETS_SETUP.md` - Configuración de secretos
- `DESPLIEGUE_AUTOMATIZADO.md` - Guía Terraform
- `.github/workflows/ci-cd.yml` - Workflow actual
