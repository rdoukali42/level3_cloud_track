#!/bin/bash
# Script to set up local kubeconfig for the K3s cluster
# Usage: ./setup_k3s_kubeconfig.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform2"

cd "$TERRAFORM_DIR"

echo "Setting up K3s kubeconfig..."

# Check if Terraform has been applied
if [ ! -f "terraform.tfstate" ]; then
    echo "Error: No terraform.tfstate found. Please run 'terraform apply' first."
    exit 1
fi

# Get master node IP (handle list output)
MASTER_IP=$(terraform output -json master_floating_ips | jq -r '.[0]')
if [ -z "$MASTER_IP" ] || [ "$MASTER_IP" = "null" ]; then
    echo "Error: Could not get master node IP from Terraform output."
    exit 1
fi

# Get SSH configuration
SSH_USER=$(terraform output -raw ssh_user 2>/dev/null || echo "ubuntu")
PRIVATE_KEY_PATH=$(terraform output -raw private_key_path 2>/dev/null || echo "~/.ssh/id_rsa")

# Expand tilde in path
PRIVATE_KEY_PATH="${PRIVATE_KEY_PATH/#\~/$HOME}"

echo "Master IP: $MASTER_IP"
echo "SSH User: $SSH_USER"
echo "Private Key: $PRIVATE_KEY_PATH"

# Create kubeconfig directory if it doesn't exist
mkdir -p ~/.kube

# Wait a moment for K3s to be fully ready
echo "Waiting for K3s to be ready..."
sleep 10

# Retrieve kubeconfig from master node
echo "Retrieving kubeconfig from master node..."
ssh -i "$PRIVATE_KEY_PATH" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$SSH_USER@$MASTER_IP" \
    'sudo cat /etc/rancher/k3s/k3s.yaml' > ~/.kube/k3s-config-temp

# Update server address in kubeconfig
sed "s/127.0.0.1/$MASTER_IP/" ~/.kube/k3s-config-temp > ~/.kube/k3s-config

# Set proper permissions
chmod 600 ~/.kube/k3s-config

# Remove temp file
rm -f ~/.kube/k3s-config-temp

echo "Kubeconfig saved to ~/.kube/k3s-config"
echo ""
echo "To use this kubeconfig, run:"
echo "export KUBECONFIG=~/.kube/k3s-config"
echo ""
echo "Or merge it with your existing kubeconfig:"
echo "KUBECONFIG=~/.kube/config:~/.kube/k3s-config kubectl config view --flatten > ~/.kube/config-merged"
echo "mv ~/.kube/config-merged ~/.kube/config"
echo ""
echo "Test the connection:"
echo "kubectl --kubeconfig ~/.kube/k3s-config get nodes --insecure-skip-tls-verify"
echo "kubectl --kubeconfig ~/.kube/k3s-config get pods -A --insecure-skip-tls-verify"
echo "kubectl --kubeconfig ~/.kube/k3s-config top nodes --insecure-skip-tls-verify"
echo "kubectl --kubeconfig ~/.kube/k3s-config top pods -A --insecure-skip-tls-verify"





ssh -i "$PRIVATE_KEY_PATH" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SSH_USER@$MASTER_IP" 'sudo cat /etc/rancher/k3s/k3s.yaml' > ~/.kube/k3s-config-temp


ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@172.24.4.151


'sudo cat /etc/rancher/k3s/k3s.yaml' > ~/.kube/k3s-config-temp