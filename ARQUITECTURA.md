# Arquitectura del Despliegue Automatizado

## Diagrama de Infraestructura

```
┌─────────────────────────────────────────────────────────────────┐
│                      GCP Project                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            VPC Network (10.0.0.0/20)                     │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │                                                            │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │        Subred (10.0.0.0/24)                        │ │  │
│  │  ├────────────────────────────────────────────────────┤ │  │
│  │  │                                                     │ │  │
│  │  │  ┌──────────────────────────────────────────────┐ │ │  │
│  │  │  │   GKE Cluster (dev-gke-cluster)             │ │ │  │
│  │  │  ├──────────────────────────────────────────────┤ │ │  │
│  │  │  │                                              │ │ │  │
│  │  │  │  ┌─────────────┐  ┌─────────────┐          │ │ │  │
│  │  │  │  │   Node 0    │  │   Node 1    │          │ │ │  │
│  │  │  │  │ (n1-std-1)  │  │ (n1-std-1)  │          │ │ │  │
│  │  │  │  └─────────────┘  └─────────────┘          │ │ │  │
│  │  │  │   (Preemptible - cheaper)                  │ │ │  │
│  │  │  │                                              │ │ │  │
│  │  │  │  ┌────────────────────────────────────┐    │ │ │  │
│  │  │  │  │  Kubernetes Pods                    │    │ │ │  │
│  │  │  │  ├────────────────────────────────────┤    │ │ │  │
│  │  │  │  │                                     │    │ │ │  │
│  │  │  │  │  ┌──────────────────────────────┐ │    │ │ │  │
│  │  │  │  │  │  nestjs-api (replicas: 2)   │ │    │ │ │  │
│  │  │  │  │  ├──────────────────────────────┤ │    │ │ │  │
│  │  │  │  │  │                               │ │    │ │ │  │
│  │  │  │  │  │  Pod 1: nestjs-api-xxxxx    │ │    │ │ │  │
│  │  │  │  │  │  Pod 2: nestjs-api-yyyyy    │ │    │ │ │  │
│  │  │  │  │  │  Pod 3: (HPA scale: 2-5)    │ │    │ │ │  │
│  │  │  │  │  │                               │ │    │ │ │  │
│  │  │  │  │  └──────────────────────────────┘ │    │ │ │  │
│  │  │  │  │                                     │    │ │ │  │
│  │  │  │  │  ┌──────────────────────────────┐ │    │ │ │  │
│  │  │  │  │  │  ConfigMaps                  │ │    │ │ │  │
│  │  │  │  │  │  • nestjs-api-config        │ │    │ │ │  │
│  │  │  │  │  │  • LOG_LEVEL=debug          │ │    │ │ │  │
│  │  │  │  │  └──────────────────────────────┘ │    │ │ │  │
│  │  │  │  │                                     │    │ │ │  │
│  │  │  │  │  ┌──────────────────────────────┐ │    │ │ │  │
│  │  │  │  │  │  Secrets                     │ │    │ │ │  │
│  │  │  │  │  │  • DB_PASSWORD (encrypted)  │ │    │ │ │  │
│  │  │  │  │  │  • JWT_SECRET               │ │    │ │ │  │
│  │  │  │  │  └──────────────────────────────┘ │    │ │ │  │
│  │  │  │  │                                     │    │ │ │  │
│  │  │  │  │  Services:                          │    │ │ │  │
│  │  │  │  │  • Service: nestjs-api (ClusterIP) │    │ │ │  │
│  │  │  │  │  • HPA: min=2, max=5               │    │ │ │  │
│  │  │  │  │  • PDB: min_available=1            │    │ │ │  │
│  │  │  │  │                                     │    │ │ │  │
│  │  │  │  └─────────────────────────────────────┘    │ │ │  │
│  │  │  │                                              │ │ │  │
│  │  │  └──────────────────────────────────────────────┘ │ │  │
│  │  │                                                     │ │  │
│  │  └─────────────────────────────────────────────────────┘ │  │
│  │                                                            │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Cloud NAT (para salida a internet)                      │  │
│  │  • IP Estática                                           │  │
│  │  • Ruta default a Cloud NAT                             │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Firewall Rules                                          │  │
│  │  • Allow internal (10.0.0.0/20)                         │  │
│  │  • Allow SSH (22)                                        │  │
│  │  • Allow Kubernetes API (443)                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  IAM Service Accounts                                    │  │
│  │  • gke-nodes-sa (Control plane & nodes)                │  │
│  │  • Permisos necesarios asignados                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  GCS (Google Cloud Storage)                              │  │
│  │  • tfstate-PROJECT_ID-dev (Estado Terraform)            │  │
│  │  • Encriptado y versionado                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│                   Tu Computadora Local                      │
├────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  gcloud CLI                                          │  │
│  │  • Autenticación                                    │  │
│  │  • Gestión de GCP                                   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Terraform                                           │  │
│  │  • Plan                                              │  │
│  │  • Apply                                             │  │
│  │  • Destroy                                           │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  kubectl                                             │  │
│  │  • Pod management                                    │  │
│  │  • Logs & debug                                      │  │
│  │  • Port-forward                                      │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└────────────────────────────────────────────────────────────┘
        ↕ (HTTPS / autenticado)
        │
        └─→ GCP Cloud / GKE Cluster
            └─→ Control Plane + Nodes
                └─→ Kubernetes Pods
                    └─→ nestjs-api containers
```

## Flujo de Despliegue

```
┌─────────────────────────────────────────────────────────────────┐
│  1. INICIO: Ejecutar deploy-dev.sh                              │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  2. Validación                                                   │
│     • gcloud ✓                                                   │
│     • terraform ✓                                               │
│     • kubectl ✓                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  3. Autenticación GCP (gcloud auth login)                       │
│     • Abre navegador                                             │
│     • Confirma credenciales                                     │
│     • Token guardado localmente                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  4. Crear Buckets GCS para estado Terraform                     │
│     • Bucket: tfstate-PROJECT_ID-dev                            │
│     • Versioning: habilitado                                    │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  5. Inicializar Terraform (terraform init)                      │
│     • Descargar providers                                        │
│     • Configurar backend                                        │
│     • Crear .terraform/                                         │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  6. Planificar (terraform plan) - MOSTRAR CAMBIOS               │
│     └─ VPC Network                                              │
│     └─ Firewall                                                 │
│     └─ Cloud NAT                                                │
│     └─ GKE Cluster                                              │
│     └─ Node Pool                                                │
│     └─ IAM Service Accounts                                     │
│     └─ Kubernetes Deployment                                    │
│     └─ Service                                                  │
│     └─ ConfigMap                                                │
│     └─ Secret                                                   │
│     └─ HPA                                                      │
│     └─ Network Policies                                         │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  7. Confirmación: "Do you want to proceed? (yes/no)"            │
│     • Si NO: abortar                                            │
│     • Si SI: continuar                                          │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  8. Aplicar (terraform apply) - CREAR RECURSOS                  │
│     • 10-15 minutos (GKE es lento)                              │
│     • Mostrar progreso                                          │
│     • En paralelo: infraestructura + Kubernetes                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  9. Obtener credenciales del cluster                            │
│     • Descargar kubeconfig                                      │
│     • Guardar en ~/.kube/config                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  10. Configurar kubectl (gcloud container clusters...)          │
│      • kubectl ahora puede conectarse                           │
│      • kubectl get pods                                         │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  11. COMPLETO ✓                                                  │
│      • Véase:                                                    │
│        - kubectl get pods                                        │
│        - kubectl get svc                                         │
│        - kubectl logs -f ...                                     │
│      • Acceder:                                                  │
│        - kubectl port-forward svc/nestjs-api 3000:80            │
│        - http://localhost:3000                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Componentes del Terraform

### Módulos Utilizados

```
terraform/
├── modules/
│   ├── vpc/                          # Red (VPC + Firewall + Cloud NAT)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── gke/                          # Cluster GKE + Node Pool
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam/                          # Service Accounts + IAM
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── kubernetes/                   # Despliegue de aplicación
│       ├── main.tf                   # Deployment + Service + HPA
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/development/
    ├── main.tf                       # Orquestación de módulos
    ├── variables.tf                  # Variables específicas env
    ├── terraform.tfvars              # Valores de desarrollo
    └── backend.tf                    # Backend GCS específico
```

### Variables Principales

```hcl
# terraform/environments/development/terraform.tfvars

gcp_project_id          = "my-project"
gcp_region              = "us-central1"      # Región GCP
environment             = "development"

# GKE Cluster
cluster_name            = "dev-gke-cluster"
kubernetes_version      = "1.28"
node_count              = 2                 # Nodos iniciales
min_node_count          = 1                 # Min para autoscaling
max_node_count          = 3                 # Max para autoscaling
machine_type            = "n1-standard-1"   # Economizar dev
preemptible             = true              # 60% descuento

# Red
network_name            = "nestjs-network"
subnet_cidr             = "10.0.0.0/20"

# Kubernetes Application
app_name                = "nestjs-api"
docker_image            = "ghcr.io/tu-org/imagen:latest"
k8s_replicas            = 2
k8s_resources_requests_cpu    = "100m"
k8s_resources_requests_memory = "256Mi"
k8s_resources_limits_cpu      = "500m"
k8s_resources_limits_memory   = "512Mi"

# Autoscaling Horizontal
enable_hpa              = true
hpa_min_replicas        = 2
hpa_max_replicas        = 5
hpa_cpu_threshold       = 70    # Escalar con 70% CPU
hpa_memory_threshold    = 80    # Escalar con 80% RAM

# Resilencia
enable_pdb              = true
enable_network_policy   = true
```

## Ciclo de Vida de la Infraestructura

```
┌──────────────────────────────────┐
│  Estado 1: No Existe             │
│  • 0 máquinas GCP                │
│  • 0 redes, 0 firewalls          │
│  • 0 K8s pods                    │
└──────────────────────────────────┘
            ↓ terraform apply
            │
┌──────────────────────────────────┐
│  Estado 2: Creating              │
│  (5 min)                          │
│  • VPC Network + Firewall (2min) │
│  • Cloud NAT (1min)              │
│  • GKE Cluster (8-12min)         │
│  • Nodes iniciando (3min)        │
└──────────────────────────────────┘
            ↓ cluster ready
            │
┌──────────────────────────────────┐
│  Estado 3: Ready                 │
│  • Control Plane activo          │
│  • Nodes corriendo               │
│  • Pods desplegados              │
│  • Servicios accesibles          │
└──────────────────────────────────┘
            ↓ terraform destroy
            │
┌──────────────────────────────────┐
│  Estado 1: Destroyed             │
│  • Todos los recursos borrados   │
│  • Cero costos                   │
└──────────────────────────────────┘
```

## Seguridad en Capas

```
                    User (kubectl/local)
                          ↓ mTLS
                    ├─────────────────
                    │
            ┌───────────────────┐
            │  API Server Token │ (autenticación)
            └───────────────────┘
                    ↓ RBAC
            ┌───────────────────┐
            │  Service Account  │ (autorización)
            │  Roles / Bindings │
            └───────────────────┘
                    ↓
            ┌───────────────────┐
            │  Network Policy   │ (aislamiento)
            │  Intra-cluster    │
            └───────────────────┘
                    ↓
            ┌───────────────────┐
            │  Pod Security     │ (contenedores)
            │  runAsNonRoot     │
            │  fsGroup: 1000    │
            └───────────────────┘
                    ↓
            ┌───────────────────┐
            │  Container Image  │ (aplicación)
            │  nestjs-api:vX    │
            └───────────────────┘
                    ↓
┌───────────────────────────────────┐
│  GCP IAM + Workload Identity      │
│  Service Account credentials      │
│  (acceso a recursos GCP)         │
└───────────────────────────────────┘
```

## Costo por Recurso

```
┌─────────────────────────────────────────┐
│  GKE Cluster                    $73/mes  │
├─────────────────────────────────────────┤
│  2x n1-standard-1 (preemptible) $40/mes  │
│  • CPU: 2 vCPU                          │
│  • RAM: 3.75 GB                         │
│  • Descuento: 60% (preemptible)         │
├─────────────────────────────────────────┤
│  GCS Bucket (state)              $0/mes  │
│  • < 1GB almacenado             │  (very cheap)
├─────────────────────────────────────────┤
│  Cloud NAT (outbound traffic)    $0/mes  │
│  • Primera unidad hora gratis    │
│  • Luego: $0.045/hora           │
├─────────────────────────────────────────┤
│  TOTAL (Desarrollo)              ~$110/mes
│  (si se ejecuta 24/7)                   │
└─────────────────────────────────────────┘

Cómo Ahorrar:
└─ Apagar quando no usas (terraform destroy)
└─ Usar preemptible nodes (ya está)
└─ Reducir replicas (1 en lugar de 2)
└─ Usar machine más pequeño (n1-standard-1 ok)
```
