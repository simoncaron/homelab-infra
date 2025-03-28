data "talos_cluster_health" "k8s_api_available" {
  client_configuration   = data.talos_client_configuration.this.client_configuration
  endpoints              = local.controlplane_ips
  control_plane_nodes    = local.controlplane_ips
  skip_kubernetes_checks = true

  timeouts = {
    read = var.timeout
  }
}

data "talos_cluster_health" "this" {
  client_configuration   = data.talos_client_configuration.this.client_configuration
  endpoints              = local.controlplane_ips
  control_plane_nodes    = local.controlplane_ips
  skip_kubernetes_checks = false

  timeouts = {
    read = var.timeout
  }
}
