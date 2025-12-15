locals {
  config_file_path = "/etc/pve/lxc/{{VM_ID}}.conf"

  environment_variables = merge(
    var.environment,
    var.enable_nvidia_gpu ? {
      NVIDIA_VISIBLE_DEVICES     = "all"
      NVIDIA_DRIVER_CAPABILITIES = "compute,utility,video"
    } : {}
  )

  remove_commands = [
    "sudo sed -i '/^lxc\\.environment:/d' ${local.config_file_path}",
    "sudo sed -i '/^lxc\\.hook\\.mount:/d' ${local.config_file_path}",
  ]

  add_commands = compact(concat(
    [
      for key, value in local.environment_variables :
      "echo 'lxc.environment: ${key}=${value}' | sudo tee -a ${local.config_file_path}"
    ],
    [
      var.enable_nvidia_gpu ? "echo 'lxc.hook.mount: /usr/share/lxc/hooks/nvidia' | sudo tee -a ${local.config_file_path}" : null
    ],
  ))

  config_commands = concat(
    ["sleep 10"],
    local.remove_commands,
    local.add_commands,
    ["sudo pct reboot {{VM_ID}}"]
  )
}

resource "proxmox_virtual_environment_oci_image" "oci_image" {
  datastore_id = var.image.datastore_id
  node_name    = var.node_name
  reference    = var.image.reference
}

resource "proxmox_virtual_environment_container" "app_container" {
  node_name = var.node_name

  depends_on = [restapi_object.proxmox_volumes, null_resource.fix_permissions]

  unprivileged = true

  console {
    enabled   = true
    tty_count = 2
    type      = "console"
  }

  cpu {
    cores = var.cpu
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.root_disk.datastore_id
    size         = var.root_disk.size
  }

  dynamic "mount_point" {
    for_each = var.volumes
    content {
      path   = mount_point.value.path
      volume = "${mount_point.value.storage}:subvol-999-${var.name}-${mount_point.key}"
      backup = mount_point.value.backup
    }
  }

  dynamic "mount_point" {
    for_each = var.bind_mounts
    content {
      path   = mount_point.value.container_path
      volume = mount_point.value.host_path
    }
  }

  tags = var.tags

  initialization {
    hostname = var.name

    ip_config {
      ipv4 {
        address = var.networking.address
        gateway = var.networking.gateway
      }
    }
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_oci_image.oci_image.id
  }

  network_interface {
    name   = "eth0"
    bridge = var.networking.bridge
  }

  lifecycle {
    ignore_changes = [environment_variables]
  }
}

resource "restapi_object" "proxmox_volumes" {
  for_each = var.volumes
  path     = "/api2/json/nodes/${each.value.node}/storage/${each.value.storage}/content"

  id_attribute = "data"

  data = jsonencode({
    vmid     = "999"
    filename = "subvol-999-${var.name}-${each.key}"
    size     = each.value.size
    format   = "subvol"
  })

  ignore_all_server_changes = true
}

resource "null_resource" "fix_permissions" {
  for_each = var.volumes

  depends_on = [restapi_object.proxmox_volumes]

  triggers = {
    volume_id = restapi_object.proxmox_volumes[each.key].id
  }

  connection {
    type  = "ssh"
    user  = "terraform"
    host  = var.node_name
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chown 100000:100000 /rpool/data/subvol-999-${var.name}-${each.key}",
    ]
  }
}

resource "null_resource" "set_lxc_config_options" {
  depends_on = [proxmox_virtual_environment_container.app_container]
  count      = length(local.add_commands) > 0 ? 1 : 0

  triggers = {
    # Re-run if the commands list changes
    config_change = jsonencode(local.config_commands)

    # Re-run if the container is replaced (ID changes)
    container_id = proxmox_virtual_environment_container.app_container.id
  }

  connection {
    type  = "ssh"
    user  = "terraform"
    host  = var.node_name
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      for cmd in local.config_commands :
      replace(cmd, "{{VM_ID}}", proxmox_virtual_environment_container.app_container.vm_id)
    ]
  }
}

resource "adguard_rewrite" "defined_rules" {
  domain = format("%s.%s", var.name, var.domain)
  answer = proxmox_virtual_environment_container.app_container.ipv4["eth0"]
}