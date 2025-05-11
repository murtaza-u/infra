#!/usr/bin/env bash

set -euo pipefail

if [[ -z "$SSH_HOST_KEY" ]]; then
    echo "missing SSH_HOST_KEY env var"
    exit 1
fi

mkdir -p etc/ssh
echo "$SSH_HOST_KEY" > etc/ssh/ssh_host_ed25519_key
chmod 600 etc/ssh/ssh_host_ed25519_key
