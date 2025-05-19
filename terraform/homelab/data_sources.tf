data "bitwarden_item_login" "proxmox_password" {
  id = "d68b9210-7ef9-4066-98db-1fee4492da8b"
}

data "bitwarden_item_login" "proxmox_user" {
  id = "6b4bd7da-b5e5-4717-b4f7-4230636bb37b"
}

data "bitwarden_item_login" "adguard_home_credentials" {
  id = "38b92cad-dce1-454a-971a-abb204790eef"
}

data "bitwarden_item_secure_note" "sealed_secrets_private_key" {
  id = "787b59fd-109b-4e25-a10a-5226b7934f8b"
}

data "bitwarden_item_secure_note" "sealed_secrets_public_key" {
  id = "57f9dd37-16a3-4478-875f-07250b6210d4"
}