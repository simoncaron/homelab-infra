
export PATH := justfile_directory() + "/env/bin:" + env_var("PATH")

# Recipes
@default:
  just --list

ansible-setup:
    python -m venv .venv
    pip3 install -r ansible/dev-requirements.txt
    cd ansible/ && ansible-galaxy install -r requirements.yml --force

# Run terraform with required environment
terraform +ARGS:
    #!/usr/bin/env bash
    cd terraform/homelab/

    terraform {{ ARGS }}

ansible-deploy *ARGS:
    cd ansible/ && ansible-playbook site.yml {{ ARGS }}

terraform-lint:
    just terraform validate
    just terraform fmt -check -recursive

yamllint:
    yamllint -s .

ansible-lint: yamllint
    #!/usr/bin/env bash
    cd ansible/

    ansible-lint -p
    ansible-playbook site.yml --syntax-check

lint: terraform-lint ansible-lint
