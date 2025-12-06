terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
    adguard = {
      source = "gmichels/adguard"
    }
    ansiblevault = {
      source = "MeilleursAgents/ansiblevault"
    }
  }
}