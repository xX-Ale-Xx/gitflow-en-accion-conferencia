output "gke_nodes_sa_email" {
  value       = google_service_account.gke_nodes.email
  description = "GKE Nodes Service Account Email"
}

output "gke_nodes_sa_name" {
  value       = google_service_account.gke_nodes.account_id
  description = "GKE Nodes Service Account Name"
}

output "gke_cluster_sa_email" {
  value       = google_service_account.gke_cluster.email
  description = "GKE Cluster Service Account Email"
}
