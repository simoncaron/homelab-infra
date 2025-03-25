output "image_id" {
  value       = talos_image_factory_schematic.this.id
  description = "The ID of the generated Talos image schematic"
}

output "proxmox_file_id" {
  value       = "local:iso/talos-${var.talos_version}-nocloud-amd64.img"
  description = "The Proxmox ISO file ID for the generated Talos image"
}