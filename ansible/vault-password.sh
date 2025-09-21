#!/bin/bash

if [ -n "${ANSIBLE_VAULT_PASSWORD+x}" ]; then
  echo -n "$ANSIBLE_VAULT_PASSWORD"
else
  bw get password Infrastructure-Ansible-Vault
fi