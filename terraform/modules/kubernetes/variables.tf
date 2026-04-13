variable "cluster_endpoint" {
  type        = string
  description = "Kubernetes API endpoint"
}

variable "cluster_token" {
  type        = string
  description = "Kubernetes API token"
  sensitive   = true
}

variable "cluster_ca_certificate" {
  type        = string
  description = "Kubernetes cluster CA certificate (base64 encoded)"
  sensitive   = true
}

variable "cluster_dependency" {
  type        = any
  description = "Implicit dependency on cluster creation"
  default     = null
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace"
  default     = "default"
}

variable "create_namespace" {
  type        = bool
  description = "Create namespace if it doesn't exist"
  default     = false
}

variable "app_name" {
  type        = string
  description = "Application name"
  default     = "nestjs-api"
}

variable "environment" {
  type        = string
  description = "Environment (development, staging, production)"
}

variable "image" {
  type        = string
  description = "Container image URI"
}

variable "replicas" {
  type        = number
  description = "Number of replicas"
  default     = 3
}

variable "container_port" {
  type        = number
  description = "Container port"
  default     = 3000
}

variable "service_type" {
  type        = string
  description = "Service type (ClusterIP, LoadBalancer, NodePort)"
  default     = "ClusterIP"
}

variable "service_port" {
  type        = number
  description = "Service port"
  default     = 80
}

variable "image_pull_policy" {
  type        = string
  description = "Image pull policy"
  default     = "IfNotPresent"
}

variable "resources_requests_cpu" {
  type        = string
  description = "CPU request"
  default     = "100m"
}

variable "resources_requests_memory" {
  type        = string
  description = "Memory request"
  default     = "256Mi"
}

variable "resources_limits_cpu" {
  type        = string
  description = "CPU limit"
  default     = "500m"
}

variable "resources_limits_memory" {
  type        = string
  description = "Memory limit"
  default     = "512Mi"
}

variable "readiness_probe_path" {
  type        = string
  description = "Readiness probe path"
  default     = "/health"
}

variable "max_surge" {
  type        = number
  description = "Rolling update max surge"
  default     = 1
}

variable "max_unavailable" {
  type        = number
  description = "Rolling update max unavailable"
  default     = 0
}

variable "enable_hpa" {
  type        = bool
  description = "Enable HorizontalPodAutoscaler"
  default     = true
}

variable "min_replicas" {
  type        = number
  description = "Minimum replicas for HPA"
  default     = 2
}

variable "max_replicas" {
  type        = number
  description = "Maximum replicas for HPA"
  default     = 10
}

variable "hpa_cpu_threshold" {
  type        = number
  description = "CPU threshold for HPA (%)"
  default     = 70
}

variable "hpa_memory_threshold" {
  type        = number
  description = "Memory threshold for HPA (%)"
  default     = 80
}

variable "enable_pdb" {
  type        = bool
  description = "Enable PodDisruptionBudget"
  default     = true
}

variable "pdb_min_available" {
  type        = number
  description = "Minimum available pods in PDB"
  default     = 1
}

variable "enable_network_policy" {
  type        = bool
  description = "Enable network policies"
  default     = true
}

variable "config_map_data" {
  type        = map(string)
  description = "ConfigMap data"
  default     = null
}

variable "secret_data" {
  type        = map(string)
  description = "Secret data (base64 encoded values)"
  sensitive   = true
  default = {
    "DATABASE_URL" = "base64encodedstring"
  }
}
