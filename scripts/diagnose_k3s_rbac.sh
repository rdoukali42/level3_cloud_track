#!/bin/bash
# k3s RBAC Diagnostic Script
# This script collects targeted diagnostic information to identify the root cause
# of kube-proxy RBAC errors in k3s clusters

set -e

echo "=== k3s RBAC Diagnostic Script ==="
echo "Timestamp: $(date)"
echo ""

# Get cluster nodes for context
echo "=== CLUSTER NODES ==="
kubectl --kubeconfig ~/.kube/k3s-config get nodes -o wide
echo ""

# Check what processes are claiming to be kube-proxy
echo "=== PROXY PROCESS ANALYSIS ==="
echo "Checking for kube-proxy processes (should be NONE in k3s):"
for node in $(kubectl --kubeconfig ~/.kube/k3s-config get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'); do
    echo "Node $node:"
    ssh -i ~/.ssh/id_rsa ubuntu@$(kubectl --kubeconfig ~/.kube/k3s-config get nodes -o jsonpath="{.items[?(@.status.addresses[0].address=='$node')].status.addresses[?(@.type=='ExternalIP')].address}") \
        "ps aux | grep -E 'kube-proxy|k3s.*proxy' | grep -v grep" || echo "  No proxy processes found"
done
echo ""

# Check k3s configuration on master
echo "=== K3S MASTER CONFIGURATION ==="
MASTER_IP="172.24.4.24"
echo "Master node: $MASTER_IP"
ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP 'echo "k3s service status:"; sudo systemctl status k3s | head -20'
echo ""
ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP 'echo "k3s service args:"; sudo journalctl -u k3s | grep "Starting k3s" | tail -3'
echo ""

# Check what's making the system:kube-proxy API calls
echo "=== API SERVER AUDIT (Last 50 system:kube-proxy requests) ==="
ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP \
    'sudo journalctl -u k3s | grep "system:kube-proxy" | tail -50' || echo "No recent system:kube-proxy requests found"
echo ""

# Check k3s built-in RBAC
echo "=== K3S BUILT-IN RBAC CHECK ==="
echo "Checking if system:kube-proxy ServiceAccount exists:"
kubectl --kubeconfig ~/.kube/k3s-config get serviceaccount -n kube-system | grep kube-proxy || echo "  No kube-proxy ServiceAccount found"
echo ""
echo "Checking if system:node-proxier ClusterRole exists:"
kubectl --kubeconfig ~/.kube/k3s-config get clusterrole | grep node-proxier || echo "  No node-proxier ClusterRole found"
echo ""
echo "Checking ClusterRoleBindings for kube-proxy:"
kubectl --kubeconfig ~/.kube/k3s-config get clusterrolebinding | grep proxy || echo "  No proxy-related ClusterRoleBindings found"
echo ""

# Check k3s components
echo "=== K3S COMPONENTS STATUS ==="
kubectl --kubeconfig ~/.kube/k3s-config get pods -n kube-system
echo ""

# Check if there are any DaemonSets trying to run kube-proxy
echo "=== PROXY DAEMONSETS CHECK ==="
kubectl --kubeconfig ~/.kube/k3s-config get daemonsets -A | grep proxy || echo "No proxy DaemonSets found (this is expected in k3s)"
echo ""

# Check k3s proxy mode from config
echo "=== K3S PROXY MODE CONFIGURATION ==="
ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP \
    'echo "Checking k3s config:"; sudo cat /etc/systemd/system/k3s.service | grep ExecStart'
echo ""
ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP \
    'echo "Checking for proxy-related flags:"; sudo ps aux | grep k3s | head -1'
echo ""

# NodePort service test
echo "=== NODEPORT SERVICE TEST - Worker 1==="
echo "Testing NodePort service accessibility:"
WORKER_IP="172.24.4.190"
curl -m 5 http://$WORKER_IP:30080/api/v1/databases 2>/dev/null || echo "NodePort service not accessible"
echo ""

# NodePort service test
echo "=== NODEPORT SERVICE TEST - Worker 2==="
echo "Testing NodePort service accessibility:"
WORKER_IP="172.24.4.212"
curl -m 5 http://$WORKER_IP:30080/api/v1/databases 2>/dev/null || echo "NodePort service not accessible"
echo ""

# NodePort service test
echo "=== NODEPORT SERVICE TEST - Master==="
echo "Testing NodePort service accessibility:"
WORKER_IP="172.24.4.24"
curl -m 5 http://$WORKER_IP:30080/api/v1/databases 2>/dev/null || echo "NodePort service not accessible"
echo ""

echo "=== DIAGNOSTIC COMPLETE ==="
echo "Please review the output above to identify the root cause."