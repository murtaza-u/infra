{ lib, terraform, extraArgs, ... }:

{
  imports = [
    ./hardware.nix
    ./disko.nix
  ];

  disko.enableConfig = true;

  boot.loader.systemd-boot.enable = true; # (for UEFI systems only)

  # Set your time zone.
  time.timeZone = "Etc/UTC";

  networking = {
    # Set hostname.
    hostName = terraform.hostname;
    # Use firewall provided by the underlying cloud provider's infrastructure.
    firewall.enable = false;
  };

  sops = {
    defaultSopsFile = ../../../secrets.yaml;
    validateSopsFiles = false;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "k3s_token" = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
    };
  };

  platform = {
    # enable flakes & configure gc
    nix.enable = true;
    # setup default users
    users.enable = true;
    # enable openssh
    ssh.enable = true;
    # enable timesyncd service
    synctime.enable = true;
    # setup K3S
    k3s = {
      enable = true;
      package = extraArgs.unstable.k3s_1_33;
      role = "server";
      nodeIP = terraform.private_ip;
      oidcIssuerURL = terraform.oidc_issuer_url;
      oidcDiscoveryURL = terraform.oidc_discovery_url;
      oidcClientID = terraform.oidc_client_id;
      oidcAudiences = [
        terraform.oidc_issuer_url
        (lib.removeSuffix ":443/.well-known/openid-configuration" terraform.oidc_discovery_url)
      ];
      oidcExtraScope = [ "get_groups" ];
      oidcGroupsClaimExpression = ''has(claims.groups) ? dyn(claims.groups).map(g, "oci:" + g.name) : []'';
      oidcUsernameClaimExpression = ''"oci:" + claims.sub'';
      oidcAdminSubjects = [
        {
          kind = "Group";
          name = "oci:Domain_Administrators";
        }
        {
          kind = "User";
          name = "oci:${terraform.oidc_client_id}";
        }
      ];
    };
  };

  system.stateVersion = "25.05";
}
