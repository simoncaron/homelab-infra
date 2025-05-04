module "k8s_cluster_nodes" {
  source   = "../proxmox_vm"
  for_each = var.machines

  vm_name   = each.key
  node_name = each.value.pve_node

  tags = ["talos", "k8s", each.value.type]

  cpu_cores        = each.value.cpu
  memory_dedicated = each.value.memory

  machine = "q35"

  disks = concat(
    [
      {
        datastore_id = "local-zfs"
        file_id = proxmox_virtual_environment_download_file.this["${each.value.pve_node}_${each.value.update_talos == true ?
        "${md5(join(",", var.talos_image.update_extensions))}_${var.talos_image.update_version}" : "${md5(join(",", var.talos_image.extensions))}_${var.talos_image.version}"}"].id
        interface = "scsi0"
        size      = 128
      }
    ]
  )

  initialization = {
    datastore_id = "local-zfs"
    ip_config = {
      ipv4 = {
        address = "${each.value.interfaces[0].addresses[0]}/24"
        gateway = "192.168.1.1"
      }
    }
  }

  hostpci = concat(
    each.value.igpu == true ? [
      {
        device  = "hostpci0"
        mapping = proxmox_virtual_environment_hardware_mapping_pci.gpu_mapping.name
        xvga    = false
      }
    ] : [],
  )

  network_devices = concat(
    [
      {
        bridge      = "vmbr0"
        mac_address = each.value.interfaces[0].hardwareAddr
        mtu         = each.value.interfaces[0].mtu
      }
    ]
  )
}

resource "proxmox_virtual_environment_hardware_mapping_pci" "gpu_mapping" {
  name = "iGPU"
  map = flatten([
    for node in distinct([for machine in var.machines : machine.pve_node]) : [
      {
        id           = "8086:4626"
        iommu_group  = 0
        node         = node
        path         = "0000:00:02.0"
        subsystem_id = "8086:3024"
      }
    ]
  ])
}
