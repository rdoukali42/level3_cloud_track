#!/bin/bash
# Terraform Installation Script for Ubuntu
# This script installs the latest version of Terraform and sets up OpenStack provider

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Terraform Installation...${NC}"

# Check if running on Ubuntu
if ! grep -qi "ubuntu" /etc/os-release &> /dev/null; then
    echo -e "${RED}This script is designed for Ubuntu operating system${NC}"
    echo -e "${YELLOW}It may work on other systems but has not been tested${NC}"
fi

# Update package list
echo -e "${YELLOW}Updating package list...${NC}"
sudo apt update

# Install required dependencies
echo -e "${YELLOW}Installing required dependencies...${NC}"
sudo apt install -y gnupg software-properties-common curl wget unzip

# Add HashiCorp GPG key
echo -e "${YELLOW}Adding HashiCorp GPG key...${NC}"
wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# Verify the key's fingerprint
gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint

# Add the official HashiCorp repository
echo -e "${YELLOW}Adding HashiCorp repository...${NC}"
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update package list again
sudo apt update

# Install Terraform
echo -e "${YELLOW}Installing Terraform...${NC}"
sudo apt install -y terraform

# Verify installation
TERRAFORM_VERSION=$(terraform version | head -n 1)
echo -e "${GREEN}Terraform installed successfully: $TERRAFORM_VERSION${NC}"

# Create Terraform configuration directory
TERRAFORM_DIR="$HOME/terraform-openstack"
echo -e "${YELLOW}Creating Terraform workspace at $TERRAFORM_DIR${NC}"
mkdir -p "$TERRAFORM_DIR"

# Create main Terraform configuration file
cat > "$TERRAFORM_DIR/main.tf" << 'EOF'
# Configure the OpenStack Provider
terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54.0"
    }
  }
  required_version = ">= 1.0"
}

# Configure the OpenStack Provider
provider "openstack" {
  # Configuration will be taken from environment variables
  # or you can specify them here
}

# Data sources for existing resources
data "openstack_networking_network_v2" "external" {
  name     = "public"
  external = true
}

data "openstack_images_image_v2" "debian12" {
  name        = "debian12"
  most_recent = true
}

# Create a network
resource "openstack_networking_network_v2" "k8s_network" {
  name           = "k8s-terraform-network"
  admin_state_up = "true"
}

# Create a subnet
resource "openstack_networking_subnet_v2" "k8s_subnet" {
  name       = "k8s-terraform-subnet"
  network_id = openstack_networking_network_v2.k8s_network.id
  cidr       = "192.168.200.0/24"
  ip_version = 4
  
  allocation_pool {
    start = "192.168.200.10"
    end   = "192.168.200.200"
  }
}

# Create a router
resource "openstack_networking_router_v2" "k8s_router" {
  name                = "k8s-terraform-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

# Create a router interface
resource "openstack_networking_router_interface_v2" "k8s_router_interface" {
  router_id = openstack_networking_router_v2.k8s_router.id
  subnet_id = openstack_networking_subnet_v2.k8s_subnet.id
}

# Create security group
resource "openstack_compute_secgroup_v2" "k8s_secgroup" {
  name        = "k8s-terraform-secgroup"
  description = "Security group for Kubernetes cluster"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 6443
    to_port     = 6443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}

# Create SSH key pair
resource "openstack_compute_keypair_v2" "k8s_keypair" {
  name       = "k8s-terraform-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Create master nodes
resource "openstack_compute_instance_v2" "k8s_master" {
  count           = var.master_count
  name            = "k8s-terraform-master-${count.index + 1}"
  image_name      = data.openstack_images_image_v2.debian12.name
  flavor_name     = var.master_flavor
  key_pair        = openstack_compute_keypair_v2.k8s_keypair.name
  security_groups = [openstack_compute_secgroup_v2.k8s_secgroup.name]

  network {
    name = openstack_networking_network_v2.k8s_network.name
  }

  metadata = {
    role = "master"
  }
}

# Create worker nodes
resource "openstack_compute_instance_v2" "k8s_worker" {
  count           = var.worker_count
  name            = "k8s-terraform-worker-${count.index + 1}"
  image_name      = data.openstack_images_image_v2.debian12.name
  flavor_name     = var.worker_flavor
  key_pair        = openstack_compute_keypair_v2.k8s_keypair.name
  security_groups = [openstack_compute_secgroup_v2.k8s_secgroup.name]

  network {
    name = openstack_networking_network_v2.k8s_network.name
  }

  metadata = {
    role = "worker"
  }
}

# Create floating IPs for master nodes
resource "openstack_networking_floatingip_v2" "k8s_master_fip" {
  count = var.master_count
  pool  = data.openstack_networking_network_v2.external.name
}

# Associate floating IPs with master nodes
resource "openstack_compute_floatingip_associate_v2" "k8s_master_fip_associate" {
  count       = var.master_count
  floating_ip = openstack_networking_floatingip_v2.k8s_master_fip[count.index].address
  instance_id = openstack_compute_instance_v2.k8s_master[count.index].id
}

# Create floating IPs for worker nodes
resource "openstack_networking_floatingip_v2" "k8s_worker_fip" {
  count = var.worker_count
  pool  = data.openstack_networking_network_v2.external.name
}

# Associate floating IPs with worker nodes
resource "openstack_compute_floatingip_associate_v2" "k8s_worker_fip_associate" {
  count       = var.worker_count
  floating_ip = openstack_networking_floatingip_v2.k8s_worker_fip[count.index].address
  instance_id = openstack_compute_instance_v2.k8s_worker[count.index].id
}
EOF

# Create variables file
cat > "$TERRAFORM_DIR/variables.tf" << 'EOF'
variable "master_count" {
  description = "Number of master nodes"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "master_flavor" {
  description = "Flavor for master nodes"
  type        = string
  default     = "m1.large"
}

variable "worker_flavor" {
  description = "Flavor for worker nodes"
  type        = string
  default     = "m1.large"
}

variable "cluster_name" {
  description = "Name prefix for the cluster"
  type        = string
  default     = "k8s-terraform"
}
EOF

# Create outputs file
cat > "$TERRAFORM_DIR/outputs.tf" << 'EOF'
output "master_nodes" {
  description = "Master node information"
  value = {
    for i, instance in openstack_compute_instance_v2.k8s_master : 
    instance.name => {
      private_ip   = instance.network[0].fixed_ip_v4
      floating_ip  = openstack_networking_floatingip_v2.k8s_master_fip[i].address
      id          = instance.id
    }
  }
}

output "worker_nodes" {
  description = "Worker node information"
  value = {
    for i, instance in openstack_compute_instance_v2.k8s_worker : 
    instance.name => {
      private_ip   = instance.network[0].fixed_ip_v4
      floating_ip  = openstack_networking_floatingip_v2.k8s_worker_fip[i].address
      id          = instance.id
    }
  }
}

output "network_info" {
  description = "Network information"
  value = {
    network_id = openstack_networking_network_v2.k8s_network.id
    subnet_id  = openstack_networking_subnet_v2.k8s_subnet.id
    router_id  = openstack_networking_router_v2.k8s_router.id
  }
}
EOF

# Create terraform.tfvars.example
cat > "$TERRAFORM_DIR/terraform.tfvars.example" << 'EOF'
# Copy this file to terraform.tfvars and modify the values as needed

master_count   = 1
worker_count   = 2
master_flavor  = "m1.large"
worker_flavor  = "m1.large"
cluster_name   = "k8s-terraform"
EOF

# Create environment setup script
cat > "$TERRAFORM_DIR/setup_env.sh" << 'EOF'
#!/bin/bash
# Source OpenStack credentials for Terraform

# Load OpenStack credentials
if [ -f /home/reda/devstack/openrc ]; then
    source /home/reda/devstack/openrc admin admin
    echo "OpenStack credentials loaded"
else
    echo "OpenStack RC file not found. Please check the path."
    exit 1
fi

# Export additional variables for Terraform
export TF_VAR_region_name="${OS_REGION_NAME:-RegionOne}"
export TF_VAR_tenant_name="$OS_PROJECT_NAME"

echo "Environment variables set for Terraform"
echo "OS_AUTH_URL: $OS_AUTH_URL"
echo "OS_PROJECT_NAME: $OS_PROJECT_NAME"
echo "OS_USERNAME: $OS_USERNAME"
EOF

chmod +x "$TERRAFORM_DIR/setup_env.sh"

# Create deployment script
cat > "$TERRAFORM_DIR/deploy.sh" << 'EOF'
#!/bin/bash
# Terraform deployment script

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Starting Terraform deployment...${NC}"

# Source environment
echo -e "${YELLOW}Loading OpenStack environment...${NC}"
source ./setup_env.sh

# Check if SSH key exists
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo -e "${YELLOW}Generating SSH key...${NC}"
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init

# Plan the deployment
echo -e "${YELLOW}Planning deployment...${NC}"
terraform plan

# Apply the configuration
echo -e "${YELLOW}Applying configuration...${NC}"
read -p "Do you want to proceed with the deployment? (y/N): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    terraform apply -auto-approve
    echo -e "${GREEN}Deployment completed successfully!${NC}"
    echo -e "${YELLOW}Getting instance information...${NC}"
    terraform output
else
    echo -e "${YELLOW}Deployment cancelled.${NC}"
fi
EOF

chmod +x "$TERRAFORM_DIR/deploy.sh"

# Create destroy script
cat > "$TERRAFORM_DIR/destroy.sh" << 'EOF'
#!/bin/bash
# Terraform destroy script

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}Starting Terraform destroy...${NC}"

# Source environment
echo -e "${YELLOW}Loading OpenStack environment...${NC}"
source ./setup_env.sh

# Destroy the infrastructure
echo -e "${YELLOW}Planning destroy...${NC}"
terraform plan -destroy

read -p "Are you sure you want to destroy all resources? (y/N): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    terraform destroy -auto-approve
    echo -e "${GREEN}Infrastructure destroyed successfully!${NC}"
else
    echo -e "${YELLOW}Destroy cancelled.${NC}"
fi
EOF

chmod +x "$TERRAFORM_DIR/destroy.sh"

# Create README
cat > "$TERRAFORM_DIR/README.md" << 'EOF'
# Terraform OpenStack Kubernetes Infrastructure

This Terraform configuration creates a Kubernetes cluster infrastructure on OpenStack.

## Prerequisites

- Terraform installed
- OpenStack credentials configured
- SSH key pair generated

## Quick Start

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your desired values

3. Deploy the infrastructure:
   ```bash
   ./deploy.sh
   ```

4. To destroy the infrastructure:
   ```bash
   ./destroy.sh
   ```

## Manual Commands

### Initialize Terraform
```bash
source ./setup_env.sh
terraform init
```

### Plan deployment
```bash
terraform plan
```

### Apply configuration
```bash
terraform apply
```

### Show outputs
```bash
terraform output
```

### Destroy infrastructure
```bash
terraform destroy
```

## Configuration

### Variables

- `master_count`: Number of master nodes (default: 1)
- `worker_count`: Number of worker nodes (default: 2)
- `master_flavor`: OpenStack flavor for master nodes (default: m1.large)
- `worker_flavor`: OpenStack flavor for worker nodes (default: m1.large)
- `cluster_name`: Name prefix for resources (default: k8s-terraform)

### Outputs

- `master_nodes`: Information about master nodes including IPs
- `worker_nodes`: Information about worker nodes including IPs
- `network_info`: Network infrastructure details

## Network Configuration

- Network: 192.168.200.0/24
- DHCP Pool: 192.168.200.10 - 192.168.200.200
- External connectivity via router to public network

## Security Groups

The security group allows:
- SSH (port 22)
- HTTP (port 80)
- HTTPS (port 443)
- Kubernetes API (port 6443)
- ICMP (ping)

## Next Steps

After deployment, you can:
1. SSH into the nodes using the floating IPs
2. Install Kubernetes (K3s, kubeadm, etc.)
3. Configure your cluster
EOF

echo -e "${GREEN}Terraform installation and setup completed!${NC}"
echo -e "${YELLOW}Terraform workspace created at: $TERRAFORM_DIR${NC}"
echo -e "${YELLOW}To get started:${NC}"
echo -e "  1. cd $TERRAFORM_DIR"
echo -e "  2. cp terraform.tfvars.example terraform.tfvars"
echo -e "  3. Edit terraform.tfvars as needed"
echo -e "  4. Run: ./deploy.sh"
echo ""
echo -e "${GREEN}Installation Summary:${NC}"
echo -e "  - Terraform: $(terraform version | head -n 1)"
echo -e "  - Workspace: $TERRAFORM_DIR"
echo -e "  - Ready to use with OpenStack provider"
