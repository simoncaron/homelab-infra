variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "node_name" {
  description = "Name of the Proxmox node"
  type        = string
}

variable "vm_id" {
  description = "Specific ID for the VM. If null or not provided, Proxmox will assign the next available ID."
  type        = number
  default     = null
}

variable "on_boot" {
  description = "Start the VM on boot"
  type        = bool
  default     = false
}

variable "agent_enabled" {
  description = "Enable QEMU guest agent"
  type        = bool
  default     = true
}

variable "pool_id" {
  description = "Resource pool ID"
  type        = string
  default     = "terraform"
}

variable "tags" {
  description = "List of tags to apply to the VM"
  type        = list(string)
  default     = []
}

variable "cpu_type" {
  description = "CPU type"
  type        = string
  default     = "x86-64-v2-AES"
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 4
}

variable "cpu_architecture" {
  description = "CPU architecture"
  type        = string
  default     = "x86_64"
}

variable "memory_dedicated" {
  description = "Dedicated memory in MB"
  type        = number
  default     = 16384
}

variable "memory_floating" {
  description = "Floating memory in MB"
  type        = number
  default     = null
}

variable "machine" {
  description = "Machine type"
  type        = string
  default     = "pc"
}

variable "boot_order" {
  description = "Boot order of the VM"
  type        = list(string)
  default     = ["scsi0"]
}

variable "disks" {
  description = "List of disk configurations"
  type = list(object({
    datastore_id = string
    file_id      = optional(string)
    interface    = string
    iothread     = optional(bool, true)
    discard      = optional(string, "on")
    size         = number
    cache        = optional(string, "writeback")
    ssd          = optional(bool, true)
    file_format  = optional(string, "raw")
  }))
  default = []
}

variable "scsi_hardware" {
  description = "SCSI controller model"
  type        = string
  default     = "virtio-scsi-single"
}

variable "initialization" {
  description = "Cloud-init configuration for the VM."
  type = object({
    datastore_id = string
    ip_config = optional(object({
      ipv4 = optional(object({
        address = string
        gateway = string
      }))
    }))
    user_account = optional(object({
      username = string
      keys     = list(string)
    }))
    vendor_data_file_id = optional(string)
  })
  default = null
}

variable "network_devices" {
  description = "List of network device configurations"
  type = list(object({
    bridge      = string
    mac_address = optional(string)
    mtu         = optional(number)
    queues      = optional(number, 4)
  }))
  default = []
}

variable "hostpci" {
  description = "A list of PCI passthrough configurations for the VM."
  type = list(object({
    device  = string
    mapping = string
    pcie    = optional(bool, true)
    rombar  = optional(bool, true)
  }))
  default = []
}

variable "operating_system" {
  description = "Operating system type"
  type = object({
    type = string
  })
  default = {
    type = "l26"
  }
}

variable "serial_device" {
  description = "Serial device configuration"
  type = object({
    device = string
  })
  default = {
    device = "socket"
  }
}

variable "domain" {
  description = "Domain of the virtual machine, used for the primary AdGuard rewrite rule."
  type        = string
  default     = "simn.io"
}

variable "extra_adguard_rewrites" {
  description = "A list of extra AdGuard rewrite rules to create for the VM."
  type = list(object({
    domain = string
    answer = string
  }))
  default = []
}