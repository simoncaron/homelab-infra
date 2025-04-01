# Talos Cluster Terraform Module

A Terraform module for deploying and managing Talos Linux clusters on Proxmox VE virtual machines.

## Overview

This module provisions a Kubernetes cluster using Talos Linux on Proxmox VE, automating the deployment of control plane and worker nodes with appropriate configurations. It is specifically designed for Proxmox VE environments only.

## Features

- Declarative cluster configuration
- Support for node labeling and configuration
- Network interface customization
- Disk configuration and mounting
- DNS settings management
- Talos-specific configurations (etcd, kubelet, etc.)

## Usage

```hcl
module "talos_cluster" {
  source = "path/to/module"
  
  cluster_name    = "production"
  cluster_endpoint = "10.10.10.10"
  cluster_vip     = "10.10.10.100"
  cluster_node_subnet = "10.10.10.0/24"
  
  machines = {
    "cp-1" = {
      type     = "controlplane"
      pve_node = "proxmox-node1"
      interfaces = [
        {
          hardwareAddr = "AA:BB:CC:DD:EE:FF"
          addresses    = ["10.10.10.11/24"]
        }
      ]
    },
    "worker-1" = {
      type     = "worker"
      pve_node = "proxmox-node2"
      interfaces = [
        {
          hardwareAddr = "AA:BB:CC:DD:EE:00"
          addresses    = ["10.10.10.21/24"]
        }
      ]
    }
  }
  
  kubernetes_version = "1.30.1"
  talos_version     = "v1.9.0"
}
```

See the `variables.tf` file for all available configuration options.

## Credits

This module was inspired by and builds upon the work of:

- [Stone Garden Blog: Talos on Proxmox with Terraform](https://blog.stonegarden.dev/articles/2024/08/talos-proxmox-tofu) and the [associated GitLab repo](https://gitlab.com/vehagn/blog)
- [ionfury's homelab-modules](https://github.com/ionfury/homelab-modules)

## License

MIT