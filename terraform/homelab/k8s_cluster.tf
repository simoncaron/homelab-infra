locals {
  # Common configuration for control plane nodes
  controlplane_base_config = {
    type   = "controlplane"
    cpu    = 4
    memory = 8192
  }

  # Control-plane-specific configurations (unique properties per worker)
  controlplane_nodes = {
    "k8s-controlplane01" = {
      pve_node = "pvenuc01"
      interfaces = [{
        hardwareAddr = "0c:c4:7a:a4:c1:00"
        addresses    = ["192.168.1.243"]
      }]
    },
    "k8s-controlplane02" = {
      pve_node = "pvenuc02"
      interfaces = [{
        hardwareAddr = "0c:c4:7a:a4:c2:00"
        addresses    = ["192.168.1.244"]
      }]
    },
    "k8s-controlplane03" = {
      pve_node = "pvenuc03"
      interfaces = [{
        hardwareAddr = "0c:c4:7a:a4:c3:00"
        addresses    = ["192.168.1.245"]
      }]
    }
  }

  # Common configuration for all worker nodes
  worker_base_config = {
    type   = "worker"
    cpu    = 8
    memory = 16384
    igpu   = true
    disks = [{
      device = "/dev/sdb"
      partitions = [{
        mountpoint = "/var/lib/longhorn"
      }]
    }]
    extra_mounts = [{
      source      = "/var/lib/longhorn"
      destination = "/var/lib/longhorn"
      type        = "bind"
      options     = ["rbind", "rw", "rshared"]
    }]
  }

  # Worker-specific configurations (unique properties per worker)
  worker_nodes = {
    "k8s-worker01" = {
      pve_node = "pvenuc01"
      interfaces = [
        {
          hardwareAddr = "0c:c4:7a:a4:b1:00"
          addresses    = ["192.168.1.246"]
        },
        {
          hardwareAddr = "0c:c4:7a:a4:b1:01"
          addresses    = ["10.15.15.246"]
        }
      ]
    },
    "k8s-worker02" = {
      pve_node = "pvenuc02"
      interfaces = [
        {
          hardwareAddr = "0c:c4:7a:a4:b2:00"
          addresses    = ["192.168.1.247"]
        },
        {
          hardwareAddr = "0c:c4:7a:a4:b2:01"
          addresses    = ["10.15.15.247"]
        }
      ]
    },
    "k8s-worker03" = {
      pve_node = "pvenuc03"
      interfaces = [
        {
          hardwareAddr = "0c:c4:7a:a4:b3:00"
          addresses    = ["192.168.1.248"],
        },
        {
          hardwareAddr = "0c:c4:7a:a4:b3:01"
          addresses    = ["10.15.15.248"]
        }
      ]
    }
  }

  # Merge all configurations to create the final machines map
  controlplane_configs = {
    for name, node in local.controlplane_nodes : name => merge(local.controlplane_base_config, node)
  }

  worker_configs = {
    for name, node in local.worker_nodes : name => merge(local.worker_base_config, node)
  }

  machines = merge(local.controlplane_configs, local.worker_configs)
}

module "talos_cluster" {
  source = "../modules/talos_cluster"

  cluster_name     = "k8s-homelab-cluster"
  cluster_endpoint = "192.168.1.243"
  cluster_vip      = "192.168.1.249"

  machine_network_nameservers = ["192.168.1.10", "192.168.1.114"]

  kubernetes_version = "1.31.2"

  talos_image = {
    version = "v1.9.5"
    extensions = [
      "siderolabs/iscsi-tools",
      "siderolabs/qemu-guest-agent",
      "siderolabs/util-linux-tools"
    ]
  }

  updated_talos_image = {
    version = "v1.9.5"
    extensions = [
      "siderolabs/iscsi-tools",
      "siderolabs/qemu-guest-agent",
      "siderolabs/util-linux-tools",
      "siderolabs/i915-ucode",
      "siderolabs/intel-ucode"
    ]
  }

  machines = local.machines
}
