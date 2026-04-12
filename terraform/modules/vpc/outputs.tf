output "network_id" {
  value       = google_compute_network.vpc.id
  description = "VPC Network ID"
}

output "network_name" {
  value       = google_compute_network.vpc.name
  description = "VPC Network Name"
}

output "subnet_id" {
  value       = google_compute_subnetwork.subnet.id
  description = "Subnet ID"
}

output "subnet_name" {
  value       = google_compute_subnetwork.subnet.name
  description = "Subnet Name"
}
