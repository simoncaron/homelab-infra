module "app_newt01" {
  source = "../modules/proxmox_app_ct"

  name = "newt01"

  image = {
    reference = "docker.io/fosrl/newt:1.7.0"
  }

  tags = ["docker", "newt", "oci"]

  environment = {
    PANGOLIN_ENDPOINT = "https://pg.simn.io"
    NEWT_ID           = data.ansiblevault_string.newt_id.value
    NEWT_SECRET       = data.ansiblevault_string.newt_secret.value
    LOG_LEVEL         = "INFO"
  }

  networking = {
    bridge = "vnet2"
  }
}