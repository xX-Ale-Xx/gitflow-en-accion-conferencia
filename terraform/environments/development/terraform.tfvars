# Development Environment Configuration

gcp_project_id   = "your-gcp-project-id"  # CHANGE THIS
gcp_region       = "us-central1"
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
