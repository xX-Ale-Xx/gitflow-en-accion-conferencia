# Production Environment

module "vpc" {
  source = "../../modules/vpc"

  region       = var.gcp_region
  environment  = var.environment
  network_name = var.network_name
  subnet_cidr  = var.subnet_cidr

  labels = {
    environment = var.environment
    managed-by  = "terraform"
    project     = var.project_name
  }
}

module "iam" {
  source = "../../modules/iam"

  project_id  = var.gcp_project_id
  environment = var.environment

  labels = {
    environment = var.environment
    managed-by  = "terraform"
    project     = var.project_name
  }
}

module "gke" {
  source = "../../modules/gke"

  project_id              = var.gcp_project_id
  region                  = var.gcp_region
  environment             = var.environment
  cluster_name            = var.cluster_name
  kubernetes_version      = var.kubernetes_version
  network_name            = module.vpc.network_name
  subnet_name             = module.vpc.subnet_name
  node_count              = var.node_count
  min_node_count          = var.min_node_count
  max_node_count          = var.max_node_count
  machine_type            = var.machine_type
  preemptible             = false  # Prod uses standard (HA)
  service_account_email   = module.iam.gke_nodes_sa_email
  network_dependency      = module.vpc.subnet_id

  labels = {
    environment = var.environment
    managed-by  = "terraform"
    project     = var.project_name
  }
}

# Outputs
output "cluster_endpoint" {
  value       = module.gke.cluster_endpoint
  sensitive   = true
  description = "GKE cluster endpoint"
}

output "configure_kubectl" {
  value       = module.gke.kubectl_config
  description = "Command to configure kubectl"
}

output "region" {
  value       = var.gcp_region
  description = "GCP region"
}

output "cluster_name" {
  value       = module.gke.cluster_name
  description = "GKE cluster name"
}
