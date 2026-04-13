# Production Environment

# Data source to get access token for GKE
data "google_client_config" "default" {}

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
  preemptible             = false  # Prod: no preemptible (reliability)
  service_account_email   = module.iam.gke_nodes_sa_email
  network_dependency      = module.vpc.subnet_id

  labels = {
    environment = var.environment
    managed-by  = "terraform"
    project     = var.project_name
  }
}

# Kubernetes applications deployment
module "kubernetes_apps" {
  source = "../../modules/kubernetes"

  cluster_endpoint       = module.gke.cluster_endpoint
  cluster_token          = data.google_client_config.default.access_token
  cluster_ca_certificate = module.gke.cluster_ca_certificate
  cluster_dependency     = module.gke.cluster_name

  namespace       = var.k8s_namespace
  create_namespace = var.create_k8s_namespace
  app_name        = var.app_name
  environment     = var.environment
  image           = var.docker_image
  replicas        = var.k8s_replicas

  # Resources
  resources_requests_cpu    = var.k8s_resources_requests_cpu
  resources_requests_memory = var.k8s_resources_requests_memory
  resources_limits_cpu      = var.k8s_resources_limits_cpu
  resources_limits_memory   = var.k8s_resources_limits_memory

  # HPA Configuration
  enable_hpa              = var.enable_hpa
  min_replicas            = var.hpa_min_replicas
  max_replicas            = var.hpa_max_replicas
  hpa_cpu_threshold       = var.hpa_cpu_threshold
  hpa_memory_threshold    = var.hpa_memory_threshold

  # PDB Configuration
  enable_pdb             = var.enable_pdb
  pdb_min_available      = var.pdb_min_available

  # Network Policy
  enable_network_policy  = var.enable_network_policy

  # ConfigMap and Secrets
  config_map_data = var.config_map_data
  secret_data     = var.secret_data

  depends_on = [module.gke]
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

output "kubernetes_app_name" {
  value       = module.kubernetes_apps.deployment_name
  description = "Kubernetes deployment name"
}

output "kubernetes_service_name" {
  value       = module.kubernetes_apps.service_name
  description = "Kubernetes service name"
}

output "kubernetes_service_ip" {
  value       = module.kubernetes_apps.service_ip
  description = "Kubernetes service cluster IP"
}

output "app_url" {
  value       = module.kubernetes_apps.app_url
  description = "Application URL"
}
