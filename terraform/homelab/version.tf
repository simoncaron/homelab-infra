terraform {
  required_version = ">= 1.3.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.85.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.11.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.23.0"
    }
    adguard = {
      source  = "gmichels/adguard"
      version = "1.6.2"
    }
    ovh = {
      source  = "ovh/ovh"
      version = "2.8.0"
    }
    ansiblevault = {
      source  = "MeilleursAgents/ansiblevault"
      version = "3.0.1"
    }
  }
}
