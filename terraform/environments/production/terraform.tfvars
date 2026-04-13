# Production Environment Configuration

# GCP Configuration
gcp_project_id   = "your-gcp-project-id"  # CHANGE THIS
gcp_region       = "us-central1"

# Environment
environment      = "production"
project_name     = "nestjs-backend"
cluster_name     = "prod-gke-cluster"
kubernetes_version = "1.28"

# Node Pool Configuration (Production: más nodos, máquinas más grandes)
node_count     = 3           # Mínimo 3 para producción
min_node_count = 2           # Mínimo con 2
max_node_count = 10          # Máximo 10
machine_type   = "n2-standard-4"  # Máquina más potente para prod

# Network Configuration
network_name = "nestjs-network-prod"
subnet_cidr  = "10.0.0.0/20"

# Kubernetes Application Configuration
k8s_namespace           = "production"
create_k8s_namespace    = true
app_name                = "nestjs-api"
docker_image            = "ghcr.io/your-org/professional-nestjs-backend:latest"  # CHANGE THIS
k8s_replicas            = 3  # Mínimo 3 en prod

# Resources (Producción: más recursos)
k8s_resources_requests_cpu    = "200m"   # Más que dev
k8s_resources_requests_memory = "512Mi"  # Más que dev
k8s_resources_limits_cpu      = "1000m"  # Límite mayor
k8s_resources_limits_memory   = "1Gi"    # Límite mayor

# HPA Configuration (Producción: escalado más agresivo)
enable_hpa            = true
hpa_min_replicas      = 3           # Mínimo 3
hpa_max_replicas      = 20          # Máximo 20
hpa_cpu_threshold     = 60          # Escalar antes (prod es crítico)
hpa_memory_threshold  = 70

# PDB Configuration
enable_pdb       = true
pdb_min_available = 2  # En prod, mínimo 2 siempre disponibles

# Network Policy
enable_network_policy = true

# Application Configuration (ConfigMap)
config_map_data = {
  "LOG_LEVEL"    = "info"          # info, no debug
  "ENVIRONMENT"  = "production"
  "DATABASE_NAME" = "nestjs_prod"
}

# Application Secrets (IMPORTANTE: Cambiar en producción)
secret_data = {
  "DATABASE_HOST"     = "prod-db.example.com"
  "DATABASE_PORT"     = "5432"
  "DATABASE_USER"     = "prod_user"
  "DATABASE_PASSWORD" = "CHANGE-ME-SECURE-PASSWORD"
  "JWT_SECRET"        = "CHANGE-ME-SECURE-JWT-SECRET"
}
