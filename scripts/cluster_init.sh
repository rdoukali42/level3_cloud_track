#!/bin/bash
# kubernetes_provision.sh
# This script creates the necessary OpenStack resources for a cluster (no Kubernetes install)

# Exit on error
set -e

# =====================
# Global Configuration
# =====================
OS_PROJECT_NAME="admin"         # <--- User can set this to desired project
OS_TENANT_NAME="admin"          # <--- User can set this to desired tenant
OS_USERNAME="admin"             # <--- User can set this to desired username
OS_USER_DOMAIN_NAME="Default"
OS_PROJECT_DOMAIN_NAME="Default"
OS_IDENTITY_API_VERSION=3


CLUSTER_NAME="k8s-cluster"
IMAGE_NAME="debian12"
FLAVOR_NAME_MASTER="m1.large"   # Master node flavor
FLAVOR_NAME_WORKER="m1.large"  # Worker node flavor
NETWORK_NAME="k8s-network"
SUBNET_NAME="k8s-subnet"
SUBNET_CIDR="192.168.100.0/24"
ROUTER_NAME="k8s-router"
SECURITY_GROUP_NAME="default"
SSH_KEY_NAME="k8s-key"
MASTER_COUNT=1
WORKER_COUNT=2

# Set color codes for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running on Ubuntu
if ! grep -qi "ubuntu" /etc/os-release &> /dev/null; then
    echo -e "${RED}This script is designed for Ubuntu operating system${NC}"
    echo -e "${YELLOW}It may work on other systems but has not been tested${NC}"
fi

# Check if basic utilities are installed
for pkg in curl wget jq ssh-keygen; do
    if ! command -v $pkg &> /dev/null; then
        echo -e "${YELLOW}Installing required utility: $pkg${NC}"
        sudo apt update && sudo apt install -y curl wget jq openssh-client
        break
    fi
done

echo -e "${GREEN}Starting Infrastructure Provisioning Script${NC}"

# Check if OpenStack CLI is available
if ! command -v openstack &> /dev/null; then
    echo -e "${RED}OpenStack CLI not found. Please ensure OpenStack is installed and credentials are sourced.${NC}"
    exit 1
fi


# Always source devstack openrc with user/project from global variables
if [ -f /home/reda/devstack/openrc ]; then
    echo -e "${YELLOW}Sourcing OpenStack credentials (project: $OS_PROJECT_NAME, user: $OS_USERNAME)...${NC}"
    set +u  # Temporarily disable unset variable errors for sourcing
    source /home/reda/devstack/openrc "$OS_USERNAME" "$OS_PROJECT_NAME"
    set -u
    export OS_PROJECT_NAME
    export OS_TENANT_NAME
    export OS_USERNAME
    export OS_USER_DOMAIN_NAME
    export OS_PROJECT_DOMAIN_NAME
    export OS_IDENTITY_API_VERSION
    echo -e "${YELLOW}OpenStack environment set to project: $OS_PROJECT_NAME, user: $OS_USERNAME.${NC}"
else
    echo -e "${RED}OpenStack RC file not found at /home/reda/devstack/openrc. Exiting.${NC}"
    exit 1
fi

# Source OpenStack credentials if not already done
# if [ -z "$OS_AUTH_URL" ]; then
#     if [ -f /home/reda/devstack/openrc ]; then
#         echo -e "${YELLOW}Sourcing OpenStack credentials...${NC}"
#         source /home/reda/devstack/openrc admin admin
#     else
#         echo -e "${RED}OpenStack RC file not found. Please provide the path to the openrc file.${NC}"
#         read -p "Path to openrc file: " OPENRC_PATH
#         if [ -f "$OPENRC_PATH" ]; then
#             source "$OPENRC_PATH"
#         else
#             echo -e "${RED}Invalid openrc file path.${NC}"
#             exit 1
#         fi
#     fi
# fi

# Check if SSH key exists, create if not
echo -e "${YELLOW}Checking for SSH key...${NC}"
if ! openstack keypair show "$SSH_KEY_NAME" &>/dev/null; then
    echo -e "${YELLOW}Creating new SSH key pair...${NC}"
    if [ ! -f ~/.ssh/id_rsa.pub ]; then
        echo -e "${YELLOW}Generating new SSH key...${NC}"
        ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
    fi
    openstack keypair create --public-key ~/.ssh/id_rsa.pub "$SSH_KEY_NAME"
else
    echo -e "${YELLOW}Using existing SSH key: $SSH_KEY_NAME${NC}"
fi

# Create flavors if they don't exist
echo -e "${YELLOW}Checking for required flavors...${NC}"
if ! openstack flavor show "$FLAVOR_NAME_MASTER" &>/dev/null; then
    openstack flavor create --ram 8192 --disk 40 --vcpus 4 "$FLAVOR_NAME_MASTER"
fi
if ! openstack flavor show "$FLAVOR_NAME_WORKER" &>/dev/null; then
    openstack flavor create --ram 4096 --disk 20 --vcpus 2 "$FLAVOR_NAME_WORKER"
fi

# Helper function to check last command and exit on failure
check_success() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: $1${NC}"
        exit 1
    fi
}

# Create network if it doesn't exist
echo -e "${YELLOW}Creating network infrastructure...${NC}"
if ! openstack network show "$NETWORK_NAME" &>/dev/null; then
    openstack network create "$NETWORK_NAME"
    check_success "Failed to create network $NETWORK_NAME"
    openstack subnet create --network "$NETWORK_NAME" --subnet-range "$SUBNET_CIDR" "$SUBNET_NAME"
    check_success "Failed to create subnet $SUBNET_NAME"
else
    echo -e "${YELLOW}Network $NETWORK_NAME already exists.${NC}"
fi

# Create router if it doesn't exist
if ! openstack router show "$ROUTER_NAME" &>/dev/null; then
    openstack router create "$ROUTER_NAME"
    check_success "Failed to create router $ROUTER_NAME"
    openstack router add subnet "$ROUTER_NAME" "$SUBNET_NAME"
    check_success "Failed to add subnet $SUBNET_NAME to router $ROUTER_NAME"
    EXTERNAL_NETWORK=$(openstack network list --external -f value -c Name | head -n 1)
    if [ -n "$EXTERNAL_NETWORK" ]; then
        echo -e "${YELLOW}Connecting router to external network: $EXTERNAL_NETWORK${NC}"
        openstack router set --external-gateway "$EXTERNAL_NETWORK" "$ROUTER_NAME"
        check_success "Failed to set external gateway for router $ROUTER_NAME"
    else
        echo -e "${RED}No external network found. Router will not have external connectivity.${NC}"
    fi
else
    echo -e "${YELLOW}Router $ROUTER_NAME already exists.${NC}"
    # Ensure subnet is attached to router (idempotent)
    if ! openstack router show "$ROUTER_NAME" -c interfaces_info -f json | grep -q $(openstack subnet show "$SUBNET_NAME" -f value -c id); then
        openstack router add subnet "$ROUTER_NAME" "$SUBNET_NAME"
        check_success "Failed to add subnet $SUBNET_NAME to router $ROUTER_NAME"
        echo -e "${YELLOW}Added subnet $SUBNET_NAME to router $ROUTER_NAME${NC}"
    fi
fi




# Create security group and rules
echo -e "${YELLOW}Setting up security group...${NC}"
# Get the security group ID for the given name (pick the first one if multiple)
SECURITY_GROUP_ID=$(openstack security group list -f value -c ID -c Name | grep "$SECURITY_GROUP_NAME" | awk '{print $1}' | tail -n 1)
if [ -z "$SECURITY_GROUP_ID" ]; then
    # If not found, create it
    SECURITY_GROUP_ID=$(openstack security group create "$SECURITY_GROUP_NAME" --description "Security group for cluster" -f value -c id)
    echo -e "${YELLOW}Created security group $SECURITY_GROUP_NAME with ID $SECURITY_GROUP_ID${NC}"
else
    echo -e "${YELLOW}Using existing security group $SECURITY_GROUP_NAME with ID $SECURITY_GROUP_ID${NC}"
fi

# Add SSH rule (without checking first)
echo -e "${YELLOW}Ensuring SSH access is allowed...${NC}"
openstack security group rule create --protocol tcp --dst-port 22 "$SECURITY_GROUP_ID" &>/dev/null || {
    echo -e "${YELLOW}SSH rule already exists in security group $SECURITY_GROUP_NAME${NC}"
}
# Always ensure SSH rule exists (idempotent)
# if ! openstack security group rule list "$SECURITY_GROUP_ID" -f value -c Protocol -c "Port Range" | grep -E "tcp.*22(:22)?" > /dev/null; then
#     openstack security group rule create --protocol tcp --dst-port 22 "$SECURITY_GROUP_ID"
#     echo -e "${YELLOW}Added SSH rule to security group $SECURITY_GROUP_NAME${NC}"
# else
#     echo -e "${YELLOW}SSH rule already exists in security group $SECURITY_GROUP_NAME${NC}"
# fi

# No image upload, just check for existing image
if ! openstack image show "$IMAGE_NAME" &>/dev/null; then
    echo -e "${RED}Image $IMAGE_NAME not found. Please ensure it exists in OpenStack.${NC}"
    exit 1
else
    echo -e "${YELLOW}Image $IMAGE_NAME found.${NC}"
fi

# Create master node(s)
echo -e "${YELLOW}Creating $MASTER_COUNT master node(s)...${NC}"
for i in $(seq 1 $MASTER_COUNT); do
    NODE_NAME="${CLUSTER_NAME}-master-${i}"
    if ! openstack server show "$NODE_NAME" &>/dev/null; then
        echo -e "${YELLOW}Creating master node: $NODE_NAME${NC}"
        openstack server create \
            --flavor "$FLAVOR_NAME_MASTER" \
            --image "$IMAGE_NAME" \
            --key-name "$SSH_KEY_NAME" \
            --security-group "$SECURITY_GROUP_ID" \
            --network "$NETWORK_NAME" \
            "$NODE_NAME"
    else
        echo -e "${YELLOW}Master node $NODE_NAME already exists.${NC}"
    fi
    # Assign floating IP if external network exists
    EXTERNAL_NETWORK=$(openstack network list --external -f value -c Name | head -n 1)
    if [ -n "$EXTERNAL_NETWORK" ]; then
        # Wait a moment for the server to be fully ready
        echo -e "${YELLOW}Waiting for server $NODE_NAME to be ready...${NC}"
        sleep 5
        
        # Check if node already has a floating IP assigned using multiple methods
        EXISTING_FLOATING_IP=$(openstack server show "$NODE_NAME" -f json | jq -r '.addresses | to_entries[] | .value[] | select(.["OS-EXT-IPS:type"] == "floating") | .addr' 2>/dev/null | head -n 1)
        
        # Alternative check using floating IP list
        SERVER_PORTS=$(openstack port list --server "$NODE_NAME" -f value -c ID)
        HAS_FLOATING_IP=false
        for port in $SERVER_PORTS; do
            if openstack floating ip list --port "$port" -f value -c "Floating IP Address" | grep -q .; then
                HAS_FLOATING_IP=true
                EXISTING_FLOATING_IP=$(openstack floating ip list --port "$port" -f value -c "Floating IP Address" | head -n 1)
                break
            fi
        done
        
        if [ "$HAS_FLOATING_IP" = "false" ] && ([ -z "$EXISTING_FLOATING_IP" ] || [ "$EXISTING_FLOATING_IP" = "null" ]); then
            echo -e "${YELLOW}Assigning floating IP to $NODE_NAME${NC}"
            FLOATING_IP=$(openstack floating ip create "$EXTERNAL_NETWORK" -f value -c floating_ip_address)
            openstack server add floating ip "$NODE_NAME" "$FLOATING_IP"
            echo -e "${GREEN}Assigned floating IP $FLOATING_IP to $NODE_NAME${NC}"
        else
            echo -e "${YELLOW}Node $NODE_NAME already has floating IP: $EXISTING_FLOATING_IP${NC}"
        fi
    fi
done

# Create worker node(s)
echo -e "${YELLOW}Creating $WORKER_COUNT worker node(s)...${NC}"
for i in $(seq 1 $WORKER_COUNT); do
    NODE_NAME="${CLUSTER_NAME}-worker-${i}"
    if ! openstack server show "$NODE_NAME" &>/dev/null; then
        echo -e "${YELLOW}Creating worker node: $NODE_NAME${NC}"
        openstack server create \
            --flavor "$FLAVOR_NAME_WORKER" \
            --image "$IMAGE_NAME" \
            --key-name "$SSH_KEY_NAME" \
            --security-group "$SECURITY_GROUP_ID" \
            --network "$NETWORK_NAME" \
            "$NODE_NAME"
    else
        echo -e "${YELLOW}Worker node $NODE_NAME already exists.${NC}"
    fi
    # Assign floating IP if external network exists
    if [ -n "$EXTERNAL_NETWORK" ]; then
        # Wait a moment for the server to be fully ready
        echo -e "${YELLOW}Waiting for server $NODE_NAME to be ready...${NC}"
        sleep 5
        
        # Check if node already has a floating IP assigned using multiple methods
        EXISTING_FLOATING_IP=$(openstack server show "$NODE_NAME" -f json | jq -r '.addresses | to_entries[] | .value[] | select(.["OS-EXT-IPS:type"] == "floating") | .addr' 2>/dev/null | head -n 1)
        
        # Alternative check using floating IP list
        SERVER_PORTS=$(openstack port list --server "$NODE_NAME" -f value -c ID)
        HAS_FLOATING_IP=false
        for port in $SERVER_PORTS; do
            if openstack floating ip list --port "$port" -f value -c "Floating IP Address" | grep -q .; then
                HAS_FLOATING_IP=true
                EXISTING_FLOATING_IP=$(openstack floating ip list --port "$port" -f value -c "Floating IP Address" | head -n 1)
                break
            fi
        done
        
        if [ "$HAS_FLOATING_IP" = "false" ] && ([ -z "$EXISTING_FLOATING_IP" ] || [ "$EXISTING_FLOATING_IP" = "null" ]); then
            echo -e "${YELLOW}Assigning floating IP to $NODE_NAME${NC}"
            FLOATING_IP=$(openstack floating ip create "$EXTERNAL_NETWORK" -f value -c floating_ip_address)
            openstack server add floating ip "$NODE_NAME" "$FLOATING_IP"
            echo -e "${GREEN}Assigned floating IP $FLOATING_IP to $NODE_NAME${NC}"
        else
            echo -e "${YELLOW}Node $NODE_NAME already has floating IP: $EXISTING_FLOATING_IP${NC}"
        fi
    fi
done

echo -e "${GREEN}Infrastructure provisioning completed!${NC}"
echo -e "${YELLOW}Master node(s):${NC}"
openstack server list --name "${CLUSTER_NAME}-master-" -f value -c Name -c Networks

echo -e "${YELLOW}Worker node(s):${NC}"
openstack server list --name "${CLUSTER_NAME}-worker-" -f value -c Name -c Networks

echo -e "${GREEN}Next steps:${NC}"
echo -e "${YELLOW}1. SSH into the master and worker nodes to set up your environment as needed.${NC}"
echo -e "${YELLOW}2. Install K3s, Kubernetes, or any other software manually or via your own scripts.${NC}"
echo -e "${YELLOW}3. Use the floating IPs (if assigned) for external SSH access.${NC}"
