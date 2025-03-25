module "talos_image" {
  source           = "../modules/talos_image"
  talos_version    = "v1.9.3"
  target_pve_nodes = local.pve_cluster_nodes
}

module "talos_image_1_9_5" {
  source           = "../modules/talos_image"
  talos_version    = "v1.9.5"
  target_pve_nodes = local.pve_cluster_nodes
}

module "control_plane_nodes" {
  source   = "../modules/proxmox_vm"
  for_each = { for k, v in local.machines : k => v if v.type == "controlplane" }

  vm_name   = each.key
  node_name = each.value.pve_node

  tags = ["talos", "control-plane", "k8s"]

  cpu_cores        = 4
  memory_dedicated = 16384

  disks = [
    {
      datastore_id = "local-zfs"
      file_id      = module.talos_image.proxmox_file_id
      interface    = "scsi0"
      size         = 128
    }
  ]

  initialization = {
    datastore_id = "local-lvm"
    ip_config = {
      ipv4 = {
        address = format("%s/24", each.value.interfaces[0].addresses[0])
        gateway = "192.168.1.1"
      }
    }
  }

  network_devices = [
    {
      bridge      = "vmbr0",
      mac_address = each.value.interfaces[0].hardwareAddr
    }
  ]
}

module "worker_nodes" {
  source   = "../modules/proxmox_vm"
  for_each = { for k, v in local.machines : k => v if v.type == "worker" }

  vm_name   = each.key
  node_name = each.value.pve_node

  tags = ["talos", "worker", "k8s"]

  cpu_cores        = 4
  memory_dedicated = 16384
  memory_floating  = 16384

  disks = [
    {
      datastore_id = "local-zfs"
      file_id      = module.talos_image.proxmox_file_id
      interface    = "scsi0"
      size         = 128
    },
    # Longhorn disk
    {
      datastore_id = "local-lvm"
      interface    = "scsi1"
      size         = 512
    }
  ]

  initialization = {
    datastore_id = "local-lvm"
    ip_config = {
      ipv4 = {
        address = format("%s/24", each.value.interfaces[0].addresses[0])
        gateway = "192.168.1.1"
      }
    }
  }

  network_devices = [
    {
      bridge      = "vmbr0"
      mac_address = each.value.interfaces[0].hardwareAddr
    },

    # Longhorn network interface
    {
      bridge      = "vmbr1"
      mac_address = each.value.interfaces[1].hardwareAddr
    }
  ]
}