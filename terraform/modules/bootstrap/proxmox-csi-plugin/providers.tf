terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}