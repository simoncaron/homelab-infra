resource "proxmox_virtual_environment_download_file" "debian-12_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve01"
  overwrite    = false

  file_name = "debian-12-generic-amd64.qcow2.img"
  url       = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
}

resource "proxmox_virtual_environment_download_file" "debian-13_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve01"
  overwrite    = false

  file_name = "debian-13-generic-amd64.qcow2.img"
  url       = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
}

resource "proxmox_virtual_environment_download_file" "haos_16_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve01"

  decompression_algorithm = "zst"
  file_name               = "haos_ova-16.1.img"
  overwrite               = false

  url = "https://github.com/home-assistant/operating-system/releases/download/16.1/haos_ova-16.1.qcow2.xz"
}

resource "proxmox_virtual_environment_file" "cloud_config_vendor" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve01"

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
  tags             = ["debian", "nextcloud", "docker"]
  memory_dedicated = 6144

  disks = [{
    file_id   = proxmox_virtual_environment_download_file.debian-12_cloud_image.id
    interface = "virtio0"
    size      = 256
  }]

  initialization = {
    ip_config = {
      ipv4 = {
        address = "10.10.10.128/24"
        gateway = "10.10.10.1"
      }
    }
    user_account = {
      username = "debian"
      keys     = [data.ansiblevault_string.default_ssh_public_key.value]
    }
    vendor_data_file_id = proxmox_virtual_environment_file.cloud_config_vendor.id
  }

  network_devices = [{
    bridge = "vnet1"
  }]
}

module "vm_monitoring01" {
  source = "../modules/proxmox_vm"

  vm_id            = 117
  vm_name          = "monitoring01"
  tags             = ["debian", "docker", "metrics"]
  memory_dedicated = 8192

  disks = [{
    file_id   = proxmox_virtual_environment_download_file.debian-12_cloud_image.id
    interface = "virtio0"
    size      = 256
  }]

  initialization = {
    ip_config = {
      ipv4 = {
        address = "10.10.10.117/24"
        gateway = "10.10.10.1"
      }
    }
    user_account = {
      username = "debian"
      keys     = [data.ansiblevault_string.default_ssh_public_key.value]
    }
    vendor_data_file_id = proxmox_virtual_environment_file.cloud_config_vendor.id
  }

  network_devices = [{
    bridge = "vnet1"
  }]
}

module "vm_docker01" {
  source = "../modules/proxmox_vm"

  vm_id            = 115
  vm_name          = "docker01"
  tags             = ["debian", "docker", "apps"]
  memory_dedicated = 8192

  disks = [{
    file_id   = proxmox_virtual_environment_download_file.debian-12_cloud_image.id
    interface = "virtio0"
    size      = 256
  }]

  initialization = {
    ip_config = {
      ipv4 = {
        address = "10.10.10.115/24"
        gateway = "10.10.10.1"
      }
    }
    user_account = {
      username = "debian"
      keys     = [data.ansiblevault_string.default_ssh_public_key.value]
    }
    vendor_data_file_id = proxmox_virtual_environment_file.cloud_config_vendor.id
  }

  network_devices = [{
    bridge = "vnet1"
  }]
}

module "vm_docker02" {
  source = "../modules/proxmox_vm"

  vm_id            = 116
  vm_name          = "docker02"
  tags             = ["debian", "docker", "vpn"]
  memory_dedicated = 8192

  disks = [{
    file_id   = proxmox_virtual_environment_download_file.debian-12_cloud_image.id
    interface = "virtio0"
    size      = 256
  }]

  initialization = {
    ip_config = {
      ipv4 = {
        address = "10.10.10.116/24"
        gateway = "10.10.10.1"
      }
    }
    user_account = {
      username = "debian"
      keys     = [data.ansiblevault_string.default_ssh_public_key.value]
    }
    vendor_data_file_id = proxmox_virtual_environment_file.cloud_config_vendor.id
  }

  network_devices = [{
    bridge = "vnet1"
  }]
}

module "vm_haos01" {
  source = "../modules/proxmox_vm"

  vm_id   = 133
  vm_name = "haos01"
  tags    = ["home-assistant", "ansible-skip"]

  cpu_cores        = 2
  memory_dedicated = 4096
  memory_floating  = 4096

  bios = "ovmf"

  efi_disk = {
    datastore_id = "local-zfs"
    type         = "4m"
    file_format  = "raw"
  }

  disks = [{
    file_id   = proxmox_virtual_environment_download_file.haos_16_image.id
    interface = "scsi0"
    cache     = "writethrough"
    discard   = "on"
    iothread  = true
    ssd       = true
    size      = 64
  }]

  network_devices = [{
    bridge = "vmbr0"
  }]
}

module "vm_gateway01" {
  source = "../modules/ovh_vm"
}
