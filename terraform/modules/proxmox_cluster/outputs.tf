
output "user_tokens" {
  description = "User tokens generated for each user"
  sensitive   = true
  value = { for user in var.users : user.name => {
    user_name    = user.token.name
    token_id     = proxmox_virtual_environment_user_token.tokens[user.name].id
    token_secret = element(split("=", proxmox_virtual_environment_user_token.tokens[user.name].value), length(split("=", proxmox_virtual_environment_user_token.tokens[user.name].value)) - 1)
  } }
}