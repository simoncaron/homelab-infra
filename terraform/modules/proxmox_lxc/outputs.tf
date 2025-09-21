output "id" {
  description = "The full ID of the created LXC container (e.g., 'pve01/lxc/114')."
  value       = proxmox_virtual_environment_container.lxc.id
}

output "vm_id" {
  description = "The numeric VMID of the LXC container."
  value       = proxmox_virtual_environment_container.lxc.vm_id
}
