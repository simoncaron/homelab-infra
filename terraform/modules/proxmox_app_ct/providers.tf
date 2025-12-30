terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
    restapi = {
      source = "Mastercard/restapi"
    }
    null = {
      source = "hashicorp/null"
    }
    powerdns = {
      source = "pan-net/powerdns"
    }
  }
}