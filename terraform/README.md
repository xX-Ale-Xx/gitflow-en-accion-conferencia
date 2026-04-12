# Terraform - Infrastructure as Code for GCP

Provisiona **Google Kubernetes Engine (GKE)** completo con **dos ambientes separados**: Development y Production.

## 📋 Estructura

```
terraform/
├── provider.tf                          ← Google Cloud provider
├── variables.tf                         ← Variables globales
├── backend.tf                           ← GCS backend (state)
│
├── modules/
│   ├── vpc/                             ← VPC Network + Subnet + Cloud NAT
│   ├── iam/                             ← Service Accounts + IAM Roles
│   └── gke/                             ← GKE Cluster + Node Pool
│
└── environments/
    ├── development/                     ← Variables DEV
    │   ├── backend.tf                   ← GCS bucket: dev-tfstate-bucket
    │   ├── main.tf                      ← Llamadas a módulos
    │   └── terraform.tfvars             ← Valores DEV
    │
    └── production/                      ← Variables PROD
        ├── backend.tf                   ← GCS bucket: prod-tfstate-bucket
        ├── main.tf                      ← Llamadas a módulos
        └── terraform.tfvars             ← Valores PROD
```

## 🔧 Setup Inicial

### 1. Crear GCS Buckets para State

```bash
# Development state bucket
gsutil mb -p your-gcp-project-id gs://dev-tfstate-bucket
gsutil versioning set on gs://dev-tfstate-bucket

# Production state bucket
gsutil mb -p your-gcp-project-id gs://prod-tfstate-bucket
gsutil versioning set on gs://prod-tfstate-bucket

# Habilitar versionado y crear bloqueos
gsutil uniform-bucket-level-access set on gs://dev-tfstate-bucket
gsutil uniform-bucket-level-access set on gs://prod-tfstate-bucket
```

### 2. Configurar Google Cloud SDK

```bash
gcloud auth login
gcloud config set project your-gcp-project-id
```

## 🚀 Deployment Development

```bash
cd terraform/environments/development

# 1. Editar terraform.tfvars
# Cambiar: gcp_project_id = "your-gcp-project-id"

# 2. Inicializar Terraform
terraform init

# 3. Validar configuración
terraform validate

# 4. Ver plan (qué va a crear)
terraform plan -var-file="terraform.tfvars" -out=tfplan

# 5. Aplicar (crear infraestructura)
terraform apply tfplan

# 6. Obtener credenciales de kubectl
gcloud container clusters get-credentials dev-gke-cluster --zone us-central1-a --project your-gcp-project-id

# 7. Verificar
kubectl get nodes
```

## 🏢 Deployment Production

```bash
cd terraform/environments/production

# 1. Editar terraform.tfvars
# Cambiar: gcp_project_id = "your-gcp-project-id"

# 2. Inicializar Terraform
terraform init

# 3. Ver plan
terraform plan -var-file="terraform.tfvars" -out=tfplan

# 4. Aplicar (crear infraestructura)
terraform apply tfplan

# 5. Obtener credenciales
gcloud container clusters get-credentials prod-gke-cluster --zone us-east1-b --project your-gcp-project-id

# 6. Verificar
kubectl get nodes
```

## 🔄 Escalar Nodos

### Development: Aumentar nodos

```bash
cd terraform/environments/development

# Editar terraform.tfvars:
# node_count = 2        → node_count = 4
# max_node_count = 3    → max_node_count = 5

terraform plan -var-file="terraform.tfvars"
terraform apply -auto-approve
```

### Production: Cambiar machine type

```bash
cd terraform/environments/production

# Editar terraform.tfvars:
# machine_type = "n2-standard-4" → "n2-highmem-8"

terraform plan -var-file="terraform.tfvars"
terraform apply -auto-approve
```

## 📊 Comparativa Dev vs Prod

| Aspecto | Development | Production |
|--------|-------------|-----------|
| **Region** | us-central1 | us-east1 |
| **Nodos Iniciales** | 2 | 5 |
| **Nodos Mínimos** | 1 | 3 |
| **Nodos Máximos** | 3 | 10 |
| **Machine Type** | n1-standard-1 | n2-standard-4 |
| **Preemptible** | Sí (barato) | No (HA) |
| **State Bucket** | dev-tfstate-bucket | prod-tfstate-bucket |
| **Cost/mes aprox.** | $50-100 | $200-300 |

## 🗑️ Eliminar Infraestructura

### ⚠️ DESTRUIR DEVELOPMENT

```bash
cd terraform/environments/development
terraform destroy -var-file="terraform.tfvars"
```

### ⚠️ DESTRUIR PRODUCTION

```bash
cd terraform/environments/production
terraform destroy -var-file="terraform.tfvars"
```

## 🔐 Seguridad

### Lo que incluye Terraform:

✅ **VPC**: Red privada aislada  
✅ **Cloud NAT**: NAT gateway para pods sin IP pública  
✅ **Service Accounts**: Identidades con permisos mínimos (least privilege)  
✅ **Workload Identity**: Pods pueden acceder a GCP APIs seguramente  
✅ **Network Policy**: Restricciones de tráfico entre pods  
✅ **Shielded GKE**: Secure Boot + Integrity Monitoring  
✅ **Monitoring**: Logging y Monitoring automático  

### Recomendaciones Adicionales:

1. **Habilitar Binary Authorization** (verificar imágenes firmadas)
2. **Cloud Armor** (DDoS protection)
3. **VPC Service Controls** (aislamiento de datos)
4. **Backup de etcd** con Cloud Snapshots

## 🔧 Troubleshooting

### Error: "Quota exceeded"
```bash
# Aumentar quota en Google Cloud Console:
# APIs & Services → Quotas → Seleccionar recurso
```

### Error: "Permission denied"
```bash
# Verificar roles del usuario:
gcloud projects get-iam-policy your-gcp-project-id
# Agregar rol: roles/container.admin, roles/compute.admin
```

### No se crea el cluster
```bash
# Ver logs de Terraform
terraform apply -var-file="terraform.tfvars" -lock=false

# O revisar recursos en Google Cloud Console
gcloud container clusters list
```

## 📚 Recursos Útiles

- [Google Cloud Terraform Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Terraform Best Practices](https://www.terraform.io/language)

## 🔑 Variables por Ambiente

### Development (terraform.tfvars)
```hcl
gcp_project_id   = "your-project-id"
gcp_region       = "us-central1"
environment      = "development"
node_count       = 2
machine_type     = "n1-standard-1"
max_node_count   = 3
```

### Production (terraform.tfvars)
```hcl
gcp_project_id   = "your-project-id"
gcp_region       = "us-east1"
environment      = "production"
node_count       = 5
machine_type     = "n2-standard-4"
max_node_count   = 10
```

---

**Nota**: Cambiar `your-gcp-project-id` por tu proyecto real en GCP.

