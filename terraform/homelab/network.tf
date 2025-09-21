resource "proxmox_virtual_environment_sdn_zone_simple" "sdn_zone_priv01" {
  id    = "znpriv01"
  nodes = ["pve01"]

  ipam = "pve"
}

resource "proxmox_virtual_environment_sdn_zone_simple" "sdn_zone_pub01" {
  id    = "znpub01"
  nodes = ["pve01"]

  ipam = "pve"
}