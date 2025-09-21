resource "proxmox_virtual_environment_vm" "vm" {
  vm_id     = var.vm_id
  name      = var.vm_name
  node_name = var.node_name
  on_boot   = var.on_boot
  started   = var.started

  agent {
    enabled = var.agent_enabled
  }

  pool_id = var.pool_id
  tags    = var.tags

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

  bios = var.bios

  dynamic "efi_disk" {
    for_each = var.efi_disk != null ? [var.efi_disk] : []
    content {
      datastore_id = efi_disk.value.datastore_id
      type         = efi_disk.value.type
      file_format  = efi_disk.value.file_format
    }
  }

  machine    = var.machine
  boot_order = var.boot_order

  dynamic "disk" {
    for_each = var.disks
    content {
      datastore_id      = disk.value.datastore_id
      file_id           = disk.value.file_id
      interface         = disk.value.interface
      iothread          = disk.value.iothread
      discard           = disk.value.discard
      size              = disk.value.size
      cache             = disk.value.cache
      ssd               = disk.value.ssd
      file_format       = disk.value.file_format
      path_in_datastore = disk.value.path_in_datastore
    }
  }

  scsi_hardware = var.scsi_hardware

  dynamic "initialization" {
    for_each = var.initialization != null ? [var.initialization] : []
    content {
      datastore_id = initialization.value.datastore_id

      dynamic "ip_config" {
        for_each = try(initialization.value.ip_config, null) != null ? [initialization.value.ip_config] : []
        content {
          dynamic "ipv4" {
            for_each = try(ip_config.value.ipv4, null) != null ? [ip_config.value.ipv4] : []
            content {
              address = ipv4.value.address
              gateway = ipv4.value.gateway
            }
          }
        }
      }

      dynamic "user_account" {
        for_each = try(initialization.value.user_account, null) != null ? [initialization.value.user_account] : []
        content {
          username = user_account.value.username
          keys     = user_account.value.keys
        }
      }
      vendor_data_file_id = try(initialization.value.vendor_data_file_id, null)
    }
  }

  dynamic "network_device" {
    for_each = var.network_devices
    content {
      bridge      = network_device.value.bridge
      mac_address = network_device.value.mac_address
      queues      = network_device.value.queues
      mtu         = network_device.value.mtu
    }
  }

  dynamic "hostpci" {
    for_each = var.hostpci != null ? var.hostpci : []
    content {
      device  = hostpci.value.device
      mapping = hostpci.value.mapping
      pcie    = hostpci.value.pcie
      rombar  = hostpci.value.rombar
    }
  }

  dynamic "virtiofs" {
    for_each = var.virtiofs != null ? var.virtiofs : []
    content {
      mapping = virtiofs.value.mapping
    }
  }

  operating_system {
    type = var.operating_system.type
  }
}

resource "adguard_rewrite" "proxmox_vm" {
  count = var.initialization != null && can(var.initialization.ip_config.ipv4.address) ? 1 : 0

  answer = split("/", var.initialization.ip_config.ipv4.address)[0]
  domain = format("%s.%s", var.vm_name, var.domain)
}

resource "adguard_rewrite" "proxmox_vm_extra_rewrites" {
  for_each = { for idx, rule in var.additional_dns_records : tostring(idx) => rule }

  domain = each.value.domain
  answer = each.value.answer
}