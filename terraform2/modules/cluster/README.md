# Cluster Module

This module manages all OpenStack resources needed for a Kubernetes cluster in a single region.

## Resources
- Network, subnet, router
- Security groups
- Compute instances (masters, workers)
- Floating IPs

## Usage
Call this module from your root `main.tf` with the appropriate provider and variables.
