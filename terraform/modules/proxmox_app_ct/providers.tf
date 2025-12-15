terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
    restapi = {
      source = "Mastercard/restapi"
    }
    adguard = {
      source = "gmichels/adguard"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}