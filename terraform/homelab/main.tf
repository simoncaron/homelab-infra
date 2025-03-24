module "proxmox_cluster" {
  source            = "../modules/proxmox_cluster"
  pve_cluster_nodes = ["pvenuc01", "pvenuc02", "pvenuc03"]

  dns_config = {
    domain  = "simn.io"
    servers = ["192.168.1.10", "192.168.1.114"]
  }

  pools = [
    {
      pool_id = "terraform"
      comment = "Resources managed using terraform"
    },
    {
      pool_id = "manual"
      comment = "Manually created resources"
    },
    {
      pool_id = "ansible"
      comment = "Resources managed using ansible"
    }
  ]
}
