target_host := ""
ssh_identity_file := ""

default:
    @just -l

build host:
    nix build ".#nixosConfigurations.{{ host }}.config.system.build.toplevel" --impure

switch host: (build host)
    export NIX_SSHOPTS="-i {{ ssh_identity_file }} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"; \
    nix-copy-closure --to {{ target_host }} "$(readlink -f ./result)"; \
    ssh -i {{ ssh_identity_file }} \
        -o UserKnownHostsFile=/dev/null \
        -o StrictHostKeyChecking=no \
        {{ target_host }} "sudo $(readlink -f ./result)/bin/switch-to-configuration switch"

install host:
    nix run nixpkgs#nixos-anywhere -- \
        --generate-hardware-config nixos-generate-config nixos/hosts/{{ host }}/hardware.nix \
        --flake .#{{ host }} \
        --target-host {{ target_host }} \
        -i {{ ssh_identity_file }} \
        --ssh-option UserKnownHostsFile=/dev/null \
        --ssh-option StrictHostKeyChecking=no \
        --build-on local \
        --extra-files "$(./hack/ssh-host-key.sh)" \
        --option pure-eval false
