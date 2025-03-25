resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.vm_name
  node_name = var.node_name
  on_boot   = var.on_boot

  agent {
    enabled = var.agent_enabled
  }

  pool_id = var.pool_id

  tags = var.tags

  serial_device {
    device = var.serial_device.device
  }

  cpu {
    type         = var.cpu_type
    cores        = var.cpu_cores
    architecture = var.cpu_architecture
  }

  memory {
    dedicated = var.memory_dedicated
    floating  = var.memory_floating
  }

  dynamic "disk" {
    for_each = var.disks
    content {
      datastore_id = disk.value.datastore_id
      file_id      = disk.value.file_id
      interface    = disk.value.interface
      iothread     = disk.value.iothread
      discard      = disk.value.discard
      size         = disk.value.size
      cache        = disk.value.cache
      ssd          = disk.value.ssd
      file_format  = disk.value.file_format
    }
  }

  scsi_hardware = var.scsi_hardware

  dynamic "initialization" {
    for_each = var.initialization != null ? [var.initialization] : []
    content {
      datastore_id = initialization.value.datastore_id

      dynamic "ip_config" {
        for_each = initialization.value.ip_config != null ? [initialization.value.ip_config] : []
        content {
          dynamic "ipv4" {
            for_each = ip_config.value.ipv4 != null ? [ip_config.value.ipv4] : []
            content {
              address = ipv4.value.address
              gateway = ipv4.value.gateway
            }
          }
        }
      }
    }
  }

  dynamic "network_device" {
    for_each = var.network_devices
    content {
      bridge      = network_device.value.bridge
      mac_address = network_device.value.mac_address
      queues      = network_device.value.queues
    }
  }

  operating_system {
    type = var.operating_system.type
  }
}

resource "adguard_rewrite" "proxmox_vm" {
  answer = split("/", var.initialization.ip_config.ipv4.address)[0]
  domain = format("%s.%s", var.vm_name, var.domain)
}