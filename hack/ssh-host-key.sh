#!/usr/bin/env bash

set -euo pipefail

: "${EXTRA_FILES_PATH:=$(mktemp -d)}"

if [[ -z "$SSH_HOST_KEY" ]]; then
    echo "missing SSH_HOST_KEY env var"
    exit 1
fi

pushd "$EXTRA_FILES_PATH" > /dev/null

mkdir -p etc/ssh
echo "$SSH_HOST_KEY" > etc/ssh/ssh_host_ed25519_key
chmod 600 etc/ssh/ssh_host_ed25519_key

popd > /dev/null

echo "$EXTRA_FILES_PATH"
