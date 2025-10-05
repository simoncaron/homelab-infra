locals {
  passthrough_gpu_devices = var.passthrough_gpu ? ["/dev/nvidia0", "/dev/nvidiactl", "/dev/nvidia-modeset", "/dev/nvidia-uvm", "/dev/nvidia-uvm-tools", "/dev/nvidia-caps/nvidia-cap1", "/dev/nvidia-caps/nvidia-cap2"] : []
  passthrough_tun_device  = var.passthrough_tun ? ["/dev/net/tun"] : []

  all_passthrough_devices = concat(local.passthrough_gpu_devices, local.passthrough_tun_device)

  default_dns_record = { domain = format("%s.%s", var.hostname, var.domain), answer = split("/", var.network_interfaces[0].ipv4.address)[0] }
  extra_dns_records  = var.additional_dns_records != null ? var.additional_dns_records : []

  all_dns_records = concat([local.default_dns_record], local.extra_dns_records)
}

resource "proxmox_virtual_environment_container" "lxc" {
  node_name     = var.node_name
  vm_id         = var.vm_id
  description   = var.description
  pool_id       = var.pool_id
  tags          = var.tags
  started       = var.started
  start_on_boot = var.start_on_boot

  features {
    keyctl  = var.features.keyctl
    nesting = var.features.nesting
    mount   = var.features.mount
  }

  operating_system {
    template_file_id = var.template_file_id
    type             = var.os_type
  }
  unprivileged = var.unprivileged

  initialization {
    hostname = var.hostname

    user_account {
      password = var.root_password != null ? var.root_password : data.ansiblevault_string.default_root_password.value
      keys     = length(var.ssh_public_keys) > 0 ? var.ssh_public_keys : [data.ansiblevault_string.default_ssh_public_key.value]
    }

    dynamic "dns" {
      for_each = var.dns_config != null ? [var.dns_config] : []
      content {
        domain  = dns.value.domain
        servers = dns.value.servers
      }
    }

    dynamic "ip_config" {
      for_each = var.network_interfaces
      content {
        dynamic "ipv4" {
          for_each = ip_config.value.ipv4 != null ? [ip_config.value.ipv4] : []
          content {
            address = ipv4.value.address
            gateway = ipv4.value.gateway
          }
        }
        dynamic "ipv6" {
          for_each = ip_config.value.ipv6 != null ? [ip_config.value.ipv6] : []
          content {
            address = ipv6.value.address
            gateway = ipv6.value.gateway
          }
        }
      }
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interfaces
    content {
      name     = network_interface.value.name
      bridge   = network_interface.value.bridge
      firewall = network_interface.value.firewall
      vlan_id  = network_interface.value.vlan_id
    }
  }

  cpu {
    cores        = var.cpu_cores
    architecture = var.cpu_architecture
  }

  memory {
    dedicated = var.memory_dedicated
    swap      = var.memory_swap
  }

  disk {
    datastore_id = var.disk_datastore_id
    size         = var.disk_size
  }

  dynamic "mount_point" {
    for_each = var.mount_points
    content {
      path   = mount_point.value.path
      volume = mount_point.value.volume
      backup = mount_point.value.backup
    }
  }

  hook_script_file_id = var.hook_script_file_id

  dynamic "device_passthrough" {
    for_each = local.all_passthrough_devices
    content {
      path = device_passthrough.value
      mode = "0666"
    }
  }
}

resource "adguard_rewrite" "defined_rules" {
  count = length(local.all_dns_records) > 0 ? length(local.all_dns_records) : 0

  domain = local.all_dns_records[count.index].domain
  answer = local.all_dns_records[count.index].answer
}
