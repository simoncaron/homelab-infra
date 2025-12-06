terraform {
  required_version = ">= 1.3.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.88.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.14.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.24.0"
    }
    adguard = {
      source  = "gmichels/adguard"
      version = "1.6.2"
    }
    ovh = {
      source  = "ovh/ovh"
      version = "2.10.0"
    }
    ansiblevault = {
      source  = "MeilleursAgents/ansiblevault"
      version = "3.0.1"
    }
  }
}
