resource "proxmox_virtual_environment_dns" "pve_dns" {
  for_each  = var.pve_cluster_nodes
  domain    = var.dns_config.domain
  node_name = each.key

  servers = var.dns_config.servers
}

resource "proxmox_virtual_environment_pool" "pool" {
  for_each = { for pool in var.pools : pool.pool_id => pool }

  pool_id = each.value.pool_id
  comment = each.value.comment
}

resource "proxmox_virtual_environment_role" "roles" {
  for_each = { for role in flatten([for user in var.users : user.roles]) : role.name => role }

  role_id    = each.key
  privileges = each.value.privileges
}

resource "proxmox_virtual_environment_user" "users" {
  for_each = var.users

  user_id = format("%s@%s", each.value.name, each.value.realm)
  comment = each.value.description
  enabled = true

  dynamic "acl" {
    for_each = [for role in each.value.roles : {
      path      = "/"
      role_id   = role.name
      propagate = true
    }]
    content {
      path      = acl.value.path
      role_id   = acl.value.role_id
      propagate = acl.value.propagate
    }
  }

  depends_on = [proxmox_virtual_environment_role.roles]
}

resource "proxmox_virtual_environment_user_token" "tokens" {
  for_each = var.users

  user_id               = proxmox_virtual_environment_user.users[each.key].user_id
  token_name            = each.value.token.name
  comment               = each.value.token.description
  privileges_separation = false

  depends_on = [proxmox_virtual_environment_user.users]
}
