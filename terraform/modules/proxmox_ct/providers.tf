terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
    ansiblevault = {
      source = "MeilleursAgents/ansiblevault"
    }
    powerdns = {
      source = "pan-net/powerdns"
    }
  }
}