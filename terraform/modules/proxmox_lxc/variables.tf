# ./modules/lxc/variables.tf

variable "vm_id" {
  description = "The unique ID of the LXC container. This is a required parameter."
  type        = number
}

variable "hostname" {
  description = "The hostname of the LXC container. This is a required parameter."
  type        = string
}

variable "node_name" {
  description = "The Proxmox node to create the LXC on."
  type        = string
}

variable "started" {
  description = "Whether the container should be started after creation."
  type        = bool
  default     = false
}

variable "start_on_boot" {
  description = "Whether the container should start automatically when the Proxmox host boots."
  type        = bool
  default     = false
}

variable "unprivileged" {
  description = "Whether the container should be unprivileged. Highly recommended for security."
  type        = bool
  default     = true
}

variable "features" {
  description = "Features to enable for the LXC container (e.g., nesting, keyctl)."
  type = object({
    keyctl  = optional(bool, false) # keyctl defaults to false
    nesting = optional(bool, true)  # nesting now defaults to true
  })
  default = { # Default values for features
    keyctl  = false
    nesting = true
  }
}

variable "root_password" {
  description = "The root password for the container. This is a sensitive value."
  type        = string
  sensitive   = true
}

variable "ssh_public_keys" {
  description = "A list of SSH public keys to install for the root user. These are sensitive values."
  type        = list(string)
  default     = []
  sensitive   = true
}

variable "dns_config" {
  description = "A list of DNS configuration options for the container. This is a list of objects with 'domain' and 'servers'."
  type = object({
    domain  = string
    servers = list(string)
  })
  default = null
}

variable "network_interfaces" {
  description = "A list of network interfaces to create for the container, including their IP configurations. For IPv6, if the 'ipv6' object is provided for an interface, its 'address' attribute defaults to 'auto' if not specified. If the 'ipv6' object itself is omitted for an interface, no IPv6 configuration will be applied to that interface."
  type = list(object({
    name     = string
    bridge   = string
    firewall = optional(bool, false)
    vlan_id  = optional(number)
    ipv4 = optional(object({
      address = string
      gateway = string
    }), null)
    ipv6 = optional(object({
      address = optional(string, "auto")
      gateway = optional(string)
    }), null)
  }))
  default = [
    {
      name     = "eth0"
      bridge   = "vmbr0"
      firewall = false
      ipv4     = null
      ipv6     = { address = "auto" }
    }
  ]
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
  description = "The Proxmox hook script file ID. Set to null if no hook script is needed."
  type        = string
  default     = null
}

variable "tags" {
  description = "A list of tags to apply to the container in Proxmox."
  type        = list(string)
  default     = ["terraform-lxc"]
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
  default     = "local-lvm"
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

variable "adguard_rewrite_rules" {
  description = "A list of AdGuard Home rewrite rules. Each rule is an object with 'domain' and 'answer'."
  type = list(object({
    domain = string # The domain to rewrite
    answer = string # The IP address or CNAME the domain should resolve to
  }))
  default = [] # If this list is empty, no AdGuard rules will be created.
}

variable "firewall_rules_enabled" {
  description = "Set to true to enable managing Proxmox firewall rules for this container using this module."
  type        = bool
  default     = false
}

variable "firewall_rules" {
  description = "A list of firewall rules to apply to the container. Only applied if 'firewall_rules_enabled' is true."
  type = list(object({
    type    = optional(string, "in")
    action  = string
    iface   = optional(string)
    source  = optional(string)
    dest    = optional(string)
    macro   = optional(string)
    proto   = optional(string)
    dport   = optional(string)
    sport   = optional(string)
    log     = optional(string)
    comment = optional(string)
  }))
  default = []
}

variable "device_passthrough" {
  description = "A list of device passthrough configurations."
  type = list(object({
    path       = string           # (Required) Device path on the host (e.g., /dev/dri/renderD128 or /dev/ttyUSB0)
    deny_write = optional(bool)   # (Optional) Deny container write access (defaults to false in provider)
    gid        = optional(number) # (Optional) Group ID for the device node in the container
    mode       = optional(string) # (Optional) Access mode (4-digit octal, e.g., "0660") for the device node
    uid        = optional(number) # (Optional) User ID for the device node in the container
  }))
  default = []
}
