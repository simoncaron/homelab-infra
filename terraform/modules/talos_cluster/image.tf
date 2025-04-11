locals {
  # Build the versions map directly with conditional merge
  talos_versions = merge(
    {
      "${md5(join(",", var.talos_image.extensions))}_${var.talos_image.version}" = {
        version    = var.talos_image.version
        extensions = var.talos_image.extensions
      }
    },
    var.talos_image.update_version != null ? {
      "${md5(join(",", var.talos_image.update_extensions))}_${var.talos_image.update_version}" = {
        version    = var.talos_image.update_version
        extensions = var.talos_image.update_extensions
      }
    } : {}
  )

  # Create the node-version combinations
  pve_nodes_versions = flatten([
    for version_key, version_info in local.talos_versions : [
      for machine in var.machines : {
        pve_node         = machine.pve_node
        talos_version    = version_info.version
        talos_extensions = version_info.extensions
        image_id         = version_key
      }
    ]
  ])
}

data "talos_image_factory_extensions_versions" "this" {
  for_each      = local.talos_versions
  talos_version = each.value.version
  filters = {
    names = each.value.extensions
  }
}

resource "proxmox_virtual_environment_download_file" "this" {
  for_each = toset(distinct([for k, v in local.pve_nodes_versions : "${v.pve_node}_${v.image_id}"]))

  content_type = "iso"
  datastore_id = "local"
  node_name    = split("_", each.key)[0]

  file_name               = "talos-${split("_", each.key)[1]}-${split("_", each.key)[2]}-${var.talos_image.platform}-${var.talos_image.arch}.img"
  url                     = "${var.talos_image.factory_url}/image/${talos_image_factory_schematic.this["${split("_", each.key)[1]}_${split("_", each.key)[2]}"].id}/${split("_", each.key)[2]}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}

resource "talos_image_factory_schematic" "this" {
  for_each = local.talos_versions
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