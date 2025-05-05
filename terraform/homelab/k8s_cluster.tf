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
  }

  # Worker-specific configurations (unique properties per worker)
  worker_nodes = {
    "k8s-worker01" = {
      pve_node = "pvenuc01"
      interfaces = [
        {
          hardwareAddr = "0c:c4:7a:a4:b1:00"
          addresses    = ["192.168.1.246"]
        }
      ]
    },
    "k8s-worker02" = {
      pve_node = "pvenuc02"
      interfaces = [
        {
          hardwareAddr = "0c:c4:7a:a4:b2:00"
          addresses    = ["192.168.1.247"]
        }
      ]
    },
    "k8s-worker03" = {
      pve_node = "pvenuc03"
      interfaces = [
        {
          hardwareAddr = "0c:c4:7a:a4:b3:00"
          addresses    = ["192.168.1.248"],
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

  cluster_name    = "k8s-homelab-cluster"
  proxmox_cluster = "pve-cluster01"

  cluster_endpoint = "192.168.1.243"
  cluster_vip      = "192.168.1.249"

  machine_network_nameservers = ["192.168.1.10", "192.168.1.114"]

  # Spegel layer configuration
  machine_files = [
    {
      path    = "/etc/cri/conf.d/20-customization.part"
      op      = "create"
      content = <<EOT
        [plugins."io.containerd.cri.v1.images"]
          discard_unpacked_layers = false
      EOT
    }
  ]

  kubernetes_version = "1.31.2"

  talos_image = {
    version = "v1.9.5"
    extensions = [
      "siderolabs/qemu-guest-agent",
      "siderolabs/i915-ucode",
      "siderolabs/intel-ucode"
    ]
  }

  machines = local.machines
}

module "k8s_secrets_bootstrap" {
  source = "../modules/k8s_secrets_bootstrap"

  secrets = {
    "sealed-secret-key" = {
      namespace = {
        name   = "kube-system"
        create = false
      }
      secret = {
        name = "sealed-secrets-key"
        type = "kubernetes.io/tls"
        labels = {
          "sealedsecrets.bitnami.com/sealed-secrets-key" : "active"
        }
        data = {
          "tls.key" = data.bitwarden_item_secure_note.sealed_secrets_private_key.notes
          "tls.crt" = data.bitwarden_item_secure_note.sealed_secrets_public_key.notes
        }
      }
    }
    "proxmox-csi-plugin" = {
      name = "proxmox-csi-plugin"
      namespace = {
        name = "csi-proxmox"
        labels = {
          "pod-security.kubernetes.io/enforce" : "privileged"
          "pod-security.kubernetes.io/audit" : "baseline"
          "pod-security.kubernetes.io/warn" : "baseline"
        }
        create = true
      }
      secret = {
        name   = "proxmox-csi-plugin"
        type   = "Opaque"
        labels = {}
        data = {
          "config.yaml" = <<EOF
            clusters:
            - url: "https://pve-cluster01.simn.io:8006/api2/json"
              insecure: true
              token_id: "${module.proxmox_cluster.user_tokens["kubernetes-csi"].token_id}"
              token_secret: "${module.proxmox_cluster.user_tokens["kubernetes-csi"].token_secret}"
              region: pve-cluster01
            EOF
        }
      }
    }
  }
}
