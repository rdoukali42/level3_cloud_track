#!/bin/bash
# Terraform Installation Script for Ubuntu
# This script installs the latest version of Terraform on Ubuntu

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Terraform Installation Script${NC}"
echo -e "${YELLOW}This script will install the latest version of Terraform${NC}"

# Check if running on Ubuntu
if ! grep -qi "ubuntu" /etc/os-release; then
    echo -e "${RED}This script is designed for Ubuntu. It may work on other Debian-based systems.${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update package index
echo -e "${YELLOW}Updating package index...${NC}"
sudo apt update

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
sudo apt install -y wget curl unzip gnupg software-properties-common

# Add HashiCorp GPG key
echo -e "${YELLOW}Adding HashiCorp GPG key...${NC}"
wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# Verify the key fingerprint
echo -e "${YELLOW}Verifying GPG key fingerprint...${NC}"
gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint

# Add HashiCorp repository
echo -e "${YELLOW}Adding HashiCorp repository...${NC}"
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update package index again
echo -e "${YELLOW}Updating package index with new repository...${NC}"
sudo apt update

# Install Terraform
echo -e "${YELLOW}Installing Terraform...${NC}"
sudo apt install -y terraform

# Verify installation
echo -e "${YELLOW}Verifying Terraform installation...${NC}"
terraform --version

# Install Terraform autocomplete
echo -e "${YELLOW}Setting up Terraform autocomplete...${NC}"
terraform -install-autocomplete

echo -e "${GREEN}Terraform installation completed successfully!${NC}"
echo -e "${YELLOW}Terraform version:${NC}"
terraform --version

echo -e "${GREEN}Next steps:${NC}"
echo -e "${YELLOW}1. Create a new directory for your Terraform project${NC}"
echo -e "${YELLOW}2. Initialize Terraform with 'terraform init'${NC}"
echo -e "${YELLOW}3. Create your Terraform configuration files (.tf files)${NC}"
echo -e "${YELLOW}4. Plan your deployment with 'terraform plan'${NC}"
echo -e "${YELLOW}5. Apply your configuration with 'terraform apply'${NC}"

echo ""
echo -e "${YELLOW}For OpenStack integration, you'll also need to install the OpenStack Terraform provider.${NC}"
echo -e "${YELLOW}This will be done automatically when you run 'terraform init' in a project with OpenStack provider configuration.${NC}"
