# Kubernetes resources module
# Migrated and parameterized from original main.tf
terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

resource "kubernetes_deployment" "postgresql" {
  metadata {
    name      = var.postgresql_name
    namespace = var.namespace
    labels = {
      app = var.postgresql_name
    }
  }
  spec {
    replicas = var.postgresql_replicas
    selector {
      match_labels = {
        app = var.postgresql_name
      }
    }
    template {
      metadata {
        labels = {
          app = var.postgresql_name
        }
      }
      spec {
        container {
          name  = var.postgresql_name
          image = var.postgresql_image
          port {
            container_port = 5432
          }
          env {
            name  = "POSTGRES_DB"
            value = var.postgresql_db
          }
          env {
            name  = "POSTGRES_USER"
            value = var.postgresql_user
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = var.postgresql_password
          }
          volume_mount {
            name       = "postgresql-storage"
            mount_path = "/var/lib/postgresql/data"
          }
          resources {
            limits = {
              cpu    = var.postgresql_cpu_limit
              memory = var.postgresql_mem_limit
            }
            requests = {
              cpu    = var.postgresql_cpu_request
              memory = var.postgresql_mem_request
            }
          }
        }
        volume {
          name = "postgresql-storage"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "postgresql" {
  metadata {
    name      = var.postgresql_name
    namespace = var.namespace
  }
  spec {
    selector = {
      app = var.postgresql_name
    }
    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
      node_port   = var.postgresql_node_port
    }
    type = "NodePort"
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "postgresql" {
  metadata {
    name      = "${var.postgresql_name}-hpa"
    namespace = var.namespace
  }
  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.postgresql.metadata[0].name
    }
    min_replicas = var.postgresql_hpa_min
    max_replicas = var.postgresql_hpa_max
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.postgresql_hpa_cpu_util
        }
      }
    }
  }
}

resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = var.prometheus_name
    namespace = var.namespace
  }
  spec {
    replicas = var.prometheus_replicas
    selector {
      match_labels = {
        app = var.prometheus_name
      }
    }
    template {
      metadata {
        labels = {
          app = var.prometheus_name
        }
      }
      spec {
        container {
          image = var.prometheus_image
          name  = var.prometheus_name
          port {
            container_port = 9090
          }
          volume_mount {
            name       = "prometheus-config"
            mount_path = "/etc/prometheus"
          }
        }
        volume {
          name = "prometheus-config"
          config_map {
            name = kubernetes_config_map.prometheus_config.metadata[0].name
          }
        }
      }
    }
  }
  depends_on = [kubernetes_config_map.prometheus_config]
}

resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = var.namespace
  }
  data = {
    "prometheus.yml" = var.prometheus_config_yaml
  }
}

resource "kubernetes_service" "prometheus" {
  metadata {
    name      = var.prometheus_name
    namespace = var.namespace
  }
  spec {
    selector = {
      app = var.prometheus_name
    }
    port {
      port        = 9090
      target_port = 9090
      node_port   = var.prometheus_node_port
    }
    type = "NodePort"
  }
}

resource "kubernetes_deployment" "paas_api" {
  metadata {
    name      = var.paas_api_name
    namespace = var.namespace
    labels = {
      app = var.paas_api_name
    }
  }
  spec {
    replicas = var.paas_api_replicas
    selector {
      match_labels = {
        app = var.paas_api_name
      }
    }
    template {
      metadata {
        labels = {
          app = var.paas_api_name
        }
      }
      spec {
        container {
          image = var.paas_api_image
          name  = var.paas_api_name
          env {
            name  = "POSTGRES_DSN"
            value = "postgres://${var.postgresql_user}:${var.postgresql_password}@${var.postgresql_name}.default.svc.cluster.local:5432/${var.postgresql_db}?sslmode=disable"
          }
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "paas_api" {
  metadata {
    name      = var.paas_api_name
    namespace = var.namespace
  }
  spec {
    selector = {
      app = var.paas_api_name
    }
    port {
      port        = 80
      target_port = 80
      node_port   = var.paas_api_node_port
    }
    type = "NodePort"
  }
}
