# Outputs for k8s-apps module

# Define outputs for service endpoints, etc.

output "postgresql_service_name" {
  description = "Name of the PostgreSQL service."
  value       = kubernetes_service.postgresql.metadata[0].name
}

output "prometheus_service_name" {
  description = "Name of the Prometheus service."
  value       = kubernetes_service.prometheus.metadata[0].name
}

output "paas_api_service_name" {
  description = "Name of the PaaS API service."
  value       = kubernetes_service.paas_api.metadata[0].name
}
