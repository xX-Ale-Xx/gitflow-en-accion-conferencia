# Production Environment Configuration

gcp_project_id   = "your-gcp-project-id"  # CHANGE THIS
gcp_region       = "us-east1"             # Different region for HA
environment      = "production"
project_name     = "nestjs-backend"
cluster_name     = "prod-gke-cluster"
kubernetes_version = "1.28"

# Node Pool Configuration
node_count     = 5                    # More nodes for HA
min_node_count = 3                    # Higher minimum
max_node_count = 10                   # Higher maximum
machine_type   = "n2-standard-4"      # More powerful for prod

# Network Configuration
network_name = "nestjs-network"
subnet_cidr  = "10.0.0.0/20"
