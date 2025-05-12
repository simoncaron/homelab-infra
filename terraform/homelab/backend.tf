terraform {
  backend "s3" {
    bucket                      = "tfstate"
    key                         = "homelab-infra.tfstate"
    region                      = "us-east-1"
    endpoint                    = "minio.simn.io:9000"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}