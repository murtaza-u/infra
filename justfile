set shell := ["bash", "-cu"]

target_host := ""
ssh_identity_file := ""

default:
    @just -l

build host:
    nix build .#nixosConfigurations.{{ host }}.config.system.build.toplevel --impure

deploy host:
    export NIX_SSHOPTS="-i {{ ssh_identity_file }}"; \
    nixos-rebuild switch \
        --impure \
        --flake .#{{ host }} \
        --target-host {{ target_host }} \
        --use-remote-sudo

install host:
    nixos-anywhere \
        --generate-hardware-config nixos-generate-config nixos/hosts/{{ host }}/hardware.nix \
        --flake .#{{ host }} \
        --target-host {{ target_host }} \
        -i {{ ssh_identity_file }} \
        --build-on local \
        --extra-files "$(./hack/ssh-host-key.sh)" \
        --option pure-eval false
