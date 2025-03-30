terraform {
  required_providers {
    talos = {
      source = "siderolabs/talos"
    }
    local = {
      source = "hashicorp/local"
    }
    null = {
      source = "hashicorp/null"
    }
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}
