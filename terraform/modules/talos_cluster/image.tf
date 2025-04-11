data "talos_image_factory_extensions_versions" "extensions" {
  talos_version = var.talos_image.version
  filters = {
    names = var.talos_image.extensions
  }
}

data "talos_image_factory_extensions_versions" "extensions_updated" {
  talos_version = var.updated_talos_image.version
  filters = {
    names = var.updated_talos_image.extensions
  }
}

resource "talos_image_factory_schematic" "schematic" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.extensions.extensions_info.*.name
        }
      }
    }
  )
}

resource "talos_image_factory_schematic" "schematic_updated" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.extensions_updated.extensions_info.*.name
        }
      }
    }
  )
}

locals {
  image_id        = "${talos_image_factory_schematic.schematic.id}_${var.talos_image.version}"
  update_image_id = "${talos_image_factory_schematic.schematic_updated.id}_${var.updated_talos_image.version}"
}

resource "proxmox_virtual_environment_download_file" "talos_nocloud_image" {
  for_each = toset(distinct([for k, v in var.machines : "${v.pve_node}_${v.update_talos == true ? local.update_image_id : local.image_id}"]))

  content_type = "iso"
  datastore_id = "local"
  node_name    = split("_", each.key)[0]

  file_name = "talos-${split("_", each.key)[1]}-${split("_", each.key)[2]}-nocloud-amd64.img"
  url       = "https://factory.talos.dev/image/${split("_", each.key)[1]}/${split("_", each.key)[2]}/nocloud-amd64.raw.gz"

  decompression_algorithm = "gz"
  overwrite               = false
}
