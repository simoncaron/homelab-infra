# Infrastructure

## Requirements

- Python 3
- Locally configured SSH config
- `ansible` installed on the system
- [`just`](https://github.com/casey/just)

## Installation

- `just setup`
- `just terraform init`

### Private Settings

Ansible integrates with Hashicorp Vault Secrets through its CLI.

Terraform secrets need to be referenced in `terraform/secrets.tf`.

## Deploying

- `just ansible-deploy`
- `just terraform apply`

## Credits

Based on the work of:
- @RealOrangeOne https://github.com/RealOrangeOne/infrastructure
- @ironicbadger https://github.com/ironicbadger/infra
