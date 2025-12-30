locals {
  config_file_path = "/etc/pve/lxc/{{VM_ID}}.conf"

  # Commands to clear existing config options for managed keys
  # These are cleared first to avoid duplicates/drift when re-applying
  remove_commands = [
    "sudo sed -i '/^lxc\\.environment:/d' ${local.config_file_path}",
    "sudo sed -i '/^lxc\\.hook\\.mount:/d' ${local.config_file_path}",
  ]

  # Commands to add/update config options for managed keys (lxc.environment, lxc.hook.mount)
  add_commands = compact(concat(
    [
      for key, value in var.environment :
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

  vm_id = var.vm_id

  depends_on = [restapi_object.proxmox_volumes, null_resource.fix_permissions]

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
    ignore_changes = [environment_variables]
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
      "sudo chown ${each.value.uid}:${each.value.gid} /rpool/data/subvol-${var.vm_id}-disk-${each.key + 1}",
    ]
  }
}

# Set LXC config options that are not directly supported by the Proxmox provider
# This is necessary for setting environment variables and enabling NVIDIA GPU passthrough
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

resource "powerdns_record" "powerdns_dns_record" {
  zone    = "${var.domain}."
  name    = "${var.name}.${var.domain}."
  type    = "A"
  ttl     = 14400
  records = [proxmox_virtual_environment_container.app_container.ipv4["eth0"]]
}
