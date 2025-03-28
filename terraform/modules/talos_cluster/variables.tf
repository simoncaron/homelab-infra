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

variable "cluster_allowSchedulingOnControlPlanes" {
  description = "Whether to allow scheduling on control plane nodes."
  type        = bool
  default     = true
}

variable "machine_kubelet_extraMounts" {
  description = "A list of extra mounts to add to the kubelet."
  type = list(object({
    destination = string
    type        = string
    source      = string
    options     = list(string)
  }))
  default = []
}

variable "machine_network_nameservers" {
  description = "A list of nameservers to use for the Talos cluster."
  type        = list(string)
  default     = ["1.1.1.1", "1.0.0.1"]
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

variable "talos_version" {
  description = "The version of Talos to use."
  type        = string
  default     = "v1.9.0"
}

variable "timeout" {
  description = "The timeout to use for the Talos cluster."
  type        = string
  default     = "10m"
}

variable "machines" {
  description = "A list of machines to create the talos cluster from."
  type = map(object({
    type = string
    disks = optional(list(object({
      device = string
      partitions = list(object({
        mountpoint = string
        size       = optional(string, "")
      }))
    })), [])
    files = optional(list(object({
      content     = string
      permissions = string
      path        = string
      op          = string
    })), [])
    interfaces = list(object({
      hardwareAddr     = string
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

