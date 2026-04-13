output "deployment_name" {
  value       = kubernetes_deployment.app.metadata[0].name
  description = "Deployment name"
}

output "service_name" {
  value       = kubernetes_service.app.metadata[0].name
  description = "Service name"
}

output "service_ip" {
  value       = kubernetes_service.app.spec[0].cluster_ip
  description = "Service cluster IP"
}

output "namespace" {
  value       = kubernetes_service.app.metadata[0].namespace
  description = "Kubernetes namespace"
}

output "app_url" {
  value       = can(kubernetes_service.app.status[0].load_balancer[0].ingress[0].ip) ? kubernetes_service.app.status[0].load_balancer[0].ingress[0].ip : kubernetes_service.app.spec[0].cluster_ip
  description = "Application URL"
}
