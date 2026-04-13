terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "kubernetes" {
  host                   = "https://${var.cluster_endpoint}"
  token                  = var.cluster_token
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

provider "kubectl" {
  host                   = "https://${var.cluster_endpoint}"
  token                  = var.cluster_token
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  load_config_file       = false
}

# Crear namespace si es necesario
resource "kubernetes_namespace" "app" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = var.app_name
      "app.kubernetes.io/environment" = var.environment
    }
  }

  depends_on = [var.cluster_dependency]
}

# ConfigMap para configuración de la aplicación
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "${var.app_name}-config"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = var.app_name
      "app.kubernetes.io/environment" = var.environment
    }
  }

  data = var.config_map_data != null ? var.config_map_data : {
    "LOG_LEVEL"  = "info"
    "ENVIRONMENT" = var.environment
  }

  depends_on = [
    var.create_namespace ? kubernetes_namespace.app[0] : null
  ]
}

# Secret para datos sensibles
resource "kubernetes_secret" "app_secrets" {
  metadata {
    name      = "${var.app_name}-secrets"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = var.app_name
      "app.kubernetes.io/environment" = var.environment
    }
  }

  type = "Opaque"
  data = var.secret_data

  depends_on = [
    var.create_namespace ? kubernetes_namespace.app[0] : null
  ]
}

# ServiceAccount
resource "kubernetes_service_account" "app" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = var.app_name
      "app.kubernetes.io/environment" = var.environment
    }
  }

  depends_on = [
    var.create_namespace ? kubernetes_namespace.app[0] : null
  ]
}

# Deployment
resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = var.app_name
      "app.kubernetes.io/environment" = var.environment
    }
  }

  spec {
    replicas = var.replicas

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = var.max_surge
        max_unavailable = var.max_unavailable
      }
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"       = var.app_name
          "app.kubernetes.io/environment" = var.environment
        }
      }

      spec {
        service_account_name            = kubernetes_service_account.app.metadata[0].name
        automount_service_account_token = true

        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          fs_group        = 1000
        }

        container {
          name              = var.app_name
          image             = var.image
          image_pull_policy = var.image_pull_policy

          port {
            name           = "http"
            container_port = var.container_port
            protocol       = "TCP"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.app_secrets.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = var.resources_requests_cpu
              memory = var.resources_requests_memory
            }
            limits = {
              cpu    = var.resources_limits_cpu
              memory = var.resources_limits_memory
            }
          }

          readiness_probe {
            http_get {
              path   = var.readiness_probe_path
              port   = var.container_port
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path   = var.readiness_probe_path
              port   = var.container_port
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            period_seconds        = 15
          }
        }

        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = [var.app_name]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service_account.app,
    kubernetes_config_map.app_config,
    kubernetes_secret.app_secrets
  ]
}

# Service
resource "kubernetes_service" "app" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = var.app_name
      "app.kubernetes.io/environment" = var.environment
    }
  }

  spec {
    type = var.service_type

    selector = {
      "app.kubernetes.io/name" = var.app_name
    }

    port {
      name       = "http"
      port       = var.service_port
      target_port = var.container_port
      protocol   = "TCP"
    }
  }

  depends_on = [kubernetes_deployment.app]
}

# HorizontalPodAutoscaler
resource "kubernetes_horizontal_pod_autoscaler_v2" "app" {
  count = var.enable_hpa ? 1 : 0

  metadata {
    name      = "${var.app_name}-hpa"
    namespace = var.namespace
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_cpu_threshold
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_memory_threshold
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.app]
}

# PodDisruptionBudget
resource "kubernetes_pod_disruption_budget_v1" "app" {
  count = var.enable_pdb ? 1 : 0

  metadata {
    name      = "${var.app_name}-pdb"
    namespace = var.namespace
  }

  spec {
    min_available = var.pdb_min_available
    selector {
      match_labels = {
        "app.kubernetes.io/name" = var.app_name
      }
    }
  }

  depends_on = [kubernetes_deployment.app]
}

# Network Policy
resource "kubernetes_network_policy" "app" {
  count = var.enable_network_policy ? 1 : 0

  metadata {
    name      = "${var.app_name}-network-policy"
    namespace = var.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = var.app_name
      }
    }

    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "name" = var.namespace
          }
        }
      }

      from {
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name" = var.app_name
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = var.container_port
      }
    }

    egress {
      to {
        namespace_selector {}
      }
      ports {
        protocol = "TCP"
        port     = 53
      }
      ports {
        protocol = "UDP"
        port     = 53
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            "name" = var.namespace
          }
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.app]
}
