terraform {
  required_version = ">= 1.3.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.74.1"
    }
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = "0.13.5"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.1"
    }
    adguard = {
      source  = "gmichels/adguard"
      version = "1.5.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.13.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}