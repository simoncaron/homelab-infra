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
  source = "../modules/proxmox_lxc"

  vm_id    = 114
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
    {
      name   = "eth0"
      bridge = "vmbr0"
      ipv4   = { address = "192.168.1.114/24", gateway = "192.168.1.1" }
    },
    {
      name   = "eth1"
      bridge = "vnet1"
      ipv4   = { address = "10.10.10.114/24" }
    }
  ]

  passthrough_tun = true
}

module "lxc_newt01" {
  source = "../modules/proxmox_lxc"

  vm_id    = 118
  hostname = "newt01"

  template_file_id = proxmox_virtual_environment_file.debian_13_container_template.id
  tags             = ["debian", "newt", "pangolin"]

  cpu_cores        = 2
  memory_dedicated = 512
  disk_size        = 8

  features = {
    keyctl = true
  }

  network_interfaces = [
    {
      name   = "eth0"
      bridge = "vnet2"
      ipv4   = { address = "10.10.20.118/24", gateway = "10.10.20.1" }
    }
  ]

  passthrough_tun = true
}

module "lxc_jellyfin01" {
  source = "../modules/proxmox_lxc"

  vm_id    = 125
  hostname = "jellyfin01"

  template_file_id = proxmox_virtual_environment_file.debian_12_container_template.id
  tags             = ["debian", "jellyfin", "gpu"]

  cpu_cores        = 2
  memory_dedicated = 8192
  disk_size        = 128

  network_interfaces = [
    {
      name   = "eth0"
      bridge = "vnet1"
      ipv4   = { address = "10.10.10.125/24", gateway = "10.10.10.1" }
    }
  ]

  passthrough_gpu = true

  mount_points = [
    { path = "/media", volume = "/mnt/pve/remote-cifs-truenas01", backup = false }
  ]
}

module "lxc_plex01" {
  source = "../modules/proxmox_lxc"

  vm_id    = 124
  hostname = "plex01"

  template_file_id = proxmox_virtual_environment_file.debian_12_container_template.id
  tags             = ["debian", "plex", "gpu"]

  cpu_cores        = 2
  memory_dedicated = 8192
  disk_size        = 128

  network_interfaces = [
    {
      name   = "eth0"
      bridge = "vnet2"
      ipv4   = { address = "10.10.20.124/24", gateway = "10.10.20.1" }
    }
  ]

  passthrough_gpu = true

  mount_points = [
    { path = "/data", volume = "/mnt/pve/remote-cifs-truenas01", backup = false }
  ]
}

module "lxc_tdarr01" {
  source = "../modules/proxmox_lxc"

  vm_id    = 129
  hostname = "tdarr01"

  cpu_cores        = 4
  memory_dedicated = 4096
  disk_size        = 128

  template_file_id = proxmox_virtual_environment_file.debian_12_container_template.id
  tags             = ["debian", "tdarr", "gpu"]

  network_interfaces = [
    {
      name   = "eth0"
      bridge = "vnet1"
      ipv4   = { address = "10.10.10.129/24", gateway = "10.10.10.1" }
    }
  ]

  passthrough_gpu = true

  mount_points = [
    { path = "/mnt/media", volume = "/mnt/pve/remote-cifs-truenas01", backup = false }
  ]
}

module "lxc_forgejo01" {
  source = "../modules/proxmox_lxc"

  vm_id    = 127
  hostname = "forgejo01"

  template_file_id = proxmox_virtual_environment_file.debian_12_container_template.id
  tags             = ["debian", "git", "forgejo"]

  cpu_cores        = 4
  memory_dedicated = 4096
  disk_size        = 128

  network_interfaces = [
    {
      name   = "eth0"
      bridge = "vnet1"
      ipv4   = { address = "10.10.10.127/24", gateway = "10.10.10.1" }
    }
  ]
}

module "lxc_proxy01" {
  source = "../modules/proxmox_lxc"

  vm_id    = 113
  hostname = "proxy01"

  template_file_id = proxmox_virtual_environment_file.debian_13_container_template.id
  tags             = ["debian", "proxy", "tailscale"]

  features = {
    keyctl = true
  }

  network_interfaces = [
    {
      name   = "eth0"
      bridge = "vmbr0"
      ipv4   = { address = "192.168.1.113/24", gateway = "192.168.1.1" }
    },
    {
      name   = "eth1"
      bridge = "vnet1"
      ipv4   = { address = "10.10.10.113/24" }
    }
  ]

  passthrough_tun = true
}

module "lxc_proxy02" {
  source = "../modules/proxmox_lxc"

  vm_id    = 119
  hostname = "proxy02"

  template_file_id = proxmox_virtual_environment_file.debian_13_container_template.id
  tags             = ["debian", "proxy", "tailscale"]

  features = {
    keyctl = true
  }

  network_interfaces = [
    {
      name   = "eth0"
      bridge = "vmbr0"
      ipv4   = { address = "192.168.1.119/24", gateway = "192.168.1.1" }
    },
    {
      name   = "eth1"
      bridge = "vnet2"
      ipv4   = { address = "10.10.20.119/24" }
    }
  ]

  passthrough_tun = true
}