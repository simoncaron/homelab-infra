resource "proxmox_virtual_environment_dns" "pve_dns" {
  for_each  = var.pve_cluster_nodes
  domain    = var.dns_config.domain
  node_name = each.key

  servers = var.dns_config.servers
}
