# terraform2

This is a clean, modular Terraform architecture for your OpenStack and Kubernetes infrastructure.

- All infrastructure code is organized into modules.
- Root files orchestrate the deployment and call modules.
- See `modules/cluster` for OpenStack cluster resources.
- See `modules/k8s-apps` for Kubernetes application resources.

Edit `main.tf` and variable files in this directory to control your deployment.
