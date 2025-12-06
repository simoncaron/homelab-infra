locals {
  all_passthrough_devices = var.device_passthrough

  config_file_path = "/etc/pve/lxc/{{VM_ID}}.conf"

  remove_commands = [
    "sudo sed -i '/^lxc\\.environment:/d' ${local.config_file_path}",
    "sudo sed -i '/^lxc\\.hook\\.mount:/d' ${local.config_file_path}",
  ]

  add_commands = compact(concat(
    [
      for key, value in var.environment_variables :
      "echo 'lxc.environment: ${key}=${value}' | sudo tee -a ${local.config_file_path}"
    ],
    [
      var.hook_mount != null
      ? "echo 'lxc.hook.mount: ${var.hook_mount}' | sudo tee -a ${local.config_file_path}"
      : null
    ],
  ))

  config_commands = concat(
    ["sleep 10"],
    local.remove_commands,
    local.add_commands,
    ["sudo pct reboot {{VM_ID}}"]
  )
}

resource "proxmox_virtual_environment_container" "lxc" {
  node_name     = var.node_name
  vm_id         = var.vm_id
  description   = var.description
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

  dynamic "console" {
    for_each = var.console != null ? [1] : []
    content {
      enabled   = true
      type      = var.console.type
      tty_count = var.console.tty_count
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
      size   = mount_point.value.size
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

resource "proxmox_virtual_environment_pool_membership" "lxc_membership" {
  count   = var.pool_id != null ? 1 : 0
  pool_id = var.pool_id
  vm_id   = proxmox_virtual_environment_container.lxc.vm_id
}

resource "null_resource" "set_lxc_config_options" {
  depends_on = [proxmox_virtual_environment_container.lxc]
  count      = length(local.add_commands) > 0 ? 1 : 0

  # Hack to trigger rerun everytime commands have been edited.
  triggers = {
    always_run = jsonencode(local.config_commands)
  }

  connection {
    type  = "ssh"
    user  = "terraform"
    host  = format("%s.%s", var.node_name, var.domain)
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      for cmd in local.config_commands :
      replace(cmd, "{{VM_ID}}", proxmox_virtual_environment_container.lxc.vm_id)
    ]
  }
}

resource "adguard_rewrite" "defined_rules" {
  domain = format("%s.%s", var.hostname, var.domain)
  answer = proxmox_virtual_environment_container.lxc.ipv4[var.network_interfaces[0].name]
}
