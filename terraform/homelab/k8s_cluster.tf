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

  machines = {
    "k8s-controlplane01" = {
      pve_node = "pvenuc01"
      type     = "controlplane"
      cpu      = 4
      memory   = 8192
      interfaces = [{
        hardwareAddr = "0c:c4:7a:a4:c1:00"
        addresses    = ["192.168.1.243"]
      }]
    },
    "k8s-controlplane02" = {
      pve_node = "pvenuc02"
      type     = "controlplane"
      cpu      = 4
      memory   = 8192
      interfaces = [{
        hardwareAddr = "0c:c4:7a:a4:c2:00"
        addresses    = ["192.168.1.244"]
      }]
    },
    "k8s-controlplane03" = {
      pve_node = "pvenuc03"
      type     = "controlplane"
      cpu      = 4
      memory   = 8192
      interfaces = [{
        hardwareAddr = "0c:c4:7a:a4:c3:00"
        addresses    = ["192.168.1.245"]
      }]
    },
    "k8s-worker01" = {
      pve_node = "pvenuc01"
      type     = "worker"
      cpu      = 8
      memory   = 16384
      interfaces = [
        {
          hardwareAddr = "0c:c4:7a:a4:b1:00"
          addresses    = ["192.168.1.246"]
        }
      ]
    },
    "k8s-worker02" = {
      pve_node = "pvenuc02"
      type     = "worker"
      cpu      = 8
      memory   = 16384
      interfaces = [
        {
          hardwareAddr = "0c:c4:7a:a4:b2:00"
          addresses    = ["192.168.1.247"]
        }
      ]
    },
    "k8s-worker03" = {
      pve_node = "pvenuc03"
      type     = "worker"
      cpu      = 8
      memory   = 16384
      interfaces = [
        {
          hardwareAddr = "0c:c4:7a:a4:b3:00"
          addresses    = ["192.168.1.248"],
        }
      ]
    }
  }
}

module "sealed_secrets" {
  depends_on = [module.talos_cluster]
  source     = "../modules/bootstrap/sealed-secrets"
  cert = {
    key  = data.bitwarden_item_secure_note.sealed_secrets_private_key.notes
    cert = data.bitwarden_item_secure_note.sealed_secrets_public_key.notes
  }
}

module "proxmox_csi_plugin" {
  depends_on = [module.talos_cluster]
  source     = "../modules/bootstrap/proxmox-csi-plugin"

  proxmox_cluster = {
    endpoint     = "https://pve-cluster01.simn.io:8006/"
    insecure     = true
    cluster_name = "pve-cluster01"
  }
}
