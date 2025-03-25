variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "node_name" {
  description = "Name of the Proxmox node"
  type        = string
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
  description = "Initialization configuration"
  type = object({
    datastore_id = string
    ip_config = object({
      ipv4 = object({
        address = string
        gateway = string
      })
    })
  })
  default = null
}

variable "network_devices" {
  description = "List of network device configurations"
  type = list(object({
    bridge      = string
    mac_address = optional(string)
    queues      = optional(number, 4)
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
  description = "Domain of the virtual machine"
  type        = string
  default     = "simn.io"
}
