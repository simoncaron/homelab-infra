terraform {
  required_providers {
    talos = {
      source = "siderolabs/talos"
    }
    local = {
      source = "hashicorp/local"
    }
    time = {
      source = "hashicorp/time"
    }
    null = {
      source = "hashicorp/null"
    }
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}
