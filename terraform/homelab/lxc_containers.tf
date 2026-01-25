resource "proxmox_virtual_environment_file" "debian_12_container_template" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "pve01"

  source_file {
    path = "http://download.proxmox.com/images/system/debian-12-standard_12.0-1_amd64.tar.zst"
  }
}

resource "proxmox_virtual_environment_file" "debian_13_container_template" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "pve01"

  source_file {
    path = "http://download.proxmox.com/images/system/debian-13-standard_13.1-1_amd64.tar.zst"
  }
}

module "lxc_dns02" {
  source = "../modules/proxmox_ct"

  hostname = "dns02"

  template_file_id = proxmox_virtual_environment_file.debian_13_container_template.id
  tags             = ["debian", "dns-lxc", "tailscale"]

  cpu_cores        = 2
  memory_dedicated = 512
  disk_size        = 8

  features = {
    keyctl = true
  }

  dns_config = {
    domain  = "simn.io"
    servers = ["1.1.1.1", "1.0.0.1"]
  }

  network_interfaces = [
    { name = "eth0", bridge = "vmbr0", ipv4 = { address = "192.168.1.114/24", gateway = "192.168.1.1" } },
    { name = "eth1", bridge = "vnet1", ipv4 = { address = "10.10.10.114/24", gateway = "10.10.10.1" } }
  ]

  device_passthrough = ["/dev/net/tun"]
}

module "lxc_newt01" {
  source = "../modules/proxmox_oci_app"

  name = "newt01"
  image = {
    reference = "docker.io/fosrl/newt:1.9.0"
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

module "lxc_jellyfin01" {
  source = "../modules/proxmox_ct"

  hostname = "jellyfin01"

  template_file_id = proxmox_virtual_environment_file.debian_12_container_template.id
  tags             = ["debian", "jellyfin", "gpu"]

  cpu_cores        = 2
  memory_dedicated = 8192
  disk_size        = 128

  network_interfaces = [{ name = "eth0", bridge = "vnet1" }]

  hook_mount = "/usr/share/lxc/hooks/nvidia"

  environment_variables = {
    NVIDIA_VISIBLE_DEVICES     = "all"
    NVIDIA_DRIVER_CAPABILITIES = "compute,utility,video"
  }

  mount_points = [
    { path = "/media", volume = "/mnt/pve/remote-cifs-truenas01", backup = false }
  ]
}

module "lxc_plex01" {
  source = "../modules/proxmox_ct"

  hostname = "plex01"

  template_file_id = proxmox_virtual_environment_file.debian_12_container_template.id
  tags             = ["debian", "plex", "gpu"]

  cpu_cores        = 2
  memory_dedicated = 8192
  disk_size        = 128

  network_interfaces = [{ name = "eth0", bridge = "vnet2" }]

  hook_mount = "/usr/share/lxc/hooks/nvidia"

  environment_variables = {
    NVIDIA_VISIBLE_DEVICES     = "all"
    NVIDIA_DRIVER_CAPABILITIES = "compute,utility,video"
  }

  # Required for transcoding to work properly in Plex
  device_passthrough = ["/dev/nvidia-modeset", "/dev/nvidia-caps/nvidia-cap1", "/dev/nvidia-caps/nvidia-cap2"]

  mount_points = [
    { path = "/data", volume = "/mnt/pve/remote-cifs-truenas01", backup = false }
  ]
}

module "lxc_tdarr01" {
  source = "../modules/proxmox_oci_app"

  vm_id = "106"
  name  = "tdarr01"
  tags  = ["docker", "tdarr", "oci"]

  cpu    = 4
  memory = 4096

  image = {
    reference = "docker.io/haveagitgat/tdarr:2.58.02"
  }

  environment = {
    TZ           = "America/Toronto"
    serverIP     = "0.0.0.0"
    internalNode = "true"
    nodeIP       = "0.0.0.0"
    nodeID       = "InternalNode"
    PUID         = "10000"
    PGID         = "10000"
  }

  enable_nvidia_gpu = true

  networking = { bridge = "vnet1" }

  volumes = [
    { path = "/app/server", size = "4G" },
    { path = "/app/configs", size = "2G" },
    { path = "/app/logs", size = "2G" },
    { path = "/temp", size = "16G" }
  ]

  bind_mounts = [
    { host_path = "/mnt/pve/remote-cifs-truenas01", container_path = "/mnt/media" }
  ]
}

module "lxc_forgejo01" {
  source = "../modules/proxmox_ct"

  hostname = "forgejo01"

  template_file_id = proxmox_virtual_environment_file.debian_12_container_template.id
  tags             = ["debian", "git", "forgejo"]

  cpu_cores        = 4
  memory_dedicated = 4096
  disk_size        = 128

  network_interfaces = [{ name = "eth0", bridge = "vnet1" }]
}

module "lxc_proxy01" {
  source = "../modules/proxmox_ct"

  hostname = "proxy01"

  template_file_id = proxmox_virtual_environment_file.debian_13_container_template.id
  tags             = ["debian", "proxy", "tailscale"]

  features = {
    keyctl = true
  }

  network_interfaces = [
    { name = "eth0", bridge = "vmbr0", ipv4 = { address = "192.168.1.113/24", gateway = "192.168.1.1" } },
    { name = "eth1", bridge = "vnet1", }
  ]

  device_passthrough = ["/dev/net/tun"]
}

module "lxc_proxy02" {
  source = "../modules/proxmox_ct"

  hostname = "proxy02"

  template_file_id = proxmox_virtual_environment_file.debian_13_container_template.id
  tags             = ["debian", "proxy", "tailscale"]

  features = {
    keyctl = true
  }

  network_interfaces = [
    { name = "eth0", bridge = "vmbr0", ipv4 = { address = "192.168.1.119/24", gateway = "192.168.1.1" } },
    { name = "eth1", bridge = "vnet2" }
  ]

  device_passthrough = ["/dev/net/tun"]
}