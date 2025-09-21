output "vm_id" {
  description = "The ID of the VM"
  value       = proxmox_virtual_environment_vm.vm.id
}

output "vm_name" {
  description = "The name of the VM"
  value       = proxmox_virtual_environment_vm.vm.name
}
