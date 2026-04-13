# Guía de Despliegue Automatizado - Desarrollo

## Visión General

Este proyecto utiliza **Terraform** para automatizar completamente el despliegue del backend NestJS en **Google Cloud Platform (GCP)** sin necesidad de configuración manual en la consola de GCP.

### ¿Qué se automatiza?

✅ Creación de la infraestructura en GCP (VPC, Firewall, Cloud NAT)  
✅ Provisión del cluster GKE (Kubernetes)  
✅ Configuración de Security Groups y IAM  
✅ Despliegue de la aplicación NestJS en Kubernetes  
✅ Configuración de ConfigMaps y Secrets  
✅ Auto-escalado de pods (HPA)  
✅ Políticas de seguridad de red  
✅ Configuración automática de kubectl  

## Requisitos Previos

### 1. Software Requerido (instalar en orden)

```bash
# Google Cloud SDK
https://cloud.google.com/sdk/docs/install

# Terraform
https://www.terraform.io/downloads

# kubectl (opcional, se instala con gcloud)
gcloud components install kubectl
```

### 2. Cuenta GCP Activa

- Cuenta de Google Cloud activa
- Proyecto GCP creado
- Permisos de propietario o admin del proyecto

### 3. Credenciales Docker (opcional)

Si usas un repositorio Docker privado, configura las credenciales:

```bash
kubectl create secret docker-registry dockercred \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_TOKEN \
  --docker-email=your@email.com
```

## Estructura del Proyecto

```
terraform/
├── provider.tf                    # Configuración de Google Cloud
├── variables.tf                   # Variables globales
├── backend.tf                     # Backend remoto (GCS)
├── modules/
│   ├── vpc/                       # Módulo de red (VPC, Firewall, Cloud NAT)
│   ├── iam/                       # Módulo de identidad (Service Accounts, IAM)
│   ├── gke/                       # Módulo de cluster Kubernetes
│   └── kubernetes/                # Módulo para desplegar apps en K8s
└── environments/
    └── development/
        ├── main.tf                # Configuración de desarrollo
        ├── variables.tf           # Variables específicas de dev
        ├── terraform.tfvars       # Valores para dev
        └── backend.tf             # Backend específico de dev

k8s/
├── deployment.yaml                # Manifiesto del deployment (no usado ahora)
├── service.yaml
├── configmap-secret.yaml
└── ...

deploy-dev.sh                       # Script de automatización (Linux/Mac)
deploy-dev.bat                      # Script de automatización (Windows)
```

## Instrucciones de Uso

### Paso 1: Preparar las Variables

Edita `terraform/environments/development/terraform.tfvars`:

```hcl
gcp_project_id   = "tu-proyecto-gcp"  # ← CAMBIAR
gcp_region       = "us-central1"
docker_image     = "ghcr.io/tu-org/tu-imagen:latest"  # ← CAMBIAR
app_name         = "nestjs-api"
k8s_replicas     = 2
```

### Paso 2: Ejecutar el Script de Automatización

#### En Linux/Mac:

```bash
chmod +x deploy-dev.sh
./deploy-dev.sh
```

#### En Windows (PowerShell):

```powershell
.\deploy-dev.bat
```

#### O manualmente paso a paso:

```bash
# 1. Autenticarse con GCP
gcloud auth login

# 2. Configurar proyecto
gcloud config set project YOUR_PROJECT_ID

# 3. Inicializar Terraform
cd terraform/environments/development
terraform init \
  -backend-config="bucket=tfstate-YOUR_PROJECT_ID-dev" \
  -backend-config="prefix=nestjs-backend/dev"

# 4. Planificar cambios
terraform plan -out=tfplan

# 5. Aplicar cambios
terraform apply tfplan

# 6. Configurar kubectl
gcloud container clusters get-credentials dev-gke-cluster \
  --region us-central1 \
  --project YOUR_PROJECT_ID

# 7. Verificar
kubectl get pods
```

### Paso 3: Verificar el Despliegue

```bash
# Ver pods
kubectl get pods -o wide

# Ver servicios
kubectl get svc

# Ver logs de la aplicación
kubectl logs -l app.kubernetes.io/name=nestjs-api --tail=100 -f

# Acceso local
kubectl port-forward svc/nestjs-api 3000:80
# Luego: http://localhost:3000
```

## Configuración de Aplicación

### Variables de Entorno (ConfigMap)

Se definen en `terraform/environments/development/terraform.tfvars`:

```hcl
config_map_data = {
  "LOG_LEVEL"    = "debug"
  "ENVIRONMENT"  = "development"
  "DATABASE_NAME" = "nestjs_dev"
}
```

### Secretos (Variables Sensibles)

```hcl
secret_data = {
  "DATABASE_HOST"     = "tu-db.example.com"
  "DATABASE_PASSWORD" = "tu-contraseña"
  "JWT_SECRET"        = "tu-jwt-secret"
}
```

⚠️ **IMPORTANTE**: En producción, usa un gestor de secretos como:
- Google Secret Manager
- HashiCorp Vault
- Sealed Secrets

## Personalización

### Cambiar Tamaño de Cluster

En `terraform/environments/development/terraform.tfvars`:

```hcl
# Desarrollo (económico)
node_count     = 2
min_node_count = 1
max_node_count = 3
machine_type   = "n1-standard-1"

# Producción (más potente)
node_count     = 3
min_node_count = 2
max_node_count = 10
machine_type   = "n2-standard-4"
```

### Cambiar Región

```hcl
gcp_region = "us-east1"  # O cualquier otra región
```

### Auto-escalado de Pods

```hcl
enable_hpa           = true
hpa_min_replicas     = 2
hpa_max_replicas     = 5
hpa_cpu_threshold    = 70      # Escalar con 70% CPU
hpa_memory_threshold = 80      # Escalar con 80% Memoria
```

### Recursos de Pod

```hcl
k8s_resources_requests_cpu    = "100m"      # Min requeridos
k8s_resources_requests_memory = "256Mi"
k8s_resources_limits_cpu      = "500m"      # Máx permitidos
k8s_resources_limits_memory   = "512Mi"
```

## Comandos Útiles

### Monitoreo

```bash
# Estado de nodos
kubectl get nodes -o wide

# Estado de pods
kubectl get pods --all-namespaces -o wide

# Eventos del cluster
kubectl get events --sort-by='.lastTimestamp'

# Recursos utilizados
kubectl top nodes
kubectl top pods
```

### Depuración

```bash
# Describir pod
kubectl describe pod <POD_NAME>

# Ver logs
kubectl logs <POD_NAME>

# Ejecutar comando en pod
kubectl exec -it <POD_NAME> -- /bin/bash

# Port-forward
kubectl port-forward pod/<POD_NAME> 3000:3000
```

### Mantenimiento

```bash
# Escalar manualmente
kubectl scale deployment nestjs-api --replicas=5

# Actualizar imagen
kubectl set image deployment/nestjs-api \
  nestjs-api=ghcr.io/tu-org/tu-imagen:v2

# Reiniciar pods
kubectl rollout restart deployment/nestjs-api

# Ver historial de deployments
kubectl rollout history deployment/nestjs-api
```

## Destrucción del Ambiente

⚠️ **Para eliminar TODO (cluster, VPC, etc.)**:

```bash
cd terraform/environments/development
terraform destroy

# O confirmar interactivamente
terraform destroy -auto-approve
```

## Solución de Problemas

### Error: "Terraform initialization failed"

```bash
# Limpiar y reintentar
rm -rf .terraform
rm -f .terraform.lock.hcl
terraform init [opciones de backend]
```

### Error: "Failed to authenticate with GCP"

```bash
# Reintentar login
gcloud auth login --cred-type=user --quiet

# O usar service account
gcloud auth activate-service-account --key-file=/path/to/key.json
```

### Pods en estado "Pending"

```bash
# Ver eventos
kubectl describe pod <POD_NAME>

# Generalmente es falta de recursos
# Reducir replicas o aumentar máquinas
kubectl scale deployment nestjs-api --replicas=1
```

### No puedo acceder a la aplicación

```bash
# 1. Verificar servicio
kubectl get svc nestjs-api

# 2. Port-forward temporal
kubectl port-forward svc/nestjs-api 3000:80

# 3. Acceder a http://localhost:3000
```

### TimeOut en Terraform Apply

- El cluster tarda 10-15 minutos en crear
- Ten paciencia o aumenta el timeout:

```bash
terraform apply -no-color -lock=false -input=false \
  -var="timeout=30m"
```

## Costos Estimados

### Desarrollo (Configuración Actual)

- **GKE Cluster**: ~$70/mes
- **Máquinas (2x n1-standard-1)**: ~$40/mes
- **Almacenamiento**: ~$0.20/mes
- **Ancho de banda**: ~$0-5/mes
- **Total**: ~$110/mes

### Cómo Reducir Costos

1. Usar nodos **preemptible** (dev): 60-70% descuento
2. Reducir número de nodos cuando no usas
3. Usar `n1-standard-1` en lugar de máquinas más grandes
4. Activar auto-scaling para no cargar

## Integración CI/CD

### GitHub Actions

```yaml
name: Deploy to Dev

on:
  push:
    branches: [develop]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      
      - name: Authenticate to GCP
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      
      - name: Deploy
        working-directory: terraform/environments/development
        run: |
          terraform init -backend-config="bucket=tfstate-${{ secrets.GCP_PROJECT_ID }}-dev"
          terraform apply -auto-approve -var="docker_image=${{ env.IMAGE_TAG }}"
```

## Seguridad

✅ Network Policies habilitadas  
✅ Pod Security Policies aplicadas  
✅ Secrets encriptados en etcd  
✅ RBAC habilitado  
✅ Workload Identity activado  
✅ Non-root containers  

### Mejoras de Producción

```hcl
# Usar Google Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"
}

# Usar Sealed Secrets
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Usar Workload Identity
kubectl annotate serviceaccount nestjs-api \
  iam.gke.io/gcp-service-account=sa@project.iam.gserviceaccount.com
```

## Siguientes Pasos

1. ✅ Desplegar en desarrollo con este script
2. ⬜ Crear ambiente de staging (copiar la carpeta `development` a `staging`)
3. ⬜ Crear ambiente de producción (con máquinas más potentes)
4. ⬜ Implementar monitoreo con Prometheus/Grafana
5. ⬜ Configurar backups automáticos
6. ⬜ Implementar Service Mesh (Istio) para tráfico avanzado

## Soporte

- Documentación Terraform: https://www.terraform.io/docs
- GCE Documentation: https://cloud.google.com/docs
- Kubernetes Docs: https://kubernetes.io/docs

---

**¿Preguntas?** Revisa los logs de Terraform:

```bash
TF_LOG=DEBUG terraform apply  # Para debug
```
