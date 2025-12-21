variable "node_name" {
  description = "The Proxmox node to create the container on."
  type        = string
  default     = "pve01"
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
    size         = optional(number, 16)
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
}

variable "enable_nvidia_gpu" {
  description = "Whether to enable NVIDIA GPU passthrough in the container."
  type        = bool
  default     = false
}

variable "volumes" {
  description = "A map of persistent volumes to create and attach to the container."
  type = map(object({
    path    = string
    storage = optional(string, "local-zfs")
    node    = optional(string, "pve01")
    size    = string
    backup  = optional(bool, true)
  }))

  default = {}
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

variable "domain" {
  description = "The domain name to use for the container DNS record."
  type        = string
  default     = "simn.io"
}