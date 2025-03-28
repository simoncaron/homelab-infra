variable "talos_version" {
  type        = string
  description = "Version of Talos to use"
}

variable "target_pve_nodes" {
  type        = set(string)
  description = "List of Proxmox nodes to target"
}

variable "pve_datastore_id" {
  type        = string
  description = "Datastore ID for the Proxmox VM"
  default     = "local"
}

variable "extensions" {
  type = list(string)
  default = [
    "siderolabs/iscsi-tools",
    "siderolabs/qemu-guest-agent",
    "siderolabs/util-linux-tools"
  ]
}