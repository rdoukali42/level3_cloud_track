# Outputs for cluster (OpenStack infra) module

# Define outputs for network IDs, instance IPs, etc.

output "cluster_summary" {
  description = "Summary of the created cluster"
  value = {
    cluster_name    = var.cluster_name
    master_count    = length(openstack_compute_instance_v2.master_nodes)
    worker_count    = length(openstack_compute_instance_v2.worker_nodes)
    total_nodes     = length(openstack_compute_instance_v2.master_nodes) + length(openstack_compute_instance_v2.worker_nodes)
    network_cidr    = var.network_cidr
  }
}

output "master_instances" {
  description = "Master node instances information"
  value = {
    for idx, instance in openstack_compute_instance_v2.master_nodes : 
    instance.name => {
      id              = instance.id
      private_ip      = instance.network[0].fixed_ip_v4
      floating_ip     = openstack_networking_floatingip_v2.cluster_floatingips[idx].address
      status          = instance.power_state
    }
  }
}

output "worker_instances" {
  description = "Worker node instances information"
  value = {
    for idx, instance in openstack_compute_instance_v2.worker_nodes : 
    instance.name => {
      id              = instance.id
      private_ip      = instance.network[0].fixed_ip_v4
      floating_ip     = openstack_networking_floatingip_v2.cluster_floatingips[var.master_count + idx].address
      status          = instance.power_state
    }
  }
}

output "network_info" {
  description = "Network information"
  value = {
    network_id    = openstack_networking_network_v2.cluster_network.id
    network_name  = openstack_networking_network_v2.cluster_network.name
    subnet_id     = openstack_networking_subnet_v2.cluster_subnet.id
    subnet_cidr   = openstack_networking_subnet_v2.cluster_subnet.cidr
    router_id     = openstack_networking_router_v2.cluster_router.id
  }
}

output "security_group_info" {
  description = "Security group information"
  value = {
    id   = openstack_networking_secgroup_v2.cluster_secgroup.id
    name = openstack_networking_secgroup_v2.cluster_secgroup.name
  }
}

output "master_floating_ips" {
  description = "Floating IPs for master nodes."
  value       = [for i in range(var.master_count) : openstack_networking_floatingip_v2.cluster_floatingips[i].address]
}

output "worker_floating_ips" {
  description = "Floating IPs for worker nodes."
  value       = [for i in range(var.worker_count) : openstack_networking_floatingip_v2.cluster_floatingips[var.master_count + i].address]
}

output "master_instance_ids" {
  description = "IDs of master node instances."
  value       = openstack_compute_instance_v2.master_nodes[*].id
}

output "worker_instance_ids" {
  description = "IDs of worker node instances."
  value       = openstack_compute_instance_v2.worker_nodes[*].id
}

output "network_id" {
  description = "ID of the cluster network."
  value       = openstack_networking_network_v2.cluster_network.id
}

output "subnet_id" {
  description = "ID of the cluster subnet."
  value       = openstack_networking_subnet_v2.cluster_subnet.id
}

output "k3s_token" {
  description = "K3s cluster token (sensitive)"
  value       = random_string.k3s_token.result
  sensitive   = true
}

output "cluster_kubeconfig_command" {
  description = "Command to retrieve the kubeconfig from the master node"
  value       = var.master_count > 0 ? "ssh -i ${var.private_key_path} ${var.ssh_user}@${openstack_networking_floatingip_v2.cluster_floatingips[0].address} 'sudo cat /etc/rancher/k3s/k3s.yaml'" : "No master nodes created"
}