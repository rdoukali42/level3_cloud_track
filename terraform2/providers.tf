# Providers for terraform2

provider "openstack" {
  # region, credentials, etc. should be set via variables or environment
}

# Example for multiple regions (add aliases as needed)
# provider "openstack" {
#   alias  = "DE"
#   region = "Germany"
#   # ...
# }
# provider "openstack" {
#   alias  = "MR"
#   region = "Morocco"
#   # ...
# }


provider "kubernetes" {
  config_path = var.kubeconfig_path
  insecure    = true
}
