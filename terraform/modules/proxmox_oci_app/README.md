# Proxmox OCI Application Container (LXC) Module

This Terraform module creates unprivileged LXC containers on Proxmox VE using OCI images, with support for persistent volumes, environment variables, GPU passthrough, and advanced configuration options.

## Requirements

### Proxmox Host Requirements

1. **libnvidia-container** (for GPU passthrough)
   - Required only if using `enable_nvidia_gpu = true`
   - Must be installed on the Proxmox host

2. **SSH Access**
   - A `terraform` user with SSH key authentication
   - Passwordless sudo access for the following commands:
     - `pct start/shutdown`
     - `sed` (for LXC config file modification)
     - `chown` (for volume permission fixing)
     - `grep`, `tee` (for config updates)

3. **Proxmox API Access**
   - API token with sufficient permissions for:
     - Container creation/deletion
     - Storage volume management
     - OCI image pulling

### Terraform Provider Requirements

```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.92.0"  # Recommended: pin to a specific version
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = "~> 1.19.0"  # Recommended: pin to a specific version
    }
  }
}
```

## Volume Creation Process

This module uses a specialized approach for managing persistent volumes. In order to keep data intact when image version changes and LXC container is recreated, disk for volumes are created using the Proxmox rest API. When a container gets recreated, the module will remove references to the volumes from the lxc config so they don't get deleted and they will get remounted to the new container instance preserving data.

### Why REST API for Volumes?

The module creates persistent ZFS subvolumes via the Proxmox REST API (using `restapi_object` resources) instead of using the Proxmox provider's native volume support inspired by https://github.com/bpg/terraform-provider-proxmox/issues/1465/.

1. **Decouples volume lifecycle from container lifecycle**: Volumes persist independently and aren't destroyed when the container is recreated
2. **Enables explicit volume management**: Allows precise control over when volumes are created/destroyed
3. **Supports volume reuse**: Containers can be replaced while keeping data intact

### Volume Creation Steps

1. **API Volume Creation** (`restapi_object.proxmox_volumes`): Creates ZFS subvolumes via Proxmox API with naming pattern `subvol-{vm_id}-disk-{id+100}`
2. **Permission Fixing** (`null_resource.fix_permissions`): Changes ownership of volumes to match unprivileged container UID/GID mappings
3. **Container Creation** (`proxmox_virtual_environment_container`): Creates container with volumes mounted
4. **Detach on Destroy** (`null_resource.detach_volumes_on_destroy`): Unmounts volumes before container deletion to prevent accidental data loss

### Storage Path Configuration

Since the subvol volumes are created by the REST API, they get created with root permissions. The `null_resource.fix_permissions` will fix permissions to default 100000:100000 perms to allow the container to write data in them.

The module defaults to `/rpool/data` as the base path for ZFS volumes. If your Proxmox storage is mounted elsewhere, override using:

```hcl
storage_mount_path = "/path/to/your/storage"
```

### Volume Disk IDs

Volume disk IDs follow the pattern `disk-{id+100}`. For example:
- `volumes[0].id = 0` → `disk-100`
- `volumes[1].id = 1` → `disk-101`

This offset avoids conflicts with the root disk and ensures consistent numbering.

### Unprivileged Container UID/GID Mapping

Proxmox unprivileged containers use UID/GID mapping (typically +100000). When setting volume ownership:
- Container UID 0 (root) = Host UID 100000
- Container UID 999 = Host UID 100999
- Container UID 1000 = Host UID 101000

Set the `uid` and `gid` in the volumes configuration to match your application's expected container UID/GID after mapping.

## Usage Example

### Basic Container

```hcl
module "app_container" {
  source = "./modules/proxmox_app_ct"

  name      = "my-app"
  node_name = "pve01"
  vm_id     = 100

  image = {
    reference    = "docker.io/library/nginx:latest"
    datastore_id = "local"
  }

  cpu    = 2
  memory = 2048

  root_disk = {
    datastore_id = "local-zfs"
    size         = 8
  }

  networking = {
    bridge  = "vmbr0"
    address = "192.168.1.100/24"
    gateway = "192.168.1.1"
  }

  tags = ["web", "production"]
}
```

### Container with Persistent Volumes

```hcl
module "app_with_storage" {
  source = "./modules/proxmox_app_ct"

  name    = "database"
  vm_id   = 101

  image = {
    reference = "docker.io/library/postgres:15"
  }

  volumes = [
    {
      id      = 0
      path    = "/var/lib/postgresql/data"
      storage = "local-zfs"
      node    = "pve01"
      size    = "20G"
      backup  = true
      uid     = 100999  # Postgres UID in unprivileged container
      gid     = 100999
    }
  ]

  environment = {
    POSTGRES_PASSWORD = "secret"
    POSTGRES_DB       = "myapp"
  }
}
```

### Container with NVIDIA GPU

```hcl
module "gpu_container" {
  source = "./modules/proxmox_app_ct"

  name      = "ml-workload"
  vm_id     = 102

  image = {
    reference = "docker.io/nvidia/cuda:12.0-base"
  }

  cpu    = 4
  memory = 8192

  enable_nvidia_gpu = true

  device_passthrough = [
    {
      path = "/dev/nvidia0"
      mode = "0666"
    },
    {
      path = "/dev/nvidiactl"
      mode = "0666"
    },
    {
      path = "/dev/nvidia-uvm"
      mode = "0666"
    }
  ]
}
```

### Container with Bind Mounts

```hcl
module "app_with_mounts" {
  source = "./modules/proxmox_app_ct"

  name  = "config-reader"
  vm_id = 103

  image = {
    reference = "docker.io/library/alpine:latest"
  }

  bind_mounts = [
    {
      host_path      = "/mnt/config"
      container_path = "/config"
      read_only      = true
    },
    {
      host_path      = "/mnt/data"
      container_path = "/data"
      read_only      = false
    }
  ]
}
```

## Input Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `name` | `string` | The hostname of the container |
| `image` | `object` | OCI image configuration (reference, datastore_id) |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `node_name` | `string` | `"pve01"` | Proxmox node name |
| `vm_id` | `number` | `null` | Container ID (auto-assigned if null, required if using volumes) |
| `cpu` | `number` | `1` | Number of CPU cores |
| `memory` | `number` | `1024` | Memory in MB |
| `root_disk` | `object` | `{datastore_id="local-zfs", size=4}` | Root disk configuration (size in GB) |
| `environment` | `map(string)` | `{}` | Environment variables (sensitive) |
| `enable_nvidia_gpu` | `bool` | `false` | Enable NVIDIA GPU passthrough |
| `volumes` | `list(object)` | `[]` | Persistent volumes list |
| `bind_mounts` | `list(object)` | `[]` | Host bind mounts |
| `device_passthrough` | `list(object)` | `[]` | Device passthrough list |
| `networking` | `object` | `{bridge="vmbr0", address="dhcp"}` | Network configuration |
| `tags` | `list(string)` | `[]` | Proxmox tags |
| `storage_mount_path` | `string` | `"/rpool/data"` | Base path for volume storage |

### Volume Object Schema

```hcl
{
  id      = number                    # Unique ID for this volume (disk will be id+100)
  path    = string                    # Mount path inside container
  storage = optional(string)          # Proxmox storage name (default: "local-zfs")
  node    = optional(string)          # Proxmox node (default: "pve01")
  size    = string                    # Size with unit (e.g., "10G", "512M")
  backup  = optional(bool)            # Include in backups (default: true)
  uid     = optional(number)          # Owner UID (default: 100000)
  gid     = optional(number)          # Owner GID (default: 100000)
}
```
