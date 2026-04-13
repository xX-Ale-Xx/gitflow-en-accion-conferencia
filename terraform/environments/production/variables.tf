variable "gcp_project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "gcp_region" {
  type        = string
  description = "GCP region (e.g., us-central1, us-east1)"
  default     = "us-central1"
}

variable "environment" {
  type        = string
  description = "Environment name (development, production)"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "nestjs-backend"
}

variable "cluster_name" {
  type        = string
  description = "GKE Cluster Name"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version (e.g., 1.28, 1.29)"
  default     = "1.28"
}

variable "node_count" {
  type        = number
  description = "Initial node count"
  default     = 3
}

variable "min_node_count" {
  type        = number
  description = "Minimum node count for autoscaling"
  default     = 2
}

variable "max_node_count" {
  type        = number
  description = "Maximum node count for autoscaling"
  default     = 10
}

variable "machine_type" {
  type        = string
  description = "Machine type for nodes (e.g., n1-standard-1, n2-standard-4)"
  default     = "n1-standard-1"
}

variable "enable_autoscaling" {
  type        = bool
  description = "Enable autoscaling"
  default     = true
}

variable "network_name" {
  type        = string
  description = "VPC network name"
  default     = "nestjs-network"
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet CIDR range"
  default     = "10.0.0.0/20"
}

# Kubernetes Application Variables
variable "k8s_namespace" {
  type        = string
  description = "Kubernetes namespace for application"
  default     = "production"
}

variable "create_k8s_namespace" {
  type        = bool
  description = "Create namespace if it doesn't exist"
  default     = true
}

variable "app_name" {
  type        = string
  description = "Application name"
  default     = "nestjs-api"
}

variable "docker_image" {
  type        = string
  description = "Docker image URI for the application"
}

variable "k8s_replicas" {
  type        = number
  description = "Number of Kubernetes replicas"
  default     = 3
}

variable "k8s_resources_requests_cpu" {
  type        = string
  description = "CPU request for pods"
  default     = "200m"
}

variable "k8s_resources_requests_memory" {
  type        = string
  description = "Memory request for pods"
  default     = "512Mi"
}

variable "k8s_resources_limits_cpu" {
  type        = string
  description = "CPU limit for pods"
  default     = "1000m"
}

variable "k8s_resources_limits_memory" {
  type        = string
  description = "Memory limit for pods"
  default     = "1Gi"
}

variable "enable_hpa" {
  type        = bool
  description = "Enable HorizontalPodAutoscaler"
  default     = true
}

variable "hpa_min_replicas" {
  type        = number
  description = "Minimum replicas for HPA"
  default     = 3
}

variable "hpa_max_replicas" {
  type        = number
  description = "Maximum replicas for HPA"
  default     = 20
}

variable "hpa_cpu_threshold" {
  type        = number
  description = "CPU threshold for HPA (%)"
  default     = 60
}

variable "hpa_memory_threshold" {
  type        = number
  description = "Memory threshold for HPA (%)"
  default     = 70
}

variable "enable_pdb" {
  type        = bool
  description = "Enable PodDisruptionBudget"
  default     = true
}

variable "pdb_min_available" {
  type        = number
  description = "Minimum available pods in PDB"
  default     = 2
}

variable "enable_network_policy" {
  type        = bool
  description = "Enable network policies"
  default     = true
}

variable "config_map_data" {
  type        = map(string)
  description = "ConfigMap data for application configuration"
  default     = {}
}

variable "secret_data" {
  type        = map(string)
  description = "Secret data for sensitive values"
  sensitive   = true
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "GCP labels/tags"
  default = {
    "created-by" = "terraform"
    "managed-by" = "terraform"
  }
}
