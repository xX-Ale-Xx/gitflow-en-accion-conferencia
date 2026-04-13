# Development Environment Configuration

# GCP Configuration
gcp_project_id   = "your-gcp-project-id"  # CHANGE THIS
gcp_region       = "us-central1"

# Environment
environment      = "development"
project_name     = "nestjs-backend"
cluster_name     = "dev-gke-cluster"
kubernetes_version = "1.28"

# Node Pool Configuration
node_count     = 2
min_node_count = 1
max_node_count = 3
machine_type   = "n1-standard-1"  # Smaller for dev

# Network Configuration
network_name = "nestjs-network"
subnet_cidr  = "10.0.0.0/20"

# Kubernetes Application Configuration
k8s_namespace           = "default"
create_k8s_namespace    = false
app_name                = "nestjs-api"
docker_image            = "ghcr.io/your-org/professional-nestjs-backend:latest"  # CHANGE THIS
k8s_replicas            = 1

# Resources
k8s_resources_requests_cpu   = "100m"
k8s_resources_requests_memory = "256Mi"
k8s_resources_limits_cpu     = "500m"
k8s_resources_limits_memory  = "512Mi"

# HPA Configuration
enable_hpa            = true
hpa_min_replicas      = 2
hpa_max_replicas      = 5
hpa_cpu_threshold     = 70
hpa_memory_threshold  = 80

# PDB Configuration
enable_pdb       = true
pdb_min_available = 1

# Network Policy
enable_network_policy = true

# Application Configuration (ConfigMap)
config_map_data = {
  "LOG_LEVEL"    = "debug"
  "ENVIRONMENT"  = "development"
  "DATABASE_NAME" = "nestjs_dev"
}

# Application Secrets (IMPORTANT: Use sensitive values and encrypt in production)
secret_data = {
  "DATABASE_HOST"     = "db.example.com"  # Base64 will be encoded by Terraform
  "DATABASE_PORT"     = "5432"
  "DATABASE_USER"     = "postgres"
  "DATABASE_PASSWORD" = "dev-password-change-me"
  "JWT_SECRET"        = "your-jwt-secret-change-me"
}
