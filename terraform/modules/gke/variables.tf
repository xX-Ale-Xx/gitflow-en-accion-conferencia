variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "cluster_name" {
  type        = string
  description = "GKE Cluster name"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.28"
}

variable "network_name" {
  type        = string
  description = "VPC network name"
}

variable "subnet_name" {
  type        = string
  description = "VPC subnet name"
}

variable "node_count" {
  type        = number
  description = "Initial node count"
  default     = 3
}

variable "min_node_count" {
  type        = number
  description = "Minimum nodes for autoscaling"
  default     = 2
}

variable "max_node_count" {
  type        = number
  description = "Maximum nodes for autoscaling"
  default     = 10
}

variable "machine_type" {
  type        = string
  description = "Machine type for nodes"
  default     = "n1-standard-1"
}

variable "preemptible" {
  type        = bool
  description = "Use preemptible VMs (cheaper, can be preempted)"
  default     = false
}

variable "service_account_email" {
  type        = string
  description = "Service account email for nodes"
}

variable "cluster_secondary_range_name" {
  type        = string
  description = "Secondary IP range name for cluster IPs"
  default     = "10.4.0.0/14"
}

variable "labels" {
  type        = map(string)
  description = "GCP labels"
  default     = {}
}

variable "network_dependency" {
  type        = any
  description = "Dependency on network resources"
  default     = null
}
