data "bitwarden_item_login" "cloudflare_api_token" {
  id = "26ce8b2c-4f13-4030-8a93-1d5b759e9574"
}

data "bitwarden_item_login" "proxmox_password" {
  id = "d68b9210-7ef9-4066-98db-1fee4492da8b"
}

data "bitwarden_item_login" "proxmox_user" {
  id = "6b4bd7da-b5e5-4717-b4f7-4230636bb37b"
}

data "bitwarden_item_login" "oci_fingerprint" {
  id = "dddd739d-1e9d-48b1-af55-e183e1000874"
}

data "bitwarden_item_login" "oci_user" {
  id = "128903c9-59fb-442d-8c74-6307a514e088"
}

data "bitwarden_item_login" "oci_tenancy" {
  id = "63ea2a5a-0997-4f71-b732-a7d42f8da556"
}

data "bitwarden_item_secure_note" "oci_private_key" {
  id = "7e5fe57f-20c8-456c-8cc1-3bdc696ff10c"
}

data "bitwarden_item_login" "oci_compartment" {
  id = "2e06d089-381b-49e9-abeb-d99dba9e7280"
}

data "bitwarden_item_login" "tailscale_oauth_client_secret" {
  id = "acef7bc5-a93f-4a90-b493-b9e406ce3295"
}