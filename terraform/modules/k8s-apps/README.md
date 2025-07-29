# k8s-apps Module

This module manages all Kubernetes resources for your applications.

## Resources
- Deployments (PostgreSQL, Prometheus, API, etc.)
- Services (NodePort, ClusterIP)
- Horizontal Pod Autoscalers (HPA)
- ConfigMaps

## Usage
Call this module from your root `main.tf` after your cluster is up and kubeconfig is available.
