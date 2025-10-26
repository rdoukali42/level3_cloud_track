# Variables for k8s-apps module

variable "namespace" {
  description = "Kubernetes namespace for all resources."
  type        = string
  default     = "default"
}

# PostgreSQL variables
variable "postgresql_name" {
  description = "Name for the PostgreSQL deployment and service."
  type        = string
  default     = "postgresql"
}
variable "postgresql_image" {
  description = "PostgreSQL Docker image."
  type        = string
  default     = "postgres:13"
}
variable "postgresql_replicas" {
  description = "Number of PostgreSQL pods."
  type        = number
  default     = 1
}
variable "postgresql_db" {
  description = "Database name for PostgreSQL."
  type        = string
  default     = "mydb"
}
variable "postgresql_user" {
  description = "Database user for PostgreSQL."
  type        = string
  default     = "myuser"
}
variable "postgresql_password" {
  description = "Database password for PostgreSQL."
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_IN_PRODUCTION"  # Override in terraform.tfvars
}
variable "postgresql_cpu_limit" {
  description = "CPU limit for PostgreSQL container."
  type        = string
  default     = "3000m"
}
variable "postgresql_mem_limit" {
  description = "Memory limit for PostgreSQL container."
  type        = string
  default     = "512Mi"
}
variable "postgresql_cpu_request" {
  description = "CPU request for PostgreSQL container."
  type        = string
  default     = "500m"
}
variable "postgresql_mem_request" {
  description = "Memory request for PostgreSQL container."
  type        = string
  default     = "256Mi"
}
variable "postgresql_node_port" {
  description = "NodePort for PostgreSQL service."
  type        = number
  default     = 30080
}
variable "postgresql_hpa_min" {
  description = "Minimum replicas for PostgreSQL HPA."
  type        = number
  default     = 1
}
variable "postgresql_hpa_max" {
  description = "Maximum replicas for PostgreSQL HPA."
  type        = number
  default     = 3
}
variable "postgresql_hpa_cpu_util" {
  description = "Target CPU utilization for PostgreSQL HPA."
  type        = number
  default     = 76
}

# Prometheus variables
variable "prometheus_name" {
  description = "Name for the Prometheus deployment and service."
  type        = string
  default     = "prometheus"
}
variable "prometheus_image" {
  description = "Prometheus Docker image."
  type        = string
  default     = "prom/prometheus:latest"
}
variable "prometheus_replicas" {
  description = "Number of Prometheus pods."
  type        = number
  default     = 1
}
variable "prometheus_node_port" {
  description = "NodePort for Prometheus service."
  type        = number
  default     = 30090
}
variable "prometheus_config_yaml2" {
  description = "YAML config for Prometheus."
  type        = string
  default     = <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod

  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
      - role: endpoints
    scheme: https
    tls_config:
      insecure_skip_verify: true
    relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: default;kubernetes;https
  - job_name: 'node-exporter'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_name]
        action: keep
        regex: node-exporter
      - source_labels: [__meta_kubernetes_pod_container_port_number]
        action: keep
        regex: "9100"
EOF
}

# PaaS API variables
variable "paas_api_name" {
  description = "Name for the PaaS API deployment and service."
  type        = string
  default     = "paas-api"
}
variable "paas_api_image" {
  description = "PaaS API Docker image."
  type        = string
  default     = "nginx:alpine"
}
variable "paas_api_replicas" {
  description = "Number of PaaS API pods."
  type        = number
  default     = 1
}
variable "paas_api_node_port" {
  description = "NodePort for PaaS API service."
  type        = number
  default     = 30081
}

# Grafana variables
variable "grafana_name" {
  description = "Name for the Grafana release."
  type        = string
  default     = "grafana"
}
variable "grafana_repository" {
  description = "Helm repository for Grafana."
  type        = string
  default     = "https://grafana.github.io/helm-charts"
}
variable "grafana_chart" {  
  description = "Helm chart for Grafana."
  type        = string
  default     = "grafana"
}
variable "grafana_version" {
  description = "Version of the Grafana Helm chart."    
  type        = string
  default     = "8.0.0"
}
variable "grafana_namespace" {
  description = "Namespace for Grafana resources."
  type        = string
  default     = "default"
}


