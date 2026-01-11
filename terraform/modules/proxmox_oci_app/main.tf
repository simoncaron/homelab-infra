locals {
  config_file_path = "/etc/pve/lxc/{{VM_ID}}.conf"

  # Commands to add/update config options for managed keys (lxc.environment, lxc.hook.mount)
  config_lines_overrides = compact(concat(
    [
      for key, value in var.environment :
      "sudo grep -q '^lxc\\.environment\\.runtime: ${key}=' ${local.config_file_path} && sudo sed -i 's/^lxc\\.environment\\.runtime: ${key}=.*/lxc.environment.runtime: ${key}=${value}/' ${local.config_file_path} || echo 'lxc.environment.runtime: ${key}=${value}' | sudo tee -a ${local.config_file_path}"
    ],
    [
      var.enable_nvidia_gpu ? "echo 'lxc.hook.mount: /usr/share/lxc/hooks/nvidia' | sudo tee -a ${local.config_file_path}" : null
    ],
  ))

  config_commands = concat(
    local.config_lines_overrides,
    # Start the container after updating config
    ["sudo pct start {{VM_ID}}"]
  )
}

# Trigger Container Recreation when environment Variables are changed
resource "null_resource" "lxc_extra_configs_trigger" {
  triggers = {
    env_vars = jsonencode(local.config_lines_overrides)
  }
}

resource "proxmox_virtual_environment_oci_image" "oci_image" {
  datastore_id = var.image.datastore_id
  node_name    = var.node_name
  reference    = var.image.reference
}

resource "proxmox_virtual_environment_container" "app_container" {
  node_name = var.node_name

  vm_id = var.vm_id

  # Can't start container here since we need to update it's environment variables before first boot
  started = false

  start_on_boot = false
  depends_on    = [restapi_object.proxmox_volumes, null_resource.fix_permissions]

  unprivileged = true

  console {
    enabled   = true
    tty_count = 1
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
      volume = "${mount_point.value.storage}:subvol-${var.vm_id}-disk-${mount_point.value.id + 100}"
      backup = mount_point.value.backup
    }
  }

  dynamic "mount_point" {
    for_each = var.bind_mounts
    content {
      path      = mount_point.value.container_path
      volume    = mount_point.value.host_path
      read_only = mount_point.value.read_only
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

  dynamic "device_passthrough" {
    for_each = var.device_passthrough
    content {
      path = device_passthrough.value.path
      mode = device_passthrough.value.mode
    }
  }

  network_interface {
    name   = "eth0"
    bridge = var.networking.bridge
  }

  lifecycle {
    ignore_changes       = [environment_variables, started]
    replace_triggered_by = [null_resource.lxc_extra_configs_trigger]
  }
}

# Create persistent volumes
# These are created via the REST API to manage their lifecycle separately from the container
resource "restapi_object" "proxmox_volumes" {
  for_each = { for i, vol in var.volumes : i => vol }
  path     = "/api2/json/nodes/${each.value.node}/storage/${each.value.storage}/content"

  id_attribute = "data"

  data = jsonencode({
    vmid     = var.vm_id
    filename = "subvol-${var.vm_id}-disk-${each.value.id + 100}"
    size     = each.value.size
    format   = "subvol"
  })

  ignore_all_server_changes = true

  lifecycle {
    precondition {
      condition     = length(var.volumes) == 0 || var.vm_id != null
      error_message = "If 'volumes' are defined, you must explicitly provide a 'vm_id'."
    }
  }
}

# Detach volumes before destroying the container
# This is necessary to avoid issues with Proxmox trying to delete attached volumes where data is persisted
resource "null_resource" "detach_volumes_on_destroy" {
  count      = length(var.volumes) > 0 ? 1 : 0
  depends_on = [proxmox_virtual_environment_container.app_container]

  triggers = {
    node_name = var.node_name
    vmid      = proxmox_virtual_environment_container.app_container.id
  }

  connection {
    type  = "ssh"
    user  = "terraform"
    host  = self.triggers.node_name
    agent = true
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "sudo sed -i '/^mp[0-9]\\+:/d' /etc/pve/lxc/${self.triggers.vmid}.conf",
      "sudo pct shutdown ${self.triggers.vmid}",
    ]
  }
}

# Fix permissions on created volumes
# Proxmox creates volumes with root ownership, which can cause issues with unprivileged containers
resource "null_resource" "fix_permissions" {
  for_each   = { for i, vol in var.volumes : i => vol }
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
      "sudo chown ${each.value.uid}:${each.value.gid} ${var.storage_mount_path}/subvol-${var.vm_id}-disk-${each.value.id + 100}",
    ]
  }
}

# Set LXC config options that are not directly supported by the Proxmox provider
# This is necessary for setting environment variables and enabling NVIDIA GPU passthrough
resource "null_resource" "set_lxc_config_options" {
  depends_on = [proxmox_virtual_environment_container.app_container]
  count      = length(local.config_lines_overrides) > 0 ? 1 : 0

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