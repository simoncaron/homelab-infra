terraform {
  required_version = ">= 1.3.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.94.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.16.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.26.0"
    }
    ovh = {
      source  = "ovh/ovh"
      version = "2.11.0"
    }
    ansiblevault = {
      source  = "MeilleursAgents/ansiblevault"
      version = "3.0.1"
    }
    powerdns = {
      source  = "pan-net/powerdns"
      version = "1.5.0"
    }
  }
}
