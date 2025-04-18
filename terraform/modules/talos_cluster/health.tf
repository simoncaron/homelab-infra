data "talos_cluster_health" "k8s_api_available" {
  depends_on = [
    talos_machine_configuration_apply.machines,
    talos_machine_bootstrap.this
  ]

  client_configuration   = data.talos_client_configuration.this.client_configuration
  endpoints              = local.controlplane_ips
  control_plane_nodes    = local.controlplane_ips
  worker_nodes           = local.worker_ips
  skip_kubernetes_checks = true

  timeouts = {
    read = var.timeout
  }
}

data "talos_cluster_health" "this" {
  depends_on = [
    talos_machine_configuration_apply.machines,
    talos_machine_bootstrap.this
  ]

  client_configuration   = data.talos_client_configuration.this.client_configuration
  endpoints              = local.controlplane_ips
  control_plane_nodes    = local.controlplane_ips
  worker_nodes           = local.worker_ips
  skip_kubernetes_checks = false

  timeouts = {
    read = var.timeout
  }
}
