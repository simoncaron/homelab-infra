terraform {
  required_providers {
    talos = {
      source = "siderolabs/talos"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.12.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}
