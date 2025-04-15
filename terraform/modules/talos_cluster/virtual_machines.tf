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
        size      = 64
      }
    ],
    # Add a second disk for longhorn storage
    each.value.type == "worker" ? [
      {
        datastore_id = "local-lvm"
        interface    = "scsi1"
        size         = 512
      }
    ] : []
  )

  initialization = {
    datastore_id = "local-lvm"
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
    ],
    # Add a second network device for longhorn network
    each.value.type == "worker" ? [
      {
        bridge      = "vmbr1"
        mac_address = each.value.interfaces[1].hardwareAddr
        mtu         = each.value.interfaces[1].mtu
      }
    ] : []
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
