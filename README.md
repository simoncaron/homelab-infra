# homelab-infra

## Requirements

- Python 3
- Locally configured SSH config
- `ansible` installed on the system
- [`just`](https://github.com/casey/just)

## Installation

- `just setup`
- `just terraform init`

### Private Settings

This project uses ansible-vault for managing secrets for both Ansible/Docker configurations and Terraform deployments.

## Deploying

- `just ansible-deploy`
- `just terraform apply`

## Credits

Based on the work of:
- @RealOrangeOne https://github.com/RealOrangeOne/infrastructure
- @ironicbadger https://github.com/ironicbadger/infra
