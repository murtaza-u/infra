{ lib, config, extraArgs, ... }:
let
  infra = lib.importJSON (builtins.getEnv "TF_OUTPUT_JSON");
in
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
    hostName = "srv-oci-0";
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
      "tailscale/auth_keys/srv_oci_0" = {
        mode = "0400";
        owner = "root";
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
    # tailscale
    tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets."tailscale/auth_keys/srv_oci_0".path;
    };
    # setup K3S
    k3s = {
      enable = true;
      package = extraArgs.unstable.k3s_1_34;
      role = "server";
      isBootstrapNode = true;
      # nodeIP = infra.oci_instances.value."srv-oci-0".private_ip;
      nodeInternalDNS = "srv-oci-0.tadpole-stonecat.ts.net";
      oidcIssuerURL = infra.oci_icds.value.oidc_issuer_url;
      oidcDiscoveryURL = infra.oci_icds.value.oidc_discovery_url;
      oidcClientID = infra.oci_icds.value.oidc_client_id;
      oidcAudiences = [
        infra.oci_icds.value.oidc_issuer_url
        (lib.removeSuffix ":443/.well-known/openid-configuration" infra.oci_icds.value.oidc_discovery_url)
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
          name = "oci:${infra.oci_icds.value.oidc_client_id}";
        }
      ];
      installLonghornDependencies = true;
    };
  };

  system.stateVersion = "25.11";
}
