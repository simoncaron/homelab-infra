provider "ansiblevault" {
  root_folder = "../../ansible"
  vault_pass  = var.ansible_vault_password
}

provider "proxmox" {
  endpoint = "https://pve01.simn.io:8006/"
  username = data.ansiblevault_string.proxmox_user.value
  password = data.ansiblevault_string.proxmox_password.value

  ssh {
    agent    = true
    username = "terraform"
  }
}

provider "adguard" {
  host     = "dns01.simn.io"
  username = data.ansiblevault_string.adguard_home_username.value
  password = data.ansiblevault_string.adguard_home_password.value
  timeout  = 30
}

provider "cloudflare" {
  api_token = data.ansiblevault_string.cloudflare_api_token.value
}

provider "ovh" {
  endpoint           = "ovh-ca"
  application_key    = data.ansiblevault_string.ovhcloud_application_key.value
  application_secret = data.ansiblevault_string.ovhcloud_application_secret.value
  consumer_key       = data.ansiblevault_string.ovhcloud_consumer_key.value
}

provider "tailscale" {
  oauth_client_id     = data.ansiblevault_string.tailscale_oauth_client_id.value
  oauth_client_secret = data.ansiblevault_string.tailscale_oauth_client_secret.value
  scopes              = ["all"]
}

provider "restapi" {
  uri                  = "https://pve01.simn.io:8006/"
  write_returns_object = true

  headers = {
    "Content-Type"  = "application/json"
    "Authorization" = "PVEAPIToken=${data.ansiblevault_string.proxmox_api_token.value}"
  }
}
