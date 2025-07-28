#!/bin/bash
# k3s Proxy Fix Script
# Restarts k3s services to reinitialize built-in proxy functionality

set -e

echo "=== k3s Proxy Fix Script ==="
echo "Restarting k3s services to fix built-in proxy issues"
echo ""

# Get master and worker IPs
MASTER_IP="172.24.4.24"
WORKER1_IP="172.24.4.190"

echo "Master IP: $MASTER_IP"
echo "Worker-1 IP: $WORKER1_IP"
echo ""

# Restart k3s on master
echo "=== Restarting k3s on Master Node ==="
ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP 'sudo systemctl restart k3s && sleep 10 && sudo systemctl status k3s'
echo "Master restart complete"
echo ""

# Restart k3s-agent on worker-1
echo "=== Restarting k3s-agent on Worker-1 ==="
ssh -i ~/.ssh/id_rsa ubuntu@$WORKER1_IP 'sudo systemctl restart k3s-agent && sleep 10 && sudo systemctl status k3s-agent'
echo "Worker-1 restart complete"
echo ""

# Wait for services to stabilize
echo "Waiting 30 seconds for services to stabilize..."
sleep 30

# Test NodePort accessibility on all nodes
echo "=== Testing NodePort Service After Fix ==="
echo "Testing Master node:"
curl -m 5 http://$MASTER_IP:30080/api/v1/databases 2>/dev/null && echo " ✅ Master NodePort working" || echo " ❌ Master NodePort still failed"

echo "Testing Worker-1 node:"
curl -m 5 http://$WORKER1_IP:30080/api/v1/databases 2>/dev/null && echo " ✅ Worker-1 NodePort working" || echo " ❌ Worker-1 NodePort still failed"

echo ""
echo "=== Fix Complete ==="
echo "If NodePort services are still not accessible, the issue may require deeper k3s reconfiguration."