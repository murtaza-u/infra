{ config, pkgs, ... }:

{
  sops = {
    defaultSopsFile = ../../secrets.yaml;
    validateSopsFiles = false;
    age.sshKeyPaths = [ "/home/${config.users.users.scout.name}/.ssh/id_ed25519" ];
    secrets."gh_pat" = {
      mode = "0400";
      owner = config.users.users.ghrunner.name;
      group = config.users.users.ghrunner.group;
    };
  };

  services.github-runners.infra = {
    name = "node-base-infra";
    enable = true;
    ephemeral = true;
    replace = true;
    user = config.users.users.ghrunner.name;
    url = "https://github.com/murtaza-u/infra";
    tokenFile = config.sops.secrets."gh_pat".path;
    extraLabels = [ "nixos" "nixos-24.11" "node-base" "infra" ];
    serviceOverrides = {
      ProtectHome = false;
    };
    extraPackages = with pkgs; [ ssh-agents openssh ];
  };
}
