locals {
  pve_cluster_nodes = ["pvenuc01", "pvenuc02", "pvenuc03"]

  machines = {
    "k8s-controlplane01" = {
      pve_node = "pvenuc01"
      type     = "controlplane"
      interfaces = [{
        hardwareAddr = "0c:c4:7a:a4:c1:00"
        addresses    = ["192.168.1.243"]
      }]
    },
    "k8s-controlplane02" = {
      pve_node = "pvenuc02"
      type     = "controlplane"
      interfaces = [{
        hardwareAddr = "0c:c4:7a:a4:c2:00"
        addresses    = ["192.168.1.244"]
      }]
    },
    "k8s-controlplane03" = {
      pve_node = "pvenuc03"
      type     = "controlplane"
      interfaces = [{
        hardwareAddr = "0c:c4:7a:a4:c3:00"
        addresses    = ["192.168.1.245"]
      }]
    },
    "k8s-worker01" = {
      pve_node = "pvenuc01"
      type     = "worker"
      disks = [{
        device = "/dev/sdb"
        partitions = [{
          mountpoint = "/var/lib/longhorn"
        }]
      }],
      extra_mounts = [{
        source      = "/var/lib/longhorn"
        destination = "/var/lib/longhorn"
        type        = "bind"
        options     = ["rbind", "rw", "rshared"]
      }],
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
      type     = "worker"
      disks = [{
        device = "/dev/sdb"
        partitions = [{
          mountpoint = "/var/lib/longhorn"
        }]
      }],
      extra_mounts = [{
        source      = "/var/lib/longhorn"
        destination = "/var/lib/longhorn"
        type        = "bind"
        options     = ["rbind", "rw", "rshared"]
      }],
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
      type     = "worker"
      disks = [{
        device = "/dev/sdb"
        partitions = [{
          mountpoint = "/var/lib/longhorn"
        }]
      }],
      extra_mounts = [{
        source      = "/var/lib/longhorn"
        destination = "/var/lib/longhorn"
        type        = "bind"
        options     = ["rbind", "rw", "rshared"]
      }],
      interfaces = [
        {
          hardwareAddr = "0c:c4:7a:a4:b3:00"
          addresses    = ["192.168.1.248"]
        },
        {
          hardwareAddr = "0c:c4:7a:a4:b3:01"
          addresses    = ["10.15.15.248"]
        }
      ]
    }
  }
}