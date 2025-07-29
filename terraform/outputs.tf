# Root-level outputs for terraform2

# Output values for easy access to cluster information

output "master_instances" {
  description = "Master node instances information"
  value = module.cluster.master_instance_ids
}

output "worker_instances" {
  description = "Worker node instances information"
  value = module.cluster.worker_instance_ids
}

output "network_info" {
  description = "Network information"
  value = {
    network_id    = module.cluster.network_id
    subnet_id     = module.cluster.subnet_id
  }
}

output "master_floating_ips" {
  description = "List of master node floating IPs"
  value       = module.cluster.master_floating_ips
}

output "worker_floating_ips" {
  description = "List of worker node floating IPs"
  value       = module.cluster.worker_floating_ips
}

output "ssh_user" {
  description = "SSH user for connecting to instances"
  value       = var.ssh_user
}

output "private_key_path" {
  description = "Path to the SSH private key file"
  value       = var.private_key_path
}
