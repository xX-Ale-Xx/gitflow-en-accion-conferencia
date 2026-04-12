variable "region" {
  type        = string
  description = "GCP region"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "network_name" {
  type        = string
  description = "VPC network name"
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet CIDR range"
}

variable "labels" {
  type        = map(string)
  description = "GCP labels"
  default     = {}
}
