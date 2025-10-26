# Terraform Infrastructure

This directory contains Terraform code to provision a complete Kubernetes cluster on OpenStack with monitoring and database services.

## Architecture

```
OpenStack Cloud
├── Network Infrastructure
│   ├── Private Network (10.0.0.0/24)
│   ├── Router with External Gateway
│   └── Security Groups (SSH, K8s API, NodePorts)
│
├── Compute Resources
│   ├── Master Nodes (K3s Control Plane)
│   └── Worker Nodes (K3s Workers)
│
└── Kubernetes Applications
    ├── PostgreSQL Database
    ├── Prometheus Monitoring
    ├── Node Exporter
    └── PaaS API
```

## Modules

### `modules/cluster/`

Provisions OpenStack infrastructure and K3s cluster:
- Virtual machines (masters & workers)
- Networking (VPC, subnets, router)
- Security groups and floating IPs
- K3s installation and configuration

### `modules/k8s-apps/`

Deploys Kubernetes applications:
- PostgreSQL with HPA
- Prometheus monitoring
- PaaS API service

## Quick Start

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan

# Get kubeconfig
export KUBECONFIG=$(terraform output -raw kubeconfig_path)
kubectl get nodes
```

## Configuration

Create a `terraform.tfvars` file or use environment variables:

```hcl
ssh_key_name      = "k8s-key"
public_key_path   = "~/.ssh/k8s-key.pub"
private_key_path  = "~/.ssh/k8s-key"
cluster_name      = "my-k8s-cluster"
master_count      = 1
worker_count      = 2
postgresql_password = "change_me_in_production"
```

See the main [README.md](../README.md) for complete documentation.
