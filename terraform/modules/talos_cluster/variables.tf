variable "cluster_name" {
  description = "A name to provide for the Talos cluster."
  type        = string
  default     = "cluster"

  validation {
    condition     = length(var.cluster_name) <= 32 && can(regex("^([a-z0-9]+-)*[a-z0-9]+$", var.cluster_name))
    error_message = "The name must contain at most 32 characters, begin and end with a lower case alphanumeric character, and may contain lower case alphanumeric characters and dashes between."
  }
}

variable "cluster_endpoint" {
  description = "The endpoint for the Talos cluster."
  type        = string
  default     = "10.10.10.10"
}

variable "cluster_vip" {
  description = "The VIP to use for the Talos cluster. Applied to the first interface of control plane machines."
  type        = string
  default     = ""
}

variable "cluster_node_subnet" {
  description = "The subnet to use for the Talos cluster nodes."
  type        = string
  default     = "192.168.1.0/24"
}

variable "cluster_allowSchedulingOnControlPlanes" {
  description = "Whether to allow scheduling on control plane nodes."
  type        = bool
  default     = false
}

variable "machine_network_nameservers" {
  description = "A list of nameservers to use for the Talos cluster."
  type        = list(string)
  default     = ["1.1.1.1", "1.0.0.1"]
}

variable "machine_files" {
  description = "A list of files to add to all machines in the cluster. See: https://www.talos.dev/v1.9/reference/configuration/v1alpha1/config/#Config.machine.files."
  type = list(object({
    content     = string
    permissions = optional(string, "0o644")
    path        = string
    op          = string
  }))
  default = []

  validation {
    condition     = alltrue([for file in var.machine_files : file.op == "create" || file.op == "append" || file.op == "overwrite"])
    error_message = "The 'op' field in machine_files must be one of 'create', 'append', or 'overwrite'."
  }
}

variable "talos_config_path" {
  description = "The path to output the Talos configuration file."
  type        = string
  default     = "~/.talos"
}

variable "kube_config_path" {
  description = "The path to output the Kubernetes configuration file."
  type        = string
  default     = "~/.kube"
}

variable "kubernetes_version" {
  description = "The version of kubernetes to deploy."
  type        = string
  default     = "1.30.1"
}

variable "talos_image" {
  description = "The Talos image configuration."
  type = object({
    arch              = optional(string, "amd64")
    platform          = optional(string, "nocloud")
    factory_url       = optional(string, "https://factory.talos.dev")
    extensions        = list(string)
    version           = string
    update_extensions = optional(list(string))
    update_version    = optional(string)
  })
}

variable "timeout" {
  description = "The timeout to use for the Talos cluster."
  type        = string
  default     = "10m"
}

variable "machine_kubelet_extraArgs" {
  description = "A list of extra arguments to pass to the kubelet."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "machines" {
  description = "A list of machines to create the talos cluster from."
  type = map(object({
    type         = string
    pve_node     = string
    cpu          = number
    memory       = number
    igpu         = optional(bool, false)
    update_talos = optional(bool, false)
    disks = optional(list(object({
      device = string
      partitions = list(object({
        mountpoint = string
        size       = optional(string, "")
      }))
    })), [])
    extra_mounts = optional(list(object({
      source      = string
      destination = string
      type        = string
      options     = list(string)
    })), [])
    labels = optional(list(object({
      key   = string
      value = optional(string, "")
    })), [])
    files = optional(list(object({
      content     = string
      permissions = string
      path        = string
      op          = string
    })), [])
    interfaces = list(object({
      hardwareAddr     = string
      mtu              = optional(number)
      addresses        = list(string)
      dhcp_routeMetric = optional(number, 100)
      dhcp             = optional(bool, false)
      vlans = optional(list(object({
        vlanId           = number
        addresses        = list(string)
        dhcp_routeMetric = optional(number, 100)
      })), [])
    }))
  }))
}
