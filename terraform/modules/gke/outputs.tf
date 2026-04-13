output "cluster_id" {
  value       = google_container_cluster.primary.id
  description = "GKE Cluster ID"
}

output "cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "cluster_endpoint" {
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
  description = "GKE Cluster Endpoint"
}

output "cluster_ca_certificate" {
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
  description = "GKE Cluster CA Certificate (base64 encoded)"
}

output "region" {
  value       = var.region
  description = "GCP region"
}

output "project_id" {
  value       = var.project_id
  description = "GCP Project ID"
}

output "kubectl_config" {
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}"
  description = "Command to configure kubectl"
}
