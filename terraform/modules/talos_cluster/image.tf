locals {
  talos_versions = var.updated_talos_version != null ? tolist([var.talos_version, var.updated_talos_version]) : tolist([var.talos_version])
  pve_nodes_versions = flatten([
    for version in local.talos_versions : [
      for machine in var.machines : {
        pve_node      = machine.pve_node
        talos_version = version
      }
    ]
  ])
}

data "talos_image_factory_extensions_versions" "this" {
  for_each      = { for version in local.talos_versions : version => version }
  talos_version = each.key
  filters = {
    names = var.machine_extensions
  }
}

resource "proxmox_virtual_environment_download_file" "talos_nocloud_image" {
  for_each = toset(distinct([for k, v in local.pve_nodes_versions : "${v.pve_node}_${v.talos_version}"]))

  content_type = "iso"
  datastore_id = "local"
  node_name    = split("_", each.key)[0]

  file_name               = "talos-${split("_", each.key)[1]}-nocloud-amd64.img"
  url                     = "https://factory.talos.dev/image/${talos_image_factory_schematic.this[split("_", each.key)[1]].id}/${split("_", each.key)[1]}/nocloud-amd64.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}

resource "talos_image_factory_schematic" "this" {
  for_each = { for version in local.talos_versions : version => version }
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this[each.key].extensions_info.*.name
        }
      }
    }
  )
}