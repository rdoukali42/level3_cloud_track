#!/bin/bash
# Deploy PostgreSQL PaaS service

set -e

echo "Deploying PostgreSQL PaaS service..."

# Change to the current directory (paas-postgresql)
cd "$(dirname "$0")/../terraform"

# Check if terraform files exist
if [ ! -f "main.tf" ]; then
    echo "Error: Terraform files not found in current directory"
    echo "Current directory: $(pwd)"
    echo "Expected files: main.tf, variables.tf, outputs.tf"
    exit 1
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Apply configuration
echo "Applying Terraform configuration..."
terraform apply -auto-approve

echo "Deployment complete!"
echo ""
echo "API Endpoints:"
echo "POST   http://<node-ip>:30080/api/v1/databases       # Create database"
echo "GET    http://<node-ip>:30080/api/v1/databases       # List databases"
echo "GET    http://<node-ip>:30080/api/v1/databases/{id}  # Get database"
echo "DELETE http://<node-ip>:30080/api/v1/databases/{id}  # Delete database"
echo "GET    http://<node-ip>:30080/api/v1/databases/{id}/metrics # Get metrics"
echo ""
echo "To get node IP:"
echo "kubectl --kubeconfig ~/.kube/k3s-config get nodes -o wide --insecure-skip-tls-verify"
echo ""
echo "Test commands:"
echo "kubectl --kubeconfig ~/.kube/k3s-config get pods -A --insecure-skip-tls-verify"
echo "kubectl --kubeconfig ~/.kube/k3s-config get pods -l app=paas-api --insecure-skip-tls-verify"
echo "kubectl --kubeconfig ~/.kube/k3s-config get pods -l app=prometheus --insecure-skip-tls-verify"
echo "kubectl --kubeconfig ~/.kube/k3s-config get svc paas-api --insecure-skip-tls-verify"





echo "1. Test API health"
echo "curl http://172.24.4.151:30080/api/v1/databases"

echo "2. Create a PostgreSQL database"
echo "curl -X POST http://<NODE_IP>:30080/api/v1/databases \
  -H "Content-Type: application/json" \
  -d '{"name": "test-db", "size": "1Gi"}'"

echo "3. List all databases"
echo "curl http://<NODE_IP>:30080/api/v1/databases"

echo "4. Get specific database details"
echo "curl http://<NODE_IP>:30080/api/v1/databases/test-db"

echo "5. Get database metrics"
echo "curl http://<NODE_IP>:30080/api/v1/databases/test-db/metrics"

echo "6. Delete database"
echo "curl -X DELETE http://<NODE_IP>:30080/api/v1/databases/test-db"

curl -X POST http:/172.24.4.55:30080/api/v1/databases -H "Content-Type: application/json" -d '{"name": "zbbi-db", "size": "1Gi"}'