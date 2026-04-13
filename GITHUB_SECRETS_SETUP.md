# GitHub Actions - Configuración de Secretos y Despliegue

## 🔐 Secretos Requeridos en GitHub

Para que el pipeline CI/CD funcione, debes agregar los siguientes secretos en GitHub.

### 1. Acceder a Secretos del Repositorio

```
https://github.com/[tu-usuario]/[tu-repo]/settings/secrets/actions
```

### 2. Variables Necesarias

#### A. `GCP_PROJECT_ID` (⚠️ VARIABLE, no secreto)

```
Ir a: https://github.com/[tu-usuario]/[tu-repo]/settings/variables/actions
Agregar:
  Name: GCP_PROJECT_ID
  Value: tu-proyecto-gcp-id
  
Ejemplo: my-gcp-project-123
```

**⚠️ IMPORTANTE:** Es una **VARIABLE** (pública), no un Secreto. El CI/CD la necesita como variable para construir nombres de buckets.

#### B. `GCP_SA_KEY` (⚠️ SECRETO - Service Account Key)

**Crear Service Account en GCP:**

```bash
# 1. Crear service account
gcloud iam service-accounts create github-actions-sa \
  --display-name="GitHub Actions Deployment"

# 2. Asignar permisos necesarios
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/container.admin"  # GKE admin

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.admin"  # Compute admin

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.securityAdmin"  # IAM admin

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/owner"  # O "roles/editor" si "owner" no funciona

# 3. Crear JSON key
gcloud iam service-accounts keys create ~/gha-key.json \
  --iam-account=github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com

# 4. Codificar en base64
cat ~/gha-key.json | base64
```

**Agregar a GitHub:**

```
Settings → Secrets and Variables → Actions → New repository secret

Name: GCP_SA_KEY
Value: [el contenido base64 de gha-key.json]
```

### 3. Resumen de Secretos a Agregar

| Variable | Tipo | ejemplo | Dónde obtenerlo |
|----------|------|---------|-----------------|
| `GCP_PROJECT_ID` | Variable | `my-gcp-project-123` | GCP Console |
| `GCP_SA_KEY` | Secreto | (JSON base64) | Comando `gcloud` arriba |

---

## 🚀 Flujo del Pipeline

### Cuando haces `git push` a `develop` o `main`:

```
┌─────────────────────────────────────┐
│ 1. lint / test / build              │
│ ✓ npm lint                          │
│ ✓ npm test                          │
│ ✓ npm build                         │
│ ✓ docker build & push               │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│ 2. Terraform Provision              │
│ ✓ Autentica con GCP                 │
│ ✓ Init Terraform                    │
│ ✓ Plan cambios                      │
│ ✓ Apply (crea infraestructura)      │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│ 3. Configure kubectl                │
│ ✓ Conecta al cluster GKE            │
│ ✓ Crea namespaces                   │
│ ✓ Verifica conectividad             │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│ ✅ DEPLOY COMPLETADO                │
│                                     │
│ Si es develop → Environment: dev    │
│ Si es main → Environment: prod      │
└─────────────────────────────────────┘
```

---

## 📝 Comportamiento por Rama

### `develop` branch
- Crea/actualiza: `dev-gke-cluster` en `us-central1`
- Namespace: `development`
- Imagen: `ghcr.io/[repo]:develop`
- Estado Terraform: `tfstate-[PROJECT_ID]-dev`

### `main` branch  
- Crea/actualiza: `prod-gke-cluster` en `us-central1`
- Namespace: `production`
- Imagen: `ghcr.io/[repo]:latest`
- Estado Terraform: `tfstate-[PROJECT_ID]-prod`

---

## ✅ Checklist Pre-Deploy

Antes de hacer push, verifica:

- [ ] Service Account creado en GCP
- [ ] Permissions asignados (container.admin, compute.admin, etc.)
- [ ] JSON key generado
- [ ] Base64 del key en GitHub Secrets como `GCP_SA_KEY`
- [ ] `GCP_PROJECT_ID` en GitHub Variables
- [ ] `terraform.tfvars` para development actualizado
- [ ] `terraform.tfvars` para production creado (opcional)
- [ ] `.github/workflows/ci-cd.yml` actualizado con Terraform

---

## 🔍 Debug

### Ver logs del deploy en GitHub
```
1. Ir a: https://github.com/[owner]/[repo]/actions
2. Seleccionar el workflow que falló
3. Click en el job "deploy"
4. Expandir cada step para ver logs
```

### Troubleshooting

**Error: "GCP_SA_KEY not found"**
- Verificar que el secreto está en la sección correcta (Settings → Secrets)
- Nombre debe ser exactamente `GCP_SA_KEY`

**Error: "Bucket already exists"**
- Terraform intenta crear buckets que ya existen
- Es normal, Terraform debería ignorarlos

**Error: "pods are pending"**
```bash
# Loguear manualmente al cluster y verificar
gcloud container clusters get-credentials dev-gke-cluster \
  --region us-central1 \
  --project YOUR_PROJECT_ID

kubectl get pods -A
kubectl describe pod <pod-name>
```

**Error: "terraform: command not found"**
- El action de setup-terraform no se ejecutó correctamente
- Revisar que está instalando versión latest

---

## 🔒 Seguridad

### Recomendaciones
1. **Service Account limitado**: No usar "Owner", usar permisos mínimos necesarios
2. **Rotar keys regularmente**: Cambiar keys cada 90 días
3. **No commitear secrets**: `.env`, `gha-key.json` siempre en `.gitignore`
4. **Audit logs**: Revisar GCP audit logs regularmente
5. **Branch protection**: Requerir PR reviews antes de merge a `main`

### Revocar acceso rápidamente
```bash
# Si comprometes el key:
gcloud iam service-accounts keys delete KEY_ID \
  --iam-account=github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

---

## 📞 Comandos Útiles

```bash
# Ver estado del último deploy
gcloud container clusters get-credentials dev-gke-cluster --region us-central1 --project YOUR_PROJECT_ID
kubectl get all -A

# Ver logs de un pod
kubectl logs -l app.kubernetes.io/name=nestjs-api -f

# Escalar deployment
kubectl scale deployment nestjs-api --replicas=5 -n development

# Ver eventos
kubectl get events -A --sort-by='.lastTimestamp'

# Limpiar recursos (destruir)
cd terraform/environments/development
terraform destroy -auto-approve
```

---

## 📖 Documentación de Referencia

- Terraform Google Provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- GitHub Actions Secrets: https://docs.github.com/en/actions/security-guides/encrypted-secrets
- GCP Service Accounts: https://cloud.google.com/iam/docs/service-accounts
- GKE: https://cloud.google.com/kubernetes-engine/docs
