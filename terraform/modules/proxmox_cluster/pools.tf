resource "proxmox_virtual_environment_pool" "pool" {
  for_each = { for pool in var.pools : pool.pool_id => pool }

  pool_id = each.value.pool_id
  comment = each.value.comment
}