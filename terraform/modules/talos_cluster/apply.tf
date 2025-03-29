locals {
  bootstrap_node     = [for machine_key, machine in var.machines : machine_key if machine.type == "controlplane"][0]
  bootstrap_endpoint = [for machine_key, machine in var.machines : machine.interfaces[0].addresses[0] if machine.type == "controlplane"][0]
}

resource "talos_machine_configuration_apply" "machines" {
  for_each = var.machines

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration
  node                        = each.key
  endpoint                    = each.value.interfaces[0].addresses[0]
  depends_on                  = [module.k8s_cluster_nodes]
  lifecycle {
    # re-run config apply if vm changes
    replace_triggered_by = [module.k8s_cluster_nodes[each.key]]
  }
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.machines]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.bootstrap_node
  endpoint             = local.bootstrap_endpoint
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.bootstrap_node
  endpoint             = local.bootstrap_endpoint
}
