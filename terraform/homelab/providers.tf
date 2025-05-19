provider "proxmox" {
  endpoint = "https://pvenuc01.simn.io:8006/"
  username = data.bitwarden_item_login.proxmox_user.password
  password = data.bitwarden_item_login.proxmox_password.password

  ssh {
    agent    = true
    username = "terraform"
  }
}

provider "bitwarden" {
  server          = "https://bw.simn.io"
  email           = "infra@simn.io"
  master_password = var.bitwarden_master_password
}

provider "talos" {}

provider "kubernetes" {
  host                   = module.talos_cluster.kubeconfig_host
  client_certificate     = module.talos_cluster.kubeconfig_client_certificate
  client_key             = module.talos_cluster.kubeconfig_client_key
  cluster_ca_certificate = module.talos_cluster.kubeconfig_cluster_ca_certificate
}

provider "adguard" {
  host     = "dns01.simn.io"
  username = data.bitwarden_item_login.adguard_home_credentials.username
  password = data.bitwarden_item_login.adguard_home_credentials.password
}
