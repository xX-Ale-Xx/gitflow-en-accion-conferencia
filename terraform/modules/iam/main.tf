# Service Account para GKE nodes
resource "google_service_account" "gke_nodes" {
  account_id   = "gke-nodes-${var.environment}"
  display_name = "GKE Nodes Service Account (${var.environment})"

  labels = var.labels
}

# Service Account para GKE cluster
resource "google_service_account" "gke_cluster" {
  account_id   = "gke-cluster-${var.environment}"
  display_name = "GKE Cluster Service Account (${var.environment})"

  labels = var.labels
}

# Roles para GKE nodes
resource "google_project_iam_member" "gke_nodes_roles" {
  for_each = toset([
    "roles/container.nodeServiceAccount",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Roles para GKE cluster
resource "google_project_iam_member" "gke_cluster_roles" {
  for_each = toset([
    "roles/container.developer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_cluster.email}"
}

# Workload Identity Binding para aplicaciones en K8s
resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.gke_nodes.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[kube-system/default]"
}
