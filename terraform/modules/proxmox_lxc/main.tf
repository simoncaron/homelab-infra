# ./modules/lxc/main.tf
resource "proxmox_virtual_environment_container" "lxc" {
  # Basic settings
  node_name     = var.node_name
  vm_id         = var.vm_id
  description   = var.description
  pool_id       = var.pool_id
  tags          = var.tags
  started       = var.started
  start_on_boot = var.start_on_boot

  # Features
  features {
    keyctl  = var.features.keyctl
    nesting = var.features.nesting
  }

  # Operating System
  operating_system {
    template_file_id = var.template_file_id
    type             = var.os_type
  }
  unprivileged = var.unprivileged

  # Initialization
  initialization {
    hostname = var.hostname

    user_account {
      password = var.root_password
      keys     = var.ssh_public_keys
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

  # Network Interfaces
  dynamic "network_interface" {
    for_each = var.network_interfaces
    content {
      name     = network_interface.value.name
      bridge   = network_interface.value.bridge
      firewall = network_interface.value.firewall
      vlan_id  = network_interface.value.vlan_id
    }
  }

  # CPU
  cpu {
    cores        = var.cpu_cores
    architecture = var.cpu_architecture
  }

  # Memory
  memory {
    dedicated = var.memory_dedicated
    swap      = var.memory_swap
  }

  # Root Disk
  disk {
    datastore_id = var.disk_datastore_id
    size         = var.disk_size
  }

  # Additional Mount Points
  dynamic "mount_point" {
    for_each = var.mount_points
    content {
      path   = mount_point.value.path
      volume = mount_point.value.volume
      backup = mount_point.value.backup
    }
  }

  # Hook Script
  hook_script_file_id = var.hook_script_file_id

  # Device Passthrough
  # Dynamically create device_passthrough blocks
  dynamic "device_passthrough" {
    for_each = var.device_passthrough
    content {
      path       = device_passthrough.value.path
      deny_write = device_passthrough.value.deny_write
      gid        = device_passthrough.value.gid
      mode       = device_passthrough.value.mode
      uid        = device_passthrough.value.uid
    }
  }
}

# AdGuard Home DNS Rewrite Rules
resource "adguard_rewrite" "defined_rules" {
  # Create rules only if the list is not empty
  count = length(var.adguard_rewrite_rules) > 0 ? length(var.adguard_rewrite_rules) : 0

  domain = var.adguard_rewrite_rules[count.index].domain
  answer = var.adguard_rewrite_rules[count.index].answer
}

# Proxmox Firewall Rules
resource "proxmox_virtual_environment_firewall_rules" "lxc_firewall" {
  count = var.firewall_rules_enabled ? 1 : 0

  node_name = proxmox_virtual_environment_container.lxc.node_name
  vm_id     = proxmox_virtual_environment_container.lxc.vm_id

  dynamic "rule" {
    for_each = var.firewall_rules
    content {
      type    = rule.value.type
      action  = rule.value.action
      iface   = rule.value.iface
      source  = rule.value.source
      dest    = rule.value.dest
      macro   = rule.value.macro
      proto   = rule.value.proto
      dport   = rule.value.dport
      sport   = rule.value.sport
      log     = rule.value.log
      comment = rule.value.comment
    }
  }
  depends_on = [proxmox_virtual_environment_container.lxc]
}
