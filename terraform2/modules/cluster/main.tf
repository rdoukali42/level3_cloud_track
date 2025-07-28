# Cluster (OpenStack infrastructure) module
# Migrated and parameterized from original main.tf
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


resource "openstack_compute_keypair_v2" "cluster_key" {
  name       = var.ssh_key_name
  public_key = file(var.public_key_path)
  lifecycle {
    ignore_changes = [public_key]
  }
}

data "openstack_networking_network_v2" "external" {
  external = true
}

data "openstack_images_image_v2" "cluster_image" {
  name        = var.image_name
  most_recent = true
}

resource "openstack_networking_network_v2" "cluster_network" {
  name           = "${var.cluster_name}-network"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "cluster_subnet" {
  name            = "${var.cluster_name}-subnet"
  network_id      = openstack_networking_network_v2.cluster_network.id
  cidr            = var.network_cidr
  ip_version      = 4
  dns_nameservers = var.dns_nameservers
}

resource "openstack_networking_router_v2" "cluster_router" {
  name                = "${var.cluster_name}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "cluster_router_interface" {
  router_id = openstack_networking_router_v2.cluster_router.id
  subnet_id = openstack_networking_subnet_v2.cluster_subnet.id
}

resource "openstack_networking_secgroup_v2" "cluster_secgroup" {
  name        = "${var.cluster_name}-secgroup"
  description = "Security group for ${var.cluster_name}"
}

resource "openstack_networking_secgroup_rule_v2" "ssh_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.cluster_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "ssh_access_ipv6" {
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "::/0"
  security_group_id = openstack_networking_secgroup_v2.cluster_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "nodeport_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32767
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.cluster_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "k8s_api_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.cluster_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "cluster_internal" {
direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = null
  remote_ip_prefix  = var.network_cidr
  security_group_id = openstack_networking_secgroup_v2.cluster_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "pod_network_all" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = null
  remote_ip_prefix  = "10.42.0.0/16"
  security_group_id = openstack_networking_secgroup_v2.cluster_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "allow_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.cluster_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "allow_dns_udp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 53
  port_range_max    = 53
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.cluster_secgroup.id
}

# resource "openstack_networking_secgroup_rule_v2" "allow_all_egress" {
#   direction         = "egress"
#   ethertype         = "IPv4"
#   security_group_id = openstack_networking_secgroup_v2.cluster_secgroup.id
# }

resource "openstack_networking_floatingip_v2" "cluster_floatingips" {
  count = var.master_count + var.worker_count
  pool  = data.openstack_networking_network_v2.external.name
}

resource "openstack_networking_port_v2" "cluster_ports" {
  count          = var.master_count + var.worker_count
  name           = "${var.cluster_name}-port-${count.index + 1}"
  network_id     = openstack_networking_network_v2.cluster_network.id
  admin_state_up = true
  port_security_enabled = true
  security_group_ids = [openstack_networking_secgroup_v2.cluster_secgroup.id]
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.cluster_subnet.id
  }
}

resource "openstack_networking_floatingip_associate_v2" "cluster_fip_assoc" {
  count       = var.master_count + var.worker_count
  floating_ip = openstack_networking_floatingip_v2.cluster_floatingips[count.index].address
  port_id     = openstack_networking_port_v2.cluster_ports[count.index].id
  depends_on  = [openstack_networking_router_interface_v2.cluster_router_interface]
}

resource "random_string" "k3s_token" {
  length  = 32
  special = false
}

resource "openstack_compute_instance_v2" "master_nodes" {
  count           = var.master_count
  name            = "${var.cluster_name}-master-${count.index + 1}"
  image_name      = data.openstack_images_image_v2.cluster_image.name
  flavor_name     = var.master_flavor
  key_pair        = openstack_compute_keypair_v2.cluster_key.name
  security_groups = [openstack_networking_secgroup_v2.cluster_secgroup.name]
  network {
    uuid = openstack_networking_network_v2.cluster_network.id
    port = openstack_networking_port_v2.cluster_ports[count.index].id
  }
  metadata = {
    role    = "master"
    cluster = var.cluster_name
  }
  user_data = var.master_user_data
  depends_on = [
    openstack_networking_floatingip_associate_v2.cluster_fip_assoc,
    openstack_networking_router_interface_v2.cluster_router_interface
  ]

   provisioner "remote-exec" {
    when = create
    inline = [
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables iptables-persistent",
      
      # Install K3s with specific configuration for OpenStack
      "curl -sfL https://get.k3s.io | K3S_TOKEN=${random_string.k3s_token.result} INSTALL_K3S_EXEC='--tls-san ${openstack_networking_floatingip_v2.cluster_floatingips[count.index].address} --node-external-ip ${openstack_networking_floatingip_v2.cluster_floatingips[count.index].address} --node-ip ${openstack_networking_port_v2.cluster_ports[count.index].all_fixed_ips[0]}' sh -s - --disable=traefik",
      
      "sudo systemctl enable k3s",
      "sleep 10",
      
      # Create kubeconfig
      "sudo mkdir -p /home/ubuntu/.kube",
      "sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/k3s-config",
      "sudo chown ubuntu:ubuntu /home/ubuntu/.kube/k3s-config",
      "sudo sed -i 's/127.0.0.1/${openstack_networking_floatingip_v2.cluster_floatingips[count.index].address}/g' /home/ubuntu/.kube/k3s-config",
      
      # Configure kube-proxy for OpenStack
      "sleep 20",
      "sudo kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get configmap kube-proxy -n kube-system -o yaml > /tmp/kube-proxy-config.yaml",
      "sudo sed -i 's/mode: \"\"/mode: \"iptables\"/g' /tmp/kube-proxy-config.yaml",
      "sudo kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml apply -f /tmp/kube-proxy-config.yaml",
      
      # Add iptables rules for NodePort forwarding
      "sudo iptables -t nat -A PREROUTING -p tcp --dport 30000:32767 -j DNAT --to-destination ${openstack_networking_port_v2.cluster_ports[count.index].all_fixed_ips[0]}",
      "sudo iptables -t nat -A POSTROUTING -p tcp --dport 30000:32767 -j MASQUERADE",
      "sudo iptables-save | sudo tee /etc/iptables/rules.v4",
      
      # Restart K3s services
      "sudo systemctl restart k3s"
    ]
    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.private_key_path)
      host        = openstack_networking_floatingip_v2.cluster_floatingips[count.index].address
      timeout     = "5m"
    }
  }
  
  provisioner "local-exec" {
    when = create
    command = <<-EOT
      mkdir -p ~/.kube
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.private_key_path} ${var.ssh_user}@${openstack_networking_floatingip_v2.cluster_floatingips[count.index].address}:~/.kube/k3s-config ~/.kube/k3s-config
      chmod 600 ~/.kube/k3s-config
    EOT
  }
  # Provisioners omitted for brevity; add as needed
}

resource "null_resource" "download_kubeconfig" {
  depends_on = [
    openstack_compute_instance_v2.master_nodes[0]
  ]

  triggers = {
    master_instance_id = openstack_compute_instance_v2.master_nodes[0].id
    floating_ip = openstack_networking_floatingip_v2.cluster_floatingips[0].address
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for kubeconfig to be ready..."
      sleep 30
      mkdir -p ~/.kube
      
      for i in {1..5}; do
        if scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30 -i ${var.private_key_path} ${var.ssh_user}@${openstack_networking_floatingip_v2.cluster_floatingips[0].address}:~/.kube/k3s-config ~/.kube/k3s-config; then
          chmod 600 ~/.kube/k3s-config
          echo "✅ Kubeconfig successfully downloaded to ~/.kube/k3s-config"
          break
        else
          echo "⚠️  Attempt $i failed, retrying in 10 seconds..."
          sleep 20
        fi
      done
      
      if kubectl --kubeconfig ~/.kube/k3s-config cluster-info --request-timeout=30s > /dev/null 2>&1; then
        echo "✅ Kubeconfig is working correctly"
        kubectl --kubeconfig ~/.kube/k3s-config get nodes
      else
        echo "❌ Kubeconfig download failed or cluster is not accessible"
        exit 1
      fi
    EOT
  }
}

resource "openstack_compute_instance_v2" "worker_nodes" {
  count           = var.worker_count
  name            = "${var.cluster_name}-worker-${count.index + 1}"
  image_name      = data.openstack_images_image_v2.cluster_image.name
  flavor_name     = var.worker_flavor
  key_pair        = openstack_compute_keypair_v2.cluster_key.name
  security_groups = [openstack_networking_secgroup_v2.cluster_secgroup.name]
  network {
    uuid = openstack_networking_network_v2.cluster_network.id
    port = openstack_networking_port_v2.cluster_ports[var.master_count + count.index].id
  }
  metadata = {
    role    = "worker"
    cluster = var.cluster_name
  }
  user_data = var.worker_user_data
  depends_on = [
    openstack_networking_floatingip_associate_v2.cluster_fip_assoc,
    openstack_networking_router_interface_v2.cluster_router_interface,
    openstack_compute_instance_v2.master_nodes
  ]
  # Provisioners omitted for brevity; add as needed
  provisioner "remote-exec" {
    when = create
    inline = [
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables iptables-persistent",
      
      # Install K3s agent with OpenStack configuration
      "curl -sfL https://get.k3s.io | K3S_URL=https://${openstack_compute_instance_v2.master_nodes[0].network[0].fixed_ip_v4}:6443 K3S_TOKEN=${random_string.k3s_token.result} INSTALL_K3S_EXEC='--node-external-ip ${openstack_networking_floatingip_v2.cluster_floatingips[var.master_count + count.index].address} --node-ip ${openstack_networking_port_v2.cluster_ports[var.master_count + count.index].all_fixed_ips[0]}' sh -",
      
      "sudo systemctl enable k3s-agent",
      "sleep 10",
      
      # Add iptables rules for NodePort forwarding
      "sudo iptables -t nat -A PREROUTING -p tcp --dport 30000:32767 -j DNAT --to-destination ${openstack_networking_port_v2.cluster_ports[var.master_count + count.index].all_fixed_ips[0]}",
      "sudo iptables -t nat -A POSTROUTING -p tcp --dport 30000:32767 -j MASQUERADE",
      "sudo iptables-save | sudo tee /etc/iptables/rules.v4",
      
      # Restart K3s agent
      "sudo systemctl restart k3s-agent"
    ]
    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.private_key_path)
      host        = openstack_networking_floatingip_v2.cluster_floatingips[var.master_count + count.index].address
      timeout     = "5m"
    }
  }
}
