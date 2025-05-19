variable "proxmox_cluster" {
  description = "Proxmox cluster configuration"
  type = object({
    cluster_name = string
    endpoint     = string
    insecure     = bool
  })
}

variable "namespace" {
  description = "Namespace where Proxmox CSI Plugin will be installed"
  type        = string
  default     = "csi-proxmox"
}