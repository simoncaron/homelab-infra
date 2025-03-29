module "talos_image" {
  source           = "../modules/talos_image"
  talos_version    = "v1.9.5"
  target_pve_nodes = local.pve_cluster_nodes
}

module "k8s_cluster_nodes" {
  source     = "../modules/proxmox_vm"
  depends_on = [module.talos_image]
  for_each   = local.machines

  vm_name   = each.key
  node_name = each.value.pve_node

  tags = ["talos", "k8s", each.value.type]

  cpu_cores        = 4
  memory_dedicated = 16384

  disks = concat(
    [
      {
        datastore_id = "local-zfs"
        file_id      = module.talos_image.proxmox_file_id
        interface    = "scsi0"
        size         = 64
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
        address = format("%s/24", each.value.interfaces[0].addresses[0])
        gateway = "192.168.1.1"
      }
    }
  }

  network_devices = concat(
    [
      {
        bridge      = "vmbr0"
        mac_address = each.value.interfaces[0].hardwareAddr
      }
    ],
    # Add a second network device for longhorn network
    each.value.type == "worker" ? [
      {
        bridge      = "vmbr1"
        mac_address = each.value.interfaces[1].hardwareAddr
      }
    ] : []
  )
}

module "talos_cluster" {
  source     = "../modules/talos_cluster"
  depends_on = [module.k8s_cluster_nodes]

  cluster_name                           = "k8s-homelab-cluster"
  cluster_endpoint                       = "192.168.1.243"
  cluster_vip                            = "192.168.1.249"
  cluster_allowSchedulingOnControlPlanes = false
  machine_network_nameservers            = ["192.168.1.10", "192.168.1.114"]
  kubernetes_version                     = "1.31.1"
  talos_version                          = "v1.9.5"
  machines                               = local.machines
}
