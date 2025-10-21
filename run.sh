#!/usr/bin/env bash

set -euo pipefail

info() {
    echo '[INFO]' "$@"
}

warn() {
    echo '[WARN]' "$@" >&2
}

fatal() {
    echo '[ERROR]' "$@" >&2
    exit 1
}

usage() {
    echo "Usage:"
    echo "  $0 build <host>"
    echo "  $0 switch <host> <target_host> <ssh_identity_file>"
    echo "  $0 install <host> <target_host> <ssh_identity_file>"
    echo "  $0 oci-setup <parent_compartment_ocid> <public_key_file>"
    exit 1
}

build() {
    local host="$1"
    nix build ".#nixosConfigurations.${host}.config.system.build.toplevel" --impure
}

switch() {
    local host="$1"
    local target_host="$2"
    local ssh_identity_file="$3"

    build "$host"

    export NIX_SSHOPTS="-i ${ssh_identity_file} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
    nix-copy-closure --to "${target_host}" "$(readlink -f ./result)"
    ssh -i "${ssh_identity_file}" \
        -o UserKnownHostsFile=/dev/null \
        -o StrictHostKeyChecking=no \
        "${target_host}" "sudo $(readlink -f ./result)/bin/switch-to-configuration switch"
}

install() {
    local host="$1"
    local target_host="$2"
    local ssh_identity_file="$3"

    nix run nixpkgs#nixos-anywhere -- \
        --generate-hardware-config nixos-generate-config "nixos/hosts/${host}/hardware.nix" \
        --flake ".#${host}" \
        --target-host "${target_host}" \
        -i "${ssh_identity_file}" \
        --ssh-option UserKnownHostsFile=/dev/null \
        --ssh-option StrictHostKeyChecking=no \
        --build-on local \
        --extra-files "$(./hack/ssh-host-key.sh)" \
        --option pure-eval false
}

oci_setup() {
    local parent_compartment_ocid="$1"
    local public_key_file="$2"

    compartment_ocid=$(oci iam compartment list \
        --compartment-id-in-subtree true \
        --query "data[?name=='homelab'].id | [0]" \
        --raw-output
    )
    if [[ -z "${compartment_ocid}" || "${compartment_ocid}" == "null" ]]; then
        info "Creating compartment 'homelab'..."
        compartment_ocid=$(oci iam compartment create \
            --compartment-id "${parent_compartment_ocid}" \
            --name homelab \
            --description "Self-hosted adventures, experiments, fun." \
            --query "data.id" \
            --raw-output
        ) || fatal "Failed to create compartment"
    else
        info "Compartment 'homelab' already exists."
    fi

    group_ocid=$(oci iam group list \
        --all \
        --query "data[?name=='HomelabTerraformProvisioners'].id | [0]" \
        --raw-output
    )
    if [[ -z "${group_ocid}" || "${group_ocid}" == "null" ]]; then
        info "Creating group 'HomelabTerraformProvisioners'..."
        group_ocid=$(oci iam group create \
            --name "HomelabTerraformProvisioners" \
            --description "Group for Terraform homelab provisioners" \
            --query "data.id" \
            --raw-output
        ) || fatal "Failed to create group"
    else
        info "Group 'HomelabTerraformProvisioners' already exists."
    fi

    user_ocid=$(oci iam user list \
        --all \
        --query "data[?name=='terraform-homelab-provisioner'].id | [0]" \
        --raw-output
    )
    if [[ -z "${user_ocid}" || "${user_ocid}" == "null" ]]; then
        info "Creating user 'terraform-homelab-provisioner'..."
        user_ocid=$(oci iam user create \
            --name "terraform-homelab-provisioner" \
            --description "Terraform service user for homelab provisioning" \
            --query "data.id" \
            --raw-output
        ) || fatal "Failed to create user"
    else
        info "User 'terraform-homelab-provisioner' already exists."
    fi

    user_in_group=$(oci iam group list-users \
        --group-id "${group_ocid}" \
        --query "data[?id=='${user_ocid}'] | [0]" \
        --raw-output
    )
    if ! echo "$user_in_group" | grep -q "${user_ocid}"; then
        info "Adding user to group..."
        oci iam group add-user \
            --group-id "${group_ocid}" \
            --user-id "${user_ocid}" || fatal "Failed to add user to group"
    else
        info "User already in group."
    fi

    policy_ocid=$(oci iam policy list \
        --all \
        --compartment-id "${parent_compartment_ocid}" \
        --query "data[?name=='TerraformHomelabProvisionPolicy'].id | [0]" \
        --raw-output
    )
    if [[ -z "${policy_ocid}" || "${policy_ocid}" == "null" ]]; then
        info "Creating policy 'TerraformHomelabProvisionPolicy'..."
        oci iam policy create \
            --name "TerraformHomelabProvisionPolicy" \
            --compartment-id "${parent_compartment_ocid}" \
            --description "Grants Terraform homelab provisioners access to manage resources in the homelab compartment" \
            --statements '[
                "Allow group HomelabTerraformProvisioners to manage compartments in tenancy",
                "Allow group HomelabTerraformProvisioners to manage domains in compartment homelab",
                "Allow group HomelabTerraformProvisioners to manage groups in compartment homelab",
                "Allow group HomelabTerraformProvisioners to manage users in compartment homelab",
                "Allow group HomelabTerraformProvisioners to manage policies in compartment homelab",
                "Allow group HomelabTerraformProvisioners to manage virtual-network-family in compartment homelab",
                "Allow group HomelabTerraformProvisioners to manage instance-family in compartment homelab"
            ]' || fatal "Failed to create policy"
    else
        info "Policy already exists."
    fi

    key_fp=$(openssl rsa -in "${public_key_file}" -pubin -outform DER 2>/dev/null | openssl md5 -c | awk '{print $2}')
    api_key_exists=$(oci iam user api-key list \
        --user-id "${user_ocid}" \
        --query "data[*].fingerprint" \
        --raw-output
    )
    if ! echo "$api_key_exists" | grep -q "${key_fp}"; then
        info "Uploading API key..."
        oci iam user api-key upload \
            --user-id "${user_ocid}" \
            --key-file "${public_key_file}" || fatal "Failed to upload API key"
    else
        info "API key already exists for this user."
    fi

    info "Homelab Compartment OCID: ${compartment_ocid}"
    info "Terraform Group OCID: ${group_ocid}"
    info "Terraform User OCID: ${user_ocid}"
}

if [[ "$#" -lt 1 ]]; then
    usage
fi

cmd="${1}"; shift

case "$cmd" in
    build)     build "$@" ;;
    switch)    switch "$@" ;;
    install)   install "$@" ;;
    oci-setup) oci_setup "$@" ;;
    *)         usage ;;
esac
