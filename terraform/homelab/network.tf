resource "proxmox_virtual_environment_sdn_zone_simple" "sdn_zone_priv01" {
  id    = "znpriv01"
  nodes = ["pve01"]

  ipam = "pve"

  depends_on = [
    proxmox_virtual_environment_sdn_applier.finalizer
  ]
}

resource "proxmox_virtual_environment_sdn_zone_simple" "sdn_zone_pub01" {
  id    = "znpub01"
  nodes = ["pve01"]

  ipam = "pve"

  depends_on = [
    proxmox_virtual_environment_sdn_applier.finalizer
  ]
}

resource "proxmox_virtual_environment_sdn_vnet" "sdn_vnet_priv1" {
  id   = "vnet1"
  zone = proxmox_virtual_environment_sdn_zone_simple.sdn_zone_priv01.id

  depends_on = [
    proxmox_virtual_environment_sdn_applier.finalizer
  ]
}

resource "proxmox_virtual_environment_sdn_vnet" "sdn_vnet_pub1" {
  id   = "vnet2"
  zone = proxmox_virtual_environment_sdn_zone_simple.sdn_zone_pub01.id

  depends_on = [
    proxmox_virtual_environment_sdn_applier.finalizer
  ]
}

resource "proxmox_virtual_environment_sdn_subnet" "sdn_subnet_priv1" {
  cidr    = "10.10.10.0/24"
  gateway = "10.10.10.1"

  vnet = proxmox_virtual_environment_sdn_vnet.sdn_vnet_priv1.id
  snat = true

  depends_on = [
    proxmox_virtual_environment_sdn_applier.finalizer
  ]
}

resource "proxmox_virtual_environment_sdn_subnet" "sdn_subnet_pub1" {
  cidr    = "10.10.20.0/24"
  gateway = "10.10.20.1"

  vnet = proxmox_virtual_environment_sdn_vnet.sdn_vnet_pub1.id
  snat = true

  depends_on = [
    proxmox_virtual_environment_sdn_applier.finalizer
  ]
}

# SDN Applier for all resources
resource "proxmox_virtual_environment_sdn_applier" "subnet_applier" {
  depends_on = [
    proxmox_virtual_environment_sdn_zone_simple.sdn_zone_priv01,
    proxmox_virtual_environment_sdn_zone_simple.sdn_zone_pub01,
    proxmox_virtual_environment_sdn_vnet.sdn_vnet_priv1,
    proxmox_virtual_environment_sdn_vnet.sdn_vnet_pub1,
    proxmox_virtual_environment_sdn_subnet.sdn_subnet_priv1,
    proxmox_virtual_environment_sdn_subnet.sdn_subnet_pub1
  ]
}

resource "proxmox_virtual_environment_sdn_applier" "finalizer" {
}