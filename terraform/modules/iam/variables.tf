variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "labels" {
  type        = map(string)
  description = "GCP labels"
  default     = {}
}
