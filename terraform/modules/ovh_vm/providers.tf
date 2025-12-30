terraform {
  required_providers {
    ovh = {
      source = "ovh/ovh"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    powerdns = {
      source = "pan-net/powerdns"
    }
  }
}
