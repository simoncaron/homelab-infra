variable "vm_id" {
  description = "The unique ID of the LXC container."
  type        = number
  default     = null
}

variable "hostname" {
  description = "The hostname of the LXC container."
  type        = string
}

variable "node_name" {
  description = "The Proxmox node to create the LXC on."
  type        = string
  default     = "pve01"
}

variable "started" {
  description = "Whether the container should be started after creation."
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Whether the container should start automatically when the Proxmox host boots."
  type        = bool
  default     = false
}

variable "unprivileged" {
  description = "Whether the container should be unprivileged."
  type        = bool
  default     = true
}

variable "features" {
  description = "Features to enable for the LXC container (e.g., nesting, keyctl)."
  type = object({
    keyctl  = optional(bool, false)
    nesting = optional(bool, true)
    mount   = optional(list(string), [])
  })
  default = {
    keyctl  = false
    nesting = true
  }
}

variable "root_password" {
  description = "The root password for the container. If not root password is set, default module password will be used."
  type        = string
  sensitive   = true
  default     = null
}

variable "ssh_public_keys" {
  description = "A list of SSH public keys to install for the root user. If no keys are provided, the default SSH public key will be used."
  type        = list(string)
  default     = []
  sensitive   = true
}

variable "dns_config" {
  description = "DNS configuration options for the container."
  type = object({
    domain  = string
    servers = list(string)
  })
  default = null
}

variable "network_interfaces" {
  description = "A list of network interfaces to create for the container, including their IP configurations."
  type = list(object({
    name     = string
    bridge   = string
    firewall = optional(bool, false)
    vlan_id  = optional(number)
    ipv4 = optional(object({
      address = optional(string, "dhcp")
      gateway = optional(string)
    }), { address = "dhcp" })
    ipv6 = optional(object({
      address = optional(string, "auto")
      gateway = optional(string)
    }), null)
  }))
}

variable "template_file_id" {
  description = "The Proxmox template file ID to use for the container."
  type        = string
}

variable "os_type" {
  description = "The type of the operating system."
  type        = string
  default     = "debian"
}

variable "hook_script_file_id" {
  description = "The Proxmox hook script file ID."
  type        = string
  default     = null
}

variable "tags" {
  description = "A list of tags to apply to the container in Proxmox."
  type        = list(string)
  default     = []
}

variable "pool_id" {
  description = "The Proxmox resource pool ID to assign this container to."
  type        = string
  default     = "terraform"
}

variable "cpu_cores" {
  description = "The number of CPU cores for the container."
  type        = number
  default     = 1
}

variable "cpu_architecture" {
  description = "The CPU architecture for the container."
  type        = string
  default     = "amd64"
}

variable "memory_dedicated" {
  description = "The dedicated memory in MB for the container."
  type        = number
  default     = 512
}

variable "memory_swap" {
  description = "The swap memory in MB for the container."
  type        = number
  default     = 0
}

variable "disk_datastore_id" {
  description = "The Proxmox datastore ID for the container's root disk."
  type        = string
  default     = "local-zfs"
}

variable "disk_size" {
  description = "The size of the root disk in GB."
  type        = number
  default     = 8
}

variable "description" {
  description = "A description for the LXC container."
  type        = string
  default     = ""
}

variable "mount_points" {
  description = "A list of mount points to configure for the container."
  type = list(object({
    path   = string
    volume = string
    backup = optional(bool, false)
  }))
  default = []
}

variable "domain" {
  description = "The domain suffix to append to the hostname for DNS records."
  type        = string
  default     = "simn.io"
}

variable "passthrough_gpu" {
  description = "Whether to enable GPU passthrough for the container."
  type        = bool
  default     = false
}

variable "passthrough_tun" {
  description = "Whether to enable TUN/TAP device passthrough for the container."
  type        = bool
  default     = false
}

variable "device_passthrough" {
  description = "A list of devices to passthrough to the container."
  type        = list(string)
  default     = []
}
