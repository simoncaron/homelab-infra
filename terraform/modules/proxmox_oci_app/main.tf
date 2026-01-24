locals {
  config_file_path = "/etc/pve/lxc/{{VM_ID}}.conf"

  # Inject "Docker-style" environment variables as lxc.environment.runtime entries
  # Update existing environment variables if they already exist in the lxc config
  environment_variable_config_lines = compact(
    [
      for key, value in var.environment :
      "sudo grep -q '^lxc\\.environment\\.runtime: ${key}=' ${local.config_file_path} && sudo sed -i 's/^lxc\\.environment\\.runtime: ${key}=.*/lxc.environment.runtime: ${key}=${value}/' ${local.config_file_path} || echo 'lxc.environment.runtime: ${key}=${value}' | sudo tee -a ${local.config_file_path}"
    ],
  )

  # Inject NVIDIA GPU passthrough hook script and environment variables as lxc.environment entries
  gpu_passthrough_config_lines = [
    "echo 'lxc.environment: NVIDIA_VISIBLE_DEVICES=all' | sudo tee -a ${local.config_file_path}",
    "echo 'lxc.environment: NVIDIA_DRIVER_CAPABILITIES=compute,utility,video' | sudo tee -a ${local.config_file_path}",
    "echo 'lxc.hook.mount: /usr/share/lxc/hooks/nvidia' | sudo tee -a ${local.config_file_path}",
  ]

  # Merge all required extra config commands
  config_commands = concat(
    local.environment_variable_config_lines,
    (var.enable_nvidia_gpu ? local.gpu_passthrough_config_lines : []),
    ["sudo pct start {{VM_ID}}"]
  )
}

# Trigger Container Recreation when:
# - Environment variables change
# - Volumes change (since they are attached outside of the Proxmox provider and order cannot be guaranteed)
resource "null_resource" "lxc_extra_configs_trigger" {
  triggers = {
    env_vars = jsonencode(local.environment_variable_config_lines)
    volumes  = jsonencode(var.volumes)
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
      volume = "${mount_point.value.storage}:subvol-${var.vm_id}-disk-${mount_point.key + 1}"
      backup = mount_point.value.backup
      size   = mount_point.value.size
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
    filename = "subvol-${var.vm_id}-disk-${each.key + 1}"
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
      "sudo chown ${each.value.uid}:${each.value.gid} ${var.storage_mount_path}/subvol-${var.vm_id}-disk-${each.key + 1}",
    ]
  }
}

# Set LXC config options that are not directly supported by the Proxmox provider
# This is necessary for setting environment variables and enabling NVIDIA GPU passthrough
resource "null_resource" "set_lxc_config_options" {
  depends_on = [proxmox_virtual_environment_container.app_container]
  count      = length(local.environment_variable_config_lines) > 0 ? 1 : 0

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