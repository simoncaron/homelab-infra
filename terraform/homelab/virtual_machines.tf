resource "proxmox_virtual_environment_download_file" "debian-12_cloud_image" {
  content_type = "iso"
  datastore_id = "cephfs"
  node_name    = "pvenuc01" # Not really important since cephfs is shared

  file_name = "debian-12-generic-amd64.qcow2.img"
  url       = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
  overwrite = false
}

resource "proxmox_virtual_environment_file" "cloud_config_vendor" {
  content_type = "snippets"
  datastore_id = "cephfs"
  node_name    = "pvenuc01" # Not really important since cephfs is shared

  source_raw {
    data = <<-EOF
      #cloud-config
      package_update: true
      package_upgrade: true
      packages: 
        - qemu-guest-agent
        - net-tools
      runcmd:
        - timedatectl set-timezone America/Toronto
        - systemctl enable qemu-guest-agent
        - systemctl start qemu-guest-agent
        - ufw disable
        - systemctl enable serial-getty@ttyS0.service
        - systemctl start serial-getty@ttyS0.service
        - echo "done" > /tmp/vendor-cloud-init-done
      EOF

    file_name = "cloud-config-vendor.yaml"
  }
}

module "vm_nextcloud01" {
  source = "../modules/proxmox_vm"

  vm_id            = 128
  vm_name          = "nextcloud01"
  node_name        = "pve01"
  tags             = ["debian", "nextcloud", "docker"]
  on_boot          = false
  agent_enabled    = true
  pool_id          = "terraform"
  memory_dedicated = 6144

  disks = [{
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.debian-12_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 256
    cache        = "none"
    ssd          = false
    file_format  = "qcow2"
  }]

  initialization = {
    datastore_id = "local-lvm"
    ip_config = {
      ipv4 = {
        address = "10.10.10.128/24"
        gateway = "10.10.10.1"
      }
    }
    user_account = {
      username = "debian"
      keys     = [data.bitwarden_item_login.default_ssh_public_key.password]
    }
    vendor_data_file_id = proxmox_virtual_environment_file.cloud_config_vendor.id
  }

  network_devices = [{
    bridge = "vmbr1"
  }]

  extra_adguard_rewrites = [
    {
      domain = "cloud.simn.io"
      answer = "192.168.1.113"
    }
  ]
}

module "vm_monitoring01" {
  source = "../modules/proxmox_vm"

  vm_id            = 117
  vm_name          = "monitoring01"
  node_name        = "pve01"
  tags             = ["debian", "docker", "metrics"]
  on_boot          = false
  agent_enabled    = true
  pool_id          = "terraform"
  memory_dedicated = 16384

  disks = [{
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.debian-12_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 256
    cache        = "none"
    ssd          = false
    file_format  = "qcow2"
  }]

  initialization = {
    datastore_id = "local-lvm"
    ip_config = {
      ipv4 = {
        address = "10.10.10.117/24"
        gateway = "10.10.10.1"
      }
    }
    user_account = {
      username = "debian"
      keys     = [data.bitwarden_item_login.default_ssh_public_key.password]
    }
    vendor_data_file_id = proxmox_virtual_environment_file.cloud_config_vendor.id
  }

  network_devices = [{
    bridge = "vmbr1"
  }]
}

module "vm_docker01" {
  source = "../modules/proxmox_vm"

  vm_id            = 115
  vm_name          = "docker01"
  node_name        = "pve01"
  tags             = ["debian", "docker", "apps"]
  on_boot          = false
  agent_enabled    = true
  pool_id          = "terraform"
  memory_dedicated = 16384

  disks = [{
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.debian-12_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 256
    cache        = "none"
    ssd          = false
    file_format  = "qcow2"
  }]

  initialization = {
    datastore_id = "local-lvm"
    ip_config = {
      ipv4 = {
        address = "10.10.10.115/24"
        gateway = "10.10.10.1"
      }
    }
    user_account = {
      username = "debian"
      keys     = [data.bitwarden_item_login.default_ssh_public_key.password]
    }
    vendor_data_file_id = proxmox_virtual_environment_file.cloud_config_vendor.id
  }

  network_devices = [{
    bridge = "vmbr1"
  }]
}

module "vm_docker02" {
  source = "../modules/proxmox_vm"

  vm_id            = 116
  vm_name          = "docker02"
  node_name        = "pve01"
  tags             = ["debian", "docker", "vpn"]
  on_boot          = false
  agent_enabled    = true
  pool_id          = "terraform"
  memory_dedicated = 16384

  disks = [{
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.debian-12_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 256
    cache        = "none"
    ssd          = false
    file_format  = "qcow2"
  }]

  initialization = {
    datastore_id = "local-lvm"
    ip_config = {
      ipv4 = {
        address = "10.10.10.116/24"
        gateway = "10.10.10.1"
      }
    }
    user_account = {
      username = "debian"
      keys     = [data.bitwarden_item_login.default_ssh_public_key.password]
    }
    vendor_data_file_id = proxmox_virtual_environment_file.cloud_config_vendor.id
  }

  network_devices = [{
    bridge = "vmbr1"
  }]
}