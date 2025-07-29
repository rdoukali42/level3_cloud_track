# Variables (replace PUBLIC_IP with your DevStack host's public IP)
PUBLIC_PORT="30081"                   # Public port for K3s API
INSTANCE_PRIVATE_IP="172.24.4.144"    # Floating IP of the K3s master node
INSTANCE_PRIVATE_PORT="30081"         # K3s API por
NETWORK_INTERFACE="eth0"             # Adjust to your DevStack host's internet-facing interface

# 1. Add a DNAT rule to forward traffic from public IP:public_port to instance_private_ip:instance_private_port
sudo iptables -t nat -A PREROUTING -i $NETWORK_INTERFACE -p tcp --dport $PUBLIC_PORT -j DNAT --to-destination $INSTANCE_PRIVATE_IP:$INSTANCE_PRIVATE_PORT

# 2. Add a MASQUERADE rule for traffic originating from the instance
sudo iptables -t nat -A POSTROUTING -o $NETWORK_INTERFACE -j MASQUERADE

# 3. Allow forwarded traffic in the filter table (FORWARD chain)
sudo iptables -A FORWARD -p tcp -d $INSTANCE_PRIVATE_IP --dport $INSTANCE_PRIVATE_PORT -j ACCEPT

# 4. Enable IP forwarding (if not already enabled)
sudo sysctl -w net.ipv4.ip_forward=1

# Optional: Save iptables rules to persist across reboots (method depends on OS)
# For Ubuntu/Debian, you might use:
# sudo iptables-save > /etc/iptables/rules.v4