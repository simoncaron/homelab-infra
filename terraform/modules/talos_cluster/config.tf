locals {
  nodes            = [for machine_key, machine in var.machines : machine_key]
  controlplane_ips = [for machine_key, machine in var.machines : machine.interfaces[0].addresses[0] if machine.type == "controlplane"]
  worker_ips       = [for machine_key, machine in var.machines : machine.interfaces[0].addresses[0] if machine.type == "worker"]
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_machine_configuration" "this" {
  for_each = var.machines

  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cluster_endpoint}:6443"
  machine_type       = each.value.type
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  kubernetes_version = var.kubernetes_version
  talos_version      = var.talos_version

  config_patches = [for patch in fileset("${path.module}/config_patches", "**") :
    templatefile("${path.module}/config_patches/${patch}", {
      type = each.value.type

      machine_network_hostname    = each.key
      machine_network_interfaces  = each.value.interfaces
      machine_disks               = each.value.disks
      machine_kubelet_extraMounts = each.value.extra_mounts
      machine_labels              = each.value.labels

      machine_network_nameservers = var.machine_network_nameservers

      enable_metrics_server = var.enable_metrics_server

      cluster_node_subnet                    = var.cluster_node_subnet
      cluster_name                           = var.cluster_name
      cluster_vip                            = var.cluster_vip
      cluster_allowSchedulingOnControlPlanes = var.cluster_allowSchedulingOnControlPlanes
    })
  ]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = local.controlplane_ips
  nodes                = local.nodes
}
