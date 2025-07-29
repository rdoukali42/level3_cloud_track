# Variables for cluster (OpenStack infra) module

# Define variables for region, credentials, network, etc.

variable "ssh_key_name" {
  description = "Name for the OpenStack SSH keypair."
  type        = string
}

variable "public_key_path" {
  description = "Path to the public SSH key file."
  type        = string
}

variable "image_name" {
  description = "Name of the OpenStack image to use for instances."
  type        = string
}

variable "cluster_name" {
  description = "Name prefix for cluster resources."
  type        = string
}

variable "network_cidr" {
  description = "CIDR block for the cluster network."
  type        = string
}

variable "dns_nameservers" {
  description = "List of DNS nameservers for the subnet."
  type        = list(string)
}

variable "master_count" {
  description = "Number of master nodes."
  type        = number
}

variable "worker_count" {
  description = "Number of worker nodes."
  type        = number
}

variable "master_flavor" {
  description = "OpenStack flavor for master nodes."
  type        = string
}

variable "worker_flavor" {
  description = "OpenStack flavor for worker nodes."
  type        = string
}

variable "ssh_user" {
  description = "SSH username for remote-exec provisioners."
  type        = string
}

variable "private_key_path" {
  description = "Path to the private SSH key file."
  type        = string
}

variable "master_user_data" {
  description = "Cloud-init user data for master nodes."
  type        = string
  default     = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - curl
      - wget
    runcmd:
      - sleep 30
  EOF
}

variable "worker_user_data" {
  description = "Cloud-init user data for worker nodes."
  type        = string
  default     = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - curl
      - wget
    runcmd:
      - sleep 30
  EOF
}
