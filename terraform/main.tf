# Root orchestration file for terraform2

# Providers (OpenStack, Kubernetes) should be defined in providers.tf
# Variables in variables.tf
# Outputs in outputs.tf

# Example usage of modules (fill in variables as needed):

# module "cluster" {
#   source    = "./modules/cluster"
#   for_each  = local.regions
#   providers = { openstack = each.value.provider }
#   region        = each.value.name
#   cluster_name  = "my-cluster-${each.key}"
#   master_count  = var.master_count
#   worker_count  = var.worker_count
#   # ...other variables...
# }

# provider "kubernetes" {
#   config_path = var.kubeconfig_path
#   insecure    = true
# }

# module "k8s_apps" {
#   source = "./modules/k8s-apps"
#   # ...pass variables as needed...
# }

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


module "cluster" {
  source            = "./modules/cluster"
  ssh_key_name      = var.ssh_key_name
  public_key_path   = var.public_key_path
  image_name        = var.image_name
  cluster_name      = var.cluster_name
  network_cidr      = var.network_cidr
  dns_nameservers   = var.dns_nameservers
  master_count      = var.master_count
  worker_count      = var.worker_count
  master_flavor     = var.master_flavor
  worker_flavor     = var.worker_flavor
  ssh_user          = var.ssh_user
  private_key_path  = var.private_key_path
  master_user_data  = var.master_user_data
  worker_user_data  = var.worker_user_data
}

module "k8s_apps" {
  source = "./modules/k8s-apps"
  namespace                = "default"
  postgresql_name          = "postgresql"
  postgresql_image         = "postgres:13"
  postgresql_replicas      = 1
  postgresql_db            = "mydb"
  postgresql_user          = "myuser"
  postgresql_password      = var.postgresql_password  # Change in terraform.tfvars
  postgresql_cpu_limit     = "3000m"
  postgresql_mem_limit     = "512Mi"
  postgresql_cpu_request   = "500m"
  postgresql_mem_request   = "256Mi"
  postgresql_node_port     = 30080
  postgresql_hpa_min       = 1
  postgresql_hpa_max       = 3
  postgresql_hpa_cpu_util  = 76
  prometheus_name          = "prometheus"
  prometheus_image         = "prom/prometheus:latest"
  prometheus_replicas      = 1
  prometheus_node_port     = 30090
  # prometheus_config_yaml   = <<EOF
  #   global:
  #     scrape_interval: 15s
  #   scrape_configs:
  #     - job_name: 'kubernetes-pods'
  #       kubernetes_sd_configs:
  #       - role: pod
  #   EOF
  paas_api_name            = "paas-api"
  paas_api_image           = "reda404/paas-api:latest"
  paas_api_replicas        = 1
  paas_api_node_port       = 30081
}
