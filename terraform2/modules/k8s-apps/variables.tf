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
  default     = "mypassword"
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
variable "prometheus_config_yaml" {
  description = "YAML config for Prometheus."
  type        = string
  default     = <<EOF
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
    - role: pod
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

