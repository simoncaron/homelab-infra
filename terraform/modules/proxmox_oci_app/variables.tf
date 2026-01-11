variable "node_name" {
  description = "The Proxmox node to create the container on."
  type        = string
  default     = "pve01"
}

variable "vm_id" {
  description = "The unique ID of the LXC container."
  type        = number
  default     = null
}

variable "name" {
  description = "The name of the application container."
  type        = string
}

variable "cpu" {
  description = "The number of CPU cores to allocate to the container."
  type        = number
  default     = 1
}

variable "memory" {
  description = "The amount of memory (in MB) to allocate to the container."
  type        = number
  default     = 1024
}

variable "image" {
  description = "The OCI image to use for the container."
  type = object({
    reference    = string
    datastore_id = optional(string, "local")
  })
}

variable "root_disk" {
  description = "The root disk configuration for the container."
  type = object({
    datastore_id = optional(string, "local-zfs")
    size         = optional(number, 4)
  })
  default = {
    datastore_id = "local-zfs"
    size         = 4
  }
}

variable "environment" {
  description = "A map of environment variables to set in the container."
  type        = map(string)
  default     = {}
  sensitive   = true

  validation {
    condition = alltrue([
      for key, value in var.environment :
      can(regex("^[A-Za-z_][A-Za-z0-9_]*$", key))
    ])
    error_message = "Environment variable keys must start with a letter or underscore and contain only alphanumeric characters and underscores."
  }

  validation {
    condition = alltrue([
      for key, value in var.environment :
      !can(regex("[`$;|&<>(){}\\[\\]'\"]", value))
    ])
    error_message = "Environment variable values must not contain shell metacharacters (backticks, $, ;, |, &, <, >, parentheses, braces, brackets, quotes)."
  }
}

variable "enable_nvidia_gpu" {
  description = "Whether to enable NVIDIA GPU passthrough in the container."
  type        = bool
  default     = false
}

variable "volumes" {
  description = "A list of persistent volumes to create and attach to the container."
  type = list(object({
    id      = number
    path    = string
    storage = optional(string, "local-zfs")
    node    = optional(string, "pve01")
    size    = string
    backup  = optional(bool, true)
    uid     = optional(number, 100000)
    gid     = optional(number, 100000)
  }))

  default = []
}

variable "bind_mounts" {
  description = "A map of bind mounts to create and attach to the container."
  type = list(object({
    host_path      = string
    container_path = string
    read_only      = optional(bool, false)
  }))
  default = []
}

variable "networking" {
  description = "Networking configuration for the container."
  type = object({
    bridge  = string
    address = optional(string, "dhcp")
    gateway = optional(string)
  })
  default = {
    address = "dhcp"
    bridge  = "vmbr0"
  }
}

variable "tags" {
  description = "A list of tags to apply to the container in Proxmox."
  type        = list(string)
  default     = []
}

variable "device_passthrough" {
  description = "A list of devices to passthrough to the container."
  type = list(object({
    path = string
    mode = optional(string, "0666")
  }))
  default = []
}

variable "storage_mount_path" {
  description = "The base mount path where Proxmox storage volumes are located on the host."
  type        = string
  default     = "/rpool/data"
}
