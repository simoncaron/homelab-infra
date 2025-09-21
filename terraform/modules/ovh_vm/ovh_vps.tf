resource "ovh_vps" "ovh_cloud_homelab_gateway_01" {
  display_name = "vps-gateway01"
  memory_limit = 2048
  model = {
    disk                   = 20
    maximum_additionnal_ip = 16
    memory                 = 2048
    name                   = "vps-starter-1-2-20"
    offer                  = "VPS vps2020-starter-1-2-20"
    vcore                  = 1
    version                = "2019v1"
  }
  name           = "vps-0af37821.vps.ovh.ca"
  netboot_mode   = "local"
  offer_type     = "ssd"
  ovh_subsidiary = null
  plan           = []
  state          = "running"
  vcore          = 1
  zone           = "Region OpenStack: os-bhs6"
}
