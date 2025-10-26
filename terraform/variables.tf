# Root variables for terraform2

variable "ssh_key_name" {
  description = "Name for the OpenStack SSH keypair."
  type        = string
  default     = "k8s-key"
}

variable "public_key_path" {
  description = "Path to the public SSH key file."
  type        = string
  default     = "~/.ssh/id_rsa.pub"  # Update this to your key path
}

variable "image_name" {
  description = "Name of the OpenStack image to use for instances."
  type        = string
  default     = "ubuntu-min"
}

variable "cluster_name" {
  description = "Name prefix for cluster resources."
  type        = string
  default     = "k8s-cluster"
}

variable "network_cidr" {
  description = "CIDR block for the cluster network."
  type        = string
  default     = "192.168.100.0/24"
}

variable "dns_nameservers" {
  description = "List of DNS nameservers for the subnet."
  type        = list(string)
  default     = ["8.8.8.8", "1.1.1.1"]
}

variable "master_count" {
  description = "Number of master nodes."
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes."
  type        = number
  default     = 2
}

variable "master_flavor" {
  description = "OpenStack flavor for master nodes."
  type        = string
  default     = "m1.large"
}

variable "worker_flavor" {
  description = "OpenStack flavor for worker nodes."
  type        = string
  default     = "m1.large"
}

variable "ssh_user" {
  description = "SSH username for remote-exec provisioners."
  type        = string
  default     = "ubuntu"
}

variable "private_key_path" {
  description = "Path to the private SSH key file."
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "master_user_data" {
  description = "Cloud-init user data for master nodes."
  type        = string
  default     = ""
}

variable "worker_user_data" {
  description = "Cloud-init user data for worker nodes."
  type        = string
  default     = ""
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig for Kubernetes provider"
  type        = string
  default     = "~/.kube/k3s-config"
}

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default = {
    Environment = "development"
    Project     = "k8s-cluster"
    ManagedBy   = "terraform"
  }
}