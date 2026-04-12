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
  
  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "Environment must be development or production."
  }
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

variable "tags" {
  type        = map(string)
  description = "GCP labels/tags"
  default = {
    "created-by" = "terraform"
    "managed-by" = "terraform"
  }
}
